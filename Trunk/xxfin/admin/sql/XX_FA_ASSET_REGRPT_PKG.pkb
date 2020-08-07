SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF 
SET TERM ON

PROMPT Creating Package  XX_FA_ASSET_REGRPT_PKG

Prompt Program Exits If The Creation Is Not Successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY XX_FA_ASSET_REGRPT_PKG
-- +=======================================================================================+
-- |                  Office Depot - Project Simplify                                      |
-- |                  Office Depot                                                         |
-- +=======================================================================================+
-- | Name             : XX_FA_ASSET_REGRPT_PKG                                             |
-- | Description      : This Program generates fixed asset data,related to                 |
-- |                    Asset register for the report                                      |
-- |                                                                                       |
-- |                                                                                       |
-- |Change Record:                                                                         |
-- |===============                                                                        |
-- |Version    Date          Author            Remarks                                     |
-- |=======    ==========    =============     ============================================|
-- |    1.0    20-Mar-2015   Madhu Bolli       Initial code                                |
-- |    1.1    06-Apr-2015   Paddy Sanjeevi    Defect 1047 Modified for the Calendar Period|
-- |    1.2    16-Apr-2015   Paddy Sanjeevi    Defect 1110                                 |
-- |    1.3    17-Apr-2015   Madhu Bolli       Modified to get output in txt format        |
-- |                                           and update 2 queries                        |
-- |    1.4    17-Apr-2015   Madhu Bolli       Replace double quote(") from attribute15    |
-- |    1.5    01-May-2015   Paddy Sanjeevi    Modified to improve performance             |
-- |    1.6    17-Jun-2015   Paddy Sanjeevi    Added FTP call to transfer file             |
-- |    1.7    30-Oct-2015   Madhu Bolli       122 Retrofit - Remove schema                |
-- +=======================================================================================+
AS


PROCEDURE FA_REGISTER_FTP
IS

ln_req_id	NUMBER;
v_filename	VARCHAR2(100);
v_request_id	NUMBER:=FND_GLOBAL.CONC_REQUEST_ID;
BEGIN

  v_filename:='o'||TO_CHAR(v_request_id)||'.out';
 
  FND_FILE.PUT_LINE(FND_FILE.LOG, '');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '*************************************************************');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'FTPing zip file to SFTP server');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Source file name :'||v_filename);
  FND_FILE.PUT_LINE(FND_FILE.LOG, '');

  ln_req_id := FND_REQUEST.SUBMIT_REQUEST( application => 'XXFIN'
                                          ,program     => 'XXCOMFTP'
                                          ,description => 'OD FA Register Output FTP PUT'
                                          ,sub_request => FALSE
                                          ,argument1   => 'OD_FA_REGISTER'      -- Row from OD_FTP_PROCESSES translation
                                          ,argument2   => v_filename            -- Source file name
                                          ,argument3   => NULL                  -- Dest file name
                                          ,argument4   => 'Y'                   -- Delete source file
                                         );
  COMMIT;
  IF ln_req_id = 0 THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error : Unable to submit FTP program to send FA Register file');
  ELSE
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitted FTP file to SFTP server. Request id : '|| ln_req_id);
  END IF;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in OD FAGL_BAL_EXTRACT_FTP :'||SQLERRM);
END FA_REGISTER_FTP;


FUNCTION xx_fa_get_compl_period (p_psdate DATE,p_month NUMBER,p_asset_id NUMBER,p_book VARCHAR2)
return varchar2
is
CURSOR C_period(p_date DATE)
IS
SELECT period_name,start_date
FROM (
SELECT period_name,TRUNC(start_date) start_date
  FROM fa_calendar_periods
 WHERE TRUNC(start_date)>=p_date
 ORDER by start_date
     )
 where rownum<p_month+2;
v_ctr NUMBER:=0;
v_fperiod VARCHAR2(20);
v_dpis_psdate DATE;
v_date DATE;
BEGIN
  v_date:=p_psdate;
  IF p_month=0 THEN
    BEGIN
	 SELECT MAX(date_effective)
	   INTO v_date
	   FROM fa_transaction_headers
	  WHERE asset_id=p_asset_id
	    AND book_type_code=p_book;
    EXCEPTION
      WHEN others THEN
	v_date:=NULL;
    END;
  END IF;
  FOR cur IN c_period(v_date) LOOP
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
END xx_fa_get_compl_period;

PROCEDURE process_asset_register ( x_errbuf      	OUT NOCOPY VARCHAR2
                                    ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_period		IN  VARCHAR2
				    ,p_book_type	IN  VARCHAR2
				    ,p_company		IN  VARCHAR2
				    ,p_cost_ctr		IN  VARCHAR2
				    ,p_location		IN  VARCHAR2
				    ,p_lob		IN  VARCHAR2
				    ,p_cat_major	IN  VARCHAR2
	    		          )
IS
-- 1.3 modification 

CURSOR c_get_assets_register
IS
SELECT 
       a.asset_id,    
       a.asset_number,                            
       replace(a.description,'^','') description,                                
       b.book_type_code,
--     fcal.period_name,
       replace(a.attribute6,'^','') legacy_asset_no,
       replace(a.attribute7,'^','') historical_cost,
       replace(a.attribute8,'^','') legacy_dpis,
       replace(a.attribute10,'^','') tax_asset_id,
       replace(a.attribute14,'^','') vendor_name,
       a.attribute12,
-- 1.4      a.attribute15 invoice_no,
	   replace(a.attribute15, '"','') invoice_no,
       replace(a.serial_number,'^','') serial_number,
       cc.segment1 company,                                
       cc.segment4 building,                                
       fal.segment5 location,
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
       NVL(fb.life_in_months,0) life_in_months,
       DECODE(fb.rate_adjustment_factor,1,'No','Yes') Amortized_Flag,    
       a.asset_type,
       a.current_units asset_units,
       a.new_used,
       fb.prorate_convention_code,
       fb.cost,
       ds.deprn_amount,                                
       ds.ytd_deprn,                                
       ds.deprn_reserve,
       (fb.cost-ds.deprn_reserve) nbv,
       xx_fa_get_compl_period(fcp.start_date,NVL(fb.life_in_months,0),a.asset_id,b.book_type_code) compl_period
  FROM 
       fa_calendar_periods fcp,
       gl_code_combinations cc,
       fa_categories_b fcat,
       (select DS1.ASSET_ID,
        DS1.BOOK_TYPE_CODE,
        DS1.DEPRN_AMOUNT,
        DS1.YTD_DEPRN,
        DS1.DEPRN_RESERVE,
        rank() OVER(PARTITION BY DS1.ASSET_ID,DS1.BOOK_TYPE_CODE ORDER BY DS1.PERIOD_COUNTER DESC) DSRANK
        from FA_DEPRN_SUMMARY DS1) DS,
       fa_locations fal,    
       fa_books fb,                    
       fa_distribution_history b,    
       fa_additions a                                
 WHERE 1=1
-- AND a.asset_id=24710  
   AND b.asset_id=a.asset_id
   AND b.date_ineffective is null                          
   AND b.book_type_code=p_book_type
   AND fb.asset_id=b.asset_id
   AND fb.book_type_code=b.book_type_code
   AND fb.date_ineffective IS NULL
   AND fal.location_id=b.location_id
   AND fal.segment5=NVL(p_location,fal.segment5)
   AND fcat.category_id=a.asset_category_id 
   AND fcat.segment1=NVL(p_cat_major,fcat.segment1)
   AND cc.code_combination_id=b.code_combination_id
   AND cc.segment1=NVL(p_company,cc.segment1)
   AND cc.segment2=NVL(p_cost_ctr,cc.segment2)
   AND cc.segment6=NVL(p_lob,cc.segment6)
   AND ds.asset_id=fb.asset_id                                
   AND ds.book_type_code=fb.book_type_code
   AND DS.DSRANK = 1                        
   AND TRUNC(fb.date_placed_in_service) BETWEEN TRUNC(fcp.start_date) AND TRUNC(fcp.end_date)
   AND EXISTS (SELECT 'x'
                 FROM xla_events xla,
		                  fa_transaction_headers ftxn,
                      fa_calendar_periods fc
                WHERE fc.period_name=p_period
                  AND ftxn.asset_id=a.asset_id
                  AND ftxn.book_type_code=fb.book_type_code
                  AND xla.event_id=ftxn.event_id
		              AND xla.application_id=140
                  AND TRUNC(xla.event_date)<fc.end_date
              );

CURSOR C2 IS
SELECT fai.FEEDER_SYSTEM_NAME,
       fai.PAYABLES_UNITS    ,
       fai.PAYABLES_COST     ,
       fai.ASSET_INVOICE_ID,
       fai.asset_id,xai.drowid
  FROM FA_ASSET_INVOICES FAI,
       (SELECT MAX(ASSET_INVOICE_ID) MASSET_INVOICE_ID,fa.asset_id,a.rowid drowid
          FROM XLA_EVENTS XLA             ,
               FA_TRANSACTION_HEADERS FTXN,
               FA_CALENDAR_PERIODS FC     ,
               FA_ASSET_INVOICES FA,
               xx_fa_asset_addrpt_gt a
         WHERE FA.ASSET_ID           = a.asset_id
           AND FTXN.ASSET_ID         = FA.ASSET_ID
           AND XLA.EVENT_ID          = FTXN.EVENT_ID
           AND XLA.APPLICATION_ID    = 140
           AND TRUNC(XLA.EVENT_DATE) < FC.END_DATE
           AND FC.PERIOD_NAME        = p_period
         GROUP BY fa.asset_id,a.rowid
             ) XAI
  WHERE FAI.ASSET_INVOICE_ID = XAI.MASSET_INVOICE_ID;

 CURSOR C3 IS
 SELECT SUBSTR(prj.segment1,1,INSTR(prj.segment1,'-',1)-1) PAN,
	fap.asset_id,fap.drowid
   FROM 
	pa_projects_all prj,
	( SELECT MAX(project_id) project_id,fa.asset_id,a.rowid drowid
            FROM fa_asset_invoices fa,
		 xx_fa_asset_addrpt_gt a
           WHERE a.request_id IS NOT NULL
	     AND fa.asset_id=a.asset_id
             AND fa.asset_invoice_id=a.request_id
	   GROUP BY fa.asset_id,a.rowid
	) fap
  WHERE prj.project_id=fap.project_id; 

 CURSOR C4 IS
 SELECT 
	fac.asset_id,fac.drowid,
	gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7 payables_acct
   FROM gl_code_combinations gcc,
	( SELECT MAX(payables_code_combination_id) pay_ccid,fa.asset_id,b.rowid drowid
            FROM fa_asset_invoices fa,
		 xx_fa_asset_addrpt_gt b
           WHERE b.request_id IS NOT NULL
	     AND fa.asset_id=b.asset_id
             AND fa.asset_invoice_id=b.request_id
	   GROUP BY fa.asset_id,b.rowid
	) fac
  WHERE gcc.code_combination_id=fac.pay_ccid;

  CURSOR C5 IS
  SELECT fap.period_name fa_period,
	 glp.period_name gl_period,
	 evt.asset_id,
	 evt.drowid
    FROM fa_calendar_periods fap,
	 gl_periods glp,
         ( SELECT TRUNC(MAX(event_date)) event_date,b.asset_id,b.rowid drowid
             FROM xla_events xla,
	          fa_transaction_headers ftxn,
                  xx_fa_asset_addrpt_gt b
            WHERE ftxn.asset_id=b.asset_id
              AND ftxn.book_type_code=b.book_type_code
              AND xla.event_id=ftxn.event_id
              AND xla.application_id=140
	    GROUP BY b.asset_id,b.rowid
          ) evt
   WHERE evt.event_date BETWEEN fap.start_date AND fap.end_date
     AND evt.event_date BETWEEN glp.start_date AND glp.end_date
     AND glp.period_set_name='OD 445 CALENDAR';


  CURSOR C6 IS
  SELECT max(fth.amortization_start_date) amort_sdate, 
	 fth.asset_id,amt.drowid
    FROM fa_transaction_headers fth,
	 (SELECT max(date_effective) date_effective,ft.asset_id,ft.book_type_code,b.rowid drowid
            FROM fa_calendar_periods fcal,
		 xla_events xla,
                 fa_transaction_headers ft,
		 xx_fa_asset_addrpt_gt b
           where b.amortized_Flag='Yes'
	     AND ft.asset_id=b.asset_id
             and ft.book_type_code=b.book_type_code
	     and xla.event_id=ft.event_id
	     and xla.application_id=140
	     and TRUNC(xla.event_date)<fcal.end_date
             and fcal.period_name=p_period
           GROUP BY ft.asset_id,ft.book_type_code,b.rowid
	 ) amt
   WHERE fth.asset_id=amt.asset_id   
     AND fth.book_type_code=amt.book_type_code
     AND fth.transaction_subtype='AMORTIZED'  
     AND fth.date_effective=amt.date_effective
   GROUP BY fth.asset_id,amt.drowid;


  CURSOR C7 IS
  SELECT * 
    FROM xx_fa_asset_addrpt_gt
   ORDER BY asset_id;


 l_function_name  VARCHAR2(30) :=  'c_get_assets_register';   
 v_cnt NUMBER:=0;
 j NUMBER:=0;



BEGIN

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Book 		:'||p_book_type);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Period 	:'||p_period);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Company 	:'||p_company);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Cost Center 	:'||p_cost_ctr);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Location 	:'||p_location);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'LOB	 	:'||p_lob);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Major Category:'||p_cat_major);

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Beginning of Main Cursor :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'No^PAN Number^FA Entered Period^Asset Book^Asset Number^Asset Description^Asset Type^Company^Location^Cost Center^Line of Business^Major^Minor^Subminor^Depreciation Method^Asset Category^Depreciate Flag^Feeder System^New Used^Legacy Asset No^Historical Cost^Legacy DPIS^Tax Asset ID^Vendor Name^Invoice No^Serial No^Amortization Start Date^Amortized Flag^Asset Units^Prorate Convention Code^Payables Units^Payables Cost^Payables Account^Account^Life in Months^Date placed in Service^FA Life Completed Period Name^GL Period^Asset Cost^Depreciation Amount^YTD Depreciation Amount^Depreciation Reserve^NBV^');
  

  FOR CUR IN c_get_assets_register LOOP

     j:=j+1;

     IF j>10000 THEN
        COMMIT;
        j:=0;
     END IF;    

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
	       request_id,
	       cp_complete_period,
	       cp_amortized_date,
               deprn_amount,                                
	       ytd_deprn,                                
	       deprn_reserve,
	       nbv,
	       gl_period
       )
       VALUES
       (
 	      cur.asset_id,    
	       cur.asset_number,                            
	       cur.description,                                
	       cur.book_type_code,
	       NULL, --v_fa_period,
	       cur.legacy_asset_no,
	       cur.historical_cost,
	       cur.legacy_dpis,
	       cur.tax_asset_id,
	       cur.vendor_name,
	       cur.attribute12,
	       cur.invoice_no,
	       cur.serial_number,
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
	       cur.Amortized_Flag,    
	       cur.asset_type,
	       cur.asset_units,
	       cur.new_used,
	       cur.prorate_convention_code,
	       NULL,  --CP_FEEDER_SYSTEM, 
	       NULL,  --CP_PAYABLES_UNITS, 
	       NULL,  --CP_PAYABLES_COST,
	       NULL,  --CP_PAN,
	       NULL,  --CP_PAYABLES_ACCOUNT,
	       cur.cost,
	       sysdate,
	       NULL,
	       cur.compl_period,
	       NULL,  --v_amort_sdate,
	       cur.deprn_amount,                                
	       cur.ytd_deprn,                                
	       cur.deprn_reserve,
	       cur.nbv,
	       NULL --v_gl_period   
	    );

     EXCEPTION
       WHEN others THEN
         NULL;
     END;

  END LOOP;
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Completion of Main Cursor :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

  j:=0;

  FOR cur IN C2 LOOP

     j:=j+1;

     UPDATE xx_fa_asset_addrpt_gt
        SET cp_feeder_system=cur.feeder_system_name,
	    cp_payables_units=cur.payables_units,
	    cp_payables_cost=cur.payables_cost,
	    request_id=cur.asset_invoice_id
      WHERE rowid=cur.drowid;

     IF j>10000 THEN
	COMMIT;
        j:=0;
     END IF;
     
  END LOOP;
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Completion of Feeder System Derivation :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

  j:=0;
  FOR cur IN C3 LOOP

    j:=j+1;

     UPDATE xx_fa_asset_addrpt_gt
        SET cp_pan=cur.pan
      WHERE rowid=cur.drowid;

     IF j>10000 THEN
	COMMIT;
        j:=0;
     END IF;     


  END LOOP;
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Completion of PAN Derivation :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

  j:=0;
  FOR cur IN C4 LOOP

    j:=j+1;

     UPDATE xx_fa_asset_addrpt_gt
        SET cp_payables_account=cur.payables_acct
      WHERE rowid=cur.drowid;

     IF j>10000 THEN
	COMMIT;
        j:=0;
     END IF;     


  END LOOP;
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Completion of Payables Account Derivation :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

  j:=0;
  FOR cur IN C5 LOOP

    j:=j+1;

     UPDATE xx_fa_asset_addrpt_gt
        SET period_name=cur.fa_period,
	    gl_period=cur.gl_period
      WHERE rowid=cur.drowid;

     IF j>10000 THEN
	COMMIT;
        j:=0;
     END IF;     


  END LOOP;
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Completion of GL and FA Period Derivation :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

  j:=0;
  FOR cur IN C6 LOOP

    j:=j+1;

     UPDATE xx_fa_asset_addrpt_gt
        SET cp_amortized_date=cur.amort_sdate
      WHERE rowid=cur.drowid;

     IF j>10000 THEN
	COMMIT;
        j:=0;
     END IF;     


  END LOOP;
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Completion of Amortization Start Date Derivation :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Beginning of fnd_file output :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

  FOR cur IN C7 LOOP

    BEGIN

     v_cnt:=v_cnt+1;

     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, v_cnt||'^'||
                                        cur.CP_PAN||'^'||
                                        cur.period_name||'^'||
                                        cur.book_type_code||'^'||
                                        cur.asset_id||'^'||
                                        cur.description||'^'||
                                        cur.asset_type||'^'||
                                        cur.company||'^'||
                                        cur.location||'^'||
                                        cur.costcenter||'^'||
                                        cur.lob||'^'||
                                        cur.Major||'^'||
                                        cur.Minor||'^'||
                                        cur.Subminor||'^'||
                                        cur.deprn_method_code||'^'||
                                        cur.asset_category||'^'||
                                        cur.depreciate_flag||'^'||
                                        cur.CP_FEEDER_SYSTEM||'^'||
                                        cur.new_used||'^'||
                                        cur.legacy_asset_no||'^'||
                                        cur.historical_cost||'^'||
                                        cur.legacy_dpis||'^'||
                                        cur.tax_asset_id||'^'||
                                        cur.vendor_name||'^'||
                                        replace(cur.invoice_no,'^','')||'^'||
                                        cur.serial_number||'^'||
                                        TO_CHAR(cur.cp_amortized_date, 'DD-MON-RR')||'^'||
                                        cur.Amortized_Flag||'^'||
                                        cur.asset_units||'^'||
                                        cur.prorate_convention_code||'^'||
                                        cur.CP_PAYABLES_UNITS||'^'||
                                        cur.CP_PAYABLES_COST||'^'||
                                        cur.CP_PAYABLES_ACCOUNT||'^'||
                                        cur.account||'^'||
                                        cur.life_in_months||'^'||
                                        TO_CHAR(cur.date_placed_in_service, 'DD-MON-RR')||'^'||
                                        cur.cp_complete_period||'^'||
                                        cur.gl_period||'^'||
                                        round(cur.cost, 2)||'^'||
                                        round(cur.deprn_amount, 2)||'^'||
                                        round(cur.ytd_deprn, 2)||'^'||
                                        round(cur.deprn_reserve,2)||'^'||                                  
                                        round(cur.nbv, 2)||'^');
    EXCEPTION
      WHEN others THEN
	NULL;
    END;

  END LOOP;

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Completion of fnd_file output :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total :'||TO_CHAR(v_cnt)||': Asset Register Records ');
  FA_REGISTER_FTP;
END process_asset_register;
End XX_FA_ASSET_REGRPT_PKG;
/
SHOW ERRORS;