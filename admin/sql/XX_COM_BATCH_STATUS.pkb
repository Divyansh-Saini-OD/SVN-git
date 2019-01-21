 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 SET SHOW OFF
 PROMPT Creating Package XX_COM_BATCH_STATUS
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

create or replace PACKAGE BODY XX_COM_BATCH_STATUS AS

 -- +=====================================================================+
 -- |                  Office Depot - Project Simplify                    |
 -- |                       WIPRO Technologies                            |
 -- +=====================================================================+
 -- | Name : XX_COM_BATCH_STATUS                                          |
----|                                                                     |
 -- | Change Record:                                                      |
 -- |===============                                                      |
 -- |Version   Date              Author                 Remarks           |
 -- |======   ==========     =============        ======================= |
 -- |Draft 1A 10-Nov-2010    Saravanan             Initial version        |
 -- |                                                                     |
 -- +=====================================================================+


  PROCEDURE Status_Report_Main (  x_errbuf                   OUT NOCOPY      VARCHAR2
                                , x_retcode                  OUT NOCOPY      NUMBER
                                , p_period_stat              VARCHAR2 
                                , p_int_status               VARCHAR2 
                                , p_file_stat                VARCHAR2
                                , p_batch_stat               VARCHAR2
                                , p_job_stat                 VARCHAR2
                                , p_start_date               VARCHAR2
                                , p_end_date                 VARCHAR2
                                , p_file_folder              VARCHAR2
                                , p_file_start_Date          VARCHAR2
                                , p_file_end_date            VARCHAR2 
                                , p_email_list               VARCHAR2
                                )
 AS
 
   lc_request_data        VARCHAR2(50);
   ln_request_id          NUMBER;
   lb_success             BOOLEAN;
   lc_file_st_date        VARCHAR2(20);
   lc_file_ed_date        VARCHAR2(20);

  BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,'Period Stat     : '||p_period_stat);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Interface Stat  : '||p_int_status);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'File Stat       : '||p_file_stat);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Batch Stat      : '||p_batch_stat);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Job Stat        : '||p_job_stat);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Job start Date  : '||p_start_date);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Job End Date    : '||p_end_date);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'File Folder     : '||p_file_folder);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'File Start Date : '||p_file_start_Date);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'File End_Date : '||p_file_end_date);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Email List      : '||p_email_list);


   lc_request_data :=FND_CONC_GLOBAL.request_data;

   IF lc_request_data IS NULL THEN

      DELETE FROM XX_COM_FILE_STATUS;

      lc_file_st_date := TO_CHAR(TO_DATE(p_file_start_Date,'YYYY/MM/DD HH24:MI:SS'),'YYYYMMDD');
      lc_file_ed_date := TO_CHAR(TO_DATE(p_file_end_date,'YYYY/MM/DD HH24:MI:SS'),'YYYYMMDD');

     FND_FILE.PUT_LINE(FND_FILE.LOG,'File Start Date : '||lc_file_st_date);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'File End Date  : '||lc_file_ed_date);

      ln_request_id := FND_REQUEST.SUBMIT_REQUEST(  'XXFIN'
                                                  , 'XXCOMFILESTAT'
                                                  , NULL
                                                  , NULL
                                                  , TRUE
                                                  , p_file_folder
                                                  , lc_file_st_date
                                                  , lc_file_ed_date
                                                );
      IF ln_request_id > 0 THEN
         FND_CONC_GLOBAL.set_req_globals( conc_status => 'PAUSED',request_data => 'LOAD_FILE');
      END IF;
   
   ELSIF  lc_request_data = 'LOAD_FILE' THEN

         lb_success :=
               FND_REQUEST.add_layout
                  ( template_appl_name    => 'XXFIN',
                    template_code         => 'XXCOMBATCHSTATUS',
                    template_language     => 'en',
                    template_territory    => 'US',
                    output_format         => 'PDF'
                   );

       ln_request_id := FND_REQUEST.SUBMIT_REQUEST(  'XXFIN'
                                                  , 'XXCOMBATCHSTATUS'
                                                  , NULL
                                                  , NULL
                                                  , TRUE
                                                  , p_period_stat
                                                  , p_int_status
                                                  , p_file_stat
                                                  , p_batch_stat
                                                  , p_job_stat
                                                  , p_start_date
                                                  , p_end_date
                                                  , p_email_list 
                                                );
      IF ln_request_id > 0 THEN
         FND_CONC_GLOBAL.set_req_globals( conc_status => 'PAUSED',request_data => 'END_PRINT');
      END IF;
   
   END IF;

END Status_Report_Main;

PROCEDURE insert_interface_data IS

CURSOR int_record
IS
              SELECT xftv.source_value1
                    ,xftv.source_value2
                    ,xftv.source_value3
                    ,xftv.source_value4
                    ,xftv.source_value5
                    ,xftv.source_value6
              FROM xx_fin_translatedefinition    XFTD
              ,xx_fin_translatevalues       XFTV
              WHERE XFTV.translate_id     = XFTD.translate_id
              AND     XFTD.translation_name = 'OD_INTERFACE_STATUS'
              AND     XFTV.enabled_flag     = 'Y'
              AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
              AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1);
     
lc_sql_stmt varchar2(4000);
BEGIN
   DELETE FROM XX_COM_INT_STATUS;

  FOR rec in int_record
        LOOP

               INSERT INTO XX_COM_INT_STATUS VALUES
                         (   rec.source_value1
                           , rec.source_value2
                           , rec.source_value3
                           , rec.source_value4
                           , rec.source_value5
                           , rec.source_value6
                           , NULL
                           , 1
                           );

                lc_sql_stmt := 'INSERT INTO XX_COM_INT_STATUS
                                ( SELECT '''||rec.source_value1||'''
                                              ,'||NVL(rec.source_value2,'''''')||'
                                              ,'||NVL(rec.source_value3,'''''')||'
                                              ,'||NVL(rec.source_value4,'''''')||'
                                              ,'||NVL(rec.source_value5,'''''')||'
                                              ,'||NVL(rec.source_value6,'''''')||'
                                              ,count(1)
                                              , 2 FROM '||rec.source_value1||'
                                              '||'group by '||'
                                              '''||rec.source_value1||'''
                                              ,'||NVL(rec.source_value2,'''''')||'
                                              ,'||NVL(rec.source_value3,'''''')||'
                                              ,'||NVL(rec.source_value4,'''''')||'
                                              ,'||NVL(rec.source_value5,'''''')||'
                                              ,'||NVL(rec.source_value6,'''''')||'
                                              ' ||')';
      EXECUTE IMMEDIATE lc_sql_stmt;
                                                      
        END LOOP;                                       
END insert_interface_data;  


PROCEDURE Send_Status_Email (  p_request_id  NUMBER
                             , p_email_id    VARCHAR2)
IS

lc_Std_dir_path                VARCHAR2(2000);
lc_out_dir_path                VARCHAR2(2000);

lc_subject  VARCHAR2(1000) := 'Status Report';
lt_file_html              UTL_FILE.FILE_TYPE;
lt_file_mail_id           UTL_FILE.FILE_TYPE;
lt_file_attachment        UTL_FILE.FILE_TYPE;

lc_html_file VARCHAR2(4000);
lc_mail_id_file VARCHAR2(4000);
lc_attach_file VARCHAR2(4000);
lc_file_name VARCHAR2(4000);

ln_conc_request_id NUMBER;


BEGIN

          lc_html_file         := p_request_id||'_HTML'||'.html';
          lc_mail_id_file      := p_request_id||'_MAIL_ID'||'.txt';
          lc_attach_file       := p_request_id||'_ATTACH'||'.txt';
          lc_file_name         := 'XXCOMBATCHSTATUS_'||p_request_id||'_1.PDF';

          FND_FILE.PUT_LINE(FND_FILE.LOG,'HTML File name '||lc_html_file);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Mail Id File Name: '||lc_mail_id_file);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Attachment File Name '||lc_attach_file);

          SELECT directory_path
          INTO lc_Std_dir_path
          FROM dba_directories
          WHERE directory_name = 'STD_OUTPUT_DIRECTORY';

          SELECT directory_path
          INTO lc_out_dir_path
          FROM dba_directories
          WHERE directory_name = 'XXFIN_OUTBOUND';
              
          lt_file_html       := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_html_file,'w');
          UTL_FILE.PUT_LINE(lt_file_html,'Hi, Please Find the attached Status Report  Thanks ');
          UTL_FILE.fclose(lt_file_html);

          lt_file_mail_id    := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_mail_id_file ,'w');
          UTL_FILE.PUT_LINE(lt_file_mail_id,p_email_id);
          UTL_FILE.fclose(lt_file_mail_id);

           lt_file_attachment   := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_attach_file ,'w');
           UTL_FILE.PUT_LINE(lt_file_attachment,lc_file_name);
           UTL_FILE.fclose(lt_file_attachment);

                --Call the shell script program to send the mail with attachment.
                ln_conc_request_id := fnd_request.submit_request ('XXCOMN'
                                                                  ,'XXCOMHTMLMAIL'
                                                                  ,''
                                                                  ,''
                                                                  ,FALSE
                                                                  ,lc_out_dir_path||'/'||lc_mail_id_file
                                                                  , lc_subject
                                                                  ,'Concurrent_request_status_mailer'
                                                                  ,lc_out_dir_path||'/'||lc_html_file
                                                                  ,lc_Std_dir_path||'/'||lc_attach_file
                                                                  ,99999999999
                                                                  );
                COMMIT;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent Request ID(OD: HTML Mailer): '||ln_conc_request_id);

END Send_Status_Email;


FUNCTION get_threshold (p_cp_name VARCHAR2
                       ,org VARCHAR2
                       )
 RETURN VARCHAR2 IS
lc_threshold VARCHAR2(100);
BEGIN
	
	SELECT DECODE(NVL('Normal',xftv.target_value17)
                    ,'Normal',xftv.target_value5
                    ,'Peak',xftv.target_value7)
   INTO lc_threshold
   FROM  xx_fin_translatedefinition       XFTD
        ,xx_fin_translatevalues           XFTV
   WHERE XFTV.translate_id     = XFTD.translate_id
AND     XFTD.translation_name = 'OD_BATCH_EVENT_ALERT'
AND     XFTV.enabled_flag     = 'Y'
AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)        
AND     UPPER(XFTV.target_value1)	= p_cp_name
AND     XFTV.target_value2 = org;
  RETURN lc_threshold;
  
EXCEPTION WHEN OTHERS THEN
        RETURN NULL;
END get_threshold;

END XX_COM_BATCH_STATUS;
/
SHOW ERR
