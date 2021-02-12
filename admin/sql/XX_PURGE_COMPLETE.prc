CREATE OR REPLACE PROCEDURE XX_PURGE_COMPLETE(x_errbuff OUT VARCHAR2, x_retcode OUT NUMBER)
AS
  -- +============================================================================================|
  -- |                                    Office Depot                                            |
  -- +============================================================================================|
  -- |  Name:  XX_PURGE_COMPLETE                                                                  |
  -- |                                                                                            |
  -- |  Description: This procedure is for Purging the inactive Customers                         |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         02/12/2021   Ankit Jaiswal        Initial version                              |
    -- +============================================================================================+

LN_CHUNK_SIZE NUMBER;
LN_PARALLEL_LEVEL NUMBER;
L_SQL_STMT VARCHAR2(32767);
L_TASK_NAME VARCHAR2(1000);


BEGIN
     BEGIN
	    SELECT XFTV.TARGET_VALUE1,XFTV.TARGET_VALUE2
		 INTO LN_CHUNK_SIZE,LN_PARALLEL_LEVEL
	   	 FROM XX_FIN_TRANSLATEDEFINITION XFTD,
              XX_FIN_TRANSLATEVALUES XFTV
         WHERE XFTD.TRANSLATION_NAME ='OD_CRM_PURGE_CUSTOMER'
           AND XFTV.SOURCE_VALUE1      ='PURGE INACTIVE CUSTOMER'
           AND XFTD.TRANSLATE_ID       = XFTV.TRANSLATE_ID
           AND XFTD.ENABLED_FLAG       ='Y'
           AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE);
	 
	 EXCEPTION WHEN OTHERS THEN
	 fnd_file.put_line(fnd_file.log,'Erroring while fetching translation name'||SQLERRM);
	 END;
	 
	 
	 SELECT DBMS_PARALLEL_EXECUTE.generate_task_name
	 INTO L_TASK_NAME
     FROM   dual;
	 
	 fnd_file.put_line(fnd_file.output,'Task Name-'||L_TASK_NAME);
	 
	 BEGIN
          DBMS_PARALLEL_EXECUTE.create_task (task_name => L_TASK_NAME);	
     EXCEPTION WHEN OTHERS THEN
	      fnd_file.put_line(fnd_file.log,'Erroring while creating Task '||SQLERRM);	 
     END;
	 
	 BEGIN
         DBMS_PARALLEL_EXECUTE.create_chunks_by_number_col(task_name    => L_TASK_NAME,
                                                    table_owner  => 'XXFIN',
                                                    table_name   => 'XXFIN_AOPS_PURGED_CUSTOMERS',
                                                    table_column => 'ID',
                                                    chunk_size   => LN_CHUNK_SIZE);
	 /*BEGIN
     DBMS_PARALLEL_EXECUTE.create_chunks_by_rowid(task_name   => L_TASK_NAME,
                                               table_owner => 'XXFIN',
                                               table_name  => 'XXFIN_AOPS_PURGED_CUSTOMERS',
                                               by_row      => TRUE,
                                               chunk_size  => LN_CHUNK_SIZE);*/
	 EXCEPTION WHEN OTHERS THEN
	 fnd_file.put_line(fnd_file.log,'Erroring while creating Chunk '||SQLERRM);
     END;
	 
	
  
	BEGIN
	fnd_file.put_line(fnd_file.output,('Before Executing DBMS Parallel-'||to_char(sysdate,'MM/DD/YYYY HH24:Mi:SS')));--Added by Ankit
	l_sql_stmt := 'begin
					PURGE_INACTIVE_CUSTOMER1(:start_id,:end_id);
					end;				
					';
	DBMS_PARALLEL_EXECUTE.run_task(task_name      => L_TASK_NAME,
									sql_stmt       => l_sql_stmt,
									language_flag  => DBMS_SQL.NATIVE,
									parallel_level => LN_PARALLEL_LEVEL);
	fnd_file.put_line(fnd_file.output,('After Executing DBMS Parallel-'||to_char(sysdate,'MM/DD/YYYY HH24:Mi:SS')));						 
	--COMMIT;
	EXCEPTION WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Erroring while executing Task '||SQLERRM);	
	END;
	
	

EXCEPTION WHEN OTHERS THEN
fnd_file.put_line(fnd_file.log,'Error '||SQLERRM);	
x_errbuff:=SQLERRM;
x_retcode:=2;

END;
/