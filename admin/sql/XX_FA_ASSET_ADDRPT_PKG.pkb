SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package  XX_FA_ASSET_ADDRPT_PKG

Prompt Program Exits If The Creation Is Not Successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY XX_FA_ASSET_ADDRPT_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             : XX_FA_ASSET_ADDRPT_PKG                          |
-- | Description      : This Program generates fixed asset data,related to   |
-- |                   additions and register for the report, into Table     |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    20-Mar-2015   Madhu Bolli       Initial code                  |
-- |    1.1    06-Apr-2015   Paddy Sanjeevi    Defect 1047 Modified for the Calendar Period|
-- |    1.2    16-Apr-2015   Paddy Sanjeevi    Defect 1110                   |
-- |    1.3    27-Apr-2015   Paddy Sanjeevi    Removed Asset Register        |
-- |    1.4    30-Oct-2015   Madhu Bolli       122 Retrofit - Remove schema  |
-- +=========================================================================+
AS

FUNCTION get_fperiod(p_psdate DATE,p_month NUMBER)
RETURN VARCHAR2
IS

CURSOR C_period 
IS
SELECT period_name,start_date
FROM (
SELECT period_name,TRUNC(start_date) start_date
  FROM fa_calendar_periods
 WHERE TRUNC(start_date)>=p_psdate
 ORDER by start_date
     )
 where rownum<p_month+2;

v_ctr NUMBER:=0;
v_fperiod VARCHAR2(20);
BEGIN
  FOR cur IN c_period LOOP
    v_ctr:=v_Ctr+1;
    IF v_ctr=p_month+1 THEN
       v_fperiod:=cur.period_name;
    END IF;
  END LOOP;
  IF v_ctr<>p_month+1 THEN
     v_fperiod:='PERIOD MISS';
  END IF;
  RETURN(v_fperiod);
EXCEPTION
  WHEN others THEN
    v_fperiod:=NULL;
    RETURN(v_fperiod);
END get_fperiod;

FUNCTION process_asset_addition
RETURN BOOLEAN
IS
CURSOR c_get_assets_add
IS
SELECT 
       a.asset_id,    
       a.asset_number,                            
       a.description,                                
       b.book_type_code,
       fcal.period_name,
       a.attribute6 legacy_asset_no,
       a.attribute7 historical_cost,
       a.attribute8 legacy_dpis,
       a.attribute10 tax_asset_id,
       a.attribute14 vendor_name,
       a.attribute12,
       a.attribute15 invoice_no,
       a.serial_number,
       ftxn.transaction_type_code,   
       cc.segment1 company,                                
       fal.segment5 location,
       cc.segment4 building,                                
       cc.segment2 costcenter,    
       cc.segment6 lob,    
       cc.segment3 account,                            
       fcat.segment1 Major,                                
       fcat.segment2 Minor,                                
       fcat.segment3 Subminor,
       fcat.segment1||'.'||fcat.segment2||'.'||fcat.segment3 asset_category,
       fb.deprn_method_code,
       fb.depreciate_flag,
       fb.date_placed_in_service,                                
       fb.life_in_months,
       ftxn.amortization_start_date,
       DECODE(fb.rate_adjustment_factor,1,'No','Yes') Amortized_Flag,    
       a.asset_type,
       a.current_units asset_units,
       a.new_used,
       fb.prorate_convention_code
  FROM --xla_events xla,
       gl_code_combinations cc,
       fa_categories_b fcat,
       fa_locations fal,    
       fa_transaction_headers ftxn,
       fa_calendar_periods fcal,
       fa_books fb,                    
       fa_distribution_history b,    
       fa_additions a                                
 WHERE 1=1 --and a.asset_id in (21000125,20878213,20940206)
   AND fcal.period_name=p_period
   AND b.asset_id=a.asset_id
   AND b.date_ineffective is null                          
   AND b.book_type_code=p_book_type
   AND fb.asset_id=b.asset_id
   AND fb.book_type_code=b.book_type_code
   AND fb.date_ineffective IS NULL
   AND ftxn.asset_id=a.asset_id
-- AND TRUNC(ftxn.date_effective) BETWEEN fcal.start_date AND fcal.end_date
   AND ftxn.transaction_type_code='ADDITION' 
   AND ftxn.transaction_subtype IS NULL
   AND ftxn.book_type_code=fb.book_type_code
   AND fal.location_id=b.location_id
   AND fal.segment5=NVL(p_location,fal.segment5)
   AND fcat.category_id=a.asset_category_id 
   AND cc.code_combination_id=b.code_combination_id
   AND EXISTS (SELECT 'x'
		 FROM 
		      xla_events xla
		WHERE xla.event_id=ftxn.event_id
		  AND xla.application_id=140
	          AND TRUNC(xla.event_date) BETWEEN fcal.start_date AND fcal.end_date
	      )
group by
       a.asset_id,    
       a.asset_number,                            
       a.description,                                
       b.book_type_code,
       fcal.period_name,
       a.attribute6 ,
       a.attribute7 ,
       a.attribute8 ,
       a.attribute10 ,
       a.attribute14 ,
       a.attribute12,
       a.attribute15 ,
       a.serial_number,
       ftxn.transaction_type_code,                                
       cc.segment1 ,
       fal.segment5 ,
       cc.segment4 ,
       cc.segment2 ,
       cc.segment6 ,
       cc.segment3 ,
       fcat.segment1 ,
       fcat.segment2 ,
       fcat.segment3 ,
       fcat.segment1||'.'||fcat.segment2||'.'||fcat.segment3 ,
       fb.deprn_method_code,
       fb.depreciate_flag,
       fb.date_placed_in_service,                                
       fb.life_in_months,
       ftxn.amortization_start_date,
       DECODE(fb.rate_adjustment_factor,1,'No','Yes') ,    
       a.asset_type,
       a.current_units ,
       a.new_used,
       fb.prorate_convention_code;
CURSOR c_asset_adj_amt (p_asset_id NUMBER, p_period VARCHAR2, p_book VARCHAR2)
IS
 SELECT SUM(NVL(adj.adjustment_amount,0)) amt,debit_credit_Flag
   FROM xla_events xla,
	fa_adjustments adj,
        fa_calendar_periods fc,
        fa_transaction_headers ftxn
  WHERE ftxn.asset_id= P_ASSET_ID
    AND ftxn.book_type_code = P_BOOK
    AND fc.period_name = P_PERIOD
--  AND TRUNC(ftxn.date_effective)  BETWEEN fc.start_date AND fc.end_date
    AND adj.transaction_header_id=ftxn.transaction_header_id
    AND adj.adjustment_type='COST'
    AND xla.event_id=ftxn.event_id
    AND xla.application_id=140
    AND TRUNC(xla.event_date) BETWEEN fc.start_date AND fc.end_date
GROUP BY debit_credit_Flag;
 v_asset_cost NUMBER;
 v_asset_invoice_id NUMBER;
 v_cr NUMBER:=0;
 v_dr NUMBER:=0;
 v_total_cost NUMBER:=0;
 CP_FEEDER_SYSTEM    VARCHAR2(50):=NULL;
 CP_PAYABLES_COST    NUMBER:=NULL;
 CP_PAYABLES_UNITS    NUMBER:=NULL;
 CP_PAN        VARCHAR2(50);
 CP_PAYABLES_ACCOUNT VARCHAR2(100);
 l_function_name  VARCHAR2(30) :=  'c_get_assets_rowId';   
 v_cnt NUMBER:=0; 
  
BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Book Type :'||p_book_type);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Period    :'||p_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Location  :'||p_location);
   FOR CUR IN c_get_assets_add LOOP

     v_cnt:=v_cnt+1;
     v_asset_cost :=0;
     v_asset_invoice_id :=0;
     v_cr :=0;
     v_dr :=0;
     v_total_cost :=0;
     CP_FEEDER_SYSTEM    :=NULL;
     CP_PAYABLES_COST    :=NULL;
     CP_PAYABLES_UNITS    :=NULL;
     CP_PAN:=NULL;
   CP_PAYABLES_ACCOUNT:=NULL;
   BEGIN
    SELECT feeder_system_name,payables_units,payables_cost,asset_invoice_id
      INTO CP_FEEDER_SYSTEM, CP_PAYABLES_UNITS, CP_PAYABLES_COST, v_asset_invoice_id
      FROM fa_asset_invoices fai
     WHERE asset_id=cur.asset_id
       AND asset_invoice_id=(SELECT MAX(asset_invoice_id)
                               FROM xla_events xla,
                                    fa_transaction_headers ftxn,
			            fa_calendar_periods fc,
                                    fa_asset_invoices fa
                              WHERE fa.asset_id=fai.asset_id
				AND ftxn.asset_id=fa.asset_id
                                AND xla.event_id=ftxn.event_id
				AND xla.application_id=140
                                AND TRUNC(xla.event_date) BETWEEN fc.start_date AND fc.end_date
                                --AND TRUNC(fa.date_effective) BETWEEN fc.start_date AND fc.end_date
                                AND fc.period_name=cur.period_name
                             );
  EXCEPTION
    WHEN others THEN
      CP_FEEDER_SYSTEM:=NULL;
      CP_PAYABLES_COST:=NULL;
      CP_PAYABLES_UNITS:=NULL;
      v_asset_invoice_id:=-1;
  END;
  IF v_asset_invoice_id > 0 THEN
      BEGIN
          SELECT SUBSTR(segment1,1,INSTR(segment1,'-',1)-1)
        INTO CP_PAN
        FROM pa_projects_all 
        WHERE project_id IN (SELECT MAX(project_id)
                                      FROM fa_asset_invoices fa
                                     WHERE fa.asset_id=cur.asset_id
                                       AND asset_invoice_id=v_asset_invoice_id
                                 );
      EXCEPTION
          WHEN others THEN
            CP_PAN:=NULL;
        END;
    BEGIN
      SELECT segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7
        INTO CP_PAYABLES_ACCOUNT
        FROM gl_code_combinations
       WHERE code_combination_id IN (SELECT payables_code_combination_id
                                                            FROM fa_asset_invoices fai
                                                           WHERE asset_id=cur.asset_id
                                                               AND asset_invoice_id=v_asset_invoice_id
                                              );
      EXCEPTION
          WHEN others THEN
            CP_PAYABLES_ACCOUNT:=NULL;
        END;
  END IF;
  FOR C IN c_asset_adj_amt(cur.asset_id,cur.period_name,cur.book_type_code) LOOP
    IF c.debit_credit_Flag='CR' THEN
       v_cr :=c.amt;
    ELSIF
       c.debit_credit_flag='DR' THEN
       v_dr:=c.amt;
    END IF;        
  END LOOP;   
    v_total_cost:=NVL(v_dr,0)-NVL(v_cr,0);
    BEGIN
    INSERT
      INTO xx_fa_asset_addrpt_gt(
       asset_id,    
       asset_number,                            
       description,                                
       book_type_code,
       period_name,
       legacy_asset_no,
       historical_cost,
       legacy_dpis,
       tax_asset_id,
       vendor_name,
       attribute12,
       invoice_no,
       serial_number,
       transaction_type_code,   
       company,                                
       location,
       building,                                
       costcenter,    
       lob,    
       account,                            
       Major,                                
       Minor,                                
       Subminor,
       asset_category,
       deprn_method_code,
       depreciate_flag,
       date_placed_in_service,                                
       life_in_months,
       amortization_start_date,
       Amortized_Flag,    
       asset_type,
       asset_units,
       new_used,
       prorate_convention_code,
       CP_FEEDER_SYSTEM, 
       CP_PAYABLES_UNITS,
       CP_PAYABLES_COST,
       CP_PAN,
       CP_PAYABLES_ACCOUNT,
       cost, 
         creation_Date,
       request_id
      )
    VALUES
    (
       cur.asset_id,    
       cur.asset_number,                            
       cur.description,                                
       cur.book_type_code,
       cur.period_name,
       cur.legacy_asset_no,
       cur.historical_cost,
       cur.legacy_dpis,
       cur.tax_asset_id,
       cur.vendor_name,
       cur.attribute12,
       cur.invoice_no,
       cur.serial_number,
       cur.transaction_type_code,   
       cur.company,                                
       cur.location,
       cur.building,                                
       cur.costcenter,    
       cur.lob,    
       cur.account,                            
       cur.Major,                                
       cur.Minor,                                
       cur.Subminor,
       cur.asset_category,
       cur.deprn_method_code,
       cur.depreciate_flag,
       cur.date_placed_in_service,                                
       cur.life_in_months,
       cur.amortization_start_date,
       cur.Amortized_Flag,    
       cur.asset_type,
       cur.asset_units,
       cur.new_used,
       cur.prorate_convention_code,
       CP_FEEDER_SYSTEM, 
         CP_PAYABLES_UNITS,
       CP_PAYABLES_COST,
       CP_PAN,
       CP_PAYABLES_ACCOUNT,
       v_total_cost,
       sysdate,
       fnd_global.conc_request_id
    );
  EXCEPTION
   WHEN others THEN
    null;
  END;
  COMMIT;
 END LOOP;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Total :'||TO_CHAR(v_cnt)||' Asset Addition Records inserted into the table xx_fa_asset_addrpt_gt successfully'); RETURN TRUE;
 RETURN TRUE;
END process_asset_addition;
End XX_FA_ASSET_ADDRPT_PKG;
/
SHOW ERRORS;
