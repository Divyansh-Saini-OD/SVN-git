SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE BODY XX_PA_CLARITY_EXTRACT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |  Providge Consulting                                                                       |
  -- +============================================================================================+
  -- |  Name:  XX_PA_CLARITY_EXTRACT_PKG                                                          |
  -- |  RICE: I2165                                                                               |
  -- |  Description:  This package extracts Project and Budget information for CLARITY            |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         21-SEP-2011  R.Strauss            Initial version                              |
  -- | 1.1         05-SEP-2013  S.Kirubha            Updated for defect #22892                    |
  -- | 1.2         17-NOV-2015  Harvinder Rakhra     Retrofit R12.2
  -- | 1.3         13-Jun-2018  Priyam Parmar        Updated for NAIT# 38285
  -- | 1.4         03-JUN-2019 	Dinesh N        	 Replaced V$INSTANCE with DB_Name for LNS	  |
  -- | 1.5         03-AUG-2019 	Narendra        	 add supplier number in PA Clarity            |  
  -- | 1.6         25-AUG-2019 	Narendra        	 remove rpad for supplier Name                |    
  -- +============================================================================================+

FUNCTION get_exp_comment(p_exp_item_id IN NUMBER) 
RETURN VARCHAR2 
IS
lc_comment VARCHAR2(250);
BEGIN
  SELECT REPLACE(REPLACE(SUBSTR(expenditure_comment,1,150), CHR(13), ''), CHR(10), '') 
    INTO lc_comment
	FROM pa_expenditure_comments 
   WHERE expenditure_item_id=p_exp_item_id;
  RETURN(lc_comment);
EXCEPTION
  WHEN others THEN  
    lc_comment:=NULL;
	RETURN(lc_comment);
end get_exp_comment;

FUNCTION get_gl_segment_information(
    p_ccid         NUMBER)
  RETURN VARCHAR2
IS
  l_segment  VARCHAR2(100);
 
BEGIN

Begin 
  select segment3||'|'||
    segment4||'|'||
    segment6
  INTO l_segment--Account|LOCATION|LOB
  FROM gl_code_combinations
  where enabled_flag     ='Y'
  and sysdate between nvl(start_date_active,sysdate-1) and nvl(end_date_active,sysdate+1)
  and code_combination_id=p_ccid;
  
exception when others then 

l_segment:='00|000000|00000000';

end ;

return l_segment;
  
END get_gl_segment_information;
  
PROCEDURE EXTRACT_CLARITY_DATA(
    errbuf OUT NOCOPY  VARCHAR2,
    retcode OUT NOCOPY NUMBER,
    p_org_id     IN NUMBER,
    p_proj_name  IN VARCHAR2,
    p_from_date  IN DATE,
    p_to_date    IN DATE,
    p_ftp_flag   IN VARCHAR2,
    p_debug_flag IN VARCHAR2)
IS
  x_error_message  VARCHAR2(2000) DEFAULT NULL;
  x_return_status  VARCHAR2(20) DEFAULT NULL;
  x_msg_count      NUMBER DEFAULT NULL;
  x_msg_data       VARCHAR2(4000) DEFAULT NULL;
  x_return_flag    VARCHAR2(1) DEFAULT NULL;
  gc_error_loc     VARCHAR2(80) DEFAULT NULL;
  lc_org_id        NUMBER := FND_PROFILE.VALUE('ORG_ID');
  lc_instance_name varchar2(09) default null;
  lc_file_rec      VARCHAR2(1300) DEFAULT NULL; -- size has been increased from 800 to 1000 for defect #NAIT-38285
  lc_file_name     VARCHAR2(400) DEFAULT NULL;
  lc_file_path     VARCHAR2(200) := 'XXFIN_OUTBOUND';
  lc_dba_path      VARCHAR2(200) DEFAULT NULL;
  lc_dir_path      VARCHAR2(200) DEFAULT NULL;
  lc_file_handle UTL_FILE.FILE_TYPE;
  lc_req_id       NUMBER DEFAULT NULL;
  lc_wait         BOOLEAN;
  lc_conc_phase   VARCHAR2(200) DEFAULT NULL;
  lc_conc_status  VARCHAR2(200) DEFAULT NULL;
  lc_dev_phase    VARCHAR2(200) DEFAULT NULL;
  lc_dev_status   VARCHAR2(200) DEFAULT NULL;
  lc_conc_message VARCHAR2(400) DEFAULT NULL;
  lc_err_status   VARCHAR2(1) DEFAULT NULL;
  ln_extract_cnt  NUMBER := 0;
  ln_extract_amt  NUMBER := 0;
  lc_comment varchar2(250):=null;
  lc_segment varchar2(100);
  -- ==========================================================================
  -- Clarity Extract 1st cursor
  -- ==========================================================================
  CURSOR project_extract_1_cur
  IS
    SELECT SUBSTR(P.segment1,1,(INSTR(P.segment1,'-',1,1) - 1))                    AS PAN,
      SUBSTR(P.segment1,(INSTR(P.segment1,'-',1,1)        + 1),LENGTH(P.segment1)) AS PAN_EXTENSION,
      TO_CHAR(TO_DATE('01-'
      ||G.GL_PERIOD_NAME,'DD-MON-YY'),'YYYY-MM-DD')     AS PA_PERIOD_DATE,
      SUBSTR(O.NAME,3,5)                                AS COST_CENTER_CODE,
      O.NAME                                            AS COST_CENTER_DESCRIPTION,
      T.TASK_NUMBER                                     AS TASK,
      E.PROJECT_CURRENCY_CODE                           AS CURRENCY_CODE,
      TO_CHAR(E.project_burdened_cost,'999,999,999.99') AS AMOUNT,
      E.project_burdened_cost                           AS AMOUNT_NUM,
      --Changes for defect 22892 starts here
      P.name                  AS PROJECT_NAME,
      T.task_name             AS TASK_NAME,
      e.expenditure_type      AS expenditure_type,
      ET.Expenditure_Category AS EXPENDITURE_CATEGORY,
      --Changes for defect 22892 end here
      --Changes for Defect 38285 Starts here
      NULL AS supplier_name,
      NULL AS supplier_number, ---Added by Narendra NAIT-101969
      null as invoice_num,
      NULL as Invoice_Line_Num,
      null as invoice_date,
      e.expenditure_item_id as expenditure_item_id,
      null expenditure_comments,
      decode(sign(e.project_burdened_cost),1,g.dr_code_combination_id,g.cr_code_combination_id) ccid
       --Changes for Defect 38285 ends here
    FROM HR_ALL_ORGANIZATION_UNITS_TL O,
      PA_PROJECT_TYPES_ALL PT,
      PA_EXPENDITURE_TYPES ET,
      PA_PROJECTS_ALL P,
      PA_TASKS T,
      PA_EXPENDITURE_ITEMS_ALL E,
      PA_COST_DISTRIBUTION_LINES_ALL G
    WHERE 1               =1
    AND G.gl_period_name IN (TO_CHAR(SYSDATE, 'MON-YY'), TO_CHAR(SYSDATE - 30, 'MON-YY'))
    AND G.line_type       = 'R'
    AND G.line_num        =
      (SELECT MAX(line_num)
      FROM PA_COST_DISTRIBUTION_LINES_ALL D
      WHERE D.expenditure_item_id = E.expenditure_item_id
      AND D.line_type             = 'R'
      )
  AND E.expenditure_item_id      = G.expenditure_item_id
  AND E.cc_prvdr_organization_id = O.ORGANIZATION_ID(+)
  AND ((E.transaction_source    IS NULL )
  OR (E.transaction_source NOT LIKE 'AP%'))
  AND t.task_id           = E.task_id
  AND P.project_id        = T.project_id
  AND P.TEMPLATE_FLAG    <> 'Y'
  AND P.segment1          = NVL(p_proj_name,P.segment1)
  AND P.org_id            = lc_org_id
  AND PT.project_type     = P.project_type
  AND PT.direct_flag      = 'N'
  AND ET.Expenditure_type = E.Expenditure_type ----added for defect #22892
  ORDER BY 1,2,3,4,5,6,7;
  CURSOR prj_actual_dtl
  IS
    SELECT SUBSTR(P.segment1,1,(INSTR(P.segment1,'-',1,1) - 1))                    AS PAN,
      SUBSTR(P.segment1,(INSTR(P.segment1,'-',1,1)        + 1),LENGTH(P.segment1)) AS PAN_EXTENSION,
      TO_CHAR(TO_DATE('01-'
      ||G.GL_PERIOD_NAME,'DD-MON-YY'),'YYYY-MM-DD')     AS PA_PERIOD_DATE,
      SUBSTR(O.NAME,3,5)                                AS COST_CENTER_CODE,
      O.NAME                                            AS COST_CENTER_DESCRIPTION,
      T.TASK_NUMBER                                     AS TASK,
      E.PROJECT_CURRENCY_CODE                           AS CURRENCY_CODE,
      TO_CHAR(E.project_burdened_cost,'999,999,999.99') AS AMOUNT,
      E.project_burdened_cost                           AS AMOUNT_NUM,
      --Changes for defect 22892 starts here
      P.name                  AS PROJECT_NAME,
      T.task_name             AS TASK_NAME,
      E.Expenditure_Type      AS EXPENDITURE_TYPE,
      et.expenditure_category AS expenditure_category,
      --Changes for defect 22892 end here
      --Changes for Defect 38285 Starts here
      -- ai.invoice_num,s.segment1,s.vendor_name,pex.expenditure_comment,
      s.vendor_name           AS supplier_name,
      s.segment1              AS supplier_number, ---Added by Narendra NAIT-101969
      ai.invoice_num          as invoice_num,
      ail.line_number         as Invoice_Line_Num,
      TO_CHAR(ai.invoice_date,'YYYY-MM-DD')   as invoice_date,
      e.expenditure_item_id   as expenditure_item_id, 
      replace(replace(substr(ail.description,1,150), chr(13), ''), chr(10), '') as expenditure_comments,
      decode(sign(e.project_burdened_cost),1,g.dr_code_combination_id,g.cr_code_combination_id) ccid
      --Changes for Defect 38285 ends here
    FROM ap_suppliers s,
      ap_invoices_all ai,
      ap_invoice_lines_all ail,
     --- pa_expenditure_comments pex,
      HR_ALL_ORGANIZATION_UNITS_TL O,
      PA_PROJECT_TYPES_ALL PT,
      PA_EXPENDITURE_TYPES ET,
      PA_PROJECTS_ALL P,
      PA_TASKS T,
      PA_EXPENDITURE_ITEMS_ALL E,
      PA_COST_DISTRIBUTION_LINES_ALL G
    WHERE 1               =1
    AND G.gl_period_name IN (TO_CHAR(SYSDATE, 'MON-YY'), TO_CHAR(SYSDATE - 30, 'MON-YY'))
    AND G.line_type       = 'R'
    AND G.line_num        =
      (SELECT MAX(line_num)
      FROM PA_COST_DISTRIBUTION_LINES_ALL D
      WHERE D.expenditure_item_id = E.expenditure_item_id
      AND D.line_type             = 'R'
      )
  AND E.expenditure_item_id      = G.expenditure_item_id
  AND E.cc_prvdr_organization_id = O.ORGANIZATION_ID(+)
  AND E.transaction_source LIKE 'AP%'
  AND t.task_id              = E.task_id
  AND P.project_id           = T.project_id
  AND P.TEMPLATE_FLAG       <> 'Y'
  AND P.segment1             = NVL(p_proj_name,P.segment1)
  AND P.org_id               = lc_org_id
  AND PT.project_type        = P.project_type
  AND PT.direct_flag         = 'N'
  and et.expenditure_type    = e.expenditure_type ----added for defect #22892
   and ai.invoice_id=e.document_header_id
    and ail.invoice_id=ai.invoice_id
    and ail.line_number=e.document_line_number
   and s.vendor_id=ai.vendor_id 
  ORDER BY 1,2,3,4,5,6,7,
    s.segment1,
    ail.description,
    ai.invoice_num;
  -- ==========================================================================
  -- Clarity Extract 2nd cursor
  -- ==========================================================================
  CURSOR project_extract_2_cur
  IS
    SELECT SUBSTR(P.segment1,1,(INSTR(P.segment1,'-',1,1) - 1))                    AS PAN,
      SUBSTR(P.segment1,(INSTR(P.segment1,'-',1,1)        + 1),LENGTH(P.segment1)) AS PAN_EXTENSION,
      TO_CHAR(TRUNC(P.start_date),'YYYY-MM-DD')                                    AS PA_START_DATE,
      NVL(TO_CHAR(P.completion_date,'YYYY-MM-DD'),' ')                             AS PA_FINISH_DATE,
      TO_CHAR(NVL(B01.RAW_COST,0), '999,999,999.99')                               AS BUDGET_EXPENSE_AMOUNT,
      TO_CHAR(NVL(B02.RAW_COST,0), '999,999,999.99')                               AS BUDGET_CAPITAL_AMOUNT,
      TO_CHAR(TO_DATE('01-'
      ||B03.ACCUM_PERIOD,'DD-MON-YY'),'YYYY-MM-DD')          AS PA_PERIOD_DATE,
      TO_CHAR(NVL(B03.CMT_RAW_COST_YTD,0), '999,999,999.99') AS COMMITMENT,
      NVL(B03.cmt_raw_cost_ytd,0)                            AS COMMITMENT_NUM,
      P.PROJECT_CURRENCY_CODE                                AS CURRENCY_CODE
    FROM PA_PROJECTS_ALL P,
      PA_PROJECT_TYPES_ALL PT,
      --*  (Expense)
      (
      SELECT P1.PROJECT_ID,
        B1.RAW_COST
      FROM PA_PROJECTS_ALL P1,
        PA_TASKS T1,
        PA_RESOURCE_ASSIGNMENTS R1,
        PA_BUDGET_LINES B1,
        PA_BUDGET_VERSIONS V1
      WHERE P1.PROJECT_ID           = T1.PROJECT_ID
      AND T1.PROJECT_ID             = R1.PROJECT_ID
      AND T1.TASK_ID                = R1.TASK_ID
      AND R1.RESOURCE_ASSIGNMENT_ID = B1.RESOURCE_ASSIGNMENT_ID
      AND B1.BUDGET_VERSION_ID      = V1.BUDGET_VERSION_ID
      AND V1.CURRENT_FLAG           = 'Y'
      AND T1.TASK_NUMBER            = '01'
      AND NOT EXISTS
        (SELECT 'Y'
        FROM PA_PROJECTS_ALL P1A
        WHERE P1A.PROJECT_ID        = P1.PROJECT_ID
        AND P1A.PROJECT_STATUS_CODE = 'CLOSED'
        AND P1A.CLOSED_DATE         < SYSDATE - 180
        )
    ORDER BY P1.PROJECT_ID
      ) B01,
      --*  (Capital)
      (
      SELECT P2.PROJECT_ID,
        B2.RAW_COST
      FROM PA_PROJECTS_ALL P2,
        PA_TASKS T2,
        PA_RESOURCE_ASSIGNMENTS R2,
        PA_BUDGET_LINES B2,
        PA_BUDGET_VERSIONS V2
      WHERE P2.PROJECT_ID           = T2.PROJECT_ID
      AND T2.PROJECT_ID             = R2.PROJECT_ID
      AND T2.TASK_ID                = R2.TASK_ID
      AND R2.RESOURCE_ASSIGNMENT_ID = B2.RESOURCE_ASSIGNMENT_ID
      AND B2.BUDGET_VERSION_ID      = V2.BUDGET_VERSION_ID
      AND V2.CURRENT_FLAG           = 'Y'
      AND T2.TASK_NUMBER            = '02'
      AND NOT EXISTS
        (SELECT 'Y'
        FROM PA_PROJECTS_ALL P2A
        WHERE P2A.PROJECT_ID        = P2.PROJECT_ID
        AND P2A.PROJECT_STATUS_CODE = 'CLOSED'
        AND P2A.CLOSED_DATE         < SYSDATE - 180
        )
      ORDER BY P2.PROJECT_ID
      ) B02,
      --*  (Commitment)
      (
      SELECT P3.PROJECT_ID,
        H3.ACCUM_PERIOD,
        C3.CMT_RAW_COST_YTD
      FROM PA_PROJECTS_ALL P3,
        PA_PROJECT_ACCUM_HEADERS H3,
        PA_PROJECT_ACCUM_COMMITMENTS C3
      WHERE P3.PROJECT_ID            = H3.PROJECT_ID
      AND H3.PROJECT_ACCUM_ID        = C3.PROJECT_ACCUM_ID
      AND H3.TASK_ID                 = 0
      AND H3.RESOURCE_LIST_MEMBER_ID = 0
      AND NOT EXISTS
        (SELECT 'Y'
        FROM PA_PROJECTS_ALL P3A
        WHERE P3A.PROJECT_ID        = P3.PROJECT_ID
        AND P3A.PROJECT_STATUS_CODE = 'CLOSED'
        AND P3A.CLOSED_DATE         < SYSDATE - 180
        )
      ORDER BY P3.PROJECT_ID
      ) B03
    WHERE P.project_id   = B01.project_id(+)
    AND P.project_id     = B02.project_id(+)
    AND P.project_id     = B03.project_id(+)
    AND P.project_type   = PT.project_type
    AND P.TEMPLATE_FLAG <> 'Y'
    AND PT.direct_flag   = 'N'
    AND P.segment1       = NVL(p_proj_name,P.segment1)
      AND P.org_id       = lc_org_id
      AND NOT EXISTS
        (SELECT 'Y'
        FROM PA_PROJECTS_ALL P3
        WHERE P3.PROJECT_ID        = P.PROJECT_ID
        AND P3.PROJECT_STATUS_CODE = 'CLOSED'
        AND P3.CLOSED_DATE         < SYSDATE - 180
        )
        --*
      ORDER BY P.SEGMENT1;
      -- ==========================================================================
      -- Main Process
      -- ==========================================================================
    BEGIN
      gc_error_loc := 'Clarity Extract 1000- Main Process';
      lc_org_id    := NVL(p_org_id,lc_org_id);
      FND_FILE.PUT_LINE(fnd_file.log,'XX_PA_CLARITY_EXTRACT_PKG.EXTRACT_CLARITY_DATA START - parameters:      ');
      FND_FILE.PUT_LINE(fnd_file.log,'                                                 ORG_ID         = '||lc_org_id);
      FND_FILE.PUT_LINE(fnd_file.log,'                                                 PROJECT_NAME   = '||p_proj_name);
      FND_FILE.PUT_LINE(fnd_file.log,'                                                 FROM DATE      = '||p_from_date);
      FND_FILE.PUT_LINE(fnd_file.log,'                                                 TO DATE        = '||p_to_date);
      FND_FILE.PUT_LINE(fnd_file.log,'                                                 FTP_FLAG       = '||p_ftp_flag);
      FND_FILE.PUT_LINE(fnd_file.log,'                                                 DEBUG_FLAG     = '||p_debug_flag);
      FND_FILE.PUT_LINE(fnd_file.log,' ');
      BEGIN
        --SELECT name INTO lc_instance_name FROM v$database;
		SELECT SUBSTR(SYS_CONTEXT('USERENV','DB_NAME'),1,8) 		-- Changed from V$instance to DB_NAME
		INTO lc_instance_name
		FROM dual;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lc_err_status := 'E';
        FND_FILE.PUT_LINE(fnd_file.log,'Error (1) - NO_DATA_FOUND, loc = '||gc_error_loc);
      WHEN OTHERS THEN
        lc_err_status := 'E';
        FND_FILE.PUT_LINE(fnd_file.log,'Error (1) - Others, loc = '||gc_error_loc||' SQLERRM = '||SQLERRM);
      END;
      FND_FILE.PUT_LINE(fnd_file.log,'                                                 INSTANCE       = '||lc_instance_name);
      FND_FILE.PUT_LINE(fnd_file.log,' ');
      -- ==========================================================================
      -- FIRST EXTRACT
      -- ==========================================================================
      gc_error_loc := 'Clarity Extract 2000- EXTRACT START';
      BEGIN
        FND_FILE.PUT_LINE(fnd_file.log,'Starting first Clarity Extract');
        IF p_debug_flag = 'Y' THEN
          FND_FILE.PUT_LINE(fnd_file.log,'DEBUG: 1. Clarity Extract #1, preprocessing '||gc_error_loc);
        END IF;
        BEGIN
          SELECT directory_path
          INTO lc_dba_path
          FROM dba_directories
          WHERE directory_name = lc_file_path;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lc_err_status := 'E';
          FND_FILE.PUT_LINE(fnd_file.log,'Error (2) - NO_DATA_FOUND, loc = '||gc_error_loc);
        WHEN OTHERS THEN
          lc_err_status := 'E';
          FND_FILE.PUT_LINE(fnd_file.log,'Error (2) - Others, loc = '||gc_error_loc||' SQLERRM = '||SQLERRM);
        END;
        lc_file_name   := 'OD_PA_CLARITY_EXTRACT_PROJECTS_'||lc_instance_name||'_'||TO_CHAR(sysdate,'MMDDYYYY')||'.csv';
        lc_file_handle := UTL_FILE.FOPEN(lc_file_path, lc_file_name, 'W');
        lc_file_rec    := '1'||'|'|| 'PAN  '||'|'|| 'PAN_EXTENSION'||'|'|| 'PA_PERIOD_DATE'||'|'|| 'TASK                     '||'|'|| 
        'COST_CENTER_CODE'||'|'|| 'COST_CENTER_DESCRIPTION                                          '||'|'|| 
        'AMOUNT               '||'|'|| 'CURRENCY'||'|'|| 'DATA_SOURCE'||'|'||
        --Changes for defect #22892 starts here
        'EXPENDITURE_TYPE' ||'|'|| 'EXPENDITURE_CATEGORY' ||'|'|| 'PROJECT_NAME' ||'|'|| 'TASK_NAME'||'|'||
        --Changes for defect #22892 ends here
        --Changes for Defect 38285
        'SUPPLIER_NAME'||'|'|| 'SUPPLIER_NUMBER'||'|'|| 'INVOICE_DATE'||'|'|| 'INVOICE#'||'|'||'INVOICE_LINE_NUM'||'|'||'EXPENDITURE_ITEM_ID'||'|'||
        'EXPENDITURE_COMMENTS'||'|'||'ACCOUNT'||'|'||'LOCATION'||'|'||'LOB';
        ---Added by Narendra NAIT-101969
        --Changes for Defect 38285
        UTL_FILE.PUT_LINE(lc_file_handle, lc_file_rec);
      EXCEPTION
      WHEN OTHERS THEN
        lc_err_status := 'E';
        FND_FILE.PUT_LINE(fnd_file.log,'Error (3) - Others, loc = '||gc_error_loc||' SQLERRM = '||SQLERRM);
      END;
      FND_FILE.PUT_LINE(fnd_file.log,'Extracting Clarity data #1, file = '||lc_file_name);
      FOR project_rec IN project_extract_1_cur
      LOOP
        BEGIN
          gc_error_loc   := 'Clarity Extract 2200- EXTRACT LOOP';
          lc_segment:=null;
          lc_segment:=get_gl_segment_information(project_rec.ccid) ;

          IF p_debug_flag = 'Y' THEN
            fnd_file.put_line(fnd_file.log,'DEBUG: 2. Extract 1: '|| project_rec.pan||'|'|| 
            project_rec.pan_extension||'|'|| project_rec.pa_period_date||'|'|| 
            project_rec.task||'|'|| project_rec.cost_center_code||'|'|| 
            project_rec.cost_center_description||'|'|| 
            project_rec.amount||'|'|| project_rec.currency_code||'|'||
            --Changes for defect #22892 starts here
            project_rec.expenditure_type||'|'|| project_rec.expenditure_category||'|'|| project_rec.project_name||'|'|| 
            project_rec.Task_name||'|'||
            --Changes for defect #22892 ends here
            --Changes for Defect 38285 Starts here
            project_rec.supplier_name||'|'||
            project_rec.supplier_number||'|'|| ---Added by Narendra NAIT-101969
            project_rec.invoice_date||'|'|| 
            project_rec.invoice_num||'|'|| 
            project_rec.invoice_line_num||'|'||
            project_rec.EXPENDITURE_ITEM_ID||'|'||
            project_rec.expenditure_comments||'|'||
           lc_segment||'|'||
            --Changes for Defect 38285 Starts here
            ln_extract_cnt||'|'|| ln_extract_amt||'|');
          END IF;
		  lc_comment:=NULL;
		  lc_comment:=get_exp_comment(project_rec.expenditure_item_id);
          lc_file_rec := '2'||'|'|| rpad(project_rec.pan,5,' ')||'|'|| 
          rpad(project_rec.pan_extension,13,' ')||'|'|| 
          RPAD(project_rec.pa_period_date,14,' ')||'|'|| 
          rpad(project_rec.task,25,' ')||'|'|| 
          rpad(project_rec.cost_center_code,16,' ')||'|'|| 
          RPAD(project_rec.cost_center_description,65,' ')||'|'|| 
          lpad(project_rec.amount,21,' ')||'|'|| 
          rpad(project_rec.currency_code,8,' ')||'|'||
          'PA         '||'|'||
          --Changes for defect #22892 starts here
          rpad(project_rec.expenditure_type,30,' ')||'|'|| 
          rpad(project_rec.expenditure_category,30,' ')||'|'|| 
          rpad(project_rec.project_name,30,' ')||'|'|| 
          rpad(project_rec.task_name,30,' ')||'|'||
          --Changes for defect #22892 ends here
          --Changes for Defect 38285 Starts here
          rpad(project_rec.supplier_name,65,' ')||'|'||
          rpad(project_rec.supplier_number,30,' ')||'|'|| ---Added by Narendra NAIT-101969
          rpad(project_rec.invoice_date,30,' ')||'|'|| 
          rpad(project_rec.invoice_num,30,' ')||'|'||
          rpad(project_rec.invoice_line_num,10,' ')||'|'||
          rpad(project_rec.expenditure_item_id,15,' ')||'|'||
          lc_comment||'|'||lc_segment
          --Changes for Defect 38285 Starts here
           ;
          UTL_FILE.PUT_LINE(lc_file_handle, lc_file_rec);
          ln_extract_cnt := ln_extract_cnt + 1;
          ln_extract_amt := ln_extract_amt + project_rec.amount_num;
        exception
        
        WHEN OTHERS THEN
          lc_err_status := 'E';
          FND_FILE.PUT_LINE(fnd_file.log,'Error (4) - Others, loc = '||gc_error_loc||' SQLERRM = '||SQLERRM);
        END;
      END LOOP;
      FOR project_dtl IN prj_actual_dtl
      LOOP
        BEGIN
          gc_error_loc   := 'Clarity Extract 2200- EXTRACT LOOP';
          lc_segment:=null;
          lc_segment:=get_gl_segment_information(project_dtl.ccid) ;

          IF p_debug_flag = 'Y' THEN
            fnd_file.put_line(fnd_file.log,'DEBUG: 2. Extract 1: '|| project_dtl.pan||'|'|| project_dtl.pan_extension||'|'|| 
            project_dtl.pa_period_date||'|'|| project_dtl.task||'|'|| 
            project_dtl.cost_center_code||'|'|| project_dtl.cost_center_description||'|'|| 
            project_dtl.amount||'|'|| project_dtl.currency_code||'|'||
            --Changes for defect #22892 starts here
            project_dtl.expenditure_type||'|'|| project_dtl.expenditure_category||'|'|| project_dtl.project_name||'|'|| 
            project_dtl.Task_name||'|'||
            --Changes for defect #22892 ends here
            --Changes for Defect 38285 Starts here
            project_dtl.supplier_name||'|'||
            project_dtl.supplier_number||'|'||---Added by Narendra NAIT-101969 
            project_dtl.invoice_date||'|'|| 
            project_dtl.invoice_num||'|'|| 
            project_dtl.invoice_line_num||'|'|| 
            project_dtl.EXPENDITURE_ITEM_ID||'|'||
            project_dtl.expenditure_comments||'|'||
             lc_segment||'|'||
            --Changes for Defect 38285 Starts here
            ln_extract_cnt||'|'|| ln_extract_amt||'|');
          END IF;
          lc_file_rec := '2'||'|'|| rpad(project_dtl.pan,5,' ')||'|'|| rpad(project_dtl.pan_extension,13,' ')||'|'|| rpad(project_dtl.pa_period_date,14,' ')||'|'|| rpad(project_dtl.task,25,' ')||'|'|| rpad(project_dtl.cost_center_code,16,' ')||'|'|| rpad(project_dtl.cost_center_description,65,' ')||'|'|| lpad(project_dtl.amount,21,' ')||'|'|| 
          rpad(project_dtl.currency_code,8,' ')||'|'||'PA         '||'|'||
          --Changes for defect #22892 starts here
          RPAD(project_dtl.expenditure_type,30,' ')||'|'|| RPAD(project_dtl.expenditure_Category,30,' ')||'|'|| rpad(project_dtl.project_name,30,' ')||'|'|| rpad(project_dtl.task_name,30,' ')||'|'||
          --Changes for defect #22892 ends here
          --Changes for Defect 38285 Starts here
          rpad(project_dtl.supplier_name,65,' ')||'|'|| 
          rpad(project_dtl.supplier_number,30,' ')||'|'||---Added by Narendra NAIT-101969
          rpad(project_dtl.invoice_date,30,' ')||'|'|| 
          rpad(project_dtl.invoice_num,30,' ')||'|'|| 
          rpad(project_dtl.invoice_line_num,10,' ')||'|'||
          rpad(project_dtl.expenditure_item_id,15,' ')||'|'||
          project_dtl.expenditure_comments||'|'||
          lc_segment
          --Changes for Defect 38285 Starts here
           ;
          UTL_FILE.PUT_LINE(lc_file_handle, lc_file_rec);
          ln_extract_cnt := ln_extract_cnt + 1;
          ln_extract_amt := ln_extract_amt + project_dtl.amount_num;
        EXCEPTION
        WHEN OTHERS THEN
          lc_err_status := 'E';
          FND_FILE.PUT_LINE(fnd_file.log,'Error (4) - Others, loc = '||gc_error_loc||' SQLERRM = '||SQLERRM);
        END;
      END LOOP;
      UTL_FILE.FCLOSE(lc_file_handle);
      COMMIT;
      FND_FILE.PUT_LINE(fnd_file.log,'Finished first Clarity extract, records created = '||ln_extract_cnt||' amount = '||ln_extract_amt);
      ln_extract_cnt := 0;
      ln_extract_amt := 0;
      -- ==========================================================================
      -- COPY FIRST EXTRACT FOR FTP
      -- ==========================================================================
      gc_error_loc := 'Clarity Extract 3000- EXTRACT 1 FILE COPY';
      IF p_ftp_flag = 'Y' THEN
        lc_req_id  := FND_REQUEST.SUBMIT_REQUEST ('XXFIN' ,'XXCOMFILCOPY' ,'' ,SYSDATE ,FALSE ,lc_dba_path||'/'||lc_file_name ,'$XXFIN_DATA/ftp/out/projects/'||lc_file_name ,'' ,'');
        COMMIT;
        IF lc_req_id > 0 THEN
          lc_wait   := fnd_concurrent.wait_for_request (lc_req_id ,10 ,0 ,lc_conc_phase ,lc_conc_status ,lc_dev_phase ,lc_dev_status ,lc_conc_message);
        END IF;
        IF trim(lc_conc_status) = 'Error' THEN
          lc_err_status        := 'E' ;
          FND_FILE.PUT_LINE(fnd_file.log,'ERROR (5) - 1st File Copy of '||lc_file_name||' Failed, request_id = '||lc_req_id);
        ELSE
          FND_FILE.PUT_LINE(fnd_file.log,'Finished copying first Clarity extract output file for FTP');
        END IF;
      ELSE
        FND_FILE.PUT_LINE(fnd_file.log,'Not copying first Clarity extract output file for FTP due to parm');
      END IF;
      -- ==========================================================================
      -- SECOND EXTRACT
      -- ==========================================================================
      gc_error_loc := 'Clarity Extract 4000- EXTRACT START';
      BEGIN
        FND_FILE.PUT_LINE(fnd_file.log,'Starting second Clarity Extract');
        IF p_debug_flag = 'Y' THEN
          FND_FILE.PUT_LINE(fnd_file.log,'DEBUG: 3. Clarity Extract #2, preprocessing '||gc_error_loc);
        END IF;
        BEGIN
          SELECT directory_path
          INTO lc_dba_path
          FROM dba_directories
          WHERE directory_name = lc_file_path;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lc_err_status := 'E';
          FND_FILE.PUT_LINE(fnd_file.log,'Error (6) - NO_DATA_FOUND, loc = '||gc_error_loc||' SQLERRM = '||SQLERRM);
        WHEN OTHERS THEN
          lc_err_status := 'E';
          FND_FILE.PUT_LINE(fnd_file.log,'Error (6) - Others, loc = '||gc_error_loc||' SQLERRM = '||SQLERRM);
        END;
        lc_file_name   := 'OD_PA_CLARITY_EXTRACT_BUDGET_'||lc_instance_name||'_'||TO_CHAR(sysdate,'MMDDYYYY')||'.csv';
        lc_file_handle := UTL_FILE.FOPEN(lc_file_path, lc_file_name, 'W');
        lc_file_rec    := '1'||'|'|| 'PAN  '||'|'|| 'PAN_EXTENSION'||'|'|| 'PA_START_DATE'||'|'|| 'PA_FINISH_DATE'||'|'|| 'BUDGET_CAPITAL_AMOUNT'||'|'|| 'BUDGET_EXPENSE_AMOUNT'||'|'|| 'PA_PERIOD_DATE'||'|'|| 'COMMITMENT           '||'|'|| 'CURRENCY'||'|'|| 'BUDGET_PRE_PAID';
        UTL_FILE.PUT_LINE(lc_file_handle, lc_file_rec);
      EXCEPTION
      WHEN OTHERS THEN
        lc_err_status := 'E';
        FND_FILE.PUT_LINE(fnd_file.log,'Error (7) - Others, loc = '||gc_error_loc||' SQLERRM = '||SQLERRM);
      END;
      FND_FILE.PUT_LINE(fnd_file.log,'Extracting Clarity data #2, file = '||lc_file_name);
      FOR budget_rec IN project_extract_2_cur
      LOOP
        BEGIN
          gc_error_loc   := 'Clarity Extract 4200- EXTRACT LOOP';
          IF p_debug_flag = 'Y' THEN
            FND_FILE.PUT_LINE(fnd_file.log,'DEBUG: 4. Extract 2: '|| budget_rec.pan||'|'|| budget_rec.pan_extension||'|'|| budget_rec.pa_start_date||'|'|| budget_rec.pa_finish_date||'|'|| budget_rec.budget_capital_amount||'|'|| budget_rec.budget_expense_amount||'|'|| budget_rec.pa_period_date||'|'|| budget_rec.commitment||'|'|| budget_rec.currency_code||'|'|| ln_extract_cnt||'|'|| ln_extract_amt||'|');
          END IF;
          lc_file_rec := '2'||'|'|| RPAD(budget_rec.pan,5,' ')||'|'|| RPAD(budget_rec.pan_extension,13,' ')||'|'|| RPAD(budget_rec.pa_start_date,13,' ')||'|'|| RPAD(NVL(budget_rec.pa_finish_date,' '),14,' ')||'|'|| LPAD(budget_rec.budget_capital_amount,21,' ')||'|'|| LPAD(budget_rec.budget_expense_amount,21,' ')||'|'|| RPAD(budget_rec.pa_period_date,14,' ')||'|'|| LPAD(budget_rec.commitment,21,' ')||'|'|| RPAD(budget_rec.currency_code,8,' ')||'|';
          UTL_FILE.PUT_LINE(lc_file_handle, lc_file_rec);
          ln_extract_cnt := ln_extract_cnt + 1;
          ln_extract_amt := ln_extract_amt + budget_rec.commitment_num;
        EXCEPTION
        WHEN OTHERS THEN
          lc_err_status := 'E';
          FND_FILE.PUT_LINE(fnd_file.log,'Error (8) - Others, loc = '||gc_error_loc||' SQLERRM = '||SQLERRM);
        END;
      END LOOP;
      UTL_FILE.FCLOSE(lc_file_handle);
      COMMIT;
      FND_FILE.PUT_LINE(fnd_file.log,'Finished second Clarity extract, records created = '||ln_extract_cnt||' amount = '||ln_extract_amt);
      -- ==========================================================================
      -- COPY SECOND EXTRACT FOR FTP
      -- ==========================================================================
      gc_error_loc := 'Clarity Extract 5000- EXTRACT 2 FILE COPY';
      IF p_ftp_flag = 'Y' THEN
        lc_req_id  := FND_REQUEST.SUBMIT_REQUEST ('XXFIN' ,'XXCOMFILCOPY' ,'' ,SYSDATE ,FALSE ,lc_dba_path||'/'||lc_file_name ,'$XXFIN_DATA/ftp/out/projects/'||lc_file_name ,'' ,'');
        COMMIT;
        IF lc_req_id > 0 THEN
          lc_wait   := fnd_concurrent.wait_for_request (lc_req_id ,10 ,0 ,lc_conc_phase ,lc_conc_status ,lc_dev_phase ,lc_dev_status ,lc_conc_message);
        END IF;
        IF trim(lc_conc_status) = 'Error' THEN
          lc_err_status        := 'E' ;
          FND_FILE.PUT_LINE(fnd_file.log,'ERROR (9) - 2nd File Copy of '||lc_file_name||' Failed, request_id = '||lc_req_id);
        ELSE
          FND_FILE.PUT_LINE(fnd_file.log,'Finished copying second Clarity extract output file for FTP');
        END IF;
      ELSE
        FND_FILE.PUT_LINE(fnd_file.log,'Not copying second Clarity extract output file for FTP due to parm');
      END IF;
      -- ==========================================================================
      -- EXTRACT COMPLETE
      -- ==========================================================================
      FND_FILE.PUT_LINE(fnd_file.log,'Project Accounting - Clarity extract processing - Completed, status = '||lc_err_status);
      IF lc_err_status = 'W' THEN
        retcode       := 1;
      ELSE
        IF lc_err_status = 'E' THEN
          retcode       := 2;
        ELSE
          retcode := 0;
        END IF;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      retcode := 2;
      FND_FILE.PUT_LINE(fnd_file.log,'Error (final) - Others, loc = '||gc_error_loc||' SQLERRM = '||SQLERRM);
      XX_COM_ERROR_LOG_PUB.LOG_ERROR ( p_program_type => 'CONCURRENT PROGRAM' ,p_program_name => '' ,p_program_id => FND_GLOBAL.CONC_PROGRAM_ID ,p_module_name => 'AR' ,p_error_location => 'Error at OTHERS' ,p_error_message_count => 1 ,p_error_message_code => 'E' ,p_error_message => 'OTHERS' ,p_error_message_severity => 'Major' ,p_notify_flag => 'N' ,p_object_type => 'PA Clarity Extract' );
    END EXTRACT_CLARITY_DATA;
  END XX_PA_CLARITY_EXTRACT_PKG ;
/
SHOW ERROR;
 