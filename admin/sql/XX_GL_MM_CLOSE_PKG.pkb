SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package  XX_GL_MM_CLOSE_PKG

Prompt Program Exits If The Creation Is Not Successful

WHENEVER SQLERROR CONTINUE
create or replace 
PACKAGE BODY  XX_GL_MM_CLOSE_PKG

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             : XX_GL_MM_CLOSE_PKG                          |
-- | Description      : This Program contains procedures which run for the   |
-- |                   Midmonth Financial Project                                   |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    20-Mar-2015   Madhu Bolli       Initial code                  |
-- |    1.1    26-Aug-2015   Madhu Bolli       Defect#35660 - functional Currency  |
-- +=========================================================================+   
AS

  --=================================================================
  -- INITIALIZING Global variables
  --=================================================================
  g_user_id               NUMBER        := fnd_global.user_id;
  g_fin_gl_shift1_cp_name VARCHAR2(30)  := 'XXOD_FIN_GL_CAL_SHFT_1';
  g_is_shift1_exe_qry VARCHAR2(1000)  := 'SELECT count(1) FROM XX_GL_MM_CTL_TBL  xgmct WHERE req_status_code = ''S'' AND xgmct.program_id in (SELECT concurrent_program_id FROM FND_CONCURRENT_PROGRAMS WHERE concurrent_program_name = :1)';


  PROCEDURE ins_ctrl_tbl_rec(p_program_name IN VARCHAR2
                            ,x_errbuf      	OUT NOCOPY VARCHAR2
                            ,x_retcode     	OUT NOCOPY VARCHAR2
                            )
  IS
    l_proc_name         VARCHAR2(30) := 'ins_ctrl_tbl_rec';
    l_program_id        NUMBER;
  
  BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'BEGIN - '||l_proc_name);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'p_program_name - '||p_program_name);

      SELECT concurrent_program_id  into l_program_id
      FROM FND_CONCURRENT_PROGRAMS
      WHERE concurrent_program_name = p_program_name;
      
      FND_FILE.PUT_LINE(FND_FILE.LOG,'l_program_id - '||l_program_id);      
            
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserting the record into Control table XX_GL_MM_CTL_TBL');
                        INSERT into XX_GL_MM_CTL_TBL(PROGRAM_NAME,
                                      PROGRAM_ID,
                                      REQUEST_ID,
                                      REQ_STATUS_CODE, 
                                      CREATION_DATE,          
                                      CREATED_BY,    
                                      LAST_UPDATE_LOGIN,
                                      LAST_UPDATE_DATE,          
                                      LAST_UPDATED_BY) 
                          VALUES ( p_program_name
                                  ,l_program_id
                                  ,fnd_global.conc_request_id
                                  ,'S'
                                  ,sysdate
                                  ,g_user_id
                                  ,g_user_id
                                  ,sysdate
                                  ,g_user_id);
      x_retcode := 0;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserted succesfully into the Control table XX_GL_MM_CTL_TBL');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'END - '||l_proc_name);
      EXCEPTION
          WHEN OTHERS THEN
              x_retcode := 2;
              x_errbuf  := 'Control table insertion failed in '||l_proc_name||' - '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);
              FND_FILE.PUT_LINE(FND_FILE.LOG, x_errbuf);    
  END;  
  
  PROCEDURE shift_fin_gl_cal ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_account_cal		IN  VARCHAR2
				    ,p_acq_period	IN  VARCHAR2
				    ,p_od_last_day		IN  VARCHAR2
				    ,p_next_period		IN  VARCHAR2
				    ,p_next_per_start_date		IN  VARCHAR2
            ,p_us_ledger      IN  NUMBER
            ,p_can_ledger     IN  NUMBER
            ,p_ledger_set     IN  NUMBER
            ,p_is_preview     IN  VARCHAR2
	    		)
  IS

      CURSOR c_list_gl_per_apps(c_acq_period VARCHAR2, c_us_ledger NUMBER, c_can_ledger NUMBER, c_ledger_set NUMBER) IS
        SELECT application_name
        FROM fnd_application_vl
        WHERE application_id in (
            select distinct application_id from gl_period_statuses
            where Set_of_books_id  in (c_us_ledger, c_can_ledger, c_ledger_set)
                        AND period_name    = c_acq_period
                    ); 
                
      l_proc_name  VARCHAR2(50) := 'shift_fin_gl_cal';
      l_errbuf    VARCHAR2(2000) := NULL;
      l_retcode   VARCHAR2(1) := '0'; 
      
      l_od_last_day DATE;
      l_next_per_start_date DATE;
      
      l_gl_periods_end_dat_cnt      NUMBER := 0;
      l_gl_periods_start_dat_cnt    NUMBER := 0;
      l_is_gl_per_upd_complete      VARCHAR2(1) := 'N';
      
      l_gl_period_stat_start_dat_cnt NUMBER := 0;
      l_gl_period_stat_end_dat_cnt   NUMBER := 0;
      
      l_program_id                   NUMBER := NULL;
      l_cp_exec_cnt                  NUMBER;
      l_ledger_exist                 NUMBER;
      
      l_acq_per_cur_end_date         DATE;
      l_nxt_per_cur_start_date       DATE;
      l_org_cnt                      NUMBER;
            
  BEGIN
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'BEGIN Procedure - :'||l_proc_name||' ...');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_account_cal           :   '||p_account_cal);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_acq_period            :   '||p_acq_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_od_last_day           :   '||p_od_last_day);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_next_period           :   '||p_next_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_next_per_start_date   :   '||p_next_per_start_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_us_ledger             :   '||p_us_ledger);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_can_ledger            :   '||p_can_ledger);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_ledger_set            :   '||p_ledger_set);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_is_preview            :   '||p_is_preview);
    
    l_od_last_day := FND_DATE.CANONICAL_TO_DATE (p_od_last_day);
    l_next_per_start_date := FND_DATE.CANONICAL_TO_DATE (p_next_per_start_date);


    
    --  Validate input parameters
          l_ledger_exist := 0;
          select count(1) INTO l_ledger_exist from gl_ledgers where short_name = 'US_USD_P' and ledger_id = p_us_ledger;
          
          IF l_ledger_exist <= 0 THEN              
              l_retcode := 2;
              l_errbuf  :=  'The input value for parmeter ''US Ledger''  is incorrect for the US';
              FND_FILE.PUT_LINE(FND_FILE.LOG, l_errbuf);          
          END IF;
          
          l_ledger_exist := 0;
          select count(1) INTO l_ledger_exist from gl_ledgers where short_name = 'CA_CAD_P' and ledger_id = p_can_ledger;

          IF l_ledger_exist <= 0 THEN              
              l_retcode := 2;
              l_errbuf  :=  'The input value for parmeter ''CA Ledger''  is incorrect for the Canada';
              FND_FILE.PUT_LINE(FND_FILE.LOG, l_errbuf);          
          END IF;          
          
          l_ledger_exist := 0;
          select count(1)  INTO l_ledger_exist from gl_ledgers where short_name = 'OD_ALL_LEDGERS' and ledger_id = p_ledger_set;

          IF l_ledger_exist <= 0 THEN              
              l_retcode := 2;
              l_errbuf  :=  'The input value for parmeter ''Ledger Set''  is incorrect for the Ledger Set';
              FND_FILE.PUT_LINE(FND_FILE.LOG, l_errbuf);          
          END IF;  

      -- CP Output
      
      SELECT end_date INTO l_acq_per_cur_end_date FROM gl_periods WHERE period_set_name = p_account_cal AND period_name = p_acq_period and rownum <= 1;
      
      SELECT start_date INTO l_nxt_per_cur_start_date FROM gl_periods WHERE period_set_name = p_account_cal AND period_name = p_next_period and rownum <= 1;
      
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Name                  :   OD: FIN GL Calendar Shift - Stage1');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Accounting Calendar          :   '||p_account_cal);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period of Acquisition        :   '||p_acq_period);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current Period-End Date      :   '||l_acq_per_cur_end_date);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current Period New End Date  :   '||l_od_last_day);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Next Period Start Date       :   '||l_nxt_per_cur_start_date);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Next Period New Start Date   :   '||l_next_per_start_date);

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Applications Impacted:');
      
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Sl.No       Application Name');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----       -----------------');
      l_org_cnt := 0;
      FOR app in c_list_gl_per_apps(p_acq_period, p_us_ledger, p_can_ledger, p_ledger_set) LOOP
          l_org_cnt :=  l_org_cnt + 1;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_org_cnt||'.          '||app.application_name);      
      END LOOP;                      

    -- Validations 
    -- Validate whether this CP executed already or not  
    /**
    IF l_retcode = 0 THEN 
        l_retcode     := 0;
        l_cp_exec_cnt := 0;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt USING g_fin_gl_shift1_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
          
        IF  l_cp_exec_cnt >= 1 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'The CP "OD: FIN GL Calendar Shift - Stage1" is already executed');
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN GL Calendar Shift - Stage1" is already executed';
        END IF;    
    END IF;  
    **/
    FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is '||l_retcode);  
    
    IF  (p_is_preview = 'N' and l_retcode = 0) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Final Update to the Tables');
          
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column gl_periods.end_date');
        UPDATE gl_periods
        SET end_date       = l_od_last_day,
          last_update_date = sysdate,
          last_updated_by= g_user_id
        WHERE period_set_name = p_account_cal
        AND period_name       = p_acq_period;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column gl_periods.end_date');
        
        IF SQL%NOTFOUND THEN
          l_retcode := 2;	
          l_errbuf  :='Error while updating gl_periods.end_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
        ELSIF SQL%FOUND THEN
          l_gl_periods_end_dat_cnt := SQL%ROWCOUNT;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for gl_periods.end_date is :'||l_gl_periods_end_dat_cnt);
         
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column gl_periods.start_date'); 
          --Period start date change for the next period to the Acquisition period in GL Calendar
          UPDATE gl_periods
          SET start_date     = l_next_per_start_date,
            last_update_date = sysdate,
            last_updated_by  = g_user_id
          WHERE period_set_name = p_account_cal
          AND period_name       = p_next_period;
          
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column gl_periods.start_date');
          
          IF SQL%NOTFOUND THEN
            l_retcode := 2;	
            l_errbuf  :='Error while updating gl_periods.start_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
          ELSIF SQL%FOUND THEN
            l_gl_periods_start_dat_cnt := SQL%ROWCOUNT;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for gl_periods.start_date is :'||l_gl_periods_start_dat_cnt);
            
            l_is_gl_per_upd_complete := 'Y';
          
          END IF;  -- gl_periods.start_date      
        END IF;   -- gl_periods.end_date
        
              
        IF l_is_gl_per_upd_complete = 'Y' THEN
        
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column gl_period_statuses.end_date');
            --Period end date change for the Acquisition period in GL Period Statuses
            UPDATE gl_period_statuses
            SET end_date       = l_od_last_day,
              last_update_date = sysdate,
              last_updated_by  = g_user_id
            WHERE Set_of_books_id  in (p_us_ledger, p_can_ledger, p_ledger_set)
            AND period_name    = p_acq_period;  
    
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column gl_period_statuses.end_date');
            IF SQL%NOTFOUND THEN
              l_retcode := 2;	
              l_errbuf  :='Error while updating gl_period_statuses.end_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
            ELSIF SQL%FOUND THEN
                l_gl_period_stat_end_dat_cnt := SQL%ROWCOUNT;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for gl_period_statuses.end_date is :'||l_gl_period_stat_end_dat_cnt);
    
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column gl_period_statuses.start_date');
                --Period start date change for the next period to the Acquisition period in GL Period Statuses
                UPDATE gl_period_statuses
                SET start_date     = l_next_per_start_date,
                  last_update_date = sysdate,
                  last_updated_by  = g_user_id
                WHERE Set_of_books_id  in (p_us_ledger, p_can_ledger, p_ledger_set)
                AND period_name       = p_next_period;
                
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column gl_period_statuses.end_date');
                
                IF SQL%NOTFOUND THEN
                  l_retcode := 2;	
                  l_errbuf  :='Error while updating gl_period_statuses.start_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
                ELSIF SQL%FOUND THEN
                  l_gl_period_stat_start_dat_cnt := SQL%ROWCOUNT;
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for gl_period_statuses.start_date is :'||l_gl_period_stat_start_dat_cnt);
                END IF;  -- gl_period_statuses.start_date of ELSIF SQL%FOUND THEN
            END IF;  -- gl_period_statuses.end_date of ELSIF SQL%FOUND THEN                   
        END IF;      -- ENDIF of IF l_is_gl_per_upd_complete = 'Y' THEN               
        
    ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Running to preview the parameters');
    END IF; -- IF  (p_is_preview = 'N' and l_retcode = 0)

    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is '||l_retcode);
    
    IF (l_retcode = 0 and p_is_preview = 'N') THEN
      -- Insert record into the Control table    
      ins_ctrl_tbl_rec(p_program_name =>  g_fin_gl_shift1_cp_name
                      ,x_errbuf      	=>  l_errbuf
                      ,x_retcode      =>  l_retcode);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'After control table record insertion, the l_retcode is '||l_retcode);
    END IF;
        
    IF (l_retcode = 0) THEN
         COMMIT;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'COMMITTED Successfully..');
        IF (p_is_preview = 'N') THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'The tables GL_PERIODS and GL_PERIOD_STATUSES are updated Successfully.');
        END IF;
    ELSE
        ROLLBACK;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'ROLLBACKED Successfully..');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Error Message - '||l_errbuf);
    END IF;
    
    x_retcode := l_retcode;
    x_errbuf  := l_errbuf;
        
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure Name - :'||l_proc_name||' END...');
     
    EXCEPTION
      WHEN others THEN
         x_retcode := 2;
	       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in procedure '||l_proc_name||' - '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800));
  END shift_fin_gl_cal;

  PROCEDURE shift_fin_gl_data_maps ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_account_cal		IN  VARCHAR2
				    ,p_next_period		IN  VARCHAR2
            ,p_new_next_per_start_date IN  VARCHAR2
            ,p_next_per_start_date		IN  VARCHAR2
            ,p_is_preview     IN  VARCHAR2
	    		)
  IS
      l_proc_name  VARCHAR2(50) := 'shift_fin_gl_data_maps';
      l_errbuf    VARCHAR2(2000) := NULL;
      l_retcode   VARCHAR2(1) := '0'; 
      
      l_fin_gl_shift2_cp_name       VARCHAR2(30)  := 'XXOD_FIN_GL_CAL_SHFT_2';
      
      l_new_next_per_start_date     DATE;
      l_next_per_start_date         DATE;
      l_gl_dat_per_map_per_cnt      NUMBER;  
      
      l_program_id                   NUMBER := NULL;
      l_cp_exec_cnt                  NUMBER := 0; 
      l_is_gl_per_map_trunc          VARCHAR2(1);
           
  BEGIN
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'BEGIN - Procedure       :   '||l_proc_name);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_account_cal           :   '||p_account_cal);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_next_period           :   '||p_next_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_acq_per_end_date      :   '||p_new_next_per_start_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_next_per_start_date   :   '||p_next_per_start_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_is_preview            :   '||p_is_preview);

    -- Validations
    l_new_next_per_start_date    := FND_DATE.CANONICAL_TO_DATE (p_new_next_per_start_date);
    l_next_per_start_date := FND_DATE.CANONICAL_TO_DATE (p_next_per_start_date);
    
    -- CP Output  
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Name                        :   OD: FIN GL Calendar Shift - Stage2');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Accounting Calendar                :   '||p_account_cal);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Next Period                        :   '||p_next_period);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current - Next Period Start Date   :   '||l_next_per_start_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'New - Next Period Start Date       :   '||l_new_next_per_start_date);  


    -- Validate whether this CP executed already or not
    /**  
    IF l_retcode = 0 THEN 

        l_retcode     := 0;
        l_cp_exec_cnt := 0;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING l_fin_gl_shift2_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
          
        IF  l_cp_exec_cnt >= 1 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'The CP "OD: FIN GL Calendar Shift - Stage2" is already executed');
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN GL Calendar Shift - Stage2" is already executed';
        END IF;
    
    END IF; 
    **/     
    /** Begin - Validate that the first CP 'GL Calendar Periods' executed or not  **/
    IF l_retcode = 0 THEN 
        l_retcode := 0;
        l_cp_exec_cnt := -1;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING g_fin_gl_shift1_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
               
        IF  l_cp_exec_cnt = 0 THEN
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN GL Calendar Shift - Stage1" is NOT executed yet. Pls. execute it first.';
            FND_FILE.PUT_LINE(FND_FILE.LOG,l_errbuf);                
        END IF;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is :'||l_retcode);
    END IF; 
    
    /** End - Validate that the first CP 'GL Calendar Periods' executed or not    **/
      
    IF  (p_is_preview = 'N' and l_retcode = 0) THEN
    
        --Accounting Date mapping change in GL_DATE_PERIOD_MAP
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column GL_DATE_PERIOD_MAP.period_name');
        
        UPDATE GL_DATE_PERIOD_MAP
        SET period_name    = p_next_period,
          last_update_date = sysdate,
          last_updated_by  = g_user_id
        WHERE period_set_name = p_account_cal
        AND accounting_date BETWEEN l_new_next_per_start_date AND l_next_per_start_date;          
  
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column GL_DATE_PERIOD_MAP.period_name');
        
        IF SQL%NOTFOUND THEN
          l_retcode := 2;	
          l_errbuf  :='Error while updating GL_DATE_PERIOD_MAP.period_name : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
        ELSIF SQL%FOUND THEN
          l_gl_dat_per_map_per_cnt := SQL%ROWCOUNT;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for GL_DATE_PERIOD_MAP.period_name is :'||l_gl_dat_per_map_per_cnt);
        END IF;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Completed updating the column GL_DATE_PERIOD_MAP.period_name');
    END IF; -- END IF of    IF  (p_is_preview = 'N' and l_retcode = 0) THEN 

    FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is '||l_retcode);
    
    IF (l_retcode = 0 and p_is_preview = 'N') THEN
      -- Insert record into the Control table    
      ins_ctrl_tbl_rec(p_program_name =>  'XXOD_FIN_GL_CAL_SHFT_2'
                      ,x_errbuf      	=>  l_errbuf
                      ,x_retcode      =>  l_retcode);
    END IF;
    
    IF (l_retcode = 0) THEN
         COMMIT;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'COMMITTED Successfully..');
        IF (p_is_preview = 'N') THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'The table GL_DATE_PERIOD_MAP is successfully modified for Mid Month.');
        END IF;        
    ELSE
        ROLLBACK;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Error Message - '||l_errbuf);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'ROLLBACKED Successfully..');
    END IF;
    
    x_retcode := l_retcode;
    x_errbuf  := l_errbuf;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure Name - :'||l_proc_name||' END...');
     
    EXCEPTION
      WHEN others THEN
         x_retcode := 2;
	       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in procedure '||l_proc_name||' - '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800));
  END shift_fin_gl_data_maps;

  PROCEDURE shift_fin_gl_je_bat ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
            ,p_ledger_id      IN  NUMBER    
				    ,p_acq_period	    IN  VARCHAR2
				    ,p_jou_eff_date_from		IN  VARCHAR2
				    ,p_jou_eff_date_to		IN  VARCHAR2
				    ,p_new_jou_eff_date		IN  VARCHAR2
            ,p_is_preview     IN  VARCHAR2
	    		)
  IS


      CURSOR c_list_journals(c_ledger_id NUMBER, c_acq_period VARCHAR2, c_jou_eff_date_from DATE, c_jou_eff_date_to DATE) IS
        SELECT  name, to_char(default_effective_date, 'DD-MON-YY') eff_date
        FROM gl_je_headers
        WHERE ledger_id   = c_ledger_id
          AND period_name = c_acq_period
          AND default_effective_date BETWEEN c_jou_eff_date_from AND c_jou_eff_date_to;
                      
      l_proc_name  VARCHAR2(50) := 'shift_fin_gl_je_bat';
      l_errbuf    VARCHAR2(2000) := NULL;
      l_retcode   VARCHAR2(1) := '0'; 
      
      l_jou_eff_date_from DATE;
      l_jou_eff_date_to   DATE;
      l_new_jou_eff_date  DATE;
      
      l_fin_gl_shift3_cp_name       VARCHAR2(50) := 'XXOD_FIN_GL_CAL_SHFT_3';
      l_ledger_name                 VARCHAR2(30);
      
      l_gl_periods_end_dat_cnt      NUMBER := 0;
      l_gl_periods_start_dat_cnt    NUMBER := 0;
      l_is_gl_per_upd_complete      VARCHAR2(1) := 'N';
      
      l_gl_je_bat_cnt               NUMBER := 0;
      l_gl_je_hdr_cnt               NUMBER := 0;
      l_gl_je_lines_cnt             NUMBER := 0;
      
      l_program_id                   NUMBER := NULL;
      l_cp_exec_cnt                  NUMBER;
      l_ledger_exist                 NUMBER;
      l_functional_cur_code          gl_ledgers.currency_code%TYPE;
      
      l_acq_per_cur_end_date         DATE;
      l_nxt_per_cur_start_date       DATE;
      l_cur_effect_date              DATE;
      
      l_jrnl_cnt                     NUMBER;
            
  BEGIN
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'BEGIN Procedure - :'||l_proc_name||' ...');    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_ledger_id             :   '||p_ledger_id);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_acq_period            :   '||p_acq_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_jou_eff_date_from     :   '||p_jou_eff_date_from);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_jou_eff_date_to       :   '||p_jou_eff_date_to);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_new_jou_eff_date      :   '||p_new_jou_eff_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_is_preview            :   '||p_is_preview);
    
    l_jou_eff_date_from := FND_DATE.CANONICAL_TO_DATE (p_jou_eff_date_from);
    l_jou_eff_date_to   := FND_DATE.CANONICAL_TO_DATE (p_jou_eff_date_to);
    l_new_jou_eff_date  := FND_DATE.CANONICAL_TO_DATE (p_new_jou_eff_date);


    
    --  Validate input parameters
      -- CP Output
      SELECT name, currency_code INTO l_ledger_name, l_functional_cur_code from gl_ledgers where ledger_id = p_ledger_id;
      
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Name              :   OD: FIN GL Calendar Shift - Stage3');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Ledger Name              :   '||l_ledger_name);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Functional Currency Code :   '||l_functional_cur_code);
      --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current Effective Date :   '||l_cur_effect_date);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'New Effective Date       :   '||l_new_jou_eff_date); 
      
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journals Impacted:');
      
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Sl.No       Current Effective Date    Journal Name');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------      ----------------------    ------------');
      l_jrnl_cnt := 0;
      FOR jrnl in c_list_journals(p_ledger_id, p_acq_period, l_jou_eff_date_from, l_jou_eff_date_to) LOOP
          l_jrnl_cnt :=  l_jrnl_cnt + 1;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(l_jrnl_cnt,6)||'            '||jrnl.eff_date||'           '||jrnl.name);      
      END LOOP;         
                                
    -- Validations 
    -- Validate whether this CP executed already or not
    /**  
    IF l_retcode = 0 THEN 

        l_retcode     := 0;
        l_cp_exec_cnt := 0;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING l_fin_gl_shift3_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
          
        IF  l_cp_exec_cnt >= 1 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'The program "OD: FIN GL Calendar Shift - Stage3" is already executed');
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN GL Calendar Shift - Stage3" is already executed';
        END IF;
    
    END IF; 
    **/
         
    /** Begin - Validate that the first CP 'GL Calendar Periods' executed or not  **/
    IF l_retcode = 0 THEN 
        l_retcode := 0;
        l_cp_exec_cnt := -1;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING g_fin_gl_shift1_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
               
        IF  l_cp_exec_cnt = 0 THEN
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN GL Calendar Shift - Stage1" is NOT executed yet. Pls. execute it first.';
            FND_FILE.PUT_LINE(FND_FILE.LOG,l_errbuf);                
        END IF;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is :'||l_retcode);
    END IF; 
    
    /** End - Validate that the first CP 'GL Calendar Periods' executed or not    **/
      
    IF  (p_is_preview = 'N' and l_retcode = 0) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Final Update to the Tables');
          
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column gl_je_batches.default_effective_date');

        UPDATE gl_je_batches
        SET default_effective_date = l_new_jou_eff_date,
            last_update_date = sysdate,
            last_updated_by= g_user_id
        WHERE default_period_name = p_acq_period
          AND default_effective_date BETWEEN l_jou_eff_date_from AND l_jou_eff_date_to
          AND je_batch_id in (select  je_batch_id from gl_je_headers
                              WHERE ledger_id = p_ledger_id
                                AND period_name = p_acq_period
                                AND default_effective_date BETWEEN l_jou_eff_date_from AND l_jou_eff_date_to
                              );        
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column gl_je_batches.default_effective_date');
        
        IF SQL%NOTFOUND THEN
          l_retcode := 2;	
          l_errbuf  :='Error while updating gl_je_batches.default_effective_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
        ELSIF SQL%FOUND THEN
          l_gl_je_bat_cnt := SQL%ROWCOUNT;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for gl_je_batches.default_effective_date is :'||l_gl_je_bat_cnt);
         
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column gl_je_headers.default_effective_date'); 
          
          -- Update of gl_je_headers default_effective_date
          UPDATE gl_je_headers
          SET default_effective_date = l_new_jou_eff_date,
            currency_conversion_date =  l_new_jou_eff_date,
            last_update_date = sysdate,
            last_updated_by  = g_user_id
          WHERE ledger_id = p_ledger_id
          AND period_name = p_acq_period
          AND default_effective_date BETWEEN l_jou_eff_date_from AND l_jou_eff_date_to
          AND currency_code = l_functional_cur_code;          
          
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column gl_je_headers.default_effective_date');
          
          IF SQL%NOTFOUND THEN
            l_retcode := 2;	
            l_errbuf  :='Error while updating gl_je_headers.default_effective_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
          ELSIF SQL%FOUND THEN
            l_gl_je_hdr_cnt := SQL%ROWCOUNT;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for gl_je_headers.default_effective_date is :'||l_gl_je_hdr_cnt);

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column gl_je_lines.effective_date'); 
            
            -- Update of gl_je_lines default_effective_date

            UPDATE gl_je_lines
            SET effective_date = l_new_jou_eff_date,
            last_update_date = sysdate,
              last_updated_by  = g_user_id
            WHERE ledger_id = p_ledger_id
            AND period_name = p_acq_period
            AND effective_date BETWEEN l_jou_eff_date_from AND l_jou_eff_date_to;                      
            
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column gl_je_lines.effective_date');
            
            IF SQL%NOTFOUND THEN
              l_retcode := 2;	
              l_errbuf  :='Error while updating gl_je_lines.effective_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
            ELSIF SQL%FOUND THEN
              l_gl_je_lines_cnt := SQL%ROWCOUNT;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for ggl_je_lines.effective_date is :'||l_gl_je_lines_cnt);
            END IF;  -- gl_je_lines.effective_date                  
          END IF;  -- gl_je_headers.default_effective_date      
        END IF;   -- gl_je_batches.default_effective_date
        
    ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Running to preview the parameters');
    END IF; -- IF  (p_is_preview = 'N' and l_retcode = 0)

    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is '||l_retcode);
    
    IF (l_retcode = 0 and p_is_preview = 'N') THEN
      -- Insert record into the Control table    
      ins_ctrl_tbl_rec(p_program_name =>  l_fin_gl_shift3_cp_name
                      ,x_errbuf      	=>  l_errbuf
                      ,x_retcode      =>  l_retcode);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'After control table record insertion, the l_retcode is '||l_retcode);
    END IF;
        
    IF (l_retcode = 0) THEN
        IF (p_is_preview = 'N') THEN
            COMMIT;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'COMMITTED Successfully..');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'The tables GL_JE_BATCHES, GL_JE_HEADERS and GL_JE_LINES are updated Successfully for Midmonth.');
        END IF;
    ELSE
        ROLLBACK;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'ROLLBACKED Successfully..');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Error Message - '||l_errbuf);
    END IF;
    
    x_retcode := l_retcode;
    x_errbuf  := l_errbuf;
        
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure Name - :'||l_proc_name||' END...');
     
    EXCEPTION
      WHEN others THEN
         x_retcode := 2;
	       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in procedure '||l_proc_name||' - '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800));
  END shift_fin_gl_je_bat;

                    
  PROCEDURE shift_fin_inv_cal ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_account_cal		IN  VARCHAR2
				    ,p_acq_period	IN  VARCHAR2
				    ,p_od_last_day		IN  VARCHAR2
            ,p_is_preview     IN  VARCHAR2
	    		)
  IS
  
  CURSOR c_list_inv_orgs(c_account_cal VARCHAR2, c_acq_period VARCHAR2) IS
      select organization_id, name
      from hr_all_organization_units
      where organization_id in (
            SELECT distinct organization_id
            FROM org_acct_periods
            WHERE period_set_name = c_account_cal
              AND period_name = c_acq_period);        
              
      l_proc_name  VARCHAR2(50) := 'shift_fin_inv_cal';
      l_errbuf    VARCHAR2(2000) := NULL;
      l_retcode   VARCHAR2(1) := '0';
      
      l_fin_inv_cp_name       VARCHAR2(30)  := 'XXOD_FIN_INV_CAL_SHFT'; 
      
      l_od_last_day DATE; 
      l_org_acct_per_cls_date   NUMBER :=0 ;
      
      l_cp_exec_cnt             NUMBER  := 0;
      l_acq_per_cur_end_date    DATE;
      l_org_cnt                 NUMBER  := 0;
  BEGIN
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure Name - :'||l_proc_name||' BEGIN...');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_account_cal 		:'||p_account_cal);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_acq_period 	:'||p_acq_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_od_last_day 	:'||p_od_last_day);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_is_preview	 	:'||p_is_preview);

    l_od_last_day := FND_DATE.CANONICAL_TO_DATE (p_od_last_day);

    -- Validations
    
    -- Validate whether this CP executed already or not 
    /** 
    IF l_retcode = 0 THEN 

        l_retcode     := 0;
        l_cp_exec_cnt := 0;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING l_fin_inv_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
          
        IF  l_cp_exec_cnt >= 1 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'The CP "OD: FIN INV Calendar Shift" is already executed');
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN INV Calendar Shift" is already executed';
        END IF;
    
    END IF; 
    **/      
    /** Begin - Validate that the first CP 'GL Calendar Periods' executed or not  **/    
    IF l_retcode = 0 THEN
    
      l_cp_exec_cnt := -1;
      
      EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING g_fin_gl_shift1_cp_name;
      
      FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
             
      IF  l_cp_exec_cnt = 0 THEN
          l_retcode := 1;
          l_errbuf  :=  'The program "OD: FIN GL Calendar Shift - Stage1" is NOT executed yet. Pls. execute it first.';
          FND_FILE.PUT_LINE(FND_FILE.LOG,l_errbuf);                
      END IF;
      
      FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is :'||l_retcode);
    END IF;
    
    /** End - Validate that the first CP 'GL Calendar Periods' executed or not  **/
    -- CP Output
      
    SELECT schedule_close_date INTO l_acq_per_cur_end_date FROM org_acct_periods WHERE period_set_name = p_account_cal AND period_name = p_acq_period and rownum <= 1;
      
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Name                  :   OD: FIN INV Calendar Shift');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Accounting Calendar          :   '||p_account_cal);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period of Acquisition        :   '||p_acq_period);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current Period-End Date      :   '||l_acq_per_cur_end_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current Period New End Date  :   '||l_od_last_day);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Inventory Organizations Impacted:');
    
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Sl.No          Organization Code        Organization Name');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----          -----------------        -----------------');
    l_org_cnt := 0;
    FOR invOrg in c_list_inv_orgs(p_account_cal, p_acq_period) LOOP
        l_org_cnt :=  l_org_cnt + 1;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_org_cnt||'.          '||invOrg.organization_id||'        '||invOrg.name);      
    END LOOP;
       
    IF  (p_is_preview = 'N' and l_retcode = 0) THEN  
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column org_acct_periods.schedule_close_date');
        
        UPDATE org_acct_periods
        SET schedule_close_date = l_od_last_day,
          last_update_date = sysdate,
          last_updated_by  = g_user_id
        WHERE period_set_name = p_account_cal
        AND period_name       = p_acq_period; 
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column org_acct_periods.schedule_close_date');
        
        IF SQL%NOTFOUND THEN
          l_retcode := 2;	
          l_errbuf  :='Error while updating org_acct_periods.schedule_close_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
        ELSIF SQL%FOUND THEN
          l_org_acct_per_cls_date := SQL%ROWCOUNT;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for org_acct_periods.schedule_close_date is :'||l_org_acct_per_cls_date);
        END IF;  

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Completed updating the column org_acct_periods.schedule_close_date');
        
    ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Running to preview the parameters');
    END IF; -- END IF of    IF  (p_is_preview = 'N' and l_retcode = 0) THEN 

    FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is '||l_retcode);
    
    IF (l_retcode = 0 and p_is_preview = 'N') THEN
      -- Insert record into the Control table    
      ins_ctrl_tbl_rec(p_program_name =>  'XXOD_FIN_INV_CAL_SHFT'
                      ,x_errbuf      	=>  l_errbuf
                      ,x_retcode      =>  l_retcode);
    END IF;
    
    IF (l_retcode = 0) THEN
         COMMIT;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'COMMITTED Successfully..');
        IF (p_is_preview = 'N') THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'The inventory table ORG_ACCT_PERIODS  is successfully modified for Mid Month.');  
        END IF;
    ELSE
        ROLLBACK;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Error Message - '||l_errbuf);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'ROLLBACKED Successfully..');
    END IF;
        
    x_retcode := l_retcode;
    x_errbuf  := l_errbuf;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure Name - :'||l_proc_name||' END...');
     
    EXCEPTION
      WHEN others THEN
         x_retcode := 2;
	       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in procedure '||l_proc_name||' - '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800));
  END shift_fin_inv_cal;

  PROCEDURE shift_fin_pa_cal ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_acq_period	IN  VARCHAR2
				    ,p_od_last_day		IN  VARCHAR2
				    ,p_next_period		IN  VARCHAR2
				    ,p_next_per_start_date		IN  VARCHAR2
            ,p_is_preview     IN  VARCHAR2
	    		)
  IS
      l_proc_name  VARCHAR2(50) := 'shift_fin_pa_cal';
      l_errbuf    VARCHAR2(2000) := NULL;
      l_retcode   VARCHAR2(1) := '0';

      l_fin_pa_cp_name       VARCHAR2(30)  := 'XXOD_FIN_PA_CAL_SHFT'; 
      
      l_od_last_day DATE;
      l_next_per_start_date DATE;       
      
      l_pa_periods_end_dat_cnt   NUMBER := 0;
      l_pa_periods_start_dat_cnt NUMBER := 0;
      l_is_pa_per_upd_complete   VARCHAR2(1) := 'N';
      l_pji_tc_per_end_dat_cnt   NUMBER := 0;
      l_pji_tc_per_start_dat_cnt NUMBER := 0;
      
      l_cp_exec_cnt              NUMBER  := 0;

      l_acq_per_cur_end_date      DATE;
      l_nxt_per_cur_start_date    DATE;      
  BEGIN
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure Name - :'||l_proc_name||' BEGIN...');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_acq_period 	:'||p_acq_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_od_last_day 	:'||p_od_last_day);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_next_period 	:'||p_next_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_next_per_start_date 	:'||p_next_per_start_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_is_preview	 	:'||p_is_preview);

    l_od_last_day := FND_DATE.CANONICAL_TO_DATE (p_od_last_day);
    l_next_per_start_date := FND_DATE.CANONICAL_TO_DATE (p_next_per_start_date); 

    -- Validations
    -- Validate whether this CP executed already or not 
    /** 
    IF l_retcode = 0 THEN 
        l_cp_exec_cnt := 0;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING l_fin_pa_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
          
        IF  l_cp_exec_cnt >= 1 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'The CP "OD: FIN PA Calendar Shift" is already executed');
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN PA Calendar Shift" is already executed';
        END IF;
    
    END IF; 
    **/     
    /** Begin - Validate that the first CP 'GL Calendar Periods' executed or not  **/    
    IF l_retcode = 0 THEN
    
        l_cp_exec_cnt := -1;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING g_fin_gl_shift1_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
               
        IF  l_cp_exec_cnt = 0 THEN
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN GL Calendar Shift - Stage1" is NOT executed yet. Pls. execute it first.';
            FND_FILE.PUT_LINE(FND_FILE.LOG,l_errbuf);                
        END IF;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is :'||l_retcode);
    END IF;

    -- CP Output
      
    SELECT end_date INTO l_acq_per_cur_end_date FROM pa_periods_all WHERE period_name = p_acq_period  and rownum <= 1;
    
    SELECT start_date INTO l_nxt_per_cur_start_date FROM pa_periods_all WHERE period_name = p_next_period  and rownum <= 1;
      
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Name                  :   OD: FIN PA Calendar Shift');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period of Acquisition        :   '||p_acq_period);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current Period-End Date      :   '||l_acq_per_cur_end_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current Period New End Date  :   '||l_od_last_day);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Next Period Start Date       :   '||l_nxt_per_cur_start_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Next Period New Start Date   :   '||l_next_per_start_date);
    --  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Applications Impacted    :   '||);
    --  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Preview                  :   '||p_is_preview);        
       
    IF  (p_is_preview = 'N' and l_retcode = 0) THEN 
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column pa_periods_all.end_date');

        --Period end date change for the Acquisition period in PA Calendar
    
        UPDATE pa_periods_all
        SET end_date       = l_od_last_day,
          last_update_date = sysdate,
          last_updated_by  = g_user_id
        WHERE period_name  = p_acq_period;    
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column pa_periods_all.end_date');
        
        IF SQL%NOTFOUND THEN
          l_retcode := 2;	
          l_errbuf  :='Error while updating pa_periods_all.end_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
        ELSIF SQL%FOUND THEN
          l_pa_periods_end_dat_cnt := SQL%ROWCOUNT;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for pa_periods_all.end_date is :'||l_pa_periods_end_dat_cnt);
         
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column pa_periods_all.start_date'); 
          
          --Period start date change for the Acquisition period in PA Calendar
    
          UPDATE pa_periods_all
          SET start_date     = l_next_per_start_date,
            last_update_date = sysdate,
            last_updated_by  = g_user_id
          WHERE period_name  = p_next_period;
          
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column pa_periods_all.start_date');
          
          IF SQL%NOTFOUND THEN
            l_retcode := 2;	
            l_errbuf  :='Error while updating pa_periods_all.start_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
          ELSIF SQL%FOUND THEN
            l_pa_periods_start_dat_cnt := SQL%ROWCOUNT;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for pa_periods_all.start_date is :'||l_pa_periods_start_dat_cnt);
            l_is_pa_per_upd_complete := 'Y';
          
          END IF;  -- pa_periods_all.start_date      
        END IF;   -- pa_periods_all.end_date
        
              
        IF l_is_pa_per_upd_complete = 'Y' THEN
        
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column PJI_TIME_CAL_PERIOD.end_date');
            --Period end date change for the Acquisition period in PJI Calendar
    
            UPDATE PJI_TIME_CAL_PERIOD
            SET end_date       = l_od_last_day,
              last_update_date = sysdate,
              last_updated_by  = g_user_id
            WHERE name = p_acq_period;         
    
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column PJI_TIME_CAL_PERIOD.end_date');
            IF SQL%NOTFOUND THEN
              l_retcode := 2;	
              l_errbuf  :='Error while updating PJI_TIME_CAL_PERIOD.end_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
            ELSIF SQL%FOUND THEN
              l_pji_tc_per_end_dat_cnt := SQL%ROWCOUNT;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for PJI_TIME_CAL_PERIOD.end_date is :'||l_pji_tc_per_end_dat_cnt);
    
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column PJI_TIME_CAL_PERIOD.start_date');
                --Period start date change for the Acquisition period in PJI Calendar
        
                UPDATE PJI_TIME_CAL_PERIOD
                SET start_date       = l_next_per_start_date,
                  last_update_date = sysdate,
                  last_updated_by  = g_user_id
                WHERE name = p_next_period;
                
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column PJI_TIME_CAL_PERIOD.end_date');
                
                IF SQL%NOTFOUND THEN
                  l_retcode := 2;	
                  l_errbuf  :='Error while updating PJI_TIME_CAL_PERIOD.start_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
                ELSIF SQL%FOUND THEN
                  l_pji_tc_per_start_dat_cnt := SQL%ROWCOUNT;
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for PJI_TIME_CAL_PERIOD.start_date is :'||l_pji_tc_per_start_dat_cnt);
                END IF;   -- PJI_TIME_CAL_PERIOD.start_date of ELSIF SQL%FOUND THEN    
            END IF;  -- PJI_TIME_CAL_PERIOD.end_date of ELSIF SQL%FOUND THEN                   
        END IF;      -- ENDIF of IF l_is_pa_per_upd_complete = 'Y' THEN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Completed updating the column pa_periods_all.end_date');

    ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Running to preview the parameters');
    END IF; -- END IF of    IF  (p_is_preview = 'N' and l_retcode = 0) THEN 

    FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is '||l_retcode);
    
    IF (l_retcode = 0 and p_is_preview = 'N') THEN
      -- Insert record into the Control table    
      ins_ctrl_tbl_rec(p_program_name =>  'XXOD_FIN_PA_CAL_SHFT'
                      ,x_errbuf      	=>  l_errbuf
                      ,x_retcode      =>  l_retcode);
    END IF;
    
    IF (l_retcode = 0) THEN
         COMMIT;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'COMMITTED Successfully..');
        IF (p_is_preview = 'N') THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'The tables PA_PERIODS_ALL and PJI_TIME_CAL_PERIOD are successfully modified for Mid Month.');
        END IF;
    ELSE
        ROLLBACK;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Error Message - '||l_errbuf);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'ROLLBACKED Successfully..');
    END IF;
    
    x_retcode := l_retcode;
    x_errbuf  := l_errbuf;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure Name - :'||l_proc_name||' END...');
     
    EXCEPTION
      WHEN others THEN
         x_retcode := 2;
	       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in procedure '||l_proc_name||' - '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800));
  END shift_fin_pa_cal;  

  PROCEDURE shift_fin_fa_depr_cal ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_fa_depr_cal		IN  VARCHAR2
				    ,p_acq_period	IN  VARCHAR2
				    ,p_od_last_day		IN  VARCHAR2
				    ,p_next_period		IN  VARCHAR2
				    ,p_next_per_start_date		IN  VARCHAR2
            ,p_is_preview     IN  VARCHAR2
	    		)
  IS
      l_proc_name  VARCHAR2(50) := 'shift_fin_fa_depr_cal';
      l_errbuf    VARCHAR2(2000) := NULL;
      l_retcode   VARCHAR2(1) := '0'; 

      l_fin_fa_shift1_cp_name       VARCHAR2(30)  := 'XXOD_FIN_FA_CAL_SHFT_1';
      
      l_od_last_day DATE;
      l_next_per_start_date DATE;      
      
      l_fa_periods_end_dat_cnt    NUMBER := 0;
      l_fa_periods_start_dat_cnt  NUMBER := 0;
      l_fa_depr_per_cls_dat_cnt   NUMBER := 0; 
      
      l_cp_exec_cnt               NUMBER  := 0; 
      
      l_acq_per_cur_end_date      DATE;
      l_nxt_per_cur_start_date    DATE;
      l_depr_cur_close_date       DATE;
  BEGIN
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure Name - :'||l_proc_name||' BEGIN...');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_fa_depr_cal 	 :'||p_fa_depr_cal);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_acq_period 	   :'||p_acq_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_od_last_day 	 :'||p_od_last_day);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_next_period 	 :'||p_next_period);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_next_per_start_date 	:'||p_next_per_start_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_is_preview	 	 :'||p_is_preview);


    l_od_last_day := FND_DATE.CANONICAL_TO_DATE (p_od_last_day);
    l_next_per_start_date := FND_DATE.CANONICAL_TO_DATE (p_next_per_start_date);
    
    -- Validations
    -- Validate whether this CP executed already or not
    /**  
    IF l_retcode = 0 THEN 
        l_cp_exec_cnt := 0;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING l_fin_fa_shift1_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
          
        IF  l_cp_exec_cnt >= 1 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'The CP "OD: FIN FA Calendar Shift - Stage1" is already executed');
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN FA Calendar Shift - Stage1" is already executed';
        END IF;
    
    END IF; 
    **/     
    /** Begin - Validate that the first CP 'GL Calendar Periods' executed or not  **/    
    IF l_retcode = 0 THEN
        l_cp_exec_cnt := -1;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING g_fin_gl_shift1_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
               
        IF  l_cp_exec_cnt = 0 THEN
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN GL Calendar Shift - Stage1" is NOT executed yet. Pls. execute it first.';
            FND_FILE.PUT_LINE(FND_FILE.LOG,l_errbuf);                
        END IF;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is :'||l_retcode);
    END IF;

    -- CP Output
      
    SELECT end_date INTO l_acq_per_cur_end_date FROM fa_calendar_periods WHERE calendar_type = p_fa_depr_cal and period_name = p_acq_period and rownum <= 1;
    
    SELECT start_date INTO l_nxt_per_cur_start_date FROM fa_calendar_periods WHERE calendar_type = p_fa_depr_cal and period_name = p_next_period and rownum <= 1;
    
    SELECT calendar_period_close_date INTO l_depr_cur_close_date FROM fa_deprn_periods WHERE period_name = p_acq_period and rownum <= 1;
      
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Name                  :   OD: FIN FA Calendar Shift - Stage1');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Asset Calendar               :   '||p_fa_depr_cal);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period of Acquisition        :   '||p_acq_period);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current Period-End Date      :   '||l_acq_per_cur_end_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current Period New End Date  :   '||l_od_last_day);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Next Period Start Date       :   '||l_nxt_per_cur_start_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Next Period New Start Date   :   '||l_next_per_start_date);
    --  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Applications Impacted    :   '||);
    --  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Preview                  :   '||p_is_preview);   
          
    IF  (p_is_preview = 'N' and l_retcode = 0) THEN 
    
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column fa_calendar_periods.end_date');
        --Period end date change for the Acquisition period in FA Depreciation Calendar

        UPDATE fa_calendar_periods
        SET end_date       = l_od_last_day,
          last_update_date = sysdate,
          last_updated_by  = g_user_id
        WHERE calendar_type = p_fa_depr_cal
        AND period_name     = p_acq_period;
         
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column fa_calendar_periods.end_date');
        
        IF SQL%NOTFOUND THEN
          l_retcode := 2;	
          l_errbuf  :='Error while updating fa_calendar_periods.end_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
        ELSIF SQL%FOUND THEN
          l_fa_periods_end_dat_cnt := SQL%ROWCOUNT;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for fa_calendar_periods.end_date is :'||l_fa_periods_end_dat_cnt);
         
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column fa_calendar_periods.start_date'); 
          --Period start date change for the Acquisition period in FA Depreciation Calendar
    
          UPDATE fa_calendar_periods
          SET start_date     = l_next_per_start_date,
            last_update_date = sysdate,
            last_updated_by  = g_user_id
          WHERE calendar_type = p_fa_depr_cal
            AND period_name   = p_next_period;        
            
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column fa_calendar_periods.start_date');
          
          IF SQL%NOTFOUND THEN
            l_retcode := 2;	
            l_errbuf  :='Error while updating fa_calendar_periods.start_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
          ELSIF SQL%FOUND THEN
            l_fa_periods_start_dat_cnt := SQL%ROWCOUNT;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for fa_calendar_periods.start_date is :'||l_fa_periods_start_dat_cnt);

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column fa_deprn_periods.calendar_period_close_date'); 
            --Period start date change for the Acquisition period in FA Depreciation Calendar
              
            UPDATE fa_deprn_periods
            SET calendar_period_close_date = l_od_last_day -- Suresh
               -- ,last_update_date = sysdate
                --,last_updated_by  = g_user_id          
            WHERE period_name = p_acq_period;        
              
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column fa_deprn_periods.calendar_period_close_date');
            
            IF SQL%NOTFOUND THEN
              l_retcode := 2;	
              l_errbuf  :='Error while updating fa_deprn_periods.calendar_period_close_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
            ELSIF SQL%FOUND THEN
              l_fa_depr_per_cls_dat_cnt := SQL%ROWCOUNT;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for fa_deprn_periods.calendar_period_close_date is :'||l_fa_depr_per_cls_dat_cnt);
            END IF;  -- fa_deprn_periods.calendar_period_close_date  of ELSIF SQL%FOUND THEN     
            
          END IF;  -- fa_calendar_periods.start_date  of ELSIF SQL%FOUND THEN     
        END IF;   -- fa_calendar_periods.end_date of ELSIF SQL%FOUND THEN  

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column fa_calendar_periods.end_date');

    ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Running to preview the parameters');
    END IF; -- END IF of    IF  (p_is_preview = 'N' and l_retcode = 0) THEN 

    FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is '||l_retcode);
    
    IF (l_retcode = 0 and p_is_preview = 'N') THEN
      -- Insert record into the Control table    
      ins_ctrl_tbl_rec(p_program_name =>  'XXOD_FIN_FA_CAL_SHFT_1'
                      ,x_errbuf      	=>  l_errbuf
                      ,x_retcode      =>  l_retcode);
    END IF;
    
    IF (l_retcode = 0) THEN
         COMMIT;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'COMMITTED Successfully..');
        IF (p_is_preview = 'N') THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'The table FA_CALENDAR_PERIODS is successfully modified for Mid Month.');
        END IF;
    ELSE
        ROLLBACK;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Error Message - '||l_errbuf);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'ROLLBACKED Successfully..');
    END IF;
        
    x_retcode := l_retcode;
    x_errbuf  := l_errbuf;    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure Name - :'||l_proc_name||' END...');
     
    EXCEPTION
      WHEN others THEN
         x_retcode := 2;
	       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in procedure '||l_proc_name||' - '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800));
  END shift_fin_fa_depr_cal;

  PROCEDURE shift_fin_fa_pror_conv_cal ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_prorate_convention_type		IN  VARCHAR2
				    ,p_from_date	IN  VARCHAR2
				    ,p_new_to_date		IN  VARCHAR2
				    ,p_new_prorate_date		IN  VARCHAR2
				    ,p_next_per_from_date		IN  VARCHAR2
				    ,p_next_new_start_date		IN  VARCHAR2
				    ,p_next_new_prorate_date		IN  VARCHAR2            
            ,p_is_preview     IN  VARCHAR2
	    		)          
  IS
      l_proc_name  VARCHAR2(50) := 'shift_fin_fa_pror_conv_cal';
      l_errbuf    VARCHAR2(2000) := NULL;
      l_retcode   VARCHAR2(1) := '0'; 

      l_fin_fa_shift2_cp_name       VARCHAR2(30)  := 'XXOD_FIN_FA_CAL_SHFT_2';
      
      l_from_date	            DATE;
			l_new_to_date		        DATE;
			l_new_prorate_date		  DATE;
			l_next_per_from_date		DATE;
			l_next_new_start_date		DATE;
			l_next_new_prorate_date DATE;
      
      l_fa_per_pror_end_dat_cnt  NUMBER := 0;
      l_fa_per_pror_start_dat_cnt  NUMBER := 0;
      
      l_cp_exec_cnt            NUMBER  := 0;

      l_nxt_per_cur_start_date  DATE;
      l_nxt_per_cur_pror_date   DATE;
      l_acq_per_cur_end_date    DATE;
      l_acq_per_cur_proor_date  DATE;     
      
  BEGIN
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure Name - :'||l_proc_name||' BEGIN...');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_prorate_convention_type 		:'||p_prorate_convention_type);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_from_date 	:'||p_from_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_new_to_date 	:'||p_new_to_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_new_prorate_date 	:'||p_new_prorate_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_next_per_from_date 	:'||p_next_per_from_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_next_new_start_date 	:'||p_next_new_start_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_next_new_prorate_date 	:'||p_next_new_prorate_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'p_is_preview	 	:'||p_is_preview);

    l_from_date	            := FND_DATE.CANONICAL_TO_DATE (p_from_date);
		l_new_to_date		        := FND_DATE.CANONICAL_TO_DATE (p_new_to_date);
		l_new_prorate_date		  := FND_DATE.CANONICAL_TO_DATE (p_new_prorate_date);
		l_next_per_from_date		:= FND_DATE.CANONICAL_TO_DATE (p_next_per_from_date);
		l_next_new_start_date		:= FND_DATE.CANONICAL_TO_DATE (p_next_new_start_date);
		l_next_new_prorate_date := FND_DATE.CANONICAL_TO_DATE (p_next_new_prorate_date);

    -- Validations
    -- Validate whether this CP executed already or not  
    /**
    IF l_retcode = 0 THEN 
        l_cp_exec_cnt := 0;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING l_fin_fa_shift2_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
          
        IF  l_cp_exec_cnt >= 1 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'The CP "OD: FIN FA Calendar Shift - Stage2" is already executed');
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN FA Calendar Shift - Stage2" is already executed';
        END IF;
    
    END IF; 
    **/     
    /** Begin - Validate that the first CP 'GL Calendar Periods' executed or not  **/    
    IF l_retcode = 0 THEN
        l_cp_exec_cnt := -1;
        
        EXECUTE IMMEDIATE g_is_shift1_exe_qry INTO l_cp_exec_cnt  USING g_fin_gl_shift1_cp_name;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_cp_exec_cnt	 	:'||l_cp_exec_cnt);
               
        IF  l_cp_exec_cnt = 0 THEN
            l_retcode := 1;
            l_errbuf  :=  'The program "OD: FIN GL Calendar Shift - Stage1" is NOT executed yet. Pls. execute it first.';
            FND_FILE.PUT_LINE(FND_FILE.LOG,l_errbuf);                
        END IF;
    
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is :'||l_retcode);
    END IF;

    -- CP Output

    SELECT end_date, prorate_date INTO l_acq_per_cur_end_date, l_acq_per_cur_proor_date
    FROM FA_CONVENTIONS 
    WHERE prorate_convention_code = p_prorate_convention_type and start_date = l_from_date and rownum <= 1;
    
    SELECT start_date, prorate_date INTO l_nxt_per_cur_start_date, l_nxt_per_cur_pror_date
    FROM FA_CONVENTIONS 
    WHERE prorate_convention_code = p_prorate_convention_type and start_date = l_next_per_from_date and rownum <= 1;
      
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Report Name                        :   OD: FIN FA Calendar Shift - Stage2');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Prorate Convention                 :   '||p_prorate_convention_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current ''To Date''                :   '||l_acq_per_cur_end_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'New ''To Date''                    :   '||l_new_to_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current ''Prorate Date''           :   '||l_acq_per_cur_proor_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'New ''Prorate Date''               :   '||l_new_prorate_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Current Next Period ''From Date''  :   '||l_nxt_per_cur_start_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Next Period New ''From Date''      :   '||l_next_new_start_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Next Period ''Prorate Date''       :   '||l_nxt_per_cur_pror_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Next Period New ''Prorate Date''   :   '||l_next_new_prorate_date);
    --  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Applications Impacted          :   '||l_nxt_per_cur_pror_date);
    --  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Preview                        :   '||p_is_preview); 
    
           
    IF  (p_is_preview = 'N' and l_retcode = 0) THEN 
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column FA_CONVENTIONS.end_date');
        --Period end date change for the Acquisition period in FA Prorate Calendar

        UPDATE FA_CONVENTIONS
        SET end_date = l_new_to_date,
          prorate_date = l_new_prorate_date,
          last_update_date = sysdate,
          last_updated_by  = g_user_id
        WHERE prorate_convention_code = p_prorate_convention_type
          AND start_date = l_from_date;
         
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column FA_CONVENTIONS.end_date');
        
        IF SQL%NOTFOUND THEN
          l_retcode := 2;	
          l_errbuf  :='Error while updating FA_CONVENTIONS.end_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
        ELSIF SQL%FOUND THEN
          l_fa_per_pror_end_dat_cnt := SQL%ROWCOUNT;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for FA_CONVENTIONS.end_date is :'||l_fa_per_pror_end_dat_cnt);
         
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting to update the column FA_CONVENTIONS.start_date'); 
          --Period start date change for the Acquisition period in FA Prorate Calendar
    
          UPDATE FA_CONVENTIONS
          SET start_date = l_next_new_start_date, 
            prorate_date = l_next_new_prorate_date,
            last_update_date = sysdate,
            last_updated_by  = g_user_id
          WHERE prorate_convention_code = p_prorate_convention_type
            AND start_date = l_next_per_from_date;       
            
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Ended to update the column FA_CONVENTIONS.start_date');
          
          IF SQL%NOTFOUND THEN
            l_retcode := 2;	
            l_errbuf  :='Error while updating FA_CONVENTIONS.start_date : '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800);  
          ELSIF SQL%FOUND THEN
            l_fa_per_pror_start_dat_cnt := SQL%ROWCOUNT;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Total no. of records updated for FA_CONVENTIONS.start_date is :'||l_fa_per_pror_start_dat_cnt);
          END IF;  -- FA_CONVENTIONS.start_date  of ELSIF SQL%FOUND THEN     
        END IF;   -- FA_CONVENTIONS.end_date of ELSIF SQL%FOUND THEN   

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Completed updating the column FA_CONVENTIONS.end_date');   
    ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Running to preview the parameters');
    END IF; -- END IF of    IF  (p_is_preview = 'N' and l_retcode = 0) THEN 

    FND_FILE.PUT_LINE(FND_FILE.LOG,'l_retcode is '||l_retcode);
    
    IF (l_retcode = 0 and p_is_preview = 'N') THEN
      -- Insert record into the Control table    
      ins_ctrl_tbl_rec(p_program_name =>  'XXOD_FIN_FA_CAL_SHFT_2'
                      ,x_errbuf      	=>  l_errbuf
                      ,x_retcode      =>  l_retcode);
    END IF;
    
    IF (l_retcode = 0) THEN
         COMMIT;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'COMMITTED Successfully..');
        IF (p_is_preview = 'N') THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'The table FA_CONVENTIONS is successfully modified for Mid Month.');
        END IF;
    ELSE
        ROLLBACK;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Error Message - '||l_errbuf);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'ROLLBACKED Successfully..');
    END IF; 
    
    x_retcode := l_retcode;
    x_errbuf  := l_errbuf;    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure Name - :'||l_proc_name||' END...');
     
    EXCEPTION
      WHEN others THEN
         x_retcode := 2;
	       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in procedure '||l_proc_name||' - '||SQLCODE||' - '||SUBSTR(SQLERRM, 1 , 1800));
  END shift_fin_fa_pror_conv_cal;          

                
END XX_GL_MM_CLOSE_PKG;
/
SHOW ERRORS;