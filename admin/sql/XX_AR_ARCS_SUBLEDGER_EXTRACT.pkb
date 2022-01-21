CREATE OR REPLACE 
PACKAGE BODY APPS.XX_AR_ARCS_SUBLEDGER_EXTRACT
-- +============================================================================================+
-- |  					Office Depot - Project Simplify                                         |
-- +============================================================================================+
-- |  Name	 	 	:  XX_AR_ARCS_SUBLEDGER_EXTRACT                                             |
-- |  Description	:  PLSQL Package to extract AR Subledger Accounting Information             |
-- |  Change Record	:                                                                           |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         012918       Dinesh Nagapuri  Initial version                                  |
-- +============================================================================================+
AS
-- +======================================================================+
-- | Name        :  invoice_vps_extract                                   |
-- | Description :  This procedure will be called from the concurrent prog|
-- |                "OD : AR ARCS Subledger Extract" to extract AR        |
-- |                Subledger Accounting Information    				  |
-- |                                                                      |
-- | Parameters  :  Period Name                                           |
-- |                                                                      |
-- | Returns     :  x_errbuf, x_retcode                                   |
-- |                                                                      |
-- +======================================================================+
	PROCEDURE subledger_arcs_extract( p_errbuf       OUT  VARCHAR2
                                    , p_retcode      OUT  VARCHAR2
                                    , p_period_name  IN   VARCHAR2
							 )
	AS
		CURSOR subledger_extract_cur(p_period_name VARCHAR2) 
		IS
		SELECT gcc.segment1 COMPANY,
      gcc.segment2 COST_CENTER,
      gcc.segment3 ACCOUNT,
      gcc.segment4 LOCATION,
      GCC.SEGMENT5 INTERCOMPANY,
      gcc.segment6 LINE_OF_BUSINESS,
      GCC.SEGMENT7 FUTURE,
      TO_CHAR(NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0) + SUM(NVL(xll.accounted_dr,0))- SUM(NVL(xll.accounted_cr,0)),'99999999999999.00') YTD_balance,
      TO_CHAR(NVL(GB.BEGIN_BALANCE_DR,0) - NVL(GB.BEGIN_BALANCE_CR,0)) YTD_BEGINNING_BAL,
      SUM(NVL(XLL.ACCOUNTED_DR,0)) YTD_NET_DR,
      SUM(NVL(XLL.ACCOUNTED_CR,0)) YTD_NET_CR,
      (SELECT fvv.description
        FROM FND_FLEX_VALUE_SETS fvs,
             FND_FLEX_VALUES_VL fvv
        WHERE FLEX_VALUE_SET_NAME = 'OD_GL_GLOBAL_ACCOUNT'
        AND FVS.FLEX_VALUE_SET_ID = FVV.FLEX_VALUE_SET_ID 
        AND fvv.FLEX_VALUE           =gcc.segment3
        ) "ACCOUNT_DESCRIPTION",
      xll.ledger_id,
      XLL.CURRENCY_CODE,
      gb.period_name,
      gcc.code_combination_id,
      gb.actual_flag Balance_Type, --
      GLD.NAME LEDGER_NAME,
      GLLookups.meaning ledger_type,
      glcd.object_name primary_ledger_name
    FROM XLA_AE_LINES XLL,
      GL_PERIODS GP,
      gl_code_combinations gcc,
      gl_ledgers gld,
      gl_balances gb,
      gl_ledger_config_details glcd,
      GL_LOOKUPS GLLookups
    WHERE 1                     =1
    AND gcc.code_combination_id = xll.code_combination_id
    AND XLL.LEDGER_ID           = GLD.LEDGER_ID
    AND GLD.CURRENCY_CODE       = XLL.CURRENCY_CODE
    AND TO_CHAR(XLL.ACCOUNTING_DATE,'YYYY') > = GB.PERIOD_YEAR
  --  AND XLL.ACCOUNTING_DATE    >= TO_DATE('01/01/2017','mm/dd/yyyy')
    AND XLL.ACCOUNTING_DATE    <= GP.END_DATE
    AND gcc.code_combination_id = gb.code_combination_id
    AND GB.ACTUAL_FLAG          = 'A'
    AND GB.PERIOD_NAME          = p_period_name --'JAN-18'
    AND GB.PERIOD_NAME          = GP.PERIOD_NAME
    AND gb.template_id            IS NULL
    AND gb.ledger_id            = gld.ledger_id
    AND gld.currency_code       = gb.currency_code
    AND gld.configuration_id    = glcd.configuration_id
    AND glcd.object_type_code   = 'PRIMARY'
    AND glcd.setup_step_code    = 'NONE'
    AND GLLookups.lookup_type   = 'GL_ASF_LEDGER_CATEGORY'
    AND GLLookups.lookup_code   = gld.ledger_category_code
    --AND gb.period_name         IN ('JAN-17','ENE-17') -- for beginning balance
    --AND GB.PERIOD_NAME = 'SEP-17'
    --AND GCC.CODE_COMBINATION_ID = 21833485
    AND xll.application_id      =222
    /*AND EXISTS
      (SELECT 1
      FROM FND_FLEX_VALUES_VL
      WHERE ((''                     IS NULL)
      OR (structured_hierarchy_level IN
        (SELECT HIERARCHY_ID
        FROM fnd_flex_hierarchies_vl h
        WHERE h.flex_value_set_id = 1010412
        AND h.hierarchy_name LIKE ''
        )))
      AND (FLEX_VALUE_SET_ID = 1010412)
      AND FLEX_VALUE         =gcc.segment4
      )
    --AND gcc.segment1  = '1001'
    --AND gcc.segment4 BETWEEN '12311' AND '12659'*/
    GROUP BY gcc.segment1 ,
      gcc.segment2 ,
      gcc.segment3 ,
      gcc.segment4 ,
      gcc.segment5 ,
      gcc.segment6 ,
      gcc.segment7 ,
      gcc.segment8 ,
      gcc.description,
      NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0),
      xll.ledger_id,
      xll.currency_code,
      gb.period_name,
      gcc.code_combination_id,
      gb.actual_flag,
      gld.name ,
      GLLOOKUPS.MEANING,
      GLCD.OBJECT_NAME  
      UNION ALL  
      SELECT GCC.SEGMENT1 COMPANY,
      gcc.segment2 COST_CENTER,
      gcc.segment3 ACCOUNT,
      gcc.segment4 LOCATION,
      GCC.SEGMENT5 INTERCOMPANY,
      gcc.segment6 "LINE OF BUSINESS",
      GCC.SEGMENT7 FUTURE,
      TO_CHAR(NVL(GB.BEGIN_BALANCE_DR,0) - NVL(GB.BEGIN_BALANCE_CR,0),'99999999999999.00') YTD_BALANCE,
      TO_CHAR(NVL(GB.BEGIN_BALANCE_DR,0) - NVL(GB.BEGIN_BALANCE_CR,0)) YTD_BEGINNING_BAL,
      0 YTD_NET_DR,
      0 YTD_NET_CR,
      (SELECT fvv.description
        FROM FND_FLEX_VALUE_SETS fvs,
             FND_FLEX_VALUES_VL fvv
        WHERE FLEX_VALUE_SET_NAME = 'OD_GL_GLOBAL_ACCOUNT'
        AND FVS.FLEX_VALUE_SET_ID = FVV.FLEX_VALUE_SET_ID 
        AND fvv.FLEX_VALUE           =gcc.segment3
        ) "ACCOUNT_DESCRIPTION",
        --    TO_CHAR(NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0) + SUM(NVL(xll.accounted_dr,0))- SUM(NVL(xll.accounted_cr,0)),'99999999999999.00') YTD_balance,
      GLD.LEDGER_ID,
      GLD.CURRENCY_CODE,
      gb.period_name,
      gcc.code_combination_id,
      gb.actual_flag Balance_Type,
      gld.name Ledger_Name,
      GLLookups.meaning ledger_type,
      glcd.object_name primary_ledger_name
    FROM gl_code_combinations gcc,
      gl_ledgers gld,
      gl_balances gb,
      gl_ledger_config_details glcd,
      gl_lookups GLLookups
    WHERE 1                     =1
    AND gcc.code_combination_id = gb.code_combination_id
    AND gld.configuration_id    = glcd.configuration_id
    AND GLLookups.lookup_code   = gld.ledger_category_code
    AND GLCD.OBJECT_TYPE_CODE   = 'PRIMARY'
    AND glcd.setup_step_code    = 'NONE'
    AND GLLookups.lookup_type   = 'GL_ASF_LEDGER_CATEGORY'
    AND gb.actual_flag          = 'A'
    AND gb.template_id         IS NULL
    AND gb.ledger_id            = gld.ledger_id
    AND gld.currency_code       = gb.currency_code
    --AND GCC.CODE_COMBINATION_ID = 21833485
    --AND gcc.segment1  = '1001'
    --AND gcc.segment4 BETWEEN '12311' AND '12659'
    --AND gb.period_name         IN ('JAN-17','ENE-17') -- for begining balance
    --AND gb.period_name = 'SEP-17'
    /*
    AND EXISTS
      (SELECT 1
      FROM FND_FLEX_VALUES_VL
      WHERE ((''                     IS NULL)
      OR (structured_hierarchy_level IN
        (SELECT HIERARCHY_ID
        FROM fnd_flex_hierarchies_vl h
        WHERE h.flex_value_set_id = 1010412
        AND h.hierarchy_name LIKE ''
        )))
      AND (FLEX_VALUE_SET_ID = 1010412)
      AND FLEX_VALUE         =gcc.segment4
      )*/
    AND NOT EXISTS
      (SELECT 1 --XLL.CODE_COMBINATION_ID
      FROM xla_ae_lines xll,
        gl_code_combinations gcode
      WHERE 1                     =1
      AND gcc.code_combination_id = xll.code_combination_id
      AND XLL.ACCOUNTING_DATE    >= TO_DATE('01/01/2018','mm/dd/yyyy')
      AND xll.accounting_date    <= sysdate
      AND xll.application_id      =222
      /*AND EXISTS
      (SELECT 1
      FROM FND_FLEX_VALUES_VL
      WHERE ((''                     IS NULL)
      OR (structured_hierarchy_level IN
        (SELECT HIERARCHY_ID
        FROM fnd_flex_hierarchies_vl h
        WHERE h.flex_value_set_id = 1010412
        AND h.hierarchy_name LIKE ''
        )))
      AND (FLEX_VALUE_SET_ID = 1010412)
      AND FLEX_VALUE         =gcc.segment4
      )*/
      )
    GROUP BY gcc.segment1,
      gcc.segment2,
      gcc.segment3,
      gcc.segment4,
      gcc.segment5,
      gcc.segment6,
      GCC.SEGMENT7,
      gcc.segment8,
      gcc.description,
      NVL(gb.begin_balance_dr,0) - NVL(gb.begin_balance_cr,0),
      gld.ledger_id,
      gld.currency_code,
      gb.period_name,
      gcc.code_combination_id,
      GB.ACTUAL_FLAG,
      gld.name,
      GLLOOKUPS.MEANING,
      GLCD.OBJECT_NAME;
    
    TYPE subledger_extract_tab_type IS TABLE OF subledger_extract_cur%ROWTYPE;
		CURSOR get_dir_path
		IS
			SELECT directory_path 
			FROM dba_directories 
			WHERE directory_name = 'XXFIN_OUTBOUND';
            
		l_subledger_extract_tab 	    subledger_extract_tab_type; 
		lf_arcs_file          			UTL_FILE.file_type;
		lc_arcs_file_header         	VARCHAR2(32000);
		lc_arcs_file_content			VARCHAR2(32000);
		ln_chunk_size           		BINARY_INTEGER:= 32767;
		lc_arcs_file_name	    	    VARCHAR2(250) :='ARCS_AR_';	
		lc_dest_file_name  				VARCHAR2(200);
		ln_conc_file_copy_request_id 	NUMBER;
		lc_dirpath						VARCHAR2(500);
		lc_file_name_instance			VARCHAR2(250);
		lc_instance_name			   	VARCHAR2(30);
		lb_complete        		   		BOOLEAN;
		lc_phase           		   		VARCHAR2(100);
		lc_status          		   		VARCHAR2(100);
		lc_dev_phase       		   		VARCHAR2(100);
		lc_dev_status      		   		VARCHAR2(100);
		lc_message         		   		VARCHAR2(100);
        lc_delimeter                    VARCHAR2(1) :=  ',';
BEGIN
	xla_security_pkg.set_security_context(602);
	--get file dir path
	OPEN get_dir_path;
	FETCH get_dir_path INTO lc_dirpath;
	CLOSE get_dir_path;
	SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV','INSTANCE_NAME')),1,8) 
	INTO lc_instance_name
	FROM dual;
    fnd_file.put_line(fnd_file.LOG,'Processing Arcs Subledger Extract for Period End :'||p_period_name);
    lc_arcs_file_name   :=  lc_arcs_file_name||p_period_name||'.txt';
    fnd_file.put_line(fnd_file.LOG,'Processing into file :'||lc_arcs_file_name);
	SELECT NAME
	INTO   lc_file_name_instance
	FROM   v$database;
	OPEN  subledger_extract_cur (p_period_name);
	FETCH subledger_extract_cur BULK COLLECT INTO l_subledger_extract_tab;
	CLOSE subledger_extract_cur;
	fnd_file.put_line(fnd_file.LOG,'Subledger Extract Count :'||l_subledger_extract_tab.COUNT);
	IF l_subledger_extract_tab.COUNT>0 THEN
		BEGIN
			lf_arcs_file := UTL_FILE.fopen('XXFIN_OUTBOUND',
									   lc_arcs_file_name,
									   'w',
									   ln_chunk_size);
			lc_arcs_file_header := 
								'COMPANY'
								||lc_delimeter||'COST_CENTER'
								||lc_delimeter||'ACCOUNT'
								||lc_delimeter||'LOCATION'
								||lc_delimeter||'INTERCOMPANY'
								||lc_delimeter||'LINE OF BUSINESS'
								||lc_delimeter||'FUTURE'
								||lc_delimeter||'YTD_BALANCE'
								||lc_delimeter||'YTD_BEGINNING_BAL'
								||lc_delimeter||'YTD_NET_DR'
								||lc_delimeter||'YTD_NET_CR'
								||lc_delimeter||'ACCOUNT_DESCRIPTION'
								||lc_delimeter||'LEDGER_ID'
								||lc_delimeter||'CURRENCY_CODE'
								||lc_delimeter||'PERIOD_NAME'
								||lc_delimeter||'CODE_COMBINATION_ID'
								||lc_delimeter||'BALANCE_TYPE'
								||lc_delimeter||'LEDGER_NAME'
								||lc_delimeter||'LEDGER_TYPE'
								||lc_delimeter||'PRIMARY_LEDGER_NAME';
			UTL_FILE.put_line(lf_arcs_file,lc_arcs_file_header);
			FOR i IN 1.. l_subledger_extract_tab.COUNT
			LOOP
				lc_arcs_file_content :=
							l_subledger_extract_tab(i).COMPANY
							||lc_delimeter||l_subledger_extract_tab(i).COST_CENTER
							||lc_delimeter||l_subledger_extract_tab(i).ACCOUNT
							||lc_delimeter||l_subledger_extract_tab(i).LOCATION
							||lc_delimeter||l_subledger_extract_tab(i).INTERCOMPANY
							||lc_delimeter||l_subledger_extract_tab(i).LINE_OF_BUSINESS					
							||lc_delimeter||l_subledger_extract_tab(i).FUTURE					
							||lc_delimeter||l_subledger_extract_tab(i).YTD_balance					
							||lc_delimeter||l_subledger_extract_tab(i).YTD_BEGINNING_BAL						
							||lc_delimeter||l_subledger_extract_tab(i).YTD_NET_DR		
							||lc_delimeter||l_subledger_extract_tab(i).YTD_NET_CR			
							||lc_delimeter||l_subledger_extract_tab(i).ACCOUNT_DESCRIPTION					
							||lc_delimeter||l_subledger_extract_tab(i).ledger_id						
							||lc_delimeter||l_subledger_extract_tab(i).CURRENCY_CODE					
							||lc_delimeter||l_subledger_extract_tab(i).period_name					
							||lc_delimeter||l_subledger_extract_tab(i).code_combination_id			
							||lc_delimeter||l_subledger_extract_tab(i).Balance_Type				
							||lc_delimeter||l_subledger_extract_tab(i).LEDGER_NAME			
							||lc_delimeter||l_subledger_extract_tab(i).ledger_type					
							||lc_delimeter||l_subledger_extract_tab(i).primary_ledger_name;				
					UTL_FILE.put_line(lf_arcs_file,lc_arcs_file_content);
			END LOOP;
		UTL_FILE.fclose(lf_arcs_file);
		fnd_file.put_line(fnd_file.LOG,'Matched Invoice File Created: '|| lc_arcs_file_name);
		-- copy to matched invoice file to xxfin_data/vps dir
		lc_dest_file_name := '/app/ebs/ct'||lc_instance_name||'/xxfin/ftp/out/vps/'||lc_arcs_file_name;
		ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN', 
																   'XXCOMFILCOPY', 
																   '', 
																   '', 
																   FALSE, 
																   lc_dirpath||'/'||lc_arcs_file_name, --Source File Name
																   lc_dest_file_name,            --Dest File Name
																   '', '', 'Y'                   --Deleting the Source File
																  );
		IF ln_conc_file_copy_request_id > 0
		THEN
			COMMIT;
			-- wait for request to finish
			lb_complete :=fnd_concurrent.wait_for_request (
															request_id   => ln_conc_file_copy_request_id,
															interval     => 10,
															max_wait     => 0,
															phase        => lc_phase,
															status       => lc_status,
															dev_phase    => lc_dev_phase,
															dev_status   => lc_dev_status,
															message      => lc_message
															);
		END IF;					
		EXCEPTION WHEN OTHERS THEN
		fnd_file.put_line(fnd_file.LOG,SQLCODE||SQLERRM);
		END;
	END IF;
	
EXCEPTION WHEN OTHERS THEN
	fnd_file.put_line(fnd_file.LOG,SQLCODE||SQLERRM);		
END subledger_arcs_extract;  
END XX_AR_ARCS_SUBLEDGER_EXTRACT;
/
