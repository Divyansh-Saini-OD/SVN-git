
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_ESP_SCHEDULE_JOBS_PKG

        -- +===================================================================+
        -- |                  Office Depot - Project Simplify                  |
        -- |                            Oracle                                 |
        -- +===================================================================+
        -- | Name       :  XX_ESP_SCHEDULE_JOBS_PKG			                       |
        -- |								                                                   |
        -- | Rice ID    :  				                                             |
        -- | Description:To print report for all the scheduled ESP jobs run for|
        -- |             the current date                		                   |
        -- |               						                                         |
        -- |Change Record:                                                     |
        -- |===============                                                    |
        -- |Version   Date        Author           Remarks                     |
        -- |=======   ==========  =============    ============================|
        -- |DRAFT 1.A 23-Jun-2008  Piyush           Initial draft version      |
        -- +===================================================================+
AS
        -- +===================================================================+
        -- | Name             : Main_Proc                                      |
	      -- | Description      : This procedure extracts details for all the    |
	      -- |                    ESP jobs run for the current date.             |
      	-- |                    					                                     |
      	-- |                                                                   |
      	-- | parameters :      x_errbuf                                        |
        -- |                   x_retcode                                       |
        -- |                   p_user_name                                     |
        -- +===================================================================+

PROCEDURE Main_Proc    ( x_errbuf              OUT NOCOPY VARCHAR2
                        ,x_retcode             OUT NOCOPY NUMBER
                        ,p_user_name           Varchar2
                        
                       ) IS

    ----------------------------------------------------------------------
    ---                Cursor Declaration                              ---
    ----------------------------------------------------------------------

CURSOR c_data IS

SELECT FCP.user_concurrent_program_name Program_Name,
       FCR.Request_id Request_Id,
       to_char(FCR.actual_start_date,'MM DD YY HH24:MI:SS')Start_Time,
       to_char(FCR.Actual_completion_date,'MM DD YY HH24:MI:SS')Completion_Time,
       round((Actual_completion_date - actual_start_date)*24*60,2) Total_Time,
       FCR.completion_text Status_Code_Desc,
       FCR.status_code                
FROM fnd_concurrent_requests FCR,
     fnd_concurrent_programs_tl FCP,
     fnd_user FU
     WHERE FCR.requested_by =FU.user_id
     AND FU.user_name = p_user_name
     AND trunc(FCR.actual_start_date) between trunc(sysdate-1) and trunc(sysdate)
     AND FCR.CONCURRENT_PROGRAM_ID = FCP.concurrent_program_id;
     
     
     
     Begin
     
     ----------------------------------------------------------------------
     ---                Writing LOG FILE                                ---
             
     ----------------------------------------------------------------------
             fnd_file.put_line (fnd_file.Output, ' ');
             fnd_file.put_line (fnd_file.Output
                  ,  RPAD ('Office DEPOT', 40, ' ')
                  || LPAD ('DATE: ', 60, ' ')
                  || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
                  );
             fnd_file.put_line (fnd_file.Output
                  ,LPAD ('OD: ESP JOBS STATUS', 69, ' ')
                  );
             fnd_file.put_line (fnd_file.Output, ' ');
             fnd_file.put_line (fnd_file.Output
                  ,  RPAD ('Program Name', 60, ' ')
                  || ' '
                  || RPAD ('Request ID', 20, ' ')
                  || ' '
                  || RPAD ('Start Time', 30, ' ')
                  || ' '
                  || RPAD ('Completion Time', 30, ' ') 
                  || ' '
                  || RPAD ('Total Time', 20, ' ') 
                  || ' '
                  || RPAD ('Status Code', 10, ' ') 
                  || ' '
                  || RPAD ('Status Code Description', 100, ' ') 
                  );
             fnd_file.put_line (fnd_file.Output
                  ,  RPAD ('-', 60, '-')
                  || ' '
                  || RPAD ('-', 20, '-')
                  || ' '
                  || RPAD ('-', 30, '-')
                  || ' '
                  || RPAD ('-', 30, '-')
                  || ' '
                  || RPAD ('-', 20, '-')
                  || ' '
                  || RPAD ('-', 10, '-')
                  || ' '
                  || RPAD ('-', 100, '-')
                  
                  );
             fnd_file.put_line (fnd_file.Output, ' ');
             
             
             
	             
	FOR cur_rec IN c_data 
        LOOP
        
                        fnd_file.put_line (fnd_file.Output,  
	                                   RPAD (CUR_REC.Program_Name, 60, ' ')
	                                || ' '
	                                || RPAD (CUR_REC.Request_Id, 20, ' ')
	                                || ' '
	                                || RPAD (CUR_REC.Start_Time, 30, ' ')
	                                || ' '
                                        || RPAD (CUR_REC.Completion_Time, 30, ' ')
                                        || ' '
                                        || RPAD (CUR_REC.Total_Time, 20, ' ')
                                        || ' '
					|| RPAD (CUR_REC.Status_Code, 10, ' ')
					|| ' '
					|| RPAD (CUR_REC.Status_Code_Desc, 100, ' ')
					
					);
	END LOOP;
	
	END Main_Proc;
	
END XX_ESP_SCHEDULE_JOBS_PKG;

/
SHOW ERRORS;
