CREATE or REPLACE PACKAGE BODY XX_PO_INTERFACE_TO_GL_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_GL_INTERFACE_PO_TAX_PKG                                                         |
  -- |                                                                                            |
  -- |  Description:  This package is used by WEB services to load Punchout confirmation          |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-OCT-2017  Nagendra Chitla    Initial version                                |
  -- +============================================================================================+

  --/**************************************************************
  --* This function returns the current time
  --***************************************************************/
  FUNCTION time_now
          RETURN VARCHAR2
  IS
   lc_time_string VARCHAR2(40);
  BEGIN
    SELECT TO_CHAR(SYSDATE, 'DD-MON-RRRR HH24:MI:SS')
    INTO   lc_time_string
    FROM   DUAL;

    RETURN(lc_time_string);
  END time_now; 
  
  -- +===============================================================================================+
  -- | Name  : log_msg                                                                               |
  -- | Description     : This procedure used to log the messages in concurrent program log           |
  -- |    pi_log_flag            IN -- Debug Flag                                                    |
  -- |    pi_string              IN -- Message as String                                             |
  -- +================================================================================================+
  PROCEDURE log_msg(
                    pi_log_flag IN BOOLEAN DEFAULT FALSE,
                    pi_string   IN VARCHAR2
                    )
  IS
  BEGIN
    IF (pi_log_flag)
    THEN
      fnd_file.put_line(fnd_file.LOG, time_now || ' : ' || pi_string);    
    END IF;
  END log_msg;


 

  -- +===============================================================================================+
  -- | Name  : set_context                                                                           |
  -- | Description     : This procedure used to initialize and set the org_context in pl/sql block   |
  -- |    pi_translation_info            IN  -- user_name, responsiblity values from translations    |
  -- |    po_error_msg                   OUT -- Return Error message                                 |
  -- +================================================================================================+

  PROCEDURE set_context( 
                        p_translation_info   IN xx_fin_translatevalues%ROWTYPE,
                        p_error_msg          OUT VARCHAR2
                        )
  IS

   ln_responsibility_id      fnd_responsibility_tl.responsibility_id%TYPE;
   ln_user_id                fnd_user.user_id%TYPE;
   ln_application_id         fnd_responsibility_tl.application_id%TYPE;
   
  BEGIN
    
    SELECT frt.responsibility_id,
           fu.user_id,
           frt.application_id
    INTO   ln_responsibility_id,
           ln_user_id,
           ln_application_id           
    FROM   fnd_user fu,
           fnd_user_resp_groups_all furga,
           fnd_responsibility_tl frt
    WHERE   frt.LANGUAGE            = USERENV('LANG')
    AND    frt.responsibility_id    = furga.responsibility_id
    AND    (furga.start_date <= SYSDATE OR furga.start_date IS NULL)
    AND    (furga.end_date >= SYSDATE OR furga.end_date IS NULL)
    AND    furga.user_id            = fu.user_id
    AND    (fu.start_date <= SYSDATE OR fu.start_date IS NULL)
    AND    (fu.end_date >= SYSDATE OR fu.end_date IS NULL)
    AND    fu.user_name                =  p_translation_info.target_value1  -- username
    AND    frt.responsibility_name     =  p_translation_info.target_value2;  -- Resp Name

    fnd_global.apps_initialize(ln_user_id,ln_responsibility_id,ln_application_id);
    
  EXCEPTION
    WHEN OTHERS
    THEN
      p_error_msg:= 'unable to set the context ..'|| SUBSTR(SQLERRM, 1, 2000);
      log_msg(TRUE, p_error_msg);
  END set_context;
  

  
  -- +===============================================================================================+
-- | Name  : get_translation_info                                                                  |
-- | Description     : This function returns the transaltion info                                  |
-- |                                                                                               |
-- |                                                                    |
-- | Parameters      :                                                  |
-- +================================================================================================+

  FUNCTION get_translation_info(gl_translation_name   IN  xx_fin_translatedefinition.translation_name%TYPE,
                                gl_source_record      IN  xx_fin_translatevalues.source_value1%TYPE,
                                gl_translation_info   OUT xx_fin_translatevalues%ROWTYPE,
                                gl_error_msg          OUT VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    gl_error_msg        := NULL;
    gl_translation_info := NULL;

    SELECT xftv.*
    INTO gl_translation_info
    FROM xx_fin_translatedefinition xft,
         xx_fin_translatevalues xftv
    WHERE xft.translate_id    = xftv.translate_id
    AND xft.enabled_flag      = 'Y'
    AND xftv.enabled_flag     = 'Y'
    AND xft.translation_name  = gl_translation_name
    AND xftv.source_value1    = gl_source_record; --'CONFIG_DETAILS';

    RETURN 'Success';
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       gl_error_msg := 'No Translation info found for '||gl_translation_name;
       log_msg(TRUE, gl_error_msg);
       RETURN 'Failure';
     WHEN OTHERS
     THEN
       gl_error_msg := 'Error while getting the trans info '|| substr(SQLERRM,1,2000);
       log_msg(TRUE, gl_error_msg);
       RETURN 'Failure';
  END get_translation_info;  
  
  -- +===============================================================================================+
  -- | Name  : get_ledger_id                                                                      |
  -- | Description     : This procedure used to get the ledger ID of PO                              |
  -- |    p_org_id               IN -- Operating unit of PO                                          |
  -- +================================================================================================+
  FUNCTION get_ledger_id(
                         p_ledger_name IN VARCHAR2
                         ) 
  RETURN NUMBER
  IS 
  lc_ledger_id NUMBER;
  BEGIN
       SELECT ledger_id 
       INTO lc_ledger_id
       FROM gl_ledgers
       WHERE upper(Name)=upper(p_ledger_name);
       
      RETURN(lc_ledger_id);       
  EXCEPTION
  WHEN OTHERS THEN
     lc_ledger_id:=NULL;
     RETURN(lc_ledger_id);
  END get_ledger_id;
  
  -- +===============================================================================================+
  -- | Name  : get_access_set_id                                                                      |
  -- | Description     : This procedure used to get the ledger ID of PO                              |
  -- |    p_ledger_name               IN -- ledger name                                               |
  -- +================================================================================================+
  FUNCTION get_access_set_id(
                            p_ledger_name IN VARCHAR2
                            ) 
  RETURN NUMBER
  IS 
    lc_access_set_id NUMBER;
  BEGIN
      SELECT access_set_id 
      INTO lc_access_set_id
      FROM gl_access_sets
      WHERE upper(Name)=upper(p_ledger_name);
       
      RETURN(lc_access_set_id);       
  EXCEPTION
  WHEN OTHERS THEN
     lc_access_set_id:=NULL;
     RETURN(lc_access_set_id);
  END get_access_set_id;
  

 
 -- +===============================================================================================+
-- | Name  : insert_control_data                                                                  |
-- | Description     : This function used to insert data into gl control interaface                |
-- |                                                                                               |
-- |                                                                                               |
-- | Parameters      :                                                                             |
-- +================================================================================================+ 
  PROCEDURE insert_control_data(p_user_je_src_name    IN   VARCHAR2, --je source name
                                p_ledger_id           IN   NUMBER,
                                p_int_run_id          OUT NUMBER,
                                p_err_flag            OUT  VARCHAR2,
                                p_error_message       OUT VARCHAR2)
  IS
    lc_int_run_id NUMBER;
    lc_je_src_name VARCHAR2(100);
  BEGIN 
  
     -- To get the interface run id
     BEGIN
	   SELECT  gl_journal_import_s.NEXTVAL
	   INTO   lc_int_run_id
	   FROM   dual;
     EXCEPTION
     WHEN OTHERS 
	 THEN
       p_error_message:='Exception in getting the interface run id';
       log_msg(true, p_error_message);
       lc_int_run_id:=NULL;
       p_err_flag:='E';
     END;
     
    -- To get the JE Source Name
     BEGIN
	   SELECT je_source_name
       INTO lc_je_src_name
       FROM gl_je_sources 
       WHERE user_je_source_name=p_user_je_src_name;
     EXCEPTION
     WHEN OTHERS 
	 THEN
       p_error_message:='Exception in getting the JE Source Name';
       log_msg(true,p_error_message);
       lc_je_src_name:=NULL;
       p_err_flag:='E';
     END;
   	  
     IF lc_int_run_id IS NOT NULL AND lc_je_src_name IS NOT NULL THEN
       
        BEGIN
           INSERT INTO gl_interface_control(
                                            je_source_name,
                                            interface_run_id,
                                            status,
                                            set_of_books_id,
											group_id
                                           )
                                     VALUES(
                                            lc_je_src_name,
                                            lc_int_run_id,
                                            'S',
                                            p_ledger_id,
											g_conc_req_id
                                           );                     
            p_int_run_id:=lc_int_run_id;
                     
        EXCEPTION
        WHEN OTHERS 
		THEN
            p_error_message:='Exception in inserting data into gl_interface_control table';
            log_msg(true,p_error_message);
            p_err_flag:='E';
        END;
     ELSE
        p_error_message:='Exception in generating the Interface run id';
        log_msg(true,p_error_message);
        p_err_flag:='E';
     END IF;
  END insert_control_data;
  
-- +===============================================================================================+
-- | Name  : update_last_run_date                                                                 |
-- | Description     : This function used to submit Journal Import program                         |
-- |                                                                                               |
-- |                                                                                               |
-- | Parameters      :                                                                             |
-- +================================================================================================+ 

 PROCEDURE update_last_run_date(
                                 p_trans_name    IN  xx_fin_translatedefinition.translation_name%TYPE,
                                 p_source_val1   IN  xx_fin_translatevalues.source_value1%TYPE,
                                 p_curr_date     IN  DATE,
                                 p_error_flag    OUT VARCHAR2,
                                 p_error_message OUT VARCHAR2
                                 )  
 IS                                 
   BEGIN
      UPDATE xx_fin_translatevalues
      SET target_value5=TO_CHAR(p_curr_date,'DD-MON-YYYY HH24:MI:SS')
      WHERE translate_id IN (
							SELECT translate_id
							FROM  xx_fin_translatedefinition xft
							WHERE xft.enabled_flag = 'Y'
							AND   xft.translation_name= p_trans_name)
      AND source_value1=p_source_val1
      AND enabled_flag = 'Y';

   EXCEPTION
   WHEN OTHERS 
   THEN
      p_error_message:='Error while updating the Last run date in the translation values'||substr(sqlerrm,1,200);
      log_msg(true,p_error_message);    
      p_error_flag:='E';
   END update_last_run_date;
 
  -- +===============================================================================================+
-- | Name  : submit_journal_import                                                                 |
-- | Description     : This function used to submit Journal Import program                         |
-- |                                                                                               |
-- |                                                                                               |
-- | Parameters      :                                                                             |
-- +================================================================================================+ 
 PROCEDURE submit_journal_import(
                                 p_gl_hdr_rec    IN  xx_fin_translatevalues%ROWTYPE,
                                 p_inter_run_id  IN  NUMBER,
                                 p_err_flag      OUT VARCHAR2,
                                 p_error_message OUT VARCHAR2
                                 )
 IS
	lc_conc_id             NUMBER;
	lc_error_message       VARCHAR2(2000);
	lc_debug_flag          boolean;
	lc_access_set_id       NUMBER;
	e_process_exception    Exception;
  BEGIN
  
    -- Setting the Debug value
    IF p_gl_hdr_rec.target_value7 = 'Y'
    THEN 
        lc_debug_flag := TRUE;
    END IF; 
   
    -- Setting the Org Context ..
    log_msg(lc_debug_flag, 'Setting the Org Context');
 
    set_context(p_gl_hdr_rec,lc_error_message);
 
    IF lc_error_message IS NOT NULL
    THEN
        RAISE e_process_exception ;
    END IF;  
     
    lc_access_set_id:=get_access_set_id(p_gl_hdr_rec.target_value6); -- ledger name
     
    IF lc_access_set_id IS NOT NULL THEN
     
         -- Submitting the GL import program    
         lc_conc_id := fnd_request.submit_request
                           ( application   => 'SQLGL'
                            ,program       => 'GLLEZL'
                            ,description   => NULL
                            ,start_time    => SYSDATE
                            ,sub_request   => FALSE
                            ,argument1     => p_inter_run_id    --interface run id
                            ,argument2     => lc_access_set_id --data access set_id
                            ,argument3     => 'N'             --post to suspense
                            ,argument4     => NULL            --from date
                            ,argument5     => NULL            --to date
                            ,argument6     => 'N'             --summary mode
                            ,argument7     => 'N'             --import DFF
                            ,argument8     => 'Y'             --backward mode
                           );
             COMMIT;  
           
         IF nvl(lc_conc_id,0)<>0 THEN 
            log_msg(lc_debug_flag,'GL import submitted with request Id :'||lc_conc_id);
         ELSE
            p_error_message:='GL import program not submitted';
            log_msg(lc_debug_flag,p_error_message);
            p_err_flag:='E';        
         END IF;
    ELSE
       p_error_message:='Data Access set is null for ledger name :'||p_gl_hdr_rec.target_value6;
       log_msg(lc_debug_flag,p_error_message);
       p_err_flag:='E';
       
    END IF;
    
 EXCEPTION
 WHEN e_process_exception 
 THEN
   p_error_message:='Exception Occured while setting the Context'||substr(sqlerrm,1,200);
   log_msg(true,p_error_message);
   p_err_flag:='E';  
 WHEN OTHERS 
 THEN   
   p_error_message:='Error while submitting the GL Import Program:'||substr(sqlerrm,1,200);
   log_msg(true,p_error_message);
   p_err_flag:='E';  
END submit_journal_import;

  -- +===============================================================================================+
-- | Name  : get_accounting_details                                                                  |
-- | Description     : This function used to get the Header data                              |
-- |                                                                                               |
-- |                                                                                               |
-- | Parameters      :                                                                             |
-- +================================================================================================+ 
 PROCEDURE get_accounting_details(
                            p_po_header_id  IN  po_headers_all.po_header_id%Type,
                            p_po_acc_segs   OUT  r_segments_rec_type,
                            p_error_flag    OUT  VARCHAR2,
                            p_error_message OUT  VARCHAR2
                            )
 IS
 BEGIN
  
  SELECT Distinct Segment1,
         segment2,
         segment3,
         segment4,
         segment5,
         segment6,
         segment7
  INTO p_po_acc_segs
  FROM po_distributions_all pda,
       gl_code_combinations gcc
  WHERE pda.code_combination_id=gcc.code_combination_id
  AND   pda.po_header_id=p_po_header_id;
  
 EXCEPTION
 WHEN TOO_MANY_ROWS 
 THEN
   p_error_message:='Too many rows found for the PO Distribution account for PO';
   log_msg(true,p_error_message||' Header ID:'||p_po_header_id); 
   p_error_flag:='E';
 WHEN OTHERS
 THEN
    p_error_message:='Error in fetching the PO Distribution account for PO';
    log_msg(true,p_error_message||' PO Header ID:'||p_po_header_id);  
    p_error_flag:='E';
 END get_accounting_details;

  -- +===============================================================================================+
  -- | Name  : send_mail                                                                             |
  -- | Description     : Send EMAIL to Buisness for each PO with the current status                  |
  -- |                      i:e accept or reject in AOPS.                                            |
  -- |    pi_translation_rec            IN  -- Translation Values                                    |
  -- |    pi_po_number                  IN  -- PO Number                                             |
  -- |    pi_aops_number                IN  -- AOPS Number                                           |
  -- |    pi_mail_body                  IN  -- Mail Body                                             |
  -- |    po_error_msg                  OUT -- Error Message                                         |
  -- +================================================================================================+

  PROCEDURE send_mail(p_translation_rec    IN     xx_fin_translatevalues%ROWTYPE,
                      p_mail_body          IN     VARCHAR2,
                      p_return_msg         OUT    VARCHAR2)
  IS
    lc_error_msg              VARCHAR2 (4000);
    lc_conn                   UTL_SMTP.connection;
    lc_mail                   VARCHAR2 (2000) := NULL;
    lc_instance_name          VARCHAR2 (10) := NULL;
    lc_mail_subject           VARCHAR2 (4000) := NULL;
    lc_mime_type              VARCHAR2 (1000) := NULL;
    l_boundary                VARCHAR2 (50) := '----=*#abc1234321cba#*=';

    BEGIN
      lc_error_msg    := NULL;
      log_msg(TRUE, 'In Send_Mail ');

      BEGIN
        SELECT instance_name
        INTO  lc_instance_name
        FROM v$instance;
      EXCEPTION
        WHEN OTHERS
        THEN 
      lc_instance_name := NULL;
          log_msg(TRUE, 'Error While Getting the Instance Name :'||substr(sqlerrm,1,2000));
      END;

      log_msg(TRUE,'Sender :'||p_translation_rec.target_value9||chr(10)
                                ||'Recipient :'||p_translation_rec.target_value10||chr(10)
                ||'cc Recipient :'||p_translation_rec.target_value11||chr(10)
                     ||'Subject :'||p_translation_rec.target_value12);

      -- Calling xx_pa_pb_mail procedure to mail

      lc_mail_subject  := p_translation_rec.target_value12 ||' Request ID :'||g_conc_req_id;

      lc_mime_type := 'MIME-Version: 1.0' || UTL_TCP.CRLF;
      lc_mime_type := lc_mime_type ||'Content-Type: multipart/alternative; boundary="' || l_boundary || '"' || UTL_TCP.CRLF|| UTL_TCP.CRLF;

      lc_conn := xx_pa_pb_mail.begin_mail (sender          => p_translation_rec.target_value9,
                                           recipients      => p_translation_rec.target_value10,
                                           cc_recipients   => p_translation_rec.target_value11,
                                           subject         => lc_instance_name||' : '||lc_mail_subject,
                                           mime_type       => lc_mime_type
                                          );
       -- Code to send the mail in html format
       xx_pa_pb_mail.write_text (conn      => lc_conn,
                                 message   => '--' || l_boundary || UTL_TCP.CRLF);
       xx_pa_pb_mail.write_text (conn      => lc_conn,
                                 message   => 'Content-Type: text/html; charset="iso-8859-1"' || UTL_TCP.CRLF || UTL_TCP.CRLF);
       --Mail Body                                             
       xx_pa_pb_mail.write_text (conn   => lc_conn,
                                 message   => p_mail_body);
       --End of mail                                    
       xx_pa_pb_mail.end_mail (conn => lc_conn);
       log_msg(TRUE,'End of Send_Mail Program'); 
  EXCEPTION
    WHEN OTHERS
    THEN
      lc_error_msg := 'Error while sending the mail' || substr(SQLERRM,1,2000);
      p_return_msg   := lc_error_msg;
      log_msg(TRUE, lc_error_msg);
  END send_mail;
  
  -- +===============================================================================================+
-- | Name  : get_header_detls                                                                  |
-- | Description     : This function used to get the Header data                              |
-- |                                                                                               |
-- |                                                                                               |
-- | Parameters      :                                                                             |
-- +================================================================================================+ 
 PROCEDURE get_header_detls(
                            p_translation_info      OUT  xx_fin_translatevalues%ROWTYPE,
                            p_ledger_id             OUT  NUMBER,
                            p_err_flag              OUT  VARCHAR2,
                            p_error_message         OUT  VARCHAR2
                            )
 IS
	 lc_error_message        VARCHAR2(2000):=NULL;
	 lc_trans_name           xx_fin_translatedefinition.translation_name%TYPE := 'XXPO_TO_GL_TAX_CONFIG';
	 lc_debug_flag           BOOLEAN;
	 lc_return_status        VARCHAR2(50);
	 lc_cat_exist            VARCHAR2(1);
	 lc_src_exist            VARCHAR2(1);
	 e_process_exception     EXCEPTION;
 BEGIN
     p_error_message:=NULL;
     
     log_msg(true, 'Getting the Translation Values ..');   
  
     lc_return_status := get_translation_info(gl_translation_name => lc_trans_name,
                                              gl_source_record    => 'CONFIG_DETAILS',
                                              gl_translation_info => p_translation_info,
                                              gl_error_msg        => lc_error_message);
                                          
     -- Validating the Error message     
     IF lc_error_message IS NOT NULL
     THEN
        RAISE e_process_exception ;
     END IF;    
   
     -- Setting the Debug value
     IF p_translation_info.target_value7 = 'Y'
     THEN 
        lc_debug_flag := TRUE;
     END IF;
   
   
     log_msg(lc_debug_flag,'The Journal source name:'||p_translation_info.target_value3);
      
     log_msg(lc_debug_flag,'The Journal category name:'||p_translation_info.target_value4); 
        
     --Validating the GL Source name
     BEGIN
		SELECT 'Y'
		INTO lc_src_exist 
		FROM gl_je_sources
		WHERE user_je_source_name=p_translation_info.target_value3; -- JE Source name
     EXCEPTION
     WHEN NO_DATA_FOUND 
	 THEN
         p_err_flag := 'E';
         p_error_message:='The GL JE Source Name:'||p_translation_info.target_value3||' is not exist.';
         log_msg(lc_debug_flag,p_error_message);
     END;
            
     --Validating the GL Category name
     BEGIN
		SELECT 'Y' 
		INTO lc_cat_exist
		FROM gl_je_categories
		WHERE user_je_category_name=p_translation_info.target_value4; -- JE Category name
     EXCEPTION
     WHEN NO_DATA_FOUND 
	 THEN
        p_err_flag := 'E';
        p_error_message:=p_error_message||CHR(10)||'The GL JE Category Name:'||p_translation_info.target_value4||' is not exist.';
        log_msg(lc_debug_flag,p_error_message);
     END;
        
     -- Function to get the Ledger ID from PO Operating Unit    
     p_ledger_id:=get_ledger_id(p_translation_info.target_value6); -- Ledger Name
                
     -- Validating the Ledger ID    
     IF p_ledger_id IS NULL 
     THEN
        p_err_flag := 'E';
        p_error_message:=p_error_message||CHR(10)||'The Ledger name does not exist:'||p_translation_info.target_value6;
        log_msg(lc_debug_flag,'The Ledger name does not exist:'||p_translation_info.target_value6);
     END IF;
 EXCEPTION    
 WHEN e_process_exception 
 THEN
    log_msg(true, lc_error_message);
    p_error_message:=p_error_message||lc_error_message;
    p_err_flag:='E';
 WHEN OTHERS 
 THEN
    log_msg(true,'Exception raised in get_header_detls:'||SUBSTR(SQLERRM,1,250));
    p_error_message:=p_error_message||'Exception raised in get_header_detls:'||SUBSTR(SQLERRM,1,200);
    p_err_flag:='E';
 END get_header_detls;

-- +===============================================================================================+
-- | Name  : process_pending_tax_details                                                           |
-- | Description     : This procedure used to process the pending PO tax lines to GL               |
-- |                                                                                               |
-- |                                                                                               |
-- | Parameters      :                                                                             |
-- +================================================================================================+ 
 PROCEDURE process_pending_tax_details(errbuf              OUT  VARCHAR2,
                                       retcode             OUT  VARCHAR2,
									   p_po_number         IN   VARCHAR2
                                      )
 AS
                               
    CURSOR cur_gl_tax_dtls(p_last_run_date IN DATE,
						   p_current_Date  IN DATE)
    IS SELECT pha.po_header_id,
              pha.segment1,
              pha.currency_code,
              SUM(zl.tax_amt) po_tax_amount
       FROM rcv_transactions rt,
            po_headers_all pha,
            po_lines_all pla,
            po_line_locations_all plla,
            po_distributions_all pda,
            po_req_distributions_all prda,
            po_requisition_lines_all prla,
            zx_lines zl
      WHERE 1=1
      AND   rt.po_header_id = pha.po_header_id
      AND   pha.segment1    = NVL(p_po_number,pha.segment1)
      AND   rt.po_line_id   = pla.po_line_id
      AND   pla.po_line_id  = plla.po_line_id
      AND   plla.line_location_id = pda.line_location_id
      AND 	rt.po_distribution_id = pda.po_distribution_id
      AND 	pda.req_distribution_id = prda.distribution_id
      AND 	prda.requisition_line_id = prla.requisition_line_id
     AND 	prla.supplier_duns IN (SELECT xftv.target_value1
                                   FROM   xx_fin_translatedefinition xft,
									      xx_fin_translatevalues xftv
								  WHERE  xft.translate_id    = xftv.translate_id
                                  AND    xft.enabled_flag      = 'Y'
                                  AND    xftv.enabled_flag     = 'Y'
                                  AND    xft.translation_name  = 'XXPO_PUNCHOUT_CONFIG'
                                  AND    xftv.source_value1    = 'SUPPLIER_DUNS'
                                  AND    xftv.target_value12 = 'Y' --interface tax to GL
                           )
	  AND   rt.transaction_type = 'RECEIVE'
      AND 	rt.transaction_date >=NVL(p_last_run_date,rt.transaction_date) 
      AND 	rt.transaction_date <= NVL(p_current_date,rt.transaction_date)
      AND 	zl.trx_id = pha.po_header_id
      AND 	zl.trx_line_id = plla.line_location_id
      AND 	NVL(zl.cancel_flag,'XX')<>'Y'
      AND 	NVL(zl.tax_amt,0)>0
      GROUP BY pha.po_header_id,pha.segment1,pha.currency_code;
        
       lc_error_flag                    VARCHAR2(1);   
       lc_ledger_id                     gl_ledgers.ledger_id%TYPE;
       lc_debug_flag                    BOOLEAN;
       lc_translation_info              xx_fin_translatevalues%ROWTYPE;
       lc_po_to_gl_rec                  gl_interface%ROWTYPE;
       lc_last_run_date                 DATE;
       lc_int_run_id                    NUMBER;
       lc_rec_cnt                       NUMBER:=0;
       lc_rec_succ                      VARCHAR2(1):='N';
       lc_error_message                 VARCHAR2(2000);
       lc_current_Date                  DATE;
       lc_po_acc_segs                   r_segments_rec_type;
       lc_rec_exp_cnt                   NUMBER:=0;
       lc_trans_name                    xx_fin_translatedefinition.translation_name%TYPE := 'XXPO_TO_GL_TAX_CONFIG';
       lc_mail_body                     VARCHAR2(32000) := NULL;
       lc_send_mail                     VARCHAR2(1);
       e_process_exception              EXCEPTION;
       
       
 BEGIN

   
   log_msg(TRUE, 'Parameters:');
   log_msg(TRUE, 'PO Number: '||p_po_number);
   
   lc_error_message := NULL;
   lc_mail_body     := NULL;
   lc_send_mail     := 'N';
     
      
   log_msg(TRUE, 'calling get Header details ..'); 
   
  -- Function to get the Journal Header Details      
    get_header_detls(lc_translation_info,
                     lc_ledger_id,
                     lc_error_flag,
                     lc_error_message
                    );
                    
    lc_mail_body  :='<html> <body> <font face = "Arial" size = "2">
            Following Error has occured while processing OD Process Punch Out Tax details to GL program:</font>
            <br><br>';
	
	IF p_po_number IS NOT NULL
	THEN 
	  lc_last_run_Date:= NULL;
	  lc_current_Date := NULL;
	ELSE 
       --Get the last run date from Translation
       lc_last_run_date := TO_DATE(lc_translation_info.target_value5,'DD-MON-YYYY HH24:MI:SS');
	   lc_current_Date  := SYSDATE;

       IF lc_last_run_date IS NULL 
	   THEN
		  log_msg(true, 'The Last run date in translation values is null');
	      Raise e_process_exception;
	   END IF ;
	   
	END IF ;
                       
    -- Setting the Debug value
    IF lc_translation_info.target_value7 = 'Y'
    THEN 
        lc_debug_flag := TRUE;
    END IF;           
    
   
    IF nvl(lc_error_flag,'S')<>'E'
    THEN						         
                       
             log_msg(lc_debug_flag, 'Processing the pending PO tax Records Data ..');
                                     
             log_msg(lc_debug_flag, 'Inserting the Records into gl_interface table:');  
             
            lc_mail_body:=NULL;
             -- Mail Body with html tags.
            lc_mail_body  :=
                            '<html> <body> <font face = "Arial" size = "2">
                            Following PO Numbers have Exceptions while transferring Tax lines to GL :
                            <br>
                                <br>
                                    <table cellpadding=2 cellspacing=2>
                                        <tr>
                                            <td width="15%" align="left"><font face="Arial" size="2" color="BLACK">PO Number</font></td>
                                            <td width="20%" align="left"><font face="Arial" size="2" color="BLACK">Error Message</font></td>
                                        </tr>';
               
             FOR c_rec_tline in cur_gl_tax_dtls(lc_last_run_date,lc_current_Date)
             LOOP  
                  BEGIN 
                    log_msg(lc_debug_flag, 'Processing the PO header id :'|| c_rec_tline.po_header_id );
                  
                    log_msg(lc_debug_flag,'Getting the charge account details of PO:');
                  
                    get_accounting_details(p_po_header_id  => c_Rec_tline.po_header_id, 
                                           p_po_acc_segs   => lc_po_acc_segs,
                                           p_error_flag    => lc_error_flag,
                                           p_error_message => lc_error_message);
                                           
                    log_msg(lc_debug_flag,'The PO Distribution Account is:'||lc_po_acc_segs.segment1||'-'||lc_po_acc_segs.segment2||'-'||lc_po_acc_segs.segment3||'-'||
                             lc_po_acc_segs.segment4||'-'||lc_po_acc_segs.segment5||'-'||lc_po_acc_segs.segment6||'-'||lc_po_acc_segs.segment7);  
                      
                    log_msg(lc_debug_flag,'The GL Account(DR) is:'||lc_po_acc_segs.segment1||'-'||lc_po_acc_segs.segment2||'-'||lc_po_acc_segs.segment3||'-'||
                             lc_po_acc_segs.segment4||'-'||lc_po_acc_segs.segment5||'-'||lc_po_acc_segs.segment6||'-'||lc_po_acc_segs.segment7);
                    
                    log_msg(lc_debug_flag,'The Tax Account(CR) is:'||lc_po_acc_segs.segment1||'-'||lc_translation_info.target_value15||'-'||lc_translation_info.target_value8||'-'||
                             lc_po_acc_segs.segment4||'-'||lc_po_acc_segs.segment5||'-'||lc_po_acc_segs.segment6||'-'||lc_po_acc_segs.segment7);                             
                      
                             
                  IF nvl(lc_error_flag,'S')<>'E' 
                  THEN  
                      lc_rec_succ:='N';
                      
                          BEGIN
                             lc_po_to_gl_rec.status                    :='NEW';
                             lc_po_to_gl_rec.ledger_id                 :=lc_ledger_id;
                             lc_po_to_gl_rec.user_je_source_name       :=lc_translation_info.target_value3; -- JE source name
                             lc_po_to_gl_rec.user_je_category_name     :=lc_translation_info.target_value4; -- JE category name
                             lc_po_to_gl_rec.reference10               :='Buy from Ourselves Use Tax for PO #'||c_rec_tline.segment1;
                             lc_po_to_gl_rec.currency_code             :=c_rec_tline.currency_code;        
                             lc_po_to_gl_rec.actual_flag               :='A';          
                             lc_po_to_gl_rec.accounting_date           :=sysdate;
                             lc_po_to_gl_rec.date_created              :=sysdate;
                             lc_po_to_gl_rec.created_by                :=g_user_id;          
                             lc_po_to_gl_rec.entered_dr                :=c_rec_tline.po_tax_amount;           
                             lc_po_to_gl_rec.entered_cr                :=NULL; --c_rec_tline.po_tax_amount;            
                             lc_po_to_gl_rec.segment1                  :=lc_po_acc_segs.segment1;  --segment1            
                             lc_po_to_gl_rec.segment2                  :=lc_po_acc_segs.segment2;  --segment2            
                             lc_po_to_gl_rec.segment3                  :=lc_po_acc_segs.segment3;  --segment3          
                             lc_po_to_gl_rec.segment4                  :=lc_po_acc_segs.segment4; --segment4            
                             lc_po_to_gl_rec.segment5                  :=lc_po_acc_segs.segment5; --segment5              
                             lc_po_to_gl_rec.segment6                  :=lc_po_acc_segs.segment6; --segment6          
                             lc_po_to_gl_rec.segment7                  :=lc_po_acc_segs.segment7; --segment7
							 lc_po_to_gl_rec.group_id				   :=g_conc_req_id; 
                            
                             -- Inserting values into gl_interface table     
                             INSERT INTO gl_interface VALUES lc_po_to_gl_rec;
                      
                           --  COMMIT;   
                             
                            lc_rec_succ:='Y';
                             
                          EXCEPTION
                          WHEN OTHERS
                          THEN
                             ROLLBACK;       
                              lc_send_mail     := 'Y';
                              lc_rec_exp_cnt:=lc_rec_exp_cnt+1;
                              lc_mail_body := lc_mail_body ||'<tr>';
                              lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||c_rec_tline.segment1||'</font></td>'||CHR(10);
                              lc_mail_body := lc_mail_body ||'<td width="20%" align="left"><font face="Arial" size="2" color="BLACK">'||substr(sqlerrm,1,200)||'</font></td>'||CHR(10);
                              lc_mail_body := lc_mail_body ||'</tr>' || CHR (10); 
                              
                              log_msg(lc_debug_flag, 'Exception in inserting Debit the details into gl_interface table for the PO:'||c_rec_tline.segment1); 
                        END; 
                      
                    IF lc_rec_succ='Y' THEN  
                    
                       BEGIN
                             lc_po_to_gl_rec.status                    :='NEW';
                             lc_po_to_gl_rec.ledger_id                 :=lc_ledger_id;
                             lc_po_to_gl_rec.user_je_source_name       :=lc_translation_info.target_value3; -- JE source name
                             lc_po_to_gl_rec.user_je_category_name     :=lc_translation_info.target_value4; -- JE category name
                             lc_po_to_gl_rec.reference10               :='Buy from Ourselves Use Tax for PO #'||c_rec_tline.segment1;
                             lc_po_to_gl_rec.currency_code             :=c_rec_tline.currency_code;        
                             lc_po_to_gl_rec.actual_flag               :='A';          
                             lc_po_to_gl_rec.accounting_date           :=sysdate;
                             lc_po_to_gl_rec.date_created              :=sysdate;
                             lc_po_to_gl_rec.created_by                :=g_user_id;          
                             lc_po_to_gl_rec.entered_dr                :=NULL; --c_rec_tline.po_tax_amount;           
                             lc_po_to_gl_rec.entered_cr                :=c_rec_tline.po_tax_amount;            
                             lc_po_to_gl_rec.segment1                  :=lc_po_acc_segs.segment1;             --segment1            
                             lc_po_to_gl_rec.segment2                  :=lc_translation_info.target_value15;  --segment2 -- keep this from transaltion           
                             lc_po_to_gl_rec.segment3                  :=lc_translation_info.target_value8;   --segment3  -- keep this from transaltion             
                             lc_po_to_gl_rec.segment4                  :=lc_po_acc_segs.segment4;             --segment4            
                             lc_po_to_gl_rec.segment5                  :=lc_po_acc_segs.segment5;             --segment5              
                             lc_po_to_gl_rec.segment6                  :=lc_po_acc_segs.segment6;             --segment6          
                             lc_po_to_gl_rec.segment7                  :=lc_po_acc_segs.segment7;             --segment7
							 lc_po_to_gl_rec.group_id				   :=g_conc_req_id; 
                            
                             -- Inserting values into gl_interface table     
                             INSERT INTO gl_interface VALUES lc_po_to_gl_rec;
                      
                             COMMIT; 
                             
                              lc_rec_cnt:=lc_rec_cnt+1;
                                
                          EXCEPTION
                          WHEN OTHERS
                          THEN
                             ROLLBACK;       
                              lc_send_mail     := 'Y';
                              lc_rec_exp_cnt:=lc_rec_exp_cnt+1;
                              lc_mail_body := lc_mail_body ||'<tr>';
                              lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||c_rec_tline.segment1||'</font></td>'||CHR(10);
                              lc_mail_body := lc_mail_body ||'<td width="20%" align="left"><font face="Arial" size="2" color="BLACK">'||substr(sqlerrm,1,200)||'</font></td>'||CHR(10);
                              lc_mail_body := lc_mail_body ||'</tr>' || CHR (10); 
                              
                              log_msg(lc_debug_flag, 'Exception in inserting the credit details into gl_interface table for the PO:'||c_rec_tline.segment1); 
                        END;  
                        
                      END IF;   
                ELSE
                    lc_send_mail     := 'Y';
                    lc_rec_exp_cnt:=lc_rec_exp_cnt+1;
                    lc_mail_body := lc_mail_body ||'<tr>';
                    lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||c_rec_tline.segment1||'</font></td>'||CHR(10);
                    lc_mail_body := lc_mail_body ||'<td width="20%" align="left"><font face="Arial" size="2" color="BLACK">'||lc_error_message||'</font></td>'||CHR(10);
                    lc_mail_body := lc_mail_body ||'</tr>' || CHR (10); 
                END IF;     
            EXCEPTION
            WHEN OTHERS
            THEN
                log_msg(lc_debug_flag,'Exception in for loop for PO:'||c_rec_tline.po_header_id||' is '||SUBSTR(SQLERRM,1,200));
            END;
                  
        END LOOP;
              
               
             --Updating the last run date in translation table
                IF p_po_number IS NULL
                THEN
                    log_msg(lc_debug_flag,'Updating the Last run date in translation values with:'||TO_CHAR(lc_current_Date,'DD-MON-YYYY HH24:MI:SS'));
                    
                     update_last_run_date(lc_trans_name,
                                          lc_translation_info.source_value1,
                                          lc_current_Date,
                                          lc_error_flag,
                                          lc_error_message
                                          );
                                       
                     COMMIT;
                END IF;   
                
                -- If last run date update has error
                IF nvl(lc_error_flag,'S')='E'
                THEN
                    lc_send_mail     := 'Y';
                    lc_mail_body := lc_mail_body ||'<tr>';
                    lc_mail_body := lc_mail_body ||'<td width="15%" align="left"><font face="Arial" size="2" color="BLACK">'||lc_error_message||'</font></td>'||CHR(10);
                    lc_mail_body := lc_mail_body ||'</tr>' || CHR (10); 
                END IF;
                     
             lc_mail_body := lc_mail_body||'</table>';
             
             log_msg(lc_debug_flag,'Number of POs inserted into gl_interface table:'||lc_rec_cnt);
         
             IF lc_rec_exp_cnt>0 THEN
                log_msg(lc_debug_flag,'Number of POs not processed into gl_interface table:'||lc_rec_exp_cnt);
             ELSE
                lc_mail_body  :='<html> <body>';
             END IF;
          		 
         IF lc_rec_cnt>0 THEN  			 
			     
            log_msg(lc_debug_flag, 'Inserting record into gl interface control table');
               
            -- procedure to insert the data into gl_interface_control table
            insert_control_data(lc_translation_info.target_value3, --je source name
                                lc_ledger_id,
                                lc_int_run_id,
                                lc_error_flag,
                                lc_error_message
                                );

		     COMMIT;
             
                 IF nvl(lc_error_flag,'S')<>'E' 
                 THEN
                    log_msg(lc_debug_flag,'Submitting the Journal Import');
                  
                    --Submitting the journal Import program
                    submit_journal_import(lc_translation_info,
                                          lc_int_run_id,
                                          lc_error_flag,
                                          lc_error_message);
                    
                    IF nvl(lc_error_flag,'S')='E' 
                    THEN
                      lc_send_mail     := 'Y';
                      lc_mail_body  :=lc_mail_body||'<table cellpadding=2 cellspacing=2>
                                    <tr><font face = "Arial" size = "2">
                                    Following are Other Exceptions while transferring Tax lines to GL :</font></tr>';
                     
                      lc_mail_body:=lc_mail_body||'<tr><font face="Arial" size="2" color="BLACK">'||lc_error_message||'</font>'||CHR(10);
                      lc_mail_body := lc_mail_body ||'</tr></table>'; 
                    
                    END IF;
                    
                  ELSE
                     lc_send_mail     := 'Y';
                     
                     lc_mail_body  :=lc_mail_body||'<table cellpadding=2 cellspacing=2>
                                    <tr><font face = "Arial" size = "2">
                                    Following are Other Exceptions while transferring Tax lines to GL :</font></tr>';
                     
                     lc_mail_body:=lc_mail_body||'<tr><font face="Arial" size="2" color="BLACK">'||lc_error_message||'</font>'||CHR(10);
                     lc_mail_body := lc_mail_body ||'</tr></table>';  
                            
                  END IF;  
         ELSE     
             log_msg(lc_debug_flag,'Jounral import program not submitted, due to no records inserted in interface table :'||lc_rec_cnt);
         END IF;
    ELSE
          lc_send_mail     := 'Y';
          lc_mail_body:=lc_mail_body||'<font face="Arial" size="2" color="BLACK">'||lc_error_message||'</font>'||CHR(10);
    END IF;	        
    
    lc_mail_body := lc_mail_body||'</body></html>';
    
    IF nvl(lc_translation_info.target_value13,'N') = 'Y' THEN 
            IF lc_send_mail = 'Y' THEN
              log_msg(lc_debug_flag, 'Sending the Mail ..');
              send_mail(p_translation_rec    =>  lc_translation_info,
                        p_mail_body          =>  lc_mail_body,
                        p_return_msg         =>  lc_error_message);
             END IF;  
     END IF;        
    
 EXCEPTION 
 WHEN e_process_exception
 THEN
	log_msg(true,'Exception occured in process_pending_tax_details'||substr(SQLERRM,1,200));
 WHEN OTHERS 
 THEN
	retcode := 1;
    log_msg(true,'Exception occured in process_pending_tax_details'||substr(SQLERRM,1,200));
 END process_pending_tax_details;
   
END XX_PO_INTERFACE_TO_GL_PKG;
/