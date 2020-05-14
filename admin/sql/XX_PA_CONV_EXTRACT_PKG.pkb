SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE BODY XX_PA_CONV_EXTRACT_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_PA_CONV_EXTRACT_PKG                                                           |
  -- |                                                                                            |
  -- |  Description:Scripts for FA conversion   |
  -- |  RICE ID   :                |
  -- |  Description:           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         01-JUL-2019   Priyam S           Initial Version  added       
 --  | 1.1         25-SEP-19     Priyam S           Changes done in FBDI_PA_BUDGETS Quanity column to null
 --  | 1.2         28-SEP-19     Priyam S           Changes done to xx_gl_beacon_mapping function
 --  | 1.3         11-NOV-19     Paddy          Changes done to Transaction_source in Project Expenditure procedures
 --  | 1.4         30-JAN-20     Paddy          Modified fbdi_proj_team_members procedure         |
 --  | 1.5         11-FEB-20     Pramod         Changes done to Extract Project Fixed Assets and Asset Assignments for YY and YN
 --  | 1.6         26-FEB-20     Paddy          Added Attribute Category for projects extract
 --  | 1.7         03-MAR-20     Paddy          Modified for team members                         |
  -- +============================================================================================|
  -- +============================================================================================|
  gc_debug        VARCHAR2(2)     := 'N';
  gc_max_log_size CONSTANT NUMBER := 2000;
  gc_coa          VARCHAR2(100)   :='1150.13.60310.741101.00043.0000';
  gc_entity       VARCHAR2(10)    :='1150';
  gc_lob          VARCHAR2(10)    :='13';
  gc_costcenter   VARCHAR2(10)    :='60310';
  gc_location     VARCHAR2(10)    :='00043';
  gc_ic           VARCHAR2(10)    :='0000';
  gc_account      VARCHAR2(10)    :='741101';
PROCEDURE print_debug_msg(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  IF (gc_debug  = 'Y' OR p_force) THEN
    lc_message := p_message;
    fnd_file.put_line (fnd_file.LOG, lc_message);
    IF ( fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
      dbms_output.put_line (lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_debug_msg;
/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE print_out_msg(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  lc_message := p_message;
  fnd_file.put_line (fnd_file.output, lc_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    dbms_output.put_line (lc_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_out_msg;
/*********************************************************************
* Procedure used to print output based on if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.  Will prepend
*********************************************************************/
PROCEDURE print_output(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT True)
IS
  lc_message VARCHAR2(2000) := NULL;
BEGIN
  --if debug is on (defaults to true)
  IF p_force THEN
    lc_message                    := SUBSTR(p_message, 1, gc_max_log_size);
    IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.output, lc_message);
    ELSE
      DBMS_OUTPUT.put_line(lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_output;

FUNCTION xx_gl_beacon_mapping_f1(
    p_source VARCHAR2,
    p_type   VARCHAR2,
    p_flag   VARCHAR2)
  RETURN VARCHAR2
IS
  CURSOR c_map
  IS
    SELECT source,
      target,
      type
    FROM xx_gl_beacon_mapping
    WHERE source=p_source
    AND type    =p_type;
  CURSOR c_concat
  IS
    SELECT regexp_substr(p_source, '[^.]+', 1, 1) entity,
      regexp_substr(p_source, '[^.]+', 1, 2) cost_center,
      regexp_substr(p_source, '[^.]+', 1, 3) account,
      regexp_substr(p_source, '[^.]+', 1, 4) location,
      regexp_substr(p_source, '[^.]+', 1, 5) inter_company,	  
      regexp_substr(p_source, '[^.]+', 1, 6) lob
    FROM dual;
  v_target       VARCHAR2(100);
  v_entity       VARCHAR2(50);
  v_cost_center  VARCHAR2(50);
  v_account      VARCHAR2(50);
  v_location     VARCHAR2(50);
  v_intercompany VARCHAR2(50);
  v_lob          VARCHAR2(50);
  ERR_MSG        VARCHAR2(2000);
BEGIN
  IF p_source IS NOT NULL THEN
    IF p_flag  ='A' THEN
      BEGIN
        FOR i IN c_map
        LOOP
          v_target:=i.target;
        END LOOP;
      EXCEPTION
      WHEN OTHERS THEN
        --v_target:=p_source;
        v_target:=NULL;
      END;
    ELSE

      FOR i IN c_concat
      LOOP
        ERR_MSG:=null;
	    v_target    	:=NULL;
		v_entity       	:=NULL;
		v_cost_center  	:=NULL;
		v_account      	:=NULL;
		v_location     	:=NULL;
		v_intercompany 	:=NULL;
		v_lob          	:=NULL;
	  
        BEGIN
          SELECT target
          INTO v_entity
          FROM xx_gl_beacon_mapping
          WHERE source=i.entity
          AND type    ='ENTITY';
        EXCEPTION
        WHEN OTHERS THEN
          --v_entity:=i.entity;
          v_entity:=NULL;
          ERR_MSG:=ERR_MSG||' Missing Entity '||i.entity;
        END;
        BEGIN
          SELECT target
          INTO v_cost_center
          FROM xx_gl_beacon_mapping
          WHERE source=i.cost_center
          AND type    ='COST_CENTER';
        EXCEPTION
        WHEN OTHERS THEN
          --v_cost_center:=i.cost_center;
          v_cost_center:=NULL;
           ERR_MSG:=ERR_MSG||' Missing Cost Center '||i.cost_center;
        END;
        BEGIN
          SELECT target
          INTO v_account
          FROM xx_gl_beacon_mapping
          WHERE source=i.account
          AND type    ='ACCOUNT';
        EXCEPTION
        WHEN OTHERS THEN
          --v_account:=i.account;
          v_account:=NULL;
           ERR_MSG:=ERR_MSG||' Missing Account '||i.account;
        END;
        BEGIN
          SELECT target
          INTO v_location
          FROM xx_gl_beacon_mapping
          WHERE source=i.location
          AND type    ='LOCATION';
        EXCEPTION
        WHEN OTHERS THEN
          --v_location:=i.location;
          v_location:='10000';
        END;
        BEGIN
          SELECT target
          INTO v_lob
          FROM xx_gl_beacon_mapping
          WHERE source=i.lob
          AND type    ='LOB';
        EXCEPTION
        WHEN OTHERS THEN
          --v_lob:=i.lob;
          v_lob:=NULL;
           ERR_MSG:=ERR_MSG||' Missing LOB '||i.lob;
        END;

        BEGIN
          SELECT target
          INTO v_intercompany
          FROM xx_gl_beacon_mapping
          WHERE source=i.inter_company
          AND type    ='ENTITY';
        EXCEPTION
        WHEN OTHERS THEN
          v_intercompany:=NULL;
           ERR_MSG:=ERR_MSG||' Missing Intercompany'||i.inter_company;
        END;
     
      END LOOP;
      
      IF ERR_MSG is not null then 
          print_debug_msg ('Missing CTU Information details: '||ERR_MSG, true);
          print_debug_msg ('Original String for Missing CTU is : '||p_source||CHR(13)||CHR(10), true);
      
      END IF;
    
      v_target:=v_entity||'.'||v_lob||'.'||v_cost_center||'.'||v_account||'.'||v_location||'.'||v_intercompany;
    END IF;
    RETURN v_target;
  ELSE
    RETURN p_source;
  END IF;/*
  Change Location null to 10000
  Print Log in each exception for Source which got failed and atlast print the Original string.
  */
END xx_gl_beacon_mapping_f1;

PROCEDURE fbdi_project_assets
  (
    p_proj_template VARCHAR2
  )
IS
  CURSOR c_fbdi_project_assets
  IS
    SELECT
      'Demo_create' demo_create,
      'Create' create_mode,
      NULL project_id,
      trim(REPLACE(REPLACE(REPLACE(REPLACE(proj.name,chr(13), ''), chr(10), '')
      ,chr(39),''),chr(63),'')) project_name,
      proj.segment1 project_number,
      ppa.project_asset_type,
      NULL project_asset_id,
      ppa.asset_name,
      ppa.asset_number,
      REPLACE(REPLACE(REPLACE(REPLACE(ppa.asset_description,chr(13), '' ), chr(
      10), ''),chr(39),''),chr(63),'') asset_description,
      TO_CHAR(ppa.estimated_in_service_date,'YYYY/MM/DD')
      estimated_in_service_date,
      TO_CHAR(ppa.date_placed_in_service,'YYYY/MM/DD') date_placed_in_service,
      ppa.reverse_flag,
      ppa.capital_hold_flag,
      ppa.book_type_code,
      NULL asset_category_id,
      (
        SELECT
          segment1
          || '.'
          || segment2
          || '.'
          || segment3
        FROM
          fa_categories
        WHERE
          category_id = ppa.asset_category_id
      )
    asset_category,
    NULL asset_key_ccid,
    NULL asset_key,
    --(
    --select replace(segment1 || '.' || segment2 || '.' || segment3,'..','')
    --  from fa_asset_keywords
    --  where code_combination_id = ppa.asset_key_ccid
    --)  asset_key,
    ppa.asset_units,
    ppa.estimated_cost,
    ppa.estimated_asset_units,
    NULL location_id,
    /* (SELECT segment1
    || '.'
    || segment2
    || '.'
    || segment3
    || '.'
    || segment4
    || '.'
    || segment5
    || '.'
    || segment6
    FROM fa_locations
    WHERE location_id = ppa.location_id
    )*/
    ---Commneted by Priyam
    (
      SELECT
        segment1
        || '.'
        || segment2
        || '.'
        || segment3
        || '.'
        || segment4
        || '.'
        || segment6
        || '.'
        || SUBSTR(segment5,2)
      FROM
        fa_locations
      WHERE
        location_id = ppa.location_id
    )
    location,
    -- per.full_name,        --(Add Fetch)
    ppa.assigned_to_person_id,
    (
      SELECT
        paf.full_name
      FROM
        per_all_people_f paf
      WHERE
        paf.person_id = ppa.assigned_to_person_id
      AND TRUNC(sysdate) BETWEEN paf.effective_start_date AND
        paf.effective_end_date
    )
    assigned_to_person_name,
    (
      SELECT
        paf.employee_number
      FROM
        per_all_people_f paf
      WHERE
        paf.person_id = ppa.assigned_to_person_id
      AND TRUNC(sysdate) BETWEEN paf.effective_start_date AND
        paf.effective_end_date
    )
    assigned_to_person_number,
    ppa.depreciate_flag,
    NULL depreciation_expense_ccid,
    /*Commented by Priyam for EBS to Cloud segment Change
    (
    CASE
    WHEN (ppa.depreciate_flag          = 'Y'
    AND ppa.depreciation_expense_ccid IS NULL
    AND project_status_code           IN ('1000','CLOSED'))
    THEN ( '1001.43002.73802000.010000.0000.10.000000' )
    ELSE
    (SELECT concatenated_segments
    FROM gl_code_combinations_kfv
    WHERE code_combination_id = ppa.depreciation_expense_ccid
    )
    END ) depreciation_expense_account,*/
    ---Added by Priyam for EBS to Cloud segment Change
    nvl((
      CASE
        WHEN
          (
            ppa.depreciate_flag              = 'Y'
          AND ppa.depreciation_expense_ccid IS NULL
          AND project_status_code           IN ('1000','CLOSED')
          )
        THEN (xx_gl_beacon_mapping_f1(
          '1001.43002.73802000.010000.0000.10.000000',NULL,'P'))
        ELSE
          (
            SELECT
              xx_gl_beacon_mapping_f1(concatenated_segments,NULL,'P')
            FROM
              gl_code_combinations_kfv
            WHERE
              code_combination_id = ppa.depreciation_expense_ccid
          )
      END ),'1150.12.60310.741107.10000.0000') depreciation_expense_account,
    ---Changes end
    ppa.amortize_flag,
    NULL overridecategoryanddesc,
    NULL business_unit_id,
    NULL parent_asset_id,
    (
      SELECT
        asset_number
      FROM
        fa_additions_b fab
      WHERE
        asset_id = ppa.parent_asset_id
    )
    parent_asset_number,
    ppa.manufacturer_name,
    ppa.model_number,
    ppa.tag_number,
    ppa.serial_number,
    NULL ret_target_asset_id,
    (
      SELECT
        asset_number
      FROM
        fa_additions_b fab
      WHERE
        asset_id = ppa.ret_target_asset_id
    )
    ret_target_asset_number,
    ppa.pm_product_code
  FROM
    pa_project_assets_all ppa,
    pa_projects_all proj
  WHERE
    1                               =1
  AND proj.template_flag            = 'N'
  AND NVL(proj.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
  AND
    (
      proj.segment1 NOT LIKE 'PB%'
    AND proj.segment1 NOT LIKE 'NB%'
    AND proj.segment1 NOT LIKE 'TEM%'
    )
  AND proj.project_type NOT IN ('PB_PROJECT','DI_PB_PROJECT')
  AND project_status_code   IN ('APPROVED','CLOSED','1000')
  AND proj.org_id           <>403
  AND proj.project_id        = ppa.project_id
  AND ppa.project_asset_type = 'ESTIMATED'
    -- Begin Added for pstgb
  AND proj.created_from_project_id IN
    (
      SELECT
        project_id
      FROM
        pa_projects_all
      WHERE
        template_flag='Y'
      AND name       =NVL(p_proj_template,name)---'US IT Template - Labor Only'
    )
    -- End added for PSTGB
  ORDER BY
    proj.segment1;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  lc_location VARCHAR2(100):='US.FL.PALM BEACH.DELRAY BEACH.33445.10000';
BEGIN
  /* BEGIN
  SELECT directory_path
  INTO l_file_path
  FROM dba_directories
  WHERE directory_name = 'XXFIN_OUTBOUND';
  EXCEPTION
  WHEN OTHERS THEN
  l_file_path := NULL;
  END;*/
  print_debug_msg ('Package FBDI_PROJECT_ASSETS START', true);
  ---  print_debug_msg ('P_BOOK_TYPE_CODE '||P_BOOK_TYPE_CODE, TRUE);
  l_file_name    := 'fbdi_project_assets' || '.csv';
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='DEMO_CREATE'|| ','|| 'CREATE_MODE'|| ','|| 'PROJECT_ID'||
  ','|| 'PROJECT_NAME'|| ','|| 'PROJECT_NUMBER'|| ','|| 'PROJECT_ASSET_TYPE'||
  ','|| 'PROJECT_ASSET_ID'|| ','|| 'ASSET_NAME'|| ','|| 'ASSET_NUMBER'|| ','||
  'ASSET_DESCRIPTION'|| ','|| 'ESTIMATED_IN_SERVICE_DATE'|| ','||
  'DATE_PLACED_IN_SERVICE'|| ','|| 'REVERSE_FLAG'|| ','|| 'CAPITAL_HOLD_FLAG'||
  ','|| 'BOOK_TYPE_CODE'|| ','|| 'ASSET_CATEGORY_ID'|| ','|| 'ASSET_CATEGORY'||
  ','|| 'ASSET_KEY_CCID'|| ','|| 'ASSET_KEY'|| ','|| 'ASSET_UNITS'|| ','||
  'ESTIMATED_COST'|| ','|| 'ESTIMATED_ASSET_UNITS'|| ','|| 'LOCATION_ID'|| ','
  || 'LOCATION'|| ','|| 'ASSIGNED_TO_PERSON_ID'|| ','||
  'ASSIGNED_TO_PERSON_NAME'|| ','|| 'ASSIGNED_TO_PERSON_NUMBER'|| ','||
  'DEPRECIATE_FLAG'|| ','|| 'DEPRECIATION_EXPENSE_CCID'|| ','||
  'DEPRECIATION_EXPENSE_ACCOUNT'|| ','|| 'AMORTIZE_FLAG'|| ','||
  'OVERRIDECATEGORYANDDESC'|| ','|| 'BUSINESS_UNIT_ID'|| ','||
  'PARENT_ASSET_ID'|| ','|| 'PARENT_ASSET_NUMBER'|| ','|| 'MANUFACTURER_NAME'||
  ','|| 'MODEL_NUMBER'|| ','|| 'TAG_NUMBER'|| ','|| 'SERIAL_NUMBER'|| ','||
  'RET_TARGET_ASSET_ID'|| ','|| 'RET_TARGET_ASSET_NUMBER'|| ','||
  'PM_PRODUCT_CODE';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_fbdi_project_assets
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,'"'||i.demo_create|| '","'|| i.create_mode
    || '","'|| i.project_id|| '","'|| i.project_name|| '","'|| i.project_number
    || '","'|| i.project_asset_type|| '","'|| i.project_asset_id|| '","'||
    i.asset_name|| '","'|| i.asset_number|| '","'|| i.asset_description|| '","'
    || i.estimated_in_service_date|| '","'|| i.date_placed_in_service|| '","'||
    i.reverse_flag|| '","'|| i.capital_hold_flag|| '","'|| i.book_type_code||
    '","'|| i.asset_category_id|| '","'|| i.asset_category|| '","'||
    i.asset_key_ccid|| '","'|| i.asset_key|| '","'|| i.asset_units|| '","'||
    i.estimated_cost|| '","'|| i.estimated_asset_units|| '","'|| i.location_id
    || '","'|| NVL(i.location,lc_location)|| '","'|| i.assigned_to_person_id|| '","'||
    i.assigned_to_person_name|| '","'|| i.assigned_to_person_number|| '","'||
    i.depreciate_flag|| '","'|| i.depreciation_expense_ccid|| '","'||
    i.depreciation_expense_account|| '","'|| i.amortize_flag|| '","'||
    i.overridecategoryanddesc|| '","'|| i.business_unit_id|| '","'||
    i.parent_asset_id|| '","'|| i.parent_asset_number|| '","'||
    i.manufacturer_name|| '","'|| i.model_number|| '","'|| i.tag_number|| '","'
    || i.serial_number|| '","'|| i.ret_target_asset_id|| '","'||
    i.ret_target_asset_number|| '","'|| i.pm_product_code||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
  ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_project_assets;


PROCEDURE fbdi_project_assets_yn(p_proj_template VARCHAR2)
IS

CURSOR c_fbdi_project_assets_yn
IS
SELECT DISTINCT
      'Create' create_mode,
      proj.segment1 project_number,
      ppa.project_asset_type,
      ppa.asset_number,
      REPLACE(REPLACE(REPLACE(REPLACE(ppa.asset_description,chr(13), '' ), chr(10), ''),chr(39),''),chr(63),'') asset_description,
      TO_CHAR(ppa.estimated_in_service_date,'YYYY/MM/DD') estimated_in_service_date,
      TO_CHAR(ppa.date_placed_in_service,'YYYY/MM/DD') date_placed_in_service,
      'N' reverse_flag,
      ppa.book_type_code,
      NULL asset_category_id,
      (
        SELECT
          segment1
          || '.'
          || segment2
          || '.'
          || segment3
        FROM
          fa_categories
        WHERE
          category_id = ppa.asset_category_id
      )
      asset_category,
      NULL asset_key_ccid,
      NULL asset_key,
      ppa.asset_units,
      NULL estimated_cost,
      NULL estimated_asset_units,
      NULL location_id,
      (
      SELECT
        segment1
        || '.'
        || segment2
        || '.'
        || segment3
        || '.'
        || segment4
        || '.'
        || segment6
        || '.'
        || SUBSTR(segment5,2)
      FROM
        fa_locations
      WHERE
        location_id = ppa.location_id
      )
      location,
      -- per.full_name,        --(Add Fetch)
      NULL assigned_to_person_id,
      NULL assigned_to_person_name,
      NULL assigned_to_person_number,
      ppa.depreciate_flag,
      NULL depreciation_expense_ccid,
      ---Added by Priyam for EBS to Cloud segment Change
      nvl((
      CASE
        WHEN
          (
            ppa.depreciate_flag              = 'Y'
          AND ppa.depreciation_expense_ccid IS NULL
          AND project_status_code           IN ('1000','CLOSED')
          )
        THEN (xx_gl_beacon_mapping_f1(
          '1001.43002.73802000.010000.0000.10.000000',NULL,'P'))
        ELSE
          (
            SELECT
              xx_gl_beacon_mapping_f1(concatenated_segments,NULL,'P')
            FROM
              gl_code_combinations_kfv
            WHERE
              code_combination_id = ppa.depreciation_expense_ccid
          )
      END ),'1150.12.60310.741107.10000.0000') depreciation_expense_account,
      ---Changes end
      ppa.amortize_flag,
     (
      SELECT
        asset_number
      FROM
        fa_additions_b fab
      WHERE
        asset_id = ppa.parent_asset_id
     )
    parent_asset_number	  ,
      NULL overridecategoryanddesc,
      NULL business_unit_id,
      NULL parent_asset_id,
      NULL manufacturer_name,
      NULL model_number,
      NULL tag_number,
      NULL serial_number,
      NULL ret_target_asset_id,
      NULL ret_target_asset_number,
      NULL pm_product_code,
	  NULL pm_asset_reference    ,
      NULL ATTRIBUTE_CATEGORY    ,
      NULL ATTRIBUTE1            ,
      NULL ATTRIBUTE2            ,
      NULL ATTRIBUTE3            ,
      NULL ATTRIBUTE4            ,
      NULL ATTRIBUTE5            ,
      NULL ATTRIBUTE6            ,
      NULL ATTRIBUTE7            ,
      NULL ATTRIBUTE8            ,
      NULL ATTRIBUTE9            ,
      NULL ATTRIBUTE10           ,
      NULL ATTRIBUTE11           ,
      NULL ATTRIBUTE12           ,
      NULL ATTRIBUTE13           ,
      NULL ATTRIBUTE14           ,
      NULL ATTRIBUTE15           ,
      NULL capital_event_id      ,
      NULL capital_event_name    ,
      NULL capital_event_number  
  FROM pa_project_assets_all ppa,
       pa_tasks tsk,
       pa_projects_all proj
 WHERE 1=1
   AND proj.template_flag            = 'N'
   AND NVL(proj.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
   AND (
		    proj.segment1 NOT LIKE 'PB%'
		AND proj.segment1 NOT LIKE 'NB%'
		AND proj.segment1 NOT LIKE 'TEM%'
	   )
   AND proj.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
   AND proj.project_status_code IN ('APPROVED','CLOSED','1000')
   AND proj.org_id              <>403
   AND tsk.project_id          = proj.project_id
   AND tsk.billable_flag='Y'
   AND proj.created_from_project_id IN  (SELECT project_id
										  FROM pa_projects_all
										 WHERE template_flag='Y'
										   AND name=NVL(p_proj_template,name)
									   )
   AND ppa.project_id=proj.project_id
   AND ppa.project_asset_type = 'ESTIMATED'	  
ORDER 
   BY proj.segment1;
  
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  lc_location VARCHAR2(100):='US.FL.PALM BEACH.DELRAY BEACH.33445.10000';
  lv_proj_level_flg varchar2(1):='N';
  lv_text varchar2(1):=NULL;
BEGIN

  print_debug_msg ('Package fbdi_project_assets_yn START', true);
  l_file_name    := 'fbdi_project_assets_yn' || '.csv';
  
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='DEMO_CREATE'|| ','|| 'CREATE_MODE'|| ','|| 'PROJECT_ID'||
  ','|| 'PROJECT_NAME'|| ','|| 'PROJECT_NUMBER'|| ','|| 'PROJECT_ASSET_TYPE'||
  ','|| 'PROJECT_ASSET_ID'|| ','|| 'ASSET_NAME'|| ','|| 'ASSET_NUMBER'|| ','||
  'ASSET_DESCRIPTION'|| ','|| 'ESTIMATED_IN_SERVICE_DATE'|| ','||
  'DATE_PLACED_IN_SERVICE'|| ','|| 'REVERSE_FLAG'|| ','|| 'CAPITAL_HOLD_FLAG'||
  ','|| 'BOOK_TYPE_CODE'|| ','|| 'ASSET_CATEGORY_ID'|| ','|| 'ASSET_CATEGORY'||
  ','|| 'ASSET_KEY_CCID'|| ','|| 'ASSET_KEY'|| ','|| 'ASSET_UNITS'|| ','||
  'ESTIMATED_COST'|| ','|| 'ESTIMATED_ASSET_UNITS'|| ','|| 'LOCATION_ID'|| ','
  || 'LOCATION'|| ','|| 'ASSIGNED_TO_PERSON_ID'|| ','||
  'ASSIGNED_TO_PERSON_NAME'|| ','|| 'ASSIGNED_TO_PERSON_NUMBER'|| ','||
  'DEPRECIATE_FLAG'|| ','|| 'DEPRECIATION_EXPENSE_CCID'|| ','||
  'DEPRECIATION_EXPENSE_ACCOUNT'|| ','|| 'AMORTIZE_FLAG'|| ','||
  'OVERRIDECATEGORYANDDESC'|| ','|| 'BUSINESS_UNIT_ID'|| ','||
  'PARENT_ASSET_ID'|| ','|| 'PARENT_ASSET_NUMBER'|| ','|| 'MANUFACTURER_NAME'||
  ','|| 'MODEL_NUMBER'|| ','|| 'TAG_NUMBER'|| ','|| 'SERIAL_NUMBER'|| ','||
  'RET_TARGET_ASSET_ID'|| ','|| 'RET_TARGET_ASSET_NUMBER'|| ','||
  'PM_PRODUCT_CODE';
  --utl_file.put_line(lc_file_handle,lv_col_title); commenting column as it is not required for FBDI Load
  
  FOR i IN c_fbdi_project_assets_yn
  LOOP
    utl_file.put_line(lc_file_handle, '"'||'YN_ASSET'||
    '","'|| i.create_mode||
    '","'|| lv_text||
    '","'|| lv_text||
    '","'|| i.project_number||
    '","'|| i.project_asset_type||
    '","'|| lv_text||
    '","'|| i.asset_description||
    '","'|| i.asset_number||
    '","'|| i.asset_description||
    '","'|| i.estimated_in_service_date||
    '","'|| i.date_placed_in_service||
    '","'||i.reverse_flag||
    '","'|| lv_text||
    '","'|| i.book_type_code||
    '","'|| i.asset_category_id||
    '","'|| i.asset_category||
    '","'|| i.asset_key_ccid||
    '","'|| i.asset_key||
    '","'|| i.asset_units||
    '","'|| i.estimated_cost||
    '","'|| i.estimated_asset_units||
    '","'|| i.location_id ||
    '","'|| NVL(i.location,lc_location)||
    '","'|| i.assigned_to_person_id||
    '","'|| i.assigned_to_person_name||
    '","'|| i.assigned_to_person_number||
    '","'|| i.depreciate_flag||
    '","'|| i.depreciation_expense_ccid||
    '","'|| i.depreciation_expense_account||
    '","'|| i.amortize_flag|| 
    '","'|| i.overridecategoryanddesc||
    '","'|| i.business_unit_id||
    '","'|| i.parent_asset_id||
    '","'|| i.parent_asset_number||
    '","'|| i.manufacturer_name||
    '","'|| i.model_number||
    '","'|| i.tag_number||
    '","'|| i.serial_number||
    '","'|| i.ret_target_asset_id||
    '","'||i.ret_target_asset_number||
    '","'|| i.pm_product_code||
    '"'|| i.pm_asset_reference||
    '"'|| i.ATTRIBUTE_CATEGORY||
    '","'|| i.ATTRIBUTE1||
    '","'|| i.ATTRIBUTE2||
    '","'|| i.ATTRIBUTE3||
    '","'|| i.ATTRIBUTE4||
    '","'|| i.ATTRIBUTE5||
    '","'|| i.ATTRIBUTE6||
    '","'|| i.ATTRIBUTE7||
    '","'|| i.ATTRIBUTE8||
    '","'|| i.ATTRIBUTE9||
    '","'|| i.ATTRIBUTE10||
    '","'|| i.ATTRIBUTE11||
    '","'|| i.ATTRIBUTE12||
    '","'|| i.ATTRIBUTE13||
    '","'|| i.ATTRIBUTE14||
    '","'|| i.ATTRIBUTE15|| 
    '","'|| i.capital_event_id||
    '","'|| i.capital_event_name||
    '","'|| i.capital_event_number||
    '","'|| 'END'||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
  WHEN utl_file.access_denied THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.delete_failed THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.file_open THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.internal_error THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filehandle THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure:- ' ||
    ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filename THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_maxlinesize THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_mode THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_offset THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_operation THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_path THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.read_error THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.rename_failed THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.write_error THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
END fbdi_project_assets_yn;

PROCEDURE fbdi_proj_asset_assignments_yn(p_proj_template VARCHAR2)
IS
 
CURSOR c_proj_asset_assign_yn
IS
SELECT DISTINCT
       'YN_ASSET' demo_create,
       'Create' create_mode,
       ppa.asset_name asset_name,
       'Task Level Assignment' asset_assigment_level,
       prj.segment1 PROJECT_NUMBER,
       tsk.task_number
  FROM PA_Project_Asset_Assignments paa,
	   pa_project_assets_all ppa,
	   pa_tasks tsk,
	   pa_projects_all prj
 WHERE 1                              =1
   AND prj.template_flag            = 'N'
   AND NVL(prj.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
   AND (
		    prj.segment1 NOT LIKE 'PB%'
		AND prj.segment1 NOT LIKE 'NB%'
		AND prj.segment1 NOT LIKE 'TEM%'
	   )
   AND prj.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
   AND prj.project_status_code IN ('APPROVED','CLOSED','1000')
   AND prj.org_id              <>403
   AND prj.created_from_project_id IN  (SELECT project_id
										  FROM pa_projects_all
										 WHERE template_flag='Y'
										   AND name=NVL(p_proj_template,name)
									   )
   AND tsk.project_id          = prj.project_id
   AND tsk.billable_flag='Y'
   AND ppa.project_id=prj.project_id   
   AND paa.project_asset_id=ppa.project_asset_id
   AND paa.task_id=tsk.task_id
   AND paa.project_id=prj.project_id
   AND ppa.project_asset_type = 'ESTIMATED'
ORDER BY
    prj.SEGMENT1;
	
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  lc_text VARCHAR2(1):=NULL;
BEGIN
  print_debug_msg ('Package fbdi_proj_asset_assignments START', true);
  l_file_name := 'fbdi_proj_asset_assignments_yn' || '.csv';--
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='DEMO_CREATE'|| ','|| 'CREATE_MODE'|| ','||
  'ASSET_ASSIGNMENT_ID'|| ','|| 'PROJECT_ASSET_ID'|| ','|| 'ASSET_NAME'|| ','||
  'ASSET_NUMBER'|| ','|| 'ASSET_ASSIGMENT_LEVEL'|| ','|| 'PROJECT_ID'|| ','||
  'PROJECT_NAME'|| ','|| 'PROJECT_NUMBER'|| ','|| 'TASK_ID'|| ','|| 'TASK_NAME'
  || ','|| 'TASK_NUMBER' ;
  --utl_file.put_line(lc_file_handle,lv_col_title);commenting column as we are generating direct FDBI file
  
  FOR i IN c_proj_asset_assign_yn
  LOOP
    utl_file.put_line(lc_file_handle,'"'||i.DEMO_CREATE|| 
    '","'|| i.CREATE_MODE||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'||i.ASSET_NAME||
    '","'|| lc_text||
    '","'|| i.ASSET_ASSIGMENT_LEVEL||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| i.PROJECT_NUMBER||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| i.task_number||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
    '","'|| lc_text||
     '","'|| 'END'||'"');
  END LOOP;
  
  utl_file.fclose(lc_file_handle);
EXCEPTION
  WHEN utl_file.access_denied THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.delete_failed THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.file_open THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.internal_error THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filehandle THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure:- ' ||
    ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filename THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_maxlinesize THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_mode THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_offset THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_operation THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_path THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.read_error THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.rename_failed THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.write_error THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
END fbdi_proj_asset_assignments_yn;



PROCEDURE fbdi_project_assets_yy(p_proj_template VARCHAR2)
IS

CURSOR c_fbdi_project_assets_yy_main
IS
SELECT DISTINCT
       prj.segment1 proj_number
  FROM pa_project_assets_all ppa,
       pa_tasks tsk,
       pa_projects_all prj
 WHERE 1=1
   AND prj.template_flag            = 'N'
   AND NVL(prj.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
   AND (
		    prj.segment1 NOT LIKE 'PB%'
		AND prj.segment1 NOT LIKE 'NB%'
		AND prj.segment1 NOT LIKE 'TEM%'
	   )
   AND prj.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
   AND prj.project_status_code IN ('APPROVED','CLOSED','1000')
   AND prj.org_id              <>403
   AND tsk.project_id          = prj.project_id
   AND tsk.billable_flag='Y'
   AND prj.created_from_project_id IN  (SELECT project_id
										  FROM pa_projects_all
										 WHERE template_flag='Y'
										   AND name=NVL(p_proj_template,name)
									   )
   AND ppa.project_id=prj.project_id
   AND ppa.project_asset_type = 'AS-BUILT'
ORDER 
   BY prj.segment1;
   
	
CURSOR c_fbdi_project_assets_yy(p_project_number varchar2)
IS
SELECT DISTINCT
      'CONVERSION_ASSET' create_asset,
      'Create' create_mode,
       NULL project_id,
       NULL project_name,
       proj.segment1 project_number,
       'AS-BUILT' project_asset_type,
       NULL project_asset_id,
       'CONVERSION ASSET' asset_name,
       Null asset_number,
       --REPLACE(REPLACE(REPLACE(REPLACE(ppa.asset_description,chr(13), '' ), chr(10), ''),chr(39),''),chr(63),'') asset_description,
	   'CONVERSION ASSET' asset_description,
       --TO_CHAR(ppa.estimated_in_service_date,'YYYY/MM/DD') estimated_in_service_date,
	   Null estimated_in_service_date,
       TO_CHAR(ppa.date_placed_in_service,'YYYY/MM/DD') date_placed_in_service,
       'N' reverse_flag,
       NULL capital_hold_flag,
       'OD US CORP' book_type_code,
       NULL asset_category_id,
      (
        SELECT
          segment1
          || '.'
          || segment2
          || '.'
          || segment3
        FROM
          fa_categories
        WHERE
          category_id = ppa.asset_category_id
      )
      asset_category,
      NULL asset_key_ccid,
      NULL asset_key,
      ppa.asset_units,
      NULL estimated_cost,
      NULL estimated_asset_units,
      NULL location_id,
     (
      SELECT
        segment1
        || '.'
        || segment2
        || '.'
        || segment3
        || '.'
        || segment4
        || '.'
        || segment6
        || '.'
        || SUBSTR(segment5,2)
      FROM
        fa_locations
      WHERE
        location_id = ppa.location_id
     )location,
     -- per.full_name,        --(Add Fetch)
     NULL assigned_to_person_id,
     NULL assigned_to_person_name,
     NULL assigned_to_person_number,
     'Y' depreciate_flag,
     NULL depreciation_expense_ccid,
     ---Added by Priyam for EBS to Cloud segment Change
     nvl((
      CASE
        WHEN
          (
            ppa.depreciate_flag              = 'Y'
          AND ppa.depreciation_expense_ccid IS NULL
          AND project_status_code           IN ('1000','CLOSED')
          )
        THEN (xx_gl_beacon_mapping_f1(
          '1001.43002.73802000.010000.0000.10.000000',NULL,'P'))
        ELSE
          (
            SELECT
              xx_gl_beacon_mapping_f1(concatenated_segments,NULL,'P')
            FROM
              gl_code_combinations_kfv
            WHERE
              code_combination_id = ppa.depreciation_expense_ccid
          )
      END ),'1150.12.60310.741107.10000.0000') depreciation_expense_account,
      ---Changes end
      'N' amortize_flag,
      NULL overridecategoryanddesc,
      NULL business_unit_id,
      NULL parent_asset_id,
	  NULL parent_asset_number,
      NULL manufacturer_name,
      NULL model_number,
      NULL tag_number,
      NULL serial_number,
      NULL ret_target_asset_id,
      NULL ret_target_asset_number,
      NULL pm_product_code,
	  NULL pm_asset_reference    ,
      NULL ATTRIBUTE_CATEGORY    ,
      NULL ATTRIBUTE1            ,
      NULL ATTRIBUTE2            ,
      NULL ATTRIBUTE3            ,
      NULL ATTRIBUTE4            ,
      NULL ATTRIBUTE5            ,
      NULL ATTRIBUTE6            ,
      NULL ATTRIBUTE7            ,
      NULL ATTRIBUTE8            ,
      NULL ATTRIBUTE9            ,
      NULL ATTRIBUTE10           ,
      NULL ATTRIBUTE11           ,
      NULL ATTRIBUTE12           ,
      NULL ATTRIBUTE13           ,
      NULL ATTRIBUTE14           ,
      NULL ATTRIBUTE15           ,
      NULL capital_event_id      ,
      NULL capital_event_name    ,
      NULL capital_event_number  
  FROM pa_project_assets_all ppa,
       pa_tasks tsk,
       pa_projects_all proj	
 WHERE 1=1	
   AND proj.segment1=p_project_number
   AND tsk.project_id          = proj.project_id
   AND tsk.billable_flag='Y'   
   AND ppa.project_id=proj.project_id
   AND ppa.project_asset_type = 'AS-BUILT' 
 ORDER 
    BY proj.segment1;
  
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  lc_location VARCHAR2(100):='US.FL.PALM BEACH.DELRAY BEACH.33445.10000';
  lv_proj_level_flg varchar2(1):='N';
BEGIN
  /* BEGIN
  SELECT directory_path
    INTO l_file_path
    FROM dba_directories
   WHERE directory_name = 'XXFIN_OUTBOUND';
  EXCEPTION
    WHEN OTHERS THEN
      l_file_path := NULL;
  END;*/
  
  print_debug_msg ('Package FBDI_PROJECT_ASSETS_YY START', true);
  l_file_name    := 'fbdi_project_assets_yy' || '.csv';
  
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='DEMO_CREATE'|| ','|| 'CREATE_MODE'|| ','|| 'PROJECT_ID'||
  ','|| 'PROJECT_NAME'|| ','|| 'PROJECT_NUMBER'|| ','|| 'PROJECT_ASSET_TYPE'||
  ','|| 'PROJECT_ASSET_ID'|| ','|| 'ASSET_NAME'|| ','|| 'ASSET_NUMBER'|| ','||
  'ASSET_DESCRIPTION'|| ','|| 'ESTIMATED_IN_SERVICE_DATE'|| ','||
  'DATE_PLACED_IN_SERVICE'|| ','|| 'REVERSE_FLAG'|| ','|| 'CAPITAL_HOLD_FLAG'||
  ','|| 'BOOK_TYPE_CODE'|| ','|| 'ASSET_CATEGORY_ID'|| ','|| 'ASSET_CATEGORY'||
  ','|| 'ASSET_KEY_CCID'|| ','|| 'ASSET_KEY'|| ','|| 'ASSET_UNITS'|| ','||
  'ESTIMATED_COST'|| ','|| 'ESTIMATED_ASSET_UNITS'|| ','|| 'LOCATION_ID'|| ','
  || 'LOCATION'|| ','|| 'ASSIGNED_TO_PERSON_ID'|| ','||
  'ASSIGNED_TO_PERSON_NAME'|| ','|| 'ASSIGNED_TO_PERSON_NUMBER'|| ','||
  'DEPRECIATE_FLAG'|| ','|| 'DEPRECIATION_EXPENSE_CCID'|| ','||
  'DEPRECIATION_EXPENSE_ACCOUNT'|| ','|| 'AMORTIZE_FLAG'|| ','||
  'OVERRIDECATEGORYANDDESC'|| ','|| 'BUSINESS_UNIT_ID'|| ','||
  'PARENT_ASSET_ID'|| ','|| 'PARENT_ASSET_NUMBER'|| ','|| 'MANUFACTURER_NAME'||
  ','|| 'MODEL_NUMBER'|| ','|| 'TAG_NUMBER'|| ','|| 'SERIAL_NUMBER'|| ','||
  'RET_TARGET_ASSET_ID'|| ','|| 'RET_TARGET_ASSET_NUMBER'|| ','||
  'PM_PRODUCT_CODE';
  --utl_file.put_line(lc_file_handle,lv_col_title); commenting column as it is not required for FBDI Load
  
  FOR main_rec in c_fbdi_project_assets_yy_main LOOP
	lv_proj_level_flg:='N';
	FOR i IN c_fbdi_project_assets_yy(main_rec.proj_number)
	LOOP
     if lv_proj_level_flg='N' then 
    
		utl_file.put_line(lc_file_handle, '"'||i.create_asset||
		'","'|| i.create_mode||
		'","'|| i.project_id||
		'","'|| i.project_name||
		'","'|| i.project_number||
		'","'|| i.project_asset_type||
		'","'|| i.project_asset_id||
		'","'|| i.asset_name||
		'","'|| i.asset_number||
		'","'|| i.asset_description||
		'","'|| i.estimated_in_service_date||
		'","'|| i.date_placed_in_service||
		'","'||i.reverse_flag||
		'","'|| i.capital_hold_flag||
		'","'|| i.book_type_code||
		'","'|| i.asset_category_id||
		'","'|| i.asset_category||
		'","'|| i.asset_key_ccid||
		'","'|| i.asset_key||
		'","'|| i.asset_units||
		'","'|| i.estimated_cost||
		'","'|| i.estimated_asset_units||
		'","'|| i.location_id ||
		'","'|| NVL(i.location,lc_location)||
		'","'|| i.assigned_to_person_id||
		'","'|| i.assigned_to_person_name||
		'","'|| i.assigned_to_person_number||
		'","'|| i.depreciate_flag||
		'","'|| i.depreciation_expense_ccid||
		'","'|| i.depreciation_expense_account||
		'","'|| i.amortize_flag|| 
		'","'|| i.overridecategoryanddesc||
		'","'|| i.business_unit_id||
		'","'|| i.parent_asset_id||
		'","'|| i.parent_asset_number||
		'","'|| i.manufacturer_name||
		'","'|| i.model_number||
		'","'|| i.tag_number||
		'","'|| i.serial_number||
		'","'|| i.ret_target_asset_id||
		'","'||i.ret_target_asset_number||
		'","'|| i.pm_product_code||
		'"'|| i.pm_asset_reference||
		'"'|| i.ATTRIBUTE_CATEGORY||
		'","'|| i.ATTRIBUTE1||
		'","'|| i.ATTRIBUTE2||
		'","'|| i.ATTRIBUTE3||
		'","'|| i.ATTRIBUTE4||
		'","'|| i.ATTRIBUTE5||
		'","'|| i.ATTRIBUTE6||
		'","'|| i.ATTRIBUTE7||
		'","'|| i.ATTRIBUTE8||
		'","'|| i.ATTRIBUTE9||
		'","'|| i.ATTRIBUTE10||
		'","'|| i.ATTRIBUTE11||
		'","'|| i.ATTRIBUTE12||
		'","'|| i.ATTRIBUTE13||
		'","'|| i.ATTRIBUTE14||
		'","'|| i.ATTRIBUTE15|| 
		'","'|| i.capital_event_id||
		'","'|| i.capital_event_name||
		'","'|| i.capital_event_number||
		'","'|| 'END'||'"');
	  end if;
	  lv_proj_level_flg:='Y';
	END LOOP;
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
  WHEN utl_file.access_denied THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.delete_failed THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.file_open THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.internal_error THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filehandle THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure:- ' ||
    ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filename THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_maxlinesize THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_mode THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_offset THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_operation THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_path THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.read_error THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.rename_failed THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.write_error THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' ||
    ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
END fbdi_project_assets_yy;

PROCEDURE fbdi_proj_asset_assignments_yy(p_proj_template VARCHAR2)
IS

CURSOR c_proj_asset_assign_yy_main
IS
SELECT DISTINCT
      'CREATE_ASSET_ASSIGN' demo_create,
      'Create' create_mode,
      NULL Asset_Assignment_Id,
      NULL project_asset_id,
      'CONVERSION ASSET' asset_name,
      NULL  asset_number,
      'Project Level Assignment' asset_assigment_level,
      NULL project_id,
      NULL Project_Name,
      prj.SEGMENT1 Project_Number,
      NULL Task_Id,
      NULL task_Name,
      NULL task_number,
	  null ATTRIBUTE_CATEGORY ,
	  null ATTRIBUTE1         ,
	  null ATTRIBUTE2         ,
	  null ATTRIBUTE3         ,
	  null ATTRIBUTE4         ,
	  null ATTRIBUTE5         ,
	  null ATTRIBUTE6         ,
	  null ATTRIBUTE7         ,
	  null ATTRIBUTE8         ,
	  null ATTRIBUTE9         ,
	  null ATTRIBUTE10        ,
	  null ATTRIBUTE11        ,
	  null ATTRIBUTE12        ,
	  null ATTRIBUTE13        ,
	  null ATTRIBUTE14        ,
	  null ATTRIBUTE15     
  FROM pa_project_assets_all ppa,
       pa_tasks tsk,
       pa_projects_all prj
 WHERE 1=1
   AND prj.template_flag            = 'N'
   AND NVL(prj.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
   AND (
		    prj.segment1 NOT LIKE 'PB%'
		AND prj.segment1 NOT LIKE 'NB%'
		AND prj.segment1 NOT LIKE 'TEM%'
	   )
   AND prj.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
   AND prj.project_status_code IN ('APPROVED','CLOSED','1000')
   AND prj.org_id              <>403
   AND tsk.project_id          = prj.project_id
   AND tsk.billable_flag='Y'
   AND prj.created_from_project_id IN  (SELECT project_id
										  FROM pa_projects_all
										 WHERE template_flag='Y'
										   AND name=NVL(p_proj_template,name)
									   )
   AND ppa.project_id=prj.project_id
   AND ppa.project_asset_type = 'AS-BUILT'
   AND EXISTS ( SELECT 'x'
	  		      FROM PA_Project_Asset_Assignments paa,
					   pa_project_assets_all ppa
			     WHERE ppa.project_id=prj.project_id
				   AND paa.project_id=ppa.project_id
				   AND paa.project_asset_id=ppa.project_asset_id
				   AND paa.task_id=tsk.task_id
			  )   
ORDER 
   BY prj.segment1;  
   
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  lv_proj_level_flg varchar2(1):='N';
BEGIN
  print_debug_msg ('Package fbdi_proj_asset_assignments START', true);
  l_file_name := 'fbdi_proj_asset_assignments_yy' || '.csv';--
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='DEMO_CREATE'|| ','|| 'CREATE_MODE'|| ','||
  'ASSET_ASSIGNMENT_ID'|| ','|| 'PROJECT_ASSET_ID'|| ','|| 'ASSET_NAME'|| ','||
  'ASSET_NUMBER'|| ','|| 'ASSET_ASSIGMENT_LEVEL'|| ','|| 'PROJECT_ID'|| ','||
  'PROJECT_NAME'|| ','|| 'PROJECT_NUMBER'|| ','|| 'TASK_ID'|| ','|| 'TASK_NAME'
  || ','|| 'TASK_NUMBER' ;
  --utl_file.put_line(lc_file_handle,lv_col_title);commenting column as we are generating direct FDBI file
  
  FOR i in c_proj_asset_assign_yy_main LOOP
    
	utl_file.put_line(lc_file_handle,'"'||i.DEMO_CREATE|| 
    '","'|| i.CREATE_MODE||
    '","'|| i.ASSET_ASSIGNMENT_ID||
    '","'|| i.PROJECT_ASSET_ID||
    '","'||i.ASSET_NAME||
    '","'|| i.ASSET_NUMBER||
    '","'|| i.ASSET_ASSIGMENT_LEVEL||
    '","'|| i.PROJECT_ID||
    '","'|| i.PROJECT_NAME||
    '","'|| i.PROJECT_NUMBER||
    '","'|| i.TASK_ID||
    '","'|| i.TASK_NAME||
    '","'|| i.task_number||
    '","'|| i.ATTRIBUTE_CATEGORY||
    '","'|| i.ATTRIBUTE1||
    '","'|| i.ATTRIBUTE2||
    '","'|| i.ATTRIBUTE3||
    '","'|| i.ATTRIBUTE4||
    '","'|| i.ATTRIBUTE5||
    '","'|| i.ATTRIBUTE6||
    '","'|| i.ATTRIBUTE7||
    '","'|| i.ATTRIBUTE8||
    '","'|| i.ATTRIBUTE9||
    '","'|| i.ATTRIBUTE10||
    '","'|| i.ATTRIBUTE11||
    '","'|| i.ATTRIBUTE12||
    '","'|| i.ATTRIBUTE13||
    '","'|| i.ATTRIBUTE14||
    '","'|| i.ATTRIBUTE15||
     '","'|| 'END'||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
  WHEN utl_file.access_denied THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.delete_failed THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.file_open THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.internal_error THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filehandle THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure:- ' ||
    ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filename THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_maxlinesize THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_mode THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_offset THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_operation THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_path THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.read_error THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.rename_failed THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.write_error THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
    ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, true);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
END fbdi_proj_asset_assignments_yy;


PROCEDURE fbdi_proj_exp_cap_yn(
    p_proj_template VARCHAR2)
IS
  CURSOR c_fbdi_yn
  IS
    SELECT
      /*+ PARALLEL(prj,4) */
      DISTINCT 'MISCELLANEOUS' transactiontype,
      ou.name businessunitname,
      NULL businessunitid,
      user_transaction_source transactionsource,
      NULL transactionsourceid,
      user_transaction_source document,
      NULL documentid,
      user_transaction_source documententry,
      NULL documententryid,
      'Conversion' expenditurebatch,
      NULL batchendingdate,
      'Conversion' batchdescription,
      TO_CHAR(expd.expenditure_item_date,'YYYY/MM/DD') expenditureitemdate,
      NULL personnumber,
      NULL personname,
      NULL personid,
      NULL humanresourcesassignment,
      NULL humanresourcesassignmentid,
      prj.segment1 projectnumber,
      trim(REPLACE(REPLACE(REPLACE(REPLACE(prj.name,chr(13), ''), chr(10), ''),
      chr(39),''),chr(63),'')) project_name,
      NULL projectid,
      task.task_number tasknumber,
      REPLACE(REPLACE(REPLACE(REPLACE(task.task_name,chr(13), ''), chr( 10), ''
      ),chr(39),''),chr(63),'') task_name,
      NULL taskid,
      exptyp.expenditure_type expendituretype,
      NULL expendituretypeid,
      (
        SELECT
          name
        FROM
          hr_all_organization_units
        WHERE
          organization_id=expd.cc_prvdr_organization_id
      )
    expenditure_organization,
    NULL expenditureorganizationid,
    NULL contract_number,
    NULL contract_name,
    NULL contract_id,
    NULL funding_source_number,
    NULL funding_source_name ,
    '1' quantity,
    NULL unit_of_measure_name ,
    NVL(expd.unit_of_measure,'USD') unit_of_measure_code,
    NULL worktype,
    NULL worktypeid,
    'N' billable,  -- changed as per Rebecca
    DECODE(SUBSTR(task.task_number,1,2),'01','N','Y') capitalizable,
    NULL accrual_item ,
    expd.expenditure_item_id orig_transaction_reference,
    --NULL unmatchednegativetransaction,
	DECODE(SIGN(raw_cost),-1,'Y',NULL) unmatchednegativetransaction,
    NULL reversedoriginaltransaction,
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ec.expenditure_comment,chr(13), ''), chr(10
    ), ''),chr(39),''),chr(63),''),CHR(34),'') AS expenditureitemcomment,
    -- for sit only TO_CHAR(expd.expenditure_item_date,'YYYY/MM/DD') accountingdate,
	'2020/03/05' accountingdate,
    expd.project_currency_code transactioncurrencycode,
    NULL transactioncurrency,
    raw_cost rawcostintrxcurrency,
    --burden_cost_rate burdenedcostintrxcurrency,
	NULL burdenedcostintrxcurrency,
    NULL rawcostcreditccid,
    /*Commented by Priyam for EBS to Cloud segment Change
    (SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = cr_code_combination_id
    ) rawcostcreditaccount,*/
    ---  ADDED by Priyam for EBS to Cloud segment Change
    (
      SELECT
        xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,NULL
        ,'P')
      FROM
        gl_code_combinations_kfv gl_code_combinations
      WHERE
        code_combination_id = cr_code_combination_id
    )
    rawcostcreditaccount,
    NULL rawcostdebitccid,
    /* Commented by Priyam for EBS to Cloud segment Change
    (SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = dr_code_combination_id
    ) rawcostdebitaccount,*/
    ----Added by Priyam for EBS to Cloud segment Change
    (
      SELECT
        xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,NULL
        ,'P')
      FROM
        gl_code_combinations_kfv gl_code_combinations
      WHERE
        code_combination_id = dr_code_combination_id
    )
    rawcostdebitaccount,
    NULL burdenedcostcreditccid,
    NULL burdenedcostcreditaccount,
    NULL burdenedcostdebitccid,
    NULL burdenedcostdebitaccount,
    NULL burdencostdebitccid,
    NULL burdencostdebitaccount,
    NULL burdencostcreditccid,
    NULL burdencostcreditaccount,
    NULL providerledgercurrencycode,
    NULL providerledgercurrency,
    raw_cost rawcostledgercurrency,
    NULL burdenedcostledgercurrency,
    NULL providerledgerratetype,
    NULL providerledgerratedate,
    NULL providerledgerdatetype,
    NULL providerledgerrate,
    NULL providerledgerroundinglimit,
    NULL converted,
    NULL contextcategory,
    NULL userdefinedattribute1,
    NULL userdefinedattribute2,
    NULL userdefinedattribute3,
    NULL userdefinedattribute4,
    NULL userdefinedattribute5,
    NULL userdefinedattribute6,
    NULL userdefinedattribute7,
    NULL userdefinedattribute8,
    NULL userdefinedattribute9,
    NULL userdefinedattribute10,
    NULL fundingsourceid,
    NULL reservedattribute2,
    NULL reservedattribute3,
    NULL reservedattribute4,
    NULL reservedattribute5,
    NULL reservedattribute6,
    NULL reservedattribute7,
    NULL reservedattribute8,
    NULL reservedattribute9,
    NULL reservedattribute10,
    DECODE(expd.org_id,404,'OD US Fin BU',403, 'OD CA Fin BU') attributecategory ,
    expd.attribute1 attribute1,
    expd.attribute2 attribute2,
    expd.attribute3 attribute3,
    expd.attribute4 attribute4,
    expd.attribute5 attribute5,
    expd.attribute6 attribute6,
    (
      SELECT
        vendor_name
      FROM
        ap_suppliers
      WHERE
        vendor_id = expd.vendor_id
    )
    attribute7,
    (
      SELECT
        segment1
      FROM
        ap_suppliers
      WHERE
        vendor_id = expd.vendor_id
    )
    attribute8,
    (
      SELECT
        ai.invoice_num
      FROM
        ap_invoices_all ai
      WHERE
        1              =1
      AND ai.invoice_id=expd.document_header_id
    )
    attribute9,
    (
      SELECT
        TO_CHAR(ai.invoice_date,'YYYY/MM/DD')
      FROM
        ap_invoices_all ai
      WHERE
        1              =1
      AND ai.invoice_id=expd.document_header_id
    )
    attribute10
  FROM
    pa_expenditure_comments ec,
    pa_cost_distribution_lines_all cd,
    pa_transaction_sources src,
    pa_expenditure_types exptyp,
    hr_operating_units ou,
    pa_expenditure_items_all expd,
    pa_tasks task,
    pa_projects_all prj
  WHERE
    1                              =1
  AND prj.template_flag            = 'N'
  AND NVL(prj.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
  AND
    (
      prj.segment1 NOT LIKE 'PB%'
    AND prj.segment1 NOT LIKE 'NB%'
    AND prj.segment1 NOT LIKE 'TEM%'
    )
  AND prj.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
  AND prj.project_status_code IN ('APPROVED','CLOSED','1000')
  AND prj.org_id              <>403
  AND task.project_id          = prj.project_id
  AND expd.project_id          = prj.project_id
  AND expd.task_id             = task.task_id
    --------------- Capitalizable --------------
  AND expd.billable_flag            = 'Y'
  AND expd.revenue_distributed_flag = 'N'
    --------------------------------------------
  AND ou.organization_id      =expd.org_id
  AND exptyp.expenditure_type = expd.expenditure_type
  AND src.transaction_source  =expd.transaction_source
  AND cd.expenditure_item_id  = expd.expenditure_item_id
    -----------------
  AND cd.line_num =
    (
      SELECT
        MAX(line_num)
      FROM
        pa_cost_distribution_lines_all d
      WHERE
        d.expenditure_item_id = expd.expenditure_item_id
      AND d.line_type         = 'R'
    )
    ------------------
  AND ec.expenditure_item_id=expd.expenditure_item_id
    -- Begin Added for pstgb
  AND prj.created_from_project_id IN
  (
      SELECT
        project_id
      FROM
        pa_projects_all
      WHERE template_flag='Y'
        AND name       =NVL(p_proj_template,name)--'US IT Template - Labor Only'
    )
    -- End added for PSTGB
  ORDER BY
    prj.segment1,
    task.task_number,
    expd.expenditure_item_id;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  lc_rawcostcreditaccount VARCHAR2(100);
BEGIN
  /* BEGIN
  SELECT directory_path
  INTO l_file_path
  FROM dba_directories
  WHERE directory_name = 'XXFIN_OUTBOUND';
  EXCEPTION
  WHEN OTHERS THEN
  l_file_path := NULL;
  END;*/
  print_debug_msg ('Package fbdi_Proj_Exp_Cap_YN START', true);
  l_file_name := 'fbdi_ProjectExpenditure_Capitalizable_YN' || '.csv';--
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='TRANSACTIONTYPE'|| ','|| 'BUSINESSUNITNAME'|| ','||
  'BUSINESSUNITID'|| ','|| 'TRANSACTIONSOURCE'|| ','|| 'TRANSACTIONSOURCEID'||
  ','|| 'DOCUMENT'|| ','|| 'DOCUMENTID'|| ','|| 'DOCUMENTENTRY'|| ','||
  'DOCUMENTENTRYID'|| ','|| 'EXPENDITUREBATCH'|| ','|| 'BATCHENDINGDATE'|| ','
  || 'BATCHDESCRIPTION'|| ','|| 'EXPENDITUREITEMDATE'|| ','|| 'PERSONNUMBER'||
  ','|| 'PERSONNAME'|| ','|| 'PERSONID'|| ','|| 'HUMANRESOURCESASSIGNMENT'||
  ','|| 'HUMANRESOURCESASSIGNMENTID'|| ','|| 'PROJECTNUMBER'|| ','||
  'PROJECT_NAME'|| ','|| 'PROJECTID'|| ','|| 'TASKNUMBER'|| ','|| 'TASK_NAME'||
  ','|| 'TASKID'|| ','|| 'EXPENDITURETYPE'|| ','|| 'EXPENDITURETYPEID'|| ','||
  'EXPENDITURE_ORGANIZATION'|| ','|| 'EXPENDITUREORGANIZATIONID'|| ','||
  'CONTRACT_NUMBER'|| ','|| 'CONTRACT_NAME'|| ','|| 'CONTRACT_ID'|| ','||
  'FUNDING_SOURCE_NUMBER'|| ','|| 'FUNDING_SOURCE_NAME'|| ','|| 'QUANTITY'||
  ','|| 'UNIT_OF_MEASURE_NAME'|| ','|| 'UNIT_OF_MEASURE_CODE'|| ','||
  'WORKTYPE'|| ','|| 'WORKTYPEID'|| ','|| 'BILLABLE'|| ','|| 'CAPITALIZABLE'||
  ','|| 'ACCRUAL_ITEM'|| ','|| 'ORIG_TRANSACTION_REFERENCE'|| ','||
  'UNMATCHEDNEGATIVETRANSACTION'|| ','|| 'REVERSEDORIGINALTRANSACTION'|| ','||
  'EXPENDITUREITEMCOMMENT'|| ','|| 'ACCOUNTINGDATE'|| ','||
  'TRANSACTIONCURRENCYCODE'|| ','|| 'TRANSACTIONCURRENCY'|| ','||
  'RAWCOSTINTRXCURRENCY'|| ','|| 'BURDENEDCOSTINTRXCURRENCY'|| ','||
  'RAWCOSTCREDITCCID'|| ','|| 'RAWCOSTCREDITACCOUNT'|| ','|| 'RAWCOSTDEBITCCID'
  || ','|| 'RAWCOSTDEBITACCOUNT'|| ','|| 'BURDENEDCOSTCREDITCCID'|| ','||
  'BURDENEDCOSTCREDITACCOUNT'|| ','|| 'BURDENEDCOSTDEBITCCID'|| ','||
  'BURDENEDCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTDEBITCCID'|| ','||
  'BURDENCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTCREDITCCID'|| ','||
  'BURDENCOSTCREDITACCOUNT'|| ','|| 'PROVIDERLEDGERCURRENCYCODE'|| ','||
  'PROVIDERLEDGERCURRENCY'|| ','|| 'RAWCOSTLEDGERCURRENCY'|| ','||
  'BURDENEDCOSTLEDGERCURRENCY'|| ','|| 'PROVIDERLEDGERRATETYPE'|| ','||
  'PROVIDERLEDGERRATEDATE'|| ','|| 'PROVIDERLEDGERDATETYPE'|| ','||
  'PROVIDERLEDGERRATE'|| ','|| 'PROVIDERLEDGERROUNDINGLIMIT'|| ','||
  'CONVERTED'|| ','|| 'CONTEXTCATEGORY'|| ','|| 'USERDEFINEDATTRIBUTE1'|| ','||
  'USERDEFINEDATTRIBUTE2'|| ','|| 'USERDEFINEDATTRIBUTE3'|| ','||
  'USERDEFINEDATTRIBUTE4'|| ','|| 'USERDEFINEDATTRIBUTE5'|| ','||
  'USERDEFINEDATTRIBUTE6'|| ','|| 'USERDEFINEDATTRIBUTE7'|| ','||
  'USERDEFINEDATTRIBUTE8'|| ','|| 'USERDEFINEDATTRIBUTE9'|| ','||
  'USERDEFINEDATTRIBUTE10'|| ','|| 'FUNDINGSOURCEID'|| ','||
  'RESERVEDATTRIBUTE2'|| ','|| 'RESERVEDATTRIBUTE3'|| ','||
  'RESERVEDATTRIBUTE4'|| ','|| 'RESERVEDATTRIBUTE5'|| ','||
  'RESERVEDATTRIBUTE6'|| ','|| 'RESERVEDATTRIBUTE7'|| ','||
  'RESERVEDATTRIBUTE8'|| ','|| 'RESERVEDATTRIBUTE9'|| ','||
  'RESERVEDATTRIBUTE10'|| ','|| 'ATTRIBUTECATEGORY'|| ','|| 'ATTRIBUTE1'|| ','
  || 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','||
  'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'||
  ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_fbdi_yn
  LOOP
    lc_rawcostcreditaccount:=NULL;
	IF i.transactionsource LIKE '%Payables%' THEN
	   lc_rawcostcreditaccount:='1150.43.00000.211143.10000.0000';
	ELSE
	   lc_rawcostcreditaccount:=i.rawcostcreditaccount;
	END IF;
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,'"'||i.transactiontype|| '","'||
    i.businessunitname|| '","'|| i.businessunitid|| '","'|| i.transactionsource
    || '","'|| i.transactionsourceid|| '","'|| i.document|| '","'||
    i.documentid|| '","'|| i.documententry|| '","'|| i.documententryid|| '","'
    || i.expenditurebatch|| '","'|| i.batchendingdate|| '","'||
    i.batchdescription|| '","'|| i.expenditureitemdate|| '","'|| i.personnumber
    || '","'|| i.personname|| '","'|| i.personid|| '","'||
    i.humanresourcesassignment|| '","'|| i.humanresourcesassignmentid|| '","'||
    i.projectnumber|| '","'|| i.project_name|| '","'|| i.projectid|| '","'||
    i.tasknumber|| '","'|| i.task_name|| '","'|| i.taskid|| '","'||
    i.expendituretype|| '","'|| i.expendituretypeid|| '","'||
    i.expenditure_organization|| '","'|| i.expenditureorganizationid|| '","'||
    i.contract_number|| '","'|| i.contract_name|| '","'|| i.contract_id|| '","'
    || i.funding_source_number|| '","'|| i.funding_source_name|| '","'||
    i.quantity|| '","'|| i.unit_of_measure_name|| '","'||
    i.unit_of_measure_code|| '","'|| i.worktype|| '","'|| i.worktypeid|| '","'
    || i.billable|| '","'|| i.capitalizable|| '","'|| i.accrual_item|| '","'||
    i.orig_transaction_reference|| '","'|| i.unmatchednegativetransaction||
    '","'|| i.reversedoriginaltransaction|| '","'|| i.expenditureitemcomment||
    '","'|| i.accountingdate|| '","'|| i.transactioncurrencycode|| '","'||
    i.transactioncurrency|| '","'|| i.rawcostintrxcurrency|| '","'||
    i.burdenedcostintrxcurrency|| '","'|| i.rawcostcreditccid|| '","'||
    lc_rawcostcreditaccount|| '","'|| i.rawcostdebitccid|| '","'||
    i.rawcostdebitaccount|| '","'|| i.burdenedcostcreditccid|| '","'||
    i.burdenedcostcreditaccount|| '","'|| i.burdenedcostdebitccid|| '","'||
    i.burdenedcostdebitaccount|| '","'|| i.burdencostdebitccid|| '","'||
    i.burdencostdebitaccount|| '","'|| i.burdencostcreditccid|| '","'||
    i.burdencostcreditaccount|| '","'|| i.providerledgercurrencycode|| '","'||
    i.providerledgercurrency|| '","'|| i.rawcostledgercurrency|| '","'||
    i.burdenedcostledgercurrency|| '","'|| i.providerledgerratetype|| '","'||
    i.providerledgerratedate|| '","'|| i.providerledgerdatetype|| '","'||
    i.providerledgerrate|| '","'|| i.providerledgerroundinglimit|| '","'||
    i.converted|| '","'|| i.contextcategory|| '","'|| i.userdefinedattribute1||
    '","'|| i.userdefinedattribute2|| '","'|| i.userdefinedattribute3|| '","'||
    i.userdefinedattribute4|| '","'|| i.userdefinedattribute5|| '","'||
    i.userdefinedattribute6|| '","'|| i.userdefinedattribute7|| '","'||
    i.userdefinedattribute8|| '","'|| i.userdefinedattribute9|| '","'||
    i.userdefinedattribute10|| '","'|| i.fundingsourceid|| '","'||
    i.reservedattribute2|| '","'|| i.reservedattribute3|| '","'||
    i.reservedattribute4|| '","'|| i.reservedattribute5|| '","'||
    i.reservedattribute6|| '","'|| i.reservedattribute7|| '","'||
    i.reservedattribute8|| '","'|| i.reservedattribute9|| '","'||
    i.reservedattribute10|| '","'|| i.attributecategory|| '","'|| i.attribute1
    || '","'|| i.attribute2|| '","'|| i.attribute3|| '","'|| i.attribute4||
    '","'|| i.attribute5|| '","'|| i.attribute6|| '","'|| i.attribute7|| '","'
    || i.attribute8|| '","'|| i.attribute9|| '","'|| i.attribute10||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' ||
  ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_proj_exp_cap_yn;
PROCEDURE fbdi_proj_exp_cap_yy(
    p_proj_template VARCHAR2)
IS
  CURSOR c_proj_yy
  IS
    ---fbdi_ProjectExpenditure_capitalized_YY_v14
    SELECT
      /*+ PARALLEL(4) */
      DISTINCT 'MISCELLANEOUS' transactiontype,
      ou.name businessunitname,
      NULL businessunitid,
      user_transaction_source transactionsource,
      NULL transactionsourceid,
      user_transaction_source document,
      NULL documentid,
      user_transaction_source documententry,
      NULL documententryid,
      'Conversion' expenditurebatch,
      NULL batchendingdate,
      'Conversion' batchdescription,
      TO_CHAR(expd.expenditure_item_date,'YYYY/MM/DD') expenditureitemdate,
      NULL personnumber,
      NULL personname,
      NULL personid,
      NULL humanresourcesassignment,
      NULL humanresourcesassignmentid,
      prj.segment1 projectnumber,
      trim(REPLACE(REPLACE(REPLACE(REPLACE(prj.name,chr(13), ''), chr(10), ''),
      chr(39),''),chr(63),'')) project_name,
      NULL projectid,
      task.task_number tasknumber,
      REPLACE(REPLACE(REPLACE(REPLACE(task.task_name,chr(13), ''), chr( 10), ''
      ),chr(39),''),chr(63),'')task_name,
      NULL taskid,
      exptyp.expenditure_type expendituretype,
      NULL expendituretypeid,
      (
        SELECT
          name
        FROM
          hr_all_organization_units
        WHERE
          organization_id=expd.cc_prvdr_organization_id
      )
    expenditure_organization,
    NULL expenditureorganizationid,
    NULL contract_number,
    NULL contract_name,
    NULL contract_id,
    NULL funding_source_number,
    NULL funding_source_name ,
    '1' quantity,
    NULL unit_of_measure_name ,
    NVL(expd.unit_of_measure,'USD') unit_of_measure_code,
    NULL worktype,
    NULL worktypeid,
    'N' billable,   -- changed as per Rebecca
    DECODE(SUBSTR(task.task_number,1,2),'01','N','Y') capitalizable,
    NULL accrual_item ,
    expd.expenditure_item_id orig_transaction_reference,
    --NULL unmatchednegativetransaction,
	DECODE(SIGN(raw_cost),-1,'Y',NULL) unmatchednegativetransaction,
    NULL reversedoriginaltransaction,
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ec.expenditure_comment,chr(13), ''), chr(10
    ), ''),chr(39),''),chr(63),''),CHR(34),'') AS expenditureitemcomment,
    --For sit only TO_CHAR(expd.expenditure_item_date,'YYYY/MM/DD') accountingdate,
	'2020/03/05' accountingdate,
    expd.project_currency_code transactioncurrencycode,
    NULL transactioncurrency,
    raw_cost rawcostintrxcurrency,
    --burden_cost_rate burdenedcostintrxcurrency,
	NULL burdenedcostintrxcurrency,
    NULL rawcostcreditccid,
    /*Commented by Priyam for EBS to Cloud segment Change
    (SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = cd.cr_code_combination_id
    ) rawcostcreditaccount,*/
    --  Added by Priyam for EBS to Cloud segment Change
    (
      SELECT
        xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,NULL
        ,'P')
      FROM
        gl_code_combinations_kfv gl_code_combinations
      WHERE
        code_combination_id = cd.cr_code_combination_id
    )
    rawcostcreditaccount,
    ----
    NULL rawcostdebitccid,
    /*Commented by Priyam for EBS to Cloud segment Change
    (SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = cd.dr_code_combination_id
    ) rawcostdebitaccount,*/
    --- Added by Priyam for EBS to Cloud segment Change
    (
      SELECT
        xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,NULL
        ,'P')
      FROM
        gl_code_combinations_kfv gl_code_combinations
      WHERE
        code_combination_id = cd.dr_code_combination_id
    )
    rawcostdebitaccount,
    --Changes end
    NULL burdenedcostcreditccid,
    NULL burdenedcostcreditaccount,
    NULL burdenedcostdebitccid,
    NULL burdenedcostdebitaccount,
    NULL burdencostdebitccid,
    NULL burdencostdebitaccount,
    NULL burdencostcreditccid,
    NULL burdencostcreditaccount,
    NULL providerledgercurrencycode,
    NULL providerledgercurrency,
    raw_cost rawcostledgercurrency,
    NULL burdenedcostledgercurrency,
    NULL providerledgerratetype,
    NULL providerledgerratedate,
    NULL providerledgerdatetype,
    NULL providerledgerrate,
    NULL providerledgerroundinglimit,
    NULL converted,
    NULL contextcategory,
    NULL userdefinedattribute1,
    NULL userdefinedattribute2,
    NULL userdefinedattribute3,
    NULL userdefinedattribute4,
    NULL userdefinedattribute5,
    NULL userdefinedattribute6,
    NULL userdefinedattribute7,
    NULL userdefinedattribute8,
    NULL userdefinedattribute9,
    NULL userdefinedattribute10,
    NULL fundingsourceid,
    NULL reservedattribute2,
    NULL reservedattribute3,
    NULL reservedattribute4,
    NULL reservedattribute5,
    NULL reservedattribute6,
    NULL reservedattribute7,
    NULL reservedattribute8,
    NULL reservedattribute9,
    NULL reservedattribute10,
    DECODE(expd.org_id,404,'OD US Fin BU',403, 'OD CA Fin BU') attributecategory ,
    expd.attribute1 attribute1,
    expd.attribute2 attribute2,
    expd.attribute3 attribute3,
    expd.attribute4 attribute4,
    expd.attribute5 attribute5,
    expd.attribute6 attribute6,
    (
      SELECT
        vendor_name
      FROM
        ap_suppliers
      WHERE
        vendor_id = expd.vendor_id
    )
    attribute7,
    (
      SELECT
        segment1
      FROM
        ap_suppliers
      WHERE
        vendor_id = expd.vendor_id
    )
    attribute8,
    (
      SELECT
        ai.invoice_num
      FROM
        ap_invoices_all ai
      WHERE
        1              =1
      AND ai.invoice_id=expd.document_header_id
    )
    attribute9,
    (
      SELECT
        TO_CHAR(ai.invoice_date,'YYYY/MM/DD')
      FROM
        ap_invoices_all ai
      WHERE
        1              =1
      AND ai.invoice_id=expd.document_header_id
    )
    attribute10
  FROM
    pa_expenditure_comments ec,
    pa_cost_distribution_lines_all cd,
    pa_transaction_sources src,
    pa_expenditure_types exptyp,
    hr_operating_units ou,
    pa_expenditure_items_all expd,
    pa_tasks task,
    pa_projects_all prj
  WHERE
    1                              =1
  AND prj.template_flag            = 'N'
  AND NVL(prj.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
  AND
    (
      prj.segment1 NOT LIKE 'PB%'
    AND prj.segment1 NOT LIKE 'NB%'
    AND prj.segment1 NOT LIKE 'TEM%'
    )
  AND prj.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
  AND prj.project_status_code IN ('APPROVED','CLOSED','1000')
  AND prj.org_id              <>403
  AND task.project_id          = prj.project_id
  AND expd.project_id          = prj.project_id
  AND expd.task_id             = task.task_id
    --------------- Capitalized --------------
  AND expd.billable_flag            = 'Y'
  AND expd.revenue_distributed_flag = 'Y'
    --------------------------------------------
  AND ou.organization_id      =expd.org_id
  AND exptyp.expenditure_type = expd.expenditure_type
  AND src.transaction_source  =expd.transaction_source
  AND cd.expenditure_item_id  = expd.expenditure_item_id
    -----------------
  AND cd.line_num =
    (
      SELECT
        MAX(line_num)
      FROM
        pa_cost_distribution_lines_all d
      WHERE
        d.expenditure_item_id = expd.expenditure_item_id
      AND d.line_type         = 'R'
    )
    ------------------
  AND ec.expenditure_item_id=expd.expenditure_item_id
    -- Begin Added for pstgb
  AND prj.created_from_project_id IN
  (
      SELECT
        project_id
      FROM
        pa_projects_all
      WHERE template_flag='Y'
        AND name       =NVL(p_proj_template,name)--'US IT Template - Labor Only'
    )
    -- End added for PSTGB
  ORDER BY
    prj.segment1,
    task.task_number,
    expd.expenditure_item_id;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  lc_rawcostcreditaccount VARCHAR2(100);
BEGIN
  /* BEGIN
  SELECT directory_path
  INTO l_file_path
  FROM dba_directories
  WHERE directory_name = 'XXFIN_OUTBOUND';
  EXCEPTION
  WHEN OTHERS THEN
  l_file_path := NULL;
  END;*/
  print_debug_msg ('Package fbdi_Proj_Exp_Cap_YY START', true);
  l_file_name := 'fbdi_ProjectExpenditure_capitalized_YY' || '.csv';--
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='TRANSACTIONTYPE'|| ','|| 'BUSINESSUNITNAME'|| ','||
  'BUSINESSUNITID'|| ','|| 'TRANSACTIONSOURCE'|| ','|| 'TRANSACTIONSOURCEID'||
  ','|| 'DOCUMENT'|| ','|| 'DOCUMENTID'|| ','|| 'DOCUMENTENTRY'|| ','||
  'DOCUMENTENTRYID'|| ','|| 'EXPENDITUREBATCH'|| ','|| 'BATCHENDINGDATE'|| ','
  || 'BATCHDESCRIPTION'|| ','|| 'EXPENDITUREITEMDATE'|| ','|| 'PERSONNUMBER'||
  ','|| 'PERSONNAME'|| ','|| 'PERSONID'|| ','|| 'HUMANRESOURCESASSIGNMENT'||
  ','|| 'HUMANRESOURCESASSIGNMENTID'|| ','|| 'PROJECTNUMBER'|| ','||
  'PROJECT_NAME'|| ','|| 'PROJECTID'|| ','|| 'TASKNUMBER'|| ','|| 'TASK_NAME'||
  ','|| 'TASKID'|| ','|| 'EXPENDITURETYPE'|| ','|| 'EXPENDITURETYPEID'|| ','||
  'EXPENDITURE_ORGANIZATION'|| ','|| 'EXPENDITUREORGANIZATIONID'|| ','||
  'CONTRACT_NUMBER'|| ','|| 'CONTRACT_NAME'|| ','|| 'CONTRACT_ID'|| ','||
  'FUNDING_SOURCE_NUMBER'|| ','|| 'FUNDING_SOURCE_NAME'|| ','|| 'QUANTITY'||
  ','|| 'UNIT_OF_MEASURE_NAME'|| ','|| 'UNIT_OF_MEASURE_CODE'|| ','||
  'WORKTYPE'|| ','|| 'WORKTYPEID'|| ','|| 'BILLABLE'|| ','|| 'CAPITALIZABLE'||
  ','|| 'ACCRUAL_ITEM'|| ','|| 'ORIG_TRANSACTION_REFERENCE'|| ','||
  'UNMATCHEDNEGATIVETRANSACTION'|| ','|| 'REVERSEDORIGINALTRANSACTION'|| ','||
  'EXPENDITUREITEMCOMMENT'|| ','|| 'ACCOUNTINGDATE'|| ','||
  'TRANSACTIONCURRENCYCODE'|| ','|| 'TRANSACTIONCURRENCY'|| ','||
  'RAWCOSTINTRXCURRENCY'|| ','|| 'BURDENEDCOSTINTRXCURRENCY'|| ','||
  'RAWCOSTCREDITCCID'|| ','|| 'RAWCOSTCREDITACCOUNT'|| ','|| 'RAWCOSTDEBITCCID'
  || ','|| 'RAWCOSTDEBITACCOUNT'|| ','|| 'BURDENEDCOSTCREDITCCID'|| ','||
  'BURDENEDCOSTCREDITACCOUNT'|| ','|| 'BURDENEDCOSTDEBITCCID'|| ','||
  'BURDENEDCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTDEBITCCID'|| ','||
  'BURDENCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTCREDITCCID'|| ','||
  'BURDENCOSTCREDITACCOUNT'|| ','|| 'PROVIDERLEDGERCURRENCYCODE'|| ','||
  'PROVIDERLEDGERCURRENCY'|| ','|| 'RAWCOSTLEDGERCURRENCY'|| ','||
  'BURDENEDCOSTLEDGERCURRENCY'|| ','|| 'PROVIDERLEDGERRATETYPE'|| ','||
  'PROVIDERLEDGERRATEDATE'|| ','|| 'PROVIDERLEDGERDATETYPE'|| ','||
  'PROVIDERLEDGERRATE'|| ','|| 'PROVIDERLEDGERROUNDINGLIMIT'|| ','||
  'CONVERTED'|| ','|| 'CONTEXTCATEGORY'|| ','|| 'USERDEFINEDATTRIBUTE1'|| ','||
  'USERDEFINEDATTRIBUTE2'|| ','|| 'USERDEFINEDATTRIBUTE3'|| ','||
  'USERDEFINEDATTRIBUTE4'|| ','|| 'USERDEFINEDATTRIBUTE5'|| ','||
  'USERDEFINEDATTRIBUTE6'|| ','|| 'USERDEFINEDATTRIBUTE7'|| ','||
  'USERDEFINEDATTRIBUTE8'|| ','|| 'USERDEFINEDATTRIBUTE9'|| ','||
  'USERDEFINEDATTRIBUTE10'|| ','|| 'FUNDINGSOURCEID'|| ','||
  'RESERVEDATTRIBUTE2'|| ','|| 'RESERVEDATTRIBUTE3'|| ','||
  'RESERVEDATTRIBUTE4'|| ','|| 'RESERVEDATTRIBUTE5'|| ','||
  'RESERVEDATTRIBUTE6'|| ','|| 'RESERVEDATTRIBUTE7'|| ','||
  'RESERVEDATTRIBUTE8'|| ','|| 'RESERVEDATTRIBUTE9'|| ','||
  'RESERVEDATTRIBUTE10'|| ','|| 'ATTRIBUTECATEGORY'|| ','|| 'ATTRIBUTE1'|| ','
  || 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','||
  'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'||
  ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_proj_yy
  LOOP

    lc_rawcostcreditaccount:=NULL;
	IF i.transactionsource LIKE '%Payables%' THEN
	   lc_rawcostcreditaccount:='1150.43.00000.211143.10000.0000';
	ELSE
	   lc_rawcostcreditaccount:=i.rawcostcreditaccount;
	END IF;
	
    utl_file.put_line(lc_file_handle,'"'||i.transactiontype|| '","'||
    i.businessunitname|| '","'|| i.businessunitid|| '","'|| i.transactionsource
    || '","'|| i.transactionsourceid|| '","'|| i.document|| '","'||
    i.documentid|| '","'|| i.documententry|| '","'|| i.documententryid|| '","'
    || i.expenditurebatch|| '","'|| i.batchendingdate|| '","'||
    i.batchdescription|| '","'|| i.expenditureitemdate|| '","'|| i.personnumber
    || '","'|| i.personname|| '","'|| i.personid|| '","'||
    i.humanresourcesassignment|| '","'|| i.humanresourcesassignmentid|| '","'||
    i.projectnumber|| '","'|| i.project_name|| '","'|| i.projectid|| '","'||
    i.tasknumber|| '","'|| i.task_name|| '","'|| i.taskid|| '","'||
    i.expendituretype|| '","'|| i.expendituretypeid|| '","'||
    i.expenditure_organization|| '","'|| i.expenditureorganizationid|| '","'||
    i.contract_number|| '","'|| i.contract_name|| '","'|| i.contract_id|| '","'
    || i.funding_source_number|| '","'|| i.funding_source_name|| '","'||
    i.quantity|| '","'|| i.unit_of_measure_name|| '","'||
    i.unit_of_measure_code|| '","'|| i.worktype|| '","'|| i.worktypeid|| '","'
    || i.billable|| '","'|| i.capitalizable|| '","'|| i.accrual_item|| '","'||
    i.orig_transaction_reference|| '","'|| i.unmatchednegativetransaction||
    '","'|| i.reversedoriginaltransaction|| '","'|| i.expenditureitemcomment||
    '","'|| i.accountingdate|| '","'|| i.transactioncurrencycode|| '","'||
    i.transactioncurrency|| '","'|| i.rawcostintrxcurrency|| '","'||
    i.burdenedcostintrxcurrency|| '","'|| i.rawcostcreditccid|| '","'||
    lc_rawcostcreditaccount|| '","'|| i.rawcostdebitccid|| '","'||
    i.rawcostdebitaccount|| '","'|| i.burdenedcostcreditccid|| '","'||
    i.burdenedcostcreditaccount|| '","'|| i.burdenedcostdebitccid|| '","'||
    i.burdenedcostdebitaccount|| '","'|| i.burdencostdebitccid|| '","'||
    i.burdencostdebitaccount|| '","'|| i.burdencostcreditccid|| '","'||
    i.burdencostcreditaccount|| '","'|| i.providerledgercurrencycode|| '","'||
    i.providerledgercurrency|| '","'|| i.rawcostledgercurrency|| '","'||
    i.burdenedcostledgercurrency|| '","'|| i.providerledgerratetype|| '","'||
    i.providerledgerratedate|| '","'|| i.providerledgerdatetype|| '","'||
    i.providerledgerrate|| '","'|| i.providerledgerroundinglimit|| '","'||
    i.converted|| '","'|| i.contextcategory|| '","'|| i.userdefinedattribute1||
    '","'|| i.userdefinedattribute2|| '","'|| i.userdefinedattribute3|| '","'||
    i.userdefinedattribute4|| '","'|| i.userdefinedattribute5|| '","'||
    i.userdefinedattribute6|| '","'|| i.userdefinedattribute7|| '","'||
    i.userdefinedattribute8|| '","'|| i.userdefinedattribute9|| '","'||
    i.userdefinedattribute10|| '","'|| i.fundingsourceid|| '","'||
    i.reservedattribute2|| '","'|| i.reservedattribute3|| '","'||
    i.reservedattribute4|| '","'|| i.reservedattribute5|| '","'||
    i.reservedattribute6|| '","'|| i.reservedattribute7|| '","'||
    i.reservedattribute8|| '","'|| i.reservedattribute9|| '","'||
    i.reservedattribute10|| '","'|| i.attributecategory|| '","'|| i.attribute1
    || '","'|| i.attribute2|| '","'|| i.attribute3|| '","'|| i.attribute4||
    '","'|| i.attribute5|| '","'|| i.attribute6|| '","'|| i.attribute7|| '","'
    || i.attribute8|| '","'|| i.attribute9|| '","'|| i.attribute10||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' ||
  ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_proj_exp_cap_yy;
PROCEDURE fbdi_proj_exp_nei_nn(
    p_proj_template VARCHAR2)
IS
  CURSOR c_proj_nn
  IS
    ---fbdi_ProjectExpenditure_Neither_NN_v14
    SELECT
      /*+ PARALLEL(4) */
      DISTINCT 'MISCELLANEOUS' transactiontype,
      ou.name businessunitname,
      NULL businessunitid,
      user_transaction_source transactionsource,
      NULL transactionsourceid,
      user_transaction_source document,
      NULL documentid,
      user_transaction_source documententry,
      NULL documententryid,
      'Conversion' expenditurebatch,
      NULL batchendingdate,
      'Conversion' batchdescription,
      TO_CHAR(expd.expenditure_item_date,'YYYY/MM/DD') expenditureitemdate,
      NULL personnumber,
      NULL personname,
      NULL personid,
      NULL humanresourcesassignment,
      NULL humanresourcesassignmentid,
      prj.segment1 projectnumber,
      trim(REPLACE(REPLACE(REPLACE(REPLACE(prj.name,chr(13), ''), chr(10), ''),
      chr(39),''),chr(63),'')) project_name,
      NULL projectid,
      task.task_number tasknumber,
      REPLACE(REPLACE(REPLACE(REPLACE(task.task_name,chr(13), ''), chr( 10), ''
      ),chr(39),''),chr(63),'') task_name,
      NULL taskid,
      exptyp.expenditure_type expendituretype,
      NULL expendituretypeid,
      (
        SELECT
          name
        FROM
          hr_all_organization_units
        WHERE
          organization_id=expd.cc_prvdr_organization_id
      )
    expenditure_organization,
    NULL expenditureorganizationid,
    NULL contract_number,
    NULL contract_name,
    NULL contract_id,
    NULL funding_source_number,
    NULL funding_source_name ,
    '1' quantity,
    NULL unit_of_measure_name ,
    NVL(expd.unit_of_measure,'USD') unit_of_measure_code,
    NULL worktype,
    NULL worktypeid,
    'N' billable,  -- change as per billable
    DECODE(SUBSTR(task.task_number,1,2),'01','N','Y') capitalizable,
    NULL accrual_item,
    expd.expenditure_item_id orig_transaction_reference,
    --NULL unmatchednegativetransaction,   -- change
	DECODE(SIGN(raw_cost),-1,'Y',NULL)  unmatchednegativetransaction,
    NULL reversedoriginaltransaction,
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ec.expenditure_comment,chr(13), ''), chr(10
    ), ''),chr(39),''),chr(63),''),CHR(34),'') AS expenditureitemcomment,
    --For SIT Only TO_CHAR(expd.expenditure_item_date,'YYYY/MM/DD') accountingdate,
	'2020/03/05' accountingdate,
    expd.project_currency_code transactioncurrencycode,
    NULL transactioncurrency,
    raw_cost rawcostintrxcurrency,  -- change
    --burden_cost_rate burdenedcostintrxcurrency,
	NULL burdenedcostintrxcurrency,
    NULL rawcostcreditccid,
    /*Commented by Priyam for EBS to Cloud segment Change
    (SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = cr_code_combination_id
    ) rawcostcreditaccount,*/
    --- Added by Priyam for EBS to Cloud segment Change
    (
      SELECT
        xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,NULL
        ,'P')
      FROM
        gl_code_combinations_kfv gl_code_combinations
      WHERE
        code_combination_id = cr_code_combination_id
    )
    rawcostcreditaccount,
    -------
    NULL rawcostdebitccid,
    /*Commented by Priyam for EBS to Cloud segment Change
    (SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = dr_code_combination_id
    ) rawcostdebitaccount,*/
    --   Added by Priyam for EBS to Cloud segment Change
    (
      SELECT
        xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,NULL
        ,'P')
      FROM
        gl_code_combinations_kfv gl_code_combinations
      WHERE
        code_combination_id = dr_code_combination_id
    )
    rawcostdebitaccount,
    ------end
    NULL burdenedcostcreditccid,
    NULL burdenedcostcreditaccount,
    NULL burdenedcostdebitccid,
    NULL burdenedcostdebitaccount,
    NULL burdencostdebitccid,
    NULL burdencostdebitaccount,
    NULL burdencostcreditccid,
    NULL burdencostcreditaccount,
    NULL providerledgercurrencycode,
    NULL providerledgercurrency,
    raw_cost rawcostledgercurrency,
    NULL burdenedcostledgercurrency,
    NULL providerledgerratetype,
    NULL providerledgerratedate,
    NULL providerledgerdatetype,
    NULL providerledgerrate,
    NULL providerledgerroundinglimit,
    NULL converted,
    NULL contextcategory,
    NULL userdefinedattribute1,
    NULL userdefinedattribute2,
    NULL userdefinedattribute3,
    NULL userdefinedattribute4,
    NULL userdefinedattribute5,
    NULL userdefinedattribute6,
    NULL userdefinedattribute7,
    NULL userdefinedattribute8,
    NULL userdefinedattribute9,
    NULL userdefinedattribute10,
    NULL fundingsourceid,
    NULL reservedattribute2,
    NULL reservedattribute3,
    NULL reservedattribute4,
    NULL reservedattribute5,
    NULL reservedattribute6,
    NULL reservedattribute7,
    NULL reservedattribute8,
    NULL reservedattribute9,
    NULL reservedattribute10,
    DECODE(expd.org_id,404,'OD US Fin BU',403, 'OD CA Fin BU') attributecategory ,
    expd.attribute1 attribute1,
    expd.attribute2 attribute2,
    expd.attribute3 attribute3,
    expd.attribute4 attribute4,
    expd.attribute5 attribute5,
    expd.attribute6 attribute6,
    (
      SELECT
        vendor_name
      FROM
        ap_suppliers
      WHERE
        vendor_id = expd.vendor_id
    )
    attribute7,
    (
      SELECT
        segment1
      FROM
        ap_suppliers
      WHERE
        vendor_id = expd.vendor_id
    )
    attribute8,
    (
      SELECT
        ai.invoice_num
      FROM
        ap_invoices_all ai
      WHERE
        1              =1
      AND ai.invoice_id=expd.document_header_id
    )
    attribute9,
    (
      SELECT
        TO_CHAR(ai.invoice_date,'YYYY/MM/DD')
      FROM
        ap_invoices_all ai
      WHERE
        1              =1
      AND ai.invoice_id=expd.document_header_id
    )
    attribute10
  FROM
    pa_expenditure_comments ec,
    pa_cost_distribution_lines_all cd,
    pa_transaction_sources src,
    pa_expenditure_types exptyp,
    hr_operating_units ou,
    pa_expenditure_items_all expd,
    pa_tasks task,
    pa_projects_all prj
  WHERE
    1                              =1
  AND prj.template_flag            = 'N'
  AND NVL(prj.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
  AND
    (
      prj.segment1 NOT LIKE 'PB%'
    AND prj.segment1 NOT LIKE 'NB%'
    AND prj.segment1 NOT LIKE 'TEM%'
    )
  AND prj.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
  AND prj.project_status_code IN ('APPROVED','CLOSED','1000')
  AND prj.org_id              <>403
  AND task.project_id          = prj.project_id
  AND expd.project_id          = prj.project_id
  AND expd.task_id             = task.task_id
  AND ou.organization_id       =expd.org_id
    --------------- Not Capitalizable  --------------
  AND expd.billable_flag            = 'N'
  AND expd.revenue_distributed_flag = 'N'
    --------------------------------------------
  AND exptyp.expenditure_type = expd.expenditure_type
  AND src.transaction_source  =expd.transaction_source
  AND cd.expenditure_item_id  = expd.expenditure_item_id
    -----------------
  AND cd.line_num =
    (
      SELECT
        MAX(line_num)
      FROM
        pa_cost_distribution_lines_all d
      WHERE
        d.expenditure_item_id = expd.expenditure_item_id
      AND d.line_type         = 'R'
    )
    ------------------
  AND ec.expenditure_item_id=expd.expenditure_item_id
    -- Begin Added for pstgb
  AND prj.created_from_project_id IN
  (
      SELECT
        project_id
      FROM
        pa_projects_all
      WHERE template_flag='Y'
        AND name       =NVL(p_proj_template,name)--'US IT Template - Labor Only'
    )
    -- End added for PSTGB
  ORDER BY
    prj.segment1,
    task.task_number,
    expd.expenditure_item_id;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  lc_rawcostcreditaccount VARCHAR2(100);
BEGIN
  /* BEGIN
  SELECT directory_path
  INTO l_file_path
  FROM dba_directories
  WHERE directory_name = 'XXFIN_OUTBOUND';
  EXCEPTION
  WHEN OTHERS THEN
  l_file_path := NULL;
  END;*/
  print_debug_msg ('Package fbdi_proj_exp_nei_nn START', true);
  l_file_name := 'fbdi_ProjectExpenditure_Neither_NN' || '.csv';--
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='TRANSACTIONTYPE'|| ','|| 'BUSINESSUNITNAME'|| ','||
  'BUSINESSUNITID'|| ','|| 'TRANSACTIONSOURCE'|| ','|| 'TRANSACTIONSOURCEID'||
  ','|| 'DOCUMENT'|| ','|| 'DOCUMENTID'|| ','|| 'DOCUMENTENTRY'|| ','||
  'DOCUMENTENTRYID'|| ','|| 'EXPENDITUREBATCH'|| ','|| 'BATCHENDINGDATE'|| ','
  || 'BATCHDESCRIPTION'|| ','|| 'EXPENDITUREITEMDATE'|| ','|| 'PERSONNUMBER'||
  ','|| 'PERSONNAME'|| ','|| 'PERSONID'|| ','|| 'HUMANRESOURCESASSIGNMENT'||
  ','|| 'HUMANRESOURCESASSIGNMENTID'|| ','|| 'PROJECTNUMBER'|| ','||
  'PROJECT_NAME'|| ','|| 'PROJECTID'|| ','|| 'TASKNUMBER'|| ','|| 'TASK_NAME'||
  ','|| 'TASKID'|| ','|| 'EXPENDITURETYPE'|| ','|| 'EXPENDITURETYPEID'|| ','||
  'EXPENDITURE_ORGANIZATION'|| ','|| 'EXPENDITUREORGANIZATIONID'|| ','||
  'CONTRACT_NUMBER'|| ','|| 'CONTRACT_NAME'|| ','|| 'CONTRACT_ID'|| ','||
  'FUNDING_SOURCE_NUMBER'|| ','|| 'FUNDING_SOURCE_NAME'|| ','|| 'QUANTITY'||
  ','|| 'UNIT_OF_MEASURE_NAME'|| ','|| 'UNIT_OF_MEASURE_CODE'|| ','||
  'WORKTYPE'|| ','|| 'WORKTYPEID'|| ','|| 'BILLABLE'|| ','|| 'CAPITALIZABLE'||
  ','|| 'ACCRUAL_ITEM'|| ','|| 'ORIG_TRANSACTION_REFERENCE'|| ','||
  'UNMATCHEDNEGATIVETRANSACTION'|| ','|| 'REVERSEDORIGINALTRANSACTION'|| ','||
  'EXPENDITUREITEMCOMMENT'|| ','|| 'ACCOUNTINGDATE'|| ','||
  'TRANSACTIONCURRENCYCODE'|| ','|| 'TRANSACTIONCURRENCY'|| ','||
  'RAWCOSTINTRXCURRENCY'|| ','|| 'BURDENEDCOSTINTRXCURRENCY'|| ','||
  'RAWCOSTCREDITCCID'|| ','|| 'RAWCOSTCREDITACCOUNT'|| ','|| 'RAWCOSTDEBITCCID'
  || ','|| 'RAWCOSTDEBITACCOUNT'|| ','|| 'BURDENEDCOSTCREDITCCID'|| ','||
  'BURDENEDCOSTCREDITACCOUNT'|| ','|| 'BURDENEDCOSTDEBITCCID'|| ','||
  'BURDENEDCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTDEBITCCID'|| ','||
  'BURDENCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTCREDITCCID'|| ','||
  'BURDENCOSTCREDITACCOUNT'|| ','|| 'PROVIDERLEDGERCURRENCYCODE'|| ','||
  'PROVIDERLEDGERCURRENCY'|| ','|| 'RAWCOSTLEDGERCURRENCY'|| ','||
  'BURDENEDCOSTLEDGERCURRENCY'|| ','|| 'PROVIDERLEDGERRATETYPE'|| ','||
  'PROVIDERLEDGERRATEDATE'|| ','|| 'PROVIDERLEDGERDATETYPE'|| ','||
  'PROVIDERLEDGERRATE'|| ','|| 'PROVIDERLEDGERROUNDINGLIMIT'|| ','||
  'CONVERTED'|| ','|| 'CONTEXTCATEGORY'|| ','|| 'USERDEFINEDATTRIBUTE1'|| ','||
  'USERDEFINEDATTRIBUTE2'|| ','|| 'USERDEFINEDATTRIBUTE3'|| ','||
  'USERDEFINEDATTRIBUTE4'|| ','|| 'USERDEFINEDATTRIBUTE5'|| ','||
  'USERDEFINEDATTRIBUTE6'|| ','|| 'USERDEFINEDATTRIBUTE7'|| ','||
  'USERDEFINEDATTRIBUTE8'|| ','|| 'USERDEFINEDATTRIBUTE9'|| ','||
  'USERDEFINEDATTRIBUTE10'|| ','|| 'FUNDINGSOURCEID'|| ','||
  'RESERVEDATTRIBUTE2'|| ','|| 'RESERVEDATTRIBUTE3'|| ','||
  'RESERVEDATTRIBUTE4'|| ','|| 'RESERVEDATTRIBUTE5'|| ','||
  'RESERVEDATTRIBUTE6'|| ','|| 'RESERVEDATTRIBUTE7'|| ','||
  'RESERVEDATTRIBUTE8'|| ','|| 'RESERVEDATTRIBUTE9'|| ','||
  'RESERVEDATTRIBUTE10'|| ','|| 'ATTRIBUTECATEGORY'|| ','|| 'ATTRIBUTE1'|| ','
  || 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','||
  'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'||
  ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_proj_nn
  LOOP
	
    lc_rawcostcreditaccount:=NULL;
	IF i.transactionsource LIKE '%Payables%' THEN
	   lc_rawcostcreditaccount:='1150.43.00000.211143.10000.0000';
	ELSE
	   lc_rawcostcreditaccount:=i.rawcostcreditaccount;
	END IF;
	
    utl_file.put_line(lc_file_handle,'"'||i.transactiontype|| '","'||
    i.businessunitname|| '","'|| i.businessunitid|| '","'|| i.transactionsource
    || '","'|| i.transactionsourceid|| '","'|| i.document|| '","'||
    i.documentid|| '","'|| i.documententry|| '","'|| i.documententryid|| '","'
    || i.expenditurebatch|| '","'|| i.batchendingdate|| '","'||
    i.batchdescription|| '","'|| i.expenditureitemdate|| '","'|| i.personnumber
    || '","'|| i.personname|| '","'|| i.personid|| '","'||
    i.humanresourcesassignment|| '","'|| i.humanresourcesassignmentid|| '","'||
    i.projectnumber|| '","'|| i.project_name|| '","'|| i.projectid|| '","'||
    i.tasknumber|| '","'|| i.task_name|| '","'|| i.taskid|| '","'||
    i.expendituretype|| '","'|| i.expendituretypeid|| '","'||
    i.expenditure_organization|| '","'|| i.expenditureorganizationid|| '","'||
    i.contract_number|| '","'|| i.contract_name|| '","'|| i.contract_id|| '","'
    || i.funding_source_number|| '","'|| i.funding_source_name|| '","'||
    i.quantity|| '","'|| i.unit_of_measure_name|| '","'||
    i.unit_of_measure_code|| '","'|| i.worktype|| '","'|| i.worktypeid|| '","'
    || i.billable|| '","'|| i.capitalizable|| '","'|| i.accrual_item|| '","'||
    i.orig_transaction_reference|| '","'|| i.unmatchednegativetransaction||
    '","'|| i.reversedoriginaltransaction|| '","'|| i.expenditureitemcomment||
    '","'|| i.accountingdate|| '","'|| i.transactioncurrencycode|| '","'||
    i.transactioncurrency|| '","'|| i.rawcostintrxcurrency|| '","'||
    i.burdenedcostintrxcurrency|| '","'|| i.rawcostcreditccid|| '","'||
    lc_rawcostcreditaccount|| '","'|| i.rawcostdebitccid|| '","'||
    i.rawcostdebitaccount|| '","'|| i.burdenedcostcreditccid|| '","'||
    i.burdenedcostcreditaccount|| '","'|| i.burdenedcostdebitccid|| '","'||
    i.burdenedcostdebitaccount|| '","'|| i.burdencostdebitccid|| '","'||
    i.burdencostdebitaccount|| '","'|| i.burdencostcreditccid|| '","'||
    i.burdencostcreditaccount|| '","'|| i.providerledgercurrencycode|| '","'||
    i.providerledgercurrency|| '","'|| i.rawcostledgercurrency|| '","'||
    i.burdenedcostledgercurrency|| '","'|| i.providerledgerratetype|| '","'||
    i.providerledgerratedate|| '","'|| i.providerledgerdatetype|| '","'||
    i.providerledgerrate|| '","'|| i.providerledgerroundinglimit|| '","'||
    i.converted|| '","'|| i.contextcategory|| '","'|| i.userdefinedattribute1||
    '","'|| i.userdefinedattribute2|| '","'|| i.userdefinedattribute3|| '","'||
    i.userdefinedattribute4|| '","'|| i.userdefinedattribute5|| '","'||
    i.userdefinedattribute6|| '","'|| i.userdefinedattribute7|| '","'||
    i.userdefinedattribute8|| '","'|| i.userdefinedattribute9|| '","'||
    i.userdefinedattribute10|| '","'|| i.fundingsourceid|| '","'||
    i.reservedattribute2|| '","'|| i.reservedattribute3|| '","'||
    i.reservedattribute4|| '","'|| i.reservedattribute5|| '","'||
    i.reservedattribute6|| '","'|| i.reservedattribute7|| '","'||
    i.reservedattribute8|| '","'|| i.reservedattribute9|| '","'||
    i.reservedattribute10|| '","'|| i.attributecategory|| '","'|| i.attribute1
    || '","'|| i.attribute2|| '","'|| i.attribute3|| '","'|| i.attribute4||
    '","'|| i.attribute5|| '","'|| i.attribute6|| '","'|| i.attribute7|| '","'
    || i.attribute8|| '","'|| i.attribute9|| '","'|| i.attribute10||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' ||
  ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_proj_exp_nei_nn;
PROCEDURE fbdi_pa_budgets(
    p_proj_template VARCHAR2)
IS
  CURSOR c_proj_budget
  IS
    SELECT
      NULL Award_Number ,
      pln.name Financial_Plan_Type ,
      pap.segment1 Project_number ,
      trim(REPLACE(REPLACE(REPLACE(REPLACE(pap.name,chr(13), ''), chr(10), ''),
      chr(39),''),chr(63),'')) Project_Name ,
      pat.Task_Number ,
      REPLACE(REPLACE(REPLACE(REPLACE(pat.task_name,chr(13), ''), chr( 10), '')
      ,chr(39),''),chr(63),'') task_Name ,
      BV.BUDGET_STATUS_CODE
      || '_'
      || bv.version_name version_name ,
      REPLACE(REPLACE(REPLACE(REPLACE(bv.description,chr(13), ''), chr( 10), ''
      ),chr(39),''),chr(63),'') description ,
      bv.budget_status_code plan_version_status ,
      m.alias resource_name ,
      NULL Funding_Source_Number ,
      NULL Funding_Source_Name ,
      'LINE' Line_Type ,
      i.period_name ,
      TO_CHAR(i.Start_Date,'YYYY/MM/DD') start_date ,
      TO_CHAR(i.end_date,'YYYY/MM/DD') Finish_Date ,
      i.project_currency_code Planning_Currency ,
     -- i.quantity ,
	  null quantity,
      NVL(i.raw_cost,0) Total_Raw_Cost,
      NULL total_burdened_cost ,    -- based on comments by PWC
      i.revenue Total_Revenue ,
      NULL Tot_Raw_Cost_Proj_Curr ,
      NULL Tot_Burden_Cost_Proj_Curr ,
      NULL tot_rev_proj_curr ,
      NULL Tot_Raw_Cost_Ledg_Curr ,---Priyam Changed it from
      -- Tot_Raw_Cost_Proj_Curr
      NULL Tot_Burden_Cost_Ledg_Curr ,
      NULL tot_revenue_ledg_curr ,
      bv.budget_version_id src_budget_line_ref,
      i.attribute_category,
      i.attribute1,
      i.attribute2,
      i.attribute3,
      i.attribute4,
      i.attribute5,
      i.attribute6,
      i.attribute7,
      i.attribute8,
      i.attribute9,
      i.attribute10,
      i.attribute11,
      i.attribute12,
      i.attribute13,
      i.attribute14,
      i.attribute15
    FROM
      pa_fin_plan_types_vl pln,
      pa_budget_versions bv,
      pa_tasks pat,
      pa_lookups l2,
      pa_lookups l1,
      pa_budget_lines i,
      pa_resource_list_members m,
      pa_resource_assignments a,
      pa_projects_all pap
    WHERE
      1                              =1
    AND pap.template_flag            = 'N'
    AND NVL(pap.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
    AND
      (
        pap.segment1 NOT LIKE 'PB%'
      AND pap.segment1 NOT LIKE 'NB%'
      AND pap.segment1 NOT LIKE 'TEM%'
      )
    AND pap.project_type NOT        IN ('PB_PROJECT','DI_PB_PROJECT')
    AND pap.project_status_code     IN ('APPROVED','CLOSED','1000')
    AND pap.org_id                  <>403
    AND a.project_id                 =pap.project_id
    AND pat.task_id                  = a.task_id
    AND i.resource_assignment_id     = a.resource_assignment_id
    AND m.resource_list_member_id    =a.resource_list_member_id
    AND NVL(m.migration_code,'-99') <> 'N'
    AND a.unit_of_measure            = l1.lookup_code (+)
    AND l1.lookup_type (+)           = 'UNIT'
    AND i.change_reason_code         = l2.lookup_code (+)
    AND l2.lookup_type (+)           = 'BUDGET CHANGE REASON'
    AND BV.BUDGET_VERSION_ID         = a.BUDGET_VERSION_ID
    AND BV.BUDGET_TYPE_CODE          ='AC'
    AND
      (
        BV.BUDGET_STATUS_CODE = 'W'
      OR
        (
          BV.BUDGET_STATUS_CODE = 'B'
        AND BV.CURRENT_FLAG     = 'Y'
        )
      )
    AND bv.fin_plan_type_id = pln.fin_plan_type_id (+)
      -- Begin Added for pstgb
    AND pap.created_from_project_id IN ( SELECT project_id
										   FROM pa_projects_all
										  WHERE template_flag='Y'
										    AND name=NVL(p_proj_template,name)--'US IT Template - Labor Only'
									   )
    -- End added for PSTGB
  ORDER BY
    pap.segment1,
    pat.task_number;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
BEGIN
  print_debug_msg ('Package fbdi_pa_budgets START', true);
  l_file_name    := 'fbdi_pa_budgets' || '.csv';
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='AWARD_NUMBER'|| ','|| 'FINANCIAL_PLAN_TYPE'|| ','||
  'PROJECT_NUMBER'|| ','|| 'PROJECT_NAME'|| ','|| 'TASK_NUMBER'|| ','||
  'TASK_NAME'|| ','|| 'VERSION_NAME'|| ','|| 'DESCRIPTION'|| ','||
  'PLAN_VERSION_STATUS'|| ','|| 'RESOURCE_NAME'|| ','|| 'FUNDING_SOURCE_NUMBER'
  || ','|| 'FUNDING_SOURCE_NAME'|| ','|| 'LINE_TYPE'|| ','|| 'PERIOD_NAME'||
  ','|| 'START_DATE'|| ','|| 'FINISH_DATE'|| ','|| 'PLANNING_CURRENCY'|| ','||
  'QUANTITY'|| ','|| 'TOTAL_RAW_COST'|| ','|| 'TOTAL_BURDENED_COST'|| ','||
  'TOTAL_REVENUE'|| ','|| 'TOT_RAW_COST_PROJ_CURR'|| ','||
  'TOT_BURDEN_COST_PROJ_CURR'|| ','|| 'TOT_REV_PROJ_CURR'|| ','||
  'TOT_RAW_COST_PROJ_CURR'|| ','|| 'TOT_BURDEN_COST_LEDG_CURR'|| ','||
  'TOT_REVENUE_LEDG_CURR'|| ','|| 'SRC_BUDGET_LINE_REF'|| ','||
  'ATTRIBUTE_CATEGORY'|| ','|| 'ATTRIBUTE1'|| ','|| 'ATTRIBUTE2'|| ','||
  'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','|| 'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'||
  ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'|| ','|| 'ATTRIBUTE9'|| ','||
  'ATTRIBUTE10'|| ','|| 'ATTRIBUTE11'|| ','|| 'ATTRIBUTE12'|| ','||
  'ATTRIBUTE13'|| ','|| 'ATTRIBUTE14'|| ','|| 'ATTRIBUTE15' ;
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_proj_budget
  LOOP
    
    utl_file.put_line(lc_file_handle,'"'||i.award_number|| '","'||
    i.financial_plan_type|| '","'|| i.project_number|| '","'|| i.project_name||
    '","'|| i.task_number || '","'|| i.task_name|| '","'|| i.version_name||
    '","'|| i.description|| '","'|| i.plan_version_status || '","'||
    i.resource_name|| '","'|| i.funding_source_number|| '","'||
    i.funding_source_name|| '","'|| i.line_type|| '","'|| i.period_name|| '","'
    || i.start_date|| '","'|| i.finish_date|| '","'|| i.planning_currency ||
    '","'|| i.quantity || '","'|| i.total_raw_cost|| '","'||
    i.total_burdened_cost|| '","'|| i.total_revenue|| '","'||
    i.tot_raw_cost_proj_curr|| '","'|| i.tot_burden_cost_proj_curr|| '","'||
    i.tot_rev_proj_curr|| '","'|| i.tot_raw_cost_ledg_curr|| '","'||
    i.tot_burden_cost_ledg_curr|| '","'|| i.tot_revenue_ledg_curr|| '","'||
    i.src_budget_line_ref|| '","'|| i.attribute_category|| '","'|| i.attribute1
    || '","'|| i.attribute2|| '","'|| i.attribute3|| '","'|| i.attribute4||
    '","'|| i.attribute5|| '","'|| i.attribute6|| '","'|| i.attribute7||'","'||
    i.attribute8|| '","'|| i.attribute9|| '","' || i.attribute10|| '","'||
    i.attribute11|| '","'|| i.attribute12|| '","'|| i.attribute13|| '","'||
    i.attribute14|| '","'|| i.attribute15||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' || ' file_open :: '
  || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' ||
  ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_pa_budgets procedure :- ' || ' OTHERS :: ' ||
  SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_pa_budgets;
PROCEDURE fbdi_proj_asset_assignments(
    p_proj_template VARCHAR2)
IS
  CURSOR c_proj_asset_assign
  IS
    SELECT
      'Demo_create' demo_create,
      'Create' create_mode,
      NULL Asset_Assignment_Id,
      NULL project_asset_id,
      ppa.asset_name,
      ppa.asset_number,
      -- x.wbs_level
      'Task Level Assignment' asset_assigment_level,
      NULL project_id,
      trim(REPLACE(REPLACE(REPLACE(REPLACE(proj.name,chr(13), ''), chr(10), '')
      ,chr(39),''),chr(63),'')) Project_Name,
      proj.SEGMENT1 Project_Number,
      NULL Task_Id,
      REPLACE(REPLACE(REPLACE(REPLACE(x.task_name,chr(13), ''), chr(10) , ''),
      chr(39),''),chr(63),'') task_Name,
      x.task_number
    FROM
      pa_project_assets_all ppa,
      pa_tasks x,
      PA_Project_Asset_Assignments paa,
      pa_projects_all proj
    WHERE
      1                               =1
    AND proj.template_flag            = 'N'
    AND NVL(proj.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
    AND
      (
        proj.segment1 NOT LIKE 'PB%'
      AND proj.segment1 NOT LIKE 'NB%'
      AND proj.segment1 NOT LIKE 'TEM%'
      )
    AND proj.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
    AND proj.project_status_code IN ('APPROVED','CLOSED','1000')
    AND proj.org_id              <>403
    AND paa.project_id            =proj.project_id
    AND ppa.project_id            =proj.project_id
    AND ppa.project_asset_type    = 'ESTIMATED'
    AND ppa.project_asset_id      =paa.project_asset_id
    AND x.project_id              =proj.project_id
    AND x.task_id                 =paa.task_id
      -- Begin Added for pstgb
    AND proj.created_from_project_id IN
      (
        SELECT
          project_id
        FROM
          pa_projects_all
        WHERE
          template_flag='Y'
        AND name       =NVL(p_proj_template,name)--'US IT Template - Labor Only
          -- '
      )
    -- End added for PSTGB
  ORDER BY
    proj.SEGMENT1;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
BEGIN
  print_debug_msg ('Package fbdi_proj_asset_assignments START', true);
  ---  print_debug_msg ('P_BOOK_TYPE_CODE '||P_BOOK_TYPE_CODE, TRUE);
  l_file_name := 'fbdi_proj_asset_assignments' || '.csv';--
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='DEMO_CREATE'|| ','|| 'CREATE_MODE'|| ','||
  'ASSET_ASSIGNMENT_ID'|| ','|| 'PROJECT_ASSET_ID'|| ','|| 'ASSET_NAME'|| ','||
  'ASSET_NUMBER'|| ','|| 'ASSET_ASSIGMENT_LEVEL'|| ','|| 'PROJECT_ID'|| ','||
  'PROJECT_NAME'|| ','|| 'PROJECT_NUMBER'|| ','|| 'TASK_ID'|| ','|| 'TASK_NAME'
  || ','|| 'TASK_NUMBER' ;
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_proj_asset_assign
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,'"'||i.DEMO_CREATE|| '","'|| i.CREATE_MODE
    || '","'|| i.ASSET_ASSIGNMENT_ID|| '","'|| i.PROJECT_ASSET_ID|| '","'||
    i.ASSET_NAME|| '","'|| i.ASSET_NUMBER|| '","'|| i.ASSET_ASSIGMENT_LEVEL||
    '","'|| i.PROJECT_ID|| '","'|| i.PROJECT_NAME|| '","'|| i.PROJECT_NUMBER||
    '","'|| i.TASK_ID|| '","'|| i.TASK_NAME|| '","'|| i.task_number||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_proj_asset_assignments procedure :- ' ||
  ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_proj_asset_assignments;
PROCEDURE fbdi_proj_classif_lob(
    p_proj_template VARCHAR2)
IS
  CURSOR c_proj_classif_lob
  IS
    SELECT
      trim(REPLACE(REPLACE(REPLACE(REPLACE(pap.name,chr(13), ''), chr(10), ''),
      chr(39),''),chr(63),'')) Project_Name ,
      'LOB' Class_Category ,
      org.name Class_Code ,
      NULL code_percentage
    FROM
      hr_all_organization_units org,
      pa_projects_all pap
    WHERE
      1                   = 1
    AND pap.template_flag = 'N'
      --   and NVL(pap.closed_date,sysdate) > add_months(sysdate,-6)
    AND NVL(pap.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
    AND pap.template_flag            = 'N'
    AND
      (
        pap.segment1 NOT LIKE 'PB%'
      AND pap.segment1 NOT LIKE 'NB%'
      AND pap.segment1 NOT LIKE 'TEM%'
      )
    AND pap.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
    AND pap.org_id              <>403
    AND pap.project_status_code IN ('APPROVED','CLOSED','1000')
    AND org.organization_id      =pap.carrying_out_organization_id
      -- Begin Added for pstgb
    AND pap.created_from_project_id IN ( SELECT project_id
										   FROM pa_projects_all
                                          WHERE template_flag='Y'
                                            AND name=NVL(p_proj_template,name)--'US IT Template - Labor Only'
									   )
    -- End added for PSTGB
  ORDER BY
    pap.segment1;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
BEGIN
  print_debug_msg ('Package fbdi_proj_classif_lob START', true);
  l_file_name := 'fbdi_proj_classif_lob' || '.csv';--
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='PROJECT_NAME'|| ','|| 'CLASS_CATEGORY'|| ','|| 'CLASS_CODE'
  || ','|| 'CODE_PERCENTAGE';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_proj_classif_lob
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,'"'||i.PROJECT_NAME|| '","'||
    i.CLASS_CATEGORY|| '","'|| i.CLASS_CODE|| '","'|| i.code_percentage||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_proj_classif_lob procedure :- ' ||
  ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_proj_classif_lob;
PROCEDURE fbdi_proj_classification(
    p_proj_template VARCHAR2)
IS
  CURSOR c_proj_classification
  IS
    SELECT
      trim(REPLACE(REPLACE(REPLACE(REPLACE(pap.name,chr(13), ''), chr(10), ''),
      chr(39),''),chr(63),'')) Project_Name ,
      ppc.Class_Category ,
      ppc.Class_Code ,
      ppc.code_percentage
    FROM
      PA_PROJECT_CLASSES ppc,
      pa_projects_all pap
    WHERE
      1                              = 1
    AND pap.template_flag            = 'N'
    AND NVL(pap.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
    AND pap.template_flag            = 'N'
    AND
      (
        pap.segment1 NOT LIKE 'PB%'
      AND pap.segment1 NOT LIKE 'NB%'
      AND pap.segment1 NOT LIKE 'TEM%'
      )
    AND pap.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
    AND pap.org_id              <>403
    AND pap.project_status_code IN ('APPROVED','CLOSED','1000')
    AND ppc.project_id           =pap.project_id
      -- Begin Added for pstgb
    AND pap.created_from_project_id IN ( SELECT project_id
                                           FROM pa_projects_all
                                          WHERE template_flag='Y'
                                            AND name       =NVL(p_proj_template,name)
									   )
    -- End added for PSTGB
    --   and ppc.class_code is not null
  ORDER BY
    pap.project_id;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
BEGIN
  print_debug_msg ('Package fbdi_proj_classification START', true);
  l_file_name := 'fbdi_proj_classification' || '.csv';--
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='PROJECT_NAME'|| ','|| 'CLASS_CATEGORY'|| ','|| 'CLASS_CODE'
  || ','|| 'CODE_PERCENTAGE';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_proj_classification
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,'"'||i.PROJECT_NAME|| '","'||
    i.CLASS_CATEGORY|| '","'|| i.CLASS_CODE|| '","'|| i.code_percentage||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_proj_classification procedure :- ' ||
  ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_proj_classification;
/*
PROCEDURE fbdi_proj_team_members(
    p_proj_template VARCHAR2)
IS
  CURSOR c_proj_team_members
  IS
    SELECT DISTINCT
      trim(REPLACE(REPLACE(REPLACE(REPLACE(ppa.name,chr(13), ''), chr(10), ''),
      chr(39),''),chr(63),'')) Project_Name ,
      pe.employee_number,
      --- PE.FULL_NAME employee_name, Commented by Priyam as confirmed from pwc
      NULL employee_name,
      --pe.EMAIL_ADDRESS,		-- Non prod only
	  pe.employee_number||'@officedepot.com' email_address,  -- Non prod only
      DECODE( DECODE (PA.ASSIGNMENT_ID, NULL, PPRT.MEANING, PA.ASSIGNMENT_NAME)
      , 'Business Manager','Project Manager', 'Director Business Development',
      'Project Accounting', DECODE (PA.ASSIGNMENT_ID, NULL, PPRT.MEANING,
      PA.ASSIGNMENT_NAME) ) project_role,
      --      TO_CHAR(PPP.START_DATE_ACTIVE,'YYYY/MM/DD') start_date_active,
      --      TO_CHAR(ppp.end_date_active,'YYYY/MM/DD')   end_date_active,
      CASE
        WHEN PPP.START_DATE_ACTIVE < ppa.START_DATE
        THEN ( TO_CHAR(ppa.START_DATE,'YYYY/MM/DD') )
        --ELSE ( TO_CHAR(PPP.START_DATE_ACTIVE,'YYYY/MM/DD') )
		ELSE ( TO_CHAR(SYSDATE,'YYYY/MM/DD') )
      END start_date_active,
      CASE
        WHEN PPP.END_DATE_ACTIVE > ppa.COMPLETION_DATE
        THEN ( TO_CHAR(ppa.COMPLETION_DATE,'YYYY/MM/DD') )
		ELSE ( TO_CHAR(ppp.end_date_active,'YYYY/MM/DD') )
      END end_date_active,
      NULL Percent_Allocation,
      NULL Effort_in_Hours,
      NULL Cost_Rate,
      NULL Bill_Rate,
      NULL track_time
    FROM
      PA_PROJECT_PARTIES PPP,
      PA_PROJECTS_ALL PPA,
      PA_PROJECT_ROLE_TYPES PPRT,
      PER_ALL_PEOPLE_F PE,
      PA_PROJECT_ASSIGNMENTS PA,
      fnd_user u,
      (
        SELECT
          pj.name job_name,
          haou.organization_id org_id,
          haou.name org_name,
          paf.person_id,
          paf.assignment_type
        FROM
          per_all_assignments_f paf,
          per_jobs pj,
          hr_all_organization_units haou
        WHERE
          TRUNC (SYSDATE) BETWEEN TRUNC (paf.effective_start_date) AND TRUNC (
          paf.effective_end_date)
        AND paf.primary_flag      = 'Y'
        AND paf.organization_id   = haou.organization_id
        AND NVL (paf.job_id, -99) = pj.job_id(+)  
      )
    prd
  WHERE
    PPP.RESOURCE_TYPE_ID = 101
  AND ppa.project_id    IN
    (
      SELECT
        project_id
      FROM
        pa_projects_all
      WHERE
        1                          =1
      AND NVL(closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
      AND template_flag            = 'N'
      AND
        (
          segment1 NOT LIKE 'PB%'
        AND segment1 NOT LIKE 'NB%'
        AND segment1 NOT LIKE 'TEM%'
        )
      AND project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
      AND project_status_code IN ('APPROVED','CLOSED','1000')
      AND org_id              <>403
    )
  AND PPP.PROJECT_ID          = PPA.PROJECT_ID
  AND PPP.PROJECT_ROLE_ID     = PPRT.PROJECT_ROLE_ID
  AND PPP.RESOURCE_SOURCE_ID  = PE.PERSON_ID
  AND PE.EFFECTIVE_START_DATE =
    (
      SELECT
        MIN (PAPF.EFFECTIVE_START_DATE)
      FROM
        PER_ALL_PEOPLE_F PAPF
      WHERE
        PAPF.PERSON_ID             = PE.PERSON_ID
      AND PAPF.EFFECTIVE_END_DATE >= TRUNC (SYSDATE)
    )
  AND NVL (PE.EFFECTIVE_END_DATE, SYSDATE + 1) >= TRUNC (SYSDATE)
  AND NVL (PPP.END_DATE_ACTIVE, SYSDATE   + 1) >= TRUNC (SYSDATE)
  AND PPP.PROJECT_PARTY_ID                      = PA.PROJECT_PARTY_ID(+)
  AND NVL (prd.assignment_type, '-99')         IN ('C', DECODE ( DECODE (
    PE.CURRENT_EMPLOYEE_FLAG, 'Y', 'Y', DECODE (PE.CURRENT_NPW_FLAG, 'Y', 'Y',
    'N')), 'Y', 'E', 'B'), 'E', '-99')
  AND ppp.resource_source_id = prd.person_id(+)
  AND u.employee_id(+)       = ppp.resource_source_id
  AND ppp.object_type        = 'PA_PROJECTS'
  AND ppp.object_id          = ppa.project_id
    -- Begin Added for pstgb
  AND ppa.created_from_project_id IN
    (
      SELECT
        project_id
      FROM
        pa_projects_all
      WHERE
        template_flag='Y'
      AND name       =NVL(p_proj_template,name)--'US IT Template - Labor Only'
    )
    -- End added for PSTGB
  ORDER BY
    project_name,
    pe.EMPLOYEE_NUMBER;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);
  v_emp_cnt    NUMBER;
  v_employee_num per_all_people_f.employee_number%Type;
BEGIN
  print_debug_msg ('Package fbdi_proj_team_members START', true);
  l_file_name := 'fbdi_proj_team_members' || '.csv';--
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='PROJECT_NAME'|| ','||'EMPLOYEE_NUMBER'|| ','
  || 'EMPLOYEE_NAME'|| ','
  || 'EMAIL_ADDRESS'|| ','|| 'PROJECT_ROLE'|| ','|| 'START_DATE_ACTIVE'|| ','||
  ' END_DATE_ACTIVE'|| ','|| 'PERCENT_ALLOCATION'|| ','|| 'EFFORT_IN_HOURS'||
  ','|| 'COST_RATE'|| ','|| 'BILL_RATE'|| ','|| 'TRACK_TIME';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_proj_team_members
  LOOP
    --v_employee_num:='198158';  -- For SIT Only 
   
    BEGIN
      SELECT
        COUNT(1)
      INTO
        v_emp_cnt
      FROM
        per_all_people_f a
      WHERE
        employee_number=i.employee_number
        AND  person_type_id=6
      AND NVL(TO_CHAR(effective_end_date,'DD-MON-YYYY'),'31-DEC-4712') >= '31-DEC-4712';
      IF v_emp_cnt      =0 THEN
        v_employee_num :='725462';
      ELSE
        v_employee_num:=i.EMPLOYEE_NUMBER;
      END IF;
    END;
    
    utl_file.put_line(lc_file_handle,'"'||i.PROJECT_NAME|| '","'||
    v_employee_num|| '","'|| i.EMPLOYEE_NAME|| '","' || i.EMAIL_ADDRESS|| '","'
    || i.PROJECT_ROLE|| '","'|| i.START_DATE_ACTIVE|| '","'|| i.
    END_DATE_ACTIVE || '","'|| i.PERCENT_ALLOCATION|| '","'|| i.EFFORT_IN_HOURS
    || '","'|| i.COST_RATE|| '","'|| i.BILL_RATE|| '","'|| i.track_time||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_proj_team_members;
*/

PROCEDURE fbdi_proj_team_members(p_proj_template VARCHAR2)
IS

CURSOR c_main 
IS
SELECT DISTINCT
	   ppa.segment1
  FROM
       fnd_user u,
       per_all_people_f pe,
       pa_project_role_types pprt,
       pa_project_parties ppp,
       pa_projects_all ppa
 WHERE ppp.resource_type_id = 101
   AND ppa.project_id IN ( SELECT project_id
                             FROM pa_projects_all
                            WHERE 1=1
                              AND NVL(closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
                              AND template_flag='N'
                              AND (     segment1 NOT LIKE 'PB%'
								    AND segment1 NOT LIKE 'NB%'
									AND segment1 NOT LIKE 'TEM%'
								  )
                              AND project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
                              AND project_status_code IN ('APPROVED','CLOSED','1000')
                              AND org_id              <>403
                         )
   AND ppp.project_id          = ppa.project_id
   AND pprt.project_role_id=ppp.project_role_id     
   AND pe.person_id=ppp.resource_source_id
   AND u.employee_id(+)       = ppp.resource_source_id
   AND ppp.object_type        = 'PA_PROJECTS'
   AND ppp.object_id          = ppa.project_id
   AND ppa.created_from_project_id IN (SELECT project_id
										 FROM pa_projects_all
										WHERE template_flag='Y'
										  AND name=NVL(p_proj_template,name)
									  )
 ORDER BY ppa.segment1;
 
CURSOR c_proj_team_members(p_proj_no VARCHAR2)
IS
SELECT DISTINCT
	   ppa.project_status_code,
	   ppa.start_date,
	   ppa.completion_date,
       trim(REPLACE(REPLACE(REPLACE(REPLACE(ppa.name,chr(13), ''), chr(10), ''),
       chr(39),''),chr(63),'')) Project_Name ,
       DECODE(pe.employee_number,'950088','198158',pe.employee_number) employee_number,
       --- PE.FULL_NAME employee_name, Commented by Priyam as confirmed from pwc
       NULL employee_name,
       --pe.EMAIL_ADDRESS,		-- Non prod only
	   DECODE(pe.employee_number,'950088','198158',pe.employee_number)||'@officedepot.com' email_address,  -- Non prod only
       DECODE( pprt.meaning,'Business Manager','Project Manager', 
 	                       'Director Business Development','Project Accounting', 
			  pprt.meaning
            ) project_role,
       ppp.start_date_active start_date_active,
       ppp.end_date_active   end_date_active,
       NULL Percent_Allocation,
       NULL Effort_in_Hours,
       NULL Cost_Rate,
       NULL Bill_Rate,
       NULL track_time
  FROM
       fnd_user u,
       per_all_people_f pe,
       pa_project_role_types pprt,
       pa_project_parties ppp,
       pa_projects_all ppa
 WHERE ppa.segment1=p_proj_no
   AND ppp.resource_type_id = 101
   AND ppp.project_id          = ppa.project_id
   AND pprt.project_role_id=ppp.project_role_id     
   AND pe.person_id=ppp.resource_source_id
   AND u.employee_id(+)       = ppp.resource_source_id
   AND ppp.object_type        = 'PA_PROJECTS'
   AND ppp.object_id          = ppa.project_id;
   
  lc_file_handle 	utl_file.file_type;
  lv_line_count 	NUMBER;
  l_file_name  		VARCHAR2(100);
  lv_col_title 		VARCHAR2(5000);
  l_file_path  		VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  		VARCHAR2(1000);
  v_employee_num 	per_all_people_f.employee_number%Type;
  lc_start_date	    VARCHAR2(20);
  lc_end_date		VARCHAR2(20);
  ln_emp_cnt    	NUMBER;
  ln_term_cnt		NUMBER;
  lc_email_address  VARCHAR2(100);

BEGIN
  print_debug_msg ('Package fbdi_proj_team_members START', true);

  l_file_name := 'fbdi_proj_team_members' || '.csv';--
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='PROJECT_NAME'|| ','||'EMPLOYEE_NUMBER'|| ','
  || 'EMPLOYEE_NAME'|| ','
  || 'EMAIL_ADDRESS'|| ','|| 'PROJECT_ROLE'|| ','|| 'START_DATE_ACTIVE'|| ','||
  ' END_DATE_ACTIVE'|| ','|| 'PERCENT_ALLOCATION'|| ','|| 'EFFORT_IN_HOURS'||
  ','|| 'COST_RATE'|| ','|| 'BILL_RATE'|| ','|| 'TRACK_TIME';

  utl_file.put_line(lc_file_handle,lv_col_title);

  lc_start_date := TO_CHAR(SYSDATE,'YYYY/MM/DD');
  lc_end_date	 :=NULL;

  FOR cur IN c_main LOOP
    ln_term_cnt :=0;
    FOR i IN c_proj_team_members(cur.segment1)
    LOOP
	  lc_email_address:=NULL;
	  lc_email_address:=i.email_address;
      SELECT COUNT(1)
        INTO ln_emp_cnt
        FROM per_all_people_f a
       WHERE employee_number=i.employee_number
	     AND person_type_id=6
         AND SYSDATE BETWEEN effective_start_date and NVL(effective_end_date,SYSDATE);
      
      IF ln_emp_cnt=0 THEN
         ln_term_cnt:=ln_term_cnt+1;
         v_employee_num :='198158';
		 lc_email_address:='198158@officedepot.com';
      ELSE
         v_employee_num:=i.EMPLOYEE_NUMBER;
      END IF;
	  
	  IF ln_emp_cnt<>0 THEN
	     utl_file.put_line(lc_file_handle,'"'||i.PROJECT_NAME|| '","'||
         v_employee_num|| '","'|| i.employee_name|| '","' || lc_email_address|| '","'||
	     i.project_role|| '","'|| lc_start_date|| '","'|| lc_end_date|| '","'||
	     i.percent_allocation|| '","'|| i.effort_in_hours || '","'|| 
	     i.cost_rate|| '","'|| i.bill_rate|| '","'|| i.track_time||'"');
	  ELSE
        IF ln_term_cnt=1 THEN
  	      utl_file.put_line(lc_file_handle,'"'||i.PROJECT_NAME|| '","'||
          v_employee_num|| '","'|| i.employee_name|| '","' || lc_email_address|| '","'||
	      i.project_role|| '","'|| lc_start_date|| '","'|| lc_end_date|| '","'||
	      i.percent_allocation|| '","'|| i.effort_in_hours || '","'|| 
	      i.cost_rate|| '","'|| i.bill_rate|| '","'|| i.track_time||'"');
		END IF; 
	  END IF;
    END LOOP;
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_proj_team_members procedure :- ' ||
  ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_proj_team_members;

PROCEDURE fbdi_projects(
    p_proj_template VARCHAR2)
IS
  CURSOR c_projects
  IS
    SELECT
      trim(REPLACE(REPLACE(REPLACE(REPLACE(pap.name,chr(13), ''), chr(10), ''),
      chr(39),''),chr(63),'')) Project_Name ,
      pap.SEGMENT1 Project_Number ,
      (
        SELECT
          REPLACE(P.segment1,',',' ')
        FROM
          PA_PROJECTS_ALL P
        WHERE
          P.project_id = pap.created_from_project_id
      )
    SourceTemplateNumber ,
    NULL Source_Application_Code ,
    NVL(pap.pm_project_reference,'None') source_project_reference ,
    (
      SELECT
        hrprorg.name
      FROM
        PA_ALL_ORGANIZATIONS paorg,
        HR_ALL_ORGANIZATION_UNITS hrorg,
        HR_ALL_ORGANIZATION_UNITS hrprorg
      WHERE
        paorg.org_id              = hrorg.organization_id
      AND hrprorg.organization_id = paorg.organization_id
      AND paorg.organization_id   = pap.CARRYING_OUT_ORGANIZATION_ID
      AND hrorg.organization_id   = pap.org_id
      AND PA_ORG_USE_TYPE         = 'PROJECTS'
      AND paorg.inactive_date    IS NULL
    )
    Organization ,---Comma replaced by Priyam
    (
      SELECT
        b.name
      FROM
        XLE_ENTITY_PROFILES b,
        hr_operating_units a
      WHERE
        a.organization_id   =pap.org_id
      AND b.lEGAL_ENTITY_ID =a.default_legal_context_id
    )
    LegalEntity ,
    REPLACE(REPLACE(REPLACE(REPLACE(pap.description,chr(13), ''), chr( 10), '')
    ,chr(39),''),chr(63),'') Project_Description ,
    mgr.employee_number Project_Manager_Number ,
    mgr.full_name Project_Manager_Name ,
    mgr.email_address Project_Manager_email ,
    TO_CHAR(pap.START_DATE,'YYYY/MM/DD') Project_Start_Date ,
    TO_CHAR(pap.COMPLETION_DATE,'YYYY/MM/DD') Project_Finish_Date ,
    TO_CHAR(pap.CLOSED_DATE,'YYYY/MM/DD') Closed_Date ,
    pap.PROJECT_STATUS_CODE Project_Status ,
    pap.PRIORITY_CODE Priority_Code ,
    NULL Outline_Display_Level ,
    NULL Planning_Project ,
    NULL Service_Type_Code ,
    (
      SELECT
        name
      FROM
        PA_WORK_TYPES_TL
      WHERE
        WORK_TYPE_ID = pap.Work_Type_id
      AND LANGUAGE   = 'US'
    )
    WorkType ,
    pap.Limit_to_Txn_Controls_flag Limit_to_Transaction_Controls ,
    pap.Project_Currency_code Project_Currency ,
    NULL Proj_Cur_Conv_Rate_Type ,
    NULL Proj_Cur_Conv_Date_Type_Code ,
    NULL Proj_Cur_Conv_Date ,
    NULL Allow_Capitalized_Interest ,
    NULL Cap_Interest_Rate_Schedule ,
    NULL Cap_Interest_Stop_Date ,
    pap.ASSET_ALLOCATION_METHOD Asset_Cost_Alloc_Method_Code ,
    pap.CAPITAL_EVENT_PROCESSING Capital_Event_Method_Code ,
    NULL Allow_Charges_from_BU ,  -- to be null 04132020
    NULL Process_Cross_Charge_TRX ,
    NULL Labor_Traf_Price_Schedule ,
    NULL Labor_Traf_Price_Fixed_Date ,
    NULL Process_X_Charge_TRX_Nonlabor ,
    NULL Nonlabor_Tranf_Price_Schedule ,
    NULL Nonlabor_Tranf_Price_Fix_Date ,  -- to be null
    NULL Burden_Schedule ,
    NULL Burden_Schedule_Fixed_Date ,
    NULL KPI_Notifications_Enabled ,
    NULL KPI_Notifications_Enabled_PM ,
    NULL Include_Notes_in_KPI_Notf ,
    NULL Copy_Team_Members_from_T ,
    NULL Copy_Classifications_from_T ,
    NULL Copy_Attachments_from_T ,
    NULL Copy_DFF_from_T ,
    NULL Copy_Project_Space_from_T ,
    NULL Copy_Tasks_from_T ,
    NULL Copy_Task_Attachments_from_T ,
    NULL Copy_Task_DFF_from_T ,
    NULL Copy_Task_Assignments_from_T ,
    NULL Copy_TRX_Controls_from_T ,
    NULL Copy_Assets_from_T ,
    NULL Copy_Asset_Assignments_from_T ,
    NULL Copy_Costing_Overrides_from_T ,
    DECODE(pap.org_id,404,'OD US Fin BU',403, 'OD CA Fin BU') ATTRIBUTE_CATEGORY ,
    SUBSTR(pap.Attribute1,2) Attribute1 ,
    pap.Attribute2 Attribute2 ,
    pap.Attribute3 Attribute3 ,
    pap.Attribute4 Attribute4 ,
    pap.Attribute5 Attribute5 ,
    pap.Attribute6 Attribute6 ,
    pap.Attribute7 Attribute7 ,
    pap.Attribute8 Attribute8 ,
    pap.Attribute9 Attribute9 ,
    pap.Attribute10 Attribute10 ,
    NULL Attribute11 ,
    NULL Attribute12 ,
    NULL Attribute13 ,
    NULL Attribute14 ,
    NULL attribute15
  FROM
    PA_PROJECTS_ALL pap ,
    (
      SELECT
        papf.employee_number,
        papf.full_name,
        papf.email_address,
        ppp.project_id
      FROM
        pa_project_parties ppp ,
        pa_project_role_types pprt ,
        per_all_people_f papf
      WHERE
        1                        =1
      AND ppp.RESOURCE_SOURCE_ID = papf.person_id
      AND ppp.project_role_id    = pprt.project_role_id
      AND pprt.project_role_type = 'PROJECT MANAGER'
      AND TRUNC (SYSDATE) BETWEEN TRUNC (papf.EFFECTIVE_START_DATE) AND TRUNC (
        papf.EFFECTIVE_END_DATE)
      AND TRUNC(SYSDATE) BETWEEN TRUNC (ppp.start_date_active) AND TRUNC(
        ppp.end_date_active)
    )
    mgr
  WHERE
    1                          = 1
  AND mgr.project_id(+)        = pap.project_id
  AND NVL(closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
  AND pap.template_flag        = 'N'
  AND
    (
      pap.segment1 NOT LIKE 'PB%'
    AND pap.segment1 NOT LIKE 'NB%'
    AND pap.segment1 NOT LIKE 'TEM%'
    )
  AND pap.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
  AND pap.org_id              <>403
  AND PAP.PROJECT_STATUS_CODE IN ('APPROVED','CLOSED','1000')
  AND pap.created_from_project_id IN 
    ( SELECT project_id
        FROM pa_projects_all
       WHERE template_flag='Y'
         AND name       =NVL(p_proj_template,name)--'US IT Template - Labor Only'
    )
  ORDER BY
    pap.project_id;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
BEGIN
  print_debug_msg ('Package fbdi_projects START', true);
  ---  print_debug_msg ('P_BOOK_TYPE_CODE '||P_BOOK_TYPE_CODE, TRUE);
  l_file_name    := 'fbdi_projects' || '.csv';
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='PROJECT_NAME'|| ','|| 'PROJECT_NUMBER'|| ','||
  'SOURCETEMPLATENUMBER'|| ','|| 'SOURCE_APPLICATION_CODE'|| ','||
  'SOURCE_PROJECT_REFERENCE'|| ','|| 'ORGANIZATION'|| ','|| 'LEGALENTITY'|| ','
  || 'PROJECT_DESCRIPTION'|| ','|| 'PROJECT_MANAGER_NUMBER'|| ','||
  'PROJECT_MANAGER_NAME'|| ','|| 'PROJECT_MANAGER_EMAIL'|| ','||
  'PROJECT_START_DATE'|| ','|| 'PROJECT_FINISH_DATE'|| ','|| 'CLOSED_DATE '||
  ','|| 'PROJECT_STATUS'|| ','|| 'PRIORITY_CODE'|| ','||
  'OUTLINE_DISPLAY_LEVEL'|| ','|| 'PLANNING_PROJECT'|| ','||
  'SERVICE_TYPE_CODE'|| ','|| 'WORKTYPE'|| ','||
  'LIMIT_TO_TRANSACTION_CONTROLS'|| ','|| 'PROJECT_CURRENCY'|| ','||
  'PROJ_CUR_CONV_RATE_TYPE'|| ','|| 'PROJ_CUR_CONV_DATE_TYPE_CODE'|| ','||
  'PROJ_CUR_CONV_DATE'|| ','|| 'ALLOW_CAPITALIZED_INTEREST'|| ','||
  'CAP_INTEREST_RATE_SCHEDULE'|| ','|| 'CAP_INTEREST_STOP_DATE'|| ','||
  'ASSET_COST_ALLOC_METHOD_CODE'|| ','|| 'CAPITAL_EVENT_METHOD_CODE'|| ','||
  'ALLOW_CHARGES_FROM_BU'|| ','|| 'PROCESS_CROSS_CHARGE_TRX'|| ','||
  'LABOR_TRAF_PRICE_SCHEDULE'|| ','|| 'LABOR_TRAF_PRICE_FIXED_DATE'|| ','||
  'PROCESS_X_CHARGE_TRX_NONLABOR'|| ','|| 'NONLABOR_TRANF_PRICE_SCHEDULE'|| ','
  || 'NONLABOR_TRANF_PRICE_FIX_DATE'|| ','|| 'BURDEN_SCHEDULE'|| ','||
  'BURDEN_SCHEDULE_FIXED_DATE'|| ','|| 'KPI_NOTIFICATIONS_ENABLED'|| ','||
  'KPI_NOTIFICATIONS_ENABLED_PM '|| ','|| 'INCLUDE_NOTES_IN_KPI_NOTF'|| ','||
  'COPY_TEAM_MEMBERS_FROM_T'|| ','|| 'COPY_CLASSIFICATIONS_FROM_T'|| ','||
  'COPY_ATTACHMENTS_FROM_T'|| ','|| 'COPY_DFF_FROM_T'|| ','||
  'COPY_PROJECT_SPACE_FROM_T'|| ','|| 'COPY_TASKS_FROM_T'|| ','||
  'COPY_TASK_ATTACHMENTS_FROM_T'|| ','|| 'COPY_TASK_DFF_FROM_T'|| ','||
  'COPY_TASK_ASSIGNMENTS_FROM_T'|| ','|| 'COPY_TRX_CONTROLS_FROM_T'|| ','||
  'COPY_ASSETS_FROM_T'|| ','|| 'COPY_ASSET_ASSIGNMENTS_FROM_T'|| ','||
  'COPY_COSTING_OVERRIDES_FROM_T'|| ','|| 'ATTRIBUTE_CATEGORY'|| ','||
  'ATTRIBUTE1'|| ','|| 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'||
  ','|| 'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','||
  'ATTRIBUTE8'|| ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10'|| ','|| 'ATTRIBUTE11'
  || ','|| 'ATTRIBUTE12'|| ','|| 'ATTRIBUTE13'|| ','|| 'ATTRIBUTE14'|| ','||
  'ATTRIBUTE15';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_projects
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,'"'||i.PROJECT_NAME|| '","'||
    i.PROJECT_NUMBER || '","'|| i.SOURCETEMPLATENUMBER|| '","'||
    i.SOURCE_APPLICATION_CODE || '","'|| i.SOURCE_PROJECT_REFERENCE || '","'||
    i.ORGANIZATION|| '","'|| i.LEGALENTITY || '","'|| i.PROJECT_DESCRIPTION||
    '","'|| i.PROJECT_MANAGER_NUMBER|| '","'|| i.PROJECT_MANAGER_NAME|| '","'||
    i.PROJECT_MANAGER_EMAIL|| '","'|| i.PROJECT_START_DATE|| '","'||
    i.PROJECT_FINISH_DATE|| '","'|| i.CLOSED_DATE || '","'|| i.PROJECT_STATUS
    || '","'|| i.PRIORITY_CODE || '","'|| i.OUTLINE_DISPLAY_LEVEL|| '","'||
    i.PLANNING_PROJECT || '","'|| i.SERVICE_TYPE_CODE || '","'|| i.WORKTYPE||
    '","'|| i.LIMIT_TO_TRANSACTION_CONTROLS|| '","'|| i.PROJECT_CURRENCY ||
    '","'|| i.PROJ_CUR_CONV_RATE_TYPE || '","'|| i.PROJ_CUR_CONV_DATE_TYPE_CODE
    || '","'|| i.PROJ_CUR_CONV_DATE|| '","'|| i.ALLOW_CAPITALIZED_INTEREST||
    '","'|| i.CAP_INTEREST_RATE_SCHEDULE || '","'|| i.CAP_INTEREST_STOP_DATE||
    '","'|| i.ASSET_COST_ALLOC_METHOD_CODE|| '","'||
    i.CAPITAL_EVENT_METHOD_CODE || '","'|| i.ALLOW_CHARGES_FROM_BU || '","'||
    i.PROCESS_CROSS_CHARGE_TRX || '","'|| i.LABOR_TRAF_PRICE_SCHEDULE || '","'
    || i.LABOR_TRAF_PRICE_FIXED_DATE || '","'|| i.PROCESS_X_CHARGE_TRX_NONLABOR
    || '","'|| i.NONLABOR_TRANF_PRICE_SCHEDULE || '","'||
    i.NONLABOR_TRANF_PRICE_FIX_DATE || '","'|| i.BURDEN_SCHEDULE || '","'||
    i.BURDEN_SCHEDULE_FIXED_DATE || '","'|| i.KPI_NOTIFICATIONS_ENABLED ||
    '","'|| i.KPI_NOTIFICATIONS_ENABLED_PM || '","'||
    i.INCLUDE_NOTES_IN_KPI_NOTF || '","'|| i.COPY_TEAM_MEMBERS_FROM_T || '","'
    || i.COPY_CLASSIFICATIONS_FROM_T || '","'|| i.COPY_ATTACHMENTS_FROM_T ||
    '","'|| i.COPY_DFF_FROM_T || '","'|| i.COPY_PROJECT_SPACE_FROM_T || '","'||
    i.COPY_TASKS_FROM_T || '","'|| i.COPY_TASK_ATTACHMENTS_FROM_T || '","'||
    i.COPY_TASK_DFF_FROM_T || '","'|| i.COPY_TASK_ASSIGNMENTS_FROM_T || '","'||
    i.COPY_TRX_CONTROLS_FROM_T || '","'|| i.COPY_ASSETS_FROM_T || '","'||
    i.COPY_ASSET_ASSIGNMENTS_FROM_T|| '","'|| i.COPY_COSTING_OVERRIDES_FROM_T||
    '","'|| i.ATTRIBUTE_CATEGORY || '","'|| i.ATTRIBUTE1 || '","'||
    i.ATTRIBUTE2 || '","'|| i.ATTRIBUTE3 || '","'|| i.ATTRIBUTE4 || '","'||
    i.ATTRIBUTE5 || '","'|| i.ATTRIBUTE6 || '","'|| i.ATTRIBUTE7 || '","'||
    i.ATTRIBUTE8 || '","'|| i.ATTRIBUTE9 || '","'|| i.ATTRIBUTE10|| '","'||
    i.ATTRIBUTE11|| '","'|| i.ATTRIBUTE12|| '","'|| i.ATTRIBUTE13|| '","'||
    i.ATTRIBUTE14|| '","'|| i.attribute15||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' ||
  ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' ||
  ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' || ' file_open :: '
  || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' ||
  ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' ||
  ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' ||
  ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' ||
  ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' || ' read_error :: '
  || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' ||
  ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' || ' write_error :: '
  || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_projects procedure :- ' || ' OTHERS :: ' ||
  SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_projects;
PROCEDURE fbdi_tasks(
    p_proj_template VARCHAR2)
IS
  CURSOR c_tasks
  IS
    SELECT
      trim(REPLACE(REPLACE(REPLACE(REPLACE(pap.name,chr(13), ''), chr(10), ''),
      chr(39),''),chr(63),'')) Project_Name ,
      pap.segment1 Project_num ,
      REPLACE(REPLACE(REPLACE(REPLACE(pat.task_name,chr(13), ''), chr( 10), '')
      ,chr(39),''),chr(63),'') Task_Name ,
      pat.Task_Number ,
      REPLACE(REPLACE(REPLACE(REPLACE(pat.description,chr(13), ''), chr (10),
      ''),chr(39),''),chr(63),'') Task_description ,
      (
        SELECT
          Task_Number
        FROM
          pa_tasks
        WHERE
          task_id = pat.parent_task_id
      )
    Parent_Task_Number ,
    TO_CHAR(pat.START_DATE,'YYYY/MM/DD') Planning_Start_Date ,
    TO_CHAR(pat.COMPLETION_DATE,'YYYY/MM/DD') Planning_End_Date ,
    NULL Milestone ,
    NULL Critical ,
    pat.Chargeable_flag Chargeable ,
    'N' Billable ,
    pat.billable_flag Capitalizable ,
    pat.Limit_to_Txn_Controls_flag Limit_to_Transaction_Controls ,
    NULL Source_Task_Reference ,
    NULL Source_Application_Code ,
    pat.Service_Type_Code ,
    NULL Work_Type ,
    NULL Task_Manager ,
    'Y' Allow_Cross_Charge_Flag ,  -- to be Y 04132020
    NULL X_Charge_Proc_Labor_Flag ,
    NULL X_Charge_Proc_Non_Labor_Flag ,
    NULL Receive_Project_Invoice_Flag ,
    PAT.ATTRIBUTE_CATEGORY ATTRIBUTE_CATEGORY ,
    SUBSTR(pat.Attribute1,2) Attribute1 -- Arun changed to trim leading zero to
    -- reduce size to 5 chars for cloud
    ,
    pat.Attribute2 Attribute2 ,
    pat.Attribute3 Attribute3 ,
    pat.Attribute4 Attribute4 ,
    pat.Attribute5 Attribute5 ,
    pat.Attribute6 Attribute6 ,
    pat.Attribute7 Attribute7 ,
    pat.Attribute8 Attribute8 ,
    pat.Attribute9 Attribute9 ,
    pat.Attribute10 Attribute10 ,
    NULL Attribute11 ,
    NULL Attribute12 ,
    NULL Attribute13 ,
    NULL Attribute14 ,
    (
      SELECT
        hrprorg.name
      FROM
        PA_ALL_ORGANIZATIONS paorg,
        HR_ALL_ORGANIZATION_UNITS hrorg,
        HR_ALL_ORGANIZATION_UNITS hrprorg
      WHERE
        1                         = 1
      AND paorg.org_id            = hrorg.organization_id
      AND hrprorg.organization_id = paorg.organization_id
      AND paorg.organization_id   = pap.CARRYING_OUT_ORGANIZATION_ID
      AND hrorg.organization_id   = pap.org_id
      AND PA_ORG_USE_TYPE         = 'PROJECTS'
      AND paorg.INACTIVE_DATE    IS NULL
    )
    attribute15
  FROM
    pa_tasks pat,
    pa_projects_all pap
  WHERE
    1                              = 1
  AND pap.template_flag            = 'N'
  AND NVL(pap.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
  AND
    (
      pap.segment1 NOT LIKE 'PB%'
    AND pap.segment1 NOT LIKE 'NB%'
    AND pap.segment1 NOT LIKE 'TEM%'
    )
  AND pap.project_type NOT    IN ('PB_PROJECT','DI_PB_PROJECT')
  AND pap.project_status_code IN ('APPROVED','CLOSED','1000')
  AND pap.org_id              <>403
  AND pat.project_id           =pap.project_id
    -- Begin Added for pstgb
  AND pap.created_from_project_id IN
     ( SELECT project_id
         FROM pa_projects_all
        WHERE template_flag='Y'
          AND name       =NVL(p_proj_template,name)--'US IT Template - Labor Only'
     )
    -- End added for PSTGB
  ORDER BY
    pap.segment1,
    pat.Task_Number ;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
BEGIN
  print_debug_msg ('Package fbdi_tasks START', true);
  ---  print_debug_msg ('P_BOOK_TYPE_CODE '||P_BOOK_TYPE_CODE, TRUE);
  l_file_name    := 'fbdi_tasks' || '.csv';
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='PROJECT_NAME'|| ','|| 'PROJECT_NUM'|| ','|| 'TASK_NAME'||
  ','|| 'TASK_NUMBER'|| ','|| 'TASK_DESCRIPTION'|| ','|| 'PARENT_TASK_NUMBER'||
  ','|| 'PLANNING_START_DATE'|| ','|| 'PLANNING_END_DATE'|| ','|| 'MILESTONE'||
  ','|| 'CRITICAL'|| ','|| 'CHARGEABLE'|| ','|| 'BILLABLE'|| ','||
  'CAPITALIZABLE'|| ','|| 'LIMIT_TO_TRANSACTION_CONTROLS'|| ','||
  'SOURCE_TASK_REFERENCE'|| ','|| 'SOURCE_APPLICATION_CODE'|| ','||
  'SERVICE_TYPE_CODE'|| ','|| 'WORK_TYPE'|| ','|| 'TASK_MANAGE'|| ','||
  'ALLOW_CROSS_CHARGE_FLAG'|| ','|| 'X_CHARGE_PROC_LABOR_FLAG'|| ','||
  'X_CHARGE_PROC_NON_LABOR_FLAG'|| ','|| 'RECEIVE_PROJECT_INVOICE_FLAG'|| ','||
  'ATTRIBUTE_CATEGORY'|| ','|| 'ATTRIBUTE1'|| ','|| 'ATTRIBUTE2'|| ','||
  'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','|| 'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'||
  ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'|| ','|| 'ATTRIBUTE9'|| ','||
  'ATTRIBUTE10'|| ','|| 'ATTRIBUTE11'|| ','|| 'ATTRIBUTE12'|| ','||
  'ATTRIBUTE13'|| ','|| 'ATTRIBUTE14'|| ','|| 'ATTRIBUTE15';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_tasks
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,'"'||i.PROJECT_NAME|| '","'||
    i.PROJECT_NUM|| '","'|| i.TASK_NAME|| '","'|| i.TASK_NUMBER || '","'||
    i.TASK_DESCRIPTION|| '","'|| i.PARENT_TASK_NUMBER || '","'||
    i.PLANNING_START_DATE || '","'|| i.PLANNING_END_DATE || '","'|| i.MILESTONE
    || '","'|| i.CRITICAL || '","'|| i.CHARGEABLE || '","'|| i.BILLABLE ||
    '","'|| i.CAPITALIZABLE|| '","'|| i.LIMIT_TO_TRANSACTION_CONTROLS || '","'
    || i.SOURCE_TASK_REFERENCE || '","'|| i.SOURCE_APPLICATION_CODE || '","'||
    i.SERVICE_TYPE_CODE || '","'|| i.WORK_TYPE || '","'|| i.TASK_MANAGER ||
    '","'|| i.ALLOW_CROSS_CHARGE_FLAG || '","'|| i.X_CHARGE_PROC_LABOR_FLAG ||
    '","'|| i.X_CHARGE_PROC_NON_LABOR_FLAG || '","'||
    i.RECEIVE_PROJECT_INVOICE_FLAG|| '","'|| i.ATTRIBUTE_CATEGORY|| '","'||
    i.ATTRIBUTE1|| '","'|| i.ATTRIBUTE2|| '","'|| i.ATTRIBUTE3|| '","'||
    i.ATTRIBUTE4|| '","'|| i.ATTRIBUTE5|| '","'|| i.ATTRIBUTE6|| '","'||
    i.ATTRIBUTE7|| '","'|| i.ATTRIBUTE8|| '","'|| i.ATTRIBUTE9|| '","'||
    i.ATTRIBUTE10|| '","'|| i.ATTRIBUTE11 || '","'|| i.ATTRIBUTE12 || '","'||
    i.ATTRIBUTE13 || '","'|| i.ATTRIBUTE14 || '","'|| i.ATTRIBUTE15||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' || ' access_denied :: '
  || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' || ' delete_failed :: '
  || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' || ' file_open :: ' ||
  SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' || ' internal_error :: '
  || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure:- ' ||
  ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' ||
  ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' || ' invalid_mode :: '
  || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' || ' invalid_offset :: '
  || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' ||
  ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' || ' invalid_path :: '
  || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' || ' read_error :: ' ||
  SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' || ' rename_failed :: '
  || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' || ' write_error :: ' ||
  SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_tasks procedure :- ' || ' OTHERS :: ' ||
  SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_tasks;

PROCEDURE XX_OD_PA_CON_SCRIPT_wrapper(
    P_ERRBUF         VARCHAR2,
      p_retcode        NUMBER,
      p_proj_template  VARCHAR2)
AS
  v_book_type_code VARCHAR2(50);
BEGIN
      fbdi_projects(p_proj_template);
      fbdi_tasks(p_proj_template);
      fbdi_proj_team_members(p_proj_template);
      fbdi_proj_classif_lob(p_proj_template);
      fbdi_proj_classification(p_proj_template);
      fbdi_pa_budgets(p_proj_template);
	  fbdi_proj_exp_cap_yn(p_proj_template);
      fbdi_proj_exp_cap_yy(p_proj_template);
      fbdi_proj_exp_nei_nn(p_proj_template);
	  fbdi_project_assets_yy(p_proj_template);
	  fbdi_proj_asset_assignments_yy(p_proj_template);	 
      fbdi_project_assets_yn(p_proj_template);
	  fbdi_proj_asset_assignments_yn(p_proj_template);
  	  
EXCEPTION
WHEN OTHERS THEN
  print_debug_msg ('Error in XX_OD_PA_CON_SCRIPT_wrapper procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE, TRUE);
END XX_OD_PA_CON_SCRIPT_wrapper;

END XX_PA_CONV_EXTRACT_PKG;
/
SHOW ERRORS;