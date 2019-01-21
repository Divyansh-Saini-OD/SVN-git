create or replace
PACKAGE BODY XX_OD_PA_CPTL_UPLD_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name:  XX_OD_PA_CPTL_UPLD_PKG                                                             |
  -- |  Description:  PA Mass Upload Tool to update project asset information                     |
  -- |  Rice ID : E3062                                                                           |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         01-Jul-2013   Archana N.        Initial version                                |
  -- | 1.1         24-Jul-2013   Archana N.        Added enabled_flag condition while retrieving  |
  -- |                                             asset locations.                               |
  -- | 1.2         06-Sep-2013  Archana N.        Made changes for defect# 25249                  |
  -- | 1.3         17-Nov-2015  Harvinder Rakhra  Retrofit R12.2                                  |
  -- +============================================================================================+

PROCEDURE PUBLISH_REPORT
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
  lc_exc_flag      BOOLEAN := FALSE;
BEGIN
  lb_layout  := fnd_request.add_layout('XXFIN' ,'XXODPACPTLUPLD' ,'en' ,'US' ,'EXCEL');
  lc_rpt_rid := FND_REQUEST.SUBMIT_REQUEST('XXFIN' ,'XXODPACPTLUPLD' ,NULL ,NULL ,FALSE);
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
    lc_exc_flag:=fnd_concurrent.set_completion_status('WARNING','Encountered an error while publishing the report.');
  END IF;
END PUBLISH_REPORT;

PROCEDURE XX_MAIN(
    errbuff OUT NOCOPY VARCHAR2,
    retcode OUT NOCOPY NUMBER)
IS
  --declarations
  ln_msg_count               NUMBER := 0;
  lc_msg_data                VARCHAR2(4000);
  lc_return_status           VARCHAR2(1);
  ln_pa_project_id_out       NUMBER;
  lc_pa_project_number_out   VARCHAR2(500);
  ln_pa_project_asset_id_out NUMBER;
  lc_pm_asset_reference_out  VARCHAR2 (500);
  lc_pa_project_id PA_PROJECTS_ALL.PROJECT_ID%TYPE;
  lc_pa_project_number PA_PROJECTS_ALL.SEGMENT1%TYPE;
  lc_pa_project_asset_id PA_PROJECT_ASSETS_ALL.PROJECT_ASSET_ID%TYPE;
  lc_pa_asset_name PA_PROJECT_ASSETS_ALL.ASSET_NAME%TYPE;
  lc_asset_description PA_PROJECT_ASSETS_ALL.ASSET_DESCRIPTION%TYPE;
  lc_project_asset_type PA_PROJECT_ASSETS_ALL.PROJECT_ASSET_TYPE%TYPE;
  lc_actual_date_in_service DATE;
  lc_parent_asset_id PA_PROJECT_ASSETS_ALL.PARENT_ASSET_ID%TYPE ;
  lc_asset_location FA_LOCATIONS.SEGMENT5%TYPE;
  lc_actual_asset_units PA_PROJECT_ASSETS_ALL.ASSET_UNITS%TYPE;
  lc_estimated_asset_units PA_PROJECT_ASSETS_ALL.ESTIMATED_ASSET_UNITS%TYPE;
  lc_major FA_CATEGORIES_B.SEGMENT1%TYPE;
  lc_minor FA_CATEGORIES_B.SEGMENT2%TYPE;
  lc_subminor FA_CATEGORIES_B.SEGMENT3%TYPE;
  lc_asset_category VARCHAR2(500);
  lc_asset_number PA_PROJECT_ASSETS_ALL.ASSET_NUMBER%TYPE;
  lc_parent_asset_number PA_PROJECT_ASSETS_ALL.ASSET_NUMBER%TYPE;
  lc_company GL_CODE_COMBINATIONS.SEGMENT1%TYPE;
  lc_cost_center GL_CODE_COMBINATIONS.SEGMENT2%TYPE;
  lc_Account GL_CODE_COMBINATIONS.SEGMENT3%TYPE;
  lc_location GL_CODE_COMBINATIONS.SEGMENT4%TYPE;
  lc_intercompany GL_CODE_COMBINATIONS.SEGMENT5%TYPE;
  lc_line_of_business GL_CODE_COMBINATIONS.SEGMENT6%TYPE;
  lc_future GL_CODE_COMBINATIONS.SEGMENT7%TYPE;
  lc_depreciation_string VARCHAR2(3000);
  lc_code_combination_id GL_CODE_COMBINATIONS.CODE_COMBINATION_ID%TYPE;
  lc_task_number PA_TASKS.TASK_NUMBER%TYPE;
  lc_asset_category_id PA_PROJECT_ASSETS_ALL.ASSET_CATEGORY_ID%TYPE;
  lc_asset_reference PA_PROJECT_ASSETS_ALL.PM_ASSET_REFERENCE%TYPE;
  lc_book_type_code PA_PROJECT_ASSETS_ALL.BOOK_TYPE_CODE%TYPE;
  lc_location_id NUMBER(15);
  lc_anumber_count NUMBER := 0;
  lc_data          VARCHAR2(3000);
  ln_msg_index_out NUMBER;
  ln_msg_index     NUMBER := 1;
  lc_success_count NUMBER := 0;
  lc_failure_count NUMBER := 0;
  lc_exc_flag       BOOLEAN := FALSE;
  lc_request_id FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE := 0;
  lc_rpt_rid FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE := 0;
  lc_exception_flag VARCHAR2(3):='N';
  lc_ccid_enabled_flag  VARCHAR2(3);
  lc_ccid_end_date DATE;
  lc_category_enabled_flag  VARCHAR2(3);
  lc_category_end_date DATE;
  lc_location_enabled_flag  VARCHAR2(3);
  lc_location_end_date DATE;

  rec_stg_data xx_pa_mass_upload_stg%ROWTYPE;
  TYPE rec_asset_details IS RECORD (project_number PA_PROJECTS_ALL.SEGMENT1%TYPE,asset_number PA_PROJECT_ASSETS_ALL.ASSET_NUMBER%TYPE,asset_name PA_PROJECT_ASSETS_ALL.ASSET_NAME%TYPE);
TYPE tbl_type_anumber
IS
  TABLE OF rec_asset_details INDEX BY BINARY_INTEGER;
  tbl_asset_details tbl_type_anumber;
  CURSOR cur_stg_data(p_project_number VARCHAR2,p_asset_number VARCHAR2, p_asset_name VARCHAR2)
  IS
    SELECT *
    FROM xx_pa_mass_upload_stg
    WHERE status    = 'I'
    AND project_number IS NOT NULL
    AND (asset_number IS NOT NULL OR asset_name IS NOT NULL)
    AND project_number=p_project_number
    AND NVL(asset_number,0)=NVL(p_asset_number,0)
    AND NVL(UPPER(asset_name),'')=NVL(UPPER(p_asset_name),'');

  CURSOR cur_anumber_list
  IS
    SELECT project_number,asset_number,asset_name
    FROM xx_pa_mass_upload_stg
    WHERE status = 'I'
    AND project_number IS NOT NULL
    AND (asset_number IS NOT NULL OR asset_name IS NOT NULL);
BEGIN
  --fetching the request ID for the current concurrent request.
  lc_request_id := FND_GLOBAL.CONC_REQUEST_ID;
  --Delete Old processed records
  DELETE
  FROM xx_pa_mass_upload_stg
  WHERE status IN ('P','E');
  --Delete any blank rows from the table
  DELETE
  FROM xx_pa_mass_upload_stg
  WHERE (TRIM(project_number) IS NULL
  AND TRIM(asset_name) IS NULL
  AND TRIM(project_asset_type) IS NULL
  AND TRIM(Date_In_Service_Estimated) IS NULL
  AND TRIM(Date_In_Service_Actual) IS NULL
  AND TRIM(book_type_code) IS NULL
  AND TRIM(major) IS NULL
  AND TRIM(minor) IS NULL
  AND TRIM(subminor) IS NULL
  AND TRIM(Asset_Category) IS NULL
  AND TRIM(Parent_Asset_Number) IS NULL
  AND TRIM(asset_number) IS NULL
  AND TRIM(asset_location) IS NULL
  AND TRIM(company) IS NULL
  AND TRIM(cost_center) IS NULL
  AND TRIM(account) IS NULL
  AND TRIM(location) IS NULL
  AND TRIM(intercompany) IS NULL
  AND TRIM(Line_of_Business) IS NULL
  AND TRIM(future) IS NULL
  AND TRIM(Depreciation_String) IS NULL
  AND TRIM(actual_units) IS NULL
  AND TRIM(Asset_Description) IS NULL
  AND TRIM(Task_Number) IS NULL);
  --Update status to E if either asset details or project_number is NULL
  UPDATE xx_pa_mass_upload_stg
  SET status = 'E',
  status_mesg = 'Error : The Project Number or Asset details are NULL',
  conc_req_id = lc_request_id
  WHERE project_number IS NULL OR (asset_number IS NULL AND asset_name IS NULL);
  --Remove special characters in the fields
  UPDATE XX_PA_MASS_UPLOAD_STG
SET PROJECT_NUMBER = REPLACE(REPLACE(REPLACE (PROJECT_NUMBER, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
  ASSET_LOCATION   = REPLACE(REPLACE(REPLACE (ASSET_LOCATION, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
  COMPANY          = REPLACE(REPLACE(REPLACE (COMPANY, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
  COST_CENTER      = REPLACE(REPLACE(REPLACE (COST_CENTER, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
  ACCOUNT          = REPLACE(REPLACE(REPLACE (ACCOUNT, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
  LOCATION         = REPLACE(REPLACE(REPLACE (LOCATION, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
  INTERCOMPANY     = REPLACE(REPLACE(REPLACE (INTERCOMPANY, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '') ,
  LINE_OF_BUSINESS = REPLACE(REPLACE(REPLACE (LINE_OF_BUSINESS, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), ''),
  FUTURE           = REPLACE(REPLACE(REPLACE (FUTURE, CHR(14844077), '' ),CHR(15712189), '') ,CHR(14844076), '')
WHERE 1            =1;
  COMMIT;
  OPEN cur_anumber_list; --Opening cursor to fetch count of eligible assets in the staging table.
  FETCH cur_anumber_list BULK COLLECT INTO tbl_asset_details;
  lc_anumber_count:=cur_anumber_list%ROWCOUNT;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of eligible assets : '||lc_anumber_count);
  IF lc_anumber_count=0 THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exiting the program since there are no assets eligible to be processed in the staging table.');
    --calling the report publisher procedure
  PUBLISH_REPORT();
    RETURN;
  END IF;
  FOR lc_counter IN 1..lc_anumber_count
  LOOP --begin FOR loop for asset_number checkpoint #1
    --open the cursor for asset details..
    OPEN cur_stg_data(tbl_asset_details(lc_counter).project_number,tbl_asset_details(lc_counter).asset_number,tbl_asset_details(lc_counter).asset_name);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening the cursor for asset details : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
    LOOP --opening loop for asset_number loop checkpoint# 2
      FETCH cur_stg_data INTO rec_stg_data;
      EXIT WHEN cur_stg_data%NOTFOUND;
    --fetch asset details to invoke API
    BEGIN --inner block1
      SELECT project_id
      INTO lc_pa_project_id
      FROM PA_PROJECTS_ALL
      WHERE segment1   = rec_stg_data.project_number;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'The project number : '||rec_stg_data.project_number||' is invalid.');
    UPDATE xx_pa_mass_upload_stg
    SET status_mesg     ='Error : The project number entered is invalid.',
        conc_req_id       = lc_request_id,
        status='E'
    WHERE project_number                = rec_stg_data.project_number
    AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
    AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
    COMMIT;
    lc_failure_count:=lc_failure_count+1;
    CONTINUE;
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in projects block - '||SUBSTR (SQLERRM, 1, 225)||' for asset details : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='Exception in projects block.',
          conc_req_id       = lc_request_id,
          status            = 'E'
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_failure_count:=lc_failure_count+1;
        lc_exception_flag:='Y';
        GOTO end_loop1;
    END; --inner block1
    BEGIN--inner block2
    --fetching asset details
      SELECT project_asset_id
      INTO lc_pa_project_asset_id
      FROM PA_PROJECT_ASSETS_ALL
      WHERE project_id                = lc_pa_project_id
      --AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0) --commented for defect# 25249
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error : Asset number/ name are invalid.');
        lc_failure_count:=lc_failure_count+1;
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='Error : Asset number/ name are invalid.',
            status          ='E',
          conc_req_id       = lc_request_id
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_failure_count:=lc_failure_count+1;
        CONTINUE;
	  WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in project-assets block - '||SUBSTR (SQLERRM, 1, 225)||' for asset details : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='Exception in project-assets block',
          conc_req_id       = lc_request_id,
          status            = 'E'
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_failure_count:=lc_failure_count+1;
        lc_exception_flag:='Y';
        GOTO end_loop1;
      END;--inner block2
      lc_parent_asset_id             := rec_stg_data.parent_asset_number;
      --deriving the CCid for the new code combination entered by the user
      BEGIN --inner block3
      ----Modified for defect# 25249---
        IF (TRIM(rec_stg_data.company) IS NULL
          AND TRIM(rec_stg_data.cost_center) IS NULL
          AND TRIM(rec_stg_data.account) IS NULL
          AND TRIM(rec_stg_data.location) IS NULL
          AND TRIM(rec_stg_data.intercompany) IS NULL
          AND TRIM(rec_stg_data.line_of_business) IS NULL
          AND TRIM(rec_stg_data.future) IS NULL) THEN --user has not provided a value 
          lc_code_combination_id:=NULL; --do nothing, pass NULL ccid to API
        ELSE
          SELECT code_combination_id,enabled_flag,end_date_active
          INTO lc_code_combination_id,lc_ccid_enabled_flag,lc_ccid_end_date
          FROM GL_CODE_COMBINATIONS
          WHERE segment1=rec_stg_data.company
          AND segment2  = rec_stg_data.cost_center
          AND segment3  = rec_stg_data.account
          AND segment4  = rec_stg_data.location
          AND segment5  = rec_stg_data.intercompany
          AND segment6  = rec_stg_data.line_of_business
          AND segment7  = rec_stg_data.future;
          IF (lc_ccid_enabled_flag='N') OR (lc_ccid_end_date IS NOT NULL AND lc_ccid_end_date < SYSDATE) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error : The code combination id is disabled.');
            UPDATE xx_pa_mass_upload_stg
            SET status_mesg     ='Error : The code combination id is disabled.',
            status          ='E',
            conc_req_id       = lc_request_id
            WHERE project_number                = rec_stg_data.project_number
            AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
            AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
            COMMIT;
            lc_failure_count:=lc_failure_count+1;
            CONTINUE;
          END IF;
        END IF;
         ----commented for defect# 25249---
          /*SELECT code_combination_id,enabled_flag,end_date_active
          INTO lc_code_combination_id,lc_ccid_enabled_flag,lc_ccid_end_date
          FROM GL_CODE_COMBINATIONS
          WHERE segment1=rec_stg_data.company
          AND segment2  = rec_stg_data.cost_center
          AND segment3  = rec_stg_data.account
          AND segment4  = rec_stg_data.location
          AND segment5  = rec_stg_data.intercompany
          AND segment6  = rec_stg_data.line_of_business
          AND segment7  = rec_stg_data.future;
          ----Added for defect# 25249---
        IF (lc_ccid_enabled_flag='N') OR (lc_ccid_end_date<>NULL AND lc_ccid_end_date < SYSDATE) THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'The code combination id is disabled.');
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='The code combination id is disabled.',
            status          ='E',
          conc_req_id       = lc_request_id
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_failure_count:=lc_failure_count+1;
        CONTINUE;
        END IF;*/
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error : The code combination id is invalid.');
          UPDATE xx_pa_mass_upload_stg
            SET status_mesg     ='Error : The code combination id is invalid.',
            status          ='E',
            conc_req_id       = lc_request_id
            WHERE project_number                = rec_stg_data.project_number
              AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
              AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
          COMMIT;
          lc_failure_count:=lc_failure_count+1;
          CONTINUE;
        --END IF; 
         ----commented for defect# 25249---
        /*FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error fetching code combination ID for asset details : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
        lc_failure_count:=lc_failure_count+1;
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='Error fetching Code Combination ID for asset.',
            status          ='E',
          conc_req_id       = lc_request_id
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        CONTINUE; --commented for defect# 25249*/
	  WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in code-combination block - '||SUBSTR (SQLERRM, 1, 225)||' for asset details : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='Exception in code-combination block.',
          conc_req_id       = lc_request_id,
          status            = 'E'
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_failure_count:=lc_failure_count+1;
        lc_exception_flag:='Y';
        GOTO end_loop1;
      END;--inner block3
      BEGIN--inner block4
       ----Modified for defect# 25249---
        --deriving asset_category_id for the combination of asset_categories provided by the user
        IF (TRIM(rec_stg_data.major) IS NULL
          AND TRIM(rec_stg_data.minor) IS NULL
          AND TRIM(rec_stg_data.subminor) IS NULL) THEN --user has not provided a value 
          lc_asset_category_id:=NULL; --do nothing, pass NULL asset_category_id to API
        ELSE
          SELECT category_id,enabled_flag,end_date_active
          INTO lc_asset_category_id,lc_category_enabled_flag,lc_category_end_date
          FROM FA_CATEGORIES_B
          WHERE UPPER(segment1) = UPPER(rec_stg_data.major)
          AND UPPER(segment2)   = UPPER(rec_stg_data.minor)
          AND UPPER(segment3)   = UPPER(rec_stg_data.subminor);
          IF (lc_category_enabled_flag='N') OR (lc_category_end_date IS NOT NULL AND lc_category_end_date < SYSDATE) THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error : The asset category is disabled.');
          UPDATE xx_pa_mass_upload_stg
          SET status_mesg     ='Error : The asset category is disabled.',
          status          ='E',
          conc_req_id       = lc_request_id
          WHERE project_number                = rec_stg_data.project_number
          AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
          AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
          COMMIT;
          lc_failure_count:=lc_failure_count+1;
          CONTINUE;
          END IF;
        END IF;
         ----commented for defect# 25249---
        /*IF (lc_category_enabled_flag='N') OR (lc_category_end_date<>NULL AND lc_category_end_date < SYSDATE) THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'The asset category id is disabled.');
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='The asset category id is disabled.',
            status          ='E',
          conc_req_id       = lc_request_id
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_failure_count:=lc_failure_count+1;
        CONTINUE;
        END IF;*/
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error : The asset category is invalid.');
          UPDATE xx_pa_mass_upload_stg
            SET status_mesg     ='Error : The asset category is invalid.',
            status          ='E',
            conc_req_id       = lc_request_id
            WHERE project_number                = rec_stg_data.project_number
              AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
              AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
          COMMIT;
          lc_failure_count:=lc_failure_count+1;
          CONTINUE;
           ----commented for defect# 25249---
        /*FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error fetching Asset Category ID for asset details : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='Error fetching Asset Category ID for asset.',
          conc_req_id       = lc_request_id,
          status            = 'E'
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_failure_count:=lc_failure_count+1;
        CONTINUE;*/ --commented for defect# 25249
	  WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in asset-category block - '||SUBSTR (SQLERRM, 1, 225)||' for asset details : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='Exception in asset-category block.',
          conc_req_id       = lc_request_id,
          status            = 'E'
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_failure_count:=lc_failure_count+1;
        lc_exception_flag:='Y';
        GOTO end_loop1;
      END;--inner block4
      BEGIN--inner block5
       ----Modified for defect# 25249---
        --deriving location_id for the asset_location provided by the user
        IF (TRIM(rec_stg_data.asset_location) IS NULL) THEN --user has not provided a value for asset location
        lc_location_id:=NULL;--do nothing, pass NULL asset location to API
        ELSE
          SELECT location_id,enabled_flag,end_date_active
          INTO lc_location_id,lc_location_enabled_flag,lc_location_end_date
          FROM FA_LOCATIONS
          WHERE segment5 = rec_stg_data.asset_location;
        IF (lc_location_enabled_flag='N') OR (lc_location_end_date IS NOT NULL AND lc_location_end_date < SYSDATE) THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error : The asset location is disabled.');
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='Error : The asset location is disabled.',
            status          ='E',
          conc_req_id       = lc_request_id
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_failure_count:=lc_failure_count+1;
        CONTINUE;
        END IF;
      END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error : The asset location is invalid.');
          UPDATE xx_pa_mass_upload_stg
            SET status_mesg     ='Error : The asset location is invalid.',
            status          ='E',
            conc_req_id       = lc_request_id
            WHERE project_number                = rec_stg_data.project_number
              AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
              AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
          COMMIT;
          lc_failure_count:=lc_failure_count+1;
          CONTINUE;
          ----commented for defect# 25249---
        /*FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error fetching Asset Location ID for asset details : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='Error fetching Asset Location ID for asset.',
          conc_req_id       = lc_request_id,
          status            = 'E'
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_failure_count:=lc_failure_count+1;
        CONTINUE;*/ --commented for defect# 25249
	  WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in asset-location block - '||SUBSTR (SQLERRM, 1, 225)||' for asset details : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
        UPDATE xx_pa_mass_upload_stg
        SET status_mesg     ='Exception in asset-location block.',
          conc_req_id       = lc_request_id,
          status            = 'E'
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_failure_count:=lc_failure_count+1;
        lc_exception_flag:='Y';
        GOTO end_loop1;
      END;--inner block5
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling the API for asset : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);

      PA_PROJECT_ASSETS_PUB.update_project_asset(
      p_api_version_number =>1.0,
      p_commit =>FND_API.G_FALSE,
      p_init_msg_list => FND_API.G_TRUE,
      p_msg_count =>ln_msg_count,
      p_msg_data =>lc_msg_data,
      p_return_status =>lc_return_status,
      p_pa_project_id=>lc_pa_project_id,
      p_pa_project_asset_id=>lc_pa_project_asset_id,
      p_pm_product_code=>'EJM',
      P_PM_PROJECT_REFERENCE=>rec_stg_data.project_number,
      P_PM_ASSET_REFERENCE=>rec_stg_data.asset_number,
      P_PA_ASSET_NAME=>rec_stg_data.asset_name,
      P_ASSET_NUMBER=>rec_stg_data.asset_number,
      P_PROJECT_ASSET_TYPE=>UPPER(rec_stg_data.project_asset_type),
      p_estimated_in_service_date=>rec_stg_data.date_in_service_estimated,
      p_date_placed_in_service=>rec_stg_data.Date_In_Service_Actual,
      p_book_type_code=>rec_stg_data.book_type_code,
      p_asset_category_id=>lc_asset_category_id,
      p_parent_asset_id=>lc_parent_asset_id,
      p_location_id=>lc_location_id,
      p_depreciation_expense_ccid=>lc_code_combination_id,
      p_asset_units=>rec_stg_data.Actual_Units,
      P_ASSET_DESCRIPTION=>rec_stg_data.asset_description,
      p_pa_project_id_out =>ln_pa_project_id_out,
      p_pa_project_number_out =>lc_pa_project_number_out,
      p_pa_project_asset_id_out =>ln_pa_project_asset_id_out,
      p_pm_asset_reference_out =>lc_pm_asset_reference_out);
      --check for the status of the API update..
      IF lc_return_status = 'S' THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Update successful for asset : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
        lc_success_count:=lc_success_count+1;
        UPDATE xx_pa_mass_upload_stg
        SET status         = 'P',
          status_mesg       = 'Processed : Asset update successful!',
          conc_req_id     = lc_request_id
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Update failed for asset : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
        lc_failure_count:=lc_failure_count+1;
        --set status to E for the asset in the upload staging table.
        UPDATE xx_pa_mass_upload_stg
        SET status         = 'E',
        conc_req_id     = lc_request_id
        WHERE project_number                = rec_stg_data.project_number
        AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
        COMMIT;
        lc_data:=' '; --initializing
        lc_msg_data:= ' ';
        IF ln_msg_count>0 THEN
          FOR I  IN 1..LN_MSG_COUNT
          LOOP
            PA_INTERFACE_UTILS_PUB.GET_MESSAGES(
            P_MSG_DATA => LC_MSG_DATA,
            P_ENCODED => 'F',
            P_DATA => LC_DATA,
            P_MSG_COUNT => LN_MSG_COUNT,
            P_MSG_INDEX => LN_MSG_INDEX,
            P_MSG_INDEX_OUT => LN_MSG_INDEX_OUT);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error ' || ln_msg_index || ': ' ||lc_data);
            UPDATE xx_pa_mass_upload_stg
            SET status_mesg     = 'Error: '||lc_data
            WHERE project_number                = rec_stg_data.project_number
            AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
      AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
            COMMIT;
          END LOOP;
        END IF;
      END IF;
      COMMIT;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'COMPLETED processing for asset : '||tbl_asset_details(lc_counter).project_number||'-'||tbl_asset_details(lc_counter).asset_number||'- '||tbl_asset_details(lc_counter).asset_name);
    END LOOP;           --closing loop for asset_number loop checkpoint# 2
   <<end_loop1>> --label marking exit of inner loop iteration.
   CLOSE cur_stg_data; --closing the cursor for asset details..
  END LOOP;             --closing FOR loop checkpoint #1

  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Completed processing all the eligible assets from the staging table');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of assets successfully updated : '||lc_success_count);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of assets not updated : '||lc_failure_count);
  CLOSE cur_anumber_list;
  IF lc_exception_flag='Y' THEN
  lc_exc_flag:=fnd_concurrent.set_completion_status('WARNING','Concurrent request encountered an error.Please refer to log file for details.');
  COMMIT;
  END IF;
  --calling the report publisher procedure
  PUBLISH_REPORT();
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Encountered the exception while processing the asset : '||rec_stg_data.asset_number||' -> ' ||SUBSTR (SQLERRM, 1, 225) );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'End Time: ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH:MI:SS AM') );
  UPDATE xx_pa_mass_upload_stg
    SET status         = 'E',
    conc_req_id     = lc_request_id,
    status_mesg       = 'Encountered an exception.'
    WHERE project_number                = rec_stg_data.project_number
    AND NVL(asset_number,0)                = NVL(rec_stg_data.asset_number,0)
    AND NVL(asset_name,'')           = NVL(rec_stg_data.asset_name,'');
  COMMIT;
  PUBLISH_REPORT();
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Request : '||lc_request_id||' completed in error. Please refer to log file for more details.');
  lc_exc_flag:=fnd_concurrent.set_completion_status('ERROR','Concurrent request encountered an error.Please refer to log file for details.');
  COMMIT;
END XX_MAIN;

END XX_OD_PA_CPTL_UPLD_PKG;
/
