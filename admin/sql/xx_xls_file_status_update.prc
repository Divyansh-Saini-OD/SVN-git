-- +============================================================================+
-- |                  Office Depot                                              |
-- +============================================================================+
-- | Name        : xx_xls_file_status_update.sql                                |
-- | Rice ID     : E2059                                                        |
-- | Description : procedure to update the xls file status - Adhoc              |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        Author           Remarks                              |
-- |=======  ===========  =============    =====================================|
-- |1.0      02-NOV-2015  Suresh Naragam   Initial Version                      |
-- +============================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT
PROMPT Creating Procedure xx_xls_file_status_update in APPS.....
PROMPT

CREATE OR REPLACE PROCEDURE xx_xls_file_status_update
(p_retcode                NUMBER
 ,p_errbuff               VARCHAR2
 ,p_cust_doc_id           NUMBER
 ,p_file_id               NUMBER
 ,p_status                VARCHAR2
 ,p_include_header        VARCHAR2
 ,p_file_logo_required    VARCHAR2)
IS
BEGIN
 fnd_file.put_line(fnd_file.log,'Parameters entered is :');
 fnd_file.put_line(fnd_file.log,'File Id :'||p_cust_doc_id);
 fnd_file.put_line(fnd_file.log,'File Id :'||p_file_id);
 fnd_file.put_line(fnd_file.log,'Status '||p_status);
 fnd_file.put_line(fnd_file.log,'Include File Header '||p_include_header);
 fnd_file.put_line(fnd_file.log,'File Logo Required '||p_file_logo_required);
 
 fnd_file.put_line(fnd_file.log,'Updating status to '||p_status||' for file Id : '||p_file_id||' Cust Doc Id : '||p_cust_doc_id);
 BEGIN
   UPDATE xx_ar_ebl_file
   SET status = p_status
   WHERE file_id = nvl(p_file_id,file_id)
   AND cust_doc_id = p_cust_doc_id;
   fnd_file.put_line(fnd_file.log,'No. of rows updated : '||sql%rowcount||' for file_id '||p_file_id||' and Cust Doc Id : '||p_cust_doc_id);
 EXCEPTION WHEN OTHERS THEN
   fnd_file.put_line(fnd_file.log,'Error While updating status for file Id : '||p_file_id||' Cust Doc Id : '||p_cust_doc_id);
 END;
 fnd_file.put_line(fnd_file.log,'Updating Logo required and Include header for file Id : '||p_file_id||' Cust Doc Id : '||p_cust_doc_id);
 BEGIN
   UPDATE xx_cdh_ebl_templ_header
   SET logo_file_name = nvl(DECODE(p_file_logo_required,'Y','OFFICEDEPOT','N',null),logo_file_name)
      ,include_header = nvl(p_include_header,include_header)
   WHERE cust_doc_id = p_cust_doc_id;
   fnd_file.put_line(fnd_file.log,'No. of rows updated : '||sql%rowcount||' for file_id '||p_file_id||' and Cust Doc Id : '||p_cust_doc_id);
 EXCEPTION WHEN OTHERS THEN
   fnd_file.put_line(fnd_file.log,'Error While updating status for file Id : '||p_file_id||' Cust Doc Id : '||p_cust_doc_id);
 END;
  COMMIT;
END;
/

SHOW ERROR;

 

