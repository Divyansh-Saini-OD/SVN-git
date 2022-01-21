SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Credit Card Purge                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_CC_NUM_UPD_IBY_SEC_DATA.sql                              |
-- | Description : Script to update the Credit Card number to NULL for IBY tables  |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  --------- -----------------  -------------------------------|
-- | 1.0     20-APR-16 Madhu Bolli       Defect#35193 - updating iby_security_segments table individually |
-- | 1.1     26-APR-16 Madhu Bolli       Removed the hints parallel and full |
-- | 1.1     06-MAY-16 Madhu Bolli       After reviewed by Rick, added where clause for 
-- |                                     the table                         |
-- | 1.2     10-May-16 Madhu Bolli       Update for all Non-Token cc records |
-- +=======================================================================+
/***************************************************************************************************
	Create a procedure to update the records using the ids generated 
	by diving the  table into chunks.
	This procedure will be called by the script to be run in parallel
****************************************************************************************************/


CREATE OR REPLACE PROCEDURE XXOD_UPD_CCNO_IBY_SEC_DATA (p_start_id IN NUMBER, p_end_id IN NUMBER) AS

BEGIN

    update iby_security_segments iss_o
       set iss_o.cc_number_hash1 = iss_o.sec_segment_id||'***'       
          ,iss_o.cc_number_hash2 = NULL
	where iss_o.sec_segment_id between p_start_id and p_end_id
	  and exists (select 1 
                  from iby_creditcard cc 
				  where cc.cc_num_sec_segment_id = iss_o.sec_segment_id
					and NVL(cc.attribute7,'N') = 'N'   -- 1.2
					and cc.card_issuer_code NOT IN ('AMEX')   -- 1.1
                 );

	commit;

end  XXOD_UPD_CCNO_IBY_SEC_DATA;

/
  
/***************************************************************************************************
	Create task, divide the table into chunks, then run the task
****************************************************************************************************/

DECLARE

  l_task     		VARCHAR2(30)     := 'UPDATE_CCNO_IBY_SEC_SEG_DATA';
  l_sql_stmt 		VARCHAR2(32767)  := 'BEGIN  XXOD_UPD_CCNO_IBY_SEC_DATA(:start_id, :end_id); END;';
  l_chunk_sql_stmt 	VARCHAR2(32767);
  l_try      		NUMBER;
  l_status   		NUMBER;

BEGIN

	-- create a task
	DBMS_PARALLEL_EXECUTE.create_task (task_name => l_task);
	-- point to key column and set batch size
	DBMS_PARALLEL_EXECUTE.create_chunks_by_number_col
		(task_name    => l_task,
		table_owner  => 'IBY',
		table_name   => 'IBY_SECURITY_SEGMENTS',
		table_column => 'SEC_SEGMENT_ID',
		chunk_size   => 100000);

	DBMS_PARALLEL_EXECUTE.run_task(task_name    => l_task,
                                 sql_stmt       => l_sql_stmt,
                                 language_flag  => DBMS_SQL.NATIVE,
                                 parallel_level => 64);

	l_status := DBMS_PARALLEL_EXECUTE.task_status(l_task);

	dbms_output.put_line('l_status = '||l_status);

  -- If there is error, Try resuming the task for 2 more times.
  l_try := 0;
  l_status := DBMS_PARALLEL_EXECUTE.task_status(l_task);
  WHILE(l_try < 2 and l_status != DBMS_PARALLEL_EXECUTE.FINISHED)
  Loop
    l_try := l_try + 1;
    DBMS_PARALLEL_EXECUTE.resume_task(l_task);
    l_status := DBMS_PARALLEL_EXECUTE.task_status(l_task);
  END LOOP;
  

-- Monitor status
/* SELECT chunk_id, status, start_id, end_id
FROM   user_parallel_execute_chunks
WHERE  task_name = l_task
ORDER BY chunk_id;

--delete task

DBMS_PARALLEL_EXECUTE.DROP_TASK (l_task);

dbms_output.put_line('Task '||l_task||' dropped');
*/

end;
/
