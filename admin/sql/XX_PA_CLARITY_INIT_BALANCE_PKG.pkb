create or replace
PACKAGE BODY  XX_PA_CLARITY_INIT_BALANCE_PKG AS
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       |  
-- +============================================================================================+ 
-- |  Name:  XX_PA_CLARITY_EXTRACT_PKG                                                          | 
-- |                                                                                            | 
-- |  Description:  This package extracts Project and Budget information for CLARITY            |
-- |                                                                                            |
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         21-SEP-2011  R.Strauss            Initial version                              |
-- | 1.1         17-NOV-2015  Harvinder Rakhra     Retrofit R12.2                               |
-- +============================================================================================+
PROCEDURE EXTRACT_CLARITY_BALANCE(errbuf       OUT NOCOPY VARCHAR2,
                                  retcode      OUT NOCOPY NUMBER)
IS
x_error_message		VARCHAR2(2000)	DEFAULT NULL;
x_return_status		VARCHAR2(20)	DEFAULT NULL;
x_msg_count			NUMBER		DEFAULT NULL;
x_msg_data			VARCHAR2(4000)	DEFAULT NULL;
x_return_flag		VARCHAR2(1)		DEFAULT NULL;
gc_error_loc		VARCHAR2(80)	DEFAULT NULL;

lc_instance_name		VARCHAR2(09)	DEFAULT NULL;
lc_file_rec			VARCHAR2(400)	DEFAULT NULL;
lc_file_name		VARCHAR2(400)	DEFAULT NULL;
lc_file_path		VARCHAR2(200)	:= 'XXFIN_OUTBOUND';
lc_dba_path			VARCHAR2(200)	DEFAULT NULL;
lc_dir_path			VARCHAR2(200)	DEFAULT NULL;
lc_file_handle		UTL_FILE.FILE_TYPE;
lc_req_id			NUMBER		DEFAULT NULL;
lc_wait			BOOLEAN;
lc_conc_phase		VARCHAR2(200)	DEFAULT NULL;
lc_conc_status		VARCHAR2(200)	DEFAULT NULL;
lc_dev_phase		VARCHAR2(200)	DEFAULT NULL;
lc_dev_status		VARCHAR2(200)	DEFAULT NULL;
lc_conc_message		VARCHAR2(400)	DEFAULT NULL;
lc_err_status		VARCHAR2(1)		DEFAULT NULL;

ln_extract_cnt		NUMBER		:= 0;
ln_extract_amt		NUMBER		:= 0;

-- ==========================================================================
-- Clarity Extract Initial Balance
-- ==========================================================================
CURSOR project_extract_1_cur IS
	SELECT SUBSTR(P.segment1,1,(INSTR(P.segment1,'-',1,1) - 1))				AS PAN, 
		 SUBSTR(P.segment1,(INSTR(P.segment1,'-',1,1) + 1),LENGTH(P.segment1))	AS PAN_EXTENSION, 
		 TO_CHAR(TO_DATE('01-'||G.GL_PERIOD_NAME,'DD-MON-YY'),'YYYY-MM-DD')	AS PA_PERIOD_DATE, 
	       SUBSTR(O.NAME,3,5) 									AS COST_CENTER_CODE, 
		 O.NAME				 							AS COST_CENTER_DESCRIPTION, 
		 T.TASK_NUMBER 										AS TASK, 
		 E.PROJECT_CURRENCY_CODE								AS CURRENCY_CODE,
      	 TO_CHAR(SUM(E.project_burdened_cost),'999,999,999.99') 			AS AMOUNT,
		 SUM(E.project_burdened_cost)								AS AMOUNT_NUM
	FROM   PA_PROJECTS_ALL			P,
      	 PA_TASKS				T,
	       PA_EXPENDITURE_ITEMS_ALL	E,
      	 HR_ALL_ORGANIZATION_UNITS_TL	O,
		 PA_COST_DISTRIBUTION_LINES_ALL G,
		 PA_PROJECT_TYPES_ALL		PT
	WHERE  P.project_id				= T.project_id
	AND    t.task_id					= E.task_id
	AND    E.cc_prvdr_organization_id	 	= O.ORGANIZATION_ID(+)
	AND    E.expenditure_item_id			= G.expenditure_item_id
	AND    G.line_type				= 'R'
	AND    G.line_num					= (SELECT MAX(line_num)
								   FROM   PA_COST_DISTRIBUTION_LINES_ALL D
								   WHERE  D.expenditure_item_id = E.expenditure_item_id
								   AND    D.line_type = 'R')
--*
	AND    P.TEMPLATE_FLAG				<> 'Y'
	AND    P.project_type				= PT.project_type
	AND    PT.direct_flag				= 'N'
  AND    P.SEGMENT1 IN ('E3443-52105325',
 'E3451-68104710',
 'E3522-68105882',
 'E3522-68105913',
 'E3528-68105544',
 'E3532-68105333',
 'E3541-68105580',
 'E3550-68105101',
 'E3562-68105531',
 'E3566-68105724',
 'E3589-68106316',
 'G7546-00105138',
 'G7546-00106165',
 'G7686-00105201',
 'G7745-00106314',
 'G7772-00105733',
 'G7772-00105734',
 'G7772-00105735',
 'G7773-00106108',
 'G7850-00105426',
 'G7884-00105360',
 'G7885-00105870',
 'G7885-00105871',
 'G7921-00105303',
 'G7929-00106133',
 'G7968-00106126',
 'G8122-00105788',
 'G8123-00105443',
 'G8253-00104865',
 'G8297-GC105633',
 'G8297-IEP00000',
 'G8297-PC106291',
 'G8297-SS106251',
 'G8297-SS106313',
 'G8297-SS106382',
 'G8326-00106142',
 'G8364-00105605',
 'G8370-00105500',
 'G8383-00105846',
 'G8383-00106436',
 'G8389-00105304',
 'G8389-00105856',
 'G8438-00105855',
 'G8455-00105280',
 'G8457-00105784',
 'G8474-00105601',
 'G8474-00105765',
 'G8474-00105876',
 'G8538-00104891',
 'G8553-00105723',
 'G8554-00105834',
 'G8558-00105667',
 'G8669-00105895',
 'G8686-00105761',
 'G8686-00106182',
 'G8699-00105559',
 'G8707-00105886',
 'G8707-00106170',
 'G8732-00105956',
 'G8732-00105958',
 'G8733-00106158',
 'G8737-00105818',
 'G8738-00105863',
 'G8772-00106184',
 'G8776-00106185',
 'G8779-00106156',
 'G8782-00106120',
 'G8787-00010000',
 'G8815-00105947',
 'G8815-00106305',
 'G8826-00105896',
 'G8848-00105934',
 'G8862-00105942',
 'G8862-00106319',
 'G8862-00106320',
 'G8863-00105946',
 'G8867-00105921',
 'G8869-00105943',
 'G8869-00106321',
 'G8869-00106322',
 'G8869-00106323',
 'G8875-00105729',
 'G8886-00106119',
 'G8889-00105953',
 'G8891-00106157',
 'G8896-00105810',
 'G8898-00000000',
 'G8899-00106194',
 'G8900-00105890',
 'G8932-00106372',
 'G8954-00000000',
 'G8965-00105710',
 'G8969-00106223',
 'G8970-00106163',
 'G8983-00106308',
 'G8987-00000207',
 'G8987-00002221',
 'G8987-00002245',
 'G8987-00002249',
 'G8987-00002297',
 'G8999-00105817',
 'G9000-00106360',
 'G9023-00105900',
 'G9025-00105427',
 'G9028-00106282',
 'G9032-00106408',
 'G9034-00106312',
 'G9034-00106419',
 'G9044-00106348',
 'G9044-00106357',
 'G9044-20106357',
 'G9045-00106296',
 'G9056-00105950',
 'G9057-00106303',
 'G9060-00005910',
 'G9062-00105404',
 'G9093-00106423',
 'G9094-PR000288',
 'G9094-00106405',
 'G9102-00106217',
 'G9103-00106214',
 'G9104-00106198',
 'G9106-00106216',
 'G9107-00106447',
 'G9108-00105957',
 'G9137-00106403',
 'G9142-AP000321',
 'G9142-DSFTE323',
 'G9142-RRFTE321',
 'G9142-T1FTE321',
 'G9145-00105914')
	GROUP BY SUBSTR(P.segment1,1,(INSTR(P.segment1,'-',1,1) - 1)), 
		   SUBSTR(P.segment1,(INSTR(P.segment1,'-',1,1) + 1),LENGTH(P.segment1)), 
		   G.GL_PERIOD_NAME,
	         SUBSTR(O.NAME,3,5), 
		   O.NAME,
		   T.TASK_NUMBER,
		   E.PROJECT_CURRENCY_CODE 
	ORDER BY 1,2,3,4,5,6,7;

-- ==========================================================================
-- Clarity Extract 2nd cursor
-- ==========================================================================
CURSOR project_extract_2_cur IS
	SELECT SUBSTR(P.segment1,1,(INSTR(P.segment1,'-',1,1) - 1))				AS PAN, 
		 SUBSTR(P.segment1,(INSTR(P.segment1,'-',1,1) + 1),LENGTH(P.segment1))	AS PAN_EXTENSION, 
		 TO_CHAR(TRUNC(P.start_date),'YYYY-MM-DD')					AS PA_START_DATE, 
		 NVL(TO_CHAR(P.completion_date,'YYYY-MM-DD'),' ')				AS PA_FINISH_DATE,
		 TO_CHAR(NVL(B01.RAW_COST,0), '999,999,999.99')					AS BUDGET_EXPENSE_AMOUNT,
		 TO_CHAR(NVL(B02.RAW_COST,0), '999,999,999.99')					AS BUDGET_CAPITAL_AMOUNT,
		 TO_CHAR(TO_DATE('01-'||B03.ACCUM_PERIOD,'DD-MON-YY'),'YYYY-MM-DD')	AS PA_PERIOD_DATE,
		 TO_CHAR(NVL(B03.CMT_RAW_COST_YTD,0), '999,999,999.99')			AS COMMITMENT,
		 NVL(B03.cmt_raw_cost_ytd,0)								AS COMMITMENT_NUM,
		 P.PROJECT_CURRENCY_CODE								AS CURRENCY_CODE
	FROM   PA_PROJECTS_ALL			P,
		 PA_PROJECT_TYPES_ALL		PT,
--*  (Expense)
		(SELECT P1.PROJECT_ID,
			  B1.RAW_COST
		 FROM   PA_PROJECTS_ALL          P1,
			  PA_TASKS                 T1,
			  PA_RESOURCE_ASSIGNMENTS  R1,
			  PA_BUDGET_LINES          B1,
			  PA_BUDGET_VERSIONS	  V1
		 WHERE  P1.PROJECT_ID 			= T1.PROJECT_ID
		 AND    T1.PROJECT_ID 			= R1.PROJECT_ID
		 AND    T1.TASK_ID 			= R1.TASK_ID
		 AND    R1.RESOURCE_ASSIGNMENT_ID 	= B1.RESOURCE_ASSIGNMENT_ID
		 AND    B1.BUDGET_VERSION_ID		= V1.BUDGET_VERSION_ID
		 AND	  V1.CURRENT_FLAG			= 'Y'
		 AND    T1.TASK_NUMBER 			= '01'
		 AND    not exists (SELECT 'Y' 
				 FROM   PA_PROJECTS_ALL P1A
				 WHERE  P1A.PROJECT_ID			= P1.PROJECT_ID
				 AND	  P1A.PROJECT_STATUS_CODE 	= 'CLOSED'
				 AND    P1A.CLOSED_DATE			< SYSDATE - 180)
		 ORDER BY P1.PROJECT_ID) 		B01,
--*  (Capital)
		(SELECT P2.PROJECT_ID,
			  B2.RAW_COST
		 FROM   PA_PROJECTS_ALL          P2,
			  PA_TASKS                 T2,
			  PA_RESOURCE_ASSIGNMENTS  R2,
			  PA_BUDGET_LINES          B2,
			  PA_BUDGET_VERSIONS	  V2
		 WHERE  P2.PROJECT_ID 			= T2.PROJECT_ID
		 AND    T2.PROJECT_ID 			= R2.PROJECT_ID
		 AND    T2.TASK_ID 			= R2.TASK_ID
		 AND    R2.RESOURCE_ASSIGNMENT_ID 	= B2.RESOURCE_ASSIGNMENT_ID
		 AND    B2.BUDGET_VERSION_ID		= V2.BUDGET_VERSION_ID
		 AND    V2.CURRENT_FLAG			= 'Y'
		 AND    T2.TASK_NUMBER 			= '02'
		 AND    not exists (SELECT 'Y' 
				 FROM   PA_PROJECTS_ALL P2A
				 WHERE  P2A.PROJECT_ID			= P2.PROJECT_ID
				 AND	  P2A.PROJECT_STATUS_CODE 	= 'CLOSED'
				 AND    P2A.CLOSED_DATE			< SYSDATE - 180)
		 ORDER BY P2.PROJECT_ID) 		B02,
--*  (Commitment)
		(SELECT P3.PROJECT_ID, 
			  H3.ACCUM_PERIOD,
			  C3.CMT_RAW_COST_YTD
		 FROM   PA_PROJECTS_ALL			P3,
			  PA_PROJECT_ACCUM_HEADERS	H3,
			  PA_PROJECT_ACCUM_COMMITMENTS	C3
		 WHERE  P3.PROJECT_ID 			= H3.PROJECT_ID
		 AND    H3.PROJECT_ACCUM_ID 		= C3.PROJECT_ACCUM_ID
		 AND    H3.TASK_ID 			= 0
		 AND    H3.RESOURCE_LIST_MEMBER_ID 	= 0
		 AND    not exists (SELECT 'Y' 
				 FROM   PA_PROJECTS_ALL P3A
				 WHERE  P3A.PROJECT_ID			= P3.PROJECT_ID
				 AND	  P3A.PROJECT_STATUS_CODE 	= 'CLOSED'
				 AND    P3A.CLOSED_DATE			< SYSDATE - 180)
		 ORDER BY P3.PROJECT_ID)		B03		
	WHERE  P.project_id				= B01.project_id(+)
	AND	 P.project_id				= B02.project_id(+)
	AND    P.project_id				= B03.project_id(+)
	AND    P.project_type				= PT.project_type
	AND    P.TEMPLATE_FLAG				<> 'Y'
	AND    PT.direct_flag				= 'N'
	AND	 P.segment1					IN ('E3443-52105325',
 'E3451-68104710',
 'E3522-68105882',
 'E3522-68105913',
 'E3528-68105544',
 'E3532-68105333',
 'E3541-68105580',
 'E3550-68105101',
 'E3562-68105531',
 'E3566-68105724',
 'E3589-68106316',
 'G7546-00105138',
 'G7546-00106165',
 'G7686-00105201',
 'G7745-00106314',
 'G7772-00105733',
 'G7772-00105734',
 'G7772-00105735',
 'G7773-00106108',
 'G7850-00105426',
 'G7884-00105360',
 'G7885-00105870',
 'G7885-00105871',
 'G7921-00105303',
 'G7929-00106133',
 'G7968-00106126',
 'G8122-00105788',
 'G8123-00105443',
 'G8253-00104865',
 'G8297-GC105633',
 'G8297-IEP00000',
 'G8297-PC106291',
 'G8297-SS106251',
 'G8297-SS106313',
 'G8297-SS106382',
 'G8326-00106142',
 'G8364-00105605',
 'G8370-00105500',
 'G8383-00105846',
 'G8383-00106436',
 'G8389-00105304',
 'G8389-00105856',
 'G8438-00105855',
 'G8455-00105280',
 'G8457-00105784',
 'G8474-00105601',
 'G8474-00105765',
 'G8474-00105876',
 'G8538-00104891',
 'G8553-00105723',
 'G8554-00105834',
 'G8558-00105667',
 'G8669-00105895',
 'G8686-00105761',
 'G8686-00106182',
 'G8699-00105559',
 'G8707-00105886',
 'G8707-00106170',
 'G8732-00105956',
 'G8732-00105958',
 'G8733-00106158',
 'G8737-00105818',
 'G8738-00105863',
 'G8772-00106184',
 'G8776-00106185',
 'G8779-00106156',
 'G8782-00106120',
 'G8787-00010000',
 'G8815-00105947',
 'G8815-00106305',
 'G8826-00105896',
 'G8848-00105934',
 'G8862-00105942',
 'G8862-00106319',
 'G8862-00106320',
 'G8863-00105946',
 'G8867-00105921',
 'G8869-00105943',
 'G8869-00106321',
 'G8869-00106322',
 'G8869-00106323',
 'G8875-00105729',
 'G8886-00106119',
 'G8889-00105953',
 'G8891-00106157',
 'G8896-00105810',
 'G8898-00000000',
 'G8899-00106194',
 'G8900-00105890',
 'G8932-00106372',
 'G8954-00000000',
 'G8965-00105710',
 'G8969-00106223',
 'G8970-00106163',
 'G8983-00106308',
 'G8987-00000207',
 'G8987-00002221',
 'G8987-00002245',
 'G8987-00002249',
 'G8987-00002297',
 'G8999-00105817',
 'G9000-00106360',
 'G9023-00105900',
 'G9025-00105427',
 'G9028-00106282',
 'G9032-00106408',
 'G9034-00106312',
 'G9034-00106419',
 'G9044-00106348',
 'G9044-00106357',
 'G9044-20106357',
 'G9045-00106296',
 'G9056-00105950',
 'G9057-00106303',
 'G9060-00005910',
 'G9062-00105404',
 'G9093-00106423',
 'G9094-PR000288',
 'G9094-00106405',
 'G9102-00106217',
 'G9103-00106214',
 'G9104-00106198',
 'G9106-00106216',
 'G9107-00106447',
 'G9108-00105957',
 'G9137-00106403',
 'G9142-AP000321',
 'G9142-DSFTE323',
 'G9142-RRFTE321',
 'G9142-T1FTE321',
 'G9145-00105914')
	AND    not exists (SELECT 'Y' 
				 FROM   PA_PROJECTS_ALL P3
				 WHERE  P3.PROJECT_ID			= P.PROJECT_ID
				 AND	  P3.PROJECT_STATUS_CODE 	= 'CLOSED'
				 AND    P3.CLOSED_DATE			< SYSDATE - 180)
--*
	ORDER BY P.SEGMENT1;

-- ==========================================================================
-- Main Process
-- ==========================================================================
BEGIN
	gc_error_loc := 'Clarity Extract 1000- Main Process';
      lc_instance_name := 'INITIAL';
      FND_FILE.PUT_LINE(fnd_file.log,'Clarity Initial Balance extract - Begin');

		BEGIN

			SELECT directory_path
			INTO   lc_dba_path
			FROM   dba_directories
			WHERE  directory_name = lc_file_path;

			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					lc_err_status := 'E';
					FND_FILE.PUT_LINE(fnd_file.log,'Error (2) - NO_DATA_FOUND, loc = '||gc_error_loc);
				WHEN OTHERS THEN
					lc_err_status := 'E';
					FND_FILE.PUT_LINE(fnd_file.log,'Error (2) - Others, loc = '||gc_error_loc||' SQLERRM = '||SQLERRM);
		END;

-- ==========================================================================
-- FIRST EXTRACT
-- ==========================================================================
	gc_error_loc 	:= 'Clarity Extract 2000- EXTRACT START';
      FND_FILE.PUT_LINE(fnd_file.log,'Clarity Initial Balance extract - Projects begin');

	BEGIN

		lc_file_name 	:= 'OD_PA_CLARITY_IB_EXTRACT_PROJECTS_'||lc_instance_name||'_'||to_char(sysdate,'MMDDYYYY')||'.csv';
		lc_file_handle	:= UTL_FILE.FOPEN(lc_file_path, lc_file_name, 'W');

		lc_file_rec	:=	'1'||'|'||
					'PAN  '||'|'||
					'PAN_EXTENSION'||'|'||
					'PA_PERIOD_DATE'||'|'||
		            	'TASK                     '||'|'||
					'COST_CENTER_CODE'||'|'||
					'COST_CENTER_DESCRIPTION                                          '||'|'||
					'AMOUNT               '||'|'||
					'CURRENCY'||'|'||
					'DATA_SOURCE';

		UTL_FILE.PUT_LINE(lc_file_handle, lc_file_rec);

		EXCEPTION
			WHEN OTHERS THEN
				lc_err_status := 'E';
                        FND_FILE.PUT_LINE(fnd_file.log,'Error '||gc_error_loc||' SQLERRM = '||SQLERRM);
	END;

	FOR project_rec in project_extract_1_cur
	LOOP
		BEGIN

		gc_error_loc 	:= 'Clarity Extract 2200- EXTRACT LOOP';

		lc_file_rec	:=	'2'||'|'||
					RPAD(project_rec.pan,5,' ')||'|'||
					RPAD(project_rec.pan_extension,13,' ')||'|'||
					RPAD(project_rec.pa_period_date,14,' ')||'|'||
					RPAD(project_rec.task,25,' ')||'|'||
					RPAD(project_rec.cost_center_code,16,' ')||'|'||
					RPAD(project_rec.cost_center_description,65,' ')||'|'||
					LPAD(project_rec.amount,21,' ')||'|'||
					RPAD(project_rec.currency_code,8,' ')||'|'||
					'PA         ';


		UTL_FILE.PUT_LINE(lc_file_handle, lc_file_rec);

		ln_extract_cnt := ln_extract_cnt + 1;
		ln_extract_amt := ln_extract_amt + project_rec.amount_num;

		EXCEPTION
			WHEN OTHERS THEN
				lc_err_status := 'E';
                        FND_FILE.PUT_LINE(fnd_file.log,'Error '||gc_error_loc||' SQLERRM = '||SQLERRM);
		END;

	END LOOP;

	UTL_FILE.FCLOSE(lc_file_handle);

	COMMIT;

      FND_FILE.PUT_LINE(fnd_file.log,'Finished first Clarity extract, records created = '||ln_extract_cnt||' amount = '||ln_extract_amt);

	ln_extract_cnt := 0;
	ln_extract_amt := 0;


-- ==========================================================================
-- SECOND EXTRACT
-- ==========================================================================
	gc_error_loc 	:= 'Clarity Extract 4000- EXTRACT START';
      FND_FILE.PUT_LINE(fnd_file.log,'Clarity Initial Balance extract - Budget begin');

	BEGIN

		lc_file_name 	:= 'OD_PA_CLARITY_IB_EXTRACT_BUDGET_'||lc_instance_name||'_'||to_char(sysdate,'MMDDYYYY')||'.csv';
		lc_file_handle	:= UTL_FILE.FOPEN(lc_file_path, lc_file_name, 'W');

		lc_file_rec :=	'1'||'|'||
					'PAN  '||'|'||
					'PAN_EXTENSION'||'|'||
					'PA_START_DATE'||'|'||
					'PA_FINISH_DATE'||'|'||
					'BUDGET_CAPITAL_AMOUNT'||'|'||
					'BUDGET_EXPENSE_AMOUNT'||'|'||
					'PA_PERIOD_DATE'||'|'||
					'COMMITMENT           '||'|'||
					'CURRENCY'||'|'||
					'BUDGET_PRE_PAID';

		UTL_FILE.PUT_LINE(lc_file_handle, lc_file_rec);

		EXCEPTION
			WHEN OTHERS THEN
				lc_err_status := 'E';
                        FND_FILE.PUT_LINE(fnd_file.log,'Error '||gc_error_loc||' SQLERRM = '||SQLERRM);
	END;

	FOR budget_rec in project_extract_2_cur
	LOOP
		BEGIN

		gc_error_loc 	:= 'Clarity Extract 4200- EXTRACT LOOP';

		lc_file_rec	:=	'2'||'|'||
					RPAD(budget_rec.pan,5,' ')||'|'||
					RPAD(budget_rec.pan_extension,13,' ')||'|'||
					RPAD(budget_rec.pa_start_date,13,' ')||'|'||
					RPAD(NVL(budget_rec.pa_finish_date,' '),14,' ')||'|'||
					LPAD(budget_rec.budget_capital_amount,21,' ')||'|'||
					LPAD(budget_rec.budget_expense_amount,21,' ')||'|'||
					RPAD(budget_rec.pa_period_date,14,' ')||'|'||
					LPAD(budget_rec.commitment,21,' ')||'|'||
					RPAD(budget_rec.currency_code,8,' ')||'|';

		UTL_FILE.PUT_LINE(lc_file_handle, lc_file_rec);

		ln_extract_cnt := ln_extract_cnt + 1;
		ln_extract_amt := ln_extract_amt + budget_rec.commitment_num;

		EXCEPTION
			WHEN OTHERS THEN
				lc_err_status := 'E';
                        FND_FILE.PUT_LINE(fnd_file.log,'Error '||gc_error_loc||' SQLERRM = '||SQLERRM);
		END;

	END LOOP;

	UTL_FILE.FCLOSE(lc_file_handle);

	COMMIT;

      FND_FILE.PUT_LINE(fnd_file.log,'Finished first Clarity extract, records created = '||ln_extract_cnt||' amount = '||ln_extract_amt);

-- ==========================================================================
-- EXTRACT COMPLETE
-- ==========================================================================

FND_FILE.PUT_LINE(fnd_file.log,'extract complete');

END EXTRACT_CLARITY_BALANCE;

END XX_PA_CLARITY_INIT_BALANCE_PKG ;
/