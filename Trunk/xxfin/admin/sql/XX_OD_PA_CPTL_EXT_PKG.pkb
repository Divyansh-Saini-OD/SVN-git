CREATE OR REPLACE
PACKAGE BODY XX_OD_PA_CPTL_EXT_PKG
AS

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_OD_PA_CPTL_EXT_PKG                                               |
-- | Description : This Package will be executable code for the projects download repor|
-- |                                                                                   |
-- |  Rice ID : E3062                                                                  |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2013  Yamuna Shankarappa      Initial draft version               |
-- +===================================================================================+
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                            ORACLE                                                 |
-- +===================================================================================+
-- | Name        : PROJECT_ASSETS_DATA_EXTRACT                                         |
-- | Description : This Package is used to generate the project related asset informati| 
-- |                on.                                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2013  Yamuna Shankarappa     Initial draft version                |
-- |DRAFT 1.1 17-NOV-2015  Harvinder Rakhra       Retrofit R12.2                       |
-- +===================================================================================+

PROCEDURE EXTRACT
IS
  -- Local Variable declaration
  lc_rpt_rid      NUMBER(15);
  lb_layout       BOOLEAN;
  lb_req_status   BOOLEAN;
  lc_status_code  VARCHAR2(100);
  lc_phase        VARCHAR2(100);
  lc_status       VARCHAR2(100);
  lc_devphase     VARCHAR2(100);
  lc_devstatus    VARCHAR2(100);
  lc_message      VARCHAR2(1000);
  lb_print_option BOOLEAN;
  lc_boolean      BOOLEAN;
BEGIN
  lb_layout  := fnd_request.add_layout('XXFIN' ,'XXODPACPTLEXT' ,'en' ,'US' ,'EXCEL');
  lc_rpt_rid := FND_REQUEST.SUBMIT_REQUEST('XXFIN' ,'XXODPACPTLEXT' ,NULL ,NULL ,FALSE);
  COMMIT;
  lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => lc_rpt_rid ,
                                                   interval => '2' ,
                                                   max_wait => '' ,
                                                   phase => lc_phase ,
                                                   status => lc_status ,
                                                   dev_phase => lc_devphase ,
                                                   dev_status => lc_devstatus ,
                                                   MESSAGE => lc_message);
  IF lc_rpt_rid <> 0 THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The report has been submitted and the request id is: '||lc_rpt_rid);
  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error submitting the report publisher request.');
    lc_boolean:=fnd_concurrent.set_completion_status('WARNING','Encountered an error while publishing the report.');
  END IF;
END EXTRACT;

PROCEDURE XX_MAIN(
    x_err_buff OUT VARCHAR2,
    x_ret_code OUT NUMBER)
IS
  ln_request_id      NUMBER(15);
  lb_layout          BOOLEAN;
  lb_req_status      BOOLEAN;
  lc_status_code     VARCHAR2(10);
  lc_phase           VARCHAR2(50);
  lc_status          VARCHAR2(50);
  lc_devphase        VARCHAR2(50);
  lc_devstatus       VARCHAR2(50);
  lc_message         VARCHAR2(50);
  lb_print_option    BOOLEAN;
  lc_boolean         BOOLEAN;
  ln_total_processed NUMBER :=0;
  ln_success_count   NUMBER :=0;
  ln_error_count     NUMBER :=0;
  project_id        NUMBER;
  lc_flag            BOOLEAN:=TRUE ;
 
 CURSOR c_stg_data
  IS
    SELECT project_number FROM xx_pa_download_stg WHERE 1 =1 AND status='E';
 
BEGIN
  -- delete old processed records
  DELETE  FROM xx_pa_download_stg  WHERE project_number IS NULL;
  DELETE  FROM xx_pa_download_stg  WHERE project_number  IS NULL  AND status IS NULL
  AND error_msg         IS NULL  AND last_updated_by   IS NULL  AND last_update_date  IS NULL
  AND last_update_login IS NULL  AND created_by        IS NULL  AND creation_date     IS NULL;
  DELETE FROM xx_pa_download_stg WHERE status IN ('P','E');
  COMMIT;
  
  update xx_pa_download_stg ds set status ='E' where  not  exists (select 1 from pa_projects_all where segment1=ds.project_number);
  update xx_pa_download_stg ds set status ='P' where exists (select 1 from pa_projects_all where segment1=ds.project_number);
  COMMIT;
  FOR c_stg_rec IN c_stg_data
  LOOP
   FND_FILE.PUT_LINE(FND_FILE.LOG, c_stg_rec.project_number || ', is an invalid Project Number' );
  END LOOP;
  
  select count(*) into ln_total_processed from xx_pa_download_stg;
  select count(*) into ln_success_count from xx_pa_download_stg where status='P';
  select count(*) into ln_error_count from xx_pa_download_stg where status='E';
  
  FND_FILE.PUT_LINE(FND_FILE.LOG,'-----------------------------------------------------------------------------');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Projects processed              :' || ln_total_processed);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Projects successfully Found   :' || ln_success_count);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Projects errored                :' || ln_error_count);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'------------------------------------------------------------------------------');
  
  EXTRACT();
  
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered the exception:- ' ||SUBSTR (SQLERRM, 1, 225) );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'End Time: ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH:MI:SS AM') );
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Request : '||ln_request_id||' completed in error. Please refer to log file for more details.');
  lc_boolean:=fnd_concurrent.set_completion_status('ERROR','Concurrent request encountered an error.Please refer to log file for details.');
  COMMIT;
END XX_MAIN;
END XX_OD_PA_CPTL_EXT_PKG;
/
