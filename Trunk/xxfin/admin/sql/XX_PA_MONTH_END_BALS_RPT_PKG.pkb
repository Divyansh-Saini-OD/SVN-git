create or replace
PACKAGE BODY XX_PA_MONTH_END_BALS_RPT_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_PA_EXPDT_MTHLY_ACT_RPT_PKG                                                      |
-- |  Description:  OD: PA Month End Balances Report                                            |
-- |                CR631/731 - R1169                                                           |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         07-Apr-2010  Joe Klein        Initial version                                  |
-- | 1.1         06-May-2010  Joe Klein        Defect 5649 - Changed where clause for CIP       |
-- |                                           General task type.                               |
-- | 1.2         13-May-2010  Joe Klein        Defect 5866 - Added period clause to correct     |
-- |                                           wrong company issue.                             |
-- | 1.2         13-May-2010  Joe Klein        Defect 5910 - Remove tab chr(9) from project     |
-- |                                           description field.                               |
-- | 1.3         14-May-2010  Joe Klein        Defect 5862 - Derive city and state from project |
-- |                                           location when task location = 010000 or blank    |
-- | 1.4         14-May-2010  Subbu Pillai     Fixed the Company and Account Issue in Subquery  |
-- | 1.5         06-Aug-2012  Adithya   	   New procedure XX_MAIN_GRP_RPT for the new report |
-- | 					                       OD PA Month End Balances Report¡ªGrouped as per  |
-- |					                       defect# 13846	                                |
-- | 1.6         11-Sep-2013 Divya Sidhaiyan   Add 2 New columns Task Org ID and Task Org Name  |
-- |                                           for Defect# 24167                                |
-- | 1.7         14-Nov-2013 Veronica M        R1169 - Defect# 26425:Included column names in the insert|
-- |                                           to the table xx_pa_month_end_bal_rpt_tbl   |
-- | 1.8         14-Feb-2013 Paddy Sanjeevi    Defect 28233                                     |
-- | 1.9         05-Jul-2014 Kirubha Samuel    Defect 30712 - Cursor modified for performance   |
-- |                                               tuning                                       |
-- | 1.10        15-Jul-2014 Kiran Maddala    Defect 30896 -                                 	|	
-- |									      Replaced orgnaization_id and name with TASK_ORG_ID|
-- | 										  and TASK_ORG_NAME for getting data in the output  |
-- | 1.11        23-Nov-2015 Harvinder Rakhra Retrofit R12.2                                    |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: XX_PA_MONTH_END_BALS_RPT_PKG.XX_MAIN_RPT                                            |
-- |  Description: This pkg.procedure will extract project data at a point in time, up to and   |
-- |  including a particular PA period.                                                         |
-- =============================================================================================|
  PROCEDURE XX_MAIN_RPT
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER,
   p_period IN VARCHAR2 DEFAULT NULL,
   p_task_type IN VARCHAR2 DEFAULT NULL,
   p_project_num_from IN VARCHAR2 DEFAULT NULL,
   p_project_num_to IN VARCHAR2 DEFAULT NULL,
   p_company IN VARCHAR2 DEFAULT NULL)
  IS
    v_out_header   VARCHAR2(1000);
    v_log_msg      VARCHAR2(100);
    v_profile_value VARCHAR2(100);
    v_period_num gl_period_statuses.effective_period_num%TYPE;
    i NUMBER;
        
    CURSOR c_out IS
    SELECT out_rec
    FROM
      (SELECT pt.task_number||chr(9)||
              pt.task_name||chr(9)||
              GTEMP.expenditure_type||chr(9)||
              GTEMP.period_name||chr(9)||
              pt.wbs_level||chr(9)||
              pp.segment1||chr(9)||
              pp.project_type||chr(9)||
              replace(pp.description,chr(9),'')||chr(9)|| --defect 5910
              pp.completion_date||chr(9)||
              pp.attribute1||chr(9)||
              pt.attribute1||chr(9)||
              (SELECT town_or_city FROM hr_locations_all HLA WHERE location_code LIKE
                  DECODE(pt.attribute1,null,pp.attribute1,'010000',pp.attribute1,pt.attribute1)||'%' and inactive_date is null AND ROWNUM < 2)||chr(9)||  --defect 5862
              (SELECT region_2 FROM hr_locations_all HLA WHERE location_code LIKE
                  DECODE(pt.attribute1,null,pp.attribute1,'010000',pp.attribute1,pt.attribute1)||'%' and inactive_date is null AND ROWNUM < 2)||chr(9)||  --defect 5862
              SUM(NVL(GTEMP.capitalized_cost,0))||chr(9)||
              SUM(NVL(GTEMP.capitalizable_cost,0))||chr(9)||
              (SUM(NVL(GTEMP.capitalizable_cost,0)) - SUM(NVL(GTEMP.capitalized_cost,0)))||chr(9)||
              account||chr(9)||
              company out_rec
       FROM pa_tasks pt,  
            pa_projects_all pp, 
          (SELECT  /*+ USE_NL(PAL, PAD, E) INDEX( PAL PA_PROJECT_ASSET_LINES_N2) */  PAL.project_id,   
                   E.task_id,  
                   E.expenditure_type EXPENDITURE_TYPE, 
                   'X' TASK_NUMBER,  
                   'X' TASK_NAME, 
                   0 PARENT_TASK_ID, 
                   0 WBS_LEVEL, 
                   PAL.fa_period_name period_name, 
                   ROUND(DECODE(PAL.line_type,'C',(PAD.cip_cost*(PAL.current_asset_cost/decode(PAL.original_asset_cost,0,1,PAL.original_asset_cost))),0),5) CAPITALIZED_COST,  
                   0 CAPITALIZABLE_COST,
                   gcc.segment3 account,
                   gcc.segment1 company 
           FROM PA_PROJECT_ASSET_LINE_DETAILS PAD,  
                PA_PROJECT_ASSET_LINES_ALL PAL , 
                PA_EXPENDITURE_ITEMS_ALL E,
                gl_code_combinations GCC 
           WHERE  PAD.project_asset_line_detail_id = PAL.project_asset_line_detail_id      
             AND  PAL.transfer_status_code IN ('T', 'A')  
             AND  E.expenditure_item_id = PAD.expenditure_item_id  
             AND  GCC.code_combination_id = PAL.cIP_CCID 
           UNION ALL 
           SELECT  tasks.PROJECT_ID, 
                   tasks.TASK_ID, 
                   accum.expenditure_type EXPENDITURE_TYPE, 
                   'X' TASK_NUMBER, 
                   'X' TASK_NAME, 
                   0 PARENT_TASK_ID, 
                   0 WBS_LEVEL, 
                   accum.pa_period Period_name, 
                   0 CAPITALIZED_COST, 
                   (DECODE(NVL(tasks.RETIREMENT_COST_FLAG, 'N'),'N',DECODE(ptype.capital_cost_type_code,'R',NVL(accum.TOT_BILLABLE_RAW_COST,0) + 
                                 NVL(accum.I_TOT_BILLABLE_RAW_COST,0),'B',NVL(accum.TOT_BILLABLE_BURDENED_COST,0) + 
                                 NVL(accum.I_TOT_BILLABLE_BURDENED_COST,0)),0)) CAPITALIZABLE_COST,
                   (SELECT gcc.segment3 from PA_EXPENDITURE_ITEMS_ALL PEI, PA_COST_DIST_LINES_V PCDL,gl_code_combinations GCC  
                    WHERE PEI.project_id = proj.project_id  
                      AND PEI.task_id = tasks.task_id  
                      AND PCDL.expenditure_item_id = PEI.EXPENDITURE_ITEM_ID  
                      AND GCC.code_combination_id = PCDL.dr_code_combination_id 
							 AND PCDL.pa_period_name = accum.pa_period --- Added for Defect # 5866
                      AND ROWNUM < 2) account, 
                   (SELECT gcc.segment1 from PA_EXPENDITURE_ITEMS_ALL PEI, PA_COST_DIST_LINES_V PCDL,gl_code_combinations GCC  
                    WHERE PEI.project_id = proj.project_id  
                      AND PEI.task_id = tasks.task_id  
                      AND PCDL.expenditure_item_id = PEI.EXPENDITURE_ITEM_ID  
                      AND GCC.code_combination_id = PCDL.dr_code_combination_id 
                      AND PCDL.pa_period_name = accum.pa_period --- Added for Defect # 5866
                      AND ROWNUM < 2) company 
           FROM pa_txn_accum accum, 
                pa_tasks tasks, 
                pa_projects_all proj, 
                pa_project_types_all ptype 
           WHERE accum.task_id = tasks.task_id
             AND tasks.project_id = accum.project_id
             AND proj.PROJECT_ID = accum.PROJECT_ID
             AND proj.PJI_SOURCE_FLAG IS NULL
             AND proj.PROJECT_TYPE = ptype.PROJECT_TYPE
             AND proj.TEMPLATE_FLAG <> 'Y'
             AND ptype.PROJECT_TYPE_CLASS_CODE = 'CAPITAL'
             AND ptype.org_id = proj.org_id          
          ) GTEMP 
      WHERE GTEMP.task_id(+) =pt.task_id  
        AND pt.project_id= gtemp.project_id(+) 
        AND pt.project_id=pp.project_id 
        AND (GTEMP.capitalized_cost <> 0 OR GTEMP.capitalizable_cost <> 0) 
        AND (  (p_task_type = 'Marketing'          AND (pt.task_number LIKE '80.%' OR pt.task_number LIKE '%.MKT.%'))
               OR
               (p_task_type = 'Tenant Allowance'   AND (pt.task_number LIKE '81.%.ST%' OR pt.task_number LIKE '81.%.LT%'))
               OR
               (p_task_type = 'Lease Acquisitions' AND (pt.task_number = '02.LEG'))
               OR
               (p_task_type = 'CIP General'        AND (  (pt.task_number LIKE '02.%' AND pt.task_number <> '02.LEG')
                                                          OR
                                                          (pt.task_number LIKE '81.%' AND pt.task_number NOT LIKE '81.%.ST%' AND pt.task_number NOT LIKE '81.%.LT%' AND pt.task_number NOT LIKE '%.MKT.%')
                                                       ))
               OR
               (p_task_type IS NULL)
            )
        AND (  (p_project_num_from IS NOT NULL AND p_project_num_to IS NOT NULL AND pp.segment1 BETWEEN p_project_num_from AND p_project_num_to)
               OR 
               (p_project_num_from IS NOT NULL AND p_project_num_to IS     NULL AND pp.segment1 >= p_project_num_from)
               OR 
               (p_project_num_from IS     NULL AND p_project_num_to IS NOT NULL AND pp.segment1 <= p_project_num_to)
               OR
               (p_project_num_from IS     NULL AND p_project_num_to IS     NULL)
            )

        AND (  (p_company IS NOT NULL AND company = p_company)
               OR 
               (p_company IS NULL)
            )
        AND GTEMP.period_name IN (
                                  SELECT DISTINCT period_name
                                  FROM gl_period_statuses
                                  WHERE effective_period_num <= v_period_num
                                 ) 
        AND pp.org_id = v_profile_value
      GROUP BY  pt.task_number,  
                pt.task_name,  
                pt.wbs_level, 
                pp.segment1, 
                pp.project_type,
                pp.project_type, 
                replace(pp.description,chr(9),''), --defect 5910
                pp.completion_date, 
                pp.attribute1, 
                pt.attribute1, 
                GTEMP.period_name,
                GTEMP.expenditure_type,
                gtemp.account,
                gtemp.company
      ORDER BY  pt.task_number,  
                pt.task_name
      );
            
  BEGIN
    --v_log_msg := 'Starting BEGIN block';
    --FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    
--  v_profile_value := FND_PROFILE.value('ORG_ID');
  
    v_profile_value :=mo_global.get_current_org_id;  -- Defect 28233

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'org_id = ' || v_profile_value);
    
    select distinct effective_period_num into v_period_num from gl_period_statuses where period_name = p_period;
    
    v_out_header  := 'TASK NUMBER'||chr(9)||'TASK NAME'||chr(9)||'EXPENDITURE TYPE'||chr(9)||'PERIOD NAME'||chr(9)||
                     'WBS LEVEL'||chr(9)||'PROJECT NUMBER'||chr(9)||'PROJECT TYPE'||chr(9)||'PROJECT DESCRIPTION'||chr(9)||
                     'PROJECT TRANSACTION DURATION'||chr(9)||'PROJECT LOCATION NUMBER'||chr(9)||'TASK LOCATION NUMBER'||chr(9)||
                     'CITY'||chr(9)||'STATE'||chr(9)||'CAPITALIZED COST'||chr(9)||'CAPITALIZABLE COST'||chr(9)||'CIP COST'||chr(9)||'ACCOUNT'||chr(9)||'COMPANY';
                      
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_period = ' || p_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_task_type = ' || p_task_type);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_project_num_from = ' || p_project_num_from);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_project_num_to = ' || p_project_num_to);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_company = ' || p_company);
    
    i := 0;
    FOR c_out_rec IN c_out LOOP
      i := i + 1;
      IF i = 1 THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, v_out_header);
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, c_out_rec.out_rec);
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'output record count = ' || i);
  
  END XX_MAIN_RPT;
  
  --Start modification by Adithya for defect#13846
  -- +============================================================================================+
-- |  Name: XX_PA_MONTH_END_BALS_RPT_PKG.XX_MAIN_GRP_RPT                                            |
-- |  Description: This pkg.procedure will extract project data at a point in time, up to and   |
-- |  including a particular PA period.                                                         |
-- =============================================================================================|
  
PROCEDURE drop_table(
    p_table_name VARCHAR2)
IS
BEGIN
  EXECUTE IMMEDIATE 'drop table ' || p_table_name;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Table xx_pa_month_end_temp does not exist');
END drop_table;

PROCEDURE XX_MAIN_GRP_RPT(
    errbuff OUT NOCOPY VARCHAR2,
    retcode OUT NOCOPY NUMBER,
    p_start_period     IN VARCHAR2 DEFAULT NULL,
    p_end_period       IN VARCHAR2 DEFAULT NULL, --Defect# 13846
    p_capital_task     IN VARCHAR2 DEFAULT 'Y',  --Defect# 13846
    p_service_type     IN VARCHAR2 DEFAULT NULL, --Defect# 13846
    p_project_num_from IN VARCHAR2 DEFAULT NULL,
    p_project_num_to   IN VARCHAR2 DEFAULT NULL,
    p_company          IN VARCHAR2 DEFAULT NULL)
IS
  v_out_header    VARCHAR2(1000);
  v_log_msg       VARCHAR2(100);
  v_profile_value VARCHAR2(100);
  v_period_num1 gl_period_statuses.effective_period_num%TYPE;
  v_period_num2 gl_period_statuses.effective_period_num%TYPE;
  V_MIN_START_PRD GL_PERIOD_STATUSES.PERIOD_NAME%TYPE;
  I            NUMBER;
  V_REQUEST_ID            NUMBER;
  v_temp_table_name VARCHAR2(200);
  v_prd_query  VARCHAR2(2000);
  v_main_query VARCHAR2(10000);
TYPE t_od_tbl
IS
  TABLE OF xx_pa_month_end_bal_rpt_tbl%ROWTYPE;
  l_tab t_od_tbl := t_od_tbl();
  CURSOR c_main --Cursor modified with hints and where for defect #30712
  IS
    SELECT /*+ cardinality(TBL,100000) */  TBL.*
         FROM     XX_PA_MONTH_END_BAL_RPT_TBL TBL,
        (SELECT  /*+ no_merge */  TBL1.PROJECT_ID
         FROM     XX_PA_MONTH_END_BAL_RPT_TBL TBL1
         GROUP BY TBL1.PROJECT_ID
         HAVING   (SUM(TBL1.CIP_COST) <> 0)
         UNION
         SELECT   TBL2.PROJECT_ID
         FROM     XX_PA_MONTH_END_BAL_RPT_TBL TBL2
         WHERE    (TBL2.EFFECTIVE_PERIOD_NUM         >= v_period_num1
                  AND      TBL2.EFFECTIVE_PERIOD_NUM <= v_period_num2
                  )
         GROUP BY TBL2.PROJECT_ID
         ) TBL3
WHERE    TBL.PROJECT_ID = TBL3.PROJECT_ID 
ORDER BY SEGMENT1   ,
         TASK_NUMBER,
         EFFECTIVE_PERIOD_NUM;
  BEGIN
    --drop_table('xx_pa_month_end_temp');
--  V_PROFILE_VALUE := FND_PROFILE.VALUE('ORG_ID');
    v_profile_value :=mo_global.get_current_org_id;  -- Defect 28233
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'org_id = ' || v_profile_value);
    V_REQUEST_ID:=FND_GLOBAL.CONC_REQUEST_ID;
    v_temp_table_name:='xxfin.xx_pa_month_end_temp'||V_REQUEST_ID;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'org_id = ' || V_PROFILE_VALUE);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'temp_table = ' || v_temp_table_name);
    SELECT DISTINCT effective_period_num
    INTO v_period_num1
    FROM gl_period_statuses
    WHERE period_name = p_start_period;
    SELECT DISTINCT effective_period_num
    INTO v_period_num2
    FROM gl_period_statuses
    WHERE period_name = p_end_period; -- Added as per Defect# 13846
    v_prd_query      := 'SELECT DISTINCT period_name                                  
						 FROM gl_period_statuses                                  
						 WHERE effective_period_num <= '||v_period_num2||'';
    V_MAIN_QUERY     :=
    'create table '||v_temp_table_name||'  as (SELECT   PAL.project_id,                      
E.task_id,                     
E.expenditure_type EXPENDITURE_TYPE,                    
''X'' TASK_NUMBER,                     
''X'' TASK_NAME,                    
0 PARENT_TASK_ID,                    
0 WBS_LEVEL,                    
PAL.fa_period_name period_name,                    
ROUND(DECODE(PAL.line_type,''C'',(PAD.cip_cost*(PAL.current_asset_cost/decode(PAL.original_asset_cost,0,1,PAL.original_asset_cost))),0),5) CAPITALIZED_COST,                     
0 CAPITALIZABLE_COST,                   
gcc.segment3 account,                   
gcc.segment1 company           
FROM PA_PROJECT_ASSET_LINE_DETAILS PAD,                  
PA_PROJECT_ASSET_LINES_ALL PAL,                
PA_EXPENDITURE_ITEMS_ALL E,                
gl_code_combinations GCC           
WHERE  PAD.project_asset_line_detail_id  = PAL.project_asset_line_detail_id                   
AND  PAL.transfer_status_code IN (''T'', ''A'')               
AND  E.expenditure_item_id    = PAD.expenditure_item_id               
AND  GCC.code_combination_id    = PAL.cIP_CCID           
UNION ALL            
SELECT  tasks.PROJECT_ID,                    
tasks.TASK_ID,                    
accum.expenditure_type EXPENDITURE_TYPE,                    
''X'' TASK_NUMBER,                    
''X'' TASK_NAME,                    
0 PARENT_TASK_ID,                    
0 WBS_LEVEL,                    
accum.pa_period Period_name,                    
0 CAPITALIZED_COST,                    
(DECODE(NVL(tasks.RETIREMENT_COST_FLAG, ''N''),''N'',DECODE(ptype.capital_cost_type_code,''R'',NVL(accum.TOT_BILLABLE_RAW_COST,0) +                                  
NVL(accum.I_TOT_BILLABLE_RAW_COST,0),''B'',NVL(accum.TOT_BILLABLE_BURDENED_COST,0) +                                  
NVL(accum.I_TOT_BILLABLE_BURDENED_COST,0)),0)) CAPITALIZABLE_COST,                   
(SELECT gcc.segment3 from PA_EXPENDITURE_ITEMS_ALL PEI, PA_COST_DIST_LINES_V PCDL,gl_code_combinations GCC                      
WHERE PEI.project_id = proj.project_id                        
AND PEI.task_id = tasks.task_id                        
AND PCDL.expenditure_item_id = PEI.EXPENDITURE_ITEM_ID                        
AND GCC.code_combination_id = PCDL.dr_code_combination_id         
AND PCDL.pa_period_name = accum.pa_period --- Added for Defect # 5866                      
AND ROWNUM < 2) account,                    
(SELECT gcc.segment1 from PA_EXPENDITURE_ITEMS_ALL PEI, PA_COST_DIST_LINES_V PCDL,gl_code_combinations GCC                      
WHERE PEI.project_id = proj.project_id                        
AND PEI.task_id = tasks.task_id                      
AND PCDL.expenditure_item_id = PEI.EXPENDITURE_ITEM_ID                        
AND GCC.code_combination_id = PCDL.dr_code_combination_id                       
AND PCDL.pa_period_name = accum.pa_period --- Added for Defect # 5866                      
AND ROWNUM < 2) company           
FROM pa_txn_accum accum,                 
pa_tasks tasks,                 
pa_projects_all proj,                 
pa_project_types_all ptype            
WHERE accum.task_id = tasks.task_id             
AND tasks.project_id = accum.project_id             
AND proj.PROJECT_ID = accum.PROJECT_ID             
AND proj.PJI_SOURCE_FLAG IS NULL             
AND proj.PROJECT_TYPE = ptype.PROJECT_TYPE             
AND proj.TEMPLATE_FLAG <> ''Y''             
AND ptype.PROJECT_TYPE_CLASS_CODE = ''CAPITAL''             
AND ptype.org_id = proj.org_id)';
    EXECUTE IMMEDIATE v_main_query;
    COMMIT;
	
    V_MAIN_QUERY :=
    'INSERT  INTO xx_pa_month_end_bal_rpt_tbl
(TASK_NUMBER            -- Added by Veronica on 14-Nov-2013 for defect# 26425 START                                            
,TASK_ID                   
,TASK_NAME                 
,EXPENDITURE_TYPE          
,PERIOD_NAME               
,PERIOD_NUM                
,PERIOD_YEAR               
,QUARTER_NUM               
,EFFECTIVE_PERIOD_NUM      
,WBS_LEVEL                 
,SEGMENT1                  
,PROJECT_ID                
,PROJECT_TYPE              
,DESCRIPTION               
,COMPLETION_DATE           
,PROJECT_ATTRIBUTE1        
,TASK_ATTRIBUTE1           
,TOWN_OR_CITY              
,REGION_2                  
,CAPITALIZED_COST          
,CAPITALIZABLE_COST        
,CIP_COST                  
,ACCOUNT
,COMPANY
,MINOR
,TASK_ORG_ID  
,TASK_ORG_NAME)       -- Added by Veronica on 14-Nov-2013 for defect# 26425 END   	
SELECT pt.task_number,    
pt.task_id,              
pt.task_name,              
GTEMP.expenditure_type,              
--GTEMP.period_name||chr(9)||              
substr(GTEMP.period_name,0,4)||GLPRD.period_year,              
GLPRD.period_num,              
GLPRD.period_year,              
GLPRD.quarter_num,     
GLPRD.effective_period_num,              
pt.wbs_level,              
pp.segment1,     
pp.project_id,              
pp.project_type,              
replace(pp.description,chr(9),''''),               
pp.completion_date,              
pp.attribute1,              
pt.attribute1,              
(SELECT town_or_city FROM hr_locations_all HLA WHERE location_code LIKE                  
DECODE(pt.attribute1,null,pp.attribute1,''010000'',pp.attribute1,pt.attribute1)||''%'' and inactive_date is null AND ROWNUM < 2),                
(SELECT region_2 FROM hr_locations_all HLA WHERE location_code LIKE                  
DECODE(pt.attribute1,null,pp.attribute1,''010000'',pp.attribute1,pt.attribute1)||''%'' and inactive_date is null AND ROWNUM < 2),                
SUM(NVL(GTEMP.capitalized_cost,0)),              
SUM(NVL(GTEMP.capitalizable_cost,0)),              
(SUM(NVL(GTEMP.capitalizable_cost,0)) - SUM(NVL(GTEMP.capitalized_cost,0))),              
account,              
company,              
XX_PA_MONTH_END_BALS_RPT_PKG.XX_PRJ_TSK_MINOR(pp.project_id,pt.task_id),
hou.organization_id, ---added for defect# 24167 by divya sidhaiyan
hou.name     ---added for defect# 24167 by divya sidhaiyan
FROM pa_tasks pt,              
pa_projects_all pp,            
'||v_temp_table_name||' GTEMP,    
(SELECT distinct a.period_year,a.period_num, a.quarter_num,b.period_name,b.effective_period_num   
FROM gl_periods a, gl_period_statuses b   
WHERE b.period_name = a.period_name) GLPRD,
HR_ORGANIZATION_UNITS HOU      ---added for defect# 24167 by divya sidhaiyan
WHERE GTEMP.task_id(+) =pt.task_id        
AND pt.project_id= gtemp.project_id(+)        
AND pt.project_id=pp.project_id         
AND (GTEMP.capitalized_cost <> 0 OR GTEMP.capitalizable_cost <> 0)  
AND GLPRD.period_name = GTEMP.period_name   -- Added as per Defect# 13846         
AND (('''
    ||p_service_type||''' IS NOT NULL AND '''||p_service_type||''' = pt.service_type_code)            
OR            
('''||p_service_type||''' IS NULL) OR ('''||p_service_type||''' = ''ALL''))        
AND (  ('''||p_project_num_from||''' IS NOT NULL AND '''||p_project_num_to||''' IS NOT NULL AND pp.segment1 BETWEEN '''||p_project_num_from||''' AND '''||p_project_num_to||''')               
OR                
('''||p_project_num_from||''' IS NOT NULL AND '''||p_project_num_to||''' IS     NULL AND pp.segment1 >= '''||p_project_num_from||''')               
OR                
('''||p_project_num_from||''' IS     NULL AND '''||p_project_num_to||''' IS NOT NULL AND pp.segment1 <= '''||p_project_num_to||''')               
OR               
('''||p_project_num_from||''' IS     NULL AND '''||p_project_num_to||''' IS     NULL)            
)        

AND (  ('''||p_company||''' IS NOT NULL AND company = '''||p_company||''')               
OR                
('''||p_company||
    ''' IS NULL)            
)        
AND GTEMP.period_name IN (                                  
'||v_prd_query||'         
)          
AND (('''||p_capital_task||''' = ''Y'' AND NVL(pt.BILLABLE_FLAG,''N'') = '''||p_capital_task||''')
OR         
('''||p_capital_task||''' = ''N'' AND NVL(pt.BILLABLE_FLAG,''N'') = '''||p_capital_task||''')     
)        
AND pp.org_id = '||v_profile_value||
    '      
AND pt.carrying_out_organization_id = hou.organization_id  ---added for defect# 24167 by divya sidhaiyan
GROUP BY  pt.task_number,                  
pt.task_id,                
pt.task_name,                  
pt.wbs_level,                 
pp.segment1,                 
pp.project_id,                
pp.project_type,                
pp.project_type,                                
replace(pp.description,chr(9),''''), --defect 5910                
pp.completion_date,                 
pp.attribute1,                 
pt.attribute1,                 
GTEMP.period_name,                
GTEMP.expenditure_type,                
gtemp.account,                
gtemp.company,                
GLPRD.period_num,                                
GLPRD.quarter_num,                
GLPRD.period_year,    
GLPRD.effective_period_num,
hou.organization_id,---added for defect# 24167 by divya sidhaiyan
hou.name ---added for defect# 24167 by divya sidhaiyan
UNION
SELECT pt.task_number,  
pt.task_id,  
pt.task_name,  
GTEMP.expenditure_type,  
--GTEMP.period_name||chr(9)||  
SUBSTR(GTEMP.period_name,0,4)  
||GLPRD.period_year,  
GLPRD.period_num,  
GLPRD.period_year,  
GLPRD.quarter_num,  
GLPRD.effective_period_num,  
pt.wbs_level,  
pp.segment1,  
pp.project_id,  
pp.project_type,  
REPLACE(pp.description,chr(9),''''), --defect 5910  
pp.completion_date,  
pp.attribute1,  
pt.attribute1,  
(SELECT town_or_city  
FROM hr_locations_all HLA  
WHERE location_code LIKE DECODE(pt.attribute1,NULL,pp.attribute1,''010000'',pp.attribute1,pt.attribute1)    
||''%''  
AND inactive_date IS NULL  
AND ROWNUM         < 2  
), --defect 5862  
(SELECT region_2  
FROM hr_locations_all HLA  
WHERE location_code LIKE DECODE(pt.attribute1,NULL,pp.attribute1,''010000'',pp.attribute1,pt.attribute1)    
||''%''  
AND inactive_date IS NULL  
AND ROWNUM         < 2  
), --defect 5862  
SUM(NVL(GTEMP.capitalized_cost,0)),  
SUM(NVL(GTEMP.capitalizable_cost,0)),  
(SUM(NVL(GTEMP.capitalizable_cost,0)) - SUM(NVL(GTEMP.capitalized_cost,0))),  
account,  
company,  
XX_PA_MONTH_END_BALS_RPT_PKG.XX_PRJ_TSK_MINOR(pp.project_id,pt.task_id),
hou.organization_id, ---added for defect# 24167 by divya sidhaiyan
hou.name ---added for defect# 24167 by divya sidhaiyan
FROM pa_tasks pt,  
pa_projects_all pp,  
'||v_temp_table_name||' GTEMP,  
(SELECT DISTINCT a.period_year,    
a.period_num,    
a.quarter_num,    
b.period_name,    
b.effective_period_num  
FROM gl_periods a,    
gl_period_statuses b  
WHERE b.period_name = a.period_name  
) GLPRD,
HR_ORGANIZATION_UNITS HOU ---added for defect# 24167 by divya sidhaiyan
WHERE GTEMP.task_id(+)       =pt.task_id
AND pt.project_id            = gtemp.project_id(+)
AND pt.project_id            =pp.project_id
AND (GTEMP.capitalized_cost <> 0
OR GTEMP.capitalizable_cost <> 0)
AND GLPRD.period_name        = GTEMP.period_name -- Added as per Defect# 13846  
AND EXISTS  
(SELECT 1   
FROM PA_SEGMENT_VALUE_LOOKUPS PAS,       
PA_SEGMENT_VALUE_LOOKUP_SETS S  
WHERE PAS.SEGMENT_VALUE_LOOKUP_SET_ID      = S.SEGMENT_VALUE_LOOKUP_SET_ID  
AND upper(S.segment_value_lookup_set_name) = upper(''SERVICE TYPE TO CIP ACCOUNT'')  
AND SEGMENT_VALUE_LOOKUP                   =pt.service_type_code  
AND '''
    ||p_service_type||'''               = PAS.SEGMENT_VALUE  
)
AND ( ('''||p_project_num_from||''' IS NOT NULL
AND '''||p_project_num_to||'''      IS NOT NULL
AND pp.segment1 BETWEEN '''||p_project_num_from||''' AND '''||p_project_num_to||''')
OR ('''||p_project_num_from||''' IS NOT NULL
AND '''||p_project_num_to||'''   IS NULL
AND pp.segment1                  >= '''||p_project_num_from||''')
OR ('''||p_project_num_from||''' IS NULL
AND '''||p_project_num_to|| '''   IS NOT NULL
AND pp.segment1                  <= '''||p_project_num_to||''')
OR ('''||p_project_num_from||''' IS NULL
AND '''||p_project_num_to||'''   IS NULL) )
AND ( ('''||p_company||'''       IS NOT NULL
AND company                       = '''||p_company||''')
OR ('''||p_company||'''          IS NULL) )
AND GTEMP.period_name            IN ( '||v_prd_query||' )  
AND (('''||p_capital_task||''' = ''Y'' AND NVL(pt.BILLABLE_FLAG,''N'') = '''||p_capital_task||''')
OR ('''||p_capital_task||'''                                                 = ''N''
AND NVL(pt.BILLABLE_FLAG,''N'')                                              = '''||p_capital_task|| ''') )
AND pp.org_id                                                                = '||v_profile_value||' 
AND pt.carrying_out_organization_id = hou.organization_id  ---added for defect# 24167 by divya sidhaiyan
GROUP BY pt.task_number,  
pt.task_id,  
pt.task_name,  
pt.wbs_level,  
pp.segment1,  
pp.project_id,  
pp.project_type,  
pp.project_type,  
REPLACE(pp.description,chr(9),''''), --defect 5910  
pp.completion_date,  
pp.attribute1,  
pt.attribute1,  
GTEMP.period_name,  
GTEMP.expenditure_type,  
gtemp.account,  
gtemp.company,  
GLPRD.period_num,  
GLPRD.quarter_num,  
GLPRD.period_year,  
GLPRD.effective_period_num,
hou.organization_id, ---added for defect# 24167 by divya sidhaiyan
hou.name';  ---added for defect# 24167 by divya sidhaiyan
    EXECUTE IMMEDIATE v_main_query;
    COMMIT;
    drop_table(v_temp_table_name);
    v_out_header := 'TASK NUMBER'||chr(9)||'TASK NAME'||chr(9)||'EXPENDITURE TYPE'||chr(9)||'PERIOD NAME'||chr(9)|| 'PERIOD'||chr(9)||'YEAR'||chr(9)||'QUARTER'||chr(9)|| 'WBS LEVEL'||chr(9)||'PROJECT NUMBER'||chr(9)||'PROJECT TYPE'||chr(9)||'PROJECT DESCRIPTION'||chr(9)|| 'PROJECT TRANSACTION DURATION'||chr(9)||'PROJECT LOCATION NUMBER'||chr(9)||'TASK LOCATION NUMBER'||chr(9)|| 'CITY'||chr(9)||'STATE'||chr(9)||'CAPITALIZED COST'||chr(9)||'CAPITALIZABLE COST'||chr(9)||'CIP COST'||chr(9)||'ACCOUNT'||chr(9)||'COMPANY'||chr(9)||'MINOR'||chr(9)||'ORG ID'||chr(9)||'ORG NAME';  ---added org id and org name for defect# 24167 by divya sidhaiyan
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Period = ' || p_start_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'End Period = ' || p_end_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Capital task = ' || p_capital_task);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Service type = ' || p_service_type);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Project number from = ' || p_project_num_from);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Project number to = ' || p_project_num_to);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Company = ' || p_company);
    i := 0;
    OPEN c_main;
    LOOP
      FETCH c_main BULK COLLECT INTO l_tab LIMIT 1000;
      EXIT
    WHEN l_tab.COUNT = 0;
      FOR c_out_rec IN l_tab.FIRST .. l_tab.LAST
      LOOP
        i   := i + 1;
        IF i = 1 THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, v_out_header);
        END IF;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, l_tab(c_out_rec).task_number||chr(9)|| 
		l_tab(c_out_rec).task_name||chr(9)|| l_tab(c_out_rec).expenditure_type||chr(9)|| 
		l_tab(c_out_rec).period_name||chr(9)|| l_tab(c_out_rec).period_num||chr(9)|| 
		l_tab(c_out_rec).period_year||chr(9)|| 'Q'||l_tab(c_out_rec).quarter_num||chr(9)|| 
		l_tab(c_out_rec).wbs_level||chr(9)|| l_tab(c_out_rec).segment1||chr(9)|| l_tab(c_out_rec).project_type||chr(9)|| 
		l_tab(c_out_rec).description||chr(9)|| l_tab(c_out_rec).completion_date||chr(9)|| 
		l_tab(c_out_rec).project_attribute1||chr(9)|| l_tab(c_out_rec).task_attribute1||chr(9)|| 
		l_tab(c_out_rec).town_or_city||chr(9)|| l_tab(c_out_rec).region_2||chr(9)|| 
		l_tab(c_out_rec).capitalized_cost||chr(9)|| l_tab(c_out_rec).capitalizable_cost||chr(9)|| 
		l_tab(c_out_rec).cip_cost||chr(9)|| l_tab(c_out_rec).ACCOUNT||chr(9)|| l_tab(c_out_rec).company||chr(9)|| 
		l_tab(c_out_rec).MINOR --||chr(9)|| l_tab(c_out_rec).organization_id ||chr(9)|| l_tab(c_out_rec).name ); ---added org id and org name for defect# 24167 by divya sidhaiyan
		||chr(9)|| l_tab(c_out_rec).TASK_ORG_ID ||chr(9)|| l_tab(c_out_rec).TASK_ORG_NAME); ---added task_org_id and task_org_name for defect# 30896 by Kiran Maddala
	  END LOOP;
    END LOOP;
    CLOSE c_main;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'output record count = ' || i);
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR Message' || SQLERRM);
    --drop_table('xx_pa_month_end_temp');
    drop_table(v_temp_table_name);
  END XX_MAIN_GRP_RPT;
  FUNCTION XX_PRJ_TSK_MINOR(
    xx_project_id NUMBER,
    xx_task_id    NUMBER)
  RETURN VARCHAR2
IS
  lc_minor VARCHAR2(50);
BEGIN
  SELECT FA_CAT.SEGMENT2
  INTO lc_minor
  FROM PA_PROJECT_ASSET_ASSIGNMENTS PAL,
    PA_PROJECT_ASSETS_ALL PA_PAL,
    FA_CATEGORIES_B FA_CAT
  WHERE PA_PAL.PROJECT_ASSET_ID = PAL.PROJECT_ASSET_ID
  AND PAL.PROJECT_ID            = PA_PAL.PROJECT_ID
  AND FA_CAT.CATEGORY_ID        = PA_PAL.ASSET_CATEGORY_ID
  AND PAL.PROJECT_ID            = xx_project_id
  AND PAL.TASK_ID               = xx_task_id
  AND rownum                    < 2;
  RETURN lc_minor;
EXCEPTION
WHEN TOO_MANY_ROWS THEN
  RETURN NULL;
WHEN NO_DATA_FOUND THEN
  RETURN NULL;
WHEN OTHERS THEN
  RETURN NULL; --If the assets are project level return NULL as per the requirement
END;
  
  --End modification by Adithya for defect#13846

END XX_PA_MONTH_END_BALS_RPT_PKG;
/
