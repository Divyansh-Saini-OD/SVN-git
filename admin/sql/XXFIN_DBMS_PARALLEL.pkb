SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XXFIN_DBMS_PARALLEL
AS
-- +============================================================================================|
-- |  Office Depot                                            |
-- +============================================================================================|
-- |  Name:  XXFIN_DBMS_PARALLEL                                                                |
-- |                                                                                            |
-- |  Description: This package is to perform the Parallel Execution for Purging                |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================|
-- | Version     Date         Author               Remarks                                      |
-- | =========   ===========  =============        =============================================|
-- | 1.0         02/12/2021   Ankit Jaiswal        Initial version                              |
-- +============================================================================================+
	
	
/* **************************************************
       MAIN Procedure for Parallel Execution
*************************************************** */	
  PROCEDURE XXFIN_PARALLEL_EXECUTION(x_errbuff OUT VARCHAR2, x_retcode OUT NUMBER,p_module_name IN VARCHAR2 )
  IS
  LN_CHUNK_SIZE NUMBER;
  LN_PARALLEL_LEVEL NUMBER;
  LV_PKG_PROC_NAME VARCHAR2(200);
  L_SQL_STMT VARCHAR2(32767);
  L_TASK_NAME VARCHAR2(1000);
  
  
  BEGIN
      BEGIN
  	    SELECT XFTV.TARGET_VALUE2,XFTV.TARGET_VALUE3   --XFTV.TARGET_VALUE1,
  		 INTO LN_CHUNK_SIZE,LN_PARALLEL_LEVEL          --LV_PKG_PROC_NAME,
  	   	 FROM XX_FIN_TRANSLATEDEFINITION XFTD,
                XX_FIN_TRANSLATEVALUES XFTV
           WHERE 1=1
		     AND UPPER(XFTD.TRANSLATION_NAME) = 'XX DBMS PARALLEL OPTIONS'
             --AND UPPER(XFTV.SOURCE_VALUE1) = 'OD CUSTOMER PURGE'
			 --AND UPPER(XFTV.TARGET_VALUE1) = 'XXFIN_DBMS_PARALLEL.XXFIN_PARALLEL_EXECUTION'
             AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
             AND XFTD.ENABLED_FLAG       ='Y'
             AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
			 AND UPPER(XFTV.SOURCE_VALUE1) =  UPPER(p_module_name);
  	 
  	   EXCEPTION WHEN OTHERS THEN
  	       fnd_file.put_line(fnd_file.LOG,'Erroring while fetching translation name'||SQLERRM);
  	   END;
  	 
  	   BEGIN
  	       SELECT DBMS_PARALLEL_EXECUTE.generate_task_name
  	       INTO L_TASK_NAME
           FROM   dual;
	   EXCEPTION WHEN OTHERS THEN
  	       fnd_file.put_line(fnd_file.LOG,'Erroring while generating task name'||SQLERRM);
       END;
	   
  	   BEGIN
            DBMS_PARALLEL_EXECUTE.create_task (task_name => L_TASK_NAME);	
       EXCEPTION WHEN OTHERS THEN
  	      fnd_file.put_line(fnd_file.LOG,'Erroring while creating Task '||SQLERRM);	 
       END;
	   
	   BEGIN
	       fnd_file.put_line(fnd_file.OUTPUT,'---------------------------------------------------------');
  	       fnd_file.put_line(fnd_file.OUTPUT,'--------------'||'Task Name-'||L_TASK_NAME||'--------------');
  	       fnd_file.put_line(fnd_file.OUTPUT,'---------------------------------------------------------');
	   END;
	   
  	 
  	   BEGIN
	       /* Creation of Chunk by Number Column*/
           DBMS_PARALLEL_EXECUTE.create_chunks_by_number_col(task_name    => L_TASK_NAME,
                                                      table_owner  => 'XXFIN',
                                                      table_name   => 'XXFIN_AOPS_PURGED_CUSTOMERS',
                                                      table_column => 'ID',
                                                      chunk_size   => LN_CHUNK_SIZE);
  	       /*--by ROWID
           DBMS_PARALLEL_EXECUTE.create_chunks_by_rowid(task_name   => L_TASK_NAME,
                                                     table_owner => 'XXFIN',
                                                     table_name  => 'XXFIN_AOPS_PURGED_CUSTOMERS',
                                                     by_row      => TRUE,
                                                     chunk_size  => LN_CHUNK_SIZE);*/
  	   EXCEPTION WHEN OTHERS THEN
  	       fnd_file.put_line(fnd_file.LOG,'Erroring while creating Chunk '||SQLERRM);
       END;
    
  	   BEGIN
  	    fnd_file.put_line(fnd_file.OUTPUT,('Before Executing DBMS Parallel-'||TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:Mi:SS')));--Added by Ankit
		--fnd_file.put_line(fnd_file.OUTPUT,('LV_PKG_PROC_NAME--')||LV_PKG_PROC_NAME);
		--fnd_file.put_line(fnd_file.OUTPUT,('L_TASK_NAME--')||L_TASK_NAME);
		--fnd_file.put_line(fnd_file.OUTPUT,('LN_CHUNK_SIZE--')||LN_CHUNK_SIZE);
		--fnd_file.put_line(fnd_file.OUTPUT,('LN_PARALLEL_LEVEL--')||LN_PARALLEL_LEVEL);
		
     	l_sql_stmt := 'begin
  					XXFIN_PURGE_INACTIVE_CUSTOMERS.PURGE_INACTIVE_CUSTOMERS(:start_id,:end_id);
  					end;				
  					';			
	    /*l_sql_stmt := 'begin
  					   LV_PKG_PROC_NAME(:start_id,:end_id);
  					   end;
                      ';*/
       -- fnd_file.put_line(fnd_file.OUTPUT,('l_sql_stmt--')||l_sql_stmt);			
  	    DBMS_PARALLEL_EXECUTE.run_task( task_name      => L_TASK_NAME,
  	    								sql_stmt       => l_sql_stmt,
  	    								language_flag  => DBMS_SQL.NATIVE,
  	    								parallel_level => LN_PARALLEL_LEVEL);
	    	
  	    fnd_file.put_line(fnd_file.OUTPUT,('After Executing DBMS Parallel-'||TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:Mi:SS')));						 
  	   --COMMIT;
  	   EXCEPTION WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Erroring while executing Task '||SQLERRM);	
  	   END;
  	
  EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.LOG,'Error '||SQLERRM);	
      x_errbuff:=SQLERRM;
      x_retcode:=2;
  END XXFIN_PARALLEL_EXECUTION;
END XXFIN_DBMS_PARALLEL;
/
show errors;