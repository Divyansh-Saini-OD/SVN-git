SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_SEAMLESS_CONV_DUMMY
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_SEAMLESS_CONV_DUMMY                                 |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Dummy process to synchronize the Seamless Run              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      29-May-2008 Indra Varada           Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS

PROCEDURE contruct_dyn_query(
 p_orig_system IN VARCHAR2,
 p_wait_time   IN NUMBER,
 x_select_query OUT NOCOPY VARCHAR2,
 x_batch_ids    OUT NOCOPY VARCHAR2
);

PROCEDURE DUMMY_MAIN(
                  p_errbuf      OUT NOCOPY VARCHAR2,
                  p_retcode     OUT NOCOPY VARCHAR2,
                  p_source_system IN VARCHAR2
                )
  AS

TYPE lt_rec_req_type     IS RECORD
   (   req_id            hz_imp_batch_summary.main_conc_req_id%TYPE,
       batch_id          hz_imp_batch_summary.batch_id%TYPE,
       batch_s           hz_imp_batch_summary.batch_status%TYPE,
       import_s          hz_imp_batch_summary.import_status%TYPE
   );

lt_rec_req               lt_rec_req_type;

TYPE lt_batch_cur_type     IS REF CURSOR;

lc_batch_cur               lt_batch_cur_type;
l_wait_time                NUMBER;
le_batch_failed            EXCEPTION;
le_req_failed              EXCEPTION;
le_owb_failed              EXCEPTION;
le_terminated              EXCEPTION;
lv_select_query_main       VARCHAR2(2000);
lv_batch_ids               VARCHAR2(2000);
l_wait_status              BOOLEAN := TRUE;
l_rec_count                NUMBER := 0;
l_phase_code               VARCHAR2(10);
l_status_code              VARCHAR2(10);
l_owb_process_type         VARCHAR2(30);
l_terminate_value          VARCHAR2(30);
BEGIN

    l_wait_time           := NVL(fnd_profile.value('XX_CDH_SEAMLESS_WAIT_TIME'),30000);
    
    contruct_dyn_query(
     p_orig_system  => p_source_system,
     p_wait_time    => l_wait_time,
     x_select_query => lv_select_query_main,
     x_batch_ids    => lv_batch_ids
    );

 WHILE l_wait_status   LOOP
   
   l_terminate_value     := NVL(fnd_profile.value_wnps('XX_CDH_SEAMLESS_TERMINATE'),'N');   

   IF l_terminate_value = 'Y' THEN
      p_retcode := 2;
      raise le_terminated;
   END IF;
   
   l_rec_count := 0;

   OPEN lc_batch_cur FOR lv_select_query_main;

   LOOP
    FETCH lc_batch_cur INTO lt_rec_req;
    EXIT WHEN lc_batch_cur%NOTFOUND;

    l_rec_count := l_rec_count +1;

    BEGIN
       SELECT process_type INTO l_owb_process_type
       FROM XX_OWB_CRMBATCH_DETAIL_STATUS
       WHERE ((aops_batch_id =lt_rec_req.batch_id AND process_type = 'PF_C0024_LOAD_NA_N')
       OR (ebs_batch_id =lt_rec_req.batch_id AND process_type = 'PF_C0024_EXTRACT_NA_N'))
       AND status NOT LIKE 'OK'
       AND ROWNUM <=1;

       p_retcode := 2;
       RAISE le_owb_failed;

    EXCEPTION WHEN NO_DATA_FOUND THEN
     NULL;
    END;

    IF lt_rec_req.batch_s = 'ACTION_REQUIRED' AND lt_rec_req.import_s = 'ERROR' THEN
        p_retcode := 2;
        RAISE  le_batch_failed;
    ELSIF lt_rec_req.req_id IS NOT NULL THEN

       SELECT phase_code,status_code INTO l_phase_code,l_status_code
       FROM fnd_concurrent_requests
       WHERE request_id = lt_rec_req.req_id;

       IF l_phase_code = 'C' and l_status_code != 'C' THEN
         p_retcode := 2;
         RAISE  le_req_failed;
       END IF;
    END IF;
   END LOOP; -- Cursor Loop Ends
   CLOSE lc_batch_cur;

   IF l_rec_count > 0 THEN
    USER_LOCK.SLEEP(l_wait_time);
   ELSE
     l_wait_status := FALSE;
   END IF;
 END LOOP; -- Main Loop Ends

EXCEPTION
    WHEN le_terminated THEN
      fnd_file.put_line (fnd_file.log, 'Process Manually Terminated By User');
    WHEN le_owb_failed THEN
      fnd_file.put_line (fnd_file.log, 'ERROR :: OWB Process:' || l_owb_process_type || ' Failed');
    WHEN le_batch_failed THEN
      fnd_file.put_line (fnd_file.log, 'ERROR:: Import Batch:' || lt_rec_req.batch_id || ' Has Errors.');
    WHEN le_req_failed THEN
      fnd_file.put_line (fnd_file.log, 'ERROR:: Concurrent Request:' || lt_rec_req.req_id || ' Failed or Terminated.');
    WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure seamless_dummy - Error - '||SQLERRM);
      P_errbuf := 'Unexpected Error in proecedure seamless_dummy - Error - '||SQLERRM;
      p_retcode := 2;
END DUMMY_MAIN;

PROCEDURE contruct_dyn_query (
 p_orig_system   IN  VARCHAR2,
 p_wait_time     IN NUMBER,
 x_select_query  OUT NOCOPY VARCHAR2,
 x_batch_ids     OUT NOCOPY VARCHAR2
)
AS

l_start_date               VARCHAR2(30);
l_end_date                 VARCHAR2(30);
lv_select_query_main       VARCHAR2(2000);
lv_select_query_other      VARCHAR2(2000);
lv_select_query_a0         VARCHAR2(2000);
lv_construct_query         VARCHAR2(2000);
lv_construct_query_a0      VARCHAR2(2000);
lv_construct_query_other   VARCHAR2(2000);
l_lag_time                 NUMBER;
l_lag_time_day             NUMBER;
l_hold_value               VARCHAR2(30);
l_wait_time                NUMBER;

TYPE lt_batch_req_type     IS RECORD
   (
       req_id            hz_imp_batch_summary.main_conc_req_id%TYPE,
       batch_id          hz_imp_batch_summary.batch_id%TYPE,
       batch_s           hz_imp_batch_summary.batch_status%TYPE,
       import_s          hz_imp_batch_summary.import_status%TYPE
   );

lt_batch_req               lt_batch_req_type;

TYPE lt_batch_cur_type     IS REF CURSOR;

lc_batch_cur               lt_batch_cur_type;

BEGIN

    l_hold_value    := NVL(fnd_profile.value_wnps('XX_CDH_SEAMLESS_HOLD_VALUE'),'NO_HOLD');
    
    WHILE l_hold_value = 'ON_HOLD' LOOP
         USER_LOCK.SLEEP(p_wait_time);
         l_hold_value                 := NVL(fnd_profile.value_wnps('XX_CDH_SEAMLESS_HOLD_VALUE'),'NO_HOLD'); 
    END LOOP;  
    
    IF p_orig_system != 'A0' THEN

      l_start_date    := NVL(fnd_profile.value('XX_CDH_SEAMLESS_START_DATE'),'SYSDATE-1');
      l_end_date      := NVL(fnd_profile.value('XX_CDH_SEAMLESS_END_DATE'),'SYSDATE');
      
    ELSE
       l_lag_time      := NVL(fnd_profile.value('XX_CDH_SEAMLESS_LAG'),3600);
       
       USER_LOCK.SLEEP(l_lag_time*100); 
       
       l_lag_time_day  := ROUND(l_lag_time/86400,3);
       l_start_date := 'SYSDATE-' || l_lag_time_day;
       l_end_date   := 'SYSDATE';

       fnd_file.put_line (fnd_file.log, 'Lag Time - ' || l_start_date);

    END IF;

      lv_select_query_main := 'SELECT main_conc_req_id,batch_id,batch_status,import_status ' ||
                         ' FROM hz_imp_batch_summary ' ||
                         ' WHERE original_system = '''|| p_orig_system || ''' ';

      lv_construct_query_other :=  ' AND TRUNC(CREATION_DATE) BETWEEN TRUNC('|| l_start_date ||') AND TRUNC(' || l_end_date || ') ' ||
                         ' AND BATCH_STATUS = ''ACTIVE'' ';

      lv_construct_query_a0 :=   ' AND CREATION_DATE BETWEEN '|| l_start_date ||' AND ' || l_end_date;


      lv_select_query_other := ' AND (BATCH_STATUS IS NULL OR BATCH_STATUS IN (''ACTIVE'',''PROCESSING'') OR (BATCH_STATUS=''ACTION_REQUIRED'' AND IMPORT_STATUS=''ERROR''))';

      lv_select_query_a0 :=  ' AND (BATCH_STATUS IS NULL OR BATCH_STATUS IN (''ACTIVE'',''PROCESSING'') OR (BATCH_STATUS=''ACTION_REQUIRED'' AND IMPORT_STATUS=''ERROR''))';

      IF p_orig_system != 'A0' THEN
          lv_construct_query := lv_select_query_main || lv_construct_query_other;
          x_select_query := lv_select_query_main || lv_select_query_other;
      ELSE
         lv_construct_query := lv_select_query_main || lv_construct_query_a0;
         x_select_query := lv_select_query_main || lv_select_query_a0;
      END IF;
      fnd_file.put_line (fnd_file.log, 'Query Used For Batch IDs - ' || lv_construct_query);
      OPEN lc_batch_cur FOR lv_construct_query;
      LOOP
         FETCH lc_batch_cur INTO lt_batch_req;
         EXIT WHEN lc_batch_cur%NOTFOUND;
         x_batch_ids := x_batch_ids || ',' || lt_batch_req.batch_id;
      END LOOP;
         x_batch_ids := '(' || NVL(x_batch_ids,',-1') || ')';
         x_batch_ids := REPLACE(x_batch_ids,'(,','(');

      fnd_file.put_line (fnd_file.log, 'Query Used - ' || x_select_query || ' AND BATCH_ID IN ' || x_batch_ids);

      x_select_query := x_select_query || ' AND BATCH_ID IN ' || x_batch_ids;

EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line(FND_FILE.LOG,SQLERRM);
END  contruct_dyn_query;

END XX_CDH_SEAMLESS_CONV_DUMMY;
/
SHOW ERRORS;