create or replace
PACKAGE BODY XXOD_TRADE_PAYMENT_PKG AS
-- +==================================================================================================+
-- |                  Office Depot - Project Simplify                                                 |
-- |                  IT Convergence/Wirpo?Office Depot                                               |
-- +==================================================================================================+
-- | Name             :  XXOD_TRADE_PAYMENT_PKG                                                       |
-- | Description      :  This Package is used by to Extract Vendor , Invoice and Journal Information  |
-- |                                                                                                  |
-- |Change Record:                                                                                    |
-- |===============                                                                                   |
-- |Version   Date        	Author           	Remarks                                               |
-- |=======   ==========  	=============    =======================================================|
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	Initial draft version                                       |
-- |DRAFT 1.1 02-May-2008  Ganeshan J V   Modified the procedure generate_file for defect# 6527       |
-- |                                      and also replaced gl_code_combinations_kfv with             |
-- |                                      gl_code_combinations                                        |
-- |1.0       19-Sep-08    Sudha Seetharaman Modified for the defect# 11309                           |
-- |1.1       09-Dec-08    Agnes Poornima M       Code changes for defect 12418                       |
-- |1.2       11-Feb-09    Agnes Poornima M       Code changes for defect 13088                       |
-- |1.3       13-Feb-09    Manovinayak Ayyappan   Changes for the defect#13336 from Jan to Feb        |
-- |1.4       20-MAR-09	   Manovinayak Ayyappan   Code chnages for defect 12418                       |
-- |1.5       21-MAY-09	   Srinidhi               Code changes for defect 15076
-- |1.6       10-NOV-09    Lenny Lee              Code change for defect 3124                         | 
-- |1.7       01-AUG-13    Veronica Mairembam     R0461 Modified for R12 Upgrade Retrofit             | 
-- +==================================================================================================+
gc_file_path VARCHAR2(500)  := 'XXFIN_OUTBOUND';                                         --Added by Sudha for defect# 11309
PROCEDURE write_log(p_debug_flag VARCHAR2,
				      p_msg VARCHAR2)
-- +==================================================================================================+
-- |                  Office Depot - Project Simplify                                                 |
-- |                  IT Convergence/Wirpo?Office Depot                                               |
-- +==================================================================================================+
-- | Name             :  write_log				                                                |
-- | Description      :  This procedure is used to write in to log file based on the debug flag       |
-- |                                                                                                  |
-- |Change Record:                                                                                    |
-- |===============                                                                                   |
-- |Version   Date        	Author           	Remarks                                               |
-- |=======   ==========  	=============    =======================================================|
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	Initial draft version                                       |
-- +==================================================================================================+
AS
BEGIN
	IF(p_debug_flag = 'Y') Then
		fnd_file.put_line(FND_FILE.LOG,p_msg);
	END IF;
END;
PROCEDURE generate_file(p_directory VARCHAR2
					    ,p_file_name VARCHAR2
					    ,p_request_id NUMBER)
-- +==================================================================================================+
-- |                  Office Depot - Project Simplify                                                 |
-- |                  IT Convergence/Wirpo?Office Depot                                               |
-- +==================================================================================================+
-- | Name             :  generate_file			                                                |
-- | Description      :  This procedure is used to generate a output extract file and it calls XPTR   |
-- |                                                                                                  |
-- |Change Record:                                                                                    |
-- |===============                                                                                   |
-- |Version   Date        	Author           	Remarks                                               |
-- |=======   ==========  	=============    =======================================================|
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	     Initial draft version                                  |
-- |DRAFT 1.1 02-May-2008  Ganeshan J V        Modified the package to call XXCOMFILCOPYREP           |
-- |                                           instead of XXCOMFILCOPY for defect# 6527               |
-- |1.0       19-Sep-08    Sudha Seetharaman   Modified for the defect# 11309                         |
-- +==================================================================================================+
AS
	ln_req_id 		NUMBER;
   lc_source_dir_path    VARCHAR2(4000);
BEGIN
	BEGIN                                        --Added by Sudha for defect# 11309 #Starts#
           SELECT directory_path
           INTO lc_source_dir_path
           FROM   dba_directories
           WHERE  directory_name = gc_file_path;
        EXCEPTION
        WHEN OTHERS THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting directory path '|| SQLERRM);
        END;                                    --Added by Sudha for defect# 11309 #Ends#
        ln_req_id := FND_REQUEST.SUBMIT_REQUEST('XXFIN'        --Added by Sudha for defect# 11309, Modified soruce path
									,'XXCOMFILCOPYREP'
									,''
									,''
									,FALSE
									,lc_source_dir_path||'/'||p_request_id||'.out'
								        ,p_directory||'/'||p_file_name
									,'','','','',p_request_id,'','','','','','','','','','',''
									,'','','','','','','','','','','','','','','','','','','','','',''
									,'','','','','','','','','','','','','','','','','','','','','',''
									,'','','','','','','','','','','','','','','','','','','','','',''
									,'','','','','','','','','','','','','','','','') ;
END;
FUNCTION Get_Legacy_Value(p_translate_id		NUMBER
					         ,p_target_value      VARCHAR2
					        )
-- +==================================================================================================+
-- |                  Office Depot - Project Simplify                                                 |
-- |                  IT Convergence/Wirpo?Office Depot                                               |
-- +==================================================================================================+
-- | Name             :  Get_Legacy_Value				                                          |
-- | Description      :  This function is used to get the legacy value from the translations table    |
-- |                                                                                                  |
-- |Change Record:                                                                                    |
-- |===============                                                                                   |
-- |Version   Date        	Author           	Remarks                                               |
-- |=======   ==========  	=============    =======================================================|
-- |DRAFT 1.0 11-Oct-2007     Senthil Kumar 	Initial draft version                                 |
-- +==================================================================================================+
RETURN VARCHAR2
AS
	l_source_value	xx_fin_translatevalues.source_value1%TYPE;
BEGIN
	BEGIN
		SELECT rpad(source_value1,5)
		INTO l_source_value
		FROM xx_fin_translatevalues xft
		WHERE xft.translate_id=p_translate_id
		AND target_value1=p_target_value;
		RETURN l_source_value;
	EXCEPTION
		WHEN OTHERS THEN
			l_source_value:='     ';
			RETURN l_source_value;
	END;
END;
PROCEDURE Extract_Vendor(p_ret_code OUT NUMBER
					     ,p_err_msg OUT VARCHAR2
					     ,p_directory VARCHAR2
					     ,p_file_name VARCHAR2
					     ,p_debug_flag VARCHAR2
                    ,p_file_path  VARCHAR2
					      )
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  IT Convergence/Wirpo?Office Depot                             |
-- +================================================================================+
-- | Name             :    Extract_Vendor 				                  |
-- | Description      :  This procedure is used to extract the vendor information   |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        	Author           	   Remarks                          |
-- |=======   ==========  	=============       ==================================|
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	        Initial draft version             |
-- |1.0       19-Sep-08    Sudha Seetharaman      Modified for the defect# 11309    |
-- |1.1       28-05-09     Ranjith Reddy Jitta    Modified for defect# 15076        |
-- |1.2       01-Aug-13    Veronica Mairembam     Modified for R12 Upgrade Retrofit |
-- +================================================================================+
AS
	l_data		VARCHAR2(4000);
   	ln_buffer                                          BINARY_INTEGER  := 32767;   --Added by Sudha for defect# 11309
        lt_file                                            utl_file.file_type;       --Added by Sudha for defect# 11309
        lc_filename  VARCHAR2(4000);                                                 --Added by Sudha for defect# 11309
        ln_req_id NUMBER;                                                            --Added by Sudha for defect# 11309
BEGIN
   gc_file_path := p_file_path; -- Added by Ganesan for Defect 11770
	write_log(p_debug_flag,'Extracting the Vendor');                                  --Added by Sudha for defect# 11309
	ln_req_id:= fnd_profile.value('CONC_REQUEST_ID');
        --lc_filename:='TRADE_PAYMENT_'||ln_req_id;
	lc_filename:= ln_req_id||'.out';
   lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
   FOR Vendor_Cur in
		(SELECT
			lpad(PVSA.org_id,15,'0') org_id
			,rpad(nvl(PVSA.attribute8,' '),25) attribute8
			,rpad(nvl(PVSA.attribute9,' '),25) legacy_vendor_id
			,lpad(PV.vendor_id,15,'0') oracle_vendor_id
			,lpad(PVSA.vendor_site_id,15,'0') vendor_site_id
			,rpad(PVSA.vendor_site_code,15) vendor_site_code
			,rpad(nvl(PV.vendor_name,' '),50) vendor_name
                  ,rpad(nvl(substr(PV.segment1,1,15),' '),15)   vendor_number            --Added by Ranjith for defect# 15076
		FROM
			 --po_vendors PV
			 ap_suppliers PV
			--,po_vendor_sites_all PVSA
			,ap_supplier_sites_all PVSA                                  --Added/Commented for R12 Upgrade Retrofit by Veronica on 01-Aug-13
		WHERE PV.vendor_id=PVSA.vendor_id
            AND PVSA.pay_site_flag = 'Y'                                                --Added by Ranjith for defect# 15076
            AND PVSA.vendor_site_code Like 'T%'           --Added by Ranjith for defect# 15076
		ORDER BY PV.vendor_name
		)
	LOOP
		--write_log(p_debug_flag,'Extracting the Vendor Details for Vendor Name :'||Vendor_cur.vendor_name);
		l_data:=Vendor_Cur.org_id||vendor_cur.attribute8||vendor_cur.legacy_vendor_id||vendor_cur.oracle_vendor_id
					||vendor_cur.vendor_site_id||vendor_cur.vendor_site_code||vendor_cur.vendor_name||vendor_cur.vendor_number||chr(13);
	--	FND_FILE.put_line(FND_FILE.OUTPUT,l_data);                                                           Commented by Sudha for defect# 11309
	        UTL_FILE.PUT_LINE(lt_file,l_data);                                                              --Added by Sudha for defect# 11309
   END LOOP;
   UTL_FILE.fclose(lt_file);                                                                          --Added by Sudha for defect# 11309
	write_log(p_debug_flag,'Calling XPTR Program');
   generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
END Extract_Vendor;
PROCEDURE Extract_Journal(p_ret_code OUT NUMBER
					     ,p_err_msg OUT VARCHAR2
					     ,p_directory VARCHAR2
					     ,p_file_name VARCHAR2
					     ,p_debug_flag VARCHAR2
                    ,p_file_path VARCHAR2
                    ,p_period_name VARCHAR2
					      )
-- +===================================================================================================+
-- |                  Office Depot - Project Simplify                                                  |
-- |                  IT Convergence/Wirpo?Office Depot                                                |
-- +===================================================================================================+
-- | Name             :  Extract_Journal 											                               |
-- | Description      : This procedure is used to extract the journal details for the first open period|
-- |                                                                                                   |
-- |Change Record:                                                                                     |
-- |===============                                                                                    |
-- |Version   Date        	Author           	Remarks                                                   |
-- |=======   ==========  	=============    ===========================================================|
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	Initial draft version                                        |
-- |DRAFT 1.1 02-May-2008  Ganeshan J V	Replaced gl_code_combinations_kfv with gl_code_combinations  |
-- |1.0       19-Sep-08    Sudha Seetharaman Modified for the defect# 11309                            |
-- |1.1       09-Dec-08    Agnes Poornima M       Code changes for defect 12418                        |
-- |1.2       11-Feb-09    Agnes Poornima M       Code changes for defect 13088                        |
-- |1.3       20-MAR-09	   Manovinayak Ayyappan   Code chnages for defect 12418                        |
-- |1.6       10-NOV-09    Lenny Lee              Code change for defect 3124
-- +===================================================================================================+
AS
	l_data			VARCHAR2(4000);
	l_period_name	VARCHAR2(30);
   	ln_buffer                                          BINARY_INTEGER  := 32767;   --Added by Sudha for defect# 11309
        lt_file                                            utl_file.file_type;       --Added by Sudha for defect# 11309
        lc_filename  VARCHAR2(4000);                                                 --Added by Sudha for defect# 11309
        ln_req_id NUMBER;                                                            --Added by Sudha for defect# 11309
        lc_total_lines NUMBER := 0;                                                  --Added by Lenny for defect# 3124 
        lc_total_usa   NUMBER := 0;                                                  --Added by Lenny for defect# 3124 
        lc_total_can   NUMBER := 0;                                                  --Added by Lenny for defect# 3124 
BEGIN
   gc_file_path := p_file_path; -- Added by Ganesan for Defect 11770
	write_log(p_debug_flag,'Extracting the Journal Details');
        ln_req_id:= fnd_profile.value('CONC_REQUEST_ID');                            --Added by Sudha for defect# 11309
        lc_filename:= ln_req_id||'.out';                                             --Added by Sudha for defect# 11309
         lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
         l_period_name:=p_period_name;--Added by Sudha for defect# 11309
     /*
  --  Commented the code for defect 12418
		SELECT period_name
		INTO l_period_name
		FROM GL_PERIOD_STATUSES
		WHERE CLOSING_STATUS='C'
		AND APPLICATION_ID=101
		AND SET_OF_BOOKS_ID=FND_PROFILE.value('GL_SET_OF_BKS_ID')
		AND EFFECTIVE_PERIOD_NUM =
			(SELECT MAX(EFFECTIVE_PERIOD_NUM)
			  FROM GL_PERIOD_STATUSES
			  WHERE CLOSING_STATUS='C'
			  AND APPLICATION_ID=101 AND
			  SET_OF_BOOKS_ID=FND_PROFILE.value('GL_SET_OF_BKS_ID'));*/

   --Added by Manovinayak for the defect#12418
IF p_period_name IS NULL THEN
         BEGIN
		SELECT period_name
		INTO l_period_name
		FROM GL_PERIOD_STATUSES
		WHERE CLOSING_STATUS='O'
		AND APPLICATION_ID=101
		-- AND SET_OF_BOOKS_ID=FND_PROFILE.value('GL_SET_OF_BKS_ID') -- defect 3124
    AND EFFECTIVE_PERIOD_NUM =
			(SELECT MIN(EFFECTIVE_PERIOD_NUM)
			  FROM GL_PERIOD_STATUSES
			  WHERE CLOSING_STATUS='O'
			  AND APPLICATION_ID=101); 
      --  AND SET_OF_BOOKS_ID=FND_PROFILE.value('GL_SET_OF_BKS_ID'));  -- defect 3124
          	EXCEPTION
		WHEN OTHERS THEN
			l_period_name:=NULL;
			fnd_file.put_line(FND_FILE.LOG,'unable to fetch the minimum open period from GL ');
	END;
ELSE
 l_period_name := P_period_name;
 
 END IF;



	IF l_period_name IS NOT NULL THEN
		FOR Journal_Cur IN
				(SELECT
			 lpad(GJH.je_header_id,15,0) je_header_id
			--,lpad(GJH.set_of_books_id,15,0) set_of_books_id
			,lpad(GJH.ledger_id,15,0) set_of_books_id        --Commented/Added by Veronica on 01-Aug-13 for R12 Upgrade Retrofit 
			,lpad(GJH.je_batch_id,15,0) je_batch_id
			,rpad(to_char(to_date(GJH.period_name,'MON-YY'),'YYYYMM'),15) period_name
			,rpad(nvl(GJH.description,' '),50) description
			,decode(GJH.posted_date,NULL,'          ',rpad(to_char(GJH.posted_date,'YYYY-MM-DD'),10)) posted_date
			--,rpad(nvl(GJH.je_source,' '),25) je_source -- Added for defect # 12418
			--,rpad(nvl(GJH.je_category,' '),25) je_category -- Added for defect # 12418
			,rpad(nvl(GJS.user_je_source_name,' '),25) je_source -- Added for defect # 12418
			,rpad(nvl(GJC.user_je_category_name,' '),25) je_category  -- Added for defect # 12418
			,rpad(nvl(GJH.actual_flag,' '),1) actual_flag
			,rpad(nvl(GJH.currency_code,' '),15) currency_code
			,rpad(nvl(GJH.status,' '),1) status
			,decode(GJH.date_created,NULL,'          ',rpad(to_char(GJH.date_created,'YYYY-MM-DD'),10)) date_created
			,lpad(nvl(GJL.je_line_num,0),15,0) je_line_num
			,rpad(nvl(GJL.status,' '),1) line_status
			,rpad(nvl(GCC.SEGMENT1 || '.' || GCC.SEGMENT2 || '.' || GCC.SEGMENT3 || '.' || GCC.SEGMENT4 || '.' || GCC.SEGMENT5 || '.' || GCC.SEGMENT6 || '.' || GCC.SEGMENT7,' '),50) gl_accounting_string
			,DECODE(get_legacy_value(142,GCC.segment1),NULL,'     ',
				rpad(get_legacy_value(142,GCC.segment1),5)) legacy_gl_bus_unit
			,DECODE(get_legacy_value(145,GCC.segment4),NULL,'     ',
				rpad(get_legacy_value(145,GCC.segment4),5)) legacy_gl_oper_unit
			,rpad(nvl(GCC.segment3,' '),10) oracle_gl_account
			,rpad(nvl(GJL.description,' '),50) line_description
			,DECODE(sign(NVL(GJL.accounted_dr,0)),1,'+'||TRIM(TO_CHAR(GJL.accounted_dr,'0999999999999.99')),
				0,'+'||TRIM(TO_CHAR(NVL(GJL.accounted_dr,0),'0999999999999.99')),
				TRIM(TO_CHAR(NVL(GJL.accounted_dr,0),'0999999999999.99'))) accounted_dr
			,DECODE(sign(NVL(GJL.accounted_cr,0)),1,'+'||TRIM(TO_CHAR(GJL.accounted_cr,'0999999999999.99')),
				0,'+'||TRIM(TO_CHAR(NVL(GJL.accounted_cr,0),'0999999999999.99')),
				TRIM(TO_CHAR(NVL(GJL.accounted_cr,0),'0999999999999.99'))) accounted_cr
		FROM
			 gl_je_headers GJH
			,gl_je_lines GJL
			,gl_code_combinations GCC
			,gl_je_sources  GJS  -- Added for defect # 12418
			,gl_je_categories GJC -- Added for defect # 12418
		WHERE
			GJH.je_header_id=GJL.je_header_id
			AND GJL.code_combination_id=GCC.code_combination_id
		--	AND GJH.set_of_books_id=fnd_profile.value('GL_SET_OF_BKS_ID')  defect 3124
			AND GJH.period_name=l_period_name
			AND GJH.status='P' --Added by Sudha for defect# 11309
			AND GJH.je_source = GJS.je_source_name -- Added for defect # 12418
			AND  GJH.je_category = GJC.je_category_name -- Added for defect # 12418
			AND  SUBSTR(GCC.segment3,1,1) IN ('1','2','5') -- Added by Agnes for defect 13088 on 11th Feb
		ORDER BY GJH.je_header_id
		)
		LOOP
			--write_log(p_debug_flag,' Extract Journal Details for Journal :'||journal_cur.je_header_id);  Commented by Sudha for defect# 11309
			l_data:=Journal_Cur.je_header_id||Journal_Cur.set_of_books_id||Journal_Cur.je_batch_id||Journal_Cur.Period_Name
				||Journal_Cur.Description||Journal_Cur.Posted_Date||Journal_Cur.Je_Source||Journal_Cur.Je_Category
				||Journal_Cur.actual_flag||Journal_Cur.Currency_Code||Journal_Cur.status||Journal_Cur.date_created
				||Journal_Cur.set_of_books_id||Journal_Cur.je_header_id||Journal_Cur.je_line_num
				||Journal_Cur.status||Journal_Cur.gl_accounting_string||Journal_Cur.legacy_gl_bus_unit
				||Journal_Cur.legacy_gl_oper_unit||Journal_Cur.oracle_gl_account||Journal_Cur.description
				||Journal_Cur.accounted_dr||Journal_Cur.accounted_cr||chr(13);
			--fnd_file.put_line(FND_FILE.OUTPUT,l_data);                                       Commented by Sudha for defect# 11309
         UTL_FILE.PUT_LINE(lt_file,l_data);                                  --Added by Sudha for defect# 11309
         lc_total_lines := lc_total_lines + 1;                                --Added by Lenny for Defect# 3124
         IF Journal_Cur.set_of_books_id = '000000000006003'  THEN
              lc_total_usa := lc_total_usa + 1;                           --Added by Lenny for Defect# 3124
         ELSE
              lc_total_can := lc_total_can + 1;                                --Added by Lenny for Defect# 3124
         END IF;
        
		END LOOP;
      UTL_FILE.fclose(lt_file);                                                    --Added by Sudha for defect# 11309
		  write_log(p_debug_flag,'Calling XPTR Program');
      generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
      write_log(p_debug_flag,'Journal extract has been completed');
      write_log(p_debug_flag,'Period Name:' || ' ' || l_period_name);            --Added by Lenny for Defect# 3124 
      write_log(p_debug_flag,'Total Journal USA  :' || ' ' || lc_total_usa);   --Added by Lenny for Defect# 3124
      write_log(p_debug_flag,'Total Journal CAN  :' || ' ' || lc_total_can);   --Added by Lenny for Defect# 3124
      write_log(p_debug_flag,'Total Journal lines:' || ' ' || lc_total_lines);   --Added by Lenny for Defect# 3124 
   END IF;
END Extract_Journal;
PROCEDURE Extract_Invoices(p_ret_code OUT NUMBER
					     ,p_err_msg OUT VARCHAR2
					     ,p_directory VARCHAR2
					     ,p_file_name VARCHAR2
					     ,p_debug_flag VARCHAR2
                    ,p_file_path  VARCHAR2
                    ,p_period_name VARCHAR2
					      )
-- +==================================================================================================+
-- |                  Office Depot - Project Simplify                                                 |
-- |                  IT Convergence/Wirpo?Office Depot                                               |
-- +==================================================================================================+
-- | Name             :  extract_invoices			                                                        |
-- | Description      :  This procedure is used to extract the invoices information based on 		      |
-- |                     last closed period           										                            |
-- |                                                                                                  |
-- |Change Record:                                                                                    |
-- |===============                                                                                   |
-- |Version   Date        	Author           	Remarks                                                 |
-- |=======   ==========  	=============    ========================================================= |
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	Initial draft version                                       |
-- |DRAFT 1.1 02-May-2008  Ganeshan J V   Replaced gl_code_combinations_kfv with gl_code_combinations |
-- |1.0       19-Sep-08    Sudha Seetharaman Modified for the defect# 11309                           |
-- |1.2       11-Feb-09    Agnes Poornima M       Code changes for defect 13088
-- |1.3       20-Mar-09    Mano Vinayak           Added period_name parameter                         |
-- |1.4       01-Aug-13    Veronica Mairembam    Modified for R12 Upgrade Retrofit                    |
-- +==================================================================================================+
AS
	l_data			VARCHAR2(4000);
	l_period_name	VARCHAR2(30);
   ln_buffer                                          BINARY_INTEGER  := 32767;   --Added by Sudha for defect# 11309
   lt_file                                            utl_file.file_type;          --Added by Sudha for defect# 11309
   lc_filename  VARCHAR2(4000);                                                    --Added by Sudha for defect# 11309
   ln_req_id NUMBER;                                                               --Added by Sudha for defect# 11309
   lc_total_lines NUMBER :=0;                                                      --Added by Lenny for Defect# 3124
BEGIN
   gc_file_path := p_file_path; -- Added by Ganesan for Defect 11770
	write_log(p_debug_flag,'Extracting the Invoice Details');
	ln_req_id:= fnd_profile.value('CONC_REQUEST_ID');                       --Added by Sudha for defect# 11309
   lc_filename:= ln_req_id||'.out';                                        --Added by Sudha for defect# 11309
   lt_file  := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
   l_period_name:=p_period_name;--Added by Sudha for defect# 11309
BEGIN
	IF p_period_name IS NULL THEN
		SELECT period_name
		INTO l_period_name
		FROM GL_PERIOD_STATUSES
		WHERE CLOSING_STATUS='C'
		AND APPLICATION_ID=200 -- Changed application id from 101 to 200 for Defect#14764
		AND SET_OF_BOOKS_ID=FND_PROFILE.value('GL_SET_OF_BKS_ID')
		AND EFFECTIVE_PERIOD_NUM =
			(SELECT MAX(EFFECTIVE_PERIOD_NUM)
			  FROM GL_PERIOD_STATUSES
			  WHERE CLOSING_STATUS='C'
			  AND APPLICATION_ID=200 -- Changed application id from 101 to 200 for Defect#14764
                    AND SET_OF_BOOKS_ID=FND_PROFILE.value('GL_SET_OF_BKS_ID'));
	ELSE
		l_period_name := p_period_name;
	END IF;
EXCEPTION
		WHEN OTHERS THEN
			l_period_name:=NULL;
			fnd_file.put_line(FND_FILE.LOG,'No Periods are closed . Please close period and run the Extract');
 END;
	IF L_period_name IS NOT NULL THEN
		FOR Invoice_Cur IN
		(SELECT
			 lpad(nvl(AIA.org_id,0),15,0) org_id
			,rpad(nvl(PVSA.attribute8,' '),25) attribute8
			,rpad(nvl(PVSA.attribute9,' '),25) legacy_vendor_id
			--,lpad(nvl(AIA.vendor_id,0),15,0) vendor_id                 --Commented by Sudha for defect# 11309
			,rpad(nvl(substr(pv.segment1,1,15),' '),15) vendor_number         --Added by Sudha for defect# 11309
			,lpad(nvl(PVSA.vendor_site_id,0),15,0) vendor_site_id
			,rpad(nvl(PVSA.vendor_site_code,' '),15) vendor_site_code
		--	,rpad(nvl(PV.segment1,' '),50) vendor_name                   --Commented by Sudha for defect# 11309
		        ,rpad(nvl(pv.vendor_name,' '),50) vendor_name        --Added by Sudha for defect# 11309
			,lpad(nvl(AIA.batch_id,0),15,0) batch_id
			,lpad(nvl(AIA.invoice_id,0),15,0) invoice_id
			,lpad(nvl(AIA.set_of_books_id,0),15,0) set_of_books_id
			,rpad(nvl(voucher_num,' '),25) voucher_num
			,rpad(nvl(GCC.SEGMENT1 || '.' || GCC.SEGMENT2 || '.' || GCC.SEGMENT3 || '.' || GCC.SEGMENT4 || '.' || GCC.SEGMENT5 || '.' || GCC.SEGMENT6 || '.' || GCC.SEGMENT7,' '),50) gl_accounting_string
			,DECODE(get_legacy_value(142,GCC.segment1),NULL,'     ',
				rpad(get_legacy_value(142,GCC.segment1),5)) legacy_gl_bus_unit
			,DECODE(get_legacy_value(145,GCC.segment4),NULL,'     ',
				rpad(get_legacy_value(145,GCC.segment4),5)) legacy_gl_oper_unit
			,rpad(nvl(GCC.segment3,' '),10) oracle_gl_account
			,decode(AIA.invoice_date,null,'        ',to_char(AIA.invoice_date,'YYYYMMDD')) invoice_date
			,rpad(nvl(AIA.invoice_num,' '),50) invoice_num
			,decode(AIA.creation_date,null,'        ',to_char(AIA.creation_date,'YYYYMMDD')) creation_date
			,DECODE(sign(NVL(AIA.invoice_amount,0)),1,'+'||TRIM(TO_CHAR(AIA.invoice_amount,'0999999999999.99')),
				0,'+'||TRIM(TO_CHAR(NVL(AIA.invoice_amount,0),'0999999999999.99')),
				TRIM(TO_CHAR(NVL(AIA.invoice_amount,0),'0999999999999.99'))) invoice_amt
			,rpad(nvl(AIA.description,' '),50) description
			,rpad(nvl(AIA.attribute13,' '),1) voucher_type
			,rpad(nvl(AIA.invoice_currency_code,' '),15) invoice_currency_code
			,rpad(nvl(AIA.source,' '),25) source
			,rpad(nvl(AIDA.posted_flag,' '),1) posting_flag
			,lpad(nvl(AIDA.invoice_id,0),15,0) invoice_id_dist
			,lpad(nvl(AIDA.distribution_line_number,0),15,0) distribution_line_number
			,lpad(nvl(AIDA.set_of_books_id,0),15,0) set_of_books_id_dist
			,rpad(nvl(GCC.SEGMENT1 || '.' || GCC.SEGMENT2 || '.' || GCC.SEGMENT3 || '.' || GCC.SEGMENT4 || '.' || GCC.SEGMENT5 || '.' || GCC.SEGMENT6 || '.' || GCC.SEGMENT7,' '),50) gl_accounting_string_dist
			,DECODE(get_legacy_value(142,GCC.segment1),NULL,'     ',
				rpad(get_legacy_value(142,GCC.segment1),5)) legacy_gl_bus_unit_dist
			,DECODE(get_legacy_value(145,GCC.segment4),NULL,'     ',
				rpad(get_legacy_value(145,GCC.segment4),5)) legacy_gl_oper_unit_dist
			,rpad(nvl(GCC.segment3,' '),10) oracle_gl_account_dist
			,lpad(nvl(AIDA.je_batch_id,0),15,0) je_batch_id
			,decode(to_char(AIDA.accounting_date,'YYYYMMDD'),null,'        ',
				to_char(AIDA.accounting_date,'YYYYMMDD')) accounting_date
			,rpad(nvl(AIDA.posted_flag,' '),1) posted_flag
			,DECODE(sign(NVL(AIDA.amount,0)),1,'+'||TRIM(TO_CHAR(AIDA.amount,'0999999999999.99')),
				0,'+'||TRIM(TO_CHAR(NVL(AIDA.amount,0),'0999999999999.99')),
				TRIM(TO_CHAR(NVL(AIDA.amount,0),'0999999999999.99'))) invoice_amt_dist
			,decode(to_char(AIDA.creation_date,'YYYYMMDD'),null,'        ',
				to_char(AIDA.creation_date,'YYYYMMDD')) creation_date_dist
			,rpad(nvl(AIDA.description,' '),50) description_dist
			,lpad(nvl(AIDA.org_id,0),15,0) org_id_dist
			,rpad(nvl(AIDA.attribute11,' '),25) attribute11
			,rpad(nvl(AIDA.attribute7,' '),25) attribute7
			,lpad(nvl(AIDA.batch_id,0),15,0) batch_id_dist
		FROM
			 ap_invoices_all AIA
			,ap_invoice_distributions_all AIDA
			,gl_code_combinations GCC
			--,po_vendors PV
			,ap_suppliers PV 
			--,po_vendor_sites_all PVSA 
			,ap_supplier_sites_all PVSA                    --Added/Commented for R12 Upgrade Retrofit by Veronica on 01-Aug-13
		WHERE
			AIA.invoice_id=AIDA.invoice_id
			AND AIA.vendor_id=PV.vendor_id
			AND AIDA.dist_code_combination_id=GCC.code_combination_id
			AND AIDA.period_name=l_period_name
			AND PV.vendor_id=PVSA.vendor_id
			AND AIA.vendor_site_id =PVSA.vendor_site_id -- Added by Viswa for defect#11309 on 25-Sep-08
			AND aida.posted_flag= 'Y'  --Added by Sudha for defect# 11309
--			AND PVSA.purchasing_site_flag = 'Y' -- Added by Viswa for defect#11309 on 25-Sep-08
			AND PVSA.pay_site_flag = 'Y' -- Added by Srinidhi for defect#15076 on 21-May-09
			AND  SUBSTR(GCC.segment3,1,1) IN ('1','2','5')  -- Added by Agnes for defect 13088 on 11th Feb
		)
		LOOP
			--write_log(p_debug_flag,' Extract Invoice Details for Invoice :'||invoice_cur.invoice_id);
			l_data:=invoice_cur.org_id||invoice_cur.attribute8||invoice_cur.legacy_vendor_id
					||invoice_cur.vendor_number||invoice_cur.vendor_site_id||invoice_cur.vendor_site_code
					||invoice_cur.vendor_name||invoice_cur.batch_id||invoice_cur.invoice_id
					||invoice_cur.set_of_books_id||invoice_cur.voucher_num||invoice_cur.gl_accounting_string
					||invoice_cur.legacy_gl_bus_unit||invoice_cur.legacy_gl_oper_unit||invoice_cur.oracle_gl_account
					||invoice_cur.invoice_date||invoice_cur.invoice_num||invoice_cur.creation_date
					||invoice_cur.invoice_amt||invoice_cur.description||invoice_cur.voucher_type
					||invoice_cur.invoice_currency_code||invoice_cur.source||invoice_cur.posting_flag
					||invoice_cur.invoice_id_dist||invoice_cur.distribution_line_number||invoice_cur.set_of_books_id_dist
					||invoice_cur.gl_accounting_string_dist||invoice_cur.legacy_gl_bus_unit_dist
					||invoice_cur.legacy_gl_oper_unit_dist||invoice_cur.oracle_gl_account_dist
					||invoice_cur.je_batch_id||invoice_cur.accounting_date||invoice_cur.posted_flag
					||invoice_cur.invoice_amt_dist||invoice_cur.creation_date_dist||invoice_cur.description_dist
					||invoice_cur.org_id_dist||invoice_cur.attribute11||invoice_cur.attribute7
					||invoice_cur.batch_id_dist||chr(13);
			--fnd_file.put_line(FND_FILE.OUTPUT,l_data);                                               Commented by Sudha for defect# 11309
         UTL_FILE.PUT_LINE(lt_file,l_data);                                         --Added by Sudha for defect# 11309
         lc_total_lines := lc_total_lines + 1;                                      --Added by Lenny for Defect# 3124
		END LOOP;
                 UTL_FILE.fclose(lt_file);
		write_log(p_debug_flag,'Calling XPTR Program');
		generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
      write_log(p_debug_flag,'Invoice extract has been completed');
      write_log(p_debug_flag,'Period Name:' || ' ' || l_period_name);      --Added by Lenny for Defect# 3124 
      write_log(p_debug_flag,'Total Invoice Lines:' || ' ' || lc_total_lines);      --Added by Lenny for Defect# 3124 
	END IF;
END Extract_Invoices;
END;

/
