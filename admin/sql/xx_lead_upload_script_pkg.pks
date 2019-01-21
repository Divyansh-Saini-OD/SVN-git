CREATE OR REPLACE PACKAGE xx_lead_upload_script_pkg
IS
PROCEDURE xx_lead_upload_script_proc (p_errbuf OUT VARCHAR2,p_retcode OUT number, p_in_party_site_num IN VARCHAR2);
END xx_lead_upload_script_pkg;

/
SHOW ERROR;

