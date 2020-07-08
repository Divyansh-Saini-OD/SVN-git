SET VERIFY OFF
SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE BODY XX_FA_CONV_EXTRACT_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_FA_CONV_EXTRACT_PKG                                                             |
  -- |                                                                                            |
  -- |  Description:Scripts for FA conversion                                                     |
  -- |  RICE ID   :                                                                               |
  -- |  Description:                                                                              |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         03-JUL-2019   Priyam S           Initial Version  added                        |
  ---| 1.1        16-JUL-19      Priyam S            Added Projects Queries                       |
  ---| 1.2        16-JUL-19      M K Pramod Kumar    Code Modified to resolve variance issues     |
  ---| 1.3        25-JUL-19      M K Pramod Kumar    Added FA Validation logic                    |
  ---| 1.4        29-JUL-19      M K Pramod Kumar    Added CTU mapping Error logic                |
  ---| 1.5        06-AUG-19      Priyam S            Removed comma from projects query            |
  -- | 1.6        02-JAN-2000    Paddy Sanjeevi      Modified xx_gl_beacon_mapping_f1 for interco |
  -- | 1.7        03-JAN-2020    Paddy Sanjeevi      Modified to add project info in DFF and doublequote|
  -- | 1.8	      27-JAN-2020    Paddy Sanjeevi      Modified to bring fa_additions_b DFF         |
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
           ltrim(rtrim(target)) target,
           ltrim(rtrim(type)) type
      FROM xx_gl_beacon_mapping
     WHERE source=trim(p_source)
       AND type    =trim(p_type);
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
  err_msg        VARCHAR2(2000);  
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
        v_target:=NULL;
      END;
    ELSE
      v_target:=NULL;
      FOR i IN c_concat
      LOOP

   	    err_msg:=NULL;
	    v_target    	:=NULL;
		v_entity       	:=NULL;
		v_cost_center  	:=NULL;
		v_account      	:=NULL;
		v_location     	:=NULL;
		v_intercompany 	:=NULL;
		v_lob          	:=NULL;
	
        BEGIN
          SELECT ltrim(rtrim(target))
          INTO v_entity
          FROM xx_gl_beacon_mapping
          WHERE source=i.entity
          AND type    ='ENTITY';
        EXCEPTION
        WHEN OTHERS THEN
          v_entity:=NULL;
		  err_msg:=err_msg||' Missing Entity '||i.entity;
        END;
        BEGIN
          SELECT ltrim(rtrim(target))
          INTO v_cost_center
          FROM xx_gl_beacon_mapping
          WHERE source=i.cost_center
          AND type    ='COST_CENTER';
        EXCEPTION
        WHEN OTHERS THEN
          v_cost_center:=NULL;
		  err_msg:=err_msg||' Missing Cost Center '||i.cost_center;
        END;
        BEGIN
          SELECT ltrim(rtrim(target))
          INTO v_account
          FROM xx_gl_beacon_mapping
          WHERE source=i.account
          AND type    ='ACCOUNT';
        EXCEPTION
        WHEN OTHERS THEN
          v_account:=NULL;
		  err_msg:=err_msg||' Missing Account '||i.account;
        END;
        BEGIN
          SELECT ltrim(rtrim(target))
          INTO v_location
          FROM xx_gl_beacon_mapping
          WHERE source=i.location
          AND type    ='LOCATION';
        EXCEPTION
        WHEN OTHERS THEN
          v_location:=NULL;
  		  err_msg:=err_msg||' Missing Locationt '||i.location;
        END;
        BEGIN
          SELECT ltrim(rtrim(target))
          INTO v_lob
          FROM xx_gl_beacon_mapping
          WHERE source=i.lob
          AND type    ='LOB';
        EXCEPTION
        WHEN OTHERS THEN
          v_lob:=NULL;
		  err_msg:=err_msg||' Missing LOB '||i.lob;
        END;
		
        BEGIN
          SELECT ltrim(rtrim(target))
          INTO v_intercompany
          FROM xx_gl_beacon_mapping
          WHERE source=i.inter_company
          AND type    ='ENTITY';
        EXCEPTION
        WHEN OTHERS THEN
          v_intercompany:=NULL;
           err_msg:=err_msg||' Missing Intercompany'||i.inter_company;
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
  END IF;
END xx_gl_beacon_mapping_f1;


PROCEDURE ctu_mapping_validation(
    p_category           VARCHAR2,
	p_company			 VARCHAR2,
	p_lob				 VARCHAR2,
	p_costcenter		 VARCHAR2,
	p_account			 VARCHAR2,
	p_location			 VARCHAR2,
	p_interco			 VARCHAR2,
    p_in_segment1        VARCHAR2,
    p_in_segment2        VARCHAR2,
    p_in_segment3        VARCHAR2,
    p_in_segment4        VARCHAR2,
    p_in_segment5        VARCHAR2,
    p_in_segment6        VARCHAR2,
    p_asset_id           NUMBER,
    p_asset_book_type    VARCHAR2,
    p_err_message OUT VARCHAR2)
AS
lc_conc_segments VARCHAR2(100);
BEGIN
  p_err_message:='CTU Mapping Failure';
  lc_conc_segments:=p_company||'.'||p_costcenter||'.'||p_account||'.'||p_location||'.'||p_interco||'.'||p_lob;
  --print_debug_msg ('CTU Insert conc segments  :'||lc_conc_segments,TRUE);
  --print_debug_msg ('CTU Insert Failed segments for Asset :'||to_char(p_asset_id)||' : '||p_in_segment1||'.'||p_in_segment2||'.'||
--						p_in_segment3||'.'||p_in_segment4||'.'||p_in_segment5||'.'||p_in_segment6
	--				,TRUE);
  IF p_in_segment1 IS NULL THEN
    INSERT
    INTO XX_FA_CTU_ERRORS
      (
        ASSET_ID ,
        CTU_TYPE ,
        CTU_VALUE,
        GL_STRING,
        REQUEST_ID,
        CREATION_DATE,
		book_type_Code
      )
      VALUES
      (
        p_asset_id,
        'COMPANY',
        p_company,
        lc_conc_segments,
        NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
        sysdate,p_asset_book_type
      );
    p_err_message:=p_err_message||'~'||'Company not found';
  END IF;
  IF p_in_segment2 IS NULL THEN
    INSERT
    INTO XX_FA_CTU_ERRORS
      (
        ASSET_ID ,
        CTU_TYPE ,
        CTU_VALUE,
        GL_STRING,
        REQUEST_ID,
        CREATION_DATE,book_type_Code
      )
      VALUES
      (
        p_asset_id,
        'LOB',
        p_lob,
        lc_conc_segments,
        NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
        sysdate,p_asset_book_type
      );
    p_err_message:=p_err_message||'~'||'LOB not found';
  END IF;
  IF p_in_segment3 IS NULL THEN
    INSERT
    INTO XX_FA_CTU_ERRORS
      (
        ASSET_ID ,
        CTU_TYPE ,
        CTU_VALUE,
        GL_STRING,
        REQUEST_ID,
        CREATION_DATE,book_type_Code
      )
      VALUES
      (
        p_asset_id,
        'COST_CENTER',
        p_costcenter,
        lc_conc_segments,
        NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
        sysdate,p_asset_book_type
      );
    p_err_message:=p_err_message||'~'||'COST_CENTER not found';
  END IF;
  IF p_in_segment4 IS NULL THEN
    INSERT
    INTO XX_FA_CTU_ERRORS
      (
        ASSET_ID ,
        CTU_TYPE ,
        CTU_VALUE,
        GL_STRING,
        REQUEST_ID,
        CREATION_DATE,book_type_Code
      )
      VALUES
      (
        p_asset_id,
        'ACCOUNT',
        p_account,
        lc_conc_segments,
        NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
        sysdate,p_asset_book_type
      );
    p_err_message:=p_err_message||'~'||'ACCOUNT not found';
  END IF;
  IF p_in_segment5 IS NULL THEN
    INSERT
    INTO XX_FA_CTU_ERRORS
      (
        ASSET_ID ,
        CTU_TYPE ,
        CTU_VALUE,
        GL_STRING,
        REQUEST_ID,
        CREATION_DATE,book_type_Code
      )
      VALUES
      (
        p_asset_id,
        'LOCATION',
        p_location,
        lc_conc_segments,
        NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
        sysdate,p_asset_book_type
      );
    p_err_message:=p_err_message||'~'||'LOCATION not found';
  END IF;
  IF p_in_segment6 IS NULL THEN
    INSERT
    INTO XX_FA_CTU_ERRORS
      (
        ASSET_ID ,
        CTU_TYPE ,
        CTU_VALUE,
        GL_STRING,
        REQUEST_ID,
        CREATION_DATE,book_type_Code
      )
      VALUES
      (
        p_asset_id,
        'Company',
        p_interco,
        lc_conc_segments,
        NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
        sysdate,p_asset_book_type
      );
    p_err_message:=p_err_message||'~'||'Inter Company not found';
	--print_debug_msg ('CTU Insert :'||p_err_message,TRUE);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  print_debug_msg ('Error occured in ctu_mapping_validation procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE, TRUE);
END ctu_mapping_validation;
PROCEDURE generic_parent_assets_hdr
  (
    p_book_type_code VARCHAR2
  )
AS
  CURSOR c_pas_asset_hdr
  IS
    SELECT
      /*+ parallel(8) */
      Interface_Line_Number,
      Asset_Book,
      Transaction_Name,
      Asset_Number,
      Asset_Description ,
      Tag_Number,
      Manufacturer,
      Serial_Number,
      Model ,
      Asset_Type,
      Cost,
      Date_Placed_in_Service,
      Prorate_Convention,
      Asset_Units,
      Asset_Category_Segment1,
      Asset_Category_Segment2,
      Asset_Category_Segment3,
      Asset_Category_Segment4,
      Asset_Category_Segment5,
      Asset_Category_Segment6,
      Asset_Category_Segment7,
      'POST' Posting_Status,
      'NEW' Queue_Name,
      'ORACLE FBDI' Feeder_System,
      Parent_Asset,
      NULL Add_to_Asset,
      NULL Asset_Key_Segment1,
      NULL Asset_Key_Segment2,
      NULL Asset_Key_Segment3,
      NULL Asset_Key_Segment4,
      NULL Asset_Key_Segment5,
      NULL Asset_Key_Segment6,
      NULL Asset_Key_Segment7,
      NULL Asset_Key_Segment8,
      NULL Asset_Key_Segment9,
      NULL Asset_Key_Segment10,
      In_physical_inventory,
      Property_Type,
      PROPERTY_CLASS,
      --           fa_details.distribution_id,  -- Moved to end by Arun
      In_use,
      Ownership,
      Bought,
      NULL MATERIAL_INDICATOR,
      COMMITMENT ,
      INVESTMENT_LAW, --arunadded
      Amortize,
      Amortization_Start_Date,
      Depreciate,
      Salvage_Value_Type,
      Salvage_Value_Amount,
      Salvage_Value_Percent,
      YTD_Depreciation,
      Depreciation_Reserve,
      YTD_Bonus_Depreciation,
      Bonus_Depreciation_Reserve,
      YTD_IMPAIRMENT ,
      IMPAIRMENT_RESERVE ,
      Depreciation_Method ,
      LIFE_IN_MONTHS ,
      BASIC_RATE ,
      ADJUSTED_RATE ,
      UNIT_OF_MEASURE ,
      PRODUCTION_CAPACITY ,
      Ceiling_Type,
      BONUS_RULE ,
      NULL CASH_GENERATING_UNIT ,
      Depreciation_Limit_Type,
      Depreciation_Limit_Percent,
      Depreciation_Limit_Amount,
      NULL INVOICE_COST,
      (SELECT xx_gl_beacon_mapping_f1(gcc.segment1,'ENTITY','A')--ENTITY
      FROM gl_code_combinations gcc,
        fa_distribution_accounts da
      WHERE da.distribution_id    = fa_details.distribution_id
      AND da.book_type_code       = fa_details.asset_book
      AND gcc.code_combination_id = da.asset_clearing_account_ccid
      )cost_clearing_account_seg1,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment6,'LOB','A')----LOB
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg2,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment2,'COST_CENTER','A')------COST CENTER
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg3,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment3,'ACCOUNT','A')----ACCOUNT
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg4,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment4,'LOCATION','A')---LOCATION
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg5,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment5,'ENTITY','A')-----INTERCOMP
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg6,
    NULL cost_clearing_account_seg7,
    NULL Cost_Clearing_Account_Seg8,
    NULL Cost_Clearing_Account_Seg9,
    NULL COST_CLEARING_ACCOUNT_SEG10,
    NULL Cost_Clearing_Account_Seg11,
    NULL Cost_Clearing_Account_Seg12,
    NULL Cost_Clearing_Account_Seg13,
    NULL Cost_Clearing_Account_Seg14,
    NULL COST_CLEARING_ACCOUNT_SEG15,
    /*           NULL                            CLEARING_ACCT_SEGMENT16,
    NULL                            CLEARING_ACCT_SEGMENT17,
    NULL                            CLEARING_ACCT_SEGMENT18,
    NULL                            CLEARING_ACCT_SEGMENT19,
    NULL                            CLEARING_ACCT_SEGMENT20,
    NULL                            CLEARING_ACCT_SEGMENT21,
    NULL                            CLEARING_ACCT_SEGMENT22,
    NULL                            CLEARING_ACCT_SEGMENT23,
    NULL                            CLEARING_ACCT_SEGMENT24,
    NULL                            CLEARING_ACCT_SEGMENT25,
    NULL                            CLEARING_ACCT_SEGMENT26,
    NULL                            CLEARING_ACCT_SEGMENT27,
    NULL                            CLEARING_ACCT_SEGMENT28,
    NULL                            CLEARING_ACCT_SEGMENT29,
    NULL                            CLEARING_ACCT_SEGMENT30,
    */
    fa_details.ATTRIBUTE1,
    fa_details.ATTRIBUTE2,
    fa_details.ATTRIBUTE3,
    fa_details.ATTRIBUTE4,
    fa_details.ATTRIBUTE5,
    fa_details.ATTRIBUTE6,
    fa_details.ATTRIBUTE7,
    fa_details.ATTRIBUTE8,
    fa_details.ATTRIBUTE9,
    fa_details.ATTRIBUTE10,
    fa_details.ATTRIBUTE11,
    fa_details.ATTRIBUTE12,
    NULL ATTRIBUTE13,
    fa_details.ATTRIBUTE14,
    fa_details.ATTRIBUTE15,
    /*
    NULL                            ATTRIBUTE16,
    NULL                            ATTRIBUTE17,
    NULL                            ATTRIBUTE18,
    NULL                            ATTRIBUTE19,
    NULL                            ATTRIBUTE20,
    NULL                            ATTRIBUTE21,
    NULL                            ATTRIBUTE22,
    NULL                            ATTRIBUTE23,
    NULL                            ATTRIBUTE24,
    NULL                            ATTRIBUTE25,
    NULL                            ATTRIBUTE26,
    NULL                            ATTRIBUTE27,
    NULL                            ATTRIBUTE28,
    NULL                            ATTRIBUTE29,
    NULL                            ATTRIBUTE30,
    NULL                            ATTRIBUTE_NUMBER1,
    NULL                            ATTRIBUTE_NUMBER2,
    NULL                            ATTRIBUTE_NUMBER3,
    NULL                            ATTRIBUTE_NUMBER4,
    NULL                            ATTRIBUTE_NUMBER5,
    NULL                            ATTRIBUTE_DATE1,
    NULL                            ATTRIBUTE_DATE2,
    NULL                            ATTRIBUTE_DATE3,
    NULL                            ATTRIBUTE_DATE4,
    NULL                            ATTRIBUTE_DATE5,
    */
    ATTRIBUTE_CATEGORY_CODE,
    NULL context,
    /*
    NULL                            TH_ATTRIBUTE1,
    NULL                            TH_ATTRIBUTE2,
    NULL                            TH_ATTRIBUTE3,
    NULL                            TH_ATTRIBUTE4,
    NULL                            TH_ATTRIBUTE5,
    NULL                            TH_ATTRIBUTE6,
    NULL                            TH_ATTRIBUTE7,
    NULL                            TH_ATTRIBUTE8,
    NULL                            TH_ATTRIBUTE9,
    NULL                            TH_ATTRIBUTE10,
    NULL                            TH_ATTRIBUTE11,
    NULL                            TH_ATTRIBUTE12,
    NULL                            TH_ATTRIBUTE13,
    NULL                            TH_ATTRIBUTE14,
    NULL                            TH_ATTRIBUTE15,
    NULL                            TH_ATTRIBUTE_NUMBER1,
    NULL                            TH_ATTRIBUTE_NUMBER2,
    NULL                            TH_ATTRIBUTE_NUMBER3,
    NULL                            TH_ATTRIBUTE_NUMBER4,
    NULL                            TH_ATTRIBUTE_NUMBER5,
    NULL                            TH_ATTRIBUTE_DATE1,
    NULL                            TH_ATTRIBUTE_DATE2,
    NULL                            TH_ATTRIBUTE_DATE3,
    NULL                            TH_ATTRIBUTE_DATE4,
    NULL                            TH_ATTRIBUTE_DATE5,
    NULL                            TH_ATTRIBUTE_CATEGORY_CODE,
    NULL                            TH2_ATTRIBUTE1,
    NULL                            TH2_ATTRIBUTE2,
    NULL                            TH2_ATTRIBUTE3,
    NULL                            TH2_ATTRIBUTE4,
    NULL                            TH2_ATTRIBUTE5,
    NULL                            TH2_ATTRIBUTE6,
    NULL                            TH2_ATTRIBUTE7,
    NULL                            TH2_ATTRIBUTE8,
    NULL                            TH2_ATTRIBUTE9,
    NULL                            TH2_ATTRIBUTE10,
    NULL                            TH2_ATTRIBUTE11,
    NULL                            TH2_ATTRIBUTE12,
    NULL                            TH2_ATTRIBUTE13,
    NULL                            TH2_ATTRIBUTE14,
    NULL                            TH2_ATTRIBUTE15,
    NULL                            TH2_ATTRIBUTE_NUMBER1,
    NULL                            TH2_ATTRIBUTE_NUMBER2,
    NULL                            TH2_ATTRIBUTE_NUMBER3,
    NULL                            TH2_ATTRIBUTE_NUMBER4,
    NULL                            TH2_ATTRIBUTE_NUMBER5,
    NULL                            TH2_ATTRIBUTE_DATE1,
    NULL                            TH2_ATTRIBUTE_DATE2,
    NULL                            TH2_ATTRIBUTE_DATE3,
    NULL                            TH2_ATTRIBUTE_DATE4,
    NULL                            TH2_ATTRIBUTE_DATE5,
    NULL                            TH2_ATTRIBUTE_CATEGORY_CODE,
    NULL                            AI_ATTRIBUTE1,
    NULL                            AI_ATTRIBUTE2,
    NULL                            AI_ATTRIBUTE3,
    NULL                            AI_ATTRIBUTE4,
    NULL                            AI_ATTRIBUTE5,
    NULL                            AI_ATTRIBUTE6,
    NULL                            AI_ATTRIBUTE7,
    NULL                            AI_ATTRIBUTE8,
    NULL                            AI_ATTRIBUTE9,
    NULL                            AI_ATTRIBUTE10,
    NULL                            AI_ATTRIBUTE11,
    NULL                            AI_ATTRIBUTE12,
    NULL                            AI_ATTRIBUTE13,
    NULL                            AI_ATTRIBUTE14,
    NULL                            AI_ATTRIBUTE15,
    NULL                            AI_ATTRIBUTE_NUMBER1,
    NULL                            AI_ATTRIBUTE_NUMBER2,
    NULL                            AI_ATTRIBUTE_NUMBER3,
    NULL                            AI_ATTRIBUTE_NUMBER4,
    NULL                            AI_ATTRIBUTE_NUMBER5,
    NULL                            AI_ATTRIBUTE_DATE1,
    NULL                            AI_ATTRIBUTE_DATE2,
    NULL                            AI_ATTRIBUTE_DATE3,
    NULL                            AI_ATTRIBUTE_DATE4,
    NULL                            AI_ATTRIBUTE_DATE5,
    NULL                            AI_ATTRIBUTE_CATEGORY_CODE,
    */
    NULL Mass_Property_Eligible,
    NULL Group_Asset,
    NULL Reduction_Rate,
    NULL Apply_Reduction_Rate_to_Addi,
    NULL Apply_Reduction_Rate_to_Adj,
    NULL Apply_Reduction_Rate_to_Reti,
    NULL Recognize_Gain_or_Loss,
    NULL Recapture_Excess_Reserve,
    NULL Limit_Net_Proceeds_to_Cost,
    NULL Terminal_Gain_or_Loss,
    NULL Tracking_Method,
    NULL Allocate_Excess_Depreciation,
    NULL Depreciate_By,
    NULL Member_Rollup,
    NULL Allo_to_Full_Reti_and_Res_Asst,
    NULL Over_Depreciate,
    NULL PREPARER,
    --           NULL                            MERGED_LEVEL,        commented by arun
    --           NULL                            Parent_Intf_Line_no,  commented by arun
    NULL Sum_Merged_Units,
    NULL New_Master,
    NULL Units_to_Adjust,
    NULL Short_year,
    NULL Conversion_Date,
    NULL ORIGINAL_DEP_START_DATE,
    /*        NULL                            GLOBAL_ATTRIBUTE1,
    NULL                            GLOBAL_ATTRIBUTE2,
    NULL                            GLOBAL_ATTRIBUTE3,
    NULL                            GLOBAL_ATTRIBUTE4,
    NULL                            GLOBAL_ATTRIBUTE5,
    NULL                            GLOBAL_ATTRIBUTE6,
    NULL                            GLOBAL_ATTRIBUTE7,
    NULL                            GLOBAL_ATTRIBUTE8,
    NULL                            GLOBAL_ATTRIBUTE9,
    NULL                            GLOBAL_ATTRIBUTE10,
    NULL                            GLOBAL_ATTRIBUTE11,
    NULL                            GLOBAL_ATTRIBUTE12,
    NULL                            GLOBAL_ATTRIBUTE13,
    NULL                            GLOBAL_ATTRIBUTE14,
    NULL                            GLOBAL_ATTRIBUTE15,
    NULL                            GLOBAL_ATTRIBUTE16,
    NULL                            GLOBAL_ATTRIBUTE17,
    NULL                            GLOBAL_ATTRIBUTE18,
    NULL                            GLOBAL_ATTRIBUTE19,
    NULL                            GLOBAL_ATTRIBUTE20,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER1,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER2,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER3,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER4,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER5,
    NULL                            GLOBAL_ATTRIBUTE_DATE1,
    NULL                            GLOBAL_ATTRIBUTE_DATE2,
    NULL                            GLOBAL_ATTRIBUTE_DATE3,
    NULL                            GLOBAL_ATTRIBUTE_DATE4,
    NULL                            GLOBAL_ATTRIBUTE_DATE5,
    NULL                            GLOBAL_ATTRIBUTE_CATEGORY,
    */
    NBV_at_the_Time_of_Switch,
    NULL Period_Fully_Reserved,
    NULL Start_Period_of_Extended_Dep,
    Earlier_Dep_Limit_Type,
    Earlier_Dep_Limit_Percent,
    Earlier_Dep_Limit_Amount,
    NULL Earlier_Depreciation_Method ,
    Earlier_Life_in_Months,
    Earlier_Basic_Rate,
    EARLIER_ADJUSTED_RATE,
    --          NULL                            ASSET_SCHEDULE_IDENTIFIER,  commented by arun
    NULL Lease_Number,
    NULL Revaluation_Reserve,
    NULL Revaluation_Loss,
    NULL Reval_Reser_Amortization_Basis,
    NULL Impairment_Loss_Expense,
    NULL Revaluation_Cost_Ceiling,
    NULL FAIR_VALUE,
    NULL LAST_USED_PRICE_INDEX_VALUE,
    NULL Supplier_Name,
    NULL Supplier_Number,
    NULL Purchase_Order_Number,
    NULL Invoice_Number,
    NULL Invoice_Voucher_Number,
    NULL Invoice_Date,
    NULL Payables_Units,
    NULL Invoice_Line_Number,
    NULL Invoice_Line_Type,
    NULL Invoice_Line_Description,
    NULL Invoice_Payment_Number,
    NULL Project_Number,
    NULL Task_Number,
    NULL FULLY_DEPRECIATE,
    FA_DETAILS.distribution_id
  FROM
    (SELECT
      /*+ full(ds) full(fth) */
      fab.asset_id interface_line_number,
      fb.book_type_code asset_book,
      fth.transaction_type_code transaction_name,
      fab.asset_number asset_number,
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(fat.description,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' '),chr(34),' inch') Asset_Description ,
      fab.tag_number tag_number,
      fab.manufacturer_name manufacturer,
      REPLACE(fab.serial_number,chr(44),chr(124)) serial_number,
      fab.model_number model ,
      fab.asset_type asset_type,
      fb.cost cost,
      TO_CHAR(fb.DATE_PLACED_IN_SERVICE,'YYYY/MM/DD') Date_Placed_in_Service,
      fb.prorate_convention_code prorate_convention,
      fab.current_units asset_units,
      fcb.segment1 asset_category_segment1,
      fcb.segment2 asset_category_segment2,
      fcb.segment3 asset_category_segment3,
      fcb.segment4 asset_category_segment4,
      fcb.segment5 asset_category_segment5,
      fcb.segment6 asset_category_segment6,
      fcb.segment7 asset_category_segment7,
      (SELECT asset_number
      FROM fa_additions_b
      WHERE asset_id = fab.parent_asset_id
      ) Parent_Asset,
      fab.inventorial in_physical_inventory,
      fab.property_type_code property_type,
      fab.property_1245_1250_code property_class,
      fab.in_use_flag in_use,
      fab.owned_leased ownership,
      fab.new_used bought,
      fab.commitment ,
      fab.investment_law, -- added by arun
      'NO' amortize,
      TO_CHAR(FTH.DATE_EFFECTIVE,'YYYY/MM/DD') Amortization_Start_Date,
      fb.depreciate_flag depreciate,
      fb.salvage_type salvage_value_type,
      fb.salvage_value salvage_value_amount,
      fb.percent_salvage_value salvage_value_percent,
      --ds.YTD_DEPRN YTD_Depreciation,
      DECODE(TO_NUMBER(TO_CHAR(ds.deprn_run_date,'RRRR')),2020,xfs.YTD_DEPRN,0) YTD_Depreciation,
      xfs.deprn_rsv depreciation_reserve,
      ds.bonus_ytd_deprn ytd_bonus_depreciation,
      ds.bonus_deprn_reserve bonus_depreciation_reserve,
      ds.ytd_impairment ,
      ds.impairment_reserve ,
      fb.deprn_method_code depreciation_method ,
      fb.life_in_months ,
      fb.basic_rate ,
      fb.adjusted_rate ,
      fb.unit_of_measure ,
      fb.production_capacity ,
      fb.ceiling_name ceiling_type,
      fb.bonus_rule ,
      fb.deprn_limit_type depreciation_limit_type,
      fb.allowed_deprn_limit depreciation_limit_percent,
      fb.allowed_deprn_limit_amount depreciation_limit_amount,
      fab.attribute1 attribute1,
      fab.attribute2 attribute2,
      fab.attribute3 attribute3,
      fab.attribute4 attribute4,
      fab.attribute5 attribute5,
      fab.attribute6 attribute6,
      fab.attribute7 attribute7,
      fab.attribute8 attribute8,
      fab.attribute9 attribute9,
      fab.attribute10 attribute10,
	  fab.attribute11 attribute11,
      fab.attribute12 attribute12,	  
      fab.attribute14 attribute14,	  
      fab.attribute15 attribute15,	  	  
      fab.attribute_category_code,
      fb.nbv_at_switch nbv_at_the_time_of_switch,
      fb.prior_deprn_limit_type earlier_dep_limit_type,
      fb.prior_deprn_limit earlier_dep_limit_percent,
      fb.prior_deprn_limit_amount earlier_dep_limit_amount,
      fb.prior_life_in_months earlier_life_in_months,
      fb.prior_basic_rate earlier_basic_rate,
      fb.prior_adjusted_rate earlier_adjusted_rate,
      ddtl.distribution_id
    FROM 
	  fa_books fb,
      xx_fa_status xfs,
      fa_book_controls corpbook,
      fa_additions_b fab,
      fa_categories_b fcb,
      fa_additions_tl fat,
      fa_deprn_summary ds,
      fa_deprn_detail ddtl,
      fa_transaction_headers fth
    WHERE 1                =1
    AND xfs.book_type_code =p_book_type_code
    AND xfs.asset_status   ='ACTIVE'
    AND fb.book_type_code      =xfs.book_type_code
    AND fb.asset_id            = xfs.asset_id
    AND corpbook.book_type_code=FB.book_type_code
    AND corpbook.BOOK_CLASS    = 'CORPORATE'
    AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
    AND fb.date_ineffective IS NULL
    AND fab.asset_id         =fb.asset_id
    AND fab.parent_asset_id IS NULL
    AND EXISTS
      (SELECT 'x' FROM fa_additions_b WHERE parent_asset_id = fab.asset_id
      )
    AND fcb.category_id           =fab.asset_category_id
    AND fat.asset_id              =fab.asset_id
    AND fat.language              = 'US'
    AND ds.asset_id               =fb.asset_id
    AND ds.book_type_code         =fb.book_type_code
    AND fth.asset_id              = fab.asset_id
    AND fth.book_type_code        = corpbook.book_type_code
    AND fth.transaction_type_code = 'ADDITION'
    AND ds.period_counter         =
      (SELECT MAX(ds1.period_counter)
      FROM fa_deprn_summary ds1
      WHERE ds1.asset_id     =ds.asset_id
      AND ds1.book_type_code = ds.book_type_code
      )
    AND ddtl.asset_id        =fth.asset_id
    AND ddtl.book_type_code  =fth.book_type_code
    AND ddtl.period_counter  =ds.period_counter
    AND ddtl.distribution_id =
      (SELECT MAX(distribution_id)
      FROM FA_DEPRN_DETAIL
      WHERE asset_id    =ddtl.asset_id
      AND book_type_code=ddtl.book_type_code
      AND period_counter=ddtl.period_counter
      )
    ) FA_DETAILS;
	

CURSOR c_gcc(p_dist_id NUMBER,p_book VARCHAR2)
IS
SELECT 
	gcc.segment1 gcompany,
	gcc.segment6 glob,
	gcc.segment2 gcostcenter,
	gcc.segment3 gaccount,
	gcc.segment4 glocation,
	gcc.segment5 gintercompany
  FROM gl_code_combinations gcc,
       fa_distribution_accounts da
 WHERE da.distribution_id = p_dist_id
   AND da.book_type_code  = p_book
   AND gcc.code_combination_id = da.asset_clearing_account_ccid;
   
  lc_file_handle utl_file.file_type;
  lv_line_count    NUMBER;
  l_file_name      VARCHAR2(500);
  lv_col_title     VARCHAR2(5000);
  l_file_path      VARCHAR2(500):='XXFIN_OUTBOUND';---/app/ebs/ctgsidev02/xxfin/outbound
  lc_errormsg      VARCHAR2(1000);                ----            VARCHAR2(1000) := NULL;
  v_book_type_code VARCHAR2(100);
  v_segment1       VARCHAR2(50);
  v_segment2       VARCHAR2(50);
  v_segment3       VARCHAR2(50);
  v_segment4       VARCHAR2(50);
  v_segment5       VARCHAR2(50);
  v_segment6       VARCHAR2(50);
  v_rec_count      NUMBER:=0;
  v_success_count  NUMBER:=0;
  v_failure_count  NUMBER:=0;
  v_status         VARCHAR2(1);
  v_error_msg      VARCHAR2(100);
  lv_xx_fa_conv_asset_hdr xx_fa_conv_asset_hdr%ROWTYPE;
  v_gcompany       VARCHAR2(50);
  v_glob	       VARCHAR2(50);
  v_gcostcenter    VARCHAR2(50);
  v_gaccount       VARCHAR2(50);
  v_glocation      VARCHAR2(50);
  v_gintercompany  VARCHAR2(50);

BEGIN
  FOR rec IN c_pas_asset_hdr
  LOOP
    v_segment1                        :=NULL;
    v_segment2                        :=NULL;
    v_segment3                        :=NULL;
    v_segment4                        :=NULL;
    v_segment5                        :=NULL;
    v_segment6                        :=NULL;
    v_status                          :='N';
    v_error_msg                       :=NULL;
    v_gcompany       				  :=NULL;
    v_glob	       		:=NULL;
    v_gcostcenter    	:=NULL;
    v_gaccount       	:=NULL;
    v_glocation      	:=NULL;
    v_gintercompany  	:=NULL;

    IF rec.cost_clearing_account_seg1 IS NULL OR rec.cost_clearing_account_seg2 IS NULL OR rec.cost_clearing_account_seg3 IS NULL OR rec.cost_clearing_account_seg4 IS NULL OR rec.cost_clearing_account_seg5 IS NULL OR rec.cost_clearing_account_seg6 IS NULL THEN
      v_segment1                      :=gc_entity;
      v_segment2                      :=gc_lob;
      v_segment3                      :=gc_costcenter;
      v_segment4                      :=gc_account;
      v_segment5                      :=gc_location;
      v_segment6                      :=gc_ic;
      v_status                        :='C';
	  OPEN c_gcc(rec.distribution_id,rec.asset_book);
	  FETCH c_gcc 
	   INTO v_gcompany,v_glob,v_gcostcenter,v_gaccount,v_glocation,v_gintercompany;
	  CLOSE c_gcc;
/*	  print_debug_msg ('Dist id :'||to_char(rec.distribution_id), true);
	  print_debug_msg ('Company  :'||v_gcompany, true);
	  print_debug_msg ('LOB      :'||v_glob, true);
	  print_debug_msg ('CC       :'||v_gcostcenter, true);
	  print_debug_msg ('Acct     :'||v_gaccount, true);
	  print_debug_msg ('Loc      :'||v_glocation, true);
	  print_debug_msg ('Interco  :'||v_gintercompany, true);	  
	  */
      --v_error_msg                     :='CTU Mapping Failure';
      ctu_mapping_validation( 'ASSET_HDR', 
							   v_gcompany,
							   v_glob,
							   v_gcostcenter,
							   v_gaccount,
							   v_glocation,
							   v_gintercompany,
							   rec.cost_clearing_account_seg1, 
							   rec.cost_clearing_account_seg2, 
							   rec.cost_clearing_account_seg3, 
							   rec.cost_clearing_account_seg4, 
							   rec.cost_clearing_account_seg5, 
							   rec.cost_clearing_account_seg6, 
							   rec.interface_line_number, 
							   rec.asset_book, 
							   v_error_msg );
    ELSE
      v_segment1:=rec.cost_clearing_account_seg1;
      v_segment2:=rec.cost_clearing_account_seg2;
      v_segment3:=rec.cost_clearing_account_seg3;
      v_segment4:=rec.cost_clearing_account_seg4;
      v_segment5:=rec.cost_clearing_account_seg5;
      v_segment6:=rec.cost_clearing_account_seg6;
    END IF;
    BEGIN
      lv_xx_fa_conv_asset_hdr                            :=NULL ;
      lv_xx_fa_conv_asset_hdr.asset_id                   :=rec.interface_line_number ;
      lv_xx_fa_conv_asset_hdr.book_type_code             :=rec.asset_book ;
      lv_xx_fa_conv_asset_hdr.asset_attribute_category   :='PARENT' ;
      lv_xx_fa_conv_asset_hdr.transaction_name           :=rec.transaction_name ;
      lv_xx_fa_conv_asset_hdr.asset_number               :=rec.asset_number ;
      lv_xx_fa_conv_asset_hdr.asset_description          :=rec.asset_description ;
      lv_xx_fa_conv_asset_hdr.tag_number                 :=rec.tag_number ;
      lv_xx_fa_conv_asset_hdr.manufacturer               :=rec.manufacturer ;
      lv_xx_fa_conv_asset_hdr.serial_number              :=rec.serial_number ;
      lv_xx_fa_conv_asset_hdr.model                      :=rec.model ;
      lv_xx_fa_conv_asset_hdr.asset_type                 :=rec.asset_type ;
      lv_xx_fa_conv_asset_hdr.cost                       :=rec.cost ;
      lv_xx_fa_conv_asset_hdr.date_placed_in_service     :=rec.date_placed_in_service ;
      lv_xx_fa_conv_asset_hdr.prorate_convention         :=rec.prorate_convention ;
      lv_xx_fa_conv_asset_hdr.asset_units                :=rec.asset_units ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment1    :=rec.asset_category_segment1 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment2    :=rec.asset_category_segment2 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment3    :=rec.asset_category_segment3 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment4    :=rec.asset_category_segment4 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment5    :=rec.asset_category_segment5 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment6    :=rec.asset_category_segment6 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment7    :=rec.asset_category_segment7 ;
      lv_xx_fa_conv_asset_hdr.parent_asset               :=rec.parent_asset ;
      lv_xx_fa_conv_asset_hdr.in_physical_inventory      :=rec.in_physical_inventory ;
      lv_xx_fa_conv_asset_hdr.property_type              :=rec.property_type ;
      lv_xx_fa_conv_asset_hdr.property_class             :=rec.property_class ;
      lv_xx_fa_conv_asset_hdr.in_use                     :=rec.in_use ;
      lv_xx_fa_conv_asset_hdr.ownership                  :=rec.ownership ;
      lv_xx_fa_conv_asset_hdr.bought                     :=rec.bought ;
      lv_xx_fa_conv_asset_hdr.commitment                 :=rec.commitment ;
      lv_xx_fa_conv_asset_hdr.investment_law             :=rec.investment_law ;
      lv_xx_fa_conv_asset_hdr.amortize                   :=rec.amortize ;
      lv_xx_fa_conv_asset_hdr.amortization_start_date    :=rec.amortization_start_date ;
      lv_xx_fa_conv_asset_hdr.depreciate                 :=rec.depreciate ;
      lv_xx_fa_conv_asset_hdr.salvage_value_type         :=rec.salvage_value_type ;
      lv_xx_fa_conv_asset_hdr.salvage_value_amount       :=rec.salvage_value_amount ;
      lv_xx_fa_conv_asset_hdr.salvage_value_percent      :=rec.salvage_value_percent ;
      lv_xx_fa_conv_asset_hdr.ytd_depreciation           :=rec.ytd_depreciation ;
      lv_xx_fa_conv_asset_hdr.depreciation_reserve       :=rec.depreciation_reserve ;
      lv_xx_fa_conv_asset_hdr.ytd_bonus_depreciation     :=rec.ytd_bonus_depreciation ;
      lv_xx_fa_conv_asset_hdr.bonus_depreciation_reserve :=rec.bonus_depreciation_reserve ;
      lv_xx_fa_conv_asset_hdr.ytd_impairment             :=rec.ytd_impairment ;
      lv_xx_fa_conv_asset_hdr.impairment_reserve         :=rec.impairment_reserve ;
      lv_xx_fa_conv_asset_hdr.depreciation_method        :=rec.depreciation_method ;
      lv_xx_fa_conv_asset_hdr.life_in_months             :=rec.life_in_months ;
      lv_xx_fa_conv_asset_hdr.basic_rate                 :=rec.basic_rate ;
      lv_xx_fa_conv_asset_hdr.adjusted_rate              :=rec.adjusted_rate ;
      lv_xx_fa_conv_asset_hdr.unit_of_measure            :=rec.unit_of_measure ;
      lv_xx_fa_conv_asset_hdr.production_capacity        :=rec.production_capacity ;
      lv_xx_fa_conv_asset_hdr.ceiling_type               :=rec.ceiling_type ;
      lv_xx_fa_conv_asset_hdr.bonus_rule                 :=rec.bonus_rule ;
      lv_xx_fa_conv_asset_hdr.depreciation_limit_type    :=rec.depreciation_limit_type ;
      lv_xx_fa_conv_asset_hdr.depreciation_limit_percent :=rec.depreciation_limit_percent ;
      lv_xx_fa_conv_asset_hdr.depreciation_limit_amount  :=rec.depreciation_limit_amount ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg1 :=v_segment1 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg2 :=v_segment2 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg3 :=v_segment3 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg4 :=v_segment4 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg5 :=v_segment5 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg6 :=v_segment6 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg7 :=rec.cost_clearing_account_seg7 ;
      lv_xx_fa_conv_asset_hdr.attribute1                 :=rec.attribute1 ;
      lv_xx_fa_conv_asset_hdr.attribute2                 :=rec.attribute2 ;
      lv_xx_fa_conv_asset_hdr.attribute3                 :=rec.attribute3 ;
      lv_xx_fa_conv_asset_hdr.attribute4                 :=rec.attribute4 ;
      lv_xx_fa_conv_asset_hdr.attribute5                 :=rec.attribute5 ;
      lv_xx_fa_conv_asset_hdr.attribute6                 :=rec.attribute6 ;
      lv_xx_fa_conv_asset_hdr.attribute7                 :=rec.attribute7 ;
      lv_xx_fa_conv_asset_hdr.attribute8                 :=rec.attribute8 ;
      lv_xx_fa_conv_asset_hdr.attribute9                 :=rec.attribute9 ;
      lv_xx_fa_conv_asset_hdr.attribute10                :=rec.attribute10 ;
      lv_xx_fa_conv_asset_hdr.attribute11                :=rec.attribute11 ;
      lv_xx_fa_conv_asset_hdr.attribute12                :=rec.attribute12 ;
      lv_xx_fa_conv_asset_hdr.attribute13                :=rec.attribute13 ;
      lv_xx_fa_conv_asset_hdr.attribute14                :=rec.attribute14 ;
      lv_xx_fa_conv_asset_hdr.attribute15                :=rec.attribute15 ;	  
      lv_xx_fa_conv_asset_hdr.attribute_category_code    :=rec.attribute_category_code ;
      lv_xx_fa_conv_asset_hdr.nbv_at_the_time_of_switch  :=rec.nbv_at_the_time_of_switch ;
      lv_xx_fa_conv_asset_hdr.earlier_dep_limit_type     :=rec.earlier_dep_limit_type ;
      lv_xx_fa_conv_asset_hdr.earlier_dep_limit_percent  :=rec.earlier_dep_limit_percent ;
      lv_xx_fa_conv_asset_hdr.earlier_dep_limit_amount   :=rec.earlier_dep_limit_amount ;
      lv_xx_fa_conv_asset_hdr.earlier_life_in_months     :=rec.earlier_life_in_months ;
      lv_xx_fa_conv_asset_hdr.earlier_basic_rate         :=rec.earlier_basic_rate ;
      lv_xx_fa_conv_asset_hdr.earlier_adjusted_rate      :=rec.earlier_adjusted_rate ;
      lv_xx_fa_conv_asset_hdr.request_id                 :=NVL(fnd_global.conc_request_id, -1);
      lv_xx_fa_conv_asset_hdr.created_by                 :=NVL(fnd_global.user_id,         -1);
      lv_xx_fa_conv_asset_hdr.creation_date              :=SYSDATE;
      lv_xx_fa_conv_asset_hdr.last_updated_by            :=NVL(fnd_global.user_id,   -1);
      lv_xx_fa_conv_asset_hdr.last_update_login          :=NVL(fnd_global.login_id , -1);
      lv_xx_fa_conv_asset_hdr.last_update_date           := SYSDATE;
      lv_xx_fa_conv_asset_hdr.status                     :=v_status ;
      lv_xx_fa_conv_asset_hdr.error_description          :=v_error_msg;
      INSERT INTO xx_fa_conv_asset_hdr VALUES lv_XX_FA_CONV_ASSET_HDR;
      v_rec_count    :=v_rec_count    +1;
      v_success_count:=v_success_count+1;
    EXCEPTION
    WHEN OTHERS THEN
      lc_errormsg := 'In Procedure GENERIC_PARENT_ASSETS_HDR.Error to insert into XX_FA_CONV_ASSET_HDR for Asset Id:'||rec.Interface_Line_Number || '. SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE ;
      print_debug_msg (lc_errormsg, true);
      v_failure_count:=v_failure_count+1;
    END;
    IF v_rec_count>5000 THEN
      COMMIT;
      v_rec_count:=0;
    END IF;
  END LOOP;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in generic_parent_assets_hdr procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
END generic_parent_assets_hdr;
PROCEDURE generic_child_assets_hdr
  (
    p_book_type_code VARCHAR2
  )
IS
  CURSOR c_child_asset_hdr
  IS
    SELECT
      /*+ parallel(8) */
      Interface_Line_Number,
      Asset_Book,
      Transaction_Name,
      Asset_Number,
      Asset_Description ,
      Tag_Number,
      Manufacturer,
      Serial_Number,
      Model ,
      Asset_Type,
      Cost,
      Date_Placed_in_Service,
      Prorate_Convention,
      Asset_Units,
      Asset_Category_Segment1,
      Asset_Category_Segment2,
      Asset_Category_Segment3,
      Asset_Category_Segment4,
      Asset_Category_Segment5,
      Asset_Category_Segment6,
      Asset_Category_Segment7,
      'POST' Posting_Status,
      'NEW' Queue_Name,
      'ORACLE FBDI' Feeder_System,
      Parent_Asset,
      NULL Add_to_Asset,
      NULL Asset_Key_Segment1,
      NULL Asset_Key_Segment2,
      NULL Asset_Key_Segment3,
      NULL Asset_Key_Segment4,
      NULL Asset_Key_Segment5,
      NULL Asset_Key_Segment6,
      NULL Asset_Key_Segment7,
      NULL Asset_Key_Segment8,
      NULL Asset_Key_Segment9,
      NULL Asset_Key_Segment10,
      In_physical_inventory,
      Property_Type,
      PROPERTY_CLASS,
      --           fa_details.distribution_id,  -- Moved to end by Arun
      In_use,
      Ownership,
      Bought,
      NULL MATERIAL_INDICATOR,
      COMMITMENT ,
      INVESTMENT_LAW, --arunadded
      Amortize,
      Amortization_Start_Date,
      Depreciate,
      Salvage_Value_Type,
      Salvage_Value_Amount,
      Salvage_Value_Percent,
      YTD_Depreciation,
      Depreciation_Reserve,
      YTD_Bonus_Depreciation,
      Bonus_Depreciation_Reserve,
      YTD_IMPAIRMENT ,
      IMPAIRMENT_RESERVE ,
      Depreciation_Method ,
      LIFE_IN_MONTHS ,
      BASIC_RATE ,
      ADJUSTED_RATE ,
      UNIT_OF_MEASURE ,
      PRODUCTION_CAPACITY ,
      Ceiling_Type,
      BONUS_RULE ,
      NULL CASH_GENERATING_UNIT ,
      Depreciation_Limit_Type,
      Depreciation_Limit_Percent,
      Depreciation_Limit_Amount,
      NULL INVOICE_COST,
      (SELECT xx_gl_beacon_mapping_f1(gcc.segment1,'ENTITY','A')--ENTITY
      FROM gl_code_combinations gcc,
        fa_distribution_accounts da
      WHERE da.distribution_id    = fa_details.distribution_id
      AND da.book_type_code       = fa_details.asset_book
      AND gcc.code_combination_id = da.asset_clearing_account_ccid
      ) cost_clearing_account_seg1,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment6,'LOB','A')----LOB
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg2,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment2,'COST_CENTER','A')------COST CENTER
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg3,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment3,'ACCOUNT','A')----ACCOUNT
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg4,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment4,'LOCATION','A')---LOCATION
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg5,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment5,'ENTITY','A')-----INTERCOMP
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg6,
    NULL cost_clearing_account_seg7,
    NULL Cost_Clearing_Account_Seg8,
    NULL Cost_Clearing_Account_Seg9,
    NULL COST_CLEARING_ACCOUNT_SEG10,
    NULL Cost_Clearing_Account_Seg11,
    NULL Cost_Clearing_Account_Seg12,
    NULL Cost_Clearing_Account_Seg13,
    NULL Cost_Clearing_Account_Seg14,
    NULL COST_CLEARING_ACCOUNT_SEG15,
    /*           NULL                            CLEARING_ACCT_SEGMENT16,
    NULL                            CLEARING_ACCT_SEGMENT17,
    NULL                            CLEARING_ACCT_SEGMENT18,
    NULL                            CLEARING_ACCT_SEGMENT19,
    NULL                            CLEARING_ACCT_SEGMENT20,
    NULL                            CLEARING_ACCT_SEGMENT21,
    NULL                            CLEARING_ACCT_SEGMENT22,
    NULL                            CLEARING_ACCT_SEGMENT23,
    NULL                            CLEARING_ACCT_SEGMENT24,
    NULL                            CLEARING_ACCT_SEGMENT25,
    NULL                            CLEARING_ACCT_SEGMENT26,
    NULL                            CLEARING_ACCT_SEGMENT27,
    NULL                            CLEARING_ACCT_SEGMENT28,
    NULL                            CLEARING_ACCT_SEGMENT29,
    NULL                            CLEARING_ACCT_SEGMENT30,
    */
    fa_details.ATTRIBUTE1,
    fa_details.ATTRIBUTE2,
    fa_details.ATTRIBUTE3,
    fa_details.ATTRIBUTE4,
    fa_details.ATTRIBUTE5,
    fa_details.ATTRIBUTE6,
    fa_details.ATTRIBUTE7,
    fa_details.ATTRIBUTE8,
    fa_details.ATTRIBUTE9,
    fa_details.ATTRIBUTE10,
    fa_details.ATTRIBUTE11,
    fa_details.ATTRIBUTE12,
    NULL ATTRIBUTE13,
    fa_details.ATTRIBUTE14,
    fa_details.ATTRIBUTE15,
    /*
    NULL                            ATTRIBUTE16,
    NULL                            ATTRIBUTE17,
    NULL                            ATTRIBUTE18,
    NULL                            ATTRIBUTE19,
    NULL                            ATTRIBUTE20,
    NULL                            ATTRIBUTE21,
    NULL                            ATTRIBUTE22,
    NULL                            ATTRIBUTE23,
    NULL                            ATTRIBUTE24,
    NULL                            ATTRIBUTE25,
    NULL                            ATTRIBUTE26,
    NULL                            ATTRIBUTE27,
    NULL                            ATTRIBUTE28,
    NULL                            ATTRIBUTE29,
    NULL                            ATTRIBUTE30,
    NULL                            ATTRIBUTE_NUMBER1,
    NULL                            ATTRIBUTE_NUMBER2,
    NULL                            ATTRIBUTE_NUMBER3,
    NULL                            ATTRIBUTE_NUMBER4,
    NULL                            ATTRIBUTE_NUMBER5,
    NULL                            ATTRIBUTE_DATE1,
    NULL                            ATTRIBUTE_DATE2,
    NULL                            ATTRIBUTE_DATE3,
    NULL                            ATTRIBUTE_DATE4,
    NULL                            ATTRIBUTE_DATE5,
    */
    ATTRIBUTE_CATEGORY_CODE,
    NULL context,
    /*
    NULL                            TH_ATTRIBUTE1,
    NULL                            TH_ATTRIBUTE2,
    NULL                            TH_ATTRIBUTE3,
    NULL                            TH_ATTRIBUTE4,
    NULL                            TH_ATTRIBUTE5,
    NULL                            TH_ATTRIBUTE6,
    NULL                            TH_ATTRIBUTE7,
    NULL                            TH_ATTRIBUTE8,
    NULL                            TH_ATTRIBUTE9,
    NULL                            TH_ATTRIBUTE10,
    NULL                            TH_ATTRIBUTE11,
    NULL                            TH_ATTRIBUTE12,
    NULL                            TH_ATTRIBUTE13,
    NULL                            TH_ATTRIBUTE14,
    NULL                            TH_ATTRIBUTE15,
    NULL                            TH_ATTRIBUTE_NUMBER1,
    NULL                            TH_ATTRIBUTE_NUMBER2,
    NULL                            TH_ATTRIBUTE_NUMBER3,
    NULL                            TH_ATTRIBUTE_NUMBER4,
    NULL                            TH_ATTRIBUTE_NUMBER5,
    NULL                            TH_ATTRIBUTE_DATE1,
    NULL                            TH_ATTRIBUTE_DATE2,
    NULL                            TH_ATTRIBUTE_DATE3,
    NULL                            TH_ATTRIBUTE_DATE4,
    NULL                            TH_ATTRIBUTE_DATE5,
    NULL                            TH_ATTRIBUTE_CATEGORY_CODE,
    NULL                            TH2_ATTRIBUTE1,
    NULL                            TH2_ATTRIBUTE2,
    NULL                            TH2_ATTRIBUTE3,
    NULL                            TH2_ATTRIBUTE4,
    NULL                            TH2_ATTRIBUTE5,
    NULL                            TH2_ATTRIBUTE6,
    NULL                            TH2_ATTRIBUTE7,
    NULL                            TH2_ATTRIBUTE8,
    NULL                            TH2_ATTRIBUTE9,
    NULL                            TH2_ATTRIBUTE10,
    NULL                            TH2_ATTRIBUTE11,
    NULL                            TH2_ATTRIBUTE12,
    NULL                            TH2_ATTRIBUTE13,
    NULL                            TH2_ATTRIBUTE14,
    NULL                            TH2_ATTRIBUTE15,
    NULL                            TH2_ATTRIBUTE_NUMBER1,
    NULL                            TH2_ATTRIBUTE_NUMBER2,
    NULL                            TH2_ATTRIBUTE_NUMBER3,
    NULL                            TH2_ATTRIBUTE_NUMBER4,
    NULL                            TH2_ATTRIBUTE_NUMBER5,
    NULL                            TH2_ATTRIBUTE_DATE1,
    NULL                            TH2_ATTRIBUTE_DATE2,
    NULL                            TH2_ATTRIBUTE_DATE3,
    NULL                            TH2_ATTRIBUTE_DATE4,
    NULL                            TH2_ATTRIBUTE_DATE5,
    NULL                            TH2_ATTRIBUTE_CATEGORY_CODE,
    NULL                            AI_ATTRIBUTE1,
    NULL                            AI_ATTRIBUTE2,
    NULL                            AI_ATTRIBUTE3,
    NULL                            AI_ATTRIBUTE4,
    NULL                            AI_ATTRIBUTE5,
    NULL                            AI_ATTRIBUTE6,
    NULL                            AI_ATTRIBUTE7,
    NULL                            AI_ATTRIBUTE8,
    NULL                            AI_ATTRIBUTE9,
    NULL                            AI_ATTRIBUTE10,
    NULL                            AI_ATTRIBUTE11,
    NULL                            AI_ATTRIBUTE12,
    NULL                            AI_ATTRIBUTE13,
    NULL                            AI_ATTRIBUTE14,
    NULL                            AI_ATTRIBUTE15,
    NULL                            AI_ATTRIBUTE_NUMBER1,
    NULL                            AI_ATTRIBUTE_NUMBER2,
    NULL                            AI_ATTRIBUTE_NUMBER3,
    NULL                            AI_ATTRIBUTE_NUMBER4,
    NULL                            AI_ATTRIBUTE_NUMBER5,
    NULL                            AI_ATTRIBUTE_DATE1,
    NULL                            AI_ATTRIBUTE_DATE2,
    NULL                            AI_ATTRIBUTE_DATE3,
    NULL                            AI_ATTRIBUTE_DATE4,
    NULL                            AI_ATTRIBUTE_DATE5,
    NULL                            AI_ATTRIBUTE_CATEGORY_CODE,
    */
    NULL Mass_Property_Eligible,
    NULL Group_Asset,
    NULL Reduction_Rate,
    NULL Apply_Reduction_Rate_to_Addi,
    NULL Apply_Reduction_Rate_to_Adj,
    NULL Apply_Reduction_Rate_to_Reti,
    NULL Recognize_Gain_or_Loss,
    NULL Recapture_Excess_Reserve,
    NULL Limit_Net_Proceeds_to_Cost,
    NULL Terminal_Gain_or_Loss,
    NULL Tracking_Method,
    NULL Allocate_Excess_Depreciation,
    NULL Depreciate_By,
    NULL Member_Rollup,
    NULL Allo_to_Full_Reti_and_Res_Asst,
    NULL Over_Depreciate,
    NULL PREPARER,
    --           NULL                            MERGED_LEVEL,        commented by arun
    --           NULL                            Parent_Intf_Line_no,  commented by arun
    NULL Sum_Merged_Units,
    NULL New_Master,
    NULL Units_to_Adjust,
    NULL Short_year,
    NULL Conversion_Date,
    NULL ORIGINAL_DEP_START_DATE,
    /*        NULL                            GLOBAL_ATTRIBUTE1,
    NULL                            GLOBAL_ATTRIBUTE2,
    NULL                            GLOBAL_ATTRIBUTE3,
    NULL                            GLOBAL_ATTRIBUTE4,
    NULL                            GLOBAL_ATTRIBUTE5,
    NULL                            GLOBAL_ATTRIBUTE6,
    NULL                            GLOBAL_ATTRIBUTE7,
    NULL                            GLOBAL_ATTRIBUTE8,
    NULL                            GLOBAL_ATTRIBUTE9,
    NULL                            GLOBAL_ATTRIBUTE10,
    NULL                            GLOBAL_ATTRIBUTE11,
    NULL                            GLOBAL_ATTRIBUTE12,
    NULL                            GLOBAL_ATTRIBUTE13,
    NULL                            GLOBAL_ATTRIBUTE14,
    NULL                            GLOBAL_ATTRIBUTE15,
    NULL                            GLOBAL_ATTRIBUTE16,
    NULL                            GLOBAL_ATTRIBUTE17,
    NULL                            GLOBAL_ATTRIBUTE18,
    NULL                            GLOBAL_ATTRIBUTE19,
    NULL                            GLOBAL_ATTRIBUTE20,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER1,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER2,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER3,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER4,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER5,
    NULL                            GLOBAL_ATTRIBUTE_DATE1,
    NULL                            GLOBAL_ATTRIBUTE_DATE2,
    NULL                            GLOBAL_ATTRIBUTE_DATE3,
    NULL                            GLOBAL_ATTRIBUTE_DATE4,
    NULL                            GLOBAL_ATTRIBUTE_DATE5,
    NULL                            GLOBAL_ATTRIBUTE_CATEGORY,
    */
    NBV_at_the_Time_of_Switch,
    NULL Period_Fully_Reserved,
    NULL Start_Period_of_Extended_Dep,
    Earlier_Dep_Limit_Type,
    Earlier_Dep_Limit_Percent,
    Earlier_Dep_Limit_Amount,
    NULL Earlier_Depreciation_Method ,
    Earlier_Life_in_Months,
    Earlier_Basic_Rate,
    EARLIER_ADJUSTED_RATE,
    --          NULL                            ASSET_SCHEDULE_IDENTIFIER,  commented by arun
    NULL Lease_Number,
    NULL Revaluation_Reserve,
    NULL Revaluation_Loss,
    NULL Reval_Reser_Amortization_Basis,
    NULL Impairment_Loss_Expense,
    NULL Revaluation_Cost_Ceiling,
    NULL FAIR_VALUE,
    NULL LAST_USED_PRICE_INDEX_VALUE,
    NULL Supplier_Name,
    NULL Supplier_Number,
    NULL Purchase_Order_Number,
    NULL Invoice_Number,
    NULL Invoice_Voucher_Number,
    NULL Invoice_Date,
    NULL Payables_Units,
    NULL Invoice_Line_Number,
    NULL Invoice_Line_Type,
    NULL Invoice_Line_Description,
    NULL Invoice_Payment_Number,
    NULL Project_Number,
    NULL Task_Number,
    NULL FULLY_DEPRECIATE,
    FA_DETAILS.distribution_id
  FROM
    (SELECT
      /*+ full(ds) full(fth) */
      FAB.ASSET_ID Interface_Line_Number,
      FB.BOOK_TYPE_CODE Asset_Book,
      fth.TRANSACTION_TYPE_CODE Transaction_Name,
      FAB.ASSET_NUMBER Asset_Number,
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(fat.description,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' '),chr(34),' inch') Asset_Description,
      --               FAT.DESCRIPTION                 Asset_Description ,
      FAB.TAG_NUMBER Tag_Number,
      FAB.MANUFACTURER_NAME Manufacturer,
      REPLACE(fab.serial_number,chr(44),chr(124)) serial_number,
      FAB.MODEL_NUMBER Model ,
      FAB.ASSET_TYPE Asset_Type,
      fb.COST Cost,
      TO_CHAR(fb.DATE_PLACED_IN_SERVICE,'YYYY/MM/DD') Date_Placed_in_Service,
      FB.PRORATE_CONVENTION_CODE Prorate_Convention,
      fab.CURRENT_UNITS Asset_Units,
      FCB.SEGMENT1 Asset_Category_Segment1,
      FCB.SEGMENT2 Asset_Category_Segment2,
      FCB.SEGMENT3 Asset_Category_Segment3,
      FCB.SEGMENT4 Asset_Category_Segment4,
      FCB.SEGMENT5 Asset_Category_Segment5,
      FCB.SEGMENT6 Asset_Category_Segment6,
      FCB.SEGMENT7 Asset_Category_Segment7,
      (SELECT xxfss.ASSET_ID
      FROM xx_fa_status xxfss
      WHERE xxfss.asset_id     =fab.parent_asset_id
      AND xxfss.book_type_code = fb.book_type_code
      AND xxfss.asset_status   = 'ACTIVE'
      ) Parent_Asset,
      fab.INVENTORIAL In_physical_inventory,
      fab.PROPERTY_TYPE_CODE Property_Type,
      fab.PROPERTY_1245_1250_CODE Property_Class,
      fab.IN_USE_FLAG In_use,
      fab.OWNED_LEASED Ownership,
      fab.NEW_USED Bought,
      FAB.COMMITMENT ,
      fab.investment_law, -- added by Arun
      'NO' Amortize,
      TO_CHAR(FTH.DATE_EFFECTIVE,'YYYY/MM/DD') Amortization_Start_Date,
      fb.DEPRECIATE_FLAG Depreciate,
      fb.SALVAGE_TYPE Salvage_Value_Type,
      fb.SALVAGE_VALUE Salvage_Value_Amount,
      fb.PERCENT_SALVAGE_VALUE Salvage_Value_Percent,
      --ds.YTD_DEPRN YTD_Depreciation,
      DECODE(to_number(TO_CHAR(ds.deprn_run_date,'RRRR')),2020,xfs.YTD_DEPRN,0) YTD_Depreciation,
      xfs.DEPRN_RSV Depreciation_Reserve,
      ds.BONUS_YTD_DEPRN YTD_Bonus_Depreciation,
      ds.BONUS_DEPRN_RESERVE Bonus_Depreciation_Reserve,
      ds.YTD_IMPAIRMENT ,
      ds.IMPAIRMENT_RESERVE ,
      fb.deprn_method_code Depreciation_Method ,
      fb.LIFE_IN_MONTHS ,
      FB.BASIC_RATE ,
      fb.ADJUSTED_RATE ,
      fb.UNIT_OF_MEASURE ,
      fb.PRODUCTION_CAPACITY ,
      fb.CEILING_NAME Ceiling_Type,
      fb.BONUS_RULE ,
      fb.DEPRN_LIMIT_TYPE Depreciation_Limit_Type,
      fb.ALLOWED_DEPRN_LIMIT Depreciation_Limit_Percent,
      fb.ALLOWED_DEPRN_LIMIT_AMOUNT Depreciation_Limit_Amount,
      fab.attribute1 ATTRIBUTE1,
      fab.attribute2 ATTRIBUTE2,
      fab.attribute3 ATTRIBUTE3,
      fab.attribute4 ATTRIBUTE4,
      fab.ATTRIBUTE5 ATTRIBUTE5,
      fab.ATTRIBUTE6 ATTRIBUTE6,
      fab.ATTRIBUTE7 ATTRIBUTE7,
      fab.ATTRIBUTE8 ATTRIBUTE8,
      fab.ATTRIBUTE9 ATTRIBUTE9,
      fab.ATTRIBUTE10 ATTRIBUTE10,
      fab.ATTRIBUTE11 ATTRIBUTE11,
      fab.ATTRIBUTE12 ATTRIBUTE12,
      fab.ATTRIBUTE14 ATTRIBUTE14,
      fab.ATTRIBUTE15 ATTRIBUTE15,	  
      fab.ATTRIBUTE_CATEGORY_CODE,
      fb.NBV_AT_SWITCH NBV_at_the_Time_of_Switch,
      fb.PRIOR_DEPRN_LIMIT_TYPE Earlier_Dep_Limit_Type,
      fb.PRIOR_DEPRN_LIMIT Earlier_Dep_Limit_Percent,
      fb.PRIOR_DEPRN_LIMIT_AMOUNT Earlier_Dep_Limit_Amount,
      fb.PRIOR_LIFE_IN_MONTHS Earlier_Life_in_Months,
      fb.PRIOR_BASIC_RATE Earlier_Basic_Rate,
      fb.PRIOR_ADJUSTED_RATE Earlier_Adjusted_Rate,
      ddtl.distribution_id
    FROM 
	  FA_BOOKS fb,
      xx_fa_status xfs,
      FA_BOOK_CONTROLS corpbook,
      FA_ADDITIONS_B FAB,
      FA_CATEGORIES_B FCB,
      FA_ADDITIONS_TL FAT,
      FA_DEPRN_SUMMARY ds,
      FA_DEPRN_DETAIL ddtl,
      FA_TRANSACTION_HEADERS fth
    WHERE 1                =1
    AND xfs.book_type_code =p_book_type_code--'OD US CORP'
    AND xfs.ASSET_STATUS   ='ACTIVE'
    AND fb.book_type_code      =xfs.book_type_code
    AND fb.asset_id            = xfs.asset_id
    AND corpbook.book_type_code=FB.book_type_code
    AND corpbook.BOOK_CLASS    = 'CORPORATE'
    AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
    AND fb.date_ineffective IS NULL
	AND FAB.ASSET_ID=FB.ASSET_ID
    AND NOT EXISTS
      (SELECT 'x' FROM fa_additions_b WHERE parent_asset_id = fab.ASSET_ID
      )
    AND fcb.category_id           =fab.asset_category_id
    AND fat.ASSET_ID              =fab.ASSET_ID
    AND fat.language              = 'US'
    AND ds.asset_id               =fb.asset_id
    AND ds.book_type_code         =fb.book_type_code
    AND fth.ASSET_ID              = fab.ASSET_ID
    AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
    AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
    AND DS.PERIOD_COUNTER         =
      (SELECT MAX(DS1.PERIOD_COUNTER)
      FROM FA_DEPRN_SUMMARY DS1
      WHERE DS1.ASSET_ID     =DS.ASSET_ID
      AND DS1.BOOK_TYPE_CODE = DS.BOOK_TYPE_CODE
      )
    AND ddtl.asset_id       =fth.asset_id
    AND ddtl.book_type_code =fth.book_type_code
    AND ddtl.period_counter =ds.period_counter
    AND ddtl.distribution_id=
      (SELECT MAX(distribution_id)
      FROM FA_DEPRN_DETAIL
      WHERE asset_id    =ddtl.asset_id
      AND book_type_code=ddtl.book_type_code
      AND period_counter=ddtl.period_counter
      )
    ) FA_DETAILS
  ORDER BY interface_line_number;

CURSOR c_gcc(p_dist_id NUMBER,p_book VARCHAR2)
IS
SELECT 
	gcc.segment1 gcompany,
	gcc.segment6 glob,
	gcc.segment2 gcostcenter,
	gcc.segment3 gaccount,
	gcc.segment4 glocation,
	gcc.segment5 gintercompany
  FROM gl_code_combinations gcc,
       fa_distribution_accounts da
 WHERE da.distribution_id = p_dist_id
   AND da.book_type_code  = p_book
   AND gcc.code_combination_id = da.asset_clearing_account_ccid;

   
  lc_file_handle utl_file.file_type;
  lv_line_count    NUMBER;
  l_file_name      VARCHAR2(500);
  lv_col_title     VARCHAR2(5000);
  l_file_path      VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg      VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  v_book_type_code VARCHAR2(100);
  v_segment1       VARCHAR2(50);
  v_segment2       VARCHAR2(50);
  v_segment3       VARCHAR2(50);
  v_segment4       VARCHAR2(50);
  v_segment5       VARCHAR2(50);
  v_segment6       VARCHAR2(50);
  v_rec_count      NUMBER:=0;
  v_success_count  NUMBER:=0;
  v_failure_count  NUMBER:=0;
  v_status         VARCHAR2(1);
  v_error_msg      VARCHAR2(100);
  lv_xx_fa_conv_asset_hdr xx_fa_conv_asset_hdr%ROWTYPE;

  v_gcompany       VARCHAR2(50);
  v_glob	       VARCHAR2(50);
  v_gcostcenter    VARCHAR2(50);
  v_gaccount       VARCHAR2(50);
  v_glocation      VARCHAR2(50);
  v_gintercompany  VARCHAR2(50);
  
BEGIN
  FOR rec IN c_child_asset_hdr
  LOOP
    v_segment1                        :=NULL;
    v_segment2                        :=NULL;
    v_segment3                        :=NULL;
    v_segment4                        :=NULL;
    v_segment5                        :=NULL;
    v_segment6                        :=NULL;
    v_status                          :='N';
    v_error_msg                       :=NULL;

    v_gcompany       				  :=NULL;
    v_glob	       		:=NULL;
    v_gcostcenter    	:=NULL;
    v_gaccount       	:=NULL;
    v_glocation      	:=NULL;
    v_gintercompany  	:=NULL;	
	
    IF rec.cost_clearing_account_seg1 IS NULL OR rec.cost_clearing_account_seg2 IS NULL OR rec.cost_clearing_account_seg3 IS NULL OR rec.cost_clearing_account_seg4 IS NULL OR rec.cost_clearing_account_seg5 IS NULL OR rec.cost_clearing_account_seg6 IS NULL THEN
      v_segment1                      :=gc_entity;
      v_segment2                      :=gc_lob;
      v_segment3                      :=gc_costcenter;
      v_segment4                      :=gc_account;
      v_segment5                      :=gc_location;
      v_segment6                      :=gc_ic;
      v_status                        :='C';
      -- v_error_msg                     :='CTU Mapping Failure';

	  OPEN c_gcc(rec.distribution_id,rec.asset_book);
	  FETCH c_gcc 
	   INTO v_gcompany,v_glob,v_gcostcenter,v_gaccount,v_glocation,v_gintercompany;
	  CLOSE c_gcc;
	  /*print_debug_msg ('Dist id :'||to_char(rec.distribution_id), true);
	  print_debug_msg ('Company  :'||v_gcompany, true);
	  print_debug_msg ('LOB      :'||v_glob, true);
	  print_debug_msg ('CC       :'||v_gcostcenter, true);
	  print_debug_msg ('Acct     :'||v_gaccount, true);
	  print_debug_msg ('Loc      :'||v_glocation, true);
	  print_debug_msg ('Interco  :'||v_gintercompany, true);	  
      */
      ctu_mapping_validation( 'ASSET_HDR', 
							   v_gcompany,
							   v_glob,
							   v_gcostcenter,
							   v_gaccount,
							   v_glocation,
							   v_gintercompany,
								rec.cost_clearing_account_seg1, 
								rec.cost_clearing_account_seg2, 
								rec.cost_clearing_account_seg3, 
								rec.cost_clearing_account_seg4, 
								rec.cost_clearing_account_seg5, 
								rec.cost_clearing_account_seg6, 
								rec.interface_line_number, 
								rec.asset_book, v_error_msg );
    ELSE
      v_segment1:=rec.cost_clearing_account_seg1;
      v_segment2:=rec.cost_clearing_account_seg2;
      v_segment3:=rec.cost_clearing_account_seg3;
      v_segment4:=rec.cost_clearing_account_seg4;
      v_segment5:=rec.cost_clearing_account_seg5;
      v_segment6:=rec.cost_clearing_account_seg6;
    END IF;
    BEGIN
      lv_XX_FA_CONV_ASSET_HDR                            :=NULL ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_id                   :=rec.Interface_Line_Number ;
      lv_XX_FA_CONV_ASSET_HDR.Book_type_code             :=rec.Asset_Book ;
      lv_XX_FA_CONV_ASSET_HDR.ASSET_ATTRIBUTE_CATEGORY   :='CHILD' ;
      lv_XX_FA_CONV_ASSET_HDR.Transaction_Name           :=rec.Transaction_Name ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_Number               :=rec.Asset_Number ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_Description          :=rec.Asset_Description ;
      lv_XX_FA_CONV_ASSET_HDR.Tag_Number                 :=rec.Tag_Number ;
      lv_XX_FA_CONV_ASSET_HDR.Manufacturer               :=rec.Manufacturer ;
      lv_XX_FA_CONV_ASSET_HDR.Serial_Number              :=rec.Serial_Number ;
      lv_XX_FA_CONV_ASSET_HDR.Model                      :=rec.Model ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_Type                 :=rec.Asset_Type ;
      lv_XX_FA_CONV_ASSET_HDR.Cost                       :=rec.Cost ;
      lv_XX_FA_CONV_ASSET_HDR.Date_Placed_in_Service     :=rec.Date_Placed_in_Service ;
      lv_XX_FA_CONV_ASSET_HDR.Prorate_Convention         :=rec.Prorate_Convention ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_Units                :=rec.Asset_Units ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_Category_Segment1    :=rec.Asset_Category_Segment1 ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_Category_Segment2    :=rec.Asset_Category_Segment2 ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_Category_Segment3    :=rec.Asset_Category_Segment3 ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_Category_Segment4    :=rec.Asset_Category_Segment4 ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_Category_Segment5    :=rec.Asset_Category_Segment5 ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_Category_Segment6    :=rec.Asset_Category_Segment6 ;
      lv_XX_FA_CONV_ASSET_HDR.Asset_Category_Segment7    :=rec.Asset_Category_Segment7 ;
      lv_XX_FA_CONV_ASSET_HDR.Parent_Asset               :=rec.Parent_Asset ;
      lv_XX_FA_CONV_ASSET_HDR.In_physical_inventory      :=rec.In_physical_inventory ;
      lv_XX_FA_CONV_ASSET_HDR.Property_Type              :=rec.Property_Type ;
      lv_XX_FA_CONV_ASSET_HDR.PROPERTY_CLASS             :=rec.PROPERTY_CLASS ;
      lv_XX_FA_CONV_ASSET_HDR.In_use                     :=rec.In_use ;
      lv_XX_FA_CONV_ASSET_HDR.Ownership                  :=rec.Ownership ;
      lv_XX_FA_CONV_ASSET_HDR.Bought                     :=rec.Bought ;
      lv_XX_FA_CONV_ASSET_HDR.COMMITMENT                 :=rec.COMMITMENT ;
      lv_XX_FA_CONV_ASSET_HDR.INVESTMENT_LAW             :=rec.INVESTMENT_LAW ;
      lv_XX_FA_CONV_ASSET_HDR.Amortize                   :=rec.Amortize ;
      lv_XX_FA_CONV_ASSET_HDR.Amortization_Start_Date    :=rec.Amortization_Start_Date ;
      lv_XX_FA_CONV_ASSET_HDR.Depreciate                 :=rec.Depreciate ;
      lv_XX_FA_CONV_ASSET_HDR.Salvage_Value_Type         :=rec.Salvage_Value_Type ;
      lv_XX_FA_CONV_ASSET_HDR.Salvage_Value_Amount       :=rec.Salvage_Value_Amount ;
      lv_XX_FA_CONV_ASSET_HDR.Salvage_Value_Percent      :=rec.Salvage_Value_Percent ;
      lv_XX_FA_CONV_ASSET_HDR.YTD_Depreciation           :=rec.YTD_Depreciation ;
      lv_XX_FA_CONV_ASSET_HDR.Depreciation_Reserve       :=rec.Depreciation_Reserve ;
      lv_XX_FA_CONV_ASSET_HDR.YTD_Bonus_Depreciation     :=rec.YTD_Bonus_Depreciation ;
      lv_XX_FA_CONV_ASSET_HDR.Bonus_Depreciation_Reserve :=rec.Bonus_Depreciation_Reserve ;
      lv_XX_FA_CONV_ASSET_HDR.YTD_IMPAIRMENT             :=rec.YTD_IMPAIRMENT ;
      lv_XX_FA_CONV_ASSET_HDR.IMPAIRMENT_RESERVE         :=rec.IMPAIRMENT_RESERVE ;
      lv_XX_FA_CONV_ASSET_HDR.Depreciation_Method        :=rec.Depreciation_Method ;
      lv_XX_FA_CONV_ASSET_HDR.LIFE_IN_MONTHS             :=rec.LIFE_IN_MONTHS ;
      lv_XX_FA_CONV_ASSET_HDR.BASIC_RATE                 :=rec.BASIC_RATE ;
      lv_XX_FA_CONV_ASSET_HDR.ADJUSTED_RATE              :=rec.ADJUSTED_RATE ;
      lv_XX_FA_CONV_ASSET_HDR.UNIT_OF_MEASURE            :=rec.UNIT_OF_MEASURE ;
      lv_XX_FA_CONV_ASSET_HDR.PRODUCTION_CAPACITY        :=rec.PRODUCTION_CAPACITY ;
      lv_XX_FA_CONV_ASSET_HDR.Ceiling_Type               :=rec.Ceiling_Type ;
      lv_XX_FA_CONV_ASSET_HDR.BONUS_RULE                 :=rec.BONUS_RULE ;
      lv_XX_FA_CONV_ASSET_HDR.Depreciation_Limit_Type    :=rec.Depreciation_Limit_Type ;
      lv_XX_FA_CONV_ASSET_HDR.Depreciation_Limit_Percent :=rec.Depreciation_Limit_Percent ;
      lv_XX_FA_CONV_ASSET_HDR.Depreciation_Limit_Amount  :=rec.Depreciation_Limit_Amount ;
      lv_XX_FA_CONV_ASSET_HDR.COST_CLEARING_ACCOUNT_SEG1 :=v_segment1;
      lv_XX_FA_CONV_ASSET_HDR.COST_CLEARING_ACCOUNT_SEG2 :=v_segment2 ;
      lv_XX_FA_CONV_ASSET_HDR.COST_CLEARING_ACCOUNT_SEG3 :=v_segment3 ;
      lv_XX_FA_CONV_ASSET_HDR.COST_CLEARING_ACCOUNT_SEG4 :=v_segment4 ;
      lv_XX_FA_CONV_ASSET_HDR.COST_CLEARING_ACCOUNT_SEG5 :=v_segment5 ;
      lv_XX_FA_CONV_ASSET_HDR.COST_CLEARING_ACCOUNT_SEG6 :=v_segment6 ;
      lv_XX_FA_CONV_ASSET_HDR.COST_CLEARING_ACCOUNT_SEG7 :=rec.COST_CLEARING_ACCOUNT_SEG7 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE1                 :=rec.ATTRIBUTE1 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE2                 :=rec.ATTRIBUTE2 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE3                 :=rec.ATTRIBUTE3 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE4                 :=rec.ATTRIBUTE4 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE5                 :=rec.ATTRIBUTE5 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE6                 :=rec.ATTRIBUTE6 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE7                 :=rec.ATTRIBUTE7 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE8                 :=rec.ATTRIBUTE8 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE9                 :=rec.ATTRIBUTE9 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE10                :=rec.ATTRIBUTE10 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE11                :=rec.ATTRIBUTE11 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE12                :=rec.ATTRIBUTE12 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE13                :=rec.ATTRIBUTE13 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE14                :=rec.ATTRIBUTE14 ;
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE15                :=rec.ATTRIBUTE15 ;	  
      lv_XX_FA_CONV_ASSET_HDR.ATTRIBUTE_CATEGORY_CODE    :=rec.ATTRIBUTE_CATEGORY_CODE ;
      lv_XX_FA_CONV_ASSET_HDR.NBV_at_the_Time_of_Switch  :=rec.NBV_at_the_Time_of_Switch ;
      lv_XX_FA_CONV_ASSET_HDR.Earlier_Dep_Limit_Type     :=rec.Earlier_Dep_Limit_Type ;
      lv_XX_FA_CONV_ASSET_HDR.Earlier_Dep_Limit_Percent  :=rec.Earlier_Dep_Limit_Percent ;
      lv_XX_FA_CONV_ASSET_HDR.Earlier_Dep_Limit_Amount   :=rec.Earlier_Dep_Limit_Amount ;
      lv_XX_FA_CONV_ASSET_HDR.Earlier_Life_in_Months     :=rec.Earlier_Life_in_Months ;
      lv_XX_FA_CONV_ASSET_HDR.Earlier_Basic_Rate         :=rec.Earlier_Basic_Rate ;
      lv_XX_FA_CONV_ASSET_HDR.EARLIER_ADJUSTED_RATE      :=rec.EARLIER_ADJUSTED_RATE ;
      lv_XX_FA_CONV_ASSET_HDR.REQUEST_ID                 :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
      lv_XX_FA_CONV_ASSET_HDR.CREATED_BY                 :=NVL(FND_GLOBAL.USER_ID,         -1);
      lv_XX_FA_CONV_ASSET_HDR.CREATION_DATE              :=SYSDATE;
      lv_XX_FA_CONV_ASSET_HDR.LAST_UPDATED_BY            :=NVL(FND_GLOBAL.USER_ID,   -1);
      lv_XX_FA_CONV_ASSET_HDR.LAST_UPDATE_LOGIN          :=NVL(FND_GLOBAL.LOGIN_ID , -1);
      lv_XX_FA_CONV_ASSET_HDR.LAST_UPDATE_DATE           := SYSDATE;
      lv_XX_FA_CONV_ASSET_HDR.STATUS                     :=v_status;
      lv_XX_FA_CONV_ASSET_HDR.ERROR_DESCRIPTION          :=v_error_msg;
      INSERT INTO XX_FA_CONV_ASSET_HDR VALUES lv_XX_FA_CONV_ASSET_HDR;
      v_rec_count    :=v_rec_count    +1;
      v_success_count:=v_success_count+1;
    EXCEPTION
    WHEN OTHERS THEN
      lc_errormsg := 'In Procedure generic_child_assets_hdr.Error to insert into XX_FA_CONV_ASSET_HDR for Asset Id:'||rec.Interface_Line_Number || '. SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE ;
      print_debug_msg (lc_errormsg, true);
      v_failure_count:=v_failure_count+1;
    END;
    IF v_rec_count>5000 THEN
      COMMIT;
      v_rec_count:=0;
    END IF;
  END LOOP;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in generic_child_assets_hdr procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
END generic_child_assets_hdr;
PROCEDURE generic_file_extract_asset_hdr
  (
    p_book_type_code VARCHAR2,
    p_record_type    VARCHAR2
  )
AS
  CURSOR cr_asset_hdr_extract_file
  IS
    SELECT
      /*+ parallel(8) */
      asset_id interface_line_number,
      book_type_code asset_book,
      Transaction_Name,
      Asset_Number,
      Asset_Description ,
      Tag_Number,
      Manufacturer,
      Serial_Number,
      Model ,
      Asset_Type,
      Cost,
      Date_Placed_in_Service,
      Prorate_Convention,
      Asset_Units,
      Asset_Category_Segment1,
      Asset_Category_Segment2,
      Asset_Category_Segment3,
      Asset_Category_Segment4,
      Asset_Category_Segment5,
      Asset_Category_Segment6,
      Asset_Category_Segment7,
      'POST' Posting_Status,
      'NEW' Queue_Name,
      'ORACLE FBDI' Feeder_System,
      Parent_Asset,
      NULL Add_to_Asset,
      NULL Asset_Key_Segment1,
      NULL Asset_Key_Segment2,
      NULL Asset_Key_Segment3,
      NULL Asset_Key_Segment4,
      NULL Asset_Key_Segment5,
      NULL Asset_Key_Segment6,
      NULL Asset_Key_Segment7,
      NULL Asset_Key_Segment8,
      NULL Asset_Key_Segment9,
      NULL Asset_Key_Segment10,
      In_physical_inventory,
      Property_Type,
      PROPERTY_CLASS,
      In_use,
      Ownership,
      Bought,
      NULL MATERIAL_INDICATOR,
      COMMITMENT ,
      INVESTMENT_LAW,
      Amortize,
      Amortization_Start_Date,
      Depreciate,
      Salvage_Value_Type,
      Salvage_Value_Amount,
      Salvage_Value_Percent,
      YTD_Depreciation,
      Depreciation_Reserve,
      YTD_Bonus_Depreciation,
      Bonus_Depreciation_Reserve,
      YTD_IMPAIRMENT ,
      IMPAIRMENT_RESERVE ,
      Depreciation_Method ,
      LIFE_IN_MONTHS ,
      BASIC_RATE ,
      ADJUSTED_RATE ,
      UNIT_OF_MEASURE ,
      PRODUCTION_CAPACITY ,
      Ceiling_Type,
      BONUS_RULE ,
      NULL CASH_GENERATING_UNIT ,
      Depreciation_Limit_Type,
      Depreciation_Limit_Percent,
      Depreciation_Limit_Amount,
      NULL INVOICE_COST,
      COST_CLEARING_ACCOUNT_SEG1,
      COST_CLEARING_ACCOUNT_SEG2,
      COST_CLEARING_ACCOUNT_SEG3,
      COST_CLEARING_ACCOUNT_SEG4,
      COST_CLEARING_ACCOUNT_SEG5,
      COST_CLEARING_ACCOUNT_SEG6,
      COST_CLEARING_ACCOUNT_SEG7,
      NULL Cost_Clearing_Account_Seg8,
      NULL Cost_Clearing_Account_Seg9,
      NULL COST_CLEARING_ACCOUNT_SEG10,
      NULL Cost_Clearing_Account_Seg11,
      NULL Cost_Clearing_Account_Seg12,
      NULL Cost_Clearing_Account_Seg13,
      NULL Cost_Clearing_Account_Seg14,
      NULL COST_CLEARING_ACCOUNT_SEG15,
      ATTRIBUTE1,
      ATTRIBUTE2,
      ATTRIBUTE3,
      ATTRIBUTE4,
      ATTRIBUTE5,
      ATTRIBUTE6,
      ATTRIBUTE7,
      ATTRIBUTE8,
      ATTRIBUTE9,
      ATTRIBUTE10,
      ATTRIBUTE11,
      ATTRIBUTE12,
      ATTRIBUTE13,
      ATTRIBUTE14,
      ATTRIBUTE15,
      ATTRIBUTE_CATEGORY_CODE,
      NULL context,
      NULL Mass_Property_Eligible,
      NULL Group_Asset,
      NULL Reduction_Rate,
      NULL Apply_Reduction_Rate_to_Addi,
      NULL Apply_Reduction_Rate_to_Adj,
      NULL Apply_Reduction_Rate_to_Reti,
      NULL Recognize_Gain_or_Loss,
      NULL Recapture_Excess_Reserve,
      NULL Limit_Net_Proceeds_to_Cost,
      NULL Terminal_Gain_or_Loss,
      NULL Tracking_Method,
      NULL Allocate_Excess_Depreciation,
      NULL Depreciate_By,
      NULL Member_Rollup,
      NULL Allo_to_Full_Reti_and_Res_Asst,
      NULL Over_Depreciate,
      NULL PREPARER,
      NULL Sum_Merged_Units,
      NULL New_Master,
      NULL Units_to_Adjust,
      NULL Short_year,
      NULL Conversion_Date,
      NULL ORIGINAL_DEP_START_DATE,
      NBV_at_the_Time_of_Switch,
      NULL Period_Fully_Reserved,
      NULL Start_Period_of_Extended_Dep,
      Earlier_Dep_Limit_Type,
      Earlier_Dep_Limit_Percent,
      Earlier_Dep_Limit_Amount,
      NULL Earlier_Depreciation_Method ,
      Earlier_Life_in_Months,
      Earlier_Basic_Rate,
      EARLIER_ADJUSTED_RATE,
      NULL Lease_Number,
      NULL Revaluation_Reserve,
      NULL Revaluation_Loss,
      NULL Reval_Reser_Amortization_Basis,
      NULL Impairment_Loss_Expense,
      NULL Revaluation_Cost_Ceiling,
      NULL FAIR_VALUE,
      NULL LAST_USED_PRICE_INDEX_VALUE,
      NULL Supplier_Name,
      NULL Supplier_Number,
      NULL Purchase_Order_Number,
      NULL Invoice_Number,
      NULL Invoice_Voucher_Number,
      NULL Invoice_Date,
      NULL Payables_Units,
      NULL Invoice_Line_Number,
      NULL Invoice_Line_Type,
      NULL Invoice_Line_Description,
      NULL Invoice_Payment_Number,
      NULL Project_Number,
      NULL Task_Number,
      NULL FULLY_DEPRECIATE
    FROM
      (SELECT *
      FROM xx_fa_conv_asset_hdr
      WHERE book_type_code        =p_book_type_code
      AND asset_attribute_category=p_record_type
      and status in ('N','C')
      )
  ORDER BY asset_id;
  lv_xx_fa_conv_asset_hdr xx_fa_conv_asset_hdr%ROWTYPE;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  ---l_file_path   VARCHAR(200);
  l_file_name      VARCHAR2(500);
  lv_col_title     VARCHAR2(5000);
  l_file_path      VARCHAR2(500):='XXFIN_OUTBOUND';---/app/ebs/ctgsidev02/xxfin/outbound
  lc_errormsg      VARCHAR2(1000);                ----            VARCHAR2(1000) := NULL;
  v_book_type_code VARCHAR2(100);
  ---------------------------
  v_segment1      VARCHAR2(50);
  v_segment2      VARCHAR2(50);
  v_segment3      VARCHAR2(50);
  v_segment4      VARCHAR2(50);
  v_segment5      VARCHAR2(50);
  v_segment6      VARCHAR2(50);
  v_segment7      VARCHAR2(50);
  v_rec_count     NUMBER:=0;
  v_success_count NUMBER:=0;
  v_failure_count NUMBER:=0;
BEGIN
  BEGIN
    SELECT directory_path
    INTO l_file_path
    FROM dba_directories
    WHERE directory_name = 'XXFIN_OUTBOUND';
  EXCEPTION
  WHEN OTHERS THEN
    l_file_path := NULL;
  END;
  print_debug_msg ('Package generic_file_extract_asset_hdr START ', TRUE);
  print_debug_msg ('P_BOOK_TYPE_CODE '||p_book_type_code, TRUE);
  v_book_type_code :=REPLACE(REPLACE (REPLACE(p_book_type_code,'OD US ','US_'),'OD CA ','CA_'),' ','_');
  l_file_name      := p_record_type||'_'||v_book_type_code||'_HDR_'||TO_CHAR(sysdate,'DDMONYYYYHH24MISS')||'.csv';
  lc_file_handle   := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title     :='INTERFACE_LINE_NUMBER'|| ','|| 'ASSET_BOOK'|| ','|| 'TRANSACTION_NAME'|| ','|| 'ASSET_NUMBER'|| ','|| 'ASSET_DESCRIPTION'|| ','|| 'TAG_NUMBER'|| ','|| 'MANUFACTURER'|| ','|| 'SERIAL_NUMBER'|| ','|| 'MODEL'|| ','|| 'ASSET_TYPE'|| ','|| 'COST'|| ','|| 'DATE_PLACED_IN_SERVICE'|| ','|| 'PRORATE_CONVENTION'|| ','|| 'ASSET_UNITS'|| ','|| 'ASSET_CATEGORY_SEGMENT1'|| ','|| 'ASSET_CATEGORY_SEGMENT2'|| ','|| 'ASSET_CATEGORY_SEGMENT3'|| ','|| 'ASSET_CATEGORY_SEGMENT4'|| ','|| 'ASSET_CATEGORY_SEGMENT5'|| ','|| 'ASSET_CATEGORY_SEGMENT6'|| ','|| 'ASSET_CATEGORY_SEGMENT7'|| ','|| 'POSTING_STATUS'|| ','|| 'QUEUE_NAME'|| ','|| 'FEEDER_SYSTEM'|| ','|| 'PARENT_ASSET'|| ','|| 'ADD_TO_ASSET'|| ','|| 'ASSET_KEY_SEGMENT1'|| ','|| 'ASSET_KEY_SEGMENT2'|| ','|| 'ASSET_KEY_SEGMENT3'|| ','|| 'ASSET_KEY_SEGMENT4'|| ','|| 'ASSET_KEY_SEGMENT5'|| ','|| 'ASSET_KEY_SEGMENT6'|| ','|| 'ASSET_KEY_SEGMENT7'|| ','|| 'ASSET_KEY_SEGMENT8'|| ','|| 'ASSET_KEY_SEGMENT9'|| ','|| 'ASSET_KEY_SEGMENT10'|| ','
  || 'IN_PHYSICAL_INVENTORY'|| ','|| 'PROPERTY_TYPE'|| ','|| 'PROPERTY_CLASS'|| ','|| 'IN_USE'|| ','|| 'OWNERSHIP'|| ','|| 'BOUGHT'|| ','|| 'MATERIAL_INDICATOR'|| ','|| 'COMMITMENT'|| ','|| 'INVESTMENT_LAW'|| ','|| 'AMORTIZE'|| ','|| 'AMORTIZATION_START_DATE'|| ','|| 'DEPRECIATE'|| ','|| 'SALVAGE_VALUE_TYPE'|| ','|| 'SALVAGE_VALUE_AMOUNT'|| ','|| 'SALVAGE_VALUE_PERCENT'|| ','|| 'YTD_DEPRECIATION'|| ','|| 'DEPRECIATION_RESERVE'|| ','|| 'YTD_BONUS_DEPRECIATION'|| ','|| 'BONUS_DEPRECIATION_RESERVE'|| ','|| 'YTD_IMPAIRMENT'|| ','|| 'IMPAIRMENT_RESERVE'|| ','|| 'DEPRECIATION_METHOD'|| ','|| 'LIFE_IN_MONTHS'|| ','|| 'BASIC_RATE'|| ','|| 'ADJUSTED_RATE'|| ','|| 'UNIT_OF_MEASURE'|| ','|| 'PRODUCTION_CAPACITY'|| ','|| 'CEILING_TYPE'|| ','|| 'BONUS_RULE'|| ','|| 'CASH_GENERATING_UNIT'|| ','|| 'DEPRECIATION_LIMIT_TYPE'|| ','|| 'DEPRECIATION_LIMIT_PERCENT'|| ','|| 'DEPRECIATION_LIMIT_AMOUNT'|| ','|| 'INVOICE_COST'|| ','|| 'COST_CLEARING_ACCOUNT_SEG1'|| ','|| 'COST_CLEARING_ACCOUNT_SEG2'|| ','||
  'COST_CLEARING_ACCOUNT_SEG3'|| ','|| 'COST_CLEARING_ACCOUNT_SEG4'|| ','|| 'COST_CLEARING_ACCOUNT_SEG5'|| ','|| 'COST_CLEARING_ACCOUNT_SEG6'|| ','|| 'COST_CLEARING_ACCOUNT_SEG7'|| ','|| 'COST_CLEARING_ACCOUNT_SEG8'|| ','|| 'COST_CLEARING_ACCOUNT_SEG9'|| ','|| 'COST_CLEARING_ACCOUNT_SEG10'|| ','|| 'COST_CLEARING_ACCOUNT_SEG11'|| ','|| 'COST_CLEARING_ACCOUNT_SEG12'|| ','|| 'COST_CLEARING_ACCOUNT_SEG13'|| ','|| 'COST_CLEARING_ACCOUNT_SEG14'|| ','|| 'COST_CLEARING_ACCOUNT_SEG15'|| ','|| 'ATTRIBUTE1'|| ','|| 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','|| 'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'|| ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10'|| ','|| 'ATTRIBUTE11'|| ','|| 'ATTRIBUTE12'|| ','|| 'ATTRIBUTE13'|| ','|| 'ATTRIBUTE14'|| ','|| 'ATTRIBUTE15'|| ','|| 'ATTRIBUTE_CATEGORY_CODE'|| ','|| 'CONTEXT'|| ','|| 'MASS_PROPERTY_ELIGIBLE'|| ','|| 'GROUP_ASSET'|| ','|| 'REDUCTION_RATE'|| ','|| 'APPLY_REDUCTION_RATE_TO_ADDI'|| ','||
  'APPLY_REDUCTION_RATE_TO_ADJ'|| ','|| 'APPLY_REDUCTION_RATE_TO_RETI'|| ','|| 'RECOGNIZE_GAIN_OR_LOSS'|| ','|| 'RECAPTURE_EXCESS_RESERVE'|| ','|| 'LIMIT_NET_PROCEEDS_TO_COST'|| ','|| 'TERMINAL_GAIN_OR_LOSS'|| ','|| 'TRACKING_METHOD'|| ','|| 'ALLOCATE_EXCESS_DEPRECIATION'|| ','|| 'DEPRECIATE_BY'|| ','|| 'MEMBER_ROLLUP'|| ','|| 'ALLO_TO_FULL_RETI_AND_RES_ASST'|| ','|| 'OVER_DEPRECIATE'|| ','|| 'PREPARER'|| ','|| 'SUM_MERGED_UNITS'|| ','|| 'NEW_MASTER'|| ','|| 'UNITS_TO_ADJUST'|| ','|| 'SHORT_YEAR'|| ','|| 'CONVERSION_DATE'|| ','|| 'ORIGINAL_DEP_START_DATE'|| ','|| 'NBV_AT_THE_TIME_OF_SWITCH'|| ','|| 'PERIOD_FULLY_RESERVED'|| ','|| 'START_PERIOD_OF_EXTENDED_DEP'|| ','|| 'EARLIER_DEP_LIMIT_TYPE'|| ','|| 'EARLIER_DEP_LIMIT_PERCENT'|| ','|| 'EARLIER_DEP_LIMIT_AMOUNT'|| ','|| 'EARLIER_DEPRECIATION_METHOD'|| ','|| 'EARLIER_LIFE_IN_MONTHS'|| ','|| 'EARLIER_BASIC_RATE'|| ','|| 'EARLIER_ADJUSTED_RATE'|| ','|| 'LEASE_NUMBER'|| ','|| 'REVALUATION_RESERVE'|| ','|| 'REVALUATION_LOSS'|| ','||
  'REVAL_RESER_AMORTIZATION_BASIS'|| ','|| 'IMPAIRMENT_LOSS_EXPENSE'|| ','|| 'REVALUATION_COST_CEILING'|| ','|| 'FAIR_VALUE'|| ','|| 'LAST_USED_PRICE_INDEX_VALUE'|| ','|| 'SUPPLIER_NAME'|| ','|| 'SUPPLIER_NUMBER'|| ','|| 'PURCHASE_ORDER_NUMBER'|| ','|| 'INVOICE_NUMBER'|| ','|| 'INVOICE_VOUCHER_NUMBER'|| ','|| 'INVOICE_DATE'|| ','|| 'PAYABLES_UNITS'|| ','|| 'INVOICE_LINE_NUMBER'|| ','|| 'INVOICE_LINE_TYPE'|| ','|| 'INVOICE_LINE_DESCRIPTION'|| ','|| 'INVOICE_PAYMENT_NUMBER'|| ','|| 'PROJECT_NUMBER'|| ','|| 'TASK_NUMBER'|| ','|| 'FULLY_DEPRECIATE';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN cr_asset_hdr_extract_file
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,'"'||i.interface_line_number|| '","'|| i.asset_book|| '","'|| i.transaction_name|| '","'|| i.asset_number|| '","'|| i.asset_description|| '","'|| i.tag_number|| '","'|| i.manufacturer|| '","'|| i.serial_number|| '","'|| i.model|| '","'|| i.asset_type|| '","'|| i.cost|| '","'|| i.date_placed_in_service|| '","'|| i.prorate_convention|| '","'|| i.asset_units|| '","'|| i.asset_category_segment1|| '","'|| i.asset_category_segment2|| '","'|| i.asset_category_segment3|| '","'|| i.asset_category_segment4|| '","'|| i.asset_category_segment5|| '","'|| i.asset_category_segment6|| '","'|| i.asset_category_segment7|| '","'|| i.posting_status|| '","'|| i.queue_name|| '","'|| i.feeder_system|| '","'|| i.parent_asset|| '","'|| i.add_to_asset|| '","'|| i.asset_key_segment1|| '","'|| i.asset_key_segment2|| '","'|| i.asset_key_segment3|| '","'|| i.asset_key_segment4|| '","'|| i.asset_key_segment5|| '","'|| i.asset_key_segment6|| '","'|| i.asset_key_segment7|| '","'|| i.asset_key_segment8|| '","'|| i.asset_key_segment9|| '","'||
    i.asset_key_segment10|| '","'|| i.in_physical_inventory|| '","'|| i.property_type|| '","'|| i.property_class|| '","'|| i.in_use|| '","'|| i.ownership|| '","'|| i.bought|| '","'|| i.material_indicator|| '","'|| i.commitment|| '","'|| i.investment_law|| '","'|| i.amortize|| '","'|| i.amortization_start_date|| '","'|| i.depreciate|| '","'|| i.salvage_value_type|| '","'|| i.salvage_value_amount|| '","'|| i.salvage_value_percent|| '","'|| i.ytd_depreciation|| '","'|| i.depreciation_reserve|| '","'|| i.ytd_bonus_depreciation|| '","'|| i.bonus_depreciation_reserve|| '","'|| i.ytd_impairment|| '","'|| i.impairment_reserve|| '","'|| i.depreciation_method|| '","'|| i.life_in_months|| '","'|| i.basic_rate|| '","'|| i.adjusted_rate|| '","'|| i.unit_of_measure|| '","'|| i.production_capacity|| '","'|| i.ceiling_type|| '","'|| i.bonus_rule|| '","'|| i.cash_generating_unit|| '","'|| i.depreciation_limit_type|| '","'|| i.depreciation_limit_percent|| '","'|| i.depreciation_limit_amount|| '","'|| i.invoice_cost|| '","'|| i.cost_clearing_account_seg1|| '","'||
    i.cost_clearing_account_seg2|| '","'|| i.cost_clearing_account_seg3|| '","'|| i.cost_clearing_account_seg4|| '","'|| i.cost_clearing_account_seg5|| '","'|| i.cost_clearing_account_seg6|| '","'|| i.cost_clearing_account_seg7|| '","'|| i.cost_clearing_account_seg8|| '","'|| i.cost_clearing_account_seg9|| '","'|| i.cost_clearing_account_seg10|| '","'|| i.cost_clearing_account_seg11|| '","'|| i.cost_clearing_account_seg12|| '","'|| i.cost_clearing_account_seg13|| '","'|| i.cost_clearing_account_seg14|| '","'|| i.cost_clearing_account_seg15|| '","'|| 
	replace(i.attribute1,chr(34),null)|| '","'|| replace(i.attribute2,chr(34),null)|| '","'||
	replace(i.attribute3,chr(34),null)|| '","'||
	replace(i.attribute4,chr(34),null)|| '","'|| replace(i.attribute5,chr(34),null)|| '","'||
	replace(i.attribute6,chr(34),null)|| '","'||
	replace(i.attribute7,chr(34),null)|| '","'||
	replace(i.attribute8,chr(34),null)|| '","'|| 
	replace(i.attribute9,chr(34),null)||
	'","'|| replace(i.attribute10,chr(34),null)|| '","'|| replace(i.attribute11,chr(34),null)|| '","'||
	replace(i.attribute12,chr(34),null)|| '","'|| replace(i.attribute13,chr(34),null)|| '","'|| 
	replace(i.attribute14,chr(34),null)||
	'","'|| replace(i.attribute15,chr(34),null)|| '","'||
	i.attribute_category_code|| '","'|| i.context|| '","'|| i.mass_property_eligible|| '","'|| i.group_asset|| '","'|| i.reduction_rate|| '","'||
    i.apply_reduction_rate_to_addi|| '","'|| i.apply_reduction_rate_to_adj|| '","'|| i.apply_reduction_rate_to_reti|| '","'|| i.recognize_gain_or_loss|| '","'|| i.recapture_excess_reserve|| '","'|| i.limit_net_proceeds_to_cost|| '","'|| i.terminal_gain_or_loss|| '","'|| i.tracking_method|| '","'|| i.allocate_excess_depreciation|| '","'|| i.depreciate_by|| '","'|| i.member_rollup|| '","'|| i.allo_to_full_reti_and_res_asst|| '","'|| i.over_depreciate|| '","'|| i.preparer|| '","'|| i.sum_merged_units|| '","'|| i.new_master|| '","'|| i.units_to_adjust|| '","'|| i.short_year|| '","'|| i.conversion_date|| '","'|| i.original_dep_start_date|| '","'|| i.nbv_at_the_time_of_switch|| '","'|| i.period_fully_reserved|| '","'|| i.start_period_of_extended_dep|| '","'|| i.earlier_dep_limit_type|| '","'|| i.earlier_dep_limit_percent|| '","'|| i.earlier_dep_limit_amount|| '","'|| i.earlier_depreciation_method|| '","'|| i.earlier_life_in_months|| '","'|| i.earlier_basic_rate|| '","'|| i.earlier_adjusted_rate|| '","'|| i.lease_number|| '","'|| i.revaluation_reserve
    || '","'|| i.revaluation_loss|| '","'|| i.reval_reser_amortization_basis|| '","'|| i.impairment_loss_expense|| '","'|| i.revaluation_cost_ceiling|| '","'|| i.fair_value|| '","'|| i.last_used_price_index_value|| '","'|| i.supplier_name|| '","'|| i.supplier_number|| '","'|| i.purchase_order_number|| '","'|| i.invoice_number|| '","'|| i.invoice_voucher_number|| '","'|| i.invoice_date|| '","'|| i.payables_units|| '","'|| i.invoice_line_number|| '","'|| i.invoice_line_type|| '","'|| i.invoice_line_description|| '","'|| i.invoice_payment_number|| '","'|| i.project_number|| '","'|| i.task_number|| '","'|| i.fully_depreciate||'"');
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in generic_file_extract_asset_hdr procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END generic_file_extract_asset_hdr;
PROCEDURE generic_parent_distribution(
    p_book_type_code VARCHAR2)
IS
  CURSOR c_parent_dist
  IS
    SELECT
      /*+ parallel(8) */
      interface_line_number,
      units_assigned,
      employee_email_address,
      asset_location_segment1,
      asset_location_segment2,
      asset_location_segment3,
      asset_location_segment4,
      asset_location_segment6 asset_location_segment5,
      SUBSTR(asset_location_segment5,2) asset_location_segment6,
      asset_location_segment7,
	  gcompany,
		glob,
		gcostcenter,
		gaccount,
		glocation,
		gintercompany,	  
      exp_acct_segment1
      ||'.'
      || exp_acct_segment6
      ||'.'
      || exp_acct_segment2
      ||'.'
      || exp_acct_segment3
      ||'.'
      || exp_acct_segment4
      ||'.'
      || exp_acct_segment5 expense_account_segment,
      exp_acct_segment1,
      exp_acct_segment2,
      exp_acct_segment3,
      exp_acct_segment4,
      exp_acct_segment5,
      exp_acct_segment6,
      code_combination_id
    FROM
      (SELECT
        /*+ full(ds) full(fth) */
        fb.asset_id interface_line_number,
        fd.units_assigned units_assigned,
        NULL employee_email_address,
        loc.segment1 asset_location_segment1,
        loc.segment2 asset_location_segment2,
        loc.segment3 asset_location_segment3,
        loc.segment4 asset_location_segment4,
        loc.segment5 asset_location_segment5,
        loc.segment6 asset_location_segment6,
        loc.segment7 asset_location_segment7,
		gcc.segment1 gcompany,
		gcc.segment6 glob,
		gcc.segment2 gcostcenter,
		gcc.segment3 gaccount,
		gcc.segment4 glocation,
		gcc.segment5 gintercompany,
        xx_gl_beacon_mapping_f1(gcc.segment1,'ENTITY','A') exp_acct_segment1,
        xx_gl_beacon_mapping_f1(gcc.segment2,'COST_CENTER','A') exp_acct_segment2,
        xx_gl_beacon_mapping_f1(gcc.segment3,'ACCOUNT','A') exp_acct_segment3,
        xx_gl_beacon_mapping_f1(gcc.segment4,'LOCATION','A') exp_acct_segment4,
        xx_gl_beacon_mapping_f1(gcc.segment5,'ENTITY','A') exp_acct_segment5,
        xx_gl_beacon_mapping_f1(gcc.segment6,'LOB','A') exp_acct_segment6, 
        gcc.segment7 exp_acct_segment7,
        gcc.segment8 exp_acct_segment8,
        gcc.segment9 exp_acct_segment9,
        gcc.segment10 exp_acct_segment10,
        gcc.segment11 exp_acct_segment11,
        gcc.segment12 exp_acct_segment12,
        gcc.segment13 exp_acct_segment13,
        gcc.segment14 exp_acct_segment14,
        gcc.segment15 exp_acct_segment15,
        gcc.segment16 exp_acct_segment16,
        gcc.segment17 exp_acct_segment17,
        gcc.segment18 exp_acct_segment18,
        gcc.segment19 exp_acct_segment19,
        gcc.segment20 exp_acct_segment20,
        gcc.segment21 exp_acct_segment21,
        gcc.segment22 exp_acct_segment22,
        gcc.segment23 exp_acct_segment23,
        gcc.segment24 exp_acct_segment24,
        gcc.segment25 exp_acct_segment25,
        gcc.segment26 exp_acct_segment26,
        gcc.segment27 exp_acct_segment27,
        gcc.segment28 exp_acct_segment28,
        gcc.segment29 exp_acct_segment29,
        gcc.segment30 exp_acct_segment30,
        gcc.code_combination_id
      FROM fa_transaction_headers fth,
        fa_deprn_summary ds,
        fa_categories_b fcb,
        gl_code_combinations gcc,
        fa_locations loc,
        fa_distribution_history fd,
        fa_books fb,
        xx_fa_status xfs,
        fa_book_controls corpbook,
        fa_additions_b fab
      WHERE 1                =1
      AND xfs.book_type_code =p_book_type_code
      AND xfs.ASSET_STATUS   ='ACTIVE'
      AND corpbook.book_type_code=xfs.book_type_code
      AND corpbook.BOOK_CLASS    = 'CORPORATE'
      AND fab.asset_id           =xfs.asset_id
      AND fab.parent_asset_id   IS NULL
      AND EXISTS
        (SELECT 'x' FROM fa_additions_b WHERE parent_asset_id = fab.ASSET_ID
        )
    AND fb.book_type_code=xfs.book_type_code
    AND fb.asset_id      = xfs.asset_id
    AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
    AND fd.asset_id          =fb.asset_id
    AND fd.date_ineffective IS NULL
    AND fd.book_type_code    ='OD US CORP'
    AND TRUNC (sysdate) BETWEEN TRUNC (NVL (fd.date_effective, sysdate)) AND TRUNC (NVL (fd.date_ineffective, sysdate))
    AND fb.date_ineffective IS NULL
	AND loc.location_id           =fd.location_id
    AND gcc.code_combination_id   = fd.code_combination_id
    AND fcb.category_id           =fab.asset_category_id
    AND fth.ASSET_ID              = fab.ASSET_ID
    AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
    AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
    AND ds.asset_id               =fb.asset_id
    AND ds.book_type_code         =fb.book_type_code
    AND DS.PERIOD_COUNTER         =
      (SELECT MAX(DS1.PERIOD_COUNTER)
      FROM fa_deprn_summary ds1
      WHERE DS1.ASSET_ID     =DS.ASSET_ID
      AND DS1.BOOK_TYPE_CODE = DS.BOOK_TYPE_CODE
      )
      )
    ORDER BY Interface_Line_Number;
    lc_file_handle utl_file.file_type;
    l_file_name     VARCHAR2(500);
    lv_col_title    VARCHAR2(5000);
    l_file_path     VARCHAR2(500):='XXFIN_OUTBOUND';
    lc_errormsg     VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
    lv_line_count   NUMBER;
    v_rec_count     NUMBER:=0;
    v_success_count NUMBER:=0;
    v_failure_count NUMBER:=0;
    lc_coa          VARCHAR2(50);
    v_status        VARCHAR2(1);
    v_error_msg     VARCHAR2(100);
    lv_xx_fa_conv_asset_dtl xx_fa_conv_asset_dtl%ROWTYPE;
  BEGIN
    FOR rec IN c_parent_dist
    LOOP
      lc_coa                   :=NULL;
      v_status                 :='N';
      v_error_msg              :=NULL;
      IF rec.exp_acct_segment1 IS NULL OR rec.exp_acct_segment2 IS NULL OR rec.exp_acct_segment3 IS NULL OR rec.exp_acct_segment4 IS NULL OR rec.exp_acct_segment5 IS NULL OR rec.exp_acct_segment6 IS NULL THEN
        lc_coa                 :=gc_entity||'.'||gc_lob||'.'||gc_costcenter||'.'||gc_account||'.'||gc_location||'.'||gc_ic;
        v_status               :='C';
        --v_error_msg            :='CTU Mapping Failure';
        ctu_mapping_validation( 'ASSET_DISTR', 
								 rec.gcompany,
								 rec.glob,
								 rec.gcostcenter,
								 rec.gaccount,
								 rec.glocation,
								 rec.gintercompany,
								 rec.exp_acct_segment1, 
								 rec.exp_acct_segment6, 
								 rec.exp_acct_segment2, 
								 rec.exp_acct_segment3, 
								 rec.exp_acct_segment4, 
								 rec.exp_acct_segment5, 
								 rec.interface_line_number, 
								 p_book_type_code, 
								 v_error_msg );
      ELSE
        lc_coa:=rec.expense_account_segment;
      END IF;
      BEGIN
        lv_xx_fa_conv_asset_dtl                          :=NULL ;
        lv_xx_fa_conv_asset_dtl.asset_id                 :=rec.interface_line_number ;
        lv_xx_fa_conv_asset_dtl.book_type_code           :=p_book_type_code ;
        lv_xx_fa_conv_asset_dtl.asset_attribute_category :='PARENT' ;
        lv_xx_fa_conv_asset_dtl.units_assigned           :=rec.units_assigned ;
        lv_xx_fa_conv_asset_dtl.employee_email_address   :=rec.employee_email_address ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment1  :=rec.asset_location_segment1 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment2  :=rec.asset_location_segment2 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment3  :=rec.asset_location_segment3 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment4  :=rec.asset_location_segment4 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment5  :=rec.asset_location_segment5 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment6  :=rec.asset_location_segment6 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment7  :=rec.asset_location_segment7 ;
        lv_xx_fa_conv_asset_dtl.expense_account_segment  :=lc_coa ;
        lv_xx_fa_conv_asset_dtl.request_id               :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
        lv_xx_fa_conv_asset_dtl.created_by               :=NVL(FND_GLOBAL.USER_ID,         -1);
        lv_xx_fa_conv_asset_dtl.creation_date            :=SYSDATE;
        lv_xx_fa_conv_asset_dtl.last_updated_by          :=NVL(FND_GLOBAL.USER_ID,   -1);
        lv_xx_fa_conv_asset_dtl.last_update_login        :=NVL(FND_GLOBAL.LOGIN_ID , -1);
        lv_xx_fa_conv_asset_dtl.last_update_date         := SYSDATE;
        lv_xx_fa_conv_asset_dtl.status                   :=v_status ;
        lv_xx_fa_conv_asset_dtl.error_description        :=v_error_msg;
        INSERT INTO xx_fa_conv_asset_dtl VALUES lv_xx_fa_conv_asset_dtl;
        v_rec_count    :=v_rec_count    +1;
        v_success_count:=v_success_count+1;
      EXCEPTION
      WHEN OTHERS THEN
        lc_errormsg := 'In Procedure generic_parent_distribution.Error to insert into XX_FA_CONV_ASSET_DTL for Asset Id:'||rec.Interface_Line_Number || '. SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE ;
        print_debug_msg (lc_errormsg, true);
        v_failure_count:=v_failure_count+1;
      END;
      IF v_rec_count>5000 THEN
        COMMIT;
        v_rec_count:=0;
      END IF;
    END LOOP;
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in generic_parent_distribution procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
  END generic_parent_distribution;
PROCEDURE generic_child_distribution
  (
    p_book_type_code VARCHAR2
  )
IS
  CURSOR c_child_dist
  IS
    SELECT
      /*+ parallel(8) */
      interface_line_number,
      units_assigned,
      employee_email_address,
      asset_location_segment1,
      asset_location_segment2,
      asset_location_segment3,
      asset_location_segment4,
      asset_location_segment6 asset_location_segment5,
      SUBSTR(asset_location_segment5,2) asset_location_segment6,
      asset_location_segment7,
	  gcompany,
		glob,
		gcostcenter,
		gaccount,
		glocation,
		gintercompany,	  	  
      exp_acct_segment1
      ||'.'
      || exp_acct_segment6
      ||'.'
      || exp_acct_segment2
      ||'.'
      || exp_acct_segment3
      ||'.'
      || exp_acct_segment4
      ||'.'
      || exp_acct_segment5 expense_account_segment,
      exp_acct_segment1,
      exp_acct_segment2,
      exp_acct_segment3,
      exp_acct_segment4,
      exp_acct_segment5,
      exp_acct_segment6,
      code_combination_id
    FROM
      (SELECT
        /*+ full(ds) full(fth) */
        fb.asset_id interface_line_number,
        fd.units_assigned units_assigned,
        NULL employee_email_address,
        loc.segment1 asset_location_segment1,
        loc.segment2 asset_location_segment2,
        loc.segment3 asset_location_segment3,
        loc.segment4 asset_location_segment4,
        loc.segment5 asset_location_segment5,
        loc.segment6 asset_location_segment6,
        loc.segment7 asset_location_segment7,
		gcc.segment1 gcompany,
		gcc.segment6 glob,
		gcc.segment2 gcostcenter,
		gcc.segment3 gaccount,
		gcc.segment4 glocation,
		gcc.segment5 gintercompany,			
        xx_gl_beacon_mapping_f1(gcc.segment1,'ENTITY','A') exp_acct_segment1,
        xx_gl_beacon_mapping_f1(gcc.segment2,'COST_CENTER','A') exp_acct_segment2,
        xx_gl_beacon_mapping_f1(gcc.segment3,'ACCOUNT','A') exp_acct_segment3,
        xx_gl_beacon_mapping_f1(gcc.segment4,'LOCATION','A') exp_acct_segment4,
        xx_gl_beacon_mapping_f1(gcc.segment5,'ENTITY','A') exp_acct_segment5,
        xx_gl_beacon_mapping_f1(gcc.segment6,'LOB','A') exp_acct_segment6,
        gcc.segment7 exp_acct_segment7,
        gcc.segment8 exp_acct_segment8,
        gcc.segment9 exp_acct_segment9,
        gcc.segment10 exp_acct_segment10,
        gcc.segment11 exp_acct_segment11,
        gcc.segment12 exp_acct_segment12,
        gcc.segment13 exp_acct_segment13,
        gcc.segment14 exp_acct_segment14,
        gcc.segment15 exp_acct_segment15,
        gcc.segment16 exp_acct_segment16,
        gcc.segment17 exp_acct_segment17,
        gcc.segment18 exp_acct_segment18,
        gcc.segment19 exp_acct_segment19,
        gcc.segment20 exp_acct_segment20,
        gcc.segment21 exp_acct_segment21,
        gcc.segment22 exp_acct_segment22,
        gcc.segment23 exp_acct_segment23,
        gcc.segment24 exp_acct_segment24,
        gcc.segment25 exp_acct_segment25,
        gcc.segment26 exp_acct_segment26,
        gcc.segment27 exp_acct_segment27,
        gcc.segment28 exp_acct_segment28,
        gcc.segment29 exp_acct_segment29,
        gcc.segment30 exp_acct_segment30,
        gcc.code_combination_id
      FROM fa_transaction_headers fth,
        fa_deprn_summary ds,
        fa_categories_b fcb,
        gl_code_combinations gcc,
        fa_locations loc,
        fa_distribution_history fd,
        fa_books fb,
        xx_fa_status xfs,
        fa_book_controls corpbook,
        fa_additions_b fab
      WHERE 1                =1
      AND xfs.book_type_code =p_book_type_code
      AND xfs.ASSET_STATUS   ='ACTIVE'
      AND corpbook.book_type_code=xfs.book_type_code
      AND corpbook.BOOK_CLASS    = 'CORPORATE'
      AND FAB.ASSET_ID           =XFS.ASSET_ID
      AND NOT EXISTS
        (SELECT 'x' FROM FA_ADDITIONS_B WHERE parent_asset_id = fab.ASSET_ID
        )
    AND fb.book_type_code=xfs.book_type_code
    AND fb.asset_id      = xfs.asset_id
    AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
    AND fb.date_ineffective IS NULL
    AND fd.asset_id          =fb.asset_id
    AND fd.date_ineffective IS NULL
    AND fd.book_type_code    ='OD US CORP'
    AND loc.location_id      =fd.location_id
    AND TRUNC (sysdate) BETWEEN TRUNC (NVL (fd.date_effective, sysdate)) AND TRUNC (NVL (fd.date_ineffective, sysdate))
    AND gcc.code_combination_id   = fd.code_combination_id
    AND fcb.category_id           =fab.asset_category_id
    AND fth.ASSET_ID              = fab.ASSET_ID
    AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
    AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
    AND ds.asset_id               =fb.asset_id
    AND ds.book_type_code         =fb.book_type_code
    AND DS.PERIOD_COUNTER         =
      (SELECT MAX(DS1.PERIOD_COUNTER)
      FROM FA_DEPRN_SUMMARY DS1
      WHERE DS1.ASSET_ID     =DS.ASSET_ID
      AND DS1.BOOK_TYPE_CODE = DS.BOOK_TYPE_CODE
      )
      )
    ORDER BY Interface_Line_Number;
    lc_file_handle utl_file.file_type;
    lv_line_count    NUMBER;
    l_file_name      VARCHAR2(500);
    lv_col_title     VARCHAR2(5000);
    l_file_path      VARCHAR2(500):='XXFIN_OUTBOUND';
    lc_errormsg      VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
    v_book_type_code VARCHAR2(100);
    v_rec_count      NUMBER:=0;
    v_success_count  NUMBER:=0;
    v_failure_count  NUMBER:=0;
    lc_coa           VARCHAR2(50);
    v_status         VARCHAR2(1);
    v_error_msg      VARCHAR2(100);
    lv_xx_fa_conv_asset_dtl xx_fa_conv_asset_dtl%ROWTYPE;
  BEGIN
    FOR rec IN c_child_dist
    LOOP
      lc_coa                   :=NULL;
      v_status                 :='N';
      v_error_msg              :=NULL;
      IF rec.exp_acct_segment1 IS NULL OR rec.exp_acct_segment2 IS NULL OR rec.exp_acct_segment3 IS NULL OR rec.exp_acct_segment4 IS NULL OR rec.exp_acct_segment5 IS NULL OR rec.exp_acct_segment6 IS NULL THEN
        lc_coa                 :=gc_entity||'.'||gc_lob||'.'||gc_costcenter||'.'||gc_account||'.'||gc_location||'.'||gc_ic;
        v_status               :='C';
        --v_error_msg            :='CTU Mapping Failure';
		ctu_mapping_validation( 'ASSET_DISTR', 
								 rec.gcompany,
								 rec.glob,
								 rec.gcostcenter,
								 rec.gaccount,
								 rec.glocation,
								 rec.gintercompany,
								 rec.exp_acct_segment1, 
								 rec.exp_acct_segment6, 
								 rec.exp_acct_segment2, 
								 rec.exp_acct_segment3, 
								 rec.exp_acct_segment4, 
								 rec.exp_acct_segment5, 
								 rec.interface_line_number, 
								 p_book_type_code, 
								 v_error_msg );
      ELSE
        lc_coa:=rec.expense_account_segment;
      END IF;
      BEGIN
        lv_xx_fa_conv_asset_dtl                          :=NULL ;
        lv_xx_fa_conv_asset_dtl.asset_id                 :=rec.interface_line_number ;
        lv_xx_fa_conv_asset_dtl.book_type_code           :=p_book_type_code ;
        lv_xx_fa_conv_asset_dtl.asset_attribute_category :='CHILD' ;
        lv_xx_fa_conv_asset_dtl.units_assigned           :=rec.units_assigned ;
        lv_xx_fa_conv_asset_dtl.employee_email_address   :=rec.employee_email_address ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment1  :=rec.asset_location_segment1 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment2  :=rec.asset_location_segment2 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment3  :=rec.asset_location_segment3 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment4  :=rec.asset_location_segment4 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment5  :=rec.asset_location_segment5 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment6  :=rec.asset_location_segment6 ;
        lv_xx_fa_conv_asset_dtl.asset_location_segment7  :=rec.asset_location_segment7 ;
        lv_xx_fa_conv_asset_dtl.expense_account_segment  :=lc_coa ;
        lv_xx_fa_conv_asset_dtl.request_id               :=NVL(fnd_global.conc_request_id, -1);
        lv_xx_fa_conv_asset_dtl.created_by               :=NVL(fnd_global.user_id,         -1);
        lv_xx_fa_conv_asset_dtl.creation_date            :=SYSDATE;
        lv_xx_fa_conv_asset_dtl.last_updated_by          :=NVL(fnd_global.user_id,   -1);
        lv_xx_fa_conv_asset_dtl.last_update_login        :=NVL(fnd_global.login_id , -1);
        lv_xx_fa_conv_asset_dtl.last_update_date         := SYSDATE;
        lv_xx_fa_conv_asset_dtl.status                   :=v_status ;
        lv_xx_fa_conv_asset_dtl.error_description        :=v_error_msg;
        INSERT INTO xx_fa_conv_asset_dtl VALUES lv_xx_fa_conv_asset_dtl;
        v_rec_count    :=v_rec_count    +1;
        v_success_count:=v_success_count+1;
      EXCEPTION
      WHEN OTHERS THEN
        lc_errormsg := 'In Procedure generic_child_distribution.Error to insert into XX_FA_CONV_ASSET_DTL for Asset Id:'||rec.Interface_Line_Number || '. SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE ;
        print_debug_msg (lc_errormsg, true);
        v_failure_count:=v_failure_count+1;
      END;
      IF v_rec_count>5000 THEN
        COMMIT;
        v_rec_count:=0;
      END IF;
    END LOOP;
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in generic_child_distribution procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
  END generic_child_distribution;
PROCEDURE generic_file_extract_distr
  (
    p_book_type_code VARCHAR2,
    p_record_type    VARCHAR2
  )
IS
  CURSOR c_dist
  IS
    SELECT *
    FROM XX_FA_CONV_ASSET_DTL
    WHERE book_type_code         =p_book_type_code
    AND asset_attribute_category =p_record_type
      and status in ('N','C')
    ORDER BY asset_id;
  lc_file_handle utl_file.file_type;
  lv_line_count    NUMBER;
  l_file_name      VARCHAR2(500);
  v_book_type_code VARCHAR2(100);
  lv_col_title     VARCHAR2(5000);
  l_file_path      VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg      VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
BEGIN
  BEGIN
    SELECT directory_path
    INTO l_file_path
    FROM dba_directories
    WHERE directory_name = 'XXFIN_OUTBOUND';
  EXCEPTION
  WHEN OTHERS THEN
    l_file_path := NULL;
  END;
  print_debug_msg ('Package generic_file_extract_distr START', TRUE);
  print_debug_msg ('P_BOOK_TYPE_CODE '||p_book_type_code, TRUE);
  v_book_type_code :=REPLACE(REPLACE (REPLACE(p_book_type_code,'OD US ','US_'),'OD CA ','CA_'),' ','_');
  l_file_name      := p_record_type||'_'||v_book_type_code||'_DISTR_'||TO_CHAR(sysdate,'DDMONYYYYHH24MISS')||'.csv';
  lc_file_handle   := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title     :='INTERFACE_LINE_NUMBER'|| ','|| 'UNITS_ASSIGNED'|| ','|| 'EMPLOYEE_EMAIL_ADDRESS'|| ','|| 'ASSET_LOCATION_SEGMENT1'|| ','|| 'ASSET_LOCATION_SEGMENT2'|| ','|| 'ASSET_LOCATION_SEGMENT3'|| ','|| 'ASSET_LOCATION_SEGMENT4'|| ','|| 'ASSET_LOCATION_SEGMENT5'|| ','|| 'ASSET_LOCATION_SEGMENT6'|| ','|| 'ASSET_LOCATION_SEGMENT7'|| ','|| 'EXPENSE_ACCOUNT_SEGMENT';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_dist
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,'"'||i.asset_id|| '","'|| i.units_assigned|| '","'|| i.employee_email_address|| '","'|| i.asset_location_segment1|| '","'|| i.asset_location_segment2|| '","'|| i.asset_location_segment3|| '","'|| i.asset_location_segment4|| '","'|| i.asset_location_segment5|| '","'|| i.asset_location_segment6|| '","'|| i.asset_location_segment7|| '","'|| i.expense_account_segment||'"');	
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in generic_file_extract_distr procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END generic_file_extract_distr;
PROCEDURE generic_tax_parent_asset_hdr(
    p_book_type_code VARCHAR2)
IS
  CURSOR c_tax_par_asset_hdr
  IS
    SELECT
      /*+ parallel(8) */
      Interface_Line_Number,
      Asset_Book,
      Transaction_Name,
      Asset_Number,
      Asset_Description ,
      Tag_Number,
      Manufacturer,
      Serial_Number,
      Model ,
      Asset_Type,
      Cost,
      Date_Placed_in_Service,
      Prorate_Convention,
      Asset_Units,
      Asset_Category_Segment1,
      Asset_Category_Segment2,
      Asset_Category_Segment3,
      Asset_Category_Segment4,
      Asset_Category_Segment5,
      Asset_Category_Segment6,
      Asset_Category_Segment7,
      'POST' Posting_Status,
      'NEW' Queue_Name,
      'ORACLE FBDI' Feeder_System,
      Parent_Asset,
      NULL Add_to_Asset,
      NULL Asset_Key_Segment1,
      NULL Asset_Key_Segment2,
      NULL Asset_Key_Segment3,
      NULL Asset_Key_Segment4,
      NULL Asset_Key_Segment5,
      NULL Asset_Key_Segment6,
      NULL Asset_Key_Segment7,
      NULL Asset_Key_Segment8,
      NULL Asset_Key_Segment9,
      NULL Asset_Key_Segment10,
      In_physical_inventory,
      Property_Type,
      PROPERTY_CLASS,
      --           fa_details.distribution_id,  -- Moved to end by Arun
      In_use,
      Ownership,
      Bought,
      NULL MATERIAL_INDICATOR,
      COMMITMENT ,
      INVESTMENT_LAW, --arunadded
      Amortize,
      Amortization_Start_Date,
      Depreciate,
      Salvage_Value_Type,
      Salvage_Value_Amount,
      Salvage_Value_Percent,
      YTD_Depreciation,
      Depreciation_Reserve,
      YTD_Bonus_Depreciation,
      Bonus_Depreciation_Reserve,
      YTD_IMPAIRMENT ,
      IMPAIRMENT_RESERVE ,
      Depreciation_Method ,
      LIFE_IN_MONTHS ,
      BASIC_RATE ,
      ADJUSTED_RATE ,
      UNIT_OF_MEASURE ,
      PRODUCTION_CAPACITY ,
      Ceiling_Type,
      BONUS_RULE ,
      NULL CASH_GENERATING_UNIT ,
      Depreciation_Limit_Type,
      Depreciation_Limit_Percent,
      Depreciation_Limit_Amount,
      NULL INVOICE_COST,
      (SELECT xx_gl_beacon_mapping_f1(gcc.segment1,'ENTITY','A')--ENTITY
      FROM gl_code_combinations gcc,
        fa_distribution_accounts da
      WHERE da.distribution_id    = fa_details.distribution_id
      AND da.book_type_code       = fa_details.asset_book
      AND gcc.code_combination_id = da.asset_clearing_account_ccid
      )cost_clearing_account_seg1,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment6,'LOB','A')----LOB
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg2,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment2,'COST_CENTER','A')------COST CENTER
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg3,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment3,'ACCOUNT','A')----ACCOUNT
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg4,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment4,'LOCATION','A')---LOCATION
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg5,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment5,'ENTITY','A')-----INTERCOMP
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg6,
    NULL cost_clearing_account_seg7,
    NULL Cost_Clearing_Account_Seg8,
    NULL Cost_Clearing_Account_Seg9,
    NULL COST_CLEARING_ACCOUNT_SEG10,
    NULL Cost_Clearing_Account_Seg11,
    NULL Cost_Clearing_Account_Seg12,
    NULL Cost_Clearing_Account_Seg13,
    NULL Cost_Clearing_Account_Seg14,
    NULL COST_CLEARING_ACCOUNT_SEG15,
    /*           NULL                            CLEARING_ACCT_SEGMENT16,
    NULL                            CLEARING_ACCT_SEGMENT17,
    NULL                            CLEARING_ACCT_SEGMENT18,
    NULL                            CLEARING_ACCT_SEGMENT19,
    NULL                            CLEARING_ACCT_SEGMENT20,
    NULL                            CLEARING_ACCT_SEGMENT21,
    NULL                            CLEARING_ACCT_SEGMENT22,
    NULL                            CLEARING_ACCT_SEGMENT23,
    NULL                            CLEARING_ACCT_SEGMENT24,
    NULL                            CLEARING_ACCT_SEGMENT25,
    NULL                            CLEARING_ACCT_SEGMENT26,
    NULL                            CLEARING_ACCT_SEGMENT27,
    NULL                            CLEARING_ACCT_SEGMENT28,
    NULL                            CLEARING_ACCT_SEGMENT29,
    NULL                            CLEARING_ACCT_SEGMENT30,
    */
    fa_details.ATTRIBUTE1,
    fa_details.ATTRIBUTE2,
    fa_details.ATTRIBUTE3,
    fa_details.ATTRIBUTE4,
    fa_details.ATTRIBUTE5,
    fa_details.ATTRIBUTE6,
    fa_details.ATTRIBUTE7,
    fa_details.ATTRIBUTE8,
    fa_details.ATTRIBUTE9,
    fa_details.ATTRIBUTE10,
    fa_details.ATTRIBUTE11,
    fa_details.ATTRIBUTE12,
    NULL ATTRIBUTE13,
    fa_details.ATTRIBUTE14,
    fa_details.ATTRIBUTE15,
    /*
    NULL                            ATTRIBUTE16,
    NULL                            ATTRIBUTE17,
    NULL                            ATTRIBUTE18,
    NULL                            ATTRIBUTE19,
    NULL                            ATTRIBUTE20,
    NULL                            ATTRIBUTE21,
    NULL                            ATTRIBUTE22,
    NULL                            ATTRIBUTE23,
    NULL                            ATTRIBUTE24,
    NULL                            ATTRIBUTE25,
    NULL                            ATTRIBUTE26,
    NULL                            ATTRIBUTE27,
    NULL                            ATTRIBUTE28,
    NULL                            ATTRIBUTE29,
    NULL                            ATTRIBUTE30,
    NULL                            ATTRIBUTE_NUMBER1,
    NULL                            ATTRIBUTE_NUMBER2,
    NULL                            ATTRIBUTE_NUMBER3,
    NULL                            ATTRIBUTE_NUMBER4,
    NULL                            ATTRIBUTE_NUMBER5,
    NULL                            ATTRIBUTE_DATE1,
    NULL                            ATTRIBUTE_DATE2,
    NULL                            ATTRIBUTE_DATE3,
    NULL                            ATTRIBUTE_DATE4,
    NULL                            ATTRIBUTE_DATE5,
    */
    ATTRIBUTE_CATEGORY_CODE,
    NULL context,
    /*
    NULL                            TH_ATTRIBUTE1,
    NULL                            TH_ATTRIBUTE2,
    NULL                            TH_ATTRIBUTE3,
    NULL                            TH_ATTRIBUTE4,
    NULL                            TH_ATTRIBUTE5,
    NULL                            TH_ATTRIBUTE6,
    NULL                            TH_ATTRIBUTE7,
    NULL                            TH_ATTRIBUTE8,
    NULL                            TH_ATTRIBUTE9,
    NULL                            TH_ATTRIBUTE10,
    NULL                            TH_ATTRIBUTE11,
    NULL                            TH_ATTRIBUTE12,
    NULL                            TH_ATTRIBUTE13,
    NULL                            TH_ATTRIBUTE14,
    NULL                            TH_ATTRIBUTE15,
    NULL                            TH_ATTRIBUTE_NUMBER1,
    NULL                            TH_ATTRIBUTE_NUMBER2,
    NULL                            TH_ATTRIBUTE_NUMBER3,
    NULL                            TH_ATTRIBUTE_NUMBER4,
    NULL                            TH_ATTRIBUTE_NUMBER5,
    NULL                            TH_ATTRIBUTE_DATE1,
    NULL                            TH_ATTRIBUTE_DATE2,
    NULL                            TH_ATTRIBUTE_DATE3,
    NULL                            TH_ATTRIBUTE_DATE4,
    NULL                            TH_ATTRIBUTE_DATE5,
    NULL                            TH_ATTRIBUTE_CATEGORY_CODE,
    NULL                            TH2_ATTRIBUTE1,
    NULL                            TH2_ATTRIBUTE2,
    NULL                            TH2_ATTRIBUTE3,
    NULL                            TH2_ATTRIBUTE4,
    NULL                            TH2_ATTRIBUTE5,
    NULL                            TH2_ATTRIBUTE6,
    NULL                            TH2_ATTRIBUTE7,
    NULL                            TH2_ATTRIBUTE8,
    NULL                            TH2_ATTRIBUTE9,
    NULL                            TH2_ATTRIBUTE10,
    NULL                            TH2_ATTRIBUTE11,
    NULL                            TH2_ATTRIBUTE12,
    NULL                            TH2_ATTRIBUTE13,
    NULL                            TH2_ATTRIBUTE14,
    NULL                            TH2_ATTRIBUTE15,
    NULL                            TH2_ATTRIBUTE_NUMBER1,
    NULL                            TH2_ATTRIBUTE_NUMBER2,
    NULL                            TH2_ATTRIBUTE_NUMBER3,
    NULL                            TH2_ATTRIBUTE_NUMBER4,
    NULL                            TH2_ATTRIBUTE_NUMBER5,
    NULL                            TH2_ATTRIBUTE_DATE1,
    NULL                            TH2_ATTRIBUTE_DATE2,
    NULL                            TH2_ATTRIBUTE_DATE3,
    NULL                            TH2_ATTRIBUTE_DATE4,
    NULL                            TH2_ATTRIBUTE_DATE5,
    NULL                            TH2_ATTRIBUTE_CATEGORY_CODE,
    NULL                            AI_ATTRIBUTE1,
    NULL                            AI_ATTRIBUTE2,
    NULL                            AI_ATTRIBUTE3,
    NULL                            AI_ATTRIBUTE4,
    NULL                            AI_ATTRIBUTE5,
    NULL                            AI_ATTRIBUTE6,
    NULL                            AI_ATTRIBUTE7,
    NULL                            AI_ATTRIBUTE8,
    NULL                            AI_ATTRIBUTE9,
    NULL                            AI_ATTRIBUTE10,
    NULL                            AI_ATTRIBUTE11,
    NULL                            AI_ATTRIBUTE12,
    NULL                            AI_ATTRIBUTE13,
    NULL                            AI_ATTRIBUTE14,
    NULL                            AI_ATTRIBUTE15,
    NULL                            AI_ATTRIBUTE_NUMBER1,
    NULL                            AI_ATTRIBUTE_NUMBER2,
    NULL                            AI_ATTRIBUTE_NUMBER3,
    NULL                            AI_ATTRIBUTE_NUMBER4,
    NULL                            AI_ATTRIBUTE_NUMBER5,
    NULL                            AI_ATTRIBUTE_DATE1,
    NULL                            AI_ATTRIBUTE_DATE2,
    NULL                            AI_ATTRIBUTE_DATE3,
    NULL                            AI_ATTRIBUTE_DATE4,
    NULL                            AI_ATTRIBUTE_DATE5,
    NULL                            AI_ATTRIBUTE_CATEGORY_CODE,
    */
    NULL Mass_Property_Eligible,
    NULL Group_Asset,
    NULL Reduction_Rate,
    NULL Apply_Reduction_Rate_to_Addi,
    NULL Apply_Reduction_Rate_to_Adj,
    NULL Apply_Reduction_Rate_to_Reti,
    NULL Recognize_Gain_or_Loss,
    NULL Recapture_Excess_Reserve,
    NULL Limit_Net_Proceeds_to_Cost,
    NULL Terminal_Gain_or_Loss,
    NULL Tracking_Method,
    NULL Allocate_Excess_Depreciation,
    NULL Depreciate_By,
    NULL Member_Rollup,
    NULL Allo_to_Full_Reti_and_Res_Asst,
    NULL Over_Depreciate,
    NULL PREPARER,
    --           NULL                            MERGED_LEVEL,        commented by arun
    --           NULL                            Parent_Intf_Line_no,  commented by arun
    NULL Sum_Merged_Units,
    NULL New_Master,
    NULL Units_to_Adjust,
    NULL Short_year,
    NULL Conversion_Date,
    NULL ORIGINAL_DEP_START_DATE,
    /*        NULL                            GLOBAL_ATTRIBUTE1,
    NULL                            GLOBAL_ATTRIBUTE2,
    NULL                            GLOBAL_ATTRIBUTE3,
    NULL                            GLOBAL_ATTRIBUTE4,
    NULL                            GLOBAL_ATTRIBUTE5,
    NULL                            GLOBAL_ATTRIBUTE6,
    NULL                            GLOBAL_ATTRIBUTE7,
    NULL                            GLOBAL_ATTRIBUTE8,
    NULL                            GLOBAL_ATTRIBUTE9,
    NULL                            GLOBAL_ATTRIBUTE10,
    NULL                            GLOBAL_ATTRIBUTE11,
    NULL                            GLOBAL_ATTRIBUTE12,
    NULL                            GLOBAL_ATTRIBUTE13,
    NULL                            GLOBAL_ATTRIBUTE14,
    NULL                            GLOBAL_ATTRIBUTE15,
    NULL                            GLOBAL_ATTRIBUTE16,
    NULL                            GLOBAL_ATTRIBUTE17,
    NULL                            GLOBAL_ATTRIBUTE18,
    NULL                            GLOBAL_ATTRIBUTE19,
    NULL                            GLOBAL_ATTRIBUTE20,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER1,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER2,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER3,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER4,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER5,
    NULL                            GLOBAL_ATTRIBUTE_DATE1,
    NULL                            GLOBAL_ATTRIBUTE_DATE2,
    NULL                            GLOBAL_ATTRIBUTE_DATE3,
    NULL                            GLOBAL_ATTRIBUTE_DATE4,
    NULL                            GLOBAL_ATTRIBUTE_DATE5,
    NULL                            GLOBAL_ATTRIBUTE_CATEGORY,
    */
    NBV_at_the_Time_of_Switch,
    NULL Period_Fully_Reserved,
    NULL Start_Period_of_Extended_Dep,
    Earlier_Dep_Limit_Type,
    Earlier_Dep_Limit_Percent,
    Earlier_Dep_Limit_Amount,
    NULL Earlier_Depreciation_Method ,
    Earlier_Life_in_Months,
    Earlier_Basic_Rate,
    EARLIER_ADJUSTED_RATE,
    --          NULL                            ASSET_SCHEDULE_IDENTIFIER,  commented by arun
    NULL Lease_Number,
    NULL Revaluation_Reserve,
    NULL Revaluation_Loss,
    NULL Reval_Reser_Amortization_Basis,
    NULL Impairment_Loss_Expense,
    NULL Revaluation_Cost_Ceiling,
    NULL FAIR_VALUE,
    NULL LAST_USED_PRICE_INDEX_VALUE,
    NULL Supplier_Name,
    NULL Supplier_Number,
    NULL Purchase_Order_Number,
    NULL Invoice_Number,
    NULL Invoice_Voucher_Number,
    NULL Invoice_Date,
    NULL Payables_Units,
    NULL Invoice_Line_Number,
    NULL Invoice_Line_Type,
    NULL Invoice_Line_Description,
    NULL Invoice_Payment_Number,
    NULL Project_Number,
    NULL Task_Number,
    NULL FULLY_DEPRECIATE,
    FA_DETAILS.distribution_id
  FROM
    (SELECT
      /*+ full(ds) full(fth) */
      FAB.ASSET_ID Interface_Line_Number,
      FB.BOOK_TYPE_CODE Asset_Book,
      fth.TRANSACTION_TYPE_CODE Transaction_Name,
      FAB.ASSET_NUMBER Asset_Number,
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(fat.description,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' '),chr(34),' inch') Asset_Description,
      FAB.TAG_NUMBER Tag_Number,
      FAB.MANUFACTURER_NAME Manufacturer,
      REPLACE(fab.serial_number,chr(44),chr(124)) serial_number,
      FAB.MODEL_NUMBER Model ,
      FAB.ASSET_TYPE Asset_Type,
      fb.COST Cost,
      TO_CHAR(fb.DATE_PLACED_IN_SERVICE,'YYYY/MM/DD') Date_Placed_in_Service,
      FB.PRORATE_CONVENTION_CODE Prorate_Convention,
      fab.CURRENT_UNITS Asset_Units,
      FCB.SEGMENT1 Asset_Category_Segment1,
      FCB.SEGMENT2 Asset_Category_Segment2,
      FCB.SEGMENT3 Asset_Category_Segment3,
      FCB.SEGMENT4 Asset_Category_Segment4,
      FCB.SEGMENT5 Asset_Category_Segment5,
      FCB.SEGMENT6 Asset_Category_Segment6,
      FCB.SEGMENT7 Asset_Category_Segment7,
      (SELECT ASSET_NUMBER
      FROM fa_additions_b
      WHERE asset_id = fab.PARENT_ASSET_ID
      ) Parent_Asset,
      fab.INVENTORIAL In_physical_inventory,
      fab.PROPERTY_TYPE_CODE Property_Type,
      fab.PROPERTY_1245_1250_CODE Property_Class,
      fab.IN_USE_FLAG In_use,
      fab.OWNED_LEASED Ownership,
      fab.NEW_USED Bought,
      FAB.COMMITMENT ,
      fab.investment_law, -- added by Arun
      'NO' Amortize,
      TO_CHAR(FTH.DATE_EFFECTIVE,'YYYY/MM/DD') Amortization_Start_Date,
      fb.DEPRECIATE_FLAG Depreciate,
      fb.SALVAGE_TYPE Salvage_Value_Type,
      fb.SALVAGE_VALUE Salvage_Value_Amount,
      fb.PERCENT_SALVAGE_VALUE Salvage_Value_Percent,
      DECODE(TO_NUMBER(TO_CHAR(ds.deprn_run_date,'RRRR')),2020,xfs.YTD_DEPRN,0) YTD_Depreciation,
      xfs.DEPRN_RSV Depreciation_Reserve,
      ds.BONUS_YTD_DEPRN YTD_Bonus_Depreciation,
      ds.BONUS_DEPRN_RESERVE Bonus_Depreciation_Reserve,
      ds.YTD_IMPAIRMENT ,
      ds.IMPAIRMENT_RESERVE ,
      fb.deprn_method_code Depreciation_Method ,
      fb.LIFE_IN_MONTHS ,
      FB.BASIC_RATE ,
      fb.ADJUSTED_RATE ,
      fb.UNIT_OF_MEASURE ,
      fb.PRODUCTION_CAPACITY ,
      fb.CEILING_NAME Ceiling_Type,
      fb.BONUS_RULE ,
      fb.DEPRN_LIMIT_TYPE Depreciation_Limit_Type,
      fb.ALLOWED_DEPRN_LIMIT Depreciation_Limit_Percent,
      fb.ALLOWED_DEPRN_LIMIT_AMOUNT Depreciation_Limit_Amount,
      FAB.ATTRIBUTE1 ATTRIBUTE1,
      FAB.ATTRIBUTE2 ATTRIBUTE2,
      FAB.ATTRIBUTE3 ATTRIBUTE3,
      FAB.ATTRIBUTE4 ATTRIBUTE4,
      FAB.ATTRIBUTE5 ATTRIBUTE5,
      FAB.ATTRIBUTE6 ATTRIBUTE6,
      FAB.ATTRIBUTE7 ATTRIBUTE7,
      FAB.ATTRIBUTE8 ATTRIBUTE8,
      FAB.ATTRIBUTE9 ATTRIBUTE9,
      FAB.ATTRIBUTE10 ATTRIBUTE10,
      FAB.ATTRIBUTE11 ATTRIBUTE11,
      FAB.ATTRIBUTE12 ATTRIBUTE12,	  
      FAB.ATTRIBUTE14 ATTRIBUTE14,	  
      FAB.ATTRIBUTE15 ATTRIBUTE15,	  	  
	  fab.ATTRIBUTE_CATEGORY_CODE,
      fb.NBV_AT_SWITCH NBV_at_the_Time_of_Switch,
      fb.PRIOR_DEPRN_LIMIT_TYPE Earlier_Dep_Limit_Type,
      fb.PRIOR_DEPRN_LIMIT Earlier_Dep_Limit_Percent,
      fb.PRIOR_DEPRN_LIMIT_AMOUNT Earlier_Dep_Limit_Amount,
      fb.PRIOR_LIFE_IN_MONTHS Earlier_Life_in_Months,
      fb.PRIOR_BASIC_RATE Earlier_Basic_Rate,
      fb.PRIOR_ADJUSTED_RATE Earlier_Adjusted_Rate,
      ddtl.distribution_id
    FROM fa_books fb,
      xx_fa_status xfs,
      fa_book_controls corpbook,
      fa_additions_b fab,
      fa_categories_b fcb,
      fa_additions_tl fat,
      fa_deprn_summary ds,
      fa_deprn_detail ddtl,
      fa_transaction_headers fth
    WHERE 1                =1
    AND xfs.book_type_code =p_book_type_code
    AND xfs.ASSET_STATUS   ='ACTIVE'
    AND fb.book_type_code      =xfs.book_type_code
    AND fb.asset_id            = xfs.asset_id
    AND corpbook.book_type_code=FB.book_type_code
    AND corpbook.BOOK_CLASS    = 'TAX'
    AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
	AND fb.date_ineffective IS NULL
    AND fab.ASSET_ID         =fb.ASSET_ID
    AND fab.parent_asset_id IS NULL
    AND EXISTS
      (SELECT 'x' FROM FA_ADDITIONS_B WHERE PARENT_ASSET_ID = FAB.ASSET_ID
      )
    AND fcb.category_id           =fab.asset_category_id
    AND fat.ASSET_ID              =fab.ASSET_ID
    AND fat.language              = 'US'
    AND ds.asset_id               =fb.asset_id
    AND ds.book_type_code         =fb.book_type_code
    AND fth.asset_id              = fab.asset_id
    AND fth.book_type_code        = corpbook.book_type_code
    AND fth.transaction_type_code = 'ADDITION'
    AND ds.period_counter         =
      (SELECT MAX(DS1.PERIOD_COUNTER)
      FROM fa_deprn_summary ds1
      WHERE ds1.asset_id     =ds.asset_id
      AND ds1.book_type_code = ds.book_type_code
      )
    AND ddtl.asset_id        =fth.asset_id
    AND ddtl.book_type_code  =fth.book_type_code
    AND ddtl.period_counter  =ds.period_counter
    AND ddtl.distribution_id =
      (SELECT MAX(distribution_id)
      FROM fa_deprn_detail
      WHERE asset_id    =ddtl.asset_id
      AND book_type_code=ddtl.book_type_code
      AND period_counter=ddtl.period_counter
      )
    ) FA_DETAILS;

CURSOR c_gcc(p_dist_id NUMBER,p_book VARCHAR2)
IS
SELECT 
	gcc.segment1 gcompany,
	gcc.segment6 glob,
	gcc.segment2 gcostcenter,
	gcc.segment3 gaccount,
	gcc.segment4 glocation,
	gcc.segment5 gintercompany
  FROM gl_code_combinations gcc,
       fa_distribution_accounts da
 WHERE da.distribution_id = p_dist_id
   AND da.book_type_code  = p_book
   AND gcc.code_combination_id = da.asset_clearing_account_ccid;
	
	
  lc_file_handle utl_file.file_type;
  lv_line_count    NUMBER;
  l_file_name      VARCHAR2(500);
  lv_col_title     VARCHAR2(5000);
  l_file_path      VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg      VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  v_book_type_code VARCHAR2(100);
  v_rec_count      NUMBER:=0;
  v_success_count  NUMBER:=0;
  v_failure_count  NUMBER:=0;
  v_segment1       VARCHAR2(50);
  v_segment2       VARCHAR2(50);
  v_segment3       VARCHAR2(50);
  v_segment4       VARCHAR2(50);
  v_segment5       VARCHAR2(50);
  v_segment6       VARCHAR2(50);
  v_status         VARCHAR2(1);
  v_error_msg      VARCHAR2(100);
  lv_xx_fa_conv_asset_hdr xx_fa_conv_asset_hdr%ROWTYPE;

  v_gcompany       VARCHAR2(50);
  v_glob	       VARCHAR2(50);
  v_gcostcenter    VARCHAR2(50);
  v_gaccount       VARCHAR2(50);
  v_glocation      VARCHAR2(50);
  v_gintercompany  VARCHAR2(50);
 
  
BEGIN
  FOR rec IN c_tax_par_asset_hdr
  LOOP
    v_segment1                        :=NULL;
    v_segment2                        :=NULL;
    v_segment3                        :=NULL;
    v_segment4                        :=NULL;
    v_segment5                        :=NULL;
    v_segment6                        :=NULL;
    v_status                          :='N';
    v_gcompany       				  :=NULL;
    v_glob	       		:=NULL;
    v_gcostcenter    	:=NULL;
    v_gaccount       	:=NULL;
    v_glocation      	:=NULL;
    v_gintercompany  	:=NULL;
	
    IF rec.cost_clearing_account_seg1 IS NULL OR rec.cost_clearing_account_seg2 IS NULL OR rec.cost_clearing_account_seg3 IS NULL OR rec.cost_clearing_account_seg4 IS NULL OR rec.cost_clearing_account_seg5 IS NULL OR rec.cost_clearing_account_seg6 IS NULL THEN
      v_segment1                      :=gc_entity;
      v_segment2                      :=gc_lob;
      v_segment3                      :=gc_costcenter;
      v_segment4                      :=gc_account;
      v_segment5                      :=gc_location;
      v_segment6                      :=gc_ic;
      v_status                        :='C';
      --v_error_msg                     :='CTU Mapping Failure';

	  OPEN c_gcc(rec.distribution_id,rec.asset_book);
	  FETCH c_gcc 
	   INTO v_gcompany,v_glob,v_gcostcenter,v_gaccount,v_glocation,v_gintercompany;
	  CLOSE c_gcc;
	  /*print_debug_msg ('Dist id :'||to_char(rec.distribution_id), true);
	  print_debug_msg ('Company  :'||v_gcompany, true);
	  print_debug_msg ('LOB      :'||v_glob, true);
	  print_debug_msg ('CC       :'||v_gcostcenter, true);
	  print_debug_msg ('Acct     :'||v_gaccount, true);
	  print_debug_msg ('Loc      :'||v_glocation, true);
	  print_debug_msg ('Interco  :'||v_gintercompany, true);	  
	  */
      ctu_mapping_validation( 'ASSET_HDR', 
							   v_gcompany,
							   v_glob,
							   v_gcostcenter,
							   v_gaccount,
							   v_glocation,
							   v_gintercompany,
							   rec.cost_clearing_account_seg1, 
							   rec.cost_clearing_account_seg2, 
							   rec.cost_clearing_account_seg3, 
							   rec.cost_clearing_account_seg4, 
							   rec.cost_clearing_account_seg5, 
							   rec.cost_clearing_account_seg6, 
							   rec.interface_line_number, 
							   rec.asset_book, 
							   v_error_msg );
    ELSE
      v_segment1:=rec.cost_clearing_account_seg1;
      v_segment2:=rec.cost_clearing_account_seg2;
      v_segment3:=rec.cost_clearing_account_seg3;
      v_segment4:=rec.cost_clearing_account_seg4;
      v_segment5:=rec.cost_clearing_account_seg5;
      v_segment6:=rec.cost_clearing_account_seg6;
    END IF;
    BEGIN
      lv_xx_fa_conv_asset_hdr                            :=NULL ;
      lv_xx_fa_conv_asset_hdr.asset_id                   :=rec.interface_line_number ;
      lv_xx_fa_conv_asset_hdr.book_type_code             :=rec.asset_book ;
      lv_xx_fa_conv_asset_hdr.asset_attribute_category   :='PARENT' ;
      lv_xx_fa_conv_asset_hdr.transaction_name           :=rec.transaction_name ;
      lv_xx_fa_conv_asset_hdr.asset_number               :=rec.asset_number ;
      lv_xx_fa_conv_asset_hdr.asset_description          :=rec.asset_description ;
      lv_xx_fa_conv_asset_hdr.tag_number                 :=rec.tag_number ;
      lv_xx_fa_conv_asset_hdr.manufacturer               :=rec.manufacturer ;
      lv_xx_fa_conv_asset_hdr.serial_number              :=rec.serial_number ;
      lv_xx_fa_conv_asset_hdr.model                      :=rec.model ;
      lv_xx_fa_conv_asset_hdr.asset_type                 :=rec.asset_type ;
      lv_xx_fa_conv_asset_hdr.cost                       :=rec.cost ;
      lv_xx_fa_conv_asset_hdr.date_placed_in_service     :=rec.date_placed_in_service ;
      lv_xx_fa_conv_asset_hdr.prorate_convention         :=rec.prorate_convention ;
      lv_xx_fa_conv_asset_hdr.asset_units                :=rec.asset_units ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment1    :=rec.asset_category_segment1 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment2    :=rec.asset_category_segment2 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment3    :=rec.asset_category_segment3 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment4    :=rec.asset_category_segment4 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment5    :=rec.asset_category_segment5 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment6    :=rec.asset_category_segment6 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment7    :=rec.asset_category_segment7 ;
      lv_xx_fa_conv_asset_hdr.parent_asset               :=rec.parent_asset ;
      lv_xx_fa_conv_asset_hdr.in_physical_inventory      :=rec.in_physical_inventory ;
      lv_xx_fa_conv_asset_hdr.property_type              :=rec.property_type ;
      lv_xx_fa_conv_asset_hdr.property_class             :=rec.property_class ;
      lv_xx_fa_conv_asset_hdr.in_use                     :=rec.in_use ;
      lv_xx_fa_conv_asset_hdr.ownership                  :=rec.ownership ;
      lv_xx_fa_conv_asset_hdr.bought                     :=rec.bought ;
      lv_xx_fa_conv_asset_hdr.commitment                 :=rec.commitment ;
      lv_xx_fa_conv_asset_hdr.investment_law             :=rec.investment_law ;
      lv_xx_fa_conv_asset_hdr.amortize                   :=rec.amortize ;
      lv_xx_fa_conv_asset_hdr.amortization_start_date    :=rec.amortization_start_date ;
      lv_xx_fa_conv_asset_hdr.depreciate                 :=rec.depreciate ;
      lv_xx_fa_conv_asset_hdr.salvage_value_type         :=rec.salvage_value_type ;
      lv_xx_fa_conv_asset_hdr.salvage_value_amount       :=rec.salvage_value_amount ;
      lv_xx_fa_conv_asset_hdr.salvage_value_percent      :=rec.salvage_value_percent ;
      lv_xx_fa_conv_asset_hdr.ytd_depreciation           :=rec.ytd_depreciation ;
      lv_xx_fa_conv_asset_hdr.depreciation_reserve       :=rec.depreciation_reserve ;
      lv_xx_fa_conv_asset_hdr.ytd_bonus_depreciation     :=rec.ytd_bonus_depreciation ;
      lv_xx_fa_conv_asset_hdr.bonus_depreciation_reserve :=rec.bonus_depreciation_reserve ;
      lv_xx_fa_conv_asset_hdr.ytd_impairment             :=rec.ytd_impairment ;
      lv_xx_fa_conv_asset_hdr.impairment_reserve         :=rec.impairment_reserve ;
      lv_xx_fa_conv_asset_hdr.depreciation_method        :=rec.depreciation_method ;
      lv_xx_fa_conv_asset_hdr.life_in_months             :=rec.life_in_months ;
      lv_xx_fa_conv_asset_hdr.basic_rate                 :=rec.basic_rate ;
      lv_xx_fa_conv_asset_hdr.adjusted_rate              :=rec.adjusted_rate ;
      lv_xx_fa_conv_asset_hdr.unit_of_measure            :=rec.unit_of_measure ;
      lv_xx_fa_conv_asset_hdr.production_capacity        :=rec.production_capacity ;
      lv_xx_fa_conv_asset_hdr.ceiling_type               :=rec.ceiling_type ;
      lv_xx_fa_conv_asset_hdr.bonus_rule                 :=rec.bonus_rule ;
      lv_xx_fa_conv_asset_hdr.depreciation_limit_type    :=rec.depreciation_limit_type ;
      lv_xx_fa_conv_asset_hdr.depreciation_limit_percent :=rec.depreciation_limit_percent ;
      lv_xx_fa_conv_asset_hdr.depreciation_limit_amount  :=rec.depreciation_limit_amount ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg1 :=v_segment1 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg2 :=v_segment2 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg3 :=v_segment3 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg4 :=v_segment4 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg5 :=v_segment5 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg6 :=v_segment6 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg7 :=rec.cost_clearing_account_seg7 ;
      lv_xx_fa_conv_asset_hdr.attribute1                 :=rec.attribute1 ;
      lv_xx_fa_conv_asset_hdr.attribute2                 :=rec.attribute2 ;
      lv_xx_fa_conv_asset_hdr.attribute3                 :=rec.attribute3 ;
      lv_xx_fa_conv_asset_hdr.attribute4                 :=rec.attribute4 ;
      lv_xx_fa_conv_asset_hdr.attribute5                 :=rec.attribute5 ;
      lv_xx_fa_conv_asset_hdr.attribute6                 :=rec.attribute6 ;
      lv_xx_fa_conv_asset_hdr.attribute7                 :=rec.attribute7 ;
      lv_xx_fa_conv_asset_hdr.attribute8                 :=rec.attribute8 ;
      lv_xx_fa_conv_asset_hdr.attribute9                 :=rec.attribute9 ;
      lv_xx_fa_conv_asset_hdr.attribute10                :=rec.attribute10 ;
      lv_xx_fa_conv_asset_hdr.attribute11                :=rec.attribute11 ;
      lv_xx_fa_conv_asset_hdr.attribute12                :=rec.attribute12 ;
      lv_xx_fa_conv_asset_hdr.attribute13                :=rec.attribute13 ;
      lv_xx_fa_conv_asset_hdr.attribute14                :=rec.attribute14 ;
      lv_xx_fa_conv_asset_hdr.attribute15                :=rec.attribute15 ;	  
      lv_xx_fa_conv_asset_hdr.attribute_category_code    :=rec.attribute_category_code ;
      lv_xx_fa_conv_asset_hdr.nbv_at_the_time_of_switch  :=rec.nbv_at_the_time_of_switch ;
      lv_xx_fa_conv_asset_hdr.earlier_dep_limit_type     :=rec.earlier_dep_limit_type ;
      lv_xx_fa_conv_asset_hdr.earlier_dep_limit_percent  :=rec.earlier_dep_limit_percent ;
      lv_xx_fa_conv_asset_hdr.earlier_dep_limit_amount   :=rec.earlier_dep_limit_amount ;
      lv_xx_fa_conv_asset_hdr.earlier_life_in_months     :=rec.earlier_life_in_months ;
      lv_xx_fa_conv_asset_hdr.earlier_basic_rate         :=rec.earlier_basic_rate ;
      lv_xx_fa_conv_asset_hdr.earlier_adjusted_rate      :=rec.earlier_adjusted_rate ;
      lv_xx_fa_conv_asset_hdr.request_id                 :=NVL(fnd_global.conc_request_id, -1);
      lv_xx_fa_conv_asset_hdr.created_by                 :=NVL(fnd_global.user_id,         -1);
      lv_xx_fa_conv_asset_hdr.creation_date              :=SYSDATE;
      lv_xx_fa_conv_asset_hdr.last_updated_by            :=NVL(fnd_global.user_id,   -1);
      lv_xx_fa_conv_asset_hdr.last_update_login          :=NVL(fnd_global.login_id , -1);
      lv_xx_fa_conv_asset_hdr.last_update_date           := SYSDATE;
      lv_xx_fa_conv_asset_hdr.status                     :=v_status ;
      lv_xx_fa_conv_asset_hdr.error_description          :=v_error_msg;
      INSERT INTO xx_fa_conv_asset_hdr VALUES lv_xx_fa_conv_asset_hdr;
      v_rec_count    :=v_rec_count    +1;
      v_success_count:=v_success_count+1;
    EXCEPTION
    WHEN OTHERS THEN
      lc_errormsg := 'In Procedure generic_tax_parent_asset_hdr.Error to insert into XX_FA_CONV_ASSET_HDR for Asset Id:'||rec.Interface_Line_Number || '. SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE ;
      print_debug_msg (lc_errormsg, true);
      v_failure_count:=v_failure_count+1;
    END;
    IF v_rec_count>5000 THEN
      COMMIT;
      v_rec_count:=0;
    END IF;
  END LOOP;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
END generic_tax_parent_asset_hdr;
PROCEDURE generic_tax_child_asset_hdr
  (
    p_book_type_code VARCHAR2
  )
IS
  CURSOR c_tax_child_asset_hdr
  IS
    SELECT
      /*+ parallel(8) */
      Interface_Line_Number,
      Asset_Book,
      Transaction_Name,
      Asset_Number,
      Asset_Description ,
      Tag_Number,
      Manufacturer,
      Serial_Number,
      Model ,
      Asset_Type,
      Cost,
      Date_Placed_in_Service,
      Prorate_Convention,
      Asset_Units,
      Asset_Category_Segment1,
      Asset_Category_Segment2,
      Asset_Category_Segment3,
      Asset_Category_Segment4,
      Asset_Category_Segment5,
      Asset_Category_Segment6,
      Asset_Category_Segment7,
      'POST' Posting_Status,
      'NEW' Queue_Name,
      'ORACLE FBDI' Feeder_System,
      Parent_Asset,
      NULL Add_to_Asset,
      NULL Asset_Key_Segment1,
      NULL Asset_Key_Segment2,
      NULL Asset_Key_Segment3,
      NULL Asset_Key_Segment4,
      NULL Asset_Key_Segment5,
      NULL Asset_Key_Segment6,
      NULL Asset_Key_Segment7,
      NULL Asset_Key_Segment8,
      NULL Asset_Key_Segment9,
      NULL Asset_Key_Segment10,
      In_physical_inventory,
      Property_Type,
      PROPERTY_CLASS,
      --           fa_details.distribution_id,  -- Moved to end by Arun
      In_use,
      Ownership,
      Bought,
      NULL MATERIAL_INDICATOR,
      COMMITMENT ,
      INVESTMENT_LAW, --arunadded
      Amortize,
      Amortization_Start_Date,
      Depreciate,
      Salvage_Value_Type,
      Salvage_Value_Amount,
      Salvage_Value_Percent,
      YTD_Depreciation,
      Depreciation_Reserve,
      YTD_Bonus_Depreciation,
      Bonus_Depreciation_Reserve,
      YTD_IMPAIRMENT ,
      IMPAIRMENT_RESERVE ,
      Depreciation_Method ,
      LIFE_IN_MONTHS ,
      BASIC_RATE ,
      ADJUSTED_RATE ,
      UNIT_OF_MEASURE ,
      PRODUCTION_CAPACITY ,
      Ceiling_Type,
      BONUS_RULE ,
      NULL CASH_GENERATING_UNIT ,
      Depreciation_Limit_Type,
      Depreciation_Limit_Percent,
      Depreciation_Limit_Amount,
      NULL INVOICE_COST,
      (SELECT xx_gl_beacon_mapping_f1(gcc.segment1,'ENTITY','A')--ENTITY
      FROM gl_code_combinations gcc,
        fa_distribution_accounts da
      WHERE da.distribution_id    = fa_details.distribution_id
      AND da.book_type_code       = fa_details.asset_book
      AND gcc.code_combination_id = da.asset_clearing_account_ccid
      )cost_clearing_account_seg1,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment6,'LOB','A')----LOB
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg2,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment2,'COST_CENTER','A')------COST CENTER
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg3,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment3,'ACCOUNT','A')----ACCOUNT
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg4,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment4,'LOCATION','A')---LOCATION
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg5,
    (SELECT xx_gl_beacon_mapping_f1(gcc.segment5,'ENTITY','A')-----INTERCOMP
    FROM gl_code_combinations gcc,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.asset_book
    AND gcc.code_combination_id = da.asset_clearing_account_ccid
    ) cost_clearing_account_seg6,
    NULL cost_clearing_account_seg7,
    NULL Cost_Clearing_Account_Seg8,
    NULL Cost_Clearing_Account_Seg9,
    NULL COST_CLEARING_ACCOUNT_SEG10,
    NULL Cost_Clearing_Account_Seg11,
    NULL Cost_Clearing_Account_Seg12,
    NULL Cost_Clearing_Account_Seg13,
    NULL Cost_Clearing_Account_Seg14,
    NULL COST_CLEARING_ACCOUNT_SEG15,
    /*           NULL                            CLEARING_ACCT_SEGMENT16,
    NULL                            CLEARING_ACCT_SEGMENT17,
    NULL                            CLEARING_ACCT_SEGMENT18,
    NULL                            CLEARING_ACCT_SEGMENT19,
    NULL                            CLEARING_ACCT_SEGMENT20,
    NULL                            CLEARING_ACCT_SEGMENT21,
    NULL                            CLEARING_ACCT_SEGMENT22,
    NULL                            CLEARING_ACCT_SEGMENT23,
    NULL                            CLEARING_ACCT_SEGMENT24,
    NULL                            CLEARING_ACCT_SEGMENT25,
    NULL                            CLEARING_ACCT_SEGMENT26,
    NULL                            CLEARING_ACCT_SEGMENT27,
    NULL                            CLEARING_ACCT_SEGMENT28,
    NULL                            CLEARING_ACCT_SEGMENT29,
    NULL                            CLEARING_ACCT_SEGMENT30,
    */
    fa_details.ATTRIBUTE1,
    fa_details.ATTRIBUTE2,
    fa_details.ATTRIBUTE3,
    fa_details.ATTRIBUTE4,
    fa_details.ATTRIBUTE5,
    fa_details.ATTRIBUTE6,
    fa_details.ATTRIBUTE7,
    fa_details.ATTRIBUTE8,
    fa_details.ATTRIBUTE9,
    fa_details.ATTRIBUTE10,
    fa_details.ATTRIBUTE11,
    fa_details.ATTRIBUTE12,
    NULL ATTRIBUTE13,
    fa_details.ATTRIBUTE14,
    fa_details.ATTRIBUTE15,
    /*
    NULL                            ATTRIBUTE16,
    NULL                            ATTRIBUTE17,
    NULL                            ATTRIBUTE18,
    NULL                            ATTRIBUTE19,
    NULL                            ATTRIBUTE20,
    NULL                            ATTRIBUTE21,
    NULL                            ATTRIBUTE22,
    NULL                            ATTRIBUTE23,
    NULL                            ATTRIBUTE24,
    NULL                            ATTRIBUTE25,
    NULL                            ATTRIBUTE26,
    NULL                            ATTRIBUTE27,
    NULL                            ATTRIBUTE28,
    NULL                            ATTRIBUTE29,
    NULL                            ATTRIBUTE30,
    NULL                            ATTRIBUTE_NUMBER1,
    NULL                            ATTRIBUTE_NUMBER2,
    NULL                            ATTRIBUTE_NUMBER3,
    NULL                            ATTRIBUTE_NUMBER4,
    NULL                            ATTRIBUTE_NUMBER5,
    NULL                            ATTRIBUTE_DATE1,
    NULL                            ATTRIBUTE_DATE2,
    NULL                            ATTRIBUTE_DATE3,
    NULL                            ATTRIBUTE_DATE4,
    NULL                            ATTRIBUTE_DATE5,
    */
    ATTRIBUTE_CATEGORY_CODE,
    NULL context,
    /*
    NULL                            TH_ATTRIBUTE1,
    NULL                            TH_ATTRIBUTE2,
    NULL                            TH_ATTRIBUTE3,
    NULL                            TH_ATTRIBUTE4,
    NULL                            TH_ATTRIBUTE5,
    NULL                            TH_ATTRIBUTE6,
    NULL                            TH_ATTRIBUTE7,
    NULL                            TH_ATTRIBUTE8,
    NULL                            TH_ATTRIBUTE9,
    NULL                            TH_ATTRIBUTE10,
    NULL                            TH_ATTRIBUTE11,
    NULL                            TH_ATTRIBUTE12,
    NULL                            TH_ATTRIBUTE13,
    NULL                            TH_ATTRIBUTE14,
    NULL                            TH_ATTRIBUTE15,
    NULL                            TH_ATTRIBUTE_NUMBER1,
    NULL                            TH_ATTRIBUTE_NUMBER2,
    NULL                            TH_ATTRIBUTE_NUMBER3,
    NULL                            TH_ATTRIBUTE_NUMBER4,
    NULL                            TH_ATTRIBUTE_NUMBER5,
    NULL                            TH_ATTRIBUTE_DATE1,
    NULL                            TH_ATTRIBUTE_DATE2,
    NULL                            TH_ATTRIBUTE_DATE3,
    NULL                            TH_ATTRIBUTE_DATE4,
    NULL                            TH_ATTRIBUTE_DATE5,
    NULL                            TH_ATTRIBUTE_CATEGORY_CODE,
    NULL                            TH2_ATTRIBUTE1,
    NULL                            TH2_ATTRIBUTE2,
    NULL                            TH2_ATTRIBUTE3,
    NULL                            TH2_ATTRIBUTE4,
    NULL                            TH2_ATTRIBUTE5,
    NULL                            TH2_ATTRIBUTE6,
    NULL                            TH2_ATTRIBUTE7,
    NULL                            TH2_ATTRIBUTE8,
    NULL                            TH2_ATTRIBUTE9,
    NULL                            TH2_ATTRIBUTE10,
    NULL                            TH2_ATTRIBUTE11,
    NULL                            TH2_ATTRIBUTE12,
    NULL                            TH2_ATTRIBUTE13,
    NULL                            TH2_ATTRIBUTE14,
    NULL                            TH2_ATTRIBUTE15,
    NULL                            TH2_ATTRIBUTE_NUMBER1,
    NULL                            TH2_ATTRIBUTE_NUMBER2,
    NULL                            TH2_ATTRIBUTE_NUMBER3,
    NULL                            TH2_ATTRIBUTE_NUMBER4,
    NULL                            TH2_ATTRIBUTE_NUMBER5,
    NULL                            TH2_ATTRIBUTE_DATE1,
    NULL                            TH2_ATTRIBUTE_DATE2,
    NULL                            TH2_ATTRIBUTE_DATE3,
    NULL                            TH2_ATTRIBUTE_DATE4,
    NULL                            TH2_ATTRIBUTE_DATE5,
    NULL                            TH2_ATTRIBUTE_CATEGORY_CODE,
    NULL                            AI_ATTRIBUTE1,
    NULL                            AI_ATTRIBUTE2,
    NULL                            AI_ATTRIBUTE3,
    NULL                            AI_ATTRIBUTE4,
    NULL                            AI_ATTRIBUTE5,
    NULL                            AI_ATTRIBUTE6,
    NULL                            AI_ATTRIBUTE7,
    NULL                            AI_ATTRIBUTE8,
    NULL                            AI_ATTRIBUTE9,
    NULL                            AI_ATTRIBUTE10,
    NULL                            AI_ATTRIBUTE11,
    NULL                            AI_ATTRIBUTE12,
    NULL                            AI_ATTRIBUTE13,
    NULL                            AI_ATTRIBUTE14,
    NULL                            AI_ATTRIBUTE15,
    NULL                            AI_ATTRIBUTE_NUMBER1,
    NULL                            AI_ATTRIBUTE_NUMBER2,
    NULL                            AI_ATTRIBUTE_NUMBER3,
    NULL                            AI_ATTRIBUTE_NUMBER4,
    NULL                            AI_ATTRIBUTE_NUMBER5,
    NULL                            AI_ATTRIBUTE_DATE1,
    NULL                            AI_ATTRIBUTE_DATE2,
    NULL                            AI_ATTRIBUTE_DATE3,
    NULL                            AI_ATTRIBUTE_DATE4,
    NULL                            AI_ATTRIBUTE_DATE5,
    NULL                            AI_ATTRIBUTE_CATEGORY_CODE,
    */
    NULL Mass_Property_Eligible,
    NULL Group_Asset,
    NULL Reduction_Rate,
    NULL Apply_Reduction_Rate_to_Addi,
    NULL Apply_Reduction_Rate_to_Adj,
    NULL Apply_Reduction_Rate_to_Reti,
    NULL Recognize_Gain_or_Loss,
    NULL Recapture_Excess_Reserve,
    NULL Limit_Net_Proceeds_to_Cost,
    NULL Terminal_Gain_or_Loss,
    NULL Tracking_Method,
    NULL Allocate_Excess_Depreciation,
    NULL Depreciate_By,
    NULL Member_Rollup,
    NULL Allo_to_Full_Reti_and_Res_Asst,
    NULL Over_Depreciate,
    NULL PREPARER,
    --           NULL                            MERGED_LEVEL,        commented by arun
    --           NULL                            Parent_Intf_Line_no,  commented by arun
    NULL Sum_Merged_Units,
    NULL New_Master,
    NULL Units_to_Adjust,
    NULL Short_year,
    NULL Conversion_Date,
    NULL ORIGINAL_DEP_START_DATE,
    /*        NULL                            GLOBAL_ATTRIBUTE1,
    NULL                            GLOBAL_ATTRIBUTE2,
    NULL                            GLOBAL_ATTRIBUTE3,
    NULL                            GLOBAL_ATTRIBUTE4,
    NULL                            GLOBAL_ATTRIBUTE5,
    NULL                            GLOBAL_ATTRIBUTE6,
    NULL                            GLOBAL_ATTRIBUTE7,
    NULL                            GLOBAL_ATTRIBUTE8,
    NULL                            GLOBAL_ATTRIBUTE9,
    NULL                            GLOBAL_ATTRIBUTE10,
    NULL                            GLOBAL_ATTRIBUTE11,
    NULL                            GLOBAL_ATTRIBUTE12,
    NULL                            GLOBAL_ATTRIBUTE13,
    NULL                            GLOBAL_ATTRIBUTE14,
    NULL                            GLOBAL_ATTRIBUTE15,
    NULL                            GLOBAL_ATTRIBUTE16,
    NULL                            GLOBAL_ATTRIBUTE17,
    NULL                            GLOBAL_ATTRIBUTE18,
    NULL                            GLOBAL_ATTRIBUTE19,
    NULL                            GLOBAL_ATTRIBUTE20,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER1,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER2,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER3,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER4,
    NULL                            GLOBAL_ATTRIBUTE_NUMBER5,
    NULL                            GLOBAL_ATTRIBUTE_DATE1,
    NULL                            GLOBAL_ATTRIBUTE_DATE2,
    NULL                            GLOBAL_ATTRIBUTE_DATE3,
    NULL                            GLOBAL_ATTRIBUTE_DATE4,
    NULL                            GLOBAL_ATTRIBUTE_DATE5,
    NULL                            GLOBAL_ATTRIBUTE_CATEGORY,
    */
    NBV_at_the_Time_of_Switch,
    NULL Period_Fully_Reserved,
    NULL Start_Period_of_Extended_Dep,
    Earlier_Dep_Limit_Type,
    Earlier_Dep_Limit_Percent,
    Earlier_Dep_Limit_Amount,
    NULL Earlier_Depreciation_Method ,
    Earlier_Life_in_Months,
    Earlier_Basic_Rate,
    EARLIER_ADJUSTED_RATE,
    --          NULL                            ASSET_SCHEDULE_IDENTIFIER,  commented by arun
    NULL Lease_Number,
    NULL Revaluation_Reserve,
    NULL Revaluation_Loss,
    NULL Reval_Reser_Amortization_Basis,
    NULL Impairment_Loss_Expense,
    NULL Revaluation_Cost_Ceiling,
    NULL FAIR_VALUE,
    NULL LAST_USED_PRICE_INDEX_VALUE,
    NULL Supplier_Name,
    NULL Supplier_Number,
    NULL Purchase_Order_Number,
    NULL Invoice_Number,
    NULL Invoice_Voucher_Number,
    NULL Invoice_Date,
    NULL Payables_Units,
    NULL Invoice_Line_Number,
    NULL Invoice_Line_Type,
    NULL Invoice_Line_Description,
    NULL Invoice_Payment_Number,
    NULL Project_Number,
    NULL Task_Number,
    NULL FULLY_DEPRECIATE,
    FA_DETAILS.distribution_id
  FROM
    (SELECT
      /*+ full(ds) full(fth) */
      fab.asset_id interface_line_number,
      fb.book_type_code asset_book,
      fth.transaction_type_code transaction_name,
      fab.asset_number asset_number,
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(fat.description,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' '),chr(34),' inch') Asset_Description,
      fab.tag_number tag_number,
      fab.manufacturer_name manufacturer,
      REPLACE(fab.serial_number,chr(44),chr(124)) serial_number,
      fab.model_number model ,
      fab.asset_type asset_type,
      fb.cost cost,
      TO_CHAR(fb.DATE_PLACED_IN_SERVICE,'YYYY/MM/DD') Date_Placed_in_Service,
      fb.prorate_convention_code prorate_convention,
      fab.current_units asset_units,
      fcb.segment1 asset_category_segment1,
      fcb.segment2 asset_category_segment2,
      fcb.segment3 asset_category_segment3,
      fcb.segment4 asset_category_segment4,
      fcb.segment5 asset_category_segment5,
      fcb.segment6 asset_category_segment6,
      fcb.segment7 asset_category_segment7,
      (SELECT xxfss.ASSET_ID
      FROM xx_fa_status xxfss
      WHERE xxfss.asset_id     =fab.parent_asset_id
      AND xxfss.book_type_code = fb.book_type_code
      AND xxfss.asset_status   = 'ACTIVE'
      ) Parent_Asset,
      fab.inventorial in_physical_inventory,
      fab.property_type_code property_type,
      fab.property_1245_1250_code property_class,
      fab.in_use_flag in_use,
      fab.owned_leased ownership,
      fab.new_used bought,
      fab.commitment ,
      fab.investment_law, -- added by arun
      'NO' amortize,
      TO_CHAR(fth.date_effective,'YYYY/MM/DD') Amortization_Start_Date,
      fb.depreciate_flag depreciate,
      fb.salvage_type salvage_value_type,
      fb.salvage_value salvage_value_amount,
      fb.percent_salvage_value salvage_value_percent,
      DECODE(TO_NUMBER(TO_CHAR(ds.deprn_run_date,'RRRR')),2020,xfs.YTD_DEPRN,0) YTD_Depreciation,
      xfs.deprn_rsv depreciation_reserve,
      ds.bonus_ytd_deprn ytd_bonus_depreciation,
      ds.bonus_deprn_reserve bonus_depreciation_reserve,
      ds.ytd_impairment ,
      ds.impairment_reserve ,
      fb.deprn_method_code depreciation_method ,
      fb.life_in_months ,
      fb.basic_rate ,
      fb.adjusted_rate ,
      fb.unit_of_measure ,
      fb.production_capacity ,
      fb.ceiling_name ceiling_type,
      fb.bonus_rule ,
      fb.deprn_limit_type depreciation_limit_type,
      fb.allowed_deprn_limit depreciation_limit_percent,
      fb.allowed_deprn_limit_amount depreciation_limit_amount,
      fab.attribute1 attribute1,
      fab.attribute2 attribute2,
      fab.attribute3 attribute3,
      fab.attribute4 attribute4,
      fab.attribute5 attribute5,
      fab.attribute6 attribute6,
      fab.attribute7 attribute7,
      fab.attribute8 attribute8,
      fab.attribute9 attribute9,
      fab.attribute10 attribute10,
      fab.attribute11 attribute11,
      fab.attribute12 attribute12,	  
      fab.attribute14 attribute14,	  
      fab.attribute15 attribute15,	  	  
      fab.attribute_category_code,
      fb.nbv_at_switch nbv_at_the_time_of_switch,
      fb.prior_deprn_limit_type earlier_dep_limit_type,
      fb.prior_deprn_limit earlier_dep_limit_percent,
      fb.prior_deprn_limit_amount earlier_dep_limit_amount,
      fb.prior_life_in_months earlier_life_in_months,
      fb.prior_basic_rate earlier_basic_rate,
      fb.prior_adjusted_rate earlier_adjusted_rate,
      ddtl.distribution_id
    FROM fa_books fb,
      xx_fa_status xfs,
      fa_book_controls corpbook,
      fa_additions_b fab,
      fa_categories_b fcb,
      fa_additions_tl fat,
      fa_deprn_summary ds,
      fa_deprn_detail ddtl,
      fa_transaction_headers fth
    WHERE 1                =1
    AND xfs.book_type_code =p_book_type_code
    AND asset_status       ='ACTIVE'
    AND fb.book_type_code      =xfs.book_type_code
    AND fb.asset_id            = xfs.asset_id
    AND corpbook.book_type_code=FB.book_type_code
    AND corpbook.BOOK_CLASS    = 'TAX'
    AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
    AND fb.date_ineffective IS NULL
	AND fab.ASSET_ID=fb.ASSET_ID
    AND NOT EXISTS
      (SELECT 'x' FROM FA_ADDITIONS_B WHERE parent_asset_id = fab.ASSET_ID
      )
    AND fcb.category_id           =fab.asset_category_id
    AND fat.asset_id              =fab.asset_id
    AND fat.language              = 'US'
    AND ds.asset_id               =fb.asset_id
    AND ds.book_type_code         =fb.book_type_code
    AND fth.asset_id              = fab.asset_id
    AND fth.book_type_code        = corpbook.book_type_code
    AND fth.transaction_type_code = 'ADDITION'
    AND ds.period_counter         =
      (SELECT MAX(DS1.PERIOD_COUNTER)
      FROM fa_deprn_summary ds1
      WHERE ds1.asset_id     =ds.asset_id
      AND ds1.book_type_code = ds.book_type_code
      )
    AND ddtl.asset_id       =fth.asset_id
    AND ddtl.book_type_code =fth.book_type_code
    AND ddtl.period_counter =ds.period_counter
    AND ddtl.distribution_id=
      (SELECT MAX(distribution_id)
      FROM FA_DEPRN_DETAIL
      WHERE asset_id    =ddtl.asset_id
      AND book_type_code=ddtl.book_type_code
      AND period_counter=ddtl.period_counter
      )
    )FA_DETAILS;

CURSOR c_gcc(p_dist_id NUMBER,p_book VARCHAR2)
IS
SELECT 
	gcc.segment1 gcompany,
	gcc.segment6 glob,
	gcc.segment2 gcostcenter,
	gcc.segment3 gaccount,
	gcc.segment4 glocation,
	gcc.segment5 gintercompany
  FROM gl_code_combinations gcc,
       fa_distribution_accounts da
 WHERE da.distribution_id = p_dist_id
   AND da.book_type_code  = p_book
   AND gcc.code_combination_id = da.asset_clearing_account_ccid;
	
  lc_file_handle utl_file.file_type;
  lv_line_count    NUMBER;
  l_file_name      VARCHAR2(500);
  lv_col_title     VARCHAR2(5000);
  l_file_path      VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg      VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  v_book_type_code VARCHAR2(100);
  v_rec_count      NUMBER:=0;
  v_success_count  NUMBER:=0;
  v_failure_count  NUMBER:=0;
  v_segment1       VARCHAR2(50);
  v_segment2       VARCHAR2(50);
  v_segment3       VARCHAR2(50);
  v_segment4       VARCHAR2(50);
  v_segment5       VARCHAR2(50);
  v_segment6       VARCHAR2(50);
  v_status         VARCHAR2(1);
  v_error_msg      VARCHAR2(100);
  lv_xx_fa_conv_asset_hdr xx_fa_conv_asset_hdr%ROWTYPE;

  v_gcompany       VARCHAR2(50);
  v_glob	       VARCHAR2(50);
  v_gcostcenter    VARCHAR2(50);
  v_gaccount       VARCHAR2(50);
  v_glocation      VARCHAR2(50);
  v_gintercompany  VARCHAR2(50);
  
BEGIN
  FOR rec IN c_tax_child_asset_hdr
  LOOP
    v_segment1                        :=NULL;
    v_segment2                        :=NULL;
    v_segment3                        :=NULL;
    v_segment4                        :=NULL;
    v_segment5                        :=NULL;
    v_segment6                        :=NULL;
    v_status                          :='N';
    v_error_msg                       :=NULL;

    v_gcompany       				  :=NULL;
    v_glob	       		:=NULL;
    v_gcostcenter    	:=NULL;
    v_gaccount       	:=NULL;
    v_glocation      	:=NULL;
    v_gintercompany  	:=NULL;

    IF rec.cost_clearing_account_seg1 IS NULL OR rec.cost_clearing_account_seg2 IS NULL OR rec.cost_clearing_account_seg3 IS NULL OR rec.cost_clearing_account_seg4 IS NULL OR rec.cost_clearing_account_seg5 IS NULL OR rec.cost_clearing_account_seg6 IS NULL THEN
      v_segment1                      :=gc_entity;
      v_segment2                      :=gc_lob;
      v_segment3                      :=gc_costcenter;
      v_segment4                      :=gc_account;
      v_segment5                      :=gc_location;
      v_segment6                      :=gc_ic;
      v_status                        :='C';
      --v_error_msg                     :='CTU Mapping Failure';

	  OPEN c_gcc(rec.distribution_id,rec.asset_book);
	  FETCH c_gcc 
	   INTO v_gcompany,v_glob,v_gcostcenter,v_gaccount,v_glocation,v_gintercompany;
	  CLOSE c_gcc;
	 /*
   	  print_debug_msg ('Dist id :'||to_char(rec.distribution_id), true);
	  print_debug_msg ('Company  :'||v_gcompany, true);
	  print_debug_msg ('LOB      :'||v_glob, true);
	  print_debug_msg ('CC       :'||v_gcostcenter, true);
	  print_debug_msg ('Acct     :'||v_gaccount, true);
	  print_debug_msg ('Loc      :'||v_glocation, true);
	  print_debug_msg ('Interco  :'||v_gintercompany, true);	  
    */
      ctu_mapping_validation( 'ASSET_HDR', 
							   v_gcompany,
							   v_glob,
							   v_gcostcenter,
							   v_gaccount,
							   v_glocation,
							   v_gintercompany,							   
							   rec.cost_clearing_account_seg1, 
							   rec.cost_clearing_account_seg2, 
							   rec.cost_clearing_account_seg3, 
							   rec.cost_clearing_account_seg4, 
							   rec.cost_clearing_account_seg5, 
							   rec.cost_clearing_account_seg6, 
							   rec.interface_line_number, 
							   rec.asset_book, 
							   v_error_msg );
	  ELSE
      v_segment1:=rec.cost_clearing_account_seg1;
      v_segment2:=rec.cost_clearing_account_seg2;
      v_segment3:=rec.cost_clearing_account_seg3;
      v_segment4:=rec.cost_clearing_account_seg4;
      v_segment5:=rec.cost_clearing_account_seg5;
      v_segment6:=rec.cost_clearing_account_seg6;
    END IF;
    BEGIN
      lv_xx_fa_conv_asset_hdr                            :=NULL ;
      lv_xx_fa_conv_asset_hdr.asset_id                   :=rec.interface_line_number ;
      lv_xx_fa_conv_asset_hdr.book_type_code             :=rec.asset_book ;
      lv_xx_fa_conv_asset_hdr.asset_attribute_category   :='CHILD' ;
      lv_xx_fa_conv_asset_hdr.transaction_name           :=rec.transaction_name ;
      lv_xx_fa_conv_asset_hdr.asset_number               :=rec.asset_number ;
      lv_xx_fa_conv_asset_hdr.asset_description          :=rec.asset_description ;
      lv_xx_fa_conv_asset_hdr.tag_number                 :=rec.tag_number ;
      lv_xx_fa_conv_asset_hdr.manufacturer               :=rec.manufacturer ;
      lv_xx_fa_conv_asset_hdr.serial_number              :=rec.serial_number ;
      lv_xx_fa_conv_asset_hdr.model                      :=rec.model ;
      lv_xx_fa_conv_asset_hdr.asset_type                 :=rec.asset_type ;
      lv_xx_fa_conv_asset_hdr.cost                       :=rec.cost ;
      lv_xx_fa_conv_asset_hdr.date_placed_in_service     :=rec.date_placed_in_service ;
      lv_xx_fa_conv_asset_hdr.prorate_convention         :=rec.prorate_convention ;
      lv_xx_fa_conv_asset_hdr.asset_units                :=rec.asset_units ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment1    :=rec.asset_category_segment1 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment2    :=rec.asset_category_segment2 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment3    :=rec.asset_category_segment3 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment4    :=rec.asset_category_segment4 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment5    :=rec.asset_category_segment5 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment6    :=rec.asset_category_segment6 ;
      lv_xx_fa_conv_asset_hdr.asset_category_segment7    :=rec.asset_category_segment7 ;
      lv_xx_fa_conv_asset_hdr.parent_asset               :=rec.parent_asset ;
      lv_xx_fa_conv_asset_hdr.in_physical_inventory      :=rec.in_physical_inventory ;
      lv_xx_fa_conv_asset_hdr.property_type              :=rec.property_type ;
      lv_xx_fa_conv_asset_hdr.property_class             :=rec.property_class ;
      lv_xx_fa_conv_asset_hdr.in_use                     :=rec.in_use ;
      lv_xx_fa_conv_asset_hdr.ownership                  :=rec.ownership ;
      lv_xx_fa_conv_asset_hdr.bought                     :=rec.bought ;
      lv_xx_fa_conv_asset_hdr.commitment                 :=rec.commitment ;
      lv_xx_fa_conv_asset_hdr.investment_law             :=rec.investment_law ;
      lv_xx_fa_conv_asset_hdr.amortize                   :=rec.amortize ;
      lv_xx_fa_conv_asset_hdr.amortization_start_date    :=rec.amortization_start_date ;
      lv_xx_fa_conv_asset_hdr.depreciate                 :=rec.depreciate ;
      lv_xx_fa_conv_asset_hdr.salvage_value_type         :=rec.salvage_value_type ;
      lv_xx_fa_conv_asset_hdr.salvage_value_amount       :=rec.salvage_value_amount ;
      lv_xx_fa_conv_asset_hdr.salvage_value_percent      :=rec.salvage_value_percent ;
      lv_xx_fa_conv_asset_hdr.ytd_depreciation           :=rec.ytd_depreciation ;
      lv_xx_fa_conv_asset_hdr.depreciation_reserve       :=rec.depreciation_reserve ;
      lv_xx_fa_conv_asset_hdr.ytd_bonus_depreciation     :=rec.ytd_bonus_depreciation ;
      lv_xx_fa_conv_asset_hdr.bonus_depreciation_reserve :=rec.bonus_depreciation_reserve ;
      lv_xx_fa_conv_asset_hdr.ytd_impairment             :=rec.ytd_impairment ;
      lv_xx_fa_conv_asset_hdr.impairment_reserve         :=rec.impairment_reserve ;
      lv_xx_fa_conv_asset_hdr.depreciation_method        :=rec.depreciation_method ;
      lv_xx_fa_conv_asset_hdr.life_in_months             :=rec.life_in_months ;
      lv_xx_fa_conv_asset_hdr.basic_rate                 :=rec.basic_rate ;
      lv_xx_fa_conv_asset_hdr.adjusted_rate              :=rec.adjusted_rate ;
      lv_xx_fa_conv_asset_hdr.unit_of_measure            :=rec.unit_of_measure ;
      lv_xx_fa_conv_asset_hdr.production_capacity        :=rec.production_capacity ;
      lv_xx_fa_conv_asset_hdr.ceiling_type               :=rec.ceiling_type ;
      lv_xx_fa_conv_asset_hdr.bonus_rule                 :=rec.bonus_rule ;
      lv_xx_fa_conv_asset_hdr.depreciation_limit_type    :=rec.depreciation_limit_type ;
      lv_xx_fa_conv_asset_hdr.depreciation_limit_percent :=rec.depreciation_limit_percent ;
      lv_xx_fa_conv_asset_hdr.depreciation_limit_amount  :=rec.depreciation_limit_amount ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg1 :=v_segment1;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg2 :=v_segment2 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg3 :=v_segment3 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg4 :=v_segment4 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg5 :=v_segment5 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg6 :=v_segment6 ;
      lv_xx_fa_conv_asset_hdr.cost_clearing_account_seg7 :=rec.cost_clearing_account_seg7 ;
      lv_xx_fa_conv_asset_hdr.attribute1                 :=rec.attribute1 ;
      lv_xx_fa_conv_asset_hdr.attribute2                 :=rec.attribute2 ;
      lv_xx_fa_conv_asset_hdr.attribute3                 :=rec.attribute3 ;
      lv_xx_fa_conv_asset_hdr.attribute4                 :=rec.attribute4 ;
      lv_xx_fa_conv_asset_hdr.attribute5                 :=rec.attribute5 ;
      lv_xx_fa_conv_asset_hdr.attribute6                 :=rec.attribute6 ;
      lv_xx_fa_conv_asset_hdr.attribute7                 :=rec.attribute7 ;
      lv_xx_fa_conv_asset_hdr.attribute8                 :=rec.attribute8 ;
      lv_xx_fa_conv_asset_hdr.attribute9                 :=rec.attribute9 ;
      lv_xx_fa_conv_asset_hdr.attribute10                :=rec.attribute10 ;
      lv_xx_fa_conv_asset_hdr.attribute11                :=rec.attribute11 ;
      lv_xx_fa_conv_asset_hdr.attribute12                :=rec.attribute12 ;
      lv_xx_fa_conv_asset_hdr.attribute13                :=rec.attribute13 ;
      lv_xx_fa_conv_asset_hdr.attribute14                :=rec.attribute14 ;
      lv_xx_fa_conv_asset_hdr.attribute15                :=rec.attribute15 ;	  
      lv_xx_fa_conv_asset_hdr.attribute_category_code    :=rec.attribute_category_code ;
      lv_xx_fa_conv_asset_hdr.nbv_at_the_time_of_switch  :=rec.nbv_at_the_time_of_switch ;
      lv_xx_fa_conv_asset_hdr.earlier_dep_limit_type     :=rec.earlier_dep_limit_type ;
      lv_xx_fa_conv_asset_hdr.earlier_dep_limit_percent  :=rec.earlier_dep_limit_percent ;
      lv_xx_fa_conv_asset_hdr.earlier_dep_limit_amount   :=rec.earlier_dep_limit_amount ;
      lv_xx_fa_conv_asset_hdr.earlier_life_in_months     :=rec.earlier_life_in_months ;
      lv_xx_fa_conv_asset_hdr.earlier_basic_rate         :=rec.earlier_basic_rate ;
      lv_xx_fa_conv_asset_hdr.earlier_adjusted_rate      :=rec.earlier_adjusted_rate ;
      lv_xx_fa_conv_asset_hdr.request_id                 :=NVL(fnd_global.conc_request_id, -1);
      lv_xx_fa_conv_asset_hdr.created_by                 :=NVL(fnd_global.user_id,         -1);
      lv_xx_fa_conv_asset_hdr.creation_date              :=SYSDATE;
      lv_xx_fa_conv_asset_hdr.last_updated_by            :=NVL(fnd_global.user_id,   -1);
      lv_xx_fa_conv_asset_hdr.last_update_login          :=NVL(fnd_global.login_id , -1);
      lv_xx_fa_conv_asset_hdr.last_update_date           :=SYSDATE;
      lv_xx_fa_conv_asset_hdr.status                     :=v_status ;
      lv_xx_fa_conv_asset_hdr.error_description          :=v_error_msg;
      INSERT INTO xx_fa_conv_asset_hdr VALUES lv_xx_fa_conv_asset_hdr;
      v_rec_count    :=v_rec_count    +1;
      v_success_count:=v_success_count+1;
    EXCEPTION
    WHEN OTHERS THEN
      lc_errormsg := 'In Procedure generic_tax_child_asset_hdr.Error to insert into XX_FA_CONV_ASSET_HDR for Asset Id:'||rec.Interface_Line_Number || '. SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE ;
      print_debug_msg (lc_errormsg, true);
      v_failure_count:=v_failure_count+1;
    END;
    IF v_rec_count>5000 THEN
      COMMIT;
      v_rec_count:=0;
    END IF;
  END LOOP;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
END generic_tax_child_asset_hdr;
PROCEDURE generic_tax_parent_dist
  (
    p_book_type_code VARCHAR2
  )
IS
  CURSOR c_tax_par_dist
  IS
    SELECT
      /*+ parallel(16) */
      interface_line_number,
      units_assigned,
      NULL employee_email_address,
      asset_location_segment1,
      asset_location_segment2,
      asset_location_segment3,
      asset_location_segment4,
      asset_location_segment6 asset_location_segment5,
      SUBSTR(asset_location_segment5,2) asset_location_segment6,
      asset_location_segment7,
		gcompany,
		glob,
		gcostcenter,
		gaccount,
		glocation,
		gintercompany,	  
      exp_acct_segment1
      ||'.'
      || exp_acct_segment6
      ||'.'
      || exp_acct_segment2
      ||'.'
      || exp_acct_segment3
      ||'.'
      || exp_acct_segment4
      ||'.'
      || exp_acct_segment5 expense_account_segment,
      exp_acct_segment1,
      exp_acct_segment2,
      exp_acct_segment3,
      exp_acct_segment4,
      exp_acct_segment5,
      exp_acct_segment6,
      code_combination_id
    FROM
      (SELECT
        /*+ full(ds) full(fth) */
        fb.asset_id interface_line_number,
        fd.units_assigned units_assigned,
        NULL employee_email_address,
        loc.segment1 asset_location_segment1,
        loc.segment2 asset_location_segment2,
        loc.segment3 asset_location_segment3,
        loc.segment4 asset_location_segment4,
        loc.segment5 asset_location_segment5,
        loc.segment6 asset_location_segment6,
        loc.segment7 asset_location_segment7,
		gcc.segment1 gcompany,
		gcc.segment6 glob,
		gcc.segment2 gcostcenter,
		gcc.segment3 gaccount,
		gcc.segment4 glocation,
		gcc.segment5 gintercompany,
        xx_gl_beacon_mapping_f1(gcc.segment1,'ENTITY','A') exp_acct_segment1,
        xx_gl_beacon_mapping_f1(gcc.segment2,'COST_CENTER','A') exp_acct_segment2,
        xx_gl_beacon_mapping_f1(gcc.segment3,'ACCOUNT','A') exp_acct_segment3,
        xx_gl_beacon_mapping_f1(gcc.segment4,'LOCATION','A') exp_acct_segment4,
        xx_gl_beacon_mapping_f1(gcc.segment5,'ENTITY','A') exp_acct_segment5,
        xx_gl_beacon_mapping_f1(gcc.segment6,'LOB','A') exp_acct_segment6,
        gcc.segment7 exp_acct_segment7,
        gcc.segment8 exp_acct_segment8,
        gcc.segment9 exp_acct_segment9,
        gcc.segment10 exp_acct_segment10,
        gcc.segment11 exp_acct_segment11,
        gcc.segment12 exp_acct_segment12,
        gcc.segment13 exp_acct_segment13,
        gcc.segment14 exp_acct_segment14,
        gcc.segment15 exp_acct_segment15,
        gcc.segment16 exp_acct_segment16,
        gcc.segment17 exp_acct_segment17,
        gcc.segment18 exp_acct_segment18,
        gcc.segment19 exp_acct_segment19,
        gcc.segment20 exp_acct_segment20,
        gcc.segment21 exp_acct_segment21,
        gcc.segment22 exp_acct_segment22,
        gcc.segment23 exp_acct_segment23,
        gcc.segment24 exp_acct_segment24,
        gcc.segment25 exp_acct_segment25,
        gcc.segment26 exp_acct_segment26,
        gcc.segment27 exp_acct_segment27,
        gcc.segment28 exp_acct_segment28,
        gcc.segment29 exp_acct_segment29,
        gcc.segment30 exp_acct_segment30,
        gcc.code_combination_id
      FROM fa_transaction_headers fth,
        fa_deprn_summary ds,
        fa_categories_b fcb,
        gl_code_combinations gcc,
        fa_locations loc,
        fa_distribution_history fd,
        fa_books fb,
        xx_fa_status xfs,
        fa_book_controls corpbook,
        fa_additions_b fab
      WHERE 1                =1
      AND xfs.book_type_code =p_book_type_code
      AND xfs.ASSET_STATUS   ='ACTIVE'
      AND corpbook.book_type_code=xfs.book_type_code
      AND corpbook.BOOK_CLASS    = 'TAX'
      AND fab.asset_id           =xfs.asset_id
      AND fab.parent_asset_id   IS NULL
      AND EXISTS
        (SELECT 'x' FROM fa_additions_b WHERE parent_asset_id = fab.ASSET_ID
        )
    AND fb.book_type_code=xfs.book_type_code
    AND fb.asset_id      = xfs.asset_id
    AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
    AND fb.date_ineffective IS NULL	
    AND fd.asset_id               =fb.asset_id
    AND fd.date_ineffective      IS NULL
    AND fd.book_type_code         ='OD US CORP'
    AND loc.location_id           =fd.location_id
    AND gcc.code_combination_id   = fd.code_combination_id
    AND fcb.category_id           =fab.asset_category_id
    AND fth.ASSET_ID              = fab.ASSET_ID
    AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
    AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
    AND ds.asset_id               =fb.asset_id
    AND ds.book_type_code         =fb.book_type_code
    AND ds.period_counter         =
      (SELECT MAX(ds1.period_counter)
      FROM fa_deprn_summary ds1
      WHERE ds1.asset_id     =ds.asset_id
      AND ds1.book_type_code = ds.book_type_code
      )
      )
    ORDER BY Interface_Line_Number;
    lc_file_handle utl_file.file_type;
    lv_line_count    NUMBER;
    l_file_path      VARCHAR(200);
    l_file_name      VARCHAR2(500);
    lv_col_title     VARCHAR2(5000);
    l_file_path      VARCHAR2(500):='XXFIN_OUTBOUND';
    lc_errormsg      VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
    v_book_type_code VARCHAR2(100);
    v_rec_count      NUMBER:=0;
    v_success_count  NUMBER:=0;
    v_failure_count  NUMBER:=0;
    v_status         VARCHAR2(1);
    v_error_msg      VARCHAR2(100);
    lc_coa           VARCHAR2(50);
    lv_xx_fa_conv_asset_dtl xx_fa_conv_asset_dtl%ROWTYPE;
  BEGIN
    FOR rec IN c_tax_par_dist
    LOOP
      lc_coa                   :=NULL;
      v_status                 :='N';
      v_error_msg              :=NULL;
      IF rec.exp_acct_segment1 IS NULL OR rec.exp_acct_segment2 IS NULL OR rec.exp_acct_segment3 IS NULL OR rec.exp_acct_segment4 IS NULL OR rec.exp_acct_segment5 IS NULL OR rec.exp_acct_segment6 IS NULL THEN
        lc_coa                 :=gc_entity||'.'||gc_lob||'.'||gc_costcenter||'.'||gc_account||'.'||gc_location||'.'||gc_ic;
        v_status               :='C';
        --v_error_msg            :='CTU Mapping Failure';
		ctu_mapping_validation( 'ASSET_DISTR', 
								 rec.gcompany,
								 rec.glob,
								 rec.gcostcenter,
								 rec.gaccount,
								 rec.glocation,
								 rec.gintercompany,
								 rec.exp_acct_segment1, 
								 rec.exp_acct_segment6, 
								 rec.exp_acct_segment2, 
								 rec.exp_acct_segment3, 
								 rec.exp_acct_segment4, 
								 rec.exp_acct_segment5, 
								 rec.interface_line_number, 
								 p_book_type_code, 
								 v_error_msg );		
      ELSE
        lc_coa:=rec.expense_account_segment;
      END IF;
      BEGIN
        lv_XX_FA_CONV_ASSET_DTL                          :=NULL ;
        lv_XX_FA_CONV_ASSET_DTL.Asset_id                 :=rec.Interface_Line_Number ;
        lv_XX_FA_CONV_ASSET_DTL.Book_type_code           :=p_book_type_code ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_ATTRIBUTE_CATEGORY :='PARENT' ;
        lv_XX_FA_CONV_ASSET_DTL.UNITS_ASSIGNED           :=rec.UNITS_ASSIGNED ;
        lv_XX_FA_CONV_ASSET_DTL.Employee_Email_Address   :=rec.Employee_Email_Address ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT1  :=rec.ASSET_LOCATION_SEGMENT1 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT2  :=rec.ASSET_LOCATION_SEGMENT2 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT3  :=rec.ASSET_LOCATION_SEGMENT3 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT4  :=rec.ASSET_LOCATION_SEGMENT4 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT5  :=rec.ASSET_LOCATION_SEGMENT5 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT6  :=rec.ASSET_LOCATION_SEGMENT6 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT7  :=rec.ASSET_LOCATION_SEGMENT7 ;
        lv_XX_FA_CONV_ASSET_DTL.EXPENSE_ACCOUNT_SEGMENT  :=lc_coa ;
        lv_XX_FA_CONV_ASSET_DTL.REQUEST_ID               :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
        lv_XX_FA_CONV_ASSET_DTL.CREATED_BY               :=NVL(FND_GLOBAL.USER_ID,         -1);
        lv_XX_FA_CONV_ASSET_DTL.CREATION_DATE            :=SYSDATE;
        lv_XX_FA_CONV_ASSET_DTL.LAST_UPDATED_BY          :=NVL(FND_GLOBAL.USER_ID,   -1);
        lv_XX_FA_CONV_ASSET_DTL.LAST_UPDATE_LOGIN        :=NVL(FND_GLOBAL.LOGIN_ID , -1);
        lv_XX_FA_CONV_ASSET_DTL.LAST_UPDATE_DATE         :=SYSDATE;
        lv_XX_FA_CONV_ASSET_DTL.STATUS                   :=v_status;
        lv_XX_FA_CONV_ASSET_DTL.ERROR_DESCRIPTION        :=v_error_msg;
        INSERT INTO XX_FA_CONV_ASSET_DTL VALUES lv_XX_FA_CONV_ASSET_DTL;
        v_rec_count    :=v_rec_count    +1;
        v_success_count:=v_success_count+1;
      EXCEPTION
      WHEN OTHERS THEN
        lc_errormsg := 'In Procedure generic_tax_parent_dist.Error to insert into XX_FA_CONV_ASSET_DTL for Asset Id:'||rec.Interface_Line_Number || '. SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE ;
        print_debug_msg (lc_errormsg, true);
        v_failure_count:=v_failure_count+1;
      END;
      IF v_rec_count>5000 THEN
        COMMIT;
        v_rec_count:=0;
      END IF;
    END LOOP;
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
  END generic_tax_parent_dist;
PROCEDURE generic_tax_child_dist
  (
    p_book_type_code VARCHAR2
  )
IS
  CURSOR c_tax_child_dist
  IS
    SELECT
      /*+ parallel(16) */
      interface_line_number,
      units_assigned,
      NULL employee_email_address,
      asset_location_segment1,
      asset_location_segment2,
      asset_location_segment3,
      asset_location_segment4,
      asset_location_segment6 asset_location_segment5,
      SUBSTR(asset_location_segment5,2) asset_location_segment6,
      asset_location_segment7,
		gcompany,
		glob,
		gcostcenter,
		gaccount,
		glocation,
		gintercompany,	  
      exp_acct_segment1
      ||'.'
      || exp_acct_segment6
      ||'.'
      || exp_acct_segment2
      ||'.'
      || exp_acct_segment3
      ||'.'
      || exp_acct_segment4
      ||'.'
      || exp_acct_segment5 expense_account_segment,
      exp_acct_segment1,
      exp_acct_segment2,
      exp_acct_segment3,
      exp_acct_segment4,
      exp_acct_segment5,
      exp_acct_segment6,
      code_combination_id
    FROM
      (SELECT
        /*+ full(ds) full(fth) */
        fb.asset_id interface_line_number,
        fd.units_assigned units_assigned,
        NULL employee_email_address,
        loc.segment1 asset_location_segment1,
        loc.segment2 asset_location_segment2,
        loc.segment3 asset_location_segment3,
        loc.segment4 asset_location_segment4,
        loc.segment5 asset_location_segment5,
        loc.segment6 asset_location_segment6,
        loc.segment7 asset_location_segment7,
		gcc.segment1 gcompany,
		gcc.segment6 glob,
		gcc.segment2 gcostcenter,
		gcc.segment3 gaccount,
		gcc.segment4 glocation,
		gcc.segment5 gintercompany,
        xx_gl_beacon_mapping_f1(gcc.segment1,'ENTITY','A') exp_acct_segment1,
        xx_gl_beacon_mapping_f1(gcc.segment2,'COST_CENTER','A') exp_acct_segment2,
        xx_gl_beacon_mapping_f1(gcc.segment3,'ACCOUNT','A') exp_acct_segment3,
        xx_gl_beacon_mapping_f1(gcc.segment4,'LOCATION','A') exp_acct_segment4,
        xx_gl_beacon_mapping_f1(gcc.segment5,'ENTITY','A') exp_acct_segment5,
        xx_gl_beacon_mapping_f1(gcc.segment6,'LOB','A') exp_acct_segment6,
        gcc.segment7 exp_acct_segment7,
        gcc.segment8 exp_acct_segment8,
        gcc.segment9 exp_acct_segment9,
        gcc.segment10 exp_acct_segment10,
        gcc.segment11 exp_acct_segment11,
        gcc.segment12 exp_acct_segment12,
        gcc.segment13 exp_acct_segment13,
        gcc.segment14 exp_acct_segment14,
        gcc.segment15 exp_acct_segment15,
        gcc.segment16 exp_acct_segment16,
        gcc.segment17 exp_acct_segment17,
        gcc.segment18 exp_acct_segment18,
        gcc.segment19 exp_acct_segment19,
        gcc.segment20 exp_acct_segment20,
        gcc.segment21 exp_acct_segment21,
        gcc.segment22 exp_acct_segment22,
        gcc.segment23 exp_acct_segment23,
        gcc.segment24 exp_acct_segment24,
        gcc.segment25 exp_acct_segment25,
        gcc.segment26 exp_acct_segment26,
        gcc.segment27 exp_acct_segment27,
        gcc.segment28 exp_acct_segment28,
        gcc.segment29 exp_acct_segment29,
        gcc.segment30 exp_acct_segment30,
        gcc.code_combination_id
      FROM fa_transaction_headers fth,
        fa_deprn_summary ds,
        fa_categories_b fcb,
        gl_code_combinations gcc,
        fa_locations loc,
        fa_distribution_history fd,
        fa_books fb,
        xx_fa_status xfs,
        fa_book_controls corpbook,
        fa_additions_b fab
      WHERE 1                =1
      AND xfs.book_type_code =p_book_type_code
      AND xfs.ASSET_STATUS   ='ACTIVE'
      AND fb.book_type_code =xfs.book_type_code
      AND fb.asset_id       = xfs.asset_id
      AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
      AND fb.date_ineffective IS NULL
      AND corpbook.book_type_code=FB.book_type_code
      AND corpbook.BOOK_CLASS    = 'TAX'
      AND fab.ASSET_ID           =fb.ASSET_ID
      AND NOT EXISTS
        (SELECT 'x' FROM FA_ADDITIONS_B WHERE PARENT_ASSET_ID = FAB.ASSET_ID
        )
    AND fd.asset_id          =fb.asset_id
    AND fd.date_ineffective IS NULL
    AND fd.book_type_code    ='OD US CORP'
    AND TRUNC (sysdate) BETWEEN TRUNC (NVL (fd.date_effective, sysdate)) AND TRUNC (NVL (fd.date_ineffective, sysdate))
    AND loc.location_id           =fd.location_id
    AND gcc.code_combination_id   = fd.code_combination_id
    AND fcb.category_id           =fab.asset_category_id
    AND fth.ASSET_ID              = fab.ASSET_ID
    AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
    AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
    AND ds.asset_id               =fb.asset_id
    AND ds.book_type_code         =fb.book_type_code
    AND DS.PERIOD_COUNTER         =
      (SELECT MAX(DS1.PERIOD_COUNTER)
      FROM FA_DEPRN_SUMMARY DS1
      WHERE DS1.ASSET_ID     =DS.ASSET_ID
      AND DS1.BOOK_TYPE_CODE = DS.BOOK_TYPE_CODE
      )
      )
    ORDER BY interface_line_number;
    lc_file_handle utl_file.file_type;
    lv_line_count   NUMBER;
    l_file_name     VARCHAR2(500);
    lv_col_title    VARCHAR2(5000);
    l_file_path     VARCHAR2(500):='XXFIN_OUTBOUND';
    lc_errormsg     VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
    v_rec_count     NUMBER:=0;
    v_success_count NUMBER:=0;
    v_failure_count NUMBER:=0;
    v_status        VARCHAR2(1);
    v_error_msg     VARCHAR2(100);
    lc_coa          VARCHAR2(50);
    lv_xx_fa_conv_asset_dtl xx_fa_conv_asset_dtl%ROWTYPE;
  BEGIN
    FOR rec IN c_tax_child_dist
    LOOP
      lc_coa                   :=NULL;
      v_status                 :='N';
      v_error_msg              :=NULL;
      IF rec.exp_acct_segment1 IS NULL OR rec.exp_acct_segment2 IS NULL OR rec.exp_acct_segment3 IS NULL OR rec.exp_acct_segment4 IS NULL OR rec.exp_acct_segment5 IS NULL OR rec.exp_acct_segment6 IS NULL THEN
        lc_coa                 :=gc_entity||'.'||gc_lob||'.'||gc_costcenter||'.'||gc_account||'.'||gc_location||'.'||gc_ic;
        v_status               :='C';
        -- v_error_msg            :='CTU Mapping Failure';
		ctu_mapping_validation( 'ASSET_DISTR', 
								 rec.gcompany,
								 rec.glob,
								 rec.gcostcenter,
								 rec.gaccount,
								 rec.glocation,
								 rec.gintercompany,
								 rec.exp_acct_segment1, 
								 rec.exp_acct_segment6, 
								 rec.exp_acct_segment2, 
								 rec.exp_acct_segment3, 
								 rec.exp_acct_segment4, 
								 rec.exp_acct_segment5, 
								 rec.interface_line_number, 
								 p_book_type_code, 
								 v_error_msg );		
      ELSE
        lc_coa:=rec.expense_account_segment;
      END IF;
      BEGIN
        lv_XX_FA_CONV_ASSET_DTL                          :=NULL ;
        lv_XX_FA_CONV_ASSET_DTL.Asset_id                 :=rec.Interface_Line_Number ;
        lv_XX_FA_CONV_ASSET_DTL.Book_type_code           :=p_book_type_code ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_ATTRIBUTE_CATEGORY :='CHILD' ;
        lv_XX_FA_CONV_ASSET_DTL.UNITS_ASSIGNED           :=rec.UNITS_ASSIGNED ;
        lv_XX_FA_CONV_ASSET_DTL.Employee_Email_Address   :=rec.Employee_Email_Address ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT1  :=rec.ASSET_LOCATION_SEGMENT1 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT2  :=rec.ASSET_LOCATION_SEGMENT2 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT3  :=rec.ASSET_LOCATION_SEGMENT3 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT4  :=rec.ASSET_LOCATION_SEGMENT4 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT5  :=rec.ASSET_LOCATION_SEGMENT5 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT6  :=rec.ASSET_LOCATION_SEGMENT6 ;
        lv_XX_FA_CONV_ASSET_DTL.ASSET_LOCATION_SEGMENT7  :=rec.ASSET_LOCATION_SEGMENT7 ;
        lv_XX_FA_CONV_ASSET_DTL.EXPENSE_ACCOUNT_SEGMENT  :=lc_coa ;
        lv_XX_FA_CONV_ASSET_DTL.REQUEST_ID               :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
        lv_XX_FA_CONV_ASSET_DTL.CREATED_BY               :=NVL(FND_GLOBAL.USER_ID,         -1);
        lv_XX_FA_CONV_ASSET_DTL.CREATION_DATE            :=SYSDATE;
        lv_XX_FA_CONV_ASSET_DTL.LAST_UPDATED_BY          :=NVL(FND_GLOBAL.USER_ID,   -1);
        lv_XX_FA_CONV_ASSET_DTL.LAST_UPDATE_LOGIN        :=NVL(FND_GLOBAL.LOGIN_ID , -1);
        lv_XX_FA_CONV_ASSET_DTL.LAST_UPDATE_DATE         :=SYSDATE;
        lv_XX_FA_CONV_ASSET_DTL.STATUS                   :=v_status;
        lv_XX_FA_CONV_ASSET_DTL.ERROR_DESCRIPTION        :=v_error_msg;
        INSERT INTO xx_fa_conv_asset_dtl VALUES lv_xx_fa_conv_asset_dtl;
        v_rec_count    :=v_rec_count    +1;
        v_success_count:=v_success_count+1;
      EXCEPTION
      WHEN OTHERS THEN
        lc_errormsg := 'In Procedure generic_tax_child_dist.Error to insert into XX_FA_CONV_ASSET_DTL for Asset Id:'||rec.Interface_Line_Number || '. SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE ;
        print_debug_msg (lc_errormsg, true);
        v_failure_count:=v_failure_count+1;
      END;
      IF v_rec_count>5000 THEN
        COMMIT;
        v_rec_count:=0;
      END IF;
    END LOOP;
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
  END generic_tax_child_dist;
PROCEDURE generic_asset_validation
  (
    p_book_type_code VARCHAR2
  )
IS
  lc_file_handle utl_file.file_type;
  lv_line_count    NUMBER;
  l_file_name      VARCHAR2(500);
  lv_col_title     VARCHAR2(5000);
  l_file_path      VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg      VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
  v_book_type_code VARCHAR2(100);
  v_rec_count      NUMBER:=0;
  v_success_count  NUMBER:=0;
  v_failure_count  NUMBER:=0;
  v_segment1       VARCHAR2(50);
  v_segment2       VARCHAR2(50);
  v_segment3       VARCHAR2(50);
  v_segment4       VARCHAR2(50);
  v_segment5       VARCHAR2(50);
  v_segment6       VARCHAR2(50);
  v_status         VARCHAR2(1);
  v_error_msg      VARCHAR2(100);
  lv_xx_fa_conv_asset_hdr xx_fa_conv_asset_hdr%ROWTYPE;
  
  CURSOR cr_distinct_book_type
  IS
  SELECT DISTINCT book_type_Code 
    FROM XX_FA_CONV_ASSET_hdr 
   WHERE status='N';
  
  CURSOR cr_child_book_type(p_booktype VARCHAR2)
  IS
  SELECT DISTINCT book_type_Code
    FROM XX_FA_CONV_ASSET_hdr
   WHERE 1            =1
     AND book_type_Code<>p_booktype;
  
  CURSOR cr_main_book_type
  IS
  SELECT DISTINCT book_type_Code 
    FROM XX_FA_CONV_ASSET_hdr 
   where book_type_code='OD US CORP';
  
  CURSOR cr_assets_hdr(p_booktype VARCHAR2)
  IS
  SELECT asset_id 
    FROM XX_FA_CONV_ASSET_hdr 
   WHERE book_type_code=p_booktype;

  CURSOR cr_dist_units_assgn_val
  IS
  SELECT book_type_Code,
         asset_id,
         COUNT(1) total
    FROM XX_FA_CONV_ASSET_dtl
   WHERE UNITS_ASSIGNED<1
   GROUP BY book_type_Code,
            asset_id
  HAVING COUNT(1)>1
   ORDER BY book_type_Code,
            asset_id;
BEGIN
  print_debug_msg ('Package generic_tax_parent_asset_hdr START ', TRUE);
  print_debug_msg ('P_BOOK_TYPE_CODE '||p_book_type_code, TRUE);
  BEGIN
  
    lc_errormsg            :='Asset Distributions do not have parent asset that is valid';
    print_debug_msg(lc_errormsg);
    UPDATE xx_fa_conv_asset_dtl dtl
       SET status         ='Y',
           error_description=error_description||'~'||
		   'Asset Distributions do not have parent asset that is valid'
     WHERE 1=1
       AND NOT EXISTS
           (SELECT 1
              FROM xx_fa_conv_asset_hdr hdr
             WHERE hdr.asset_id    =dtl.asset_id
               AND hdr.book_type_code=dtl.book_type_code
           );
	COMMIT;
	  
    lc_errormsg:='Update Life in Months=1, cost=0 for life_in_months is null validation';
    print_debug_msg(lc_errormsg);
	
    UPDATE xx_fa_conv_asset_hdr
       SET 	--cost              =0 ,
           life_in_months      =1
     WHERE life_in_months IS NULL
       AND depreciation_method<>'UOP';
	COMMIT;
	
	/*UPDATE XX_FA_CONV_ASSET_hdr
       SET depreciation_method='STL'
     WHERE depreciation_method='UOP';
	COMMIT;
    */
	UPDATE xx_fa_conv_asset_dtl
	   SET asset_location_segment4='ST LOUIS'
	 WHERE asset_location_segment4='ST. LOUIS';
	COMMIT;
	
	UPDATE xx_fa_conv_asset_dtl
	   SET asset_location_segment4='S ARLINGTON'
	 WHERE asset_location_segment4='S.ARLINGTON';
	COMMIT;
	
	UPDATE xx_fa_conv_asset_dtl
	   SET asset_location_segment3='HAMPTON INDEP CITY'
	 WHERE asset_location_segment3='HAMPTON INDEP. CITY';
	COMMIT;

	UPDATE xx_fa_conv_asset_dtl
	   SET asset_location_segment3='NORFOLK INDEP CITY'
	 WHERE asset_location_segment3='NORFOLK INDEP. CITY';
	COMMIT;
	
	lc_errormsg          :='Update Distribution table for Units_Assigned<1 validation';
    print_debug_msg(lc_errormsg);
    
	FOR rec IN cr_dist_units_assgn_val
    LOOP
      UPDATE xx_fa_conv_asset_dtl
         SET units_assigned  =1
       WHERE book_type_Code=rec.book_type_Code
         AND asset_id        =rec.asset_id
         AND units_assigned  <1
         AND ROWNUM          <2;
      
	  UPDATE XX_FA_CONV_ASSET_DTL
         SET status         ='Y',
             ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||'UNITS_ASSIGNED is less than 1'
       WHERE book_type_Code=rec.book_type_Code
         AND asset_id        =rec.asset_id
         AND units_assigned  <1;
    END LOOP;
	COMMIT;
	
	lc_errormsg                          :='Update Parent table for DEPRECIATION_RESERVE>COST validation';
    print_debug_msg(lc_errormsg);
    
	UPDATE xx_fa_conv_asset_hdr
       SET depreciation_reserve=cost
     WHERE 1                 =1
       AND ABS(nvl(depreciation_reserve,0))>ABS(nvl(cost,0));
	COMMIT;
	
    lc_errormsg:='Update Parent table for YTD_DEPRECIATION>DEPRECIATION_RESERVE validation';
    print_debug_msg(lc_errormsg);
    
	UPDATE xx_fa_conv_asset_hdr
       SET ytd_depreciation=depreciation_reserve
     WHERE ABS(NVL(ytd_depreciation,0))  > ABS(NVL(depreciation_reserve,0));
	COMMIT;
    lc_errormsg            :='Update Parent table for YTD_DEPRECIATION<>DEPRECIATION_RESERVE validation where DPIS in current year';
    print_debug_msg(lc_errormsg);
    
	UPDATE xx_fa_conv_asset_hdr
       SET depreciation_reserve            =ytd_depreciation
     WHERE 1                               =1
       AND SUBSTR(date_placed_in_service,1,4)='2020'
       AND ABS(NVL(ytd_depreciation,0))   <> ABS(NVL(depreciation_reserve,0));
    COMMIT;
	
	UPDATE xx_fa_conv_asset_hdr a
       SET status         ='Y', 
		   error_description=error_description||'Asset does not exist in EBS'
     WHERE book_type_code='OD US CORP'
       AND NOT EXISTS ( SELECT 'x'
					      FROM fa_books
						 WHERE asset_id=a.asset_id
						   AND book_type_Code=a.book_type_code
	    			  );
	COMMIT;
	UPDATE xx_fa_conv_asset_hdr a
       SET status         ='Y', 
		   error_description=error_description||'Asset does not exist in EBS'
     WHERE book_type_code='OD US FED'
       AND NOT EXISTS ( SELECT 'x'
					      FROM fa_books
						 WHERE asset_id=a.asset_id
						   AND book_type_Code=a.book_type_code
	    			  );	
	COMMIT;					  
	UPDATE xx_fa_conv_asset_hdr a
       SET status         ='Y', 
		   error_description=error_description||'Asset does not exist in EBS'
     WHERE book_type_code='OD US STATE'
       AND NOT EXISTS ( SELECT 'x'
					      FROM fa_books
						 WHERE asset_id=a.asset_id
						   AND book_type_Code=a.book_type_code
	    			  );					  
	COMMIT;
	FOR main_book_type IN cr_main_book_type   
    LOOP
      BEGIN
        FOR child_book_type IN cr_child_book_type(main_book_type.book_type_Code)
        LOOP
          lc_errormsg:='Validation:Asset do not exists in'||child_book_type.book_type_Code;
          UPDATE xx_fa_conv_asset_hdr hdr
             SET status         ='Y',
                 error_description=error_description||'~'
                 ||'Asset do not exists in '
                 || child_book_type.book_type_Code
           WHERE book_type_code= child_book_type.book_type_code
             AND NOT EXISTS (SELECT 1
							   FROM xx_fa_conv_asset_hdr hdr1
							  WHERE hdr1.book_type_code=main_book_type.book_type_Code
								AND hdr1.asset_id        =hdr.asset_id
							);
        END LOOP;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          lc_errormsg := ( 'Error occured at location '||lc_errormsg || ' .Error Message :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
          print_debug_msg (lc_errormsg, TRUE);
      END;
    END LOOP;
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error occured at location '||lc_errormsg || ' .Error Message :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
  END;
  COMMIT;
  
  UPDATE xx_fa_conv_asset_dtl a
     SET status         ='Y', 
		 error_description=error_description||'~'||'PARENT ERROR'
   WHERE EXISTS ( SELECT 'x'
	  	            FROM xx_fa_conv_asset_hdr
				   WHERE asset_id=a.asset_id
				     AND book_type_Code=a.book_type_Code
					 AND status='Y'
		        );
   COMMIT;			
EXCEPTION
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in generic_asset_validation procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
END generic_asset_validation;
/*********************************************************************
* Function used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
*********************************************************************/
FUNCTION BEFOREREPORT
  RETURN BOOLEAN
IS
BEGIN
  RETURN TRUE;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR at XX_FA_CONV_EXTRACT_PKG.BeforeReport:- ' || SQLERRM);
END BEFOREREPORT;
/*********************************************************************
* Main Function to derive the Asset Error Details
* Calls Sub procedures to derive the Error Description for each Asset
*********************************************************************/
FUNCTION XX_FA_ASSET_ERROR_DETAILS(
    P_BOOK_TYPEC VARCHAR2 )
  RETURN XX_FA_CONV_EXTRACT_PKG.ASSET_ERROR_DETAILS_TBL PIPELINED
IS
  CURSOR cr_asset_error_details
  IS
    SELECT *
    FROM
      (SELECT ASSET_NUMBER ,
        BOOK_TYPE_CODE ,
        ASSET_DESCRIPTION ,
        TRANSACTION_NAME ,
        ASSET_TYPE ,
        COST ,
        DEPRECIATION_RESERVE ,
        YTD_DEPRECIATION ,
        LIFE_IN_MONTHS ,
        ASSET_UNITS ,
        DATE_PLACED_IN_SERVICE,
        NULL UNITS_ASSIGNED ,
        'LIFE_IN_MONTHS is null' ERROR_DESCRIPTION
      FROM XX_FA_CONV_ASSET_hdr
      WHERE ERROR_DESCRIPTION LIKE '%LIFE_IN_MONTHS is null%'
    UNION ALL
    SELECT ASSET_NUMBER ,
      BOOK_TYPE_CODE ,
      ASSET_DESCRIPTION ,
      TRANSACTION_NAME ,
      ASSET_TYPE ,
      COST ,
      DEPRECIATION_RESERVE ,
      YTD_DEPRECIATION ,
      LIFE_IN_MONTHS ,
      ASSET_UNITS ,
      DATE_PLACED_IN_SERVICE,
      NULL UNITS_ASSIGNED ,
      'DEPRECIATION_RESERVE is greater than COST' ERROR_DESCRIPTION
    FROM XX_FA_CONV_ASSET_hdr
    WHERE ERROR_DESCRIPTION LIKE '%DEPRECIATION_RESERVE is greater than COST%'
    UNION ALL
    SELECT ASSET_NUMBER ,
      BOOK_TYPE_CODE ,
      ASSET_DESCRIPTION ,
      TRANSACTION_NAME ,
      ASSET_TYPE ,
      COST ,
      DEPRECIATION_RESERVE ,
      YTD_DEPRECIATION ,
      LIFE_IN_MONTHS ,
      ASSET_UNITS ,
      DATE_PLACED_IN_SERVICE,
      NULL UNITS_ASSIGNED ,
      'YTD_DEPRECIATION is greater than DEPRECIATION_RESERVE' ERROR_DESCRIPTION
    FROM XX_FA_CONV_ASSET_hdr
    WHERE ERROR_DESCRIPTION LIKE '%YTD_DEPRECIATION is greater than DEPRECIATION_RESERVE%'
    UNION ALL
    SELECT ASSET_NUMBER ,
      BOOK_TYPE_CODE ,
      ASSET_DESCRIPTION ,
      TRANSACTION_NAME ,
      ASSET_TYPE ,
      COST ,
      DEPRECIATION_RESERVE ,
      YTD_DEPRECIATION ,
      LIFE_IN_MONTHS ,
      ASSET_UNITS ,
      DATE_PLACED_IN_SERVICE,
      NULL UNITS_ASSIGNED ,
      'Asset do not have distribution' ERROR_DESCRIPTION
    FROM XX_FA_CONV_ASSET_hdr
    WHERE ERROR_DESCRIPTION LIKE '%Asset do not have distribution%'
    UNION ALL
    SELECT ASSET_NUMBER ,
      BOOK_TYPE_CODE ,
      ASSET_DESCRIPTION ,
      TRANSACTION_NAME ,
      ASSET_TYPE ,
      COST ,
      DEPRECIATION_RESERVE ,
      YTD_DEPRECIATION ,
      LIFE_IN_MONTHS ,
      ASSET_UNITS ,
      DATE_PLACED_IN_SERVICE,
      NULL UNITS_ASSIGNED ,
      'DEPRECIATION_RESERVE and YTD_DEPRECIATION is same for DATE_PLACED_IN_SERVICE in current year(2020)' ERROR_DESCRIPTION
    FROM XX_FA_CONV_ASSET_hdr
    WHERE ERROR_DESCRIPTION LIKE '%DEPRECIATION_RESERVE and YTD_DEPRECIATION is same for DATE_PLACED_IN_SERVICE in current year(2020)%'
    UNION ALL
    SELECT ASSET_NUMBER ,
      BOOK_TYPE_CODE ,
      ASSET_DESCRIPTION ,
      TRANSACTION_NAME ,
      ASSET_TYPE ,
      COST ,
      DEPRECIATION_RESERVE ,
      YTD_DEPRECIATION ,
      LIFE_IN_MONTHS ,
      ASSET_UNITS ,
      DATE_PLACED_IN_SERVICE,
      NULL UNITS_ASSIGNED ,
      'CTU Mapping Failure' ERROR_DESCRIPTION
    FROM XX_FA_CONV_ASSET_hdr
    WHERE ERROR_DESCRIPTION LIKE '%CTU Mapping Failure%'
      )
    ORDER BY book_type_code,
      asset_number,
      error_description;
    N           NUMBER := 0;
    lc_errormsg VARCHAR2(1000);
    lv_err_msg  VARCHAR2(1000);
  TYPE ASSET_ERROR_DETAILS_TYPE
IS
  TABLE OF XX_FA_CONV_EXTRACT_PKG.ASSET_ERROR_DETAILS_REC INDEX BY PLS_INTEGER;
  L_ASSET_ERROR_DETAILS_TYPE ASSET_ERROR_DETAILS_TYPE;
  CURSOR cr_asset_distr_error_details
  IS
    SELECT *
    FROM
      (SELECT asset_id,
        book_type_Code,
        units_assigned,
        'CTU Mapping Failure' ERROR_DESCRIPTION
      FROM XX_FA_CONV_ASSET_dtl
      WHERE ERROR_DESCRIPTION LIKE '%CTU Mapping Failure%'
    UNION ALL
    SELECT asset_id,
      book_type_Code,
      units_assigned,
      'UNITS_ASSIGNED is less than 1' ERROR_DESCRIPTION
    FROM XX_FA_CONV_ASSET_dtl
    WHERE ERROR_DESCRIPTION LIKE '%UNITS_ASSIGNED is less than 1%'
    UNION ALL
    SELECT asset_id,
      book_type_Code,
      units_assigned,
      'Asset Distributions not found in Additions' ERROR_DESCRIPTION
    FROM XX_FA_CONV_ASSET_dtl
    WHERE ERROR_DESCRIPTION LIKE '%Asset Distributions not found in Additions%'
      )
    ORDER BY book_type_Code,
      asset_id,
      error_description;
    CURSOR cr_distinct_book_type
    IS
      SELECT DISTINCT book_type_Code FROM XX_FA_CONV_ASSET_hdr ;
    CURSOR cr_asset_errors(p_err_msg VARCHAR2)
    IS
      SELECT ASSET_NUMBER ,
        BOOK_TYPE_CODE ,
        ASSET_DESCRIPTION ,
        TRANSACTION_NAME ,
        ASSET_TYPE ,
        COST ,
        DEPRECIATION_RESERVE ,
        YTD_DEPRECIATION ,
        LIFE_IN_MONTHS ,
        ASSET_UNITS ,
        DATE_PLACED_IN_SERVICE,
        NULL UNITS_ASSIGNED
      FROM XX_FA_CONV_ASSET_hdr
      WHERE error_description LIKE p_err_msg;
  BEGIN
    FOR rec IN cr_distinct_book_type
    LOOP
      lv_err_msg:='%Asset do not exists in '||rec.book_type_Code||'%';
      FOR asset_rec IN cr_asset_errors(lv_err_msg)
      LOOP
        L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_NUMBER           :=asset_rec.ASSET_NUMBER ;
        L_ASSET_ERROR_DETAILS_TYPE(N).BOOK_TYPE_CODE         :=asset_rec.BOOK_TYPE_CODE ;
        L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_DESCRIPTION      :=asset_rec.ASSET_DESCRIPTION ;
        L_ASSET_ERROR_DETAILS_TYPE(N).TRANSACTION_NAME       :=asset_rec.TRANSACTION_NAME ;
        L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_TYPE             :=asset_rec.ASSET_TYPE ;
        L_ASSET_ERROR_DETAILS_TYPE(N).COST                   :=asset_rec.COST ;
        L_ASSET_ERROR_DETAILS_TYPE(N).DEPRECIATION_RESERVE   :=asset_rec.DEPRECIATION_RESERVE ;
        L_ASSET_ERROR_DETAILS_TYPE(N).YTD_DEPRECIATION       :=asset_rec.YTD_DEPRECIATION ;
        L_ASSET_ERROR_DETAILS_TYPE(N).LIFE_IN_MONTHS         :=asset_rec.LIFE_IN_MONTHS ;
        L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_UNITS            :=asset_rec.ASSET_UNITS ;
        L_ASSET_ERROR_DETAILS_TYPE(N).DATE_PLACED_IN_SERVICE :=asset_rec.DATE_PLACED_IN_SERVICE ;
        L_ASSET_ERROR_DETAILS_TYPE(N).UNITS_ASSIGNED         :=asset_rec.UNITS_ASSIGNED ;
        L_ASSET_ERROR_DETAILS_TYPE(N).ERROR_DESCRIPTION      :=lv_err_msg ;
        N                                                    :=N+1;
      END LOOP;
    END LOOP;
    FOR rec IN cr_asset_error_details
    LOOP
      L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_NUMBER           :=rec.ASSET_NUMBER ;
      L_ASSET_ERROR_DETAILS_TYPE(N).BOOK_TYPE_CODE         :=rec.BOOK_TYPE_CODE ;
      L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_DESCRIPTION      :=rec.ASSET_DESCRIPTION ;
      L_ASSET_ERROR_DETAILS_TYPE(N).TRANSACTION_NAME       :=rec.TRANSACTION_NAME ;
      L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_TYPE             :=rec.ASSET_TYPE ;
      L_ASSET_ERROR_DETAILS_TYPE(N).COST                   :=rec.COST ;
      L_ASSET_ERROR_DETAILS_TYPE(N).DEPRECIATION_RESERVE   :=rec.DEPRECIATION_RESERVE ;
      L_ASSET_ERROR_DETAILS_TYPE(N).YTD_DEPRECIATION       :=rec.YTD_DEPRECIATION ;
      L_ASSET_ERROR_DETAILS_TYPE(N).LIFE_IN_MONTHS         :=rec.LIFE_IN_MONTHS ;
      L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_UNITS            :=rec.ASSET_UNITS ;
      L_ASSET_ERROR_DETAILS_TYPE(N).DATE_PLACED_IN_SERVICE :=rec.DATE_PLACED_IN_SERVICE ;
      L_ASSET_ERROR_DETAILS_TYPE(N).UNITS_ASSIGNED         :=rec.UNITS_ASSIGNED ;
      L_ASSET_ERROR_DETAILS_TYPE(N).ERROR_DESCRIPTION      :=rec.ERROR_DESCRIPTION ;
      N                                                    :=N+1;
    END LOOP;
    FOR rec IN cr_asset_distr_error_details
    LOOP
      L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_NUMBER           :=rec.asset_id ;
      L_ASSET_ERROR_DETAILS_TYPE(N).BOOK_TYPE_CODE         :=rec.BOOK_TYPE_CODE ;
      L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_DESCRIPTION      :=NULL ;
      L_ASSET_ERROR_DETAILS_TYPE(N).TRANSACTION_NAME       :=NULL ;
      L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_TYPE             :=NULL ;
      L_ASSET_ERROR_DETAILS_TYPE(N).COST                   :=NULL ;
      L_ASSET_ERROR_DETAILS_TYPE(N).DEPRECIATION_RESERVE   :=NULL ;
      L_ASSET_ERROR_DETAILS_TYPE(N).YTD_DEPRECIATION       :=NULL ;
      L_ASSET_ERROR_DETAILS_TYPE(N).LIFE_IN_MONTHS         :=NULL ;
      L_ASSET_ERROR_DETAILS_TYPE(N).ASSET_UNITS            :=NULL ;
      L_ASSET_ERROR_DETAILS_TYPE(N).DATE_PLACED_IN_SERVICE :=NULL ;
      L_ASSET_ERROR_DETAILS_TYPE(N).UNITS_ASSIGNED         :=rec.UNITS_ASSIGNED ;
      L_ASSET_ERROR_DETAILS_TYPE(N).ERROR_DESCRIPTION      :=rec.ERROR_DESCRIPTION ;
      N                                                    :=N+1;
    END LOOP;
    FOR I IN L_ASSET_ERROR_DETAILS_TYPE.FIRST .. L_ASSET_ERROR_DETAILS_TYPE.LAST
    LOOP
      PIPE ROW ( L_ASSET_ERROR_DETAILS_TYPE(I) ) ;
    END LOOP;
    RETURN;
  EXCEPTION
  WHEN OTHERS THEN
    lc_errormsg := ( 'Exception occured in Main procedure: SQLERRM'|| SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
  END;

PROCEDURE update_fa_dff(p_book_type IN VARCHAR2) 
IS
CURSOR C1 IS
SELECT a.asset_number,
       a.rowid arowid,
	   b.segment1,
	   b.task_number,
	   b.cip_acct,
	   b.period_name
  FROM xx_fa_proj_assets b,
	   xx_fa_conv_asset_hdr	a   
 WHERE a.book_type_code=p_book_type
   AND b.asset_number=a.asset_number;
BEGIN
  FOR cur IN C1 LOOP
    UPDATE xx_fa_conv_asset_hdr
	   SET attribute1=cur.segment1,
		   attribute2=cur.task_number,
		   attribute3=cur.cip_acct,
		   attribute4=cur.period_name
     WHERE rowid=cur.arowid;
  END LOOP;  
  COMMIT;
END update_fa_dff;  
  
PROCEDURE xx_fa_proj_asset
IS
CURSOR C1 
IS 
SELECT p.segment1,t.task_number,xx_gl_beacon_mapping_f1(gcc.concatenated_segments,NULL,'P') cip_acct,g.recvr_gl_period_name,ppa.asset_number
  FROM pa_Project_Asset_Assignments paa,
	   pa_project_assets_all ppa,
	   gl_code_combinations_kfv gcc,
       pa_cost_distribution_lines_all g,
	   pa_expenditure_items_all e,	
       pa_tasks t,
	   pa_projects_all p
 WHERE 
   1=1
   AND p.template_flag            = 'N'
   AND NVL(p.closed_date,sysdate) > to_date('31-DEC-2018','dd-mon-yyyy')
   AND (    p.segment1 NOT LIKE 'PB%'
        AND p.segment1 NOT LIKE 'NB%'
        AND p.segment1 NOT LIKE 'TEM%'
       )
   AND p.project_type NOT IN ('PB_PROJECT','DI_PB_PROJECT')
   AND project_status_code   IN ('APPROVED','CLOSED','1000')
   AND p.org_id           <>403
   AND ppa.project_id=p.project_id        
   AND ppa.asset_number IS NOT NULL
   --AND ppa.project_asset_type = 'ESTIMATED'
   AND paa.project_asset_id=ppa.project_asset_id
   AND paa.task_id=t.task_id
   and paa.project_id=t.project_id
   AND p.created_from_project_id IN  ( SELECT project_id
											FROM pa_projects_all
										   WHERE template_flag='Y'
										)

 
   AND t.project_id=p.project_id
   AND t.chargeable_flag='Y'
   AND t.billable_flag='Y'
   AND e.project_id=p.project_id
   AND e.task_id=t.task_id
   AND e.expenditure_item_id= (SELECT MIN(expenditure_item_id)
							     FROM pa_expenditure_items_all pei
						        WHERE pei.project_id=t.project_id
                                  AND pei.task_id=t.task_id
						      )  
   AND g.expenditure_item_id=e.expenditure_item_id
   AND g.line_type       = 'R'
   AND g.line_num        = (SELECT MAX(line_num)
							  FROM pa_cost_distribution_lines_all d
						     WHERE d.expenditure_item_id = e.expenditure_item_id
							   AND d.line_type           = 'R'
						   )   
   AND gcc.code_combination_id=g.dr_code_combination_id
order by p.segment1,t.task_number;
i  NUMBER:=0;
lc_errormsg VARCHAR2(2000);
BEGIN
  FOR cur IN C1 LOOP
    i:=i+1;
	IF i>5000 THEN
	   COMMIT;
	   i:=0;
	END IF;
    BEGIN
	  INSERT 
	    INTO xx_fa_proj_assets 
			 ( segment1,
			   task_number,
			   cip_acct,
			   period_name,
			   asset_number
			 )
	  VALUES 
	        ( cur.segment1,
			  cur.task_number,
			  cur.cip_acct,
			  cur.recvr_gl_period_name,
			  cur.asset_number
			);
	EXCEPTION
	  WHEN others THEN
	    NULL;
	END;
  END LOOP;
  COMMIT;
EXCEPTION   
WHEN OTHERS THEN
  ROLLBACK;
  lc_errormsg := 'Unhandled Exception occured in xx_fa_proj_asset :'||' SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE ;
  print_debug_msg (lc_errormsg, true);
END xx_fa_proj_asset; 
  
  
PROCEDURE xx_od_fa_con_script_wrapper(
    p_errbuf         VARCHAR2,
    p_retcode        NUMBER,
    P_module         VARCHAR2,
    p_book_type_code VARCHAR2,
    p_book_class     VARCHAR2,
    p_extract_type   VARCHAR2)
AS
  v_book_type_code VARCHAR2(50);
BEGIN
  IF p_module         ='FA' THEN
    IF p_extract_type ='TABLE_EXTRACT' THEN
      IF p_book_class = 'TAX' THEN
        generic_tax_parent_asset_hdr(p_book_type_code);
        generic_tax_child_asset_hdr(p_book_type_code);
        generic_tax_parent_dist(p_book_type_code);
        generic_tax_child_dist(p_book_type_code);
      ELSE
        generic_parent_assets_hdr(p_book_type_code);
        generic_child_assets_hdr(p_book_type_code);
        generic_parent_distribution(p_book_type_code);
        generic_child_distribution(p_book_type_code);
		update_fa_dff(p_book_type_code);
      END IF;
    elsif p_extract_type='FILE_EXTRACT' THEN
      generic_file_extract_asset_hdr(p_book_type_code,'PARENT');
      generic_file_extract_asset_hdr(p_book_type_code,'CHILD');
      generic_file_extract_distr(p_book_type_code,'PARENT');
      generic_file_extract_distr(p_book_type_code,'CHILD');
    elsif p_extract_type='VALIDATION' THEN
      generic_asset_validation(p_book_type_code);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  --  LC_ERRORMSG := ('Error in XX_FA_CONV_EXTRACT_PKG_WRAPPER procedure :- ' || ' OTHERS :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg ('Error in XX_FA_CONV_EXTRACT_PKG_WRAPPER procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE, TRUE);
END xx_od_fa_con_script_wrapper;
/**********************************************************************
* Main Procedure to Load Asset Depreciation Details to Custom Table.
***********************************************************************/
PROCEDURE XX_FA_ASSET_DEPR_EXTRACT(
    P_ERRBUF OUT VARCHAR2,
    p_retcode OUT NUMBER,
    P_BOOK_TYPE_CODE VARCHAR2)
AS
  CURSOR cur_active_assets(P_BOOK_TYPE_CODE VARCHAR2)
  IS
    SELECT
      /*+ parallel(a,3) */
      a.asset_id,
      DECODE(a.transaction_Type_code,'FULL RETIREMENT','RETIRED','ACTIVE') Asset_status,
      a.transaction_date_entered
    FROM fa_transaction_headers a
    WHERE 1                      =1
    AND a.book_type_code         =P_BOOK_TYPE_CODE
    AND a.transaction_header_id IN
      (SELECT MAX(fth1.transaction_header_id)
      FROM fa_transaction_headers fth1
      WHERE fth1.asset_id    =a.asset_id
      AND fth1.book_type_code=a.book_type_code
      ) 
    AND NOT EXISTS (select 'x'
            from fa_books fb
            where fb.asset_id=a.asset_id
            and fb.book_type_code='OD US CORP'
            and fb.deprn_method_code='UOP'
            );
  i                       NUMBER:=0;
  v_nbv                   NUMBER:=0;
  v_deprn_rsv             NUMBER;
  v_REVAL_RSV             NUMBER;
  v_YTD_DEPRN             NUMBER;
  v_YTD_REVAL_EXP         NUMBER;
  v_REVAL_DEPRN_EXP       NUMBER;
  v_DEPRN_EXP             NUMBER;
  v_REVAL_AMO             NUMBER;
  v_PROD                  NUMBER;
  v_YTD_PROD              NUMBER;
  v_LTD_PROD              NUMBER;
  v_ADJ_COST              NUMBER;
  v_REVAL_AMO_BASIS       NUMBER;
  v_BONUS_RATE            NUMBER;
  v_DEPRN_SOURCE_CODE     VARCHAR2(50);
  v_ADJUSTED_FLAG         BOOLEAN;
  v_TRANSACTION_HEADER_ID NUMBER;
  v_BONUS_DEPRN_RSV       NUMBER;
  v_BONUS_YTD_DEPRN       NUMBER;
  v_BONUS_DEPRN_AMOUNT    NUMBER;
  v_IMPAIRMENT_RSV        NUMBER;
  v_YTD_IMPAIRMENT        NUMBER;
  v_IMPAIRMENT_AMOUNT     NUMBER;
  v_CAPITAL_ADJUSTMENT    NUMBER;
  v_GENERAL_FUND          NUMBER;
  v_dummy_num             NUMBER;
  v_dummy_char            VARCHAR2(10);
  v_dummy_bool            BOOLEAN;
  l_impairment_rsv        NUMBER;
  lc_errormsg             VARCHAR2(2000):=NULL;
  v_success_count         NUMBER        :=0;
  v_failure_count         NUMBER        :=0;
BEGIN
  print_debug_msg('In Procedure XX_FA_ASSET_DEPR_EXTRACT.Start Time :'||TO_CHAR(SYSTIMESTAMP,'DD-MON-YYYY HH24:MI:SS.FF2 TZH:TZM'),TRUE);
  print_output('                                             OD Fixed Assets Derive Depreciation Values Program  ');
  print_output('                                            --------------------------------------------------');
  print_output('');
  print_output('');
  print_output('Parameters:');
  print_output('-------------:');
  print_output('Book Type Code                   :'||P_BOOK_TYPE_CODE);
  print_output('Concurrent Request ID                :'||fnd_global.conc_request_id);
  print_output('');
  print_output('');
  FOR cur IN cur_active_assets(P_BOOK_TYPE_CODE)
  LOOP
    v_ytd_deprn       :=NULL;
    v_deprn_rsv       :=NULL;
    v_reval_rsv       :=NULL;
    v_ytd_prod        :=NULL;
    v_ltd_prod        :=NULL;
    v_bonus_deprn_rsv :=NULL;
    v_bonus_ytd_deprn :=NULL;
    IF cur.asset_status='ACTIVE' THEN
      i               :=i+1;
      BEGIN
        fa_query_balances_pkg.query_balances( X_asset_id => cur.asset_id, X_book => P_BOOK_TYPE_CODE, X_period_ctr => 0, X_dist_id => 0, X_run_mode => 'STANDARD', X_cost => v_dummy_num, X_deprn_rsv => v_deprn_rsv, X_reval_rsv => v_reval_rsv, X_ytd_deprn => v_ytd_deprn, X_ytd_reval_exp => v_dummy_num, X_reval_deprn_exp => v_dummy_num, X_deprn_exp => v_dummy_num, X_reval_amo => v_dummy_num, X_prod => v_dummy_num, X_ytd_prod => v_ytd_prod, X_ltd_prod => v_ltd_prod, X_adj_cost => v_dummy_num, X_reval_amo_basis => v_dummy_num, X_bonus_rate => v_dummy_num, X_deprn_source_code => v_dummy_char, X_adjusted_flag => v_dummy_bool, X_transaction_header_id => -1, X_bonus_deprn_rsv => v_bonus_deprn_rsv, X_bonus_ytd_deprn => v_bonus_ytd_deprn, X_bonus_deprn_amount => v_dummy_num, X_impairment_rsv => l_impairment_rsv, X_ytd_impairment => v_dummy_num, X_impairment_amount => v_dummy_num,
        -- V2.0, Added below new Parameters as part since API has been changed in R12
        X_CAPITAL_ADJUSTMENT => v_dummy_num, -- OUT NOCOPY NUMBER,  -- Bug 6666666
        X_GENERAL_FUND => v_dummy_num,       -- OUT NOCOPY NUMBER,
        X_MRC_SOB_TYPE_CODE => 'P',          -- IN VARCHAR2, -- V2.0, if passing reporting SOB then SOB is required
        X_SET_OF_BOOKS_ID => v_dummy_num,    -- IN NUMBER,
        p_log_level_rec => NULL              -- IN FA_API_TYPES.log_level_rec_type -- Bug 6666666
        );
      EXCEPTION
      WHEN OTHERS THEN
        lc_errormsg := ( 'Error to call API fa_query_balances_pkg.query_balances for Asset Id:'||cur.asset_id || '. SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
        print_debug_msg (lc_errormsg, true);
      END;
	  
      BEGIN
        INSERT
        INTO xx_fa_status VALUES
          (
            cur.asset_id,
            cur.transaction_date_entered,
            P_BOOK_TYPE_CODE,
            cur.asset_status,
            v_deprn_rsv,
			v_ytd_deprn
          );
        v_success_count:=v_success_count+1;
      EXCEPTION
      WHEN OTHERS THEN
        lc_errormsg := 'Error to insert into xx_fa_status for Asset Id:'||cur.asset_id || '. SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE ;
        print_debug_msg (lc_errormsg, true);
        v_failure_count:=v_failure_count+1;
      END;
      IF i>5000 THEN
        COMMIT;
        i:=0;
      END IF;
    END IF;
  END LOOP;
  COMMIT;
  print_output('Total Record Count        :'||(v_success_count+v_failure_count));
  print_output('Success Record Count      :'||v_success_count);
  print_output('Failure Record Count      :'||v_failure_count);
  print_debug_msg('In Procedure XX_FA_ASSET_DEPR_EXTRACT. End Time :'||TO_CHAR(SYSTIMESTAMP,'DD-MON-YYYY HH24:MI:SS.FF2 TZH:TZM'),TRUE);
  xx_fa_proj_asset;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  lc_errormsg := 'Unhandled Exception occured in procedure XX_FA_ASSET_DEPR_EXTRACT.'||'. SQLERRM' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE ;
  print_debug_msg (lc_errormsg, true);
  p_errbuf :=lc_errormsg;
  p_retcode:=2;
END XX_FA_ASSET_DEPR_EXTRACT;
END XX_FA_CONV_EXTRACT_PKG;
/
SHOW ERRORS;