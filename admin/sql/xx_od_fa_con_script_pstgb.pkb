SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
  
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE BODY xx_od_fa_con_script_pstgb
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  xx_od_fa_con_script_pstgb                                                           |
  -- |                                                                                            |
  -- |  Description:Scripts for FA conversion   |
  -- |  RICE ID   :                |
  -- |  Description:           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         03-JUL-2019   Priyam S           Initial Version  added                           |
  -- +============================================================================================|
  gc_debug VARCHAR2(2) := 'N';
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
/*
FUNCTION xx_gl_beacon_mapping_f1(
p_source VARCHAR2,
p_type   VARCHAR2,
p_flag   VARCHAR2)
RETURN VARCHAR2
IS
CURSOR c_map
IS
SELECT SOURCE,
target,
TYPE
FROM xx_gl_beacon_mapping
WHERE SOURCE=p_source
AND TYPE    =p_type;
CURSOR c_concat
IS
SELECT regexp_substr(p_source, '[^.]+', 1, 1) entity,
regexp_substr(p_source, '[^.]+', 1, 2) cost_center,
regexp_substr(p_source, '[^.]+', 1, 3) ACCOUNT,
regexp_substr(p_source, '[^.]+', 1, 4) LOCATION,
regexp_substr(p_source, '[^.]+', 1, 5) Intercompany,
regexp_substr(p_source, '[^.]+', 1, 6) LOB
FROM dual;
v_target       VARCHAR2(100);
v_entity       VARCHAR2(50);
v_cost_center  VARCHAR2(50);
v_account      VARCHAR2(50);
v_location     VARCHAR2(50);
v_intercompany VARCHAR2(50);
v_lob          VARCHAR2(50);
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
--  v_target:=p_source;
v_target:=-1;
END;
ELSE
v_target:=NULL;
FOR i IN c_concat
LOOP
BEGIN
SELECT target
INTO v_entity
FROM xx_gl_beacon_mapping
WHERE SOURCE=i.entity
AND TYPE    ='ENTITY';
EXCEPTION
WHEN OTHERS THEN
-- v_entity:=i.entity;
v_entity:=-1;
END;
BEGIN
SELECT target
INTO v_cost_center
FROM xx_gl_beacon_mapping
WHERE SOURCE=i.cost_center
AND TYPE    ='COST_CENTER';
EXCEPTION
WHEN OTHERS THEN
-- v_cost_center:=i.cost_center;
v_cost_center:=-1;
END;
BEGIN
SELECT target
INTO v_account
FROM xx_gl_beacon_mapping
WHERE SOURCE=i.ACCOUNT
AND TYPE    ='ACCOUNT';
EXCEPTION
WHEN OTHERS THEN
-- v_account:=i.account;
v_account:=-1;
END;
BEGIN
SELECT target
INTO v_location
FROM xx_gl_beacon_mapping
WHERE SOURCE=i.LOCATION
AND TYPE    ='LOCATION';
EXCEPTION
WHEN OTHERS THEN
-- v_location:=i.location;
v_location:=-1;
END;
BEGIN
SELECT target
INTO v_lob
FROM xx_gl_beacon_mapping
WHERE SOURCE=i.LOB
AND TYPE    ='LOB';
EXCEPTION
WHEN OTHERS THEN
--v_lob:=i.lob;
v_lob:=-1;
END;
BEGIN
SELECT target
INTO v_intercompany
FROM xx_gl_beacon_mapping
WHERE SOURCE=i.intercompany
AND TYPE    ='ENTITY';
EXCEPTION
WHEN OTHERS THEN
--v_lob:=i.lob;
v_intercompany:=-1;
END;
-- SELECT nvl(TARGET,source) INTO v_inter FROM XX_GL_BEACON_MAPPING WHERE source=i.inter;
END LOOP;
v_target:=v_entity||'.'||v_lob||'.'||v_cost_center||'.'||v_account||'.'||v_location||'.'||v_intercompany;
END IF;
RETURN v_target;
ELSE
RETURN p_source;
END IF;
END xx_gl_beacon_mapping_f1;
PROCEDURE insert_miss_segments(
p_source           VARCHAR2,
p_target           VARCHAR2,
p_type             VARCHAR2,
p_asset_number     VARCHAR2,
p_identifier_query VARCHAR2,
P_BOOK_NAME        VARCHAR2)
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
INSERT
INTO xx_gl_beacon_miss_mapping
(
SOURCE,
target,
TYPE,
creation_date,
created_by,
asset_number,
identifier_query,
Book_name
)
VALUES
(
p_source,
p_target,
p_type,
SYSDATE,
-1,
p_asset_number,
p_identifier_query,
P_BOOK_NAME
);
COMMIT;
end insert_miss_segments;
*/

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
        regexp_substr(p_source, '[^.]+', 1, 6) lob

      FROM dual;
    v_target       VARCHAR2(100);
    v_entity       VARCHAR2(50);
    v_cost_center  VARCHAR2(50);
    v_account      VARCHAR2(50);
    v_location     VARCHAR2(50);
    v_intercompany VARCHAR2(50);
    v_lob          VARCHAR2(50);

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
          v_target:=p_source;
        END;
      ELSE
        v_target:=NULL;
        FOR i IN c_concat
        LOOP
          BEGIN
            SELECT target
            INTO v_entity
            FROM xx_gl_beacon_mapping
            WHERE source=i.entity
            AND type    ='ENTITY';
          EXCEPTION
          WHEN OTHERS THEN
            v_entity:=i.entity;
          END;
          BEGIN
            SELECT target
            INTO v_cost_center
            FROM xx_gl_beacon_mapping
            WHERE source=i.cost_center
            AND type    ='COST_CENTER';
          EXCEPTION
          WHEN OTHERS THEN
            v_cost_center:=i.cost_center;
          END;
          BEGIN
            SELECT target
            INTO v_account
            FROM xx_gl_beacon_mapping
            WHERE source=i.account
            AND type    ='ACCOUNT';
          EXCEPTION
          WHEN OTHERS THEN
            v_account:=i.account;
          END;
          BEGIN
            SELECT target
            INTO v_location
            FROM xx_gl_beacon_mapping
            WHERE source=i.location
            AND type    ='LOCATION';
          EXCEPTION
          WHEN OTHERS THEN
            v_location:=i.location;
          END;
          BEGIN
            SELECT target
            INTO v_lob
            FROM xx_gl_beacon_mapping
            WHERE source=i.lob
            AND type    ='LOB';
          EXCEPTION
          WHEN OTHERS THEN
            v_lob:=i.lob;
          END;
          -- SELECT nvl(TARGET,source) INTO v_inter FROM XX_GL_BEACON_MAPPING WHERE source=i.inter;
        END LOOP;
        v_target:=v_entity||'.'||v_lob||'.'||v_cost_center||'.'||v_account||'.'||v_location||'.'||v_entity;
      END IF;
      RETURN v_target;
    ELSE
      RETURN p_source;
    end if;
  END xx_gl_beacon_mapping_f1;
PROCEDURE oduscorp_parent_assets_hdr(
    p_book_type_code VARCHAR2 )
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
      /* Commented by arun as split query
      (select gcc.segment1||','||gcc.segment2||','||gcc.segment3||','||gcc.segment4||','||gcc.segment5||','||
      gcc.segment6||','||gcc.segment7
      from GL_CODE_COMBINATIONS    GCC,
      fa_distribution_accounts da
      WHERE da.distribution_id = fa_details.distribution_id
      AND da.book_type_code  =  fa_details.Asset_Book
      AND gcc.code_combination_id  = da.asset_clearing_account_ccid
      ) "SG1,SG2,SG3,SG4,SG5,SG6,SG7",
      */
      (
      SELECT gcc.segment1
      FROM GL_CODE_COMBINATIONS GCC,
        fa_distribution_accounts da
      WHERE da.distribution_id    = fa_details.distribution_id
      AND da.book_type_code       = fa_details.Asset_Book
      AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
      ) COST_CLEARING_ACCOUNT_SEG1,
    (SELECT gcc.segment2
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG2,
    (SELECT gcc.segment3
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG3,
    (SELECT gcc.segment4
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG4,
    (SELECT gcc.segment5
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE DA.DISTRIBUTION_ID    = FA_DETAILS.DISTRIBUTION_ID
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG5,
    (SELECT gcc.segment6
    FROM GL_CODE_COMBINATIONS GCC,
      FA_DISTRIBUTION_ACCOUNTS DA
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG6,
    (SELECT gcc.segment7
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND DA.BOOK_TYPE_CODE       = FA_DETAILS.ASSET_BOOK
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG7,
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
    NULL ATTRIBUTE11,
    NULL ATTRIBUTE12,
    NULL ATTRIBUTE13,
    NULL ATTRIBUTE14,
    NULL ATTRIBUTE15,
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
    NULL FULLY_DEPRECIATE
  FROM
    (SELECT Interface_Line_Number,
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
      Parent_Asset,
      In_physical_inventory,
      Property_Type,
      PROPERTY_CLASS,
      distribution_id, -- commented arun
      In_use,
      Ownership,
      Bought,
      COMMITMENT ,
      INVESTMENT_LAW, -- added arun
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
      Depreciation_Limit_Type,
      Depreciation_Limit_Percent,
      Depreciation_Limit_Amount,
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
      ATTRIBUTE_CATEGORY_CODE,
      NBV_at_the_Time_of_Switch,
      Earlier_Dep_Limit_Type,
      Earlier_Dep_Limit_Percent,
      Earlier_Dep_Limit_Amount,
      Earlier_Life_in_Months,
      Earlier_Basic_Rate,
      Earlier_Adjusted_Rate
    FROM
      (SELECT
        /*+ full(ds) full(fth) */
        FAB.ASSET_ID Interface_Line_Number,
        FB.BOOK_TYPE_CODE Asset_Book,
        fth.TRANSACTION_TYPE_CODE Transaction_Name,
        FAB.ASSET_NUMBER Asset_Number,
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(fat.description,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') Asset_Description ,
        FAB.TAG_NUMBER Tag_Number,
        FAB.MANUFACTURER_NAME Manufacturer,
        FAB.SERIAL_NUMBER Serial_Number,
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
        (SELECT ASSET_NUMBER FROM fa_additions_b WHERE asset_id = fab.PARENT_ASSET_ID
        ) Parent_Asset,
        fab.INVENTORIAL In_physical_inventory,
        fab.PROPERTY_TYPE_CODE Property_Type,
        fab.PROPERTY_1245_1250_CODE Property_Class,
        fab.IN_USE_FLAG In_use,
        fab.OWNED_LEASED Ownership,
        fab.NEW_USED Bought,
        FAB.COMMITMENT ,
        fab.investment_law, -- added by Arun
        corpbook.AMORTIZE_FLAG Amortize,
        TO_CHAR(FTH.DATE_EFFECTIVE,'YYYY/MM/DD') Amortization_Start_Date,
        fb.DEPRECIATE_FLAG Depreciate,
        fb.SALVAGE_TYPE Salvage_Value_Type,
        fb.SALVAGE_VALUE Salvage_Value_Amount,
        fb.PERCENT_SALVAGE_VALUE Salvage_Value_Percent,
        --ds.YTD_DEPRN YTD_Depreciation,
        DECODE(to_number(TO_CHAR(ds.deprn_run_date,'RRRR')),2019,ds.YTD_DEPRN,0) YTD_Depreciation,
        ds.DEPRN_RESERVE Depreciation_Reserve,
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
        FCB.ATTRIBUTE1 ATTRIBUTE1,
        FCB.ATTRIBUTE2 ATTRIBUTE2,
        FCB.ATTRIBUTE3 ATTRIBUTE3,
        FCB.ATTRIBUTE4 ATTRIBUTE4,
        FCB.ATTRIBUTE5 ATTRIBUTE5,
        FCB.ATTRIBUTE6 ATTRIBUTE6,
        FCB.ATTRIBUTE7 ATTRIBUTE7,
        FCB.ATTRIBUTE8 ATTRIBUTE8,
        FCB.ATTRIBUTE9 ATTRIBUTE9,
        FCB.ATTRIBUTE10 ATTRIBUTE10,
        FCB.ATTRIBUTE_CATEGORY_CODE ATTRIBUTE_CATEGORY_CODE,
        fb.NBV_AT_SWITCH NBV_at_the_Time_of_Switch,
        fb.PRIOR_DEPRN_LIMIT_TYPE Earlier_Dep_Limit_Type,
        fb.PRIOR_DEPRN_LIMIT Earlier_Dep_Limit_Percent,
        fb.PRIOR_DEPRN_LIMIT_AMOUNT Earlier_Dep_Limit_Amount,
        fb.PRIOR_LIFE_IN_MONTHS Earlier_Life_in_Months,
        fb.PRIOR_BASIC_RATE Earlier_Basic_Rate,
        fb.PRIOR_ADJUSTED_RATE Earlier_Adjusted_Rate,
        ds.distribution_id,
        --fb.book_type_code,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.distribution_id DESC ) distidrank,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.period_counter DESC) periodcounterrank
      FROM FA_BOOKS fb,
        xx_fa_status xfs,
        FA_BOOK_CONTROLS corpbook,
        FA_ADDITIONS_B FAB,
        FA_CATEGORIES_B FCB,
        FA_ADDITIONS_TL FAT,
        FA_DEPRN_DETAIL ds,
        FA_TRANSACTION_HEADERS fth
      WHERE 1                    =1
      AND xfs.book_type_code     =p_book_type_code--'OD US CORP'
      AND xfs.ASSET_STATUS       ='ACTIVE'
      AND fb.book_type_code      =xfs.book_type_code
      AND fb.asset_id            = xfs.asset_id
      AND corpbook.book_type_code=FB.book_type_code
      AND corpbook.BOOK_CLASS    = 'CORPORATE'
      AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
      AND FAB.ASSET_ID         =FB.ASSET_ID
      AND fab.parent_asset_id IS NULL
      AND EXISTS
        (SELECT 'x' FROM FA_ADDITIONS_B WHERE parent_asset_id = fab.ASSET_ID
        )
        --and fab.asset_id not in (21417857,21418275,11896729)
      AND fcb.category_id           =fab.asset_category_id
      AND fat.ASSET_ID              =fab.ASSET_ID
      AND fat.language              = 'US'
      AND ds.asset_id               =fb.asset_id
      AND ds.book_type_code         =fb.book_type_code
      AND fth.ASSET_ID              = fab.ASSET_ID
      AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
      AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
      )
    WHERE distidrank      = 1
    AND periodcounterrank = 1
    ) FA_DETAILS
  ORDER BY interface_line_number;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  ---l_file_path   VARCHAR(200);
  l_file_name      VARCHAR2(500);
  lv_col_title     VARCHAR2(5000);
  l_file_path      VARCHAR2(500):='XXFIN_OUTBOUND';---/app/ebs/ctgsidev02/xxfin/outbound
  lc_errormsg      VARCHAR2(1000);                ----            VARCHAR2(1000) := NULL;
  v_book_type_code VARCHAR2(100);
  ---------------------------
  v_segment1 VARCHAR2(50);
  v_segment2 VARCHAR2(50);
  v_segment3 VARCHAR2(50);
  v_segment4 VARCHAR2(50);
  v_segment5 VARCHAR2(50);
  v_segment6 VARCHAR2(50);
  v_segment7 VARCHAR2(50);
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
  print_debug_msg ('Package ODUSCORP_PARENT_ASSETS_HDR START ', TRUE);
  print_debug_msg ('P_BOOK_TYPE_CODE '||p_book_type_code, TRUE);
  v_book_type_code :=REPLACE(REPLACE (REPLACE(p_book_type_code,'OD US ','US_'),'OD CA ','CA_'),' ','_');
  --l_file_name    := 'ODUSCORP_Parent_assets_Hdr_v14' || '.csv';
  l_file_name    := 'Parent_assets_Hdr_' ||v_book_type_code|| '.csv';
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='INTERFACE_LINE_NUMBER'|| ','|| 'ASSET_BOOK'|| ','|| 'TRANSACTION_NAME'|| ','|| 'ASSET_NUMBER'|| ','|| 'ASSET_DESCRIPTION'|| ','|| 'TAG_NUMBER'|| ','|| 'MANUFACTURER'|| ','|| 'SERIAL_NUMBER'|| ','|| 'MODEL'|| ','|| 'ASSET_TYPE'|| ','|| 'COST'|| ','|| 'DATE_PLACED_IN_SERVICE'|| ','|| 'PRORATE_CONVENTION'|| ','|| 'ASSET_UNITS'|| ','|| 'ASSET_CATEGORY_SEGMENT1'|| ','|| 'ASSET_CATEGORY_SEGMENT2'|| ','|| 'ASSET_CATEGORY_SEGMENT3'|| ','|| 'ASSET_CATEGORY_SEGMENT4'|| ','|| 'ASSET_CATEGORY_SEGMENT5'|| ','|| 'ASSET_CATEGORY_SEGMENT6'|| ','|| 'ASSET_CATEGORY_SEGMENT7'|| ','|| 'POSTING_STATUS'|| ','|| 'QUEUE_NAME'|| ','|| 'FEEDER_SYSTEM'|| ','|| 'PARENT_ASSET'|| ','|| 'ADD_TO_ASSET'|| ','|| 'ASSET_KEY_SEGMENT1'|| ','|| 'ASSET_KEY_SEGMENT2'|| ','|| 'ASSET_KEY_SEGMENT3'|| ','|| 'ASSET_KEY_SEGMENT4'|| ','|| 'ASSET_KEY_SEGMENT5'|| ','|| 'ASSET_KEY_SEGMENT6'|| ','|| 'ASSET_KEY_SEGMENT7'|| ','|| 'ASSET_KEY_SEGMENT8'|| ','|| 'ASSET_KEY_SEGMENT9'|| ','|| 'ASSET_KEY_SEGMENT10'|| ','||
  'IN_PHYSICAL_INVENTORY'|| ','|| 'PROPERTY_TYPE'|| ','|| 'PROPERTY_CLASS'|| ','|| 'IN_USE'|| ','|| 'OWNERSHIP'|| ','|| 'BOUGHT'|| ','|| 'MATERIAL_INDICATOR'|| ','|| 'COMMITMENT'|| ','|| 'INVESTMENT_LAW'|| ','|| 'AMORTIZE'|| ','|| 'AMORTIZATION_START_DATE'|| ','|| 'DEPRECIATE'|| ','|| 'SALVAGE_VALUE_TYPE'|| ','|| 'SALVAGE_VALUE_AMOUNT'|| ','|| 'SALVAGE_VALUE_PERCENT'|| ','|| 'YTD_DEPRECIATION'|| ','|| 'DEPRECIATION_RESERVE'|| ','|| 'YTD_BONUS_DEPRECIATION'|| ','|| 'BONUS_DEPRECIATION_RESERVE'|| ','|| 'YTD_IMPAIRMENT'|| ','|| 'IMPAIRMENT_RESERVE'|| ','|| 'DEPRECIATION_METHOD'|| ','|| 'LIFE_IN_MONTHS'|| ','|| 'BASIC_RATE'|| ','|| 'ADJUSTED_RATE'|| ','|| 'UNIT_OF_MEASURE'|| ','|| 'PRODUCTION_CAPACITY'|| ','|| 'CEILING_TYPE'|| ','|| 'BONUS_RULE'|| ','|| 'CASH_GENERATING_UNIT'|| ','|| 'DEPRECIATION_LIMIT_TYPE'|| ','|| 'DEPRECIATION_LIMIT_PERCENT'|| ','|| 'DEPRECIATION_LIMIT_AMOUNT'|| ','|| 'INVOICE_COST'|| ','|| 'COST_CLEARING_ACCOUNT_SEG1'|| ','|| 'COST_CLEARING_ACCOUNT_SEG2'|| ','||
  'COST_CLEARING_ACCOUNT_SEG3'|| ','|| 'COST_CLEARING_ACCOUNT_SEG4'|| ','|| 'COST_CLEARING_ACCOUNT_SEG5'|| ','|| 'COST_CLEARING_ACCOUNT_SEG6'|| ','|| 'COST_CLEARING_ACCOUNT_SEG7'|| ','|| 'COST_CLEARING_ACCOUNT_SEG8'|| ','|| 'COST_CLEARING_ACCOUNT_SEG9'|| ','|| 'COST_CLEARING_ACCOUNT_SEG10'|| ','|| 'COST_CLEARING_ACCOUNT_SEG11'|| ','|| 'COST_CLEARING_ACCOUNT_SEG12'|| ','|| 'COST_CLEARING_ACCOUNT_SEG13'|| ','|| 'COST_CLEARING_ACCOUNT_SEG14'|| ','|| 'COST_CLEARING_ACCOUNT_SEG15'|| ','|| 'ATTRIBUTE1'|| ','|| 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','|| 'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'|| ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10'|| ','|| 'ATTRIBUTE11'|| ','|| 'ATTRIBUTE12'|| ','|| 'ATTRIBUTE13'|| ','|| 'ATTRIBUTE14'|| ','|| 'ATTRIBUTE15'|| ','|| 'ATTRIBUTE_CATEGORY_CODE'|| ','|| 'CONTEXT'|| ','|| 'MASS_PROPERTY_ELIGIBLE'|| ','|| 'GROUP_ASSET'|| ','|| 'REDUCTION_RATE'|| ','|| 'APPLY_REDUCTION_RATE_TO_ADDI'|| ','||
  'APPLY_REDUCTION_RATE_TO_ADJ'|| ','|| 'APPLY_REDUCTION_RATE_TO_RETI'|| ','|| 'RECOGNIZE_GAIN_OR_LOSS'|| ','|| 'RECAPTURE_EXCESS_RESERVE'|| ','|| 'LIMIT_NET_PROCEEDS_TO_COST'|| ','|| 'TERMINAL_GAIN_OR_LOSS'|| ','|| 'TRACKING_METHOD'|| ','|| 'ALLOCATE_EXCESS_DEPRECIATION'|| ','|| 'DEPRECIATE_BY'|| ','|| 'MEMBER_ROLLUP'|| ','|| 'ALLO_TO_FULL_RETI_AND_RES_ASST'|| ','|| 'OVER_DEPRECIATE'|| ','|| 'PREPARER'|| ','|| 'SUM_MERGED_UNITS'|| ','|| 'NEW_MASTER'|| ','|| 'UNITS_TO_ADJUST'|| ','|| 'SHORT_YEAR'|| ','|| 'CONVERSION_DATE'|| ','|| 'ORIGINAL_DEP_START_DATE'|| ','|| 'NBV_AT_THE_TIME_OF_SWITCH'|| ','|| 'PERIOD_FULLY_RESERVED'|| ','|| 'START_PERIOD_OF_EXTENDED_DEP'|| ','|| 'EARLIER_DEP_LIMIT_TYPE'|| ','|| 'EARLIER_DEP_LIMIT_PERCENT'|| ','|| 'EARLIER_DEP_LIMIT_AMOUNT'|| ','|| 'EARLIER_DEPRECIATION_METHOD'|| ','|| 'EARLIER_LIFE_IN_MONTHS'|| ','|| 'EARLIER_BASIC_RATE'|| ','|| 'EARLIER_ADJUSTED_RATE'|| ','|| 'LEASE_NUMBER'|| ','|| 'REVALUATION_RESERVE'|| ','|| 'REVALUATION_LOSS'|| ','||
  'REVAL_RESER_AMORTIZATION_BASIS'|| ','|| 'IMPAIRMENT_LOSS_EXPENSE'|| ','|| 'REVALUATION_COST_CEILING'|| ','|| 'FAIR_VALUE'|| ','|| 'LAST_USED_PRICE_INDEX_VALUE'|| ','|| 'SUPPLIER_NAME'|| ','|| 'SUPPLIER_NUMBER'|| ','|| 'PURCHASE_ORDER_NUMBER'|| ','|| 'INVOICE_NUMBER'|| ','|| 'INVOICE_VOUCHER_NUMBER'|| ','|| 'INVOICE_DATE'|| ','|| 'PAYABLES_UNITS'|| ','|| 'INVOICE_LINE_NUMBER'|| ','|| 'INVOICE_LINE_TYPE'|| ','|| 'INVOICE_LINE_DESCRIPTION'|| ','|| 'INVOICE_PAYMENT_NUMBER'|| ','|| 'PROJECT_NUMBER'|| ','|| 'TASK_NUMBER'|| ','|| 'FULLY_DEPRECIATE';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_pas_asset_hdr
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,i.interface_line_number|| ','|| i.asset_book|| ','|| i.transaction_name|| ','|| i.asset_number|| ','|| i.asset_description|| ','|| i.tag_number|| ','|| i.manufacturer|| ','|| i.serial_number|| ','|| i.model|| ','|| i.asset_type|| ','|| i.cost|| ','|| i.date_placed_in_service|| ','|| i.prorate_convention|| ','|| i.asset_units|| ','|| i.asset_category_segment1|| ','|| i.asset_category_segment2|| ','|| i.asset_category_segment3|| ','|| i.asset_category_segment4|| ','|| i.asset_category_segment5|| ','|| i.asset_category_segment6|| ','|| i.asset_category_segment7|| ','|| i.posting_status|| ','|| i.queue_name|| ','|| i.feeder_system|| ','|| i.parent_asset|| ','|| i.add_to_asset|| ','|| i.asset_key_segment1|| ','|| i.asset_key_segment2|| ','|| i.asset_key_segment3|| ','|| i.asset_key_segment4|| ','|| i.asset_key_segment5|| ','|| i.asset_key_segment6|| ','|| i.asset_key_segment7|| ','|| i.asset_key_segment8|| ','|| i.asset_key_segment9|| ','||
    i.asset_key_segment10|| ','|| i.in_physical_inventory|| ','|| i.property_type|| ','|| i.property_class|| ','|| i.in_use|| ','|| i.ownership|| ','|| i.bought|| ','|| i.material_indicator|| ','|| i.commitment|| ','|| i.investment_law|| ','|| i.amortize|| ','|| i.amortization_start_date|| ','|| i.depreciate|| ','|| i.salvage_value_type|| ','|| i.salvage_value_amount|| ','|| i.salvage_value_percent|| ','|| i.ytd_depreciation|| ','|| i.depreciation_reserve|| ','|| i.ytd_bonus_depreciation|| ','|| i.bonus_depreciation_reserve|| ','|| i.ytd_impairment|| ','|| i.impairment_reserve|| ','|| i.depreciation_method|| ','|| i.life_in_months|| ','|| i.basic_rate|| ','|| i.adjusted_rate|| ','|| i.unit_of_measure|| ','|| i.production_capacity|| ','|| i.ceiling_type|| ','|| i.bonus_rule|| ','|| i.cash_generating_unit|| ','|| i.depreciation_limit_type|| ','|| i.depreciation_limit_percent|| ','|| i.depreciation_limit_amount|| ','|| i.invoice_cost|| ','|| i.cost_clearing_account_seg1|| ','||
    i.cost_clearing_account_seg2|| ','|| i.cost_clearing_account_seg3|| ','|| i.cost_clearing_account_seg4|| ','|| i.cost_clearing_account_seg5|| ','|| i.cost_clearing_account_seg6|| ','|| i.cost_clearing_account_seg7|| ','|| i.cost_clearing_account_seg8|| ','|| i.cost_clearing_account_seg9|| ','|| i.cost_clearing_account_seg10|| ','|| i.cost_clearing_account_seg11|| ','|| i.cost_clearing_account_seg12|| ','|| i.cost_clearing_account_seg13|| ','|| i.cost_clearing_account_seg14|| ','|| i.cost_clearing_account_seg15|| ','|| i.attribute1|| ','|| i.attribute2|| ','|| i.attribute3|| ','|| i.attribute4|| ','|| i.attribute5|| ','|| i.attribute6|| ','|| i.attribute7|| ','|| i.attribute8|| ','|| i.attribute9|| ','|| i.attribute10|| ','|| i.attribute11|| ','|| i.attribute12|| ','|| i.attribute13|| ','|| i.attribute14|| ','|| i.attribute15|| ','|| i.attribute_category_code|| ','|| i.context|| ','|| i.mass_property_eligible|| ','|| i.group_asset|| ','|| i.reduction_rate|| ','||
    i.apply_reduction_rate_to_addi|| ','|| i.apply_reduction_rate_to_adj|| ','|| i.apply_reduction_rate_to_reti|| ','|| i.recognize_gain_or_loss|| ','|| i.recapture_excess_reserve|| ','|| i.limit_net_proceeds_to_cost|| ','|| i.terminal_gain_or_loss|| ','|| i.tracking_method|| ','|| i.allocate_excess_depreciation|| ','|| i.depreciate_by|| ','|| i.member_rollup|| ','|| i.allo_to_full_reti_and_res_asst|| ','|| i.over_depreciate|| ','|| i.preparer|| ','|| i.sum_merged_units|| ','|| i.new_master|| ','|| i.units_to_adjust|| ','|| i.short_year|| ','|| i.conversion_date|| ','|| i.original_dep_start_date|| ','|| i.nbv_at_the_time_of_switch|| ','|| i.period_fully_reserved|| ','|| i.start_period_of_extended_dep|| ','|| i.earlier_dep_limit_type|| ','|| i.earlier_dep_limit_percent|| ','|| i.earlier_dep_limit_amount|| ','|| i.earlier_depreciation_method|| ','|| i.earlier_life_in_months|| ','|| i.earlier_basic_rate|| ','|| i.earlier_adjusted_rate|| ','|| i.lease_number|| ','|| i.revaluation_reserve
    || ','|| i.revaluation_loss|| ','|| i.reval_reser_amortization_basis|| ','|| i.impairment_loss_expense|| ','|| i.revaluation_cost_ceiling|| ','|| i.fair_value|| ','|| i.last_used_price_index_value|| ','|| i.supplier_name|| ','|| i.supplier_number|| ','|| i.purchase_order_number|| ','|| i.invoice_number|| ','|| i.invoice_voucher_number|| ','|| i.invoice_date|| ','|| i.payables_units|| ','|| i.invoice_line_number|| ','|| i.invoice_line_type|| ','|| i.invoice_line_description|| ','|| i.invoice_payment_number|| ','|| i.project_number|| ','|| i.task_number|| ','|| i.fully_depreciate);
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in ODUSCORP_PARENT_ASSETS_HDR procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END oduscorp_parent_assets_hdr;
PROCEDURE oduscorp_child_assets_hdr(
    p_book_type_code VARCHAR2)
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
      /* Commented by arun as split query
      (select gcc.segment1||','||gcc.segment2||','||gcc.segment3||','||gcc.segment4||','||gcc.segment5||','||
      gcc.segment6||','||gcc.segment7
      from GL_CODE_COMBINATIONS    GCC,
      fa_distribution_accounts da
      WHERE da.distribution_id = fa_details.distribution_id
      AND da.book_type_code  =  fa_details.Asset_Book
      AND gcc.code_combination_id  = da.asset_clearing_account_ccid
      ) "SG1,SG2,SG3,SG4,SG5,SG6,SG7",
      */
      (
      SELECT gcc.segment1
      FROM GL_CODE_COMBINATIONS GCC,
        fa_distribution_accounts da
      WHERE da.distribution_id    = fa_details.distribution_id
      AND da.book_type_code       = fa_details.Asset_Book
      AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
      ) COST_CLEARING_ACCOUNT_SEG1,
    (SELECT gcc.segment2
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG2,
    (SELECT gcc.segment3
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG3,
    (SELECT gcc.segment4
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG4,
    (SELECT gcc.segment5
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE DA.DISTRIBUTION_ID    = FA_DETAILS.DISTRIBUTION_ID
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG5,
    (SELECT gcc.segment6
    FROM GL_CODE_COMBINATIONS GCC,
      FA_DISTRIBUTION_ACCOUNTS DA
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG6,
    (SELECT gcc.segment7
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND DA.BOOK_TYPE_CODE       = FA_DETAILS.ASSET_BOOK
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG7,
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
    NULL ATTRIBUTE11,
    NULL ATTRIBUTE12,
    NULL ATTRIBUTE13,
    NULL ATTRIBUTE14,
    NULL ATTRIBUTE15,
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
    NULL FULLY_DEPRECIATE
  FROM
    (SELECT Interface_Line_Number,
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
      Parent_Asset,
      In_physical_inventory,
      Property_Type,
      PROPERTY_CLASS,
      distribution_id, -- commented arun
      In_use,
      Ownership,
      Bought,
      COMMITMENT ,
      INVESTMENT_LAW, -- added arun
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
      Depreciation_Limit_Type,
      Depreciation_Limit_Percent,
      Depreciation_Limit_Amount,
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
      ATTRIBUTE_CATEGORY_CODE,
      NBV_at_the_Time_of_Switch,
      Earlier_Dep_Limit_Type,
      Earlier_Dep_Limit_Percent,
      Earlier_Dep_Limit_Amount,
      Earlier_Life_in_Months,
      Earlier_Basic_Rate,
      Earlier_Adjusted_Rate
    FROM
      (SELECT
        /*+ full(ds) full(fth) */
        FAB.ASSET_ID Interface_Line_Number,
        FB.BOOK_TYPE_CODE Asset_Book,
        fth.TRANSACTION_TYPE_CODE Transaction_Name,
        FAB.ASSET_NUMBER Asset_Number,
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(fat.description,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') Asset_Description ,
        --               FAT.DESCRIPTION                 Asset_Description ,
        FAB.TAG_NUMBER Tag_Number,
        FAB.MANUFACTURER_NAME Manufacturer,
        FAB.SERIAL_NUMBER Serial_Number,
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
        --               (SELECT ASSET_NUMBER
        --                      FROM fa_additions_b
        --                      WHERE asset_id = fab.PARENT_ASSET_ID)  Parent_Asset,
        (
        SELECT xxfss.ASSET_ID
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
        corpbook.AMORTIZE_FLAG Amortize,
        TO_CHAR(FTH.DATE_EFFECTIVE,'YYYY/MM/DD') Amortization_Start_Date,
        fb.DEPRECIATE_FLAG Depreciate,
        fb.SALVAGE_TYPE Salvage_Value_Type,
        fb.SALVAGE_VALUE Salvage_Value_Amount,
        fb.PERCENT_SALVAGE_VALUE Salvage_Value_Percent,
        --ds.YTD_DEPRN YTD_Depreciation,
        DECODE(to_number(TO_CHAR(ds.deprn_run_date,'RRRR')),2019,ds.YTD_DEPRN,0) YTD_Depreciation,
        ds.DEPRN_RESERVE Depreciation_Reserve,
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
        FCB.ATTRIBUTE1 ATTRIBUTE1,
        FCB.ATTRIBUTE2 ATTRIBUTE2,
        FCB.ATTRIBUTE3 ATTRIBUTE3,
        FCB.ATTRIBUTE4 ATTRIBUTE4,
        FCB.ATTRIBUTE5 ATTRIBUTE5,
        FCB.ATTRIBUTE6 ATTRIBUTE6,
        FCB.ATTRIBUTE7 ATTRIBUTE7,
        FCB.ATTRIBUTE8 ATTRIBUTE8,
        FCB.ATTRIBUTE9 ATTRIBUTE9,
        FCB.ATTRIBUTE10 ATTRIBUTE10,
        FCB.ATTRIBUTE_CATEGORY_CODE ATTRIBUTE_CATEGORY_CODE,
        fb.NBV_AT_SWITCH NBV_at_the_Time_of_Switch,
        fb.PRIOR_DEPRN_LIMIT_TYPE Earlier_Dep_Limit_Type,
        fb.PRIOR_DEPRN_LIMIT Earlier_Dep_Limit_Percent,
        fb.PRIOR_DEPRN_LIMIT_AMOUNT Earlier_Dep_Limit_Amount,
        fb.PRIOR_LIFE_IN_MONTHS Earlier_Life_in_Months,
        fb.PRIOR_BASIC_RATE Earlier_Basic_Rate,
        fb.PRIOR_ADJUSTED_RATE Earlier_Adjusted_Rate,
        ds.distribution_id,
        --fb.book_type_code,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.distribution_id DESC ) distidrank,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.period_counter DESC) periodcounterrank
      FROM FA_BOOKS fb,
        xx_fa_status xfs,
        FA_BOOK_CONTROLS corpbook,
        FA_ADDITIONS_B FAB,
        FA_CATEGORIES_B FCB,
        FA_ADDITIONS_TL FAT,
        FA_DEPRN_DETAIL ds,
        FA_TRANSACTION_HEADERS fth
      WHERE 1                    =1
      AND xfs.book_type_code     =p_book_type_code--'OD US CORP'
      AND xfs.ASSET_STATUS       ='ACTIVE'
      AND fb.book_type_code      =xfs.book_type_code
      AND fb.asset_id            = xfs.asset_id
      AND corpbook.book_type_code=FB.book_type_code
      AND corpbook.BOOK_CLASS    = 'CORPORATE'
      AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
      AND FAB.ASSET_ID=FB.ASSET_ID
      AND NOT EXISTS
        (SELECT 'x' FROM FA_ADDITIONS_B WHERE parent_asset_id = fab.ASSET_ID
        )
        --and fab.asset_id not in (21417857,21418275,11896729)
      AND fcb.category_id           =fab.asset_category_id
      AND fat.ASSET_ID              =fab.ASSET_ID
      AND fat.language              = 'US'
      AND ds.asset_id               =fb.asset_id
      AND ds.book_type_code         =fb.book_type_code
      AND fth.ASSET_ID              = fab.ASSET_ID
      AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
      AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
      )
    WHERE distidrank      = 1
    AND periodcounterrank = 1
    ) FA_DETAILS
  ORDER BY interface_line_number;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  --  l_file_path   VARCHAR(200);
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
  v_segment7       VARCHAR2(50);
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
  print_debug_msg ('Package ODUSCORP_CHILD_ASSETS_HDR', TRUE);
  print_debug_msg ('P_BOOK_TYPE_CODE '||p_book_type_code, TRUE);
  v_book_type_code :=REPLACE(REPLACE (REPLACE(p_book_type_code,'OD US ','US_'),'OD CA ','CA_'),' ','_');
  l_file_name      := 'Child_assets_Hdr_'||v_book_type_code|| '.csv';
  lc_file_handle   := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title     :='INTERFACE_LINE_NUMBER'|| ','|| 'ASSET_BOOK'|| ','|| 'TRANSACTION_NAME'|| ','|| 'ASSET_NUMBER'|| ','|| 'ASSET_DESCRIPTION'|| ','|| 'TAG_NUMBER'|| ','|| 'MANUFACTURER'|| ','|| 'SERIAL_NUMBER'|| ','|| 'MODEL'|| ','|| 'ASSET_TYPE'|| ','|| 'COST'|| ','|| 'DATE_PLACED_IN_SERVICE'|| ','|| 'PRORATE_CONVENTION'|| ','|| 'ASSET_UNITS'|| ','|| 'ASSET_CATEGORY_SEGMENT1'|| ','|| 'ASSET_CATEGORY_SEGMENT2'|| ','|| 'ASSET_CATEGORY_SEGMENT3'|| ','|| 'ASSET_CATEGORY_SEGMENT4'|| ','|| 'ASSET_CATEGORY_SEGMENT5'|| ','|| 'ASSET_CATEGORY_SEGMENT6'|| ','|| 'ASSET_CATEGORY_SEGMENT7'|| ','|| 'POSTING_STATUS'|| ','|| 'QUEUE_NAME'|| ','|| 'FEEDER_SYSTEM'|| ','|| 'PARENT_ASSET'|| ','|| 'ADD_TO_ASSET'|| ','|| 'ASSET_KEY_SEGMENT1'|| ','|| 'ASSET_KEY_SEGMENT2'|| ','|| 'ASSET_KEY_SEGMENT3'|| ','|| 'ASSET_KEY_SEGMENT4'|| ','|| 'ASSET_KEY_SEGMENT5'|| ','|| 'ASSET_KEY_SEGMENT6'|| ','|| 'ASSET_KEY_SEGMENT7'|| ','|| 'ASSET_KEY_SEGMENT8'|| ','|| 'ASSET_KEY_SEGMENT9'|| ','|| 'ASSET_KEY_SEGMENT10'|| ','
  || 'IN_PHYSICAL_INVENTORY'|| ','|| 'PROPERTY_TYPE'|| ','|| 'PROPERTY_CLASS'|| ','|| 'IN_USE'|| ','|| 'OWNERSHIP'|| ','|| 'BOUGHT'|| ','|| 'MATERIAL_INDICATOR'|| ','|| 'COMMITMENT'|| ','|| 'INVESTMENT_LAW'|| ','|| 'AMORTIZE'|| ','|| 'AMORTIZATION_START_DATE'|| ','|| 'DEPRECIATE'|| ','|| 'SALVAGE_VALUE_TYPE'|| ','|| 'SALVAGE_VALUE_AMOUNT'|| ','|| 'SALVAGE_VALUE_PERCENT'|| ','|| 'YTD_DEPRECIATION'|| ','|| 'DEPRECIATION_RESERVE'|| ','|| 'YTD_BONUS_DEPRECIATION'|| ','|| 'BONUS_DEPRECIATION_RESERVE'|| ','|| 'YTD_IMPAIRMENT'|| ','|| 'IMPAIRMENT_RESERVE'|| ','|| 'DEPRECIATION_METHOD'|| ','|| 'LIFE_IN_MONTHS'|| ','|| 'BASIC_RATE'|| ','|| 'ADJUSTED_RATE'|| ','|| 'UNIT_OF_MEASURE'|| ','|| 'PRODUCTION_CAPACITY'|| ','|| 'CEILING_TYPE'|| ','|| 'BONUS_RULE'|| ','|| 'CASH_GENERATING_UNIT'|| ','|| 'DEPRECIATION_LIMIT_TYPE'|| ','|| 'DEPRECIATION_LIMIT_PERCENT'|| ','|| 'DEPRECIATION_LIMIT_AMOUNT'|| ','|| 'INVOICE_COST'|| ','|| 'COST_CLEARING_ACCOUNT_SEG1'|| ','|| 'COST_CLEARING_ACCOUNT_SEG2'|| ',' ||
  'COST_CLEARING_ACCOUNT_SEG3'|| ','|| 'COST_CLEARING_ACCOUNT_SEG4'|| ','|| 'COST_CLEARING_ACCOUNT_SEG5'|| ','|| 'COST_CLEARING_ACCOUNT_SEG6'|| ','|| 'COST_CLEARING_ACCOUNT_SEG7'|| ','|| 'COST_CLEARING_ACCOUNT_SEG8'|| ','|| 'COST_CLEARING_ACCOUNT_SEG9'|| ','|| 'COST_CLEARING_ACCOUNT_SEG10'|| ','|| 'COST_CLEARING_ACCOUNT_SEG11'|| ','|| 'COST_CLEARING_ACCOUNT_SEG12'|| ','|| 'COST_CLEARING_ACCOUNT_SEG13'|| ','|| 'COST_CLEARING_ACCOUNT_SEG14'|| ','|| 'COST_CLEARING_ACCOUNT_SEG15'|| ','|| 'ATTRIBUTE1'|| ','|| 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','|| 'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'|| ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10'|| ','|| 'ATTRIBUTE11'|| ','|| 'ATTRIBUTE12'|| ','|| 'ATTRIBUTE13'|| ','|| 'ATTRIBUTE14'|| ','|| 'ATTRIBUTE15'|| ','|| 'ATTRIBUTE_CATEGORY_CODE'|| ','|| 'CONTEXT'|| ','|| 'MASS_PROPERTY_ELIGIBLE'|| ','|| 'GROUP_ASSET'|| ','|| 'REDUCTION_RATE'|| ','|| 'APPLY_REDUCTION_RATE_TO_ADDI'|| ','||
  'APPLY_REDUCTION_RATE_TO_ADJ'|| ','|| 'APPLY_REDUCTION_RATE_TO_RETI'|| ','|| 'RECOGNIZE_GAIN_OR_LOSS'|| ','|| 'RECAPTURE_EXCESS_RESERVE'|| ','|| 'LIMIT_NET_PROCEEDS_TO_COST'|| ','|| 'TERMINAL_GAIN_OR_LOSS'|| ','|| 'TRACKING_METHOD'|| ','|| 'ALLOCATE_EXCESS_DEPRECIATION'|| ','|| 'DEPRECIATE_BY'|| ','|| 'MEMBER_ROLLUP'|| ','|| 'ALLO_TO_FULL_RETI_AND_RES_ASST'|| ','|| 'OVER_DEPRECIATE'|| ','|| 'PREPARER'|| ','|| 'SUM_MERGED_UNITS'|| ','|| 'NEW_MASTER'|| ','|| 'UNITS_TO_ADJUST'|| ','|| 'SHORT_YEAR'|| ','|| 'CONVERSION_DATE'|| ','|| 'ORIGINAL_DEP_START_DATE'|| ','|| 'NBV_AT_THE_TIME_OF_SWITCH'|| ','|| 'PERIOD_FULLY_RESERVED'|| ','|| 'START_PERIOD_OF_EXTENDED_DEP'|| ','|| 'EARLIER_DEP_LIMIT_TYPE'|| ','|| 'EARLIER_DEP_LIMIT_PERCENT'|| ','|| 'EARLIER_DEP_LIMIT_AMOUNT'|| ','|| 'EARLIER_DEPRECIATION_METHOD'|| ','|| 'EARLIER_LIFE_IN_MONTHS'|| ','|| 'EARLIER_BASIC_RATE'|| ','|| 'EARLIER_ADJUSTED_RATE'|| ','|| 'LEASE_NUMBER'|| ','|| 'REVALUATION_RESERVE'|| ','|| 'REVALUATION_LOSS'|| ','||
  'REVAL_RESER_AMORTIZATION_BASIS'|| ','|| 'IMPAIRMENT_LOSS_EXPENSE'|| ','|| 'REVALUATION_COST_CEILING'|| ','|| 'FAIR_VALUE'|| ','|| 'LAST_USED_PRICE_INDEX_VALUE'|| ','|| 'SUPPLIER_NAME'|| ','|| 'SUPPLIER_NUMBER'|| ','|| 'PURCHASE_ORDER_NUMBER'|| ','|| 'INVOICE_NUMBER'|| ','|| 'INVOICE_VOUCHER_NUMBER'|| ','|| 'INVOICE_DATE'|| ','|| 'PAYABLES_UNITS'|| ','|| 'INVOICE_LINE_NUMBER'|| ','|| 'INVOICE_LINE_TYPE'|| ','|| 'INVOICE_LINE_DESCRIPTION'|| ','|| 'INVOICE_PAYMENT_NUMBER'|| ','|| 'PROJECT_NUMBER'|| ','|| 'TASK_NUMBER'|| ','|| 'FULLY_DEPRECIATE';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_child_asset_hdr
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,i.interface_line_number|| ','|| i.asset_book|| ','|| i.transaction_name|| ','|| i.asset_number|| ','|| i.asset_description|| ','|| i.tag_number|| ','|| i.manufacturer|| ','|| i.serial_number|| ','|| i.model|| ','|| i.asset_type|| ','|| i.cost|| ','|| i.date_placed_in_service|| ','|| i.prorate_convention|| ','|| i.asset_units|| ','|| i.asset_category_segment1|| ','|| i.asset_category_segment2|| ','|| i.asset_category_segment3|| ','|| i.asset_category_segment4|| ','|| i.asset_category_segment5|| ','|| i.asset_category_segment6|| ','|| i.asset_category_segment7|| ','|| i.posting_status|| ','|| i.queue_name|| ','|| i.feeder_system|| ','|| i.parent_asset|| ','|| i.add_to_asset|| ','|| i.asset_key_segment1|| ','|| i.asset_key_segment2|| ','|| i.asset_key_segment3|| ','|| i.asset_key_segment4|| ','|| i.asset_key_segment5|| ','|| i.asset_key_segment6|| ','|| i.asset_key_segment7|| ','|| i.asset_key_segment8|| ','|| i.asset_key_segment9|| ','||
    i.asset_key_segment10|| ','|| i.in_physical_inventory|| ','|| i.property_type|| ','|| i.property_class|| ','|| i.in_use|| ','|| i.ownership|| ','|| i.bought|| ','|| i.material_indicator|| ','|| i.commitment|| ','|| i.investment_law|| ','|| i.amortize|| ','|| i.amortization_start_date|| ','|| i.depreciate|| ','|| i.salvage_value_type|| ','|| i.salvage_value_amount|| ','|| i.salvage_value_percent|| ','|| i.ytd_depreciation|| ','|| i.depreciation_reserve|| ','|| i.ytd_bonus_depreciation|| ','|| i.bonus_depreciation_reserve|| ','|| i.ytd_impairment|| ','|| i.impairment_reserve|| ','|| i.depreciation_method|| ','|| i.life_in_months|| ','|| i.basic_rate|| ','|| i.adjusted_rate|| ','|| i.unit_of_measure|| ','|| i.production_capacity|| ','|| i.ceiling_type|| ','|| i.bonus_rule|| ','|| i.cash_generating_unit|| ','|| i.depreciation_limit_type|| ','|| i.depreciation_limit_percent|| ','|| i.depreciation_limit_amount|| ','|| i.invoice_cost|| ','|| i.cost_clearing_account_seg1|| ','||
    i.cost_clearing_account_seg2|| ','|| i.cost_clearing_account_seg3|| ','|| i.cost_clearing_account_seg4|| ','|| i.cost_clearing_account_seg5|| ','|| i.cost_clearing_account_seg6|| ','|| i.cost_clearing_account_seg7|| ','|| i.cost_clearing_account_seg8|| ','|| i.cost_clearing_account_seg9|| ','|| i.cost_clearing_account_seg10|| ','|| i.cost_clearing_account_seg11|| ','|| i.cost_clearing_account_seg12|| ','|| i.cost_clearing_account_seg13|| ','|| i.cost_clearing_account_seg14|| ','|| i.cost_clearing_account_seg15|| ','|| i.attribute1|| ','|| i.attribute2|| ','|| i.attribute3|| ','|| i.attribute4|| ','|| i.attribute5|| ','|| i.attribute6|| ','|| i.attribute7|| ','|| i.attribute8|| ','|| i.attribute9|| ','|| i.attribute10|| ','|| i.attribute11|| ','|| i.attribute12|| ','|| i.attribute13|| ','|| i.attribute14|| ','|| i.attribute15|| ','|| i.attribute_category_code|| ','|| i.context|| ','|| i.mass_property_eligible|| ','|| i.group_asset|| ','|| i.reduction_rate|| ','||
    i.apply_reduction_rate_to_addi|| ','|| i.apply_reduction_rate_to_adj|| ','|| i.apply_reduction_rate_to_reti|| ','|| i.recognize_gain_or_loss|| ','|| i.recapture_excess_reserve|| ','|| i.limit_net_proceeds_to_cost|| ','|| i.terminal_gain_or_loss|| ','|| i.tracking_method|| ','|| i.allocate_excess_depreciation|| ','|| i.depreciate_by|| ','|| i.member_rollup|| ','|| i.allo_to_full_reti_and_res_asst|| ','|| i.over_depreciate|| ','|| i.preparer|| ','|| i.sum_merged_units|| ','|| i.new_master|| ','|| i.units_to_adjust|| ','|| i.short_year|| ','|| i.conversion_date|| ','|| i.original_dep_start_date|| ','|| i.nbv_at_the_time_of_switch|| ','|| i.period_fully_reserved|| ','|| i.start_period_of_extended_dep|| ','|| i.earlier_dep_limit_type|| ','|| i.earlier_dep_limit_percent|| ','|| i.earlier_dep_limit_amount|| ','|| i.earlier_depreciation_method|| ','|| i.earlier_life_in_months|| ','|| i.earlier_basic_rate|| ','|| i.earlier_adjusted_rate|| ','|| i.lease_number|| ','|| i.revaluation_reserve
    || ','|| i.revaluation_loss|| ','|| i.reval_reser_amortization_basis|| ','|| i.impairment_loss_expense|| ','|| i.revaluation_cost_ceiling|| ','|| i.fair_value|| ','|| i.last_used_price_index_value|| ','|| i.supplier_name|| ','|| i.supplier_number|| ','|| i.purchase_order_number|| ','|| i.invoice_number|| ','|| i.invoice_voucher_number|| ','|| i.invoice_date|| ','|| i.payables_units|| ','|| i.invoice_line_number|| ','|| i.invoice_line_type|| ','|| i.invoice_line_description|| ','|| i.invoice_payment_number|| ','|| i.project_number|| ','|| i.task_number|| ','|| i.fully_depreciate);
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in ODUSCORP_CHILD_assets_Hdr procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END oduscorp_child_assets_hdr;
PROCEDURE oduscorp_parent_distribution(
    p_book_type_code VARCHAR2)
IS
  CURSOR c_parent_dist
  IS
    SELECT
      /*+ parallel(8) */
      Interface_Line_Number,
      Units_Assigned,
      Employee_Email_Address,
      Asset_Location_Segment1,
      Asset_Location_Segment2,
      Asset_Location_Segment3,
      Asset_Location_Segment4,
      ASSET_LOCATION_SEGMENT6 "ASSET_LOCATION_SEGMENT5",
      SUBSTR(Asset_Location_Segment5,2) "ASSET_LOCATION_SEGMENT6",
      Asset_Location_Segment7,
      exp_acct_segment1
      || '.'
      || exp_acct_segment2
      || '.'
      || exp_acct_segment3
      || '.'
      || exp_acct_segment4
      || '.'
      || EXP_ACCT_SEGMENT5
      || '.'
      || EXP_ACCT_SEGMENT6
      || '.'
      || EXP_ACCT_SEGMENT7 EXPENSE_ACCOUNT_SEGMENT
    FROM
      (SELECT Interface_Line_Number,
        Units_Assigned,
        Employee_Email_Address,
        Asset_Location_Segment1,
        Asset_Location_Segment2,
        Asset_Location_Segment3,
        Asset_Location_Segment4,
        Asset_Location_Segment5,
        Asset_Location_Segment6,
        Asset_Location_Segment7,
        Exp_acct_segment1,
        Exp_acct_segment2,
        Exp_acct_segment3,
        Exp_acct_segment4,
        Exp_acct_segment5,
        Exp_acct_segment6,
        Exp_acct_segment7,
        Exp_acct_segment8,
        Exp_acct_segment9,
        Exp_acct_segment10,
        Exp_acct_segment11,
        Exp_acct_segment12,
        Exp_acct_segment13,
        Exp_acct_segment14,
        Exp_acct_segment15,
        Exp_acct_segment16,
        Exp_acct_segment17,
        Exp_acct_segment18,
        Exp_acct_segment19,
        Exp_acct_segment20,
        Exp_acct_segment21,
        Exp_acct_segment22,
        Exp_acct_segment23,
        Exp_acct_segment24,
        Exp_acct_segment25,
        Exp_acct_segment26,
        Exp_acct_segment27,
        Exp_acct_segment28,
        Exp_acct_segment29,
        Exp_acct_segment30
      FROM
        (SELECT
          /*+ full(ds) full(fth) */
          FB.ASSET_ID Interface_Line_Number,
          fd.UNITS_ASSIGNED Units_Assigned,
          NULL Employee_Email_Address,
          loc.SEGMENT1 Asset_Location_Segment1,
          loc.SEGMENT2 Asset_Location_Segment2,
          loc.SEGMENT3 Asset_Location_Segment3,
          loc.SEGMENT4 Asset_Location_Segment4,
          loc.SEGMENT5 Asset_Location_Segment5,
          loc.SEGMENT6 Asset_Location_Segment6,
          loc.SEGMENT7 Asset_Location_Segment7,
          gcc.segment1 Exp_acct_segment1,
          gcc.segment2 Exp_acct_segment2,
          gcc.segment3 Exp_acct_segment3,
          gcc.segment4 Exp_acct_segment4,
          gcc.segment5 Exp_acct_segment5,
          gcc.segment6 Exp_acct_segment6,
          gcc.segment7 Exp_acct_segment7,
          gcc.segment8 Exp_acct_segment8,
          gcc.segment9 Exp_acct_segment9,
          gcc.segment10 Exp_acct_segment10,
          gcc.segment11 Exp_acct_segment11,
          gcc.segment12 Exp_acct_segment12,
          gcc.segment13 Exp_acct_segment13,
          gcc.segment14 Exp_acct_segment14,
          gcc.segment15 Exp_acct_segment15,
          gcc.segment16 Exp_acct_segment16,
          gcc.segment17 Exp_acct_segment17,
          gcc.segment18 Exp_acct_segment18,
          gcc.segment19 Exp_acct_segment19,
          gcc.segment20 Exp_acct_segment20,
          gcc.segment21 Exp_acct_segment21,
          gcc.segment22 Exp_acct_segment22,
          gcc.segment23 Exp_acct_segment23,
          gcc.segment24 Exp_acct_segment24,
          gcc.segment25 Exp_acct_segment25,
          gcc.segment26 Exp_acct_segment26,
          gcc.segment27 Exp_acct_segment27,
          gcc.segment28 Exp_acct_segment28,
          gcc.segment29 Exp_acct_segment29,
          gcc.segment30 Exp_acct_segment30,
          RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.distribution_id DESC ) distidrank,
          RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.period_counter DESC) periodcounterrank
        FROM FA_DEPRN_DETAIL ds,
          FA_TRANSACTION_HEADERS fth,
          FA_CATEGORIES_B FCB,
          gl_code_combinations gcc,
          fa_locations loc,
          fa_distribution_history fd,
          FA_BOOKS fb,
          xx_fa_status xfs,
          FA_BOOK_CONTROLS corpbook,
          FA_ADDITIONS_B FAB
        WHERE 1                    =1
        AND xfs.book_type_code     ='OD US CORP'
        AND xfs.ASSET_STATUS       ='ACTIVE'
        AND corpbook.book_type_code=xfs.book_type_code
        AND corpbook.BOOK_CLASS    = 'CORPORATE'
        AND FAB.ASSET_ID           =XFS.ASSET_ID
          --and fab.asset_id not in (21417857,21418275,11896729)
        AND fab.parent_asset_id IS NULL
        AND EXISTS
          (SELECT 'x' FROM FA_ADDITIONS_B WHERE parent_asset_id = fab.ASSET_ID
          )
      AND fb.book_type_code=xfs.book_type_code
      AND fb.asset_id      = xfs.asset_id
      AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
      AND fd.asset_id               =fb.asset_id
      AND fd.date_ineffective      IS NULL
      AND fd.book_type_code         =fb.book_type_code
      AND loc.location_id           =fd.location_id
      AND gcc.code_combination_id   = fd.code_combination_id
      AND fcb.category_id           =fab.asset_category_id
      AND fth.ASSET_ID              = fab.ASSET_ID
      AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
      AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
      AND ds.asset_id               =fb.asset_id
      AND ds.book_type_code         =fb.book_type_code
        )
      WHERE distidrank     =1
      AND periodcounterrank=1
      )
    ORDER BY Interface_Line_Number;
    lc_file_handle utl_file.file_type;
    lv_line_count NUMBER;
    ---  l_file_path   VARCHAR(200);
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
    v_segment7       VARCHAR2(50);
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
    print_debug_msg ('Package ODUSCORP_PARENT_DISTRIBUTION START', TRUE);
    print_debug_msg ('P_BOOK_TYPE_CODE '||p_book_type_code, TRUE);
    v_book_type_code :=REPLACE(REPLACE (REPLACE(p_book_type_code,'OD US ','US_'),'OD CA ','CA_'),' ','_');
    --- l_file_name    := 'ODUSCORP_Parent_Distribution_v15' || '.csv';
    l_file_name    := 'Parent_Distribution_'||v_book_type_code|| '.csv';
    lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
    lv_col_title   :='INTERFACE_LINE_NUMBER'|| ','|| 'UNITS_ASSIGNED'|| ','|| 'EMPLOYEE_EMAIL_ADDRESS'|| ','|| 'ASSET_LOCATION_SEGMENT1'|| ','|| 'ASSET_LOCATION_SEGMENT2'|| ','|| 'ASSET_LOCATION_SEGMENT3'|| ','|| 'ASSET_LOCATION_SEGMENT4'|| ','|| 'ASSET_LOCATION_SEGMENT5'|| ','|| 'ASSET_LOCATION_SEGMENT6'|| ','|| 'ASSET_LOCATION_SEGMENT7'|| ','|| 'EXPENSE_ACCOUNT_SEGMENT';
    utl_file.put_line(lc_file_handle,lv_col_title);
    FOR i IN c_parent_dist
    LOOP
      ---UTL_FILE.put_line(lc_file_handle,'HI');
      utl_file.put_line(lc_file_handle,i.interface_line_number|| ','|| i.units_assigned|| ','|| i.employee_email_address|| ','|| i.asset_location_segment1|| ','|| i.asset_location_segment2|| ','|| i.asset_location_segment3|| ','|| i.asset_location_segment4|| ','|| i.asset_location_segment5|| ','|| i.asset_location_segment6|| ','|| i.asset_location_segment7|| ','|| i.expense_account_segment);
    END LOOP;
    utl_file.fclose(lc_file_handle);
  EXCEPTION
  WHEN utl_file.access_denied THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.delete_failed THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.file_open THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.internal_error THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filehandle THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filename THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_maxlinesize THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_mode THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_offset THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_operation THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_path THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.read_error THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.rename_failed THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.write_error THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in ODUSCORP_Parent_Distribution procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  END oduscorp_parent_distribution;
PROCEDURE oduscorp_child_distribution(
    p_book_type_code VARCHAR2)
IS
  CURSOR c_child_dist
  IS
    SELECT
      /*+ parallel(8) */
      Interface_Line_Number,
      Units_Assigned,
      Employee_Email_Address,
      Asset_Location_Segment1,
      Asset_Location_Segment2,
      Asset_Location_Segment3,
      Asset_Location_Segment4,
      ASSET_LOCATION_SEGMENT6 "ASSET_LOCATION_SEGMENT5",
      SUBSTR(Asset_Location_Segment5,2) "ASSET_LOCATION_SEGMENT6",
      Asset_Location_Segment7,
      exp_acct_segment1
      || '.'
      || exp_acct_segment2
      || '.'
      || exp_acct_segment3
      || '.'
      || exp_acct_segment4
      || '.'
      || EXP_ACCT_SEGMENT5
      || '.'
      || EXP_ACCT_SEGMENT6
      || '.'
      || EXP_ACCT_SEGMENT7 EXPENSE_ACCOUNT_SEGMENT
    FROM
      (SELECT Interface_Line_Number,
        Units_Assigned,
        Employee_Email_Address,
        Asset_Location_Segment1,
        Asset_Location_Segment2,
        Asset_Location_Segment3,
        Asset_Location_Segment4,
        Asset_Location_Segment5,
        Asset_Location_Segment6,
        Asset_Location_Segment7,
        Exp_acct_segment1,
        Exp_acct_segment2,
        Exp_acct_segment3,
        Exp_acct_segment4,
        Exp_acct_segment5,
        Exp_acct_segment6,
        Exp_acct_segment7,
        Exp_acct_segment8,
        Exp_acct_segment9,
        Exp_acct_segment10,
        Exp_acct_segment11,
        Exp_acct_segment12,
        Exp_acct_segment13,
        Exp_acct_segment14,
        Exp_acct_segment15,
        Exp_acct_segment16,
        Exp_acct_segment17,
        Exp_acct_segment18,
        Exp_acct_segment19,
        Exp_acct_segment20,
        Exp_acct_segment21,
        Exp_acct_segment22,
        Exp_acct_segment23,
        Exp_acct_segment24,
        Exp_acct_segment25,
        Exp_acct_segment26,
        Exp_acct_segment27,
        Exp_acct_segment28,
        Exp_acct_segment29,
        Exp_acct_segment30
      FROM
        (SELECT
          /*+ full(ds) full(fth) */
          FB.ASSET_ID Interface_Line_Number,
          fd.UNITS_ASSIGNED Units_Assigned,
          NULL Employee_Email_Address,
          loc.SEGMENT1 Asset_Location_Segment1,
          loc.SEGMENT2 Asset_Location_Segment2,
          loc.SEGMENT3 Asset_Location_Segment3,
          loc.SEGMENT4 Asset_Location_Segment4,
          loc.SEGMENT5 Asset_Location_Segment5,
          loc.SEGMENT6 Asset_Location_Segment6,
          loc.SEGMENT7 Asset_Location_Segment7,
          gcc.segment1 Exp_acct_segment1,
          gcc.segment2 Exp_acct_segment2,
          gcc.segment3 Exp_acct_segment3,
          gcc.segment4 Exp_acct_segment4,
          gcc.segment5 Exp_acct_segment5,
          gcc.segment6 Exp_acct_segment6,
          gcc.segment7 Exp_acct_segment7,
          gcc.segment8 Exp_acct_segment8,
          gcc.segment9 Exp_acct_segment9,
          gcc.segment10 Exp_acct_segment10,
          gcc.segment11 Exp_acct_segment11,
          gcc.segment12 Exp_acct_segment12,
          gcc.segment13 Exp_acct_segment13,
          gcc.segment14 Exp_acct_segment14,
          gcc.segment15 Exp_acct_segment15,
          gcc.segment16 Exp_acct_segment16,
          gcc.segment17 Exp_acct_segment17,
          gcc.segment18 Exp_acct_segment18,
          gcc.segment19 Exp_acct_segment19,
          gcc.segment20 Exp_acct_segment20,
          gcc.segment21 Exp_acct_segment21,
          gcc.segment22 Exp_acct_segment22,
          gcc.segment23 Exp_acct_segment23,
          gcc.segment24 Exp_acct_segment24,
          gcc.segment25 Exp_acct_segment25,
          gcc.segment26 Exp_acct_segment26,
          gcc.segment27 Exp_acct_segment27,
          gcc.segment28 Exp_acct_segment28,
          gcc.segment29 Exp_acct_segment29,
          gcc.segment30 Exp_acct_segment30,
          RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.distribution_id DESC ) distidrank,
          RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.period_counter DESC) periodcounterrank
        FROM FA_DEPRN_DETAIL ds,
          FA_TRANSACTION_HEADERS fth,
          FA_CATEGORIES_B FCB,
          gl_code_combinations gcc,
          fa_locations loc,
          fa_distribution_history fd,
          FA_BOOKS fb,
          xx_fa_status xfs,
          FA_BOOK_CONTROLS corpbook,
          FA_ADDITIONS_B FAB
        WHERE 1                    =1
        AND xfs.book_type_code     =P_book_type_code--'OD US CORP'
        AND ASSET_STATUS           ='ACTIVE'
        AND corpbook.book_type_code=xfs.book_type_code
        AND corpbook.BOOK_CLASS    = 'CORPORATE'
        AND FAB.ASSET_ID           =XFS.ASSET_ID
          --and FAB.ASSET_ID not in (21417857,21418275,11896729)
        AND NOT EXISTS
          (SELECT 'x' FROM FA_ADDITIONS_B WHERE parent_asset_id = fab.ASSET_ID
          )
      AND fb.book_type_code=xfs.book_type_code
      AND fb.asset_id      = xfs.asset_id
      AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
      AND fd.asset_id               =fb.asset_id
      AND fd.date_ineffective      IS NULL
      AND fd.book_type_code         =fb.book_type_code
      AND loc.location_id           =fd.location_id
      AND gcc.code_combination_id   = fd.code_combination_id
      AND fcb.category_id           =fab.asset_category_id
      AND fth.ASSET_ID              = fab.ASSET_ID
      AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
      AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
      AND ds.asset_id               =fb.asset_id
      AND ds.book_type_code         =fb.book_type_code
        )
      WHERE distidrank     =1
      AND periodcounterrank=1
      )
    ORDER BY Interface_Line_Number;
    lc_file_handle utl_file.file_type;
    lv_line_count NUMBER;
    ---  l_file_path   VARCHAR(200);
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
    v_segment7       VARCHAR2(50);
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
    print_debug_msg ('Package ODUSCORP_CHILD_DISTRIBUTION START', TRUE);
    print_debug_msg ('P_BOOK_TYPE_CODE '||p_book_type_code, TRUE);
    v_book_type_code :=REPLACE(REPLACE (REPLACE(p_book_type_code,'OD US ','US_'),'OD CA ','CA_'),' ','_');
    -- l_file_name    := 'ODUSCORP_Child_Distribution_v15' || '.csv';
    l_file_name    := 'Child_Distribution_'||v_book_type_code|| '.csv';
    lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
    lv_col_title   :='INTERFACE_LINE_NUMBER'|| ','|| 'UNITS_ASSIGNED'|| ','|| 'EMPLOYEE_EMAIL_ADDRESS'|| ','|| 'ASSET_LOCATION_SEGMENT1'|| ','|| 'ASSET_LOCATION_SEGMENT2'|| ','|| 'ASSET_LOCATION_SEGMENT3'|| ','|| 'ASSET_LOCATION_SEGMENT4'|| ','|| 'ASSET_LOCATION_SEGMENT5'|| ','|| 'ASSET_LOCATION_SEGMENT6'|| ','|| 'ASSET_LOCATION_SEGMENT7'|| ','|| 'EXPENSE_ACCOUNT_SEGMENT';
    utl_file.put_line(lc_file_handle,lv_col_title);
    FOR i IN c_child_dist
    LOOP
      ---UTL_FILE.put_line(lc_file_handle,'HI');
      utl_file.put_line(lc_file_handle,i.interface_line_number|| ','|| i.units_assigned|| ','|| i.employee_email_address|| ','|| i.asset_location_segment1|| ','|| i.asset_location_segment2|| ','|| i.asset_location_segment3|| ','|| i.asset_location_segment4|| ','|| i.asset_location_segment5|| ','|| i.asset_location_segment6|| ','|| i.asset_location_segment7|| ','|| i.expense_account_segment);
    END LOOP;
    utl_file.fclose(lc_file_handle);
  EXCEPTION
  WHEN utl_file.access_denied THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.delete_failed THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.file_open THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.internal_error THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filehandle THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filename THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_maxlinesize THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_mode THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_offset THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_operation THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_path THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.read_error THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.rename_failed THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.write_error THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in ODUSCORP_CHILD_Distribution procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  END oduscorp_child_distribution;
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
      /* Commented by arun as split query
      (select gcc.segment1||','||gcc.segment2||','||gcc.segment3||','||gcc.segment4||','||gcc.segment5||','||
      gcc.segment6||','||gcc.segment7
      from GL_CODE_COMBINATIONS    GCC,
      fa_distribution_accounts da
      WHERE da.distribution_id = fa_details.distribution_id
      AND da.book_type_code  =  fa_details.Asset_Book
      AND gcc.code_combination_id  = da.asset_clearing_account_ccid
      ) "SG1,SG2,SG3,SG4,SG5,SG6,SG7",
      */
      (
      SELECT gcc.segment1
      FROM GL_CODE_COMBINATIONS GCC,
        fa_distribution_accounts da
      WHERE da.distribution_id    = fa_details.distribution_id
      AND da.book_type_code       = fa_details.Asset_Book
      AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
      ) COST_CLEARING_ACCOUNT_SEG1,
    (SELECT gcc.segment2
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG2,
    (SELECT gcc.segment3
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG3,
    (SELECT gcc.segment4
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG4,
    (SELECT gcc.segment5
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE DA.DISTRIBUTION_ID    = FA_DETAILS.DISTRIBUTION_ID
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG5,
    (SELECT gcc.segment6
    FROM GL_CODE_COMBINATIONS GCC,
      FA_DISTRIBUTION_ACCOUNTS DA
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG6,
    (SELECT gcc.segment7
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND DA.BOOK_TYPE_CODE       = FA_DETAILS.ASSET_BOOK
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG7,
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
    NULL ATTRIBUTE11,
    NULL ATTRIBUTE12,
    NULL ATTRIBUTE13,
    NULL ATTRIBUTE14,
    NULL ATTRIBUTE15,
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
    NULL FULLY_DEPRECIATE
  FROM
    (SELECT Interface_Line_Number,
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
      Parent_Asset,
      In_physical_inventory,
      Property_Type,
      PROPERTY_CLASS,
      distribution_id, -- commented arun
      In_use,
      Ownership,
      Bought,
      COMMITMENT ,
      INVESTMENT_LAW, -- added arun
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
      Depreciation_Limit_Type,
      Depreciation_Limit_Percent,
      Depreciation_Limit_Amount,
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
      ATTRIBUTE_CATEGORY_CODE,
      NBV_at_the_Time_of_Switch,
      Earlier_Dep_Limit_Type,
      Earlier_Dep_Limit_Percent,
      Earlier_Dep_Limit_Amount,
      Earlier_Life_in_Months,
      Earlier_Basic_Rate,
      Earlier_Adjusted_Rate
    FROM
      (SELECT
        /*+ full(ds) full(fth) */
        FAB.ASSET_ID Interface_Line_Number,
        FB.BOOK_TYPE_CODE Asset_Book,
        fth.TRANSACTION_TYPE_CODE Transaction_Name,
        FAB.ASSET_NUMBER Asset_Number,
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(fat.description,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') Asset_Description ,
        FAB.TAG_NUMBER Tag_Number,
        FAB.MANUFACTURER_NAME Manufacturer,
        FAB.SERIAL_NUMBER Serial_Number,
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
        (SELECT ASSET_NUMBER FROM fa_additions_b WHERE asset_id = fab.PARENT_ASSET_ID
        ) Parent_Asset,
        fab.INVENTORIAL In_physical_inventory,
        fab.PROPERTY_TYPE_CODE Property_Type,
        fab.PROPERTY_1245_1250_CODE Property_Class,
        fab.IN_USE_FLAG In_use,
        fab.OWNED_LEASED Ownership,
        fab.NEW_USED Bought,
        FAB.COMMITMENT ,
        fab.investment_law, -- added by Arun
        corpbook.AMORTIZE_FLAG Amortize,
        TO_CHAR(FTH.DATE_EFFECTIVE,'YYYY/MM/DD') Amortization_Start_Date,
        fb.DEPRECIATE_FLAG Depreciate,
        fb.SALVAGE_TYPE Salvage_Value_Type,
        fb.SALVAGE_VALUE Salvage_Value_Amount,
        fb.PERCENT_SALVAGE_VALUE Salvage_Value_Percent,
        ds.YTD_DEPRN YTD_Depreciation,
        ds.DEPRN_RESERVE Depreciation_Reserve,
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
        FCB.ATTRIBUTE1 ATTRIBUTE1,
        FCB.ATTRIBUTE2 ATTRIBUTE2,
        FCB.ATTRIBUTE3 ATTRIBUTE3,
        FCB.ATTRIBUTE4 ATTRIBUTE4,
        FCB.ATTRIBUTE5 ATTRIBUTE5,
        FCB.ATTRIBUTE6 ATTRIBUTE6,
        FCB.ATTRIBUTE7 ATTRIBUTE7,
        FCB.ATTRIBUTE8 ATTRIBUTE8,
        FCB.ATTRIBUTE9 ATTRIBUTE9,
        FCB.ATTRIBUTE10 ATTRIBUTE10,
        FCB.ATTRIBUTE_CATEGORY_CODE ATTRIBUTE_CATEGORY_CODE,
        fb.NBV_AT_SWITCH NBV_at_the_Time_of_Switch,
        fb.PRIOR_DEPRN_LIMIT_TYPE Earlier_Dep_Limit_Type,
        fb.PRIOR_DEPRN_LIMIT Earlier_Dep_Limit_Percent,
        fb.PRIOR_DEPRN_LIMIT_AMOUNT Earlier_Dep_Limit_Amount,
        fb.PRIOR_LIFE_IN_MONTHS Earlier_Life_in_Months,
        fb.PRIOR_BASIC_RATE Earlier_Basic_Rate,
        fb.PRIOR_ADJUSTED_RATE Earlier_Adjusted_Rate,
        ds.distribution_id,
        --fb.book_type_code,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.distribution_id DESC ) distidrank,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.period_counter DESC) periodcounterrank
      FROM FA_BOOKS fb,
        xx_fa_status xfs,
        FA_BOOK_CONTROLS corpbook,
        FA_ADDITIONS_B FAB,
        FA_CATEGORIES_B FCB,
        FA_ADDITIONS_TL FAT,
        FA_DEPRN_DETAIL ds,
        FA_TRANSACTION_HEADERS fth
      WHERE 1                    =1
      AND xfs.book_type_code     =p_book_type_code
      AND xfs.ASSET_STATUS       ='ACTIVE'
      AND fb.book_type_code      =xfs.book_type_code
      AND fb.asset_id            = xfs.asset_id
      AND corpbook.book_type_code=FB.book_type_code
      AND corpbook.BOOK_CLASS    = 'TAX'
      AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
      AND fab.ASSET_ID=fb.ASSET_ID
        --and fab.asset_id not in (21417857,21418275,11896729)
      AND fab.parent_asset_id IS NULL
      AND EXISTS
        (SELECT 'x' FROM FA_ADDITIONS_B WHERE PARENT_ASSET_ID = FAB.ASSET_ID
        )
      AND fcb.category_id           =fab.asset_category_id
      AND fat.ASSET_ID              =fab.ASSET_ID
      AND fat.language              = 'US'
      AND ds.asset_id               =fb.asset_id
      AND ds.book_type_code         =fb.book_type_code
      AND fth.ASSET_ID              = fab.ASSET_ID
      AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
      AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
      )
    WHERE distidrank      = 1
    AND periodcounterrank = 1
    ) FA_DETAILS
  ORDER BY interface_line_number;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  --  l_file_path   VARCHAR(200);
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
  v_segment7       VARCHAR2(50);
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
  print_debug_msg ('Package GENERIC_TAX_PARENT_ASSET_HDR START', TRUE);
  print_debug_msg ('P_BOOK_TYPE_CODE '||p_book_type_code, TRUE);
  v_book_type_code :=REPLACE(REPLACE (REPLACE(p_book_type_code,'OD US ','US_'),'OD CA ','CA_'),' ','_');
  --l_file_name    := 'Generic_TAX_Parent_Asset_Hdr_v14' || '.csv';
  l_file_name    := 'Generic_TAX_Parent_Asset_Hdr_'||v_book_type_code|| '.csv';
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='INTERFACE_LINE_NUMBER'|| ','|| 'ASSET_BOOK'|| ','|| 'TRANSACTION_NAME'|| ','|| 'ASSET_NUMBER'|| ','|| 'ASSET_DESCRIPTION'|| ','|| 'TAG_NUMBER'|| ','|| 'MANUFACTURER'|| ','|| 'SERIAL_NUMBER'|| ','|| 'MODEL'|| ','|| 'ASSET_TYPE'|| ','|| 'COST'|| ','|| 'DATE_PLACED_IN_SERVICE'|| ','|| 'PRORATE_CONVENTION'|| ','|| 'ASSET_UNITS'|| ','|| 'ASSET_CATEGORY_SEGMENT1'|| ','|| 'ASSET_CATEGORY_SEGMENT2'|| ','|| 'ASSET_CATEGORY_SEGMENT3'|| ','|| 'ASSET_CATEGORY_SEGMENT4'|| ','|| 'ASSET_CATEGORY_SEGMENT5'|| ','|| 'ASSET_CATEGORY_SEGMENT6'|| ','|| 'ASSET_CATEGORY_SEGMENT7'|| ','|| 'POSTING_STATUS'|| ','|| 'QUEUE_NAME'|| ','|| 'FEEDER_SYSTEM'|| ','|| 'PARENT_ASSET'|| ','|| 'ADD_TO_ASSET'|| ','|| 'ASSET_KEY_SEGMENT1'|| ','|| 'ASSET_KEY_SEGMENT2'|| ','|| 'ASSET_KEY_SEGMENT3'|| ','|| 'ASSET_KEY_SEGMENT4'|| ','|| 'ASSET_KEY_SEGMENT5'|| ','|| 'ASSET_KEY_SEGMENT6'|| ','|| 'ASSET_KEY_SEGMENT7'|| ','|| 'ASSET_KEY_SEGMENT8'|| ','|| 'ASSET_KEY_SEGMENT9'|| ','|| 'ASSET_KEY_SEGMENT10'|| ','||
  'IN_PHYSICAL_INVENTORY'|| ','|| 'PROPERTY_TYPE'|| ','|| 'PROPERTY_CLASS'|| ','|| 'IN_USE'|| ','|| 'OWNERSHIP'|| ','|| 'BOUGHT'|| ','|| 'MATERIAL_INDICATOR'|| ','|| 'COMMITMENT'|| ','|| 'INVESTMENT_LAW'|| ','|| 'AMORTIZE'|| ','|| 'AMORTIZATION_START_DATE'|| ','|| 'DEPRECIATE'|| ','|| 'SALVAGE_VALUE_TYPE'|| ','|| 'SALVAGE_VALUE_AMOUNT'|| ','|| 'SALVAGE_VALUE_PERCENT'|| ','|| 'YTD_DEPRECIATION'|| ','|| 'DEPRECIATION_RESERVE'|| ','|| 'YTD_BONUS_DEPRECIATION'|| ','|| 'BONUS_DEPRECIATION_RESERVE'|| ','|| 'YTD_IMPAIRMENT'|| ','|| 'IMPAIRMENT_RESERVE'|| ','|| 'DEPRECIATION_METHOD'|| ','|| 'LIFE_IN_MONTHS'|| ','|| 'BASIC_RATE'|| ','|| 'ADJUSTED_RATE'|| ','|| 'UNIT_OF_MEASURE'|| ','|| 'PRODUCTION_CAPACITY'|| ','|| 'CEILING_TYPE'|| ','|| 'BONUS_RULE'|| ','|| 'CASH_GENERATING_UNIT'|| ','|| 'DEPRECIATION_LIMIT_TYPE'|| ','|| 'DEPRECIATION_LIMIT_PERCENT'|| ','|| 'DEPRECIATION_LIMIT_AMOUNT'|| ','|| 'INVOICE_COST'|| ','|| 'COST_CLEARING_ACCOUNT_SEG1'|| ','|| 'COST_CLEARING_ACCOUNT_SEG2'|| ','||
  'COST_CLEARING_ACCOUNT_SEG3'|| ','|| 'COST_CLEARING_ACCOUNT_SEG4'|| ','|| 'COST_CLEARING_ACCOUNT_SEG5'|| ','|| 'COST_CLEARING_ACCOUNT_SEG6'|| ','|| 'COST_CLEARING_ACCOUNT_SEG7'|| ','|| 'COST_CLEARING_ACCOUNT_SEG8'|| ','|| 'COST_CLEARING_ACCOUNT_SEG9'|| ','|| 'COST_CLEARING_ACCOUNT_SEG10'|| ','|| 'COST_CLEARING_ACCOUNT_SEG11'|| ','|| 'COST_CLEARING_ACCOUNT_SEG12'|| ','|| 'COST_CLEARING_ACCOUNT_SEG13'|| ','|| 'COST_CLEARING_ACCOUNT_SEG14'|| ','|| 'COST_CLEARING_ACCOUNT_SEG15'|| ','|| 'ATTRIBUTE1'|| ','|| 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','|| 'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'|| ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10'|| ','|| 'ATTRIBUTE11'|| ','|| 'ATTRIBUTE12'|| ','|| 'ATTRIBUTE13'|| ','|| 'ATTRIBUTE14'|| ','|| 'ATTRIBUTE15'|| ','|| 'ATTRIBUTE_CATEGORY_CODE'|| ','|| 'CONTEXT'|| ','|| 'MASS_PROPERTY_ELIGIBLE'|| ','|| 'GROUP_ASSET'|| ','|| 'REDUCTION_RATE'|| ','|| 'APPLY_REDUCTION_RATE_TO_ADDI'|| ','||
  'APPLY_REDUCTION_RATE_TO_ADJ'|| ','|| 'APPLY_REDUCTION_RATE_TO_RETI'|| ','|| 'RECOGNIZE_GAIN_OR_LOSS'|| ','|| 'RECAPTURE_EXCESS_RESERVE'|| ','|| 'LIMIT_NET_PROCEEDS_TO_COST'|| ','|| 'TERMINAL_GAIN_OR_LOSS'|| ','|| 'TRACKING_METHOD'|| ','|| 'ALLOCATE_EXCESS_DEPRECIATION'|| ','|| 'DEPRECIATE_BY'|| ','|| 'MEMBER_ROLLUP'|| ','|| 'ALLO_TO_FULL_RETI_AND_RES_ASST'|| ','|| 'OVER_DEPRECIATE'|| ','|| 'PREPARER'|| ','|| 'SUM_MERGED_UNITS'|| ','|| 'NEW_MASTER'|| ','|| 'UNITS_TO_ADJUST'|| ','|| 'SHORT_YEAR'|| ','|| 'CONVERSION_DATE'|| ','|| 'ORIGINAL_DEP_START_DATE'|| ','|| 'NBV_AT_THE_TIME_OF_SWITCH'|| ','|| 'PERIOD_FULLY_RESERVED'|| ','|| 'START_PERIOD_OF_EXTENDED_DEP'|| ','|| 'EARLIER_DEP_LIMIT_TYPE'|| ','|| 'EARLIER_DEP_LIMIT_PERCENT'|| ','|| 'EARLIER_DEP_LIMIT_AMOUNT'|| ','|| 'EARLIER_DEPRECIATION_METHOD'|| ','|| 'EARLIER_LIFE_IN_MONTHS'|| ','|| 'EARLIER_BASIC_RATE'|| ','|| 'EARLIER_ADJUSTED_RATE'|| ','|| 'LEASE_NUMBER'|| ','|| 'REVALUATION_RESERVE'|| ','|| 'REVALUATION_LOSS'|| ','||
  'REVAL_RESER_AMORTIZATION_BASIS'|| ','|| 'IMPAIRMENT_LOSS_EXPENSE'|| ','|| 'REVALUATION_COST_CEILING'|| ','|| 'FAIR_VALUE'|| ','|| 'LAST_USED_PRICE_INDEX_VALUE'|| ','|| 'SUPPLIER_NAME'|| ','|| 'SUPPLIER_NUMBER'|| ','|| 'PURCHASE_ORDER_NUMBER'|| ','|| 'INVOICE_NUMBER'|| ','|| 'INVOICE_VOUCHER_NUMBER'|| ','|| 'INVOICE_DATE'|| ','|| 'PAYABLES_UNITS'|| ','|| 'INVOICE_LINE_NUMBER'|| ','|| 'INVOICE_LINE_TYPE'|| ','|| 'INVOICE_LINE_DESCRIPTION'|| ','|| 'INVOICE_PAYMENT_NUMBER'|| ','|| 'PROJECT_NUMBER'|| ','|| 'TASK_NUMBER'|| ','|| 'FULLY_DEPRECIATE';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_tax_par_asset_hdr
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,i.interface_line_number|| ','|| i.asset_book|| ','|| i.transaction_name|| ','|| i.asset_number|| ','|| i.asset_description|| ','|| i.tag_number|| ','|| i.manufacturer|| ','|| i.serial_number|| ','|| i.model|| ','|| i.asset_type|| ','|| i.cost|| ','|| i.date_placed_in_service|| ','|| i.prorate_convention|| ','|| i.asset_units|| ','|| i.asset_category_segment1|| ','|| i.asset_category_segment2|| ','|| i.asset_category_segment3|| ','|| i.asset_category_segment4|| ','|| i.asset_category_segment5|| ','|| i.asset_category_segment6|| ','|| i.asset_category_segment7|| ','|| i.posting_status|| ','|| i.queue_name|| ','|| i.feeder_system|| ','|| i.parent_asset|| ','|| i.add_to_asset|| ','|| i.asset_key_segment1|| ','|| i.asset_key_segment2|| ','|| i.asset_key_segment3|| ','|| i.asset_key_segment4|| ','|| i.asset_key_segment5|| ','|| i.asset_key_segment6|| ','|| i.asset_key_segment7|| ','|| i.asset_key_segment8|| ','|| i.asset_key_segment9|| ','||
    i.asset_key_segment10|| ','|| i.in_physical_inventory|| ','|| i.property_type|| ','|| i.property_class|| ','|| i.in_use|| ','|| i.ownership|| ','|| i.bought|| ','|| i.material_indicator|| ','|| i.commitment|| ','|| i.investment_law|| ','|| i.amortize|| ','|| i.amortization_start_date|| ','|| i.depreciate|| ','|| i.salvage_value_type|| ','|| i.salvage_value_amount|| ','|| i.salvage_value_percent|| ','|| i.ytd_depreciation|| ','|| i.depreciation_reserve|| ','|| i.ytd_bonus_depreciation|| ','|| i.bonus_depreciation_reserve|| ','|| i.ytd_impairment|| ','|| i.impairment_reserve|| ','|| i.depreciation_method|| ','|| i.life_in_months|| ','|| i.basic_rate|| ','|| i.adjusted_rate|| ','|| i.unit_of_measure|| ','|| i.production_capacity|| ','|| i.ceiling_type|| ','|| i.bonus_rule|| ','|| i.cash_generating_unit|| ','|| i.depreciation_limit_type|| ','|| i.depreciation_limit_percent|| ','|| i.depreciation_limit_amount|| ','|| i.invoice_cost|| ','|| i.cost_clearing_account_seg1|| ','||
    i.cost_clearing_account_seg2|| ','|| i.cost_clearing_account_seg3|| ','|| i.cost_clearing_account_seg4|| ','|| i.cost_clearing_account_seg5|| ','|| i.cost_clearing_account_seg6|| ','|| i.cost_clearing_account_seg7|| ','|| i.cost_clearing_account_seg8|| ','|| i.cost_clearing_account_seg9|| ','|| i.cost_clearing_account_seg10|| ','|| i.cost_clearing_account_seg11|| ','|| i.cost_clearing_account_seg12|| ','|| i.cost_clearing_account_seg13|| ','|| i.cost_clearing_account_seg14|| ','|| i.cost_clearing_account_seg15|| ','|| i.attribute1|| ','|| i.attribute2|| ','|| i.attribute3|| ','|| i.attribute4|| ','|| i.attribute5|| ','|| i.attribute6|| ','|| i.attribute7|| ','|| i.attribute8|| ','|| i.attribute9|| ','|| i.attribute10|| ','|| i.attribute11|| ','|| i.attribute12|| ','|| i.attribute13|| ','|| i.attribute14|| ','|| i.attribute15|| ','|| i.attribute_category_code|| ','|| i.context|| ','|| i.mass_property_eligible|| ','|| i.group_asset|| ','|| i.reduction_rate|| ','||
    i.apply_reduction_rate_to_addi|| ','|| i.apply_reduction_rate_to_adj|| ','|| i.apply_reduction_rate_to_reti|| ','|| i.recognize_gain_or_loss|| ','|| i.recapture_excess_reserve|| ','|| i.limit_net_proceeds_to_cost|| ','|| i.terminal_gain_or_loss|| ','|| i.tracking_method|| ','|| i.allocate_excess_depreciation|| ','|| i.depreciate_by|| ','|| i.member_rollup|| ','|| i.allo_to_full_reti_and_res_asst|| ','|| i.over_depreciate|| ','|| i.preparer|| ','|| i.sum_merged_units|| ','|| i.new_master|| ','|| i.units_to_adjust|| ','|| i.short_year|| ','|| i.conversion_date|| ','|| i.original_dep_start_date|| ','|| i.nbv_at_the_time_of_switch|| ','|| i.period_fully_reserved|| ','|| i.start_period_of_extended_dep|| ','|| i.earlier_dep_limit_type|| ','|| i.earlier_dep_limit_percent|| ','|| i.earlier_dep_limit_amount|| ','|| i.earlier_depreciation_method|| ','|| i.earlier_life_in_months|| ','|| i.earlier_basic_rate|| ','|| i.earlier_adjusted_rate|| ','|| i.lease_number|| ','|| i.revaluation_reserve
    || ','|| i.revaluation_loss|| ','|| i.reval_reser_amortization_basis|| ','|| i.impairment_loss_expense|| ','|| i.revaluation_cost_ceiling|| ','|| i.fair_value|| ','|| i.last_used_price_index_value|| ','|| i.supplier_name|| ','|| i.supplier_number|| ','|| i.purchase_order_number|| ','|| i.invoice_number|| ','|| i.invoice_voucher_number|| ','|| i.invoice_date|| ','|| i.payables_units|| ','|| i.invoice_line_number|| ','|| i.invoice_line_type|| ','|| i.invoice_line_description|| ','|| i.invoice_payment_number|| ','|| i.project_number|| ','|| i.task_number|| ','|| i.fully_depreciate);
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  -- lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_ASSET_HDR procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END generic_tax_parent_asset_hdr;
PROCEDURE generic_tax_child_asset_hdr(
    p_book_type_code VARCHAR2)
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
      /* Commented by arun as split query
      (select gcc.segment1||','||gcc.segment2||','||gcc.segment3||','||gcc.segment4||','||gcc.segment5||','||
      gcc.segment6||','||gcc.segment7
      from GL_CODE_COMBINATIONS    GCC,
      fa_distribution_accounts da
      WHERE da.distribution_id = fa_details.distribution_id
      AND da.book_type_code  =  fa_details.Asset_Book
      AND gcc.code_combination_id  = da.asset_clearing_account_ccid
      ) "SG1,SG2,SG3,SG4,SG5,SG6,SG7",
      */
      (
      SELECT gcc.segment1
      FROM GL_CODE_COMBINATIONS GCC,
        fa_distribution_accounts da
      WHERE da.distribution_id    = fa_details.distribution_id
      AND da.book_type_code       = fa_details.Asset_Book
      AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
      ) COST_CLEARING_ACCOUNT_SEG1,
    (SELECT gcc.segment2
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG2,
    (SELECT gcc.segment3
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG3,
    (SELECT gcc.segment4
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG4,
    (SELECT gcc.segment5
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE DA.DISTRIBUTION_ID    = FA_DETAILS.DISTRIBUTION_ID
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG5,
    (SELECT gcc.segment6
    FROM GL_CODE_COMBINATIONS GCC,
      FA_DISTRIBUTION_ACCOUNTS DA
    WHERE da.distribution_id    = fa_details.distribution_id
    AND da.book_type_code       = fa_details.Asset_Book
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG6,
    (SELECT gcc.segment7
    FROM GL_CODE_COMBINATIONS GCC,
      fa_distribution_accounts da
    WHERE da.distribution_id    = fa_details.distribution_id
    AND DA.BOOK_TYPE_CODE       = FA_DETAILS.ASSET_BOOK
    AND GCC.CODE_COMBINATION_ID = DA.ASSET_CLEARING_ACCOUNT_CCID
    ) COST_CLEARING_ACCOUNT_SEG7,
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
    NULL ATTRIBUTE11,
    NULL ATTRIBUTE12,
    NULL ATTRIBUTE13,
    NULL ATTRIBUTE14,
    NULL ATTRIBUTE15,
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
    NULL FULLY_DEPRECIATE
  FROM
    (SELECT Interface_Line_Number,
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
      Parent_Asset,
      In_physical_inventory,
      Property_Type,
      PROPERTY_CLASS,
      distribution_id, -- commented arun
      In_use,
      Ownership,
      Bought,
      COMMITMENT ,
      INVESTMENT_LAW, -- added arun
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
      Depreciation_Limit_Type,
      Depreciation_Limit_Percent,
      Depreciation_Limit_Amount,
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
      ATTRIBUTE_CATEGORY_CODE,
      NBV_at_the_Time_of_Switch,
      Earlier_Dep_Limit_Type,
      Earlier_Dep_Limit_Percent,
      Earlier_Dep_Limit_Amount,
      Earlier_Life_in_Months,
      Earlier_Basic_Rate,
      Earlier_Adjusted_Rate
    FROM
      (SELECT
        /*+ full(ds) full(fth) */
        FAB.ASSET_ID Interface_Line_Number,
        FB.BOOK_TYPE_CODE Asset_Book,
        fth.TRANSACTION_TYPE_CODE Transaction_Name,
        FAB.ASSET_NUMBER Asset_Number,
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(fat.description,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') Asset_Description ,
        FAB.TAG_NUMBER Tag_Number,
        FAB.MANUFACTURER_NAME Manufacturer,
        FAB.SERIAL_NUMBER Serial_Number,
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
        --               (SELECT ASSET_NUMBER
        --                       FROM fa_additions_b
        --                      WHERE asset_id = fab.PARENT_ASSET_ID)  Parent_Asset,
        (
        SELECT xxfss.ASSET_ID
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
        corpbook.AMORTIZE_FLAG Amortize,
        TO_CHAR(FTH.DATE_EFFECTIVE,'YYYY/MM/DD') Amortization_Start_Date,
        fb.DEPRECIATE_FLAG Depreciate,
        fb.SALVAGE_TYPE Salvage_Value_Type,
        fb.SALVAGE_VALUE Salvage_Value_Amount,
        fb.PERCENT_SALVAGE_VALUE Salvage_Value_Percent,
        ds.YTD_DEPRN YTD_Depreciation,
        ds.DEPRN_RESERVE Depreciation_Reserve,
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
        FCB.ATTRIBUTE1 ATTRIBUTE1,
        FCB.ATTRIBUTE2 ATTRIBUTE2,
        FCB.ATTRIBUTE3 ATTRIBUTE3,
        FCB.ATTRIBUTE4 ATTRIBUTE4,
        FCB.ATTRIBUTE5 ATTRIBUTE5,
        FCB.ATTRIBUTE6 ATTRIBUTE6,
        FCB.ATTRIBUTE7 ATTRIBUTE7,
        FCB.ATTRIBUTE8 ATTRIBUTE8,
        FCB.ATTRIBUTE9 ATTRIBUTE9,
        FCB.ATTRIBUTE10 ATTRIBUTE10,
        FCB.ATTRIBUTE_CATEGORY_CODE ATTRIBUTE_CATEGORY_CODE,
        fb.NBV_AT_SWITCH NBV_at_the_Time_of_Switch,
        fb.PRIOR_DEPRN_LIMIT_TYPE Earlier_Dep_Limit_Type,
        fb.PRIOR_DEPRN_LIMIT Earlier_Dep_Limit_Percent,
        fb.PRIOR_DEPRN_LIMIT_AMOUNT Earlier_Dep_Limit_Amount,
        fb.PRIOR_LIFE_IN_MONTHS Earlier_Life_in_Months,
        fb.PRIOR_BASIC_RATE Earlier_Basic_Rate,
        fb.PRIOR_ADJUSTED_RATE Earlier_Adjusted_Rate,
        ds.distribution_id,
        --fb.book_type_code,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.distribution_id DESC ) distidrank,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.period_counter DESC) periodcounterrank
      FROM FA_BOOKS fb,
        xx_fa_status xfs,
        FA_BOOK_CONTROLS corpbook,
        FA_ADDITIONS_B FAB,
        FA_CATEGORIES_B FCB,
        FA_ADDITIONS_TL FAT,
        FA_DEPRN_DETAIL ds,
        FA_TRANSACTION_HEADERS fth
      WHERE 1                    =1
      AND xfs.book_type_code     =p_book_type_code
      AND ASSET_STATUS           ='ACTIVE'
      AND fb.book_type_code      =xfs.book_type_code
      AND fb.asset_id            = xfs.asset_id
      AND corpbook.book_type_code=FB.book_type_code
      AND corpbook.BOOK_CLASS    = 'TAX'
      AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
      AND fab.ASSET_ID=fb.ASSET_ID
        --and fab.asset_id not in (21417857,21418275,11896729)
      AND NOT EXISTS
        (SELECT 'x' FROM FA_ADDITIONS_B WHERE parent_asset_id = fab.ASSET_ID
        )
      AND fcb.category_id           =fab.asset_category_id
      AND fat.ASSET_ID              =fab.ASSET_ID
      AND fat.language              = 'US'
      AND ds.asset_id               =fb.asset_id
      AND ds.book_type_code         =fb.book_type_code
      AND fth.ASSET_ID              = fab.ASSET_ID
      AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
      AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
      )
    WHERE distidrank      = 1
    AND periodcounterrank = 1
    ) FA_DETAILS
  ORDER BY interface_line_number;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  ---l_file_path   VARCHAR(200);
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
  v_segment7       VARCHAR2(50);
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
  print_debug_msg ('Package GENERIC_TAX_CHILD_ASSET_HDR START', TRUE);
  print_debug_msg ('P_BOOK_TYPE_CODE '||p_book_type_code, TRUE);
  -- l_file_name    := 'Generic_TAX_Child_Asset_Hdr_v14' || '.csv';
  v_book_type_code :=REPLACE(REPLACE (REPLACE(p_book_type_code,'OD US ','US_'),'OD CA ','CA_'),' ','_');
  l_file_name      := 'Generic_TAX_Child_Asset_Hdr_'||v_book_type_code|| '.csv';
  lc_file_handle   := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title     :='INTERFACE_LINE_NUMBER'|| ','|| 'ASSET_BOOK'|| ','|| 'TRANSACTION_NAME'|| ','|| 'ASSET_NUMBER'|| ','|| 'ASSET_DESCRIPTION'|| ','|| 'TAG_NUMBER'|| ','|| 'MANUFACTURER'|| ','|| 'SERIAL_NUMBER'|| ','|| 'MODEL'|| ','|| 'ASSET_TYPE'|| ','|| 'COST'|| ','|| 'DATE_PLACED_IN_SERVICE'|| ','|| 'PRORATE_CONVENTION'|| ','|| 'ASSET_UNITS'|| ','|| 'ASSET_CATEGORY_SEGMENT1'|| ','|| 'ASSET_CATEGORY_SEGMENT2'|| ','|| 'ASSET_CATEGORY_SEGMENT3'|| ','|| 'ASSET_CATEGORY_SEGMENT4'|| ','|| 'ASSET_CATEGORY_SEGMENT5'|| ','|| 'ASSET_CATEGORY_SEGMENT6'|| ','|| 'ASSET_CATEGORY_SEGMENT7'|| ','|| 'POSTING_STATUS'|| ','|| 'QUEUE_NAME'|| ','|| 'FEEDER_SYSTEM'|| ','|| 'PARENT_ASSET'|| ','|| 'ADD_TO_ASSET'|| ','|| 'ASSET_KEY_SEGMENT1'|| ','|| 'ASSET_KEY_SEGMENT2'|| ','|| 'ASSET_KEY_SEGMENT3'|| ','|| 'ASSET_KEY_SEGMENT4'|| ','|| 'ASSET_KEY_SEGMENT5'|| ','|| 'ASSET_KEY_SEGMENT6'|| ','|| 'ASSET_KEY_SEGMENT7'|| ','|| 'ASSET_KEY_SEGMENT8'|| ','|| 'ASSET_KEY_SEGMENT9'|| ','|| 'ASSET_KEY_SEGMENT10'|| ','
  || 'IN_PHYSICAL_INVENTORY'|| ','|| 'PROPERTY_TYPE'|| ','|| 'PROPERTY_CLASS'|| ','|| 'IN_USE'|| ','|| 'OWNERSHIP'|| ','|| 'BOUGHT'|| ','|| 'MATERIAL_INDICATOR'|| ','|| 'COMMITMENT'|| ','|| 'INVESTMENT_LAW'|| ','|| 'AMORTIZE'|| ','|| 'AMORTIZATION_START_DATE'|| ','|| 'DEPRECIATE'|| ','|| 'SALVAGE_VALUE_TYPE'|| ','|| 'SALVAGE_VALUE_AMOUNT'|| ','|| 'SALVAGE_VALUE_PERCENT'|| ','|| 'YTD_DEPRECIATION'|| ','|| 'DEPRECIATION_RESERVE'|| ','|| 'YTD_BONUS_DEPRECIATION'|| ','|| 'BONUS_DEPRECIATION_RESERVE'|| ','|| 'YTD_IMPAIRMENT'|| ','|| 'IMPAIRMENT_RESERVE'|| ','|| 'DEPRECIATION_METHOD'|| ','|| 'LIFE_IN_MONTHS'|| ','|| 'BASIC_RATE'|| ','|| 'ADJUSTED_RATE'|| ','|| 'UNIT_OF_MEASURE'|| ','|| 'PRODUCTION_CAPACITY'|| ','|| 'CEILING_TYPE'|| ','|| 'BONUS_RULE'|| ','|| 'CASH_GENERATING_UNIT'|| ','|| 'DEPRECIATION_LIMIT_TYPE'|| ','|| 'DEPRECIATION_LIMIT_PERCENT'|| ','|| 'DEPRECIATION_LIMIT_AMOUNT'|| ','|| 'INVOICE_COST'|| ','|| 'COST_CLEARING_ACCOUNT_SEG1'|| ','|| 'COST_CLEARING_ACCOUNT_SEG2'|| ','||
  'COST_CLEARING_ACCOUNT_SEG3'|| ','|| 'COST_CLEARING_ACCOUNT_SEG4'|| ','|| 'COST_CLEARING_ACCOUNT_SEG5'|| ','|| 'COST_CLEARING_ACCOUNT_SEG6'|| ','|| 'COST_CLEARING_ACCOUNT_SEG7'|| ','|| 'COST_CLEARING_ACCOUNT_SEG8'|| ','|| 'COST_CLEARING_ACCOUNT_SEG9'|| ','|| 'COST_CLEARING_ACCOUNT_SEG10'|| ','|| 'COST_CLEARING_ACCOUNT_SEG11'|| ','|| 'COST_CLEARING_ACCOUNT_SEG12'|| ','|| 'COST_CLEARING_ACCOUNT_SEG13'|| ','|| 'COST_CLEARING_ACCOUNT_SEG14'|| ','|| 'COST_CLEARING_ACCOUNT_SEG15'|| ','|| 'ATTRIBUTE1'|| ','|| 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','|| 'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'|| ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10'|| ','|| 'ATTRIBUTE11'|| ','|| 'ATTRIBUTE12'|| ','|| 'ATTRIBUTE13'|| ','|| 'ATTRIBUTE14'|| ','|| 'ATTRIBUTE15'|| ','|| 'ATTRIBUTE_CATEGORY_CODE'|| ','|| 'CONTEXT'|| ','|| 'MASS_PROPERTY_ELIGIBLE'|| ','|| 'GROUP_ASSET'|| ','|| 'REDUCTION_RATE'|| ','|| 'APPLY_REDUCTION_RATE_TO_ADDI'|| ','||
  'APPLY_REDUCTION_RATE_TO_ADJ'|| ','|| 'APPLY_REDUCTION_RATE_TO_RETI'|| ','|| 'RECOGNIZE_GAIN_OR_LOSS'|| ','|| 'RECAPTURE_EXCESS_RESERVE'|| ','|| 'LIMIT_NET_PROCEEDS_TO_COST'|| ','|| 'TERMINAL_GAIN_OR_LOSS'|| ','|| 'TRACKING_METHOD'|| ','|| 'ALLOCATE_EXCESS_DEPRECIATION'|| ','|| 'DEPRECIATE_BY'|| ','|| 'MEMBER_ROLLUP'|| ','|| 'ALLO_TO_FULL_RETI_AND_RES_ASST'|| ','|| 'OVER_DEPRECIATE'|| ','|| 'PREPARER'|| ','|| 'SUM_MERGED_UNITS'|| ','|| 'NEW_MASTER'|| ','|| 'UNITS_TO_ADJUST'|| ','|| 'SHORT_YEAR'|| ','|| 'CONVERSION_DATE'|| ','|| 'ORIGINAL_DEP_START_DATE'|| ','|| 'NBV_AT_THE_TIME_OF_SWITCH'|| ','|| 'PERIOD_FULLY_RESERVED'|| ','|| 'START_PERIOD_OF_EXTENDED_DEP'|| ','|| 'EARLIER_DEP_LIMIT_TYPE'|| ','|| 'EARLIER_DEP_LIMIT_PERCENT'|| ','|| 'EARLIER_DEP_LIMIT_AMOUNT'|| ','|| 'EARLIER_DEPRECIATION_METHOD'|| ','|| 'EARLIER_LIFE_IN_MONTHS'|| ','|| 'EARLIER_BASIC_RATE'|| ','|| 'EARLIER_ADJUSTED_RATE'|| ','|| 'LEASE_NUMBER'|| ','|| 'REVALUATION_RESERVE'|| ','|| 'REVALUATION_LOSS'|| ','||
  'REVAL_RESER_AMORTIZATION_BASIS'|| ','|| 'IMPAIRMENT_LOSS_EXPENSE'|| ','|| 'REVALUATION_COST_CEILING'|| ','|| 'FAIR_VALUE'|| ','|| 'LAST_USED_PRICE_INDEX_VALUE'|| ','|| 'SUPPLIER_NAME'|| ','|| 'SUPPLIER_NUMBER'|| ','|| 'PURCHASE_ORDER_NUMBER'|| ','|| 'INVOICE_NUMBER'|| ','|| 'INVOICE_VOUCHER_NUMBER'|| ','|| 'INVOICE_DATE'|| ','|| 'PAYABLES_UNITS'|| ','|| 'INVOICE_LINE_NUMBER'|| ','|| 'INVOICE_LINE_TYPE'|| ','|| 'INVOICE_LINE_DESCRIPTION'|| ','|| 'INVOICE_PAYMENT_NUMBER'|| ','|| 'PROJECT_NUMBER'|| ','|| 'TASK_NUMBER'|| ','|| 'FULLY_DEPRECIATE';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_tax_child_asset_hdr
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,i.interface_line_number|| ','|| i.asset_book|| ','|| i.transaction_name|| ','|| i.asset_number|| ','|| i.asset_description|| ','|| i.tag_number|| ','|| i.manufacturer|| ','|| i.serial_number|| ','|| i.model|| ','|| i.asset_type|| ','|| i.cost|| ','|| i.date_placed_in_service|| ','|| i.prorate_convention|| ','|| i.asset_units|| ','|| i.asset_category_segment1|| ','|| i.asset_category_segment2|| ','|| i.asset_category_segment3|| ','|| i.asset_category_segment4|| ','|| i.asset_category_segment5|| ','|| i.asset_category_segment6|| ','|| i.asset_category_segment7|| ','|| i.posting_status|| ','|| i.queue_name|| ','|| i.feeder_system|| ','|| i.parent_asset|| ','|| i.add_to_asset|| ','|| i.asset_key_segment1|| ','|| i.asset_key_segment2|| ','|| i.asset_key_segment3|| ','|| i.asset_key_segment4|| ','|| i.asset_key_segment5|| ','|| i.asset_key_segment6|| ','|| i.asset_key_segment7|| ','|| i.asset_key_segment8|| ','|| i.asset_key_segment9|| ','||
    i.asset_key_segment10|| ','|| i.in_physical_inventory|| ','|| i.property_type|| ','|| i.property_class|| ','|| i.in_use|| ','|| i.ownership|| ','|| i.bought|| ','|| i.material_indicator|| ','|| i.commitment|| ','|| i.investment_law|| ','|| i.amortize|| ','|| i.amortization_start_date|| ','|| i.depreciate|| ','|| i.salvage_value_type|| ','|| i.salvage_value_amount|| ','|| i.salvage_value_percent|| ','|| i.ytd_depreciation|| ','|| i.depreciation_reserve|| ','|| i.ytd_bonus_depreciation|| ','|| i.bonus_depreciation_reserve|| ','|| i.ytd_impairment|| ','|| i.impairment_reserve|| ','|| i.depreciation_method|| ','|| i.life_in_months|| ','|| i.basic_rate|| ','|| i.adjusted_rate|| ','|| i.unit_of_measure|| ','|| i.production_capacity|| ','|| i.ceiling_type|| ','|| i.bonus_rule|| ','|| i.cash_generating_unit|| ','|| i.depreciation_limit_type|| ','|| i.depreciation_limit_percent|| ','|| i.depreciation_limit_amount|| ','|| i.invoice_cost|| ','|| i.cost_clearing_account_seg1|| ','||
    i.cost_clearing_account_seg2|| ','|| i.cost_clearing_account_seg3|| ','|| i.cost_clearing_account_seg4|| ','|| i.cost_clearing_account_seg5|| ','|| i.cost_clearing_account_seg6|| ','|| i.cost_clearing_account_seg7|| ','|| i.cost_clearing_account_seg8|| ','|| i.cost_clearing_account_seg9|| ','|| i.cost_clearing_account_seg10|| ','|| i.cost_clearing_account_seg11|| ','|| i.cost_clearing_account_seg12|| ','|| i.cost_clearing_account_seg13|| ','|| i.cost_clearing_account_seg14|| ','|| i.cost_clearing_account_seg15|| ','|| i.attribute1|| ','|| i.attribute2|| ','|| i.attribute3|| ','|| i.attribute4|| ','|| i.attribute5|| ','|| i.attribute6|| ','|| i.attribute7|| ','|| i.attribute8|| ','|| i.attribute9|| ','|| i.attribute10|| ','|| i.attribute11|| ','|| i.attribute12|| ','|| i.attribute13|| ','|| i.attribute14|| ','|| i.attribute15|| ','|| i.attribute_category_code|| ','|| i.context|| ','|| i.mass_property_eligible|| ','|| i.group_asset|| ','|| i.reduction_rate|| ','||
    i.apply_reduction_rate_to_addi|| ','|| i.apply_reduction_rate_to_adj|| ','|| i.apply_reduction_rate_to_reti|| ','|| i.recognize_gain_or_loss|| ','|| i.recapture_excess_reserve|| ','|| i.limit_net_proceeds_to_cost|| ','|| i.terminal_gain_or_loss|| ','|| i.tracking_method|| ','|| i.allocate_excess_depreciation|| ','|| i.depreciate_by|| ','|| i.member_rollup|| ','|| i.allo_to_full_reti_and_res_asst|| ','|| i.over_depreciate|| ','|| i.preparer|| ','|| i.sum_merged_units|| ','|| i.new_master|| ','|| i.units_to_adjust|| ','|| i.short_year|| ','|| i.conversion_date|| ','|| i.original_dep_start_date|| ','|| i.nbv_at_the_time_of_switch|| ','|| i.period_fully_reserved|| ','|| i.start_period_of_extended_dep|| ','|| i.earlier_dep_limit_type|| ','|| i.earlier_dep_limit_percent|| ','|| i.earlier_dep_limit_amount|| ','|| i.earlier_depreciation_method|| ','|| i.earlier_life_in_months|| ','|| i.earlier_basic_rate|| ','|| i.earlier_adjusted_rate|| ','|| i.lease_number|| ','|| i.revaluation_reserve
    || ','|| i.revaluation_loss|| ','|| i.reval_reser_amortization_basis|| ','|| i.impairment_loss_expense|| ','|| i.revaluation_cost_ceiling|| ','|| i.fair_value|| ','|| i.last_used_price_index_value|| ','|| i.supplier_name|| ','|| i.supplier_number|| ','|| i.purchase_order_number|| ','|| i.invoice_number|| ','|| i.invoice_voucher_number|| ','|| i.invoice_date|| ','|| i.payables_units|| ','|| i.invoice_line_number|| ','|| i.invoice_line_type|| ','|| i.invoice_line_description|| ','|| i.invoice_payment_number|| ','|| i.project_number|| ','|| i.task_number|| ','|| i.fully_depreciate);
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_ASSET_HDR procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END generic_tax_child_asset_hdr;
PROCEDURE generic_tax_parent_dist(
    p_book_type_code VARCHAR2)
IS
  CURSOR c_tax_par_dist
  IS
    SELECT
      /*+ parallel(16) */
      Interface_Line_Number,
      fd.Units_Assigned,
      NULL Employee_Email_Address,
      loc.SEGMENT1 Asset_Location_Segment1,
      loc.SEGMENT2 Asset_Location_Segment2,
      loc.SEGMENT3 Asset_Location_Segment3,
      loc.SEGMENT4 Asset_Location_Segment4,
      loc.SEGMENT6 "ASSET_LOCATION_SEGMENT5",
      SUBSTR(loc.SEGMENT5,2) "ASSET_LOCATION_SEGMENT6",
      loc.SEGMENT7 Asset_Location_Segment7,
      gcc.segment1
      || '.'
      || gcc.segment2
      || '.'
      || gcc.segment3
      || '.'
      || gcc.segment4
      || '.'
      || gcc.SEGMENT5
      || '.'
      || gcc.SEGMENT6
      || '.'
      || gcc.SEGMENT7 EXPENSE_ACCOUNT_SEGMENT
    FROM
      (SELECT INTERFACE_LINE_NUMBER
      FROM
        (SELECT
          /*+ full(ds) full(fth) */
          FAB.ASSET_ID Interface_Line_Number,
          FB.BOOK_TYPE_CODE Asset_Book,
          fth.TRANSACTION_TYPE_CODE Transaction_Name,
          FAB.ASSET_NUMBER Asset_Number,
          FAT.DESCRIPTION Asset_Description ,
          FAB.TAG_NUMBER Tag_Number,
          FAB.MANUFACTURER_NAME Manufacturer,
          FAB.SERIAL_NUMBER Serial_Number,
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
          FCB.SEGMENT7 ASSET_CATEGORY_SEGMENT7,
          (SELECT ASSET_NUMBER FROM fa_additions_b WHERE asset_id = fab.PARENT_ASSET_ID
          ) Parent_Asset,
        fab.INVENTORIAL In_physical_inventory,
        fab.PROPERTY_TYPE_CODE Property_Type,
        fab.PROPERTY_1245_1250_CODE Property_Class,
        fab.IN_USE_FLAG In_use,
        fab.OWNED_LEASED Ownership,
        fab.NEW_USED Bought,
        FAB.COMMITMENT ,
        fab.investment_law, -- added by Arun
        corpbook.AMORTIZE_FLAG Amortize,
        TO_CHAR(FTH.DATE_EFFECTIVE,'YYYY/MM/DD') Amortization_Start_Date,
        fb.DEPRECIATE_FLAG Depreciate,
        fb.SALVAGE_TYPE Salvage_Value_Type,
        fb.SALVAGE_VALUE Salvage_Value_Amount,
        fb.PERCENT_SALVAGE_VALUE Salvage_Value_Percent,
        ds.YTD_DEPRN YTD_Depreciation,
        ds.DEPRN_RESERVE Depreciation_Reserve,
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
        FCB.ATTRIBUTE1 ATTRIBUTE1,
        FCB.ATTRIBUTE2 ATTRIBUTE2,
        FCB.ATTRIBUTE3 ATTRIBUTE3,
        FCB.ATTRIBUTE4 ATTRIBUTE4,
        FCB.ATTRIBUTE5 ATTRIBUTE5,
        FCB.ATTRIBUTE6 ATTRIBUTE6,
        FCB.ATTRIBUTE7 ATTRIBUTE7,
        FCB.ATTRIBUTE8 ATTRIBUTE8,
        FCB.ATTRIBUTE9 ATTRIBUTE9,
        FCB.ATTRIBUTE10 ATTRIBUTE10,
        FCB.ATTRIBUTE_CATEGORY_CODE ATTRIBUTE_CATEGORY_CODE,
        fb.NBV_AT_SWITCH NBV_at_the_Time_of_Switch,
        fb.PRIOR_DEPRN_LIMIT_TYPE Earlier_Dep_Limit_Type,
        fb.PRIOR_DEPRN_LIMIT Earlier_Dep_Limit_Percent,
        fb.PRIOR_DEPRN_LIMIT_AMOUNT Earlier_Dep_Limit_Amount,
        fb.PRIOR_LIFE_IN_MONTHS Earlier_Life_in_Months,
        fb.PRIOR_BASIC_RATE Earlier_Basic_Rate,
        fb.PRIOR_ADJUSTED_RATE Earlier_Adjusted_Rate,
        ds.distribution_id,
        --fb.book_type_code,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.distribution_id DESC ) distidrank,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.period_counter DESC) periodcounterrank
      FROM FA_BOOKS fb,
        xx_fa_status xfs,
        FA_BOOK_CONTROLS corpbook,
        FA_ADDITIONS_B FAB,
        FA_CATEGORIES_B FCB,
        FA_ADDITIONS_TL FAT,
        FA_DEPRN_DETAIL ds,
        FA_TRANSACTION_HEADERS fth
      WHERE 1                    =1
      AND xfs.book_type_code     =p_book_type_code
      AND xfs.ASSET_STATUS       ='ACTIVE'
      AND fb.book_type_code      =xfs.book_type_code
      AND fb.asset_id            = xfs.asset_id
      AND corpbook.book_type_code=FB.book_type_code
      AND corpbook.BOOK_CLASS    = 'TAX'
      AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
      AND fab.ASSET_ID=fb.ASSET_ID
        --and fab.asset_id not in (21417857,21418275,11896729)
      AND fab.parent_asset_id IS NULL
      AND EXISTS
        (SELECT 'x' FROM FA_ADDITIONS_B WHERE PARENT_ASSET_ID = FAB.ASSET_ID
        )
      AND fcb.category_id           =fab.asset_category_id
      AND fat.ASSET_ID              =fab.ASSET_ID
      AND fat.language              = 'US'
      AND ds.asset_id               =fb.asset_id
      AND ds.book_type_code         =fb.book_type_code
      AND fth.ASSET_ID              = fab.ASSET_ID
      AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
      AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
        )
      WHERE distidrank      = 1
      AND periodcounterrank = 1
      ) fa_details2,
      gl_code_combinations gcc,
      fa_locations loc,
      fa_distribution_history fd
    WHERE 1                    =1
    AND fd.asset_id            =FA_DETAILS2.interface_line_number
    AND fd.date_ineffective   IS NULL
    AND fd.book_type_code      ='OD US CORP'
    AND loc.location_id        =fd.location_id
    AND gcc.code_combination_id=fd.code_combination_id
    AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fd.date_effective, SYSDATE)) AND TRUNC (NVL (fd.date_ineffective, SYSDATE))
    ORDER BY interface_line_number;
    lc_file_handle utl_file.file_type;
    lv_line_count NUMBER;
    -- l_file_path   VARCHAR(200);
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
    v_segment7       VARCHAR2(50);
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
    print_debug_msg ('Package GENERIC_TAX_PARENT_DIST START', TRUE);
    print_debug_msg ('P_BOOK_TYPE_CODE '||p_book_type_code, TRUE);
    v_book_type_code :=REPLACE(REPLACE (REPLACE(p_book_type_code,'OD US ','US_'),'OD CA ','CA_'),' ','_');
    --- l_file_name    := 'Generic_TAX_Parent_Distribution_v15' || '.csv';
    l_file_name    := 'Generic_TAX_Parent_Distribution_'||v_book_type_code|| '.csv';
    lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
    lv_col_title   :='INTERFACE_LINE_NUMBER'|| ','|| 'UNITS_ASSIGNED'|| ','|| 'EMPLOYEE_EMAIL_ADDRESS'|| ','|| 'ASSET_LOCATION_SEGMENT1'|| ','|| 'ASSET_LOCATION_SEGMENT2'|| ','|| 'ASSET_LOCATION_SEGMENT3'|| ','|| 'ASSET_LOCATION_SEGMENT4'|| ','|| 'ASSET_LOCATION_SEGMENT5'|| ','|| 'ASSET_LOCATION_SEGMENT6'|| ','|| 'ASSET_LOCATION_SEGMENT7'|| ','|| 'EXPENSE_ACCOUNT_SEGMENT';
    utl_file.put_line(lc_file_handle,lv_col_title);
    FOR i IN c_tax_par_dist
    LOOP
      ---UTL_FILE.put_line(lc_file_handle,'HI');
      utl_file.put_line(lc_file_handle,i.interface_line_number|| ','|| i.units_assigned|| ','|| i.employee_email_address|| ','|| i.asset_location_segment1|| ','|| i.asset_location_segment2|| ','|| i.asset_location_segment3|| ','|| i.asset_location_segment4|| ','|| i.asset_location_segment5|| ','|| i.asset_location_segment6|| ','|| i.asset_location_segment7|| ','|| i.expense_account_segment);
    END LOOP;
    utl_file.fclose(lc_file_handle);
  EXCEPTION
  WHEN utl_file.access_denied THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.delete_failed THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.file_open THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.internal_error THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filehandle THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filename THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_maxlinesize THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_mode THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_offset THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_operation THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_path THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.read_error THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.rename_failed THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.write_error THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_PARENT_DISTRIBUTION procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  END generic_tax_parent_dist;
PROCEDURE generic_tax_child_dist(
    p_book_type_code VARCHAR2)
IS
  CURSOR c_tax_child_dist
  IS
    SELECT
      /*+ parallel(8) */
      Interface_Line_Number,
      fd.Units_Assigned,
      NULL Employee_Email_Address,
      loc.SEGMENT1 Asset_Location_Segment1,
      loc.SEGMENT2 Asset_Location_Segment2,
      loc.SEGMENT3 Asset_Location_Segment3,
      loc.SEGMENT4 Asset_Location_Segment4,
      loc.SEGMENT6 "ASSET_LOCATION_SEGMENT5",
      SUBSTR(loc.SEGMENT5,2) "ASSET_LOCATION_SEGMENT6",
      loc.SEGMENT7 Asset_Location_Segment7,
      gcc.segment1
      || '.'
      || gcc.segment2
      || '.'
      || gcc.segment3
      || '.'
      || gcc.segment4
      || '.'
      || gcc.SEGMENT5
      || '.'
      || gcc.SEGMENT6
      || '.'
      || gcc.SEGMENT7 EXPENSE_ACCOUNT_SEGMENT
    FROM
      (SELECT INTERFACE_LINE_NUMBER
      FROM
        (SELECT
          /*+ full(ds) full(fth) */
          FAB.ASSET_ID Interface_Line_Number,
          FB.BOOK_TYPE_CODE Asset_Book,
          fth.TRANSACTION_TYPE_CODE Transaction_Name,
          FAB.ASSET_NUMBER Asset_Number,
          FAT.DESCRIPTION Asset_Description ,
          FAB.TAG_NUMBER Tag_Number,
          FAB.MANUFACTURER_NAME Manufacturer,
          FAB.SERIAL_NUMBER Serial_Number,
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
          FCB.SEGMENT7 ASSET_CATEGORY_SEGMENT7,
          (SELECT ASSET_NUMBER FROM fa_additions_b WHERE asset_id = fab.PARENT_ASSET_ID
          ) Parent_Asset,
        fab.INVENTORIAL In_physical_inventory,
        fab.PROPERTY_TYPE_CODE Property_Type,
        fab.PROPERTY_1245_1250_CODE Property_Class,
        fab.IN_USE_FLAG In_use,
        fab.OWNED_LEASED Ownership,
        fab.NEW_USED Bought,
        FAB.COMMITMENT ,
        fab.investment_law, -- added by Arun
        corpbook.AMORTIZE_FLAG Amortize,
        TO_CHAR(FTH.DATE_EFFECTIVE,'YYYY/MM/DD') Amortization_Start_Date,
        fb.DEPRECIATE_FLAG Depreciate,
        fb.SALVAGE_TYPE Salvage_Value_Type,
        fb.SALVAGE_VALUE Salvage_Value_Amount,
        fb.PERCENT_SALVAGE_VALUE Salvage_Value_Percent,
        ds.YTD_DEPRN YTD_Depreciation,
        ds.DEPRN_RESERVE Depreciation_Reserve,
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
        FCB.ATTRIBUTE1 ATTRIBUTE1,
        FCB.ATTRIBUTE2 ATTRIBUTE2,
        FCB.ATTRIBUTE3 ATTRIBUTE3,
        FCB.ATTRIBUTE4 ATTRIBUTE4,
        FCB.ATTRIBUTE5 ATTRIBUTE5,
        FCB.ATTRIBUTE6 ATTRIBUTE6,
        FCB.ATTRIBUTE7 ATTRIBUTE7,
        FCB.ATTRIBUTE8 ATTRIBUTE8,
        FCB.ATTRIBUTE9 ATTRIBUTE9,
        FCB.ATTRIBUTE10 ATTRIBUTE10,
        FCB.ATTRIBUTE_CATEGORY_CODE ATTRIBUTE_CATEGORY_CODE,
        fb.NBV_AT_SWITCH NBV_at_the_Time_of_Switch,
        fb.PRIOR_DEPRN_LIMIT_TYPE Earlier_Dep_Limit_Type,
        fb.PRIOR_DEPRN_LIMIT Earlier_Dep_Limit_Percent,
        fb.PRIOR_DEPRN_LIMIT_AMOUNT Earlier_Dep_Limit_Amount,
        fb.PRIOR_LIFE_IN_MONTHS Earlier_Life_in_Months,
        fb.PRIOR_BASIC_RATE Earlier_Basic_Rate,
        fb.PRIOR_ADJUSTED_RATE Earlier_Adjusted_Rate,
        ds.distribution_id,
        --fb.book_type_code,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.distribution_id DESC ) distidrank,
        RANK() OVER (PARTITION BY ds.BOOK_TYPE_CODE, ds.ASSET_ID ORDER BY ds.period_counter DESC) periodcounterrank
      FROM FA_BOOKS fb,
        xx_fa_status xfs,
        FA_BOOK_CONTROLS corpbook,
        FA_ADDITIONS_B FAB,
        FA_CATEGORIES_B FCB,
        FA_ADDITIONS_TL FAT,
        FA_DEPRN_DETAIL ds,
        FA_TRANSACTION_HEADERS fth
      WHERE 1                    =1
      AND xfs.book_type_code     =p_book_type_code
      AND ASSET_STATUS           ='ACTIVE'
      AND fb.book_type_code      =xfs.book_type_code
      AND fb.asset_id            = xfs.asset_id
      AND corpbook.book_type_code=FB.book_type_code
      AND corpbook.BOOK_CLASS    = 'TAX'
      AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fb.date_effective, SYSDATE)) AND TRUNC (NVL (fb.date_ineffective, sysdate))
      AND fab.ASSET_ID=fb.ASSET_ID
        --and fab.asset_id not in (21417857,21418275,11896729)
      AND NOT EXISTS
        (SELECT 'x' FROM FA_ADDITIONS_B WHERE PARENT_ASSET_ID = FAB.ASSET_ID
        )
      AND fcb.category_id           =fab.asset_category_id
      AND fat.ASSET_ID              =fab.ASSET_ID
      AND fat.language              = 'US'
      AND ds.asset_id               =fb.asset_id
      AND ds.book_type_code         =fb.book_type_code
      AND fth.ASSET_ID              = fab.ASSET_ID
      AND fth.BOOK_TYPE_CODE        = corpbook.book_type_code
      AND fth.TRANSACTION_TYPE_CODE = 'ADDITION'
        )
      WHERE distidrank      = 1
      AND PERIODCOUNTERRANK = 1
      ) FA_DETAILS2,
      gl_code_combinations gcc,
      fa_locations loc,
      fa_distribution_history fd
    WHERE 1                    =1
    AND fd.asset_id            =FA_DETAILS2.interface_line_number
    AND fd.date_ineffective   IS NULL
    AND fd.book_type_code      ='OD US CORP'
    AND loc.location_id        =fd.location_id
    AND gcc.code_combination_id=fd.code_combination_id
    AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (fd.date_effective, SYSDATE)) AND TRUNC (NVL (fd.date_ineffective, SYSDATE))
    ORDER BY interface_line_number;
    lc_file_handle utl_file.file_type;
    lv_line_count NUMBER;
    -- l_file_path   VARCHAR(200);
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
    v_segment7       VARCHAR2(50);
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
    print_debug_msg ('Package GENERIC_TAX_CHILD_DIST START', TRUE);
    print_debug_msg ('P_BOOK_TYPE_CODE '||p_book_type_code, TRUE);
    v_book_type_code :=REPLACE(REPLACE (REPLACE(p_book_type_code,'OD US ','US_'),'OD CA ','CA_'),' ','_');
    --- l_file_name    := 'Generic_TAX_Child_Distribution_v15' || '.csv';
    l_file_name    := 'Generic_TAX_Child_Distribution_'||v_book_type_code|| '.csv';
    lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
    lv_col_title   :='INTERFACE_LINE_NUMBER'|| ','|| 'UNITS_ASSIGNED'|| ','|| 'EMPLOYEE_EMAIL_ADDRESS'|| ','|| 'ASSET_LOCATION_SEGMENT1'|| ','|| 'ASSET_LOCATION_SEGMENT2'|| ','|| 'ASSET_LOCATION_SEGMENT3'|| ','|| 'ASSET_LOCATION_SEGMENT4'|| ','|| 'ASSET_LOCATION_SEGMENT5'|| ','|| 'ASSET_LOCATION_SEGMENT6'|| ','|| 'ASSET_LOCATION_SEGMENT7'|| ','|| 'EXPENSE_ACCOUNT_SEGMENT';
    utl_file.put_line(lc_file_handle,lv_col_title);
    FOR i IN c_tax_child_dist
    LOOP
      ---UTL_FILE.put_line(lc_file_handle,'HI');
      utl_file.put_line(lc_file_handle,i.interface_line_number|| ','|| i.units_assigned|| ','|| i.employee_email_address|| ','|| i.asset_location_segment1|| ','|| i.asset_location_segment2|| ','|| i.asset_location_segment3|| ','|| i.asset_location_segment4|| ','|| i.asset_location_segment5|| ','|| i.asset_location_segment6|| ','|| i.asset_location_segment7|| ','|| i.expense_account_segment);
    END LOOP;
    utl_file.fclose(lc_file_handle);
  EXCEPTION
  WHEN utl_file.access_denied THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.delete_failed THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.file_open THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.internal_error THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filehandle THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_filename THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_maxlinesize THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_mode THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_offset THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_operation THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.invalid_path THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.read_error THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.rename_failed THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN utl_file.write_error THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  WHEN OTHERS THEN
    lc_errormsg := ( 'Error in GENERIC_TAX_CHILD_DIST procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
    print_debug_msg (lc_errormsg, TRUE);
    utl_file.fclose_all;
    lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
    utl_file.fclose(lc_file_handle);
  END generic_tax_child_dist;
PROCEDURE fbdi_project_assets
IS
  CURSOR c_fbdi_project_assets
  IS
    SELECT 'Demo_create' demo_create,
      'Create' create_mode,
      NULL project_id,
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(proj.name,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') project_name,
      proj.segment1 project_number,
      ppa.project_asset_type,
      NULL project_asset_id,
      ppa.asset_name,
      ppa.asset_number,
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ppa.asset_description,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') asset_description,
      TO_CHAR(ppa.estimated_in_service_date,'YYYY/MM/DD') estimated_in_service_date,
      TO_CHAR(ppa.date_placed_in_service,'YYYY/MM/DD') date_placed_in_service,
      ppa.reverse_flag,
      ppa.capital_hold_flag,
      ppa.book_type_code,
      NULL asset_category_id,
      (SELECT segment1
        || '.'
        || segment2
        || '.'
        || segment3
      FROM fa_categories
      WHERE category_id = ppa.asset_category_id
      ) asset_category,
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
    (SELECT segment1
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
    ) location,
    -- per.full_name,        --(Add Fetch)
    ppa.assigned_to_person_id,
    (SELECT paf.full_name
    FROM per_all_people_f paf
    WHERE paf.person_id = ppa.assigned_to_person_id
    AND TRUNC(sysdate) BETWEEN paf.effective_start_date AND paf.effective_end_date
    ) assigned_to_person_name,
    (SELECT paf.employee_number
    FROM per_all_people_f paf
    WHERE paf.person_id = ppa.assigned_to_person_id
    AND TRUNC(sysdate) BETWEEN paf.effective_start_date AND paf.effective_end_date
    ) assigned_to_person_number,
    ppa.depreciate_flag,
    null depreciation_expense_ccid,
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
    (
    CASE
      WHEN (ppa.depreciate_flag          = 'Y'
      AND ppa.depreciation_expense_ccid IS NULL
      and project_status_code           in ('1000','CLOSED'))
      THEN  (xx_gl_beacon_mapping_f1('1001.43002.73802000.010000.0000.10.000000',NULL,'P'))
      else
        (SELECT xx_gl_beacon_mapping_f1(concatenated_segments,NULL,'P')
        FROM gl_code_combinations_kfv
        WHERE code_combination_id = ppa.depreciation_expense_ccid
        )
    end ) depreciation_expense_account,
    ---Changes end
    ppa.amortize_flag,
    NULL overridecategoryanddesc,
    NULL business_unit_id,
    NULL parent_asset_id,
    (SELECT asset_number
    FROM fa_additions_b fab
    WHERE asset_id = ppa.parent_asset_id
    ) parent_asset_number,
    ppa.manufacturer_name,
    ppa.model_number,
    ppa.tag_number,
    ppa.serial_number,
    NULL ret_target_asset_id,
    (SELECT asset_number
    FROM fa_additions_b fab
    WHERE asset_id = ppa.ret_target_asset_id
    ) ret_target_asset_number,
    ppa.pm_product_code
  FROM pa_project_assets_all ppa,
    pa_projects_all proj
  WHERE 1                           =1
  AND proj.template_flag            = 'N'
  AND NVL(proj.closed_date,sysdate) > to_date('30-JUN-2018','dd-mon-yyyy')
  AND (proj.segment1 NOT LIKE 'PB%'
  AND proj.segment1 NOT LIKE 'NB%'
  AND proj.segment1 NOT LIKE 'TEM%')
  AND proj.project_type NOT IN ('PB_PROJECT','DI_PB_PROJECT')
  AND project_status_code   IN ('APPROVED','CLOSED','1000')
  AND proj.org_id           <>403
  AND proj.project_id        = ppa.project_id
  AND ppa.project_asset_type = 'ESTIMATED'
  -- Begin Added for pstgb
  AND proj.created_from_project_id IN (  
  select project_id from pa_projects_all
        where template_flag='Y'
and name='US IT Template - Labor Only'
      )
-- End added for PSTGB
  ORDER BY proj.segment1;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
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
  l_file_name    := 'fbdi_project_assets' || '.csv';--GENERIC_TAX_CHILD_ASSET_HDR
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='DEMO_CREATE'|| ','|| 'CREATE_MODE'|| ','|| 'PROJECT_ID'|| ','|| 'PROJECT_NAME'|| ','|| 'PROJECT_NUMBER'|| ','|| 'PROJECT_ASSET_TYPE'|| ','|| 'PROJECT_ASSET_ID'|| ','|| 'ASSET_NAME'|| ','|| 'ASSET_NUMBER'|| ','|| 'ASSET_DESCRIPTION'|| ','|| 'ESTIMATED_IN_SERVICE_DATE'|| ','|| 'DATE_PLACED_IN_SERVICE'|| ','|| 'REVERSE_FLAG'|| ','|| 'CAPITAL_HOLD_FLAG'|| ','|| 'BOOK_TYPE_CODE'|| ','|| 'ASSET_CATEGORY_ID'|| ','|| 'ASSET_CATEGORY'|| ','|| 'ASSET_KEY_CCID'|| ','|| 'ASSET_KEY'|| ','|| 'ASSET_UNITS'|| ','|| 'ESTIMATED_COST'|| ','|| 'ESTIMATED_ASSET_UNITS'|| ','|| 'LOCATION_ID'|| ','|| 'LOCATION'|| ','|| 'ASSIGNED_TO_PERSON_ID'|| ','|| 'ASSIGNED_TO_PERSON_NAME'|| ','|| 'ASSIGNED_TO_PERSON_NUMBER'|| ','|| 'DEPRECIATE_FLAG'|| ','|| 'DEPRECIATION_EXPENSE_CCID'|| ','|| 'DEPRECIATION_EXPENSE_ACCOUNT'|| ','|| 'AMORTIZE_FLAG'|| ','|| 'OVERRIDECATEGORYANDDESC'|| ','|| 'BUSINESS_UNIT_ID'|| ','|| 'PARENT_ASSET_ID'|| ','|| 'PARENT_ASSET_NUMBER'|| ','|| 'MANUFACTURER_NAME'|| ','||
  'MODEL_NUMBER'|| ','|| 'TAG_NUMBER'|| ','|| 'SERIAL_NUMBER'|| ','|| 'RET_TARGET_ASSET_ID'|| ','|| 'RET_TARGET_ASSET_NUMBER'|| ','|| 'PM_PRODUCT_CODE';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_fbdi_project_assets
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,i.demo_create|| ','|| i.create_mode|| ','|| i.project_id|| ','|| i.project_name|| ','|| i.project_number|| ','|| i.project_asset_type|| ','|| i.project_asset_id|| ','|| i.asset_name|| ','|| i.asset_number|| ','|| i.asset_description|| ','|| i.estimated_in_service_date|| ','|| i.date_placed_in_service|| ','|| i.reverse_flag|| ','|| i.capital_hold_flag|| ','|| i.book_type_code|| ','|| i.asset_category_id|| ','|| i.asset_category|| ','|| i.asset_key_ccid|| ','|| i.asset_key|| ','|| i.asset_units|| ','|| i.estimated_cost|| ','|| i.estimated_asset_units|| ','|| i.location_id|| ','|| i.location|| ','|| i.assigned_to_person_id|| ','|| i.assigned_to_person_name|| ','|| i.assigned_to_person_number|| ','|| i.depreciate_flag|| ','|| i.depreciation_expense_ccid|| ','|| i.depreciation_expense_account|| ','|| i.amortize_flag|| ','|| i.overridecategoryanddesc|| ','|| i.business_unit_id|| ','|| i.parent_asset_id|| ','|| i.parent_asset_number|| ','||
    i.manufacturer_name|| ','|| i.model_number|| ','|| i.tag_number|| ','|| i.serial_number|| ','|| i.ret_target_asset_id|| ','|| i.ret_target_asset_number|| ','|| i.pm_product_code);
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in FBDI_PROJECT_ASSETS procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_project_assets;

PROCEDURE fbdi_proj_exp_cap_yn
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
      'Conversion' document,
      NULL documentid,
      'Conversion' documententry,
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
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(prj.name,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') project_name,
      NULL projectid,
      task.task_number tasknumber,
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(task.task_name,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') task_name,
      NULL taskid,
      exptyp.expenditure_type expendituretype,
      NULL expendituretypeid,
      (SELECT name
      FROM hr_all_organization_units
      WHERE organization_id=expd.cc_prvdr_organization_id
      ) expenditure_organization,
    NULL expenditureorganizationid,
    NULL contract_number,
    NULL contract_name,
    NULL contract_id,
    NULL funding_source_number,
    NULL funding_source_name ,
    '1' quantity,
    NULL unit_of_measure_name ,
    NVL(expd.unit_of_measure,'DOLLARS') unit_of_measure_code,
    NULL worktype,
    NULL worktypeid,
    expd.billable_flag billable,
    DECODE(SUBSTR(task.task_number,1,2),'02','Y','N') capitalizable,
    NULL accrual_item ,
    expd.expenditure_item_id orig_transaction_reference,
    NULL unmatchednegativetransaction,
    NULL reversedoriginaltransaction,
    REPLACE(REPLACE(REPLACE(REPLACE(ec.expenditure_comment,chr(13), ''), chr(10), ''),chr(39),''),chr(63),'') AS expenditureitemcomment,
    TO_CHAR(expd.expenditure_item_date,'YYYY/MM/DD') accountingdate,
    expd.project_currency_code transactioncurrencycode,
    NULL transactioncurrency,
    raw_cost rawcostintrxcurrency,
    burden_cost_rate burdenedcostintrxcurrency,
    null rawcostcreditccid,
    /*Commented by Priyam for EBS to Cloud segment Change
    (SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = cr_code_combination_id
    ) rawcostcreditaccount,*/
  ---  ADDED by Priyam for EBS to Cloud segment Change 
    (SELECT xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,null,'P')
    FROM gl_code_combinations_kfv gl_code_combinations
    where code_combination_id = cr_code_combination_id
    ) rawcostcreditaccount,
    null rawcostdebitccid,
   /* Commented by Priyam for EBS to Cloud segment Change
   (SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = dr_code_combination_id
    ) rawcostdebitaccount,*/
    ----Added by Priyam for EBS to Cloud segment Change 
    (SELECT xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,null,'P')
    FROM gl_code_combinations_kfv gl_code_combinations
    where code_combination_id = dr_code_combination_id
    ) rawcostdebitaccount,
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
    expd.attribute_category attributecategory,
    expd.attribute1 attribute1,
    expd.attribute2 attribute2,
    expd.attribute3 attribute3,
    expd.attribute4 attribute4,
    expd.attribute5 attribute5,
    expd.attribute6 attribute6,
    (SELECT vendor_name FROM ap_suppliers WHERE vendor_id = expd.vendor_id
    ) attribute7,
    (SELECT segment1 FROM ap_suppliers WHERE vendor_id = expd.vendor_id
    ) attribute8,
    (SELECT ai.invoice_num
    FROM ap_invoices_all ai
    WHERE 1          =1
    AND ai.invoice_id=expd.document_header_id
    ) attribute9,
    (SELECT TO_CHAR(ai.invoice_date,'YYYY/MM/DD')
    FROM ap_invoices_all ai
    WHERE 1          =1
    AND ai.invoice_id=expd.document_header_id
    ) attribute10
  FROM pa_expenditure_comments ec,
    pa_cost_distribution_lines_all cd,
    pa_transaction_sources src,
    pa_expenditure_types exptyp,
    hr_operating_units ou,
    pa_expenditure_items_all expd,
    pa_tasks task,
    pa_projects_all prj
  WHERE 1                          =1
  AND prj.template_flag            = 'N'
  AND NVL(prj.closed_date,sysdate) > to_date('30-JUN-2018','dd-mon-yyyy')
  AND (prj.segment1 NOT LIKE 'PB%'
  AND prj.segment1 NOT LIKE 'NB%'
  AND prj.segment1 NOT LIKE 'TEM%')
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
    (SELECT MAX(line_num)
    FROM pa_cost_distribution_lines_all d
    WHERE d.expenditure_item_id = expd.expenditure_item_id
    AND d.line_type             = 'R'
    )
    ------------------
  AND ec.expenditure_item_id=expd.expenditure_item_id
-- Begin Added for pstgb
  AND prj.created_from_project_id IN (  
  select project_id from pa_projects_all
        where template_flag='Y'
and name='US IT Template - Labor Only'
      )
-- End added for PSTGB
  ORDER BY prj.segment1,
    task.task_number,
    expd.expenditure_item_id;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
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
  --- print_debug_msg ('P_BOOK_TYPE_CODE '||P_BOOK_TYPE_CODE, TRUE);
  l_file_name    := 'fbdi_ProjectExpenditure_Capitalizable_YN' || '.csv';--GENERIC_TAX_CHILD_ASSET_HDR
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='TRANSACTIONTYPE'|| ','|| 'BUSINESSUNITNAME'|| ','|| 'BUSINESSUNITID'|| ','|| 'TRANSACTIONSOURCE'|| ','|| 'TRANSACTIONSOURCEID'|| ','|| 'DOCUMENT'|| ','|| 'DOCUMENTID'|| ','|| 'DOCUMENTENTRY'|| ','|| 'DOCUMENTENTRYID'|| ','|| 'EXPENDITUREBATCH'|| ','|| 'BATCHENDINGDATE'|| ','|| 'BATCHDESCRIPTION'|| ','|| 'EXPENDITUREITEMDATE'|| ','|| 'PERSONNUMBER'|| ','|| 'PERSONNAME'|| ','|| 'PERSONID'|| ','|| 'HUMANRESOURCESASSIGNMENT'|| ','|| 'HUMANRESOURCESASSIGNMENTID'|| ','|| 'PROJECTNUMBER'|| ','|| 'PROJECT_NAME'|| ','|| 'PROJECTID'|| ','|| 'TASKNUMBER'|| ','|| 'TASK_NAME'|| ','|| 'TASKID'|| ','|| 'EXPENDITURETYPE'|| ','|| 'EXPENDITURETYPEID'|| ','|| 'EXPENDITURE_ORGANIZATION'|| ','|| 'EXPENDITUREORGANIZATIONID'|| ','|| 'CONTRACT_NUMBER'|| ','|| 'CONTRACT_NAME'|| ','|| 'CONTRACT_ID'|| ','|| 'FUNDING_SOURCE_NUMBER'|| ','|| 'FUNDING_SOURCE_NAME'|| ','|| 'QUANTITY'|| ','|| 'UNIT_OF_MEASURE_NAME'|| ','|| 'UNIT_OF_MEASURE_CODE'|| ','|| 'WORKTYPE'|| ','|| 'WORKTYPEID'|| ','||
  'BILLABLE'|| ','|| 'CAPITALIZABLE'|| ','|| 'ACCRUAL_ITEM'|| ','|| 'ORIG_TRANSACTION_REFERENCE'|| ','|| 'UNMATCHEDNEGATIVETRANSACTION'|| ','|| 'REVERSEDORIGINALTRANSACTION'|| ','|| 'EXPENDITUREITEMCOMMENT'|| ','|| 'ACCOUNTINGDATE'|| ','|| 'TRANSACTIONCURRENCYCODE'|| ','|| 'TRANSACTIONCURRENCY'|| ','|| 'RAWCOSTINTRXCURRENCY'|| ','|| 'BURDENEDCOSTINTRXCURRENCY'|| ','|| 'RAWCOSTCREDITCCID'|| ','|| 'RAWCOSTCREDITACCOUNT'|| ','|| 'RAWCOSTDEBITCCID'|| ','|| 'RAWCOSTDEBITACCOUNT'|| ','|| 'BURDENEDCOSTCREDITCCID'|| ','|| 'BURDENEDCOSTCREDITACCOUNT'|| ','|| 'BURDENEDCOSTDEBITCCID'|| ','|| 'BURDENEDCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTDEBITCCID'|| ','|| 'BURDENCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTCREDITCCID'|| ','|| 'BURDENCOSTCREDITACCOUNT'|| ','|| 'PROVIDERLEDGERCURRENCYCODE'|| ','|| 'PROVIDERLEDGERCURRENCY'|| ','|| 'RAWCOSTLEDGERCURRENCY'|| ','|| 'BURDENEDCOSTLEDGERCURRENCY'|| ','|| 'PROVIDERLEDGERRATETYPE'|| ','|| 'PROVIDERLEDGERRATEDATE'|| ','|| 'PROVIDERLEDGERDATETYPE'|| ','||
  'PROVIDERLEDGERRATE'|| ','|| 'PROVIDERLEDGERROUNDINGLIMIT'|| ','|| 'CONVERTED'|| ','|| 'CONTEXTCATEGORY'|| ','|| 'USERDEFINEDATTRIBUTE1'|| ','|| 'USERDEFINEDATTRIBUTE2'|| ','|| 'USERDEFINEDATTRIBUTE3'|| ','|| 'USERDEFINEDATTRIBUTE4'|| ','|| 'USERDEFINEDATTRIBUTE5'|| ','|| 'USERDEFINEDATTRIBUTE6'|| ','|| 'USERDEFINEDATTRIBUTE7'|| ','|| 'USERDEFINEDATTRIBUTE8'|| ','|| 'USERDEFINEDATTRIBUTE9'|| ','|| 'USERDEFINEDATTRIBUTE10'|| ','|| 'FUNDINGSOURCEID'|| ','|| 'RESERVEDATTRIBUTE2'|| ','|| 'RESERVEDATTRIBUTE3'|| ','|| 'RESERVEDATTRIBUTE4'|| ','|| 'RESERVEDATTRIBUTE5'|| ','|| 'RESERVEDATTRIBUTE6'|| ','|| 'RESERVEDATTRIBUTE7'|| ','|| 'RESERVEDATTRIBUTE8'|| ','|| 'RESERVEDATTRIBUTE9'|| ','|| 'RESERVEDATTRIBUTE10'|| ','|| 'ATTRIBUTECATEGORY'|| ','|| 'ATTRIBUTE1'|| ','|| 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','|| 'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'|| ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_fbdi_yn
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,i.transactiontype|| ','|| i.businessunitname|| ','|| i.businessunitid|| ','|| i.transactionsource|| ','|| i.transactionsourceid|| ','|| i.document|| ','|| i.documentid|| ','|| i.documententry|| ','|| i.documententryid|| ','|| i.expenditurebatch|| ','|| i.batchendingdate|| ','|| i.batchdescription|| ','|| i.expenditureitemdate|| ','|| i.personnumber|| ','|| i.personname|| ','|| i.personid|| ','|| i.humanresourcesassignment|| ','|| i.humanresourcesassignmentid|| ','|| i.projectnumber|| ','|| i.project_name|| ','|| i.projectid|| ','|| i.tasknumber|| ','|| i.task_name|| ','|| i.taskid|| ','|| i.expendituretype|| ','|| i.expendituretypeid|| ','|| i.expenditure_organization|| ','|| i.expenditureorganizationid|| ','|| i.contract_number|| ','|| i.contract_name|| ','|| i.contract_id|| ','|| i.funding_source_number|| ','|| i.funding_source_name|| ','|| i.quantity|| ','|| i.unit_of_measure_name|| ','|| i.unit_of_measure_code|| ','|| i.worktype|| ','||
    i.worktypeid|| ','|| i.billable|| ','|| i.capitalizable|| ','|| i.accrual_item|| ','|| i.orig_transaction_reference|| ','|| i.unmatchednegativetransaction|| ','|| i.reversedoriginaltransaction|| ','|| i.expenditureitemcomment|| ','|| i.accountingdate|| ','|| i.transactioncurrencycode|| ','|| i.transactioncurrency|| ','|| i.rawcostintrxcurrency|| ','|| i.burdenedcostintrxcurrency|| ','|| i.rawcostcreditccid|| ','|| i.rawcostcreditaccount|| ','|| i.rawcostdebitccid|| ','|| i.rawcostdebitaccount|| ','|| i.burdenedcostcreditccid|| ','|| i.burdenedcostcreditaccount|| ','|| i.burdenedcostdebitccid|| ','|| i.burdenedcostdebitaccount|| ','|| i.burdencostdebitccid|| ','|| i.burdencostdebitaccount|| ','|| i.burdencostcreditccid|| ','|| i.burdencostcreditaccount|| ','|| i.providerledgercurrencycode|| ','|| i.providerledgercurrency|| ','|| i.rawcostledgercurrency|| ','|| i.burdenedcostledgercurrency|| ','|| i.providerledgerratetype|| ','|| i.providerledgerratedate|| ','||
    i.providerledgerdatetype|| ','|| i.providerledgerrate|| ','|| i.providerledgerroundinglimit|| ','|| i.converted|| ','|| i.contextcategory|| ','|| i.userdefinedattribute1|| ','|| i.userdefinedattribute2|| ','|| i.userdefinedattribute3|| ','|| i.userdefinedattribute4|| ','|| i.userdefinedattribute5|| ','|| i.userdefinedattribute6|| ','|| i.userdefinedattribute7|| ','|| i.userdefinedattribute8|| ','|| i.userdefinedattribute9|| ','|| i.userdefinedattribute10|| ','|| i.fundingsourceid|| ','|| i.reservedattribute2|| ','|| i.reservedattribute3|| ','|| i.reservedattribute4|| ','|| i.reservedattribute5|| ','|| i.reservedattribute6|| ','|| i.reservedattribute7|| ','|| i.reservedattribute8|| ','|| i.reservedattribute9|| ','|| i.reservedattribute10|| ','|| i.attributecategory|| ','|| i.attribute1|| ','|| i.attribute2|| ','|| i.attribute3|| ','|| i.attribute4|| ','|| i.attribute5|| ','|| i.attribute6|| ','|| i.attribute7|| ','|| i.attribute8|| ','|| i.attribute9|| ','|| i.attribute10);
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YN procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_proj_exp_cap_yn;
PROCEDURE fbdi_proj_exp_cap_yy
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
      'Conversion' document,
      NULL documentid,
      'Conversion' documententry,
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
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(prj.name,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') project_name,
      NULL projectid,
      task.task_number tasknumber,
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(task.task_name,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') task_name,
      NULL taskid,
      exptyp.expenditure_type expendituretype,
      NULL expendituretypeid,
      (SELECT name
      FROM hr_all_organization_units
      WHERE organization_id=expd.cc_prvdr_organization_id
      ) expenditure_organization,
    NULL expenditureorganizationid,
    NULL contract_number,
    NULL contract_name,
    NULL contract_id,
    NULL funding_source_number,
    NULL funding_source_name ,
    '1' quantity,
    NULL unit_of_measure_name ,
    NVL(expd.unit_of_measure,'DOLLARS') unit_of_measure_code,
    NULL worktype,
    NULL worktypeid,
    expd.billable_flag billable,
    DECODE(SUBSTR(task.task_number,1,2),'02','Y','N') capitalizable,
    NULL accrual_item ,
    expd.expenditure_item_id orig_transaction_reference,
    NULL unmatchednegativetransaction,
    NULL reversedoriginaltransaction,
    REPLACE(REPLACE(REPLACE(REPLACE(ec.expenditure_comment,chr(13), ''), chr(10), ''),chr(39),''),chr(63),'') AS expenditureitemcomment,
    TO_CHAR(expd.expenditure_item_date,'YYYY/MM/DD') accountingdate,
    expd.project_currency_code transactioncurrencycode,
    NULL transactioncurrency,
    raw_cost rawcostintrxcurrency,
    burden_cost_rate burdenedcostintrxcurrency,
    null rawcostcreditccid,
/*Commented by Priyam for EBS to Cloud segment Change 
(SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = cd.cr_code_combination_id
    ) rawcostcreditaccount,*/
  --  Added by Priyam for EBS to Cloud segment Change 
    (SELECT xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,null,'P')
    FROM gl_code_combinations_kfv gl_code_combinations
    where code_combination_id = cd.cr_code_combination_id
    ) rawcostcreditaccount,
    ----
    
    null rawcostdebitccid,
    /*Commented by Priyam for EBS to Cloud segment Change 
    (SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = cd.dr_code_combination_id
    ) rawcostdebitaccount,*/
   --- Added by Priyam for EBS to Cloud segment Change 
    (SELECT xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,null,'P')
    FROM gl_code_combinations_kfv gl_code_combinations
    where code_combination_id = cd.dr_code_combination_id
    ) rawcostdebitaccount,
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
    expd.attribute_category attributecategory,
    expd.attribute1 attribute1,
    expd.attribute2 attribute2,
    expd.attribute3 attribute3,
    expd.attribute4 attribute4,
    expd.attribute5 attribute5,
    expd.attribute6 attribute6,
    (SELECT vendor_name FROM ap_suppliers WHERE vendor_id = expd.vendor_id
    ) attribute7,
    (SELECT segment1 FROM ap_suppliers WHERE vendor_id = expd.vendor_id
    ) attribute8,
    (SELECT ai.invoice_num
    FROM ap_invoices_all ai
    WHERE 1          =1
    AND ai.invoice_id=expd.document_header_id
    ) attribute9,
    (SELECT TO_CHAR(ai.invoice_date,'YYYY/MM/DD')
    FROM ap_invoices_all ai
    WHERE 1          =1
    AND ai.invoice_id=expd.document_header_id
    ) attribute10
  FROM pa_expenditure_comments ec,
    pa_cost_distribution_lines_all cd,
    pa_transaction_sources src,
    pa_expenditure_types exptyp,
    hr_operating_units ou,
    pa_expenditure_items_all expd,
    pa_tasks task,
    pa_projects_all prj
  WHERE 1                          =1
  AND prj.template_flag            = 'N'
  AND NVL(prj.closed_date,sysdate) > to_date('30-JUN-2018','dd-mon-yyyy')
  AND (prj.segment1 NOT LIKE 'PB%'
  AND prj.segment1 NOT LIKE 'NB%'
  AND prj.segment1 NOT LIKE 'TEM%')
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
    (SELECT MAX(line_num)
    FROM pa_cost_distribution_lines_all d
    WHERE d.expenditure_item_id = expd.expenditure_item_id
    AND d.line_type             = 'R'
    )
    ------------------
  AND ec.expenditure_item_id=expd.expenditure_item_id
  -- Begin Added for pstgb
  AND prj.created_from_project_id IN (  
  select project_id from pa_projects_all
        where template_flag='Y'
and name='US IT Template - Labor Only'
      )
-- End added for PSTGB
  ORDER BY prj.segment1,
    task.task_number,
    expd.expenditure_item_id;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
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
  print_debug_msg ('Package GENERIC_TAX_CHILD_ASSET_HDR START', true);
  -- print_debug_msg ('P_BOOK_TYPE_CODE '||P_BOOK_TYPE_CODE, TRUE);
  l_file_name    := 'fbdi_ProjectExpenditure_capitalized_YY' || '.csv';--GENERIC_TAX_CHILD_ASSET_HDR
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='TRANSACTIONTYPE'|| ','|| 'BUSINESSUNITNAME'|| ','|| 'BUSINESSUNITID'|| ','|| 'TRANSACTIONSOURCE'|| ','|| 'TRANSACTIONSOURCEID'|| ','|| 'DOCUMENT'|| ','|| 'DOCUMENTID'|| ','|| 'DOCUMENTENTRY'|| ','|| 'DOCUMENTENTRYID'|| ','|| 'EXPENDITUREBATCH'|| ','|| 'BATCHENDINGDATE'|| ','|| 'BATCHDESCRIPTION'|| ','|| 'EXPENDITUREITEMDATE'|| ','|| 'PERSONNUMBER'|| ','|| 'PERSONNAME'|| ','|| 'PERSONID'|| ','|| 'HUMANRESOURCESASSIGNMENT'|| ','|| 'HUMANRESOURCESASSIGNMENTID'|| ','|| 'PROJECTNUMBER'|| ','|| 'PROJECT_NAME'|| ','|| 'PROJECTID'|| ','|| 'TASKNUMBER'|| ','|| 'TASK_NAME'|| ','|| 'TASKID'|| ','|| 'EXPENDITURETYPE'|| ','|| 'EXPENDITURETYPEID'|| ','|| 'EXPENDITURE_ORGANIZATION'|| ','|| 'EXPENDITUREORGANIZATIONID'|| ','|| 'CONTRACT_NUMBER'|| ','|| 'CONTRACT_NAME'|| ','|| 'CONTRACT_ID'|| ','|| 'FUNDING_SOURCE_NUMBER'|| ','|| 'FUNDING_SOURCE_NAME'|| ','|| 'QUANTITY'|| ','|| 'UNIT_OF_MEASURE_NAME'|| ','|| 'UNIT_OF_MEASURE_CODE'|| ','|| 'WORKTYPE'|| ','|| 'WORKTYPEID'|| ','||
  'BILLABLE'|| ','|| 'CAPITALIZABLE'|| ','|| 'ACCRUAL_ITEM'|| ','|| 'ORIG_TRANSACTION_REFERENCE'|| ','|| 'UNMATCHEDNEGATIVETRANSACTION'|| ','|| 'REVERSEDORIGINALTRANSACTION'|| ','|| 'EXPENDITUREITEMCOMMENT'|| ','|| 'ACCOUNTINGDATE'|| ','|| 'TRANSACTIONCURRENCYCODE'|| ','|| 'TRANSACTIONCURRENCY'|| ','|| 'RAWCOSTINTRXCURRENCY'|| ','|| 'BURDENEDCOSTINTRXCURRENCY'|| ','|| 'RAWCOSTCREDITCCID'|| ','|| 'RAWCOSTCREDITACCOUNT'|| ','|| 'RAWCOSTDEBITCCID'|| ','|| 'RAWCOSTDEBITACCOUNT'|| ','|| 'BURDENEDCOSTCREDITCCID'|| ','|| 'BURDENEDCOSTCREDITACCOUNT'|| ','|| 'BURDENEDCOSTDEBITCCID'|| ','|| 'BURDENEDCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTDEBITCCID'|| ','|| 'BURDENCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTCREDITCCID'|| ','|| 'BURDENCOSTCREDITACCOUNT'|| ','|| 'PROVIDERLEDGERCURRENCYCODE'|| ','|| 'PROVIDERLEDGERCURRENCY'|| ','|| 'RAWCOSTLEDGERCURRENCY'|| ','|| 'BURDENEDCOSTLEDGERCURRENCY'|| ','|| 'PROVIDERLEDGERRATETYPE'|| ','|| 'PROVIDERLEDGERRATEDATE'|| ','|| 'PROVIDERLEDGERDATETYPE'|| ','||
  'PROVIDERLEDGERRATE'|| ','|| 'PROVIDERLEDGERROUNDINGLIMIT'|| ','|| 'CONVERTED'|| ','|| 'CONTEXTCATEGORY'|| ','|| 'USERDEFINEDATTRIBUTE1'|| ','|| 'USERDEFINEDATTRIBUTE2'|| ','|| 'USERDEFINEDATTRIBUTE3'|| ','|| 'USERDEFINEDATTRIBUTE4'|| ','|| 'USERDEFINEDATTRIBUTE5'|| ','|| 'USERDEFINEDATTRIBUTE6'|| ','|| 'USERDEFINEDATTRIBUTE7'|| ','|| 'USERDEFINEDATTRIBUTE8'|| ','|| 'USERDEFINEDATTRIBUTE9'|| ','|| 'USERDEFINEDATTRIBUTE10'|| ','|| 'FUNDINGSOURCEID'|| ','|| 'RESERVEDATTRIBUTE2'|| ','|| 'RESERVEDATTRIBUTE3'|| ','|| 'RESERVEDATTRIBUTE4'|| ','|| 'RESERVEDATTRIBUTE5'|| ','|| 'RESERVEDATTRIBUTE6'|| ','|| 'RESERVEDATTRIBUTE7'|| ','|| 'RESERVEDATTRIBUTE8'|| ','|| 'RESERVEDATTRIBUTE9'|| ','|| 'RESERVEDATTRIBUTE10'|| ','|| 'ATTRIBUTECATEGORY'|| ','|| 'ATTRIBUTE1'|| ','|| 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','|| 'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'|| ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_proj_yy
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,i.transactiontype|| ','|| i.businessunitname|| ','|| i.businessunitid|| ','|| i.transactionsource|| ','|| i.transactionsourceid|| ','|| i.document|| ','|| i.documentid|| ','|| i.documententry|| ','|| i.documententryid|| ','|| i.expenditurebatch|| ','|| i.batchendingdate|| ','|| i.batchdescription|| ','|| i.expenditureitemdate|| ','|| i.personnumber|| ','|| i.personname|| ','|| i.personid|| ','|| i.humanresourcesassignment|| ','|| i.humanresourcesassignmentid|| ','|| i.projectnumber|| ','|| i.project_name|| ','|| i.projectid|| ','|| i.tasknumber|| ','|| i.task_name|| ','|| i.taskid|| ','|| i.expendituretype|| ','|| i.expendituretypeid|| ','|| i.expenditure_organization|| ','|| i.expenditureorganizationid|| ','|| i.contract_number|| ','|| i.contract_name|| ','|| i.contract_id|| ','|| i.funding_source_number|| ','|| i.funding_source_name|| ','|| i.quantity|| ','|| i.unit_of_measure_name|| ','|| i.unit_of_measure_code|| ','|| i.worktype|| ','||
    i.worktypeid|| ','|| i.billable|| ','|| i.capitalizable|| ','|| i.accrual_item|| ','|| i.orig_transaction_reference|| ','|| i.unmatchednegativetransaction|| ','|| i.reversedoriginaltransaction|| ','|| i.expenditureitemcomment|| ','|| i.accountingdate|| ','|| i.transactioncurrencycode|| ','|| i.transactioncurrency|| ','|| i.rawcostintrxcurrency|| ','|| i.burdenedcostintrxcurrency|| ','|| i.rawcostcreditccid|| ','|| i.rawcostcreditaccount|| ','|| i.rawcostdebitccid|| ','|| i.rawcostdebitaccount|| ','|| i.burdenedcostcreditccid|| ','|| i.burdenedcostcreditaccount|| ','|| i.burdenedcostdebitccid|| ','|| i.burdenedcostdebitaccount|| ','|| i.burdencostdebitccid|| ','|| i.burdencostdebitaccount|| ','|| i.burdencostcreditccid|| ','|| i.burdencostcreditaccount|| ','|| i.providerledgercurrencycode|| ','|| i.providerledgercurrency|| ','|| i.rawcostledgercurrency|| ','|| i.burdenedcostledgercurrency|| ','|| i.providerledgerratetype|| ','|| i.providerledgerratedate|| ','||
    i.providerledgerdatetype|| ','|| i.providerledgerrate|| ','|| i.providerledgerroundinglimit|| ','|| i.converted|| ','|| i.contextcategory|| ','|| i.userdefinedattribute1|| ','|| i.userdefinedattribute2|| ','|| i.userdefinedattribute3|| ','|| i.userdefinedattribute4|| ','|| i.userdefinedattribute5|| ','|| i.userdefinedattribute6|| ','|| i.userdefinedattribute7|| ','|| i.userdefinedattribute8|| ','|| i.userdefinedattribute9|| ','|| i.userdefinedattribute10|| ','|| i.fundingsourceid|| ','|| i.reservedattribute2|| ','|| i.reservedattribute3|| ','|| i.reservedattribute4|| ','|| i.reservedattribute5|| ','|| i.reservedattribute6|| ','|| i.reservedattribute7|| ','|| i.reservedattribute8|| ','|| i.reservedattribute9|| ','|| i.reservedattribute10|| ','|| i.attributecategory|| ','|| i.attribute1|| ','|| i.attribute2|| ','|| i.attribute3|| ','|| i.attribute4|| ','|| i.attribute5|| ','|| i.attribute6|| ','|| i.attribute7|| ','|| i.attribute8|| ','|| i.attribute9|| ','|| i.attribute10);
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Cap_YY procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_proj_exp_cap_yy;
PROCEDURE fbdi_proj_exp_nei_nn
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
      'Conversion' document,
      NULL documentid,
      'Conversion' documententry,
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
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(prj.name,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') project_name,
      NULL projectid,
      task.task_number tasknumber,
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(task.task_name,chr(13), ''), chr(10), ''),chr(39),''),chr(63),''),chr(44),' ') task_name,
      NULL taskid,
      exptyp.expenditure_type expendituretype,
      NULL expendituretypeid,
      (SELECT name
      FROM hr_all_organization_units
      WHERE organization_id=expd.cc_prvdr_organization_id
      ) expenditure_organization,
    NULL expenditureorganizationid,
    NULL contract_number,
    NULL contract_name,
    NULL contract_id,
    NULL funding_source_number,
    NULL funding_source_name ,
    '1' quantity,
    NULL unit_of_measure_name ,
    NVL(expd.unit_of_measure,'DOLLARS') unit_of_measure_code,
    NULL worktype,
    NULL worktypeid,
    expd.billable_flag billable,
    DECODE(SUBSTR(task.task_number,1,2),'02','Y','N') capitalizable,
    NULL accrual_item ,
    expd.expenditure_item_id orig_transaction_reference,
    NULL unmatchednegativetransaction,
    NULL reversedoriginaltransaction,
    REPLACE(REPLACE(REPLACE(REPLACE(ec.expenditure_comment,chr(13), ''), chr(10), ''),chr(39),''),chr(63),'') AS expenditureitemcomment,
    TO_CHAR(expd.expenditure_item_date,'YYYY/MM/DD') accountingdate,
    expd.project_currency_code transactioncurrencycode,
    NULL transactioncurrency,
    raw_cost rawcostintrxcurrency,
    burden_cost_rate burdenedcostintrxcurrency,
    null rawcostcreditccid,
    /*Commented by Priyam for EBS to Cloud segment Change 
    (SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = cr_code_combination_id
    ) rawcostcreditaccount,*/
   --- Added by Priyam for EBS to Cloud segment Change 
    (SELECT  xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,null,'P')
    FROM gl_code_combinations_kfv gl_code_combinations
    where code_combination_id = cr_code_combination_id
    ) rawcostcreditaccount,
-------
    null rawcostdebitccid,
   /*Commented by Priyam for EBS to Cloud segment Change 
   (SELECT gl_code_combinations.concatenated_segments
    FROM gl_code_combinations_kfv gl_code_combinations
    WHERE code_combination_id = dr_code_combination_id
    ) rawcostdebitaccount,*/
 --   Added by Priyam for EBS to Cloud segment Change 
  
    (SELECT xx_gl_beacon_mapping_f1(gl_code_combinations.concatenated_segments,null,'P')
    FROM gl_code_combinations_kfv gl_code_combinations
    where code_combination_id = dr_code_combination_id
    ) rawcostdebitaccount,
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
    expd.attribute_category attributecategory,
    expd.attribute1 attribute1,
    expd.attribute2 attribute2,
    expd.attribute3 attribute3,
    expd.attribute4 attribute4,
    expd.attribute5 attribute5,
    expd.attribute6 attribute6,
    (SELECT vendor_name FROM ap_suppliers WHERE vendor_id = expd.vendor_id
    ) attribute7,
    (SELECT segment1 FROM ap_suppliers WHERE vendor_id = expd.vendor_id
    ) attribute8,
    (SELECT ai.invoice_num
    FROM ap_invoices_all ai
    WHERE 1          =1
    AND ai.invoice_id=expd.document_header_id
    ) attribute9,
    (SELECT TO_CHAR(ai.invoice_date,'YYYY/MM/DD')
    FROM ap_invoices_all ai
    WHERE 1          =1
    AND ai.invoice_id=expd.document_header_id
    ) attribute10
  FROM pa_expenditure_comments ec,
    pa_cost_distribution_lines_all cd,
    pa_transaction_sources src,
    pa_expenditure_types exptyp,
    hr_operating_units ou,
    pa_expenditure_items_all expd,
    pa_tasks task,
    pa_projects_all prj
  WHERE 1                          =1
  AND prj.template_flag            = 'N'
  AND NVL(prj.closed_date,sysdate) > to_date('30-JUN-2018','dd-mon-yyyy')
  AND (prj.segment1 NOT LIKE 'PB%'
  AND prj.segment1 NOT LIKE 'NB%'
  AND prj.segment1 NOT LIKE 'TEM%')
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
    (SELECT MAX(line_num)
    FROM pa_cost_distribution_lines_all d
    WHERE d.expenditure_item_id = expd.expenditure_item_id
    AND d.line_type             = 'R'
    )
    ------------------
  AND ec.expenditure_item_id=expd.expenditure_item_id
 -- Begin Added for pstgb
  AND prj.created_from_project_id IN (  
  select project_id from pa_projects_all
        where template_flag='Y'
and name='US IT Template - Labor Only'
      )
-- End added for PSTGB
  ORDER BY prj.segment1,
    task.task_number,
    expd.expenditure_item_id;
  lc_file_handle utl_file.file_type;
  lv_line_count NUMBER;
  -- l_file_path   VARCHAR(200);
  l_file_name  VARCHAR2(100);
  lv_col_title VARCHAR2(5000);
  l_file_path  VARCHAR2(500):='XXFIN_OUTBOUND';
  lc_errormsg  VARCHAR2(1000);----            VARCHAR2(1000) := NULL;
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
  print_debug_msg ('Package GENERIC_TAX_CHILD_ASSET_HDR START', true);
  ---  print_debug_msg ('P_BOOK_TYPE_CODE '||P_BOOK_TYPE_CODE, TRUE);
  l_file_name    := 'fbdi_ProjectExpenditure_Neither_NN' || '.csv';--GENERIC_TAX_CHILD_ASSET_HDR
  lc_file_handle := utl_file.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  lv_col_title   :='TRANSACTIONTYPE'|| ','|| 'BUSINESSUNITNAME'|| ','|| 'BUSINESSUNITID'|| ','|| 'TRANSACTIONSOURCE'|| ','|| 'TRANSACTIONSOURCEID'|| ','|| 'DOCUMENT'|| ','|| 'DOCUMENTID'|| ','|| 'DOCUMENTENTRY'|| ','|| 'DOCUMENTENTRYID'|| ','|| 'EXPENDITUREBATCH'|| ','|| 'BATCHENDINGDATE'|| ','|| 'BATCHDESCRIPTION'|| ','|| 'EXPENDITUREITEMDATE'|| ','|| 'PERSONNUMBER'|| ','|| 'PERSONNAME'|| ','|| 'PERSONID'|| ','|| 'HUMANRESOURCESASSIGNMENT'|| ','|| 'HUMANRESOURCESASSIGNMENTID'|| ','|| 'PROJECTNUMBER'|| ','|| 'PROJECT_NAME'|| ','|| 'PROJECTID'|| ','|| 'TASKNUMBER'|| ','|| 'TASK_NAME'|| ','|| 'TASKID'|| ','|| 'EXPENDITURETYPE'|| ','|| 'EXPENDITURETYPEID'|| ','|| 'EXPENDITURE_ORGANIZATION'|| ','|| 'EXPENDITUREORGANIZATIONID'|| ','|| 'CONTRACT_NUMBER'|| ','|| 'CONTRACT_NAME'|| ','|| 'CONTRACT_ID'|| ','|| 'FUNDING_SOURCE_NUMBER'|| ','|| 'FUNDING_SOURCE_NAME'|| ','|| 'QUANTITY'|| ','|| 'UNIT_OF_MEASURE_NAME'|| ','|| 'UNIT_OF_MEASURE_CODE'|| ','|| 'WORKTYPE'|| ','|| 'WORKTYPEID'|| ','||
  'BILLABLE'|| ','|| 'CAPITALIZABLE'|| ','|| 'ACCRUAL_ITEM'|| ','|| 'ORIG_TRANSACTION_REFERENCE'|| ','|| 'UNMATCHEDNEGATIVETRANSACTION'|| ','|| 'REVERSEDORIGINALTRANSACTION'|| ','|| 'EXPENDITUREITEMCOMMENT'|| ','|| 'ACCOUNTINGDATE'|| ','|| 'TRANSACTIONCURRENCYCODE'|| ','|| 'TRANSACTIONCURRENCY'|| ','|| 'RAWCOSTINTRXCURRENCY'|| ','|| 'BURDENEDCOSTINTRXCURRENCY'|| ','|| 'RAWCOSTCREDITCCID'|| ','|| 'RAWCOSTCREDITACCOUNT'|| ','|| 'RAWCOSTDEBITCCID'|| ','|| 'RAWCOSTDEBITACCOUNT'|| ','|| 'BURDENEDCOSTCREDITCCID'|| ','|| 'BURDENEDCOSTCREDITACCOUNT'|| ','|| 'BURDENEDCOSTDEBITCCID'|| ','|| 'BURDENEDCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTDEBITCCID'|| ','|| 'BURDENCOSTDEBITACCOUNT'|| ','|| 'BURDENCOSTCREDITCCID'|| ','|| 'BURDENCOSTCREDITACCOUNT'|| ','|| 'PROVIDERLEDGERCURRENCYCODE'|| ','|| 'PROVIDERLEDGERCURRENCY'|| ','|| 'RAWCOSTLEDGERCURRENCY'|| ','|| 'BURDENEDCOSTLEDGERCURRENCY'|| ','|| 'PROVIDERLEDGERRATETYPE'|| ','|| 'PROVIDERLEDGERRATEDATE'|| ','|| 'PROVIDERLEDGERDATETYPE'|| ','||
  'PROVIDERLEDGERRATE'|| ','|| 'PROVIDERLEDGERROUNDINGLIMIT'|| ','|| 'CONVERTED'|| ','|| 'CONTEXTCATEGORY'|| ','|| 'USERDEFINEDATTRIBUTE1'|| ','|| 'USERDEFINEDATTRIBUTE2'|| ','|| 'USERDEFINEDATTRIBUTE3'|| ','|| 'USERDEFINEDATTRIBUTE4'|| ','|| 'USERDEFINEDATTRIBUTE5'|| ','|| 'USERDEFINEDATTRIBUTE6'|| ','|| 'USERDEFINEDATTRIBUTE7'|| ','|| 'USERDEFINEDATTRIBUTE8'|| ','|| 'USERDEFINEDATTRIBUTE9'|| ','|| 'USERDEFINEDATTRIBUTE10'|| ','|| 'FUNDINGSOURCEID'|| ','|| 'RESERVEDATTRIBUTE2'|| ','|| 'RESERVEDATTRIBUTE3'|| ','|| 'RESERVEDATTRIBUTE4'|| ','|| 'RESERVEDATTRIBUTE5'|| ','|| 'RESERVEDATTRIBUTE6'|| ','|| 'RESERVEDATTRIBUTE7'|| ','|| 'RESERVEDATTRIBUTE8'|| ','|| 'RESERVEDATTRIBUTE9'|| ','|| 'RESERVEDATTRIBUTE10'|| ','|| 'ATTRIBUTECATEGORY'|| ','|| 'ATTRIBUTE1'|| ','|| 'ATTRIBUTE2'|| ','|| 'ATTRIBUTE3'|| ','|| 'ATTRIBUTE4'|| ','|| 'ATTRIBUTE5'|| ','|| 'ATTRIBUTE6'|| ','|| 'ATTRIBUTE7'|| ','|| 'ATTRIBUTE8'|| ','|| 'ATTRIBUTE9'|| ','|| 'ATTRIBUTE10';
  utl_file.put_line(lc_file_handle,lv_col_title);
  FOR i IN c_proj_nn
  LOOP
    ---UTL_FILE.put_line(lc_file_handle,'HI');
    utl_file.put_line(lc_file_handle,i.transactiontype|| ','|| i.businessunitname|| ','|| i.businessunitid|| ','|| i.transactionsource|| ','|| i.transactionsourceid|| ','|| i.document|| ','|| i.documentid|| ','|| i.documententry|| ','|| i.documententryid|| ','|| i.expenditurebatch|| ','|| i.batchendingdate|| ','|| i.batchdescription|| ','|| i.expenditureitemdate|| ','|| i.personnumber|| ','|| i.personname|| ','|| i.personid|| ','|| i.humanresourcesassignment|| ','|| i.humanresourcesassignmentid|| ','|| i.projectnumber|| ','|| i.project_name|| ','|| i.projectid|| ','|| i.tasknumber|| ','|| i.task_name|| ','|| i.taskid|| ','|| i.expendituretype|| ','|| i.expendituretypeid|| ','|| i.expenditure_organization|| ','|| i.expenditureorganizationid|| ','|| i.contract_number|| ','|| i.contract_name|| ','|| i.contract_id|| ','|| i.funding_source_number|| ','|| i.funding_source_name|| ','|| i.quantity|| ','|| i.unit_of_measure_name|| ','|| i.unit_of_measure_code|| ','|| i.worktype|| ','||
    i.worktypeid|| ','|| i.billable|| ','|| i.capitalizable|| ','|| i.accrual_item|| ','|| i.orig_transaction_reference|| ','|| i.unmatchednegativetransaction|| ','|| i.reversedoriginaltransaction|| ','|| i.expenditureitemcomment|| ','|| i.accountingdate|| ','|| i.transactioncurrencycode|| ','|| i.transactioncurrency|| ','|| i.rawcostintrxcurrency|| ','|| i.burdenedcostintrxcurrency|| ','|| i.rawcostcreditccid|| ','|| i.rawcostcreditaccount|| ','|| i.rawcostdebitccid|| ','|| i.rawcostdebitaccount|| ','|| i.burdenedcostcreditccid|| ','|| i.burdenedcostcreditaccount|| ','|| i.burdenedcostdebitccid|| ','|| i.burdenedcostdebitaccount|| ','|| i.burdencostdebitccid|| ','|| i.burdencostdebitaccount|| ','|| i.burdencostcreditccid|| ','|| i.burdencostcreditaccount|| ','|| i.providerledgercurrencycode|| ','|| i.providerledgercurrency|| ','|| i.rawcostledgercurrency|| ','|| i.burdenedcostledgercurrency|| ','|| i.providerledgerratetype|| ','|| i.providerledgerratedate|| ','||
    i.providerledgerdatetype|| ','|| i.providerledgerrate|| ','|| i.providerledgerroundinglimit|| ','|| i.converted|| ','|| i.contextcategory|| ','|| i.userdefinedattribute1|| ','|| i.userdefinedattribute2|| ','|| i.userdefinedattribute3|| ','|| i.userdefinedattribute4|| ','|| i.userdefinedattribute5|| ','|| i.userdefinedattribute6|| ','|| i.userdefinedattribute7|| ','|| i.userdefinedattribute8|| ','|| i.userdefinedattribute9|| ','|| i.userdefinedattribute10|| ','|| i.fundingsourceid|| ','|| i.reservedattribute2|| ','|| i.reservedattribute3|| ','|| i.reservedattribute4|| ','|| i.reservedattribute5|| ','|| i.reservedattribute6|| ','|| i.reservedattribute7|| ','|| i.reservedattribute8|| ','|| i.reservedattribute9|| ','|| i.reservedattribute10|| ','|| i.attributecategory|| ','|| i.attribute1|| ','|| i.attribute2|| ','|| i.attribute3|| ','|| i.attribute4|| ','|| i.attribute5|| ','|| i.attribute6|| ','|| i.attribute7|| ','|| i.attribute8|| ','|| i.attribute9|| ','|| i.attribute10);
  END LOOP;
  utl_file.fclose(lc_file_handle);
EXCEPTION
WHEN utl_file.access_denied THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' access_denied :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.delete_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' delete_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.file_open THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' file_open :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.internal_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' internal_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filehandle THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure:- ' || ' invalid_filehandle :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_filename THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' invalid_filename :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_maxlinesize THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' invalid_maxlinesize :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_mode THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' invalid_mode :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_offset THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' invalid_offset :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_operation THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' invalid_operation :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.invalid_path THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' invalid_path :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.read_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' read_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.rename_failed THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' rename_failed :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN utl_file.write_error THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' write_error :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
WHEN OTHERS THEN
  lc_errormsg := ( 'Error in fbdi_Proj_Exp_Nei_NN procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, true);
  utl_file.fclose_all;
  lc_file_handle := utl_file.fopen (l_file_path, l_file_name, 'W', 32767);
  utl_file.fclose(lc_file_handle);
END fbdi_proj_exp_nei_nn;
PROCEDURE xx_od_fa_con_script_wrapper(
    p_errbuf         VARCHAR2,
    p_retcode        NUMBER,
    P_module         VARCHAR2,
    p_book_type_code VARCHAR2,
    p_book_class     VARCHAR2)
AS
  v_book_type_code VARCHAR2(50);
BEGIN
  BEGIN
    IF p_module       ='FA' THEN
      IF p_book_class = 'TAX' THEN
        generic_tax_parent_asset_hdr(p_book_type_code);
        generic_tax_child_asset_hdr(p_book_type_code);
        generic_tax_parent_dist(p_book_type_code);
        generic_tax_child_dist(p_book_type_code);
      ELSE
        ---v_book_type_code:='OD US CORP';
        oduscorp_parent_assets_hdr(p_book_type_code);
        oduscorp_child_assets_hdr(p_book_type_code);
        oduscorp_parent_distribution(p_book_type_code);
        oduscorp_child_distribution(p_book_type_code);
      END IF;
    ELSE
      fbdi_project_assets;
      fbdi_proj_exp_cap_yn;
      fbdi_proj_exp_cap_yy;
      fbdi_proj_exp_nei_nn;
    END IF;
  END;
EXCEPTION
WHEN OTHERS THEN
  --  LC_ERRORMSG := ( 'Error in xx_od_fa_con_script_pstgb_WRAPPER procedure :- ' || ' OTHERS :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg ('Error in xx_od_fa_con_script_pstgb_WRAPPER procedure :- ' || ' OTHERS :: ' || SUBSTR (sqlerrm, 1, 3800) || SQLCODE, TRUE);
END xx_od_fa_con_script_wrapper;
END xx_od_fa_con_script_pstgb;
/

SHOW ERRORS;