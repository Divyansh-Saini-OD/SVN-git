SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +================================================-===================+
-- | Name       : XX_CDH_DQM_SYNC                                 |
-- | Rice Id    : E0259 Customer Search                                 | 
-- | Description: Real time dqm synchronization
-- | Author: Indra Varada
-- +====================================================================+  

create or replace
PACKAGE BODY XX_CDH_DQM_SYNC AS

G_DQM_REALTIME_SYNC    BOOLEAN := TRUE;
L_REALTIME_SYNC_VALUE VARCHAR2(15) := nvl(FND_PROFILE.VALUE('HZ_DQM_ENABLE_REALTIME_SYNC'), 'Y');

PROCEDURE  REALTIME_SYNC_INDEXES(i_party IN boolean,
i_party_sites IN boolean,
i_contacts IN boolean,
i_contact_points IN boolean
) ;

PROCEDURE outandlog(
   message      IN      VARCHAR2,
   newline      IN      BOOLEAN DEFAULT TRUE);
   
PROCEDURE out(
   message      IN      VARCHAR2,
   newline      IN      BOOLEAN DEFAULT TRUE);

PROCEDURE log(
   message      IN      VARCHAR2,
   newline      IN      BOOLEAN DEFAULT TRUE);

PROCEDURE sync_index_realtime(
        p_index_name            IN     VARCHAR2,
        retcode                 OUT    VARCHAR2,
        err                     OUT    VARCHAR2);

PROCEDURE insert_interface_rec (
        p_party_id      IN      NUMBER,
        p_record_id     IN      NUMBER,
        p_party_site_id IN      NUMBER,
        p_org_contact_id IN     NUMBER,
        p_entity        IN      VARCHAR2,
        p_operation     IN      VARCHAR2,
	p_staged_flag   IN      VARCHAR2 DEFAULT 'N'
);

PROCEDURE insert_into_interface(p_party_id	IN	NUMBER
);

PROCEDURE DQM_REAL_TIME_SYNC_CREATE (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                )
AS
    l_dummy_event WF_EVENT_T;
    l_sync_result varchar2(255);
BEGIN
    -- l_dummy_event is a dummy WF_EVENT_T type variable
    -- HZ_DQM_SYNC.realtime_sync API processes all pending
    -- real time updates.
    -- We also do not want too many of these programs running at the same time
    -- and the concurrent program should be made incompatible with itself
    l_sync_result := realtime_sync(null, l_dummy_event, 'C');

    -- Procedure always returns a value of "SUCCESS"
    -- so there is no need to check status and set the concurrent program status accordingly
END DQM_REAL_TIME_SYNC_CREATE;

PROCEDURE DQM_REAL_TIME_SYNC_UPDATE (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                )
AS
    l_dummy_event WF_EVENT_T;
    l_sync_result varchar2(255);
BEGIN
    -- l_dummy_event is a dummy WF_EVENT_T type variable
    -- HZ_DQM_SYNC.realtime_sync API processes all pending
    -- real time updates.
    -- We also do not want too many of these programs running at the same time
    -- and the concurrent program should be made incompatible with itself
    l_sync_result := realtime_sync(null, l_dummy_event, 'U');

    -- Procedure always returns a value of "SUCCESS"
    -- so there is no need to check status and set the concurrent program status accordingly
END DQM_REAL_TIME_SYNC_UPDATE;

FUNCTION realtime_sync  (p_subscription_guid  IN RAW,
    p_event              IN OUT WF_EVENT_T, 
    p_operation VARCHAR2
) return VARCHAR2
 AS

 TYPE PartyIdList IS TABLE OF NUMBER;
 TYPE OperationList IS TABLE OF VARCHAR2(1);
 TYPE EntityList IS TABLE OF VARCHAR2(30);

 l_party_id PartyIdList;
 l_record_id PartyIdList;
 l_entity EntityList;
 l_operation OperationList;
 l_party_type VARCHAR2(30);
 l_sql_error_message VARCHAR2(2000);
 l_rowid EntityList;

 errbuf VARCHAR2(1000);
 retcode VARCHAR2(10);

 i_party boolean := false;
 i_party_sites boolean := false;
 i_contacts boolean := false;
 i_contact_points boolean  := false;
 l_dqm_run VARCHAR2(1);


BEGIN

  select 'Y' into l_dqm_run
  from HZ_TRANS_FUNCTIONS_VL
  where STAGED_FLAG='Y'
  and nvl(ACTIVE_FLAG,'Y')='Y'
  and rownum = 1;

  IF (l_dqm_run = 'Y') THEN

      update HZ_DQM_SYNC_INTERFACE set STAGED_FLAG = 'P'
        where (STAGED_FLAG = 'N' OR STAGED_FLAG = 'E') and REALTIME_SYNC_FLAG = 'Y' and operation = p_operation
        returning party_id, record_id, entity, operation, rowid BULK COLLECT into
        l_party_id, l_record_id, l_entity, l_operation, l_rowid;

   COMMIT;

   FOR i in 1..l_party_id.COUNT LOOP
     BEGIN
     IF (l_entity(i) = 'PARTY') THEN
        select party_type into l_party_type from hz_parties where party_id = l_party_id(i);
        hz_trans_pkg.set_party_type(l_party_type);
        HZ_STAGE_MAP_TRANSFORM.sync_single_party(l_party_id(i), l_party_type, l_operation(i));
        i_party := true;
     ELSIF (l_entity(i) = 'PARTY_SITES') THEN
        HZ_STAGE_MAP_TRANSFORM.sync_single_party_site(l_record_id(i), l_operation(i));
        i_party := true;
        i_party_sites := true;
     ELSIF (l_entity(i) = 'CONTACTS') THEN
        HZ_STAGE_MAP_TRANSFORM.sync_single_contact(l_record_id(i), l_operation(i));
        i_party := true;
        i_contacts := true;
     ELSIF (l_entity(i) = 'CONTACT_POINTS') THEN
        HZ_STAGE_MAP_TRANSFORM.sync_single_contact_point(l_record_id(i), l_operation(i));
        i_party := true;
        i_contact_points := true;
     END IF;

     BEGIN
          IF (l_entity(i) <> 'PARTY') THEN
              insert_into_interface(l_party_id(i));
          END IF;
          IF l_operation(i) = 'C' THEN
               DELETE FROM hz_dqm_sync_interface WHERE rowid = l_rowid(i) ;
          ELSE
               UPDATE hz_dqm_sync_interface SET staged_flag = 'Y' WHERE rowid = l_rowid(i);
          END IF;
     EXCEPTION WHEN OTHERS THEN
          NULL;
     END;

     EXCEPTION
       WHEN OTHERS THEN
          -- update staged_flag to 'E' if program generates an error.
          l_sql_error_message := SQLERRM;
          UPDATE hz_dqm_sync_interface SET error_data = l_sql_error_message, staged_flag = 'E' WHERE ROWID = l_rowid(i);
     END;

     COMMIT;
  END LOOP ;
  COMMIT;

   REALTIME_SYNC_INDEXES(i_party, i_party_sites, i_contacts, i_contact_points);
   RETURN 'SUCCESS';
 END IF;
 EXCEPTION
        when others then
        IF p_subscription_guid IS NOT NULL THEN
          WF_CORE.context('HZ_DQM_SYNC', 'REALTIME_SYNC', p_event.getEventName(), p_subscription_guid);
          WF_EVENT.setErrorInfo(p_event, 'ERROR');
        END IF;
        return 'ERROR';

END REALTIME_SYNC;


PROCEDURE insert_into_interface(p_party_id	IN	NUMBER
)  IS
l_char NUMBER;
BEGIN
 -- check if record already exists in HZ_DQM_SYNC_INTERFACE
	BEGIN
            select 'Y' into l_char
            from hz_dqm_sync_interface
            where party_id = p_party_id
            and entity = 'PARTY'
            and staged_flag in ('N', 'P')
	    and rownum = 1;
	EXCEPTION WHEN NO_DATA_FOUND THEN
             insert_interface_rec (p_party_id, null, null, null, 'PARTY', 'U', 'Y');
	END;
EXCEPTION WHEN others THEN
   NULL;
END insert_into_interface;

PROCEDURE insert_interface_rec (
	p_party_id	IN	NUMBER,
	p_record_id	IN	NUMBER,
	p_party_site_id	IN	NUMBER,
	p_org_contact_id IN	NUMBER,
	p_entity	IN	VARCHAR2,
	p_operation	IN	VARCHAR2,
	p_staged_flag   IN      VARCHAR2 DEFAULT 'N'
) IS

is_real_time VARCHAR2(1) := 'N';

BEGIN
   IF (G_DQM_REALTIME_SYNC) THEN
     is_real_time := 'Y';
   END IF;

  INSERT INTO hz_dqm_sync_interface (
	PARTY_ID,
	RECORD_ID,
        PARTY_SITE_ID,
        ORG_CONTACT_ID,
	ENTITY,
	OPERATION,
	STAGED_FLAG,
        REALTIME_SYNC_FLAG,
	CREATED_BY,
	CREATION_DATE,
	LAST_UPDATE_LOGIN,
	LAST_UPDATE_DATE,
	LAST_UPDATED_BY,
    SYNC_INTERFACE_NUM
  ) VALUES (
	p_party_id,
	p_record_id,
        p_party_site_id,
        p_org_contact_id,
	p_entity,
	p_operation,
	p_staged_flag,
        is_real_time,
	hz_utility_pub.created_by,
        hz_utility_pub.creation_date,
        hz_utility_pub.last_update_login,
        hz_utility_pub.last_update_date,
        hz_utility_pub.user_id,
        HZ_DQM_SYNC_INTERFACE_S.nextval
  );
END insert_interface_rec;


PROCEDURE realtime_sync_indexes(i_party IN boolean,
  i_party_sites IN boolean,
  i_contacts IN boolean,
  i_contact_points IN boolean
)
AS

  idx_retcode varchar2(1);
  idx_err     varchar2(2000);

  l_status VARCHAR2(255);
  l_index_owner VARCHAR2(255);
  l_tmp		VARCHAR2(2000);
  lt_conc_request_id   NUMBER;
  le_submit_failed     EXCEPTION;
BEGIN
 
  IF (i_party) THEN
        /*SYNC_INDEX_REALTIME(l_index_owner || '.hz_stage_parties_t1',
                                       idx_retcode , idx_err);
        IF idx_retcode = 1 THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;*/
        
      -- TODO: CALL CONC REQUEST  
      
      lt_conc_request_id := FND_REQUEST.submit_request
                                          (   application => 'XXCNV',
                                              program     => 'XX_CDH_SYNC_PARTY_INDEX',
                                              description => NULL,
                                              start_time  => NULL,
                                              sub_request => FALSE
                                          );
      IF lt_conc_request_id = 0 THEN
         RAISE le_submit_failed;
      END IF;   
  END IF;
  IF (i_party_sites) THEN
       /* SYNC_INDEX_REALTIME(l_index_owner || '.hz_stage_party_sites_t1',
                                       idx_retcode , idx_err);
        IF idx_retcode = 1 THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;*/
        
        -- TODO: CALL CONC REQUEST
        lt_conc_request_id := FND_REQUEST.submit_request
                                          (   application => 'XXCNV',
                                              program     => 'XX_CDH_SYNC_SITE_INDEX',
                                              description => NULL,
                                              start_time  => NULL,
                                              sub_request => FALSE
                                          );
      IF lt_conc_request_id = 0 THEN
         RAISE le_submit_failed;
      END IF;   
  END IF;
  IF (i_contacts) THEN
      /*SYNC_INDEX_REALTIME(l_index_owner || '.hz_stage_contact_t1',
                                       idx_retcode , idx_err);
      IF idx_retcode = 1 THEN
          RAISE FND_API.G_EXC_ERROR;
      END IF;*/
      
      -- TODO: CALL CONC REQUEST
      lt_conc_request_id := FND_REQUEST.submit_request
                                          (   application => 'XXCNV',
                                              program     => 'XX_CDH_SYNC_CONTACT_INDEX',
                                              description => NULL,
                                              start_time  => NULL,
                                              sub_request => FALSE
                                          );
      IF lt_conc_request_id = 0 THEN
         RAISE le_submit_failed;
      END IF;     
  END IF;
  IF (i_contact_points) THEN
      /*SYNC_INDEX_REALTIME(l_index_owner || '.hz_stage_cpt_t1',
                                       idx_retcode , idx_err);
      IF idx_retcode = 1 THEN
          RAISE FND_API.G_EXC_ERROR;
      END IF;
      */
      -- TODO: CALL CONC REQUEST
      lt_conc_request_id := FND_REQUEST.submit_request
                                          (   application => 'XXCNV',
                                              program     => 'XX_CDH_SYNC_CNCT_POINT_INDEX',
                                              description => NULL,
                                              start_time  => NULL,
                                              sub_request => FALSE
                                          );
      IF lt_conc_request_id = 0 THEN
         RAISE le_submit_failed;
      END IF;     
  END IF;
EXCEPTION 

WHEN le_submit_failed THEN
    outandlog('Error : Submitting Concurrent Program');
    outandlog(SQLERRM);
 WHEN OTHERS THEN
    outandlog('Error : Aborting Program');
    outandlog(SQLERRM);
END REALTIME_SYNC_INDEXES;

PROCEDURE SYNC_PARTY_INDEX (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                )
AS

 idx_retcode   varchar2(1);
 idx_err       varchar2(2000);
 l_status      VARCHAR2(255);
 l_index_owner VARCHAR2(255);
 l_tmp	       VARCHAR2(2000);

 BEGIN
    IF(fnd_installation.GET_APP_INFO('AR',l_status,l_tmp,l_index_owner)) THEN
    
        SYNC_INDEX_REALTIME(l_index_owner || '.hz_stage_parties_t1',
                                       idx_retcode , idx_err);
        IF idx_retcode = 1 THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
        
    END IF;
EXCEPTION
  WHEN FND_API.G_EXC_ERROR THEN
    x_retcode := 2; 
    outandlog('Error : Aborting Program');
    outandlog(idx_err);
  WHEN OTHERS THEN
    x_retcode := 2; 
    outandlog('Error : Aborting Program');
    outandlog(SQLERRM);
END SYNC_PARTY_INDEX;



PROCEDURE SYNC_SITE_INDEX (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                )
AS

 idx_retcode   varchar2(1);
 idx_err       varchar2(2000);
 l_status      VARCHAR2(255);
 l_index_owner VARCHAR2(255);
 l_tmp	       VARCHAR2(2000);

 BEGIN
    IF(fnd_installation.GET_APP_INFO('AR',l_status,l_tmp,l_index_owner)) THEN
      
        SYNC_INDEX_REALTIME(l_index_owner || '.hz_stage_party_sites_t1',
                                       idx_retcode , idx_err);
        IF idx_retcode = 1 THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      
    END IF;
 EXCEPTION
  WHEN FND_API.G_EXC_ERROR THEN
    x_retcode := 2; 
    outandlog('Error : Aborting Program');
    outandlog(idx_err);
  WHEN OTHERS THEN
    x_retcode := 2; 
    outandlog('Error : Aborting Program');
    outandlog(SQLERRM);
    
END SYNC_SITE_INDEX;    
                
PROCEDURE SYNC_CONTACT_INDEX (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                )
AS

 idx_retcode   varchar2(1);
 idx_err       varchar2(2000);
 l_status      VARCHAR2(255);
 l_index_owner VARCHAR2(255);
 l_tmp	       VARCHAR2(2000);

 BEGIN
    IF(fnd_installation.GET_APP_INFO('AR',l_status,l_tmp,l_index_owner)) THEN
      
        SYNC_INDEX_REALTIME(l_index_owner || '.hz_stage_contact_t1',
                                       idx_retcode , idx_err);
        IF idx_retcode = 1 THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      
    END IF;
 EXCEPTION
  WHEN FND_API.G_EXC_ERROR THEN
    x_retcode := 2; 
    outandlog('Error : Aborting Program');
    outandlog(idx_err);
  WHEN OTHERS THEN
    x_retcode := 2; 
    outandlog('Error : Aborting Program');
    outandlog(SQLERRM);
    
END SYNC_CONTACT_INDEX;                    
                
PROCEDURE SYNC_CONTACT_POINT_INDEX (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                )     
AS

 idx_retcode   varchar2(1);
 idx_err       varchar2(2000);
 l_status      VARCHAR2(255);
 l_index_owner VARCHAR2(255);
 l_tmp	       VARCHAR2(2000);

 BEGIN
    IF(fnd_installation.GET_APP_INFO('AR',l_status,l_tmp,l_index_owner)) THEN
      
        SYNC_INDEX_REALTIME(l_index_owner || '.hz_stage_cpt_t1',
                                       idx_retcode , idx_err);
        IF idx_retcode = 1 THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      
    END IF;
 EXCEPTION
  WHEN FND_API.G_EXC_ERROR THEN
    x_retcode := 2; 
    outandlog('Error : Aborting Program');
    outandlog(idx_err);
  WHEN OTHERS THEN
    x_retcode := 2; 
    outandlog('Error : Aborting Program');
    outandlog(SQLERRM);
    
END SYNC_CONTACT_POINT_INDEX;                    

PROCEDURE sync_index_realtime(
        p_index_name            IN     VARCHAR2,
        retcode                 OUT    VARCHAR2,
        err                     OUT    VARCHAR2) IS

cursor l_party_cur is select rowid, party_id, record_id
            from hz_dqm_sync_interface a
            where a.staged_flag = 'Y'
            and a.entity = 'PARTY' AND REALTIME_SYNC_FLAG='Y';
cursor l_ps_cur is select rowid, party_id, record_id
                from hz_dqm_sync_interface a
                where a.staged_flag = 'Y'
                and a.entity = 'PARTY_SITES' AND REALTIME_SYNC_FLAG='Y';
cursor l_ct_cur is select rowid, party_id, record_id
                from hz_dqm_sync_interface a
                where a.staged_flag = 'Y'
                and entity = 'CONTACTS'  AND REALTIME_SYNC_FLAG='Y';
cursor l_cp_cur is select rowid, party_id, record_id
                from hz_dqm_sync_interface a
                where a.staged_flag = 'Y'
                and entity = 'CONTACT_POINTS' AND REALTIME_SYNC_FLAG='Y';

l_limit NUMBER := 1000;
TYPE RowList IS TABLE OF VARCHAR2(255);
L_ROWID RowList;
TYPE NumberList IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
L_PARTY_ID NumberList;
L_RECORD_ID NumberList;
l_last_fetch BOOLEAN := FALSE;
l_index_name VARCHAR2(100);

BEGIN
  retcode := 0;
  err := null;
  l_index_name := lower(p_index_name);
  IF (INSTRB(l_index_name,'hz_stage_parties_t1') > 0) THEN
     ad_ctx_Ddl.Sync_Index ( p_index_name );
     OPEN l_party_cur;
     LOOP
         FETCH l_party_cur BULK COLLECT INTO
           L_ROWID
           , L_PARTY_ID
           , L_RECORD_ID  LIMIT l_limit;
         IF l_party_cur%NOTFOUND THEN
             l_last_fetch:=TRUE;
         END IF;
         IF L_PARTY_ID.COUNT=0 AND l_last_fetch THEN
             EXIT;
         END IF;
         FORALL I in L_PARTY_ID.FIRST..L_PARTY_ID.LAST
             update hz_staged_parties a set concat_col = concat_col
              where a.party_id = L_PARTY_ID(I);
         FORALL I in L_PARTY_ID.FIRST..L_PARTY_ID.LAST
             delete from hz_dqm_sync_interface
              where rowid = L_ROWID(I);
         ad_ctx_Ddl.Sync_Index ( p_index_name );
         IF l_last_fetch THEN
             EXIT;
         END IF;
         FND_CONCURRENT.AF_Commit;
      END LOOP;
      CLOSE l_party_cur;
  ELSIF (INSTRB(l_index_name,'hz_stage_party_sites_t1') > 0) THEN
     ad_ctx_Ddl.Sync_Index ( p_index_name );
     OPEN l_ps_cur;
     LOOP
         FETCH l_ps_cur BULK COLLECT INTO
             L_ROWID
           , L_PARTY_ID
           , L_RECORD_ID  LIMIT l_limit;
         IF l_ps_cur%NOTFOUND THEN
             l_last_fetch:=TRUE;
         END IF;
         IF L_RECORD_ID.COUNT=0 AND l_last_fetch THEN
             EXIT;
         END IF;
         FORALL I in L_RECORD_ID.FIRST..L_RECORD_ID.LAST
               update hz_staged_party_sites a set concat_col = concat_col
                where a.party_site_id = L_RECORD_ID(I);
         FORALL I in L_RECORD_ID.FIRST..L_RECORD_ID.LAST
               delete from hz_dqm_sync_interface
                where rowid = L_ROWID(I);
        ad_ctx_Ddl.Sync_Index ( p_index_name );
         IF l_last_fetch THEN
             EXIT;
         END IF;
         FND_CONCURRENT.AF_Commit;
      END LOOP;
      CLOSE l_ps_cur;
  ELSIF (INSTRB(l_index_name,'hz_stage_contact_t1') > 0) THEN
      ad_ctx_Ddl.Sync_Index ( p_index_name );
      OPEN l_ct_cur;
      LOOP
         FETCH l_ct_cur BULK COLLECT INTO
             L_ROWID
           , L_PARTY_ID
           , L_RECORD_ID  LIMIT l_limit;
         IF l_ct_cur%NOTFOUND THEN
             l_last_fetch:=TRUE;
         END IF;
         IF L_RECORD_ID.COUNT=0 AND l_last_fetch THEN
             EXIT;
         END IF;
         FORALL I in L_RECORD_ID.FIRST..L_RECORD_ID.LAST
                update hz_staged_contacts a set concat_col = concat_col
                 where a.org_contact_id  = L_RECORD_ID(I);
         FORALL I in L_RECORD_ID.FIRST..L_RECORD_ID.LAST
               delete from hz_dqm_sync_interface
                where rowid = L_ROWID(I);
        ad_ctx_Ddl.Sync_Index ( p_index_name );
         IF l_last_fetch THEN
             EXIT;
         END IF;
         FND_CONCURRENT.AF_Commit;
      END LOOP;
      CLOSE l_ct_cur;
 ELSIF (INSTRB(l_index_name,'hz_stage_cpt_t1') > 0) THEN
     ad_ctx_Ddl.Sync_Index ( p_index_name );
     OPEN l_cp_cur;
     LOOP
         FETCH l_cp_cur BULK COLLECT INTO
             L_ROWID
           , L_PARTY_ID
           , L_RECORD_ID  LIMIT l_limit;
         IF l_cp_cur%NOTFOUND THEN
            l_last_fetch:=TRUE;
         END IF;
         IF L_RECORD_ID.COUNT=0 AND l_last_fetch THEN
             EXIT;
         END IF;
         FORALL I in L_RECORD_ID.FIRST..L_RECORD_ID.LAST
               update hz_staged_contact_points a set concat_col = concat_col
                where a.contact_point_id  = L_RECORD_ID(I);
         FORALL I in L_RECORD_ID.FIRST..L_RECORD_ID.LAST
               delete from hz_dqm_sync_interface
                where rowid = L_ROWID(I);
         ad_ctx_Ddl.Sync_Index ( p_index_name );
         IF l_last_fetch THEN
             EXIT;
         END IF;
         FND_CONCURRENT.AF_Commit;
      END LOOP;
      CLOSE l_cp_cur;
  END IF;
  --Call to sync index
END sync_index_realtime;

/**
* Procedure to write a message to the out and log files
**/
PROCEDURE outandlog(
   message      IN      VARCHAR2,
   newline      IN      BOOLEAN DEFAULT TRUE) IS
BEGIN
  out(message, newline);
  log(message, newline);
END outandlog;

PROCEDURE out(
   message      IN      VARCHAR2,
   newline      IN      BOOLEAN DEFAULT TRUE) IS
BEGIN
  IF message = 'NEWLINE' THEN
    FND_FILE.NEW_LINE(FND_FILE.OUTPUT, 1);
  ELSIF (newline) THEN
    FND_FILE.put_line(fnd_file.output,message);
  ELSE
    FND_FILE.put(fnd_file.output,message);
  END IF;
END out;

/**
* Procedure to write a message to the log file
**/
PROCEDURE log(
   message      IN      VARCHAR2,
   newline      IN      BOOLEAN DEFAULT TRUE
) IS
BEGIN
  IF message = 'NEWLINE' THEN
   FND_FILE.NEW_LINE(FND_FILE.LOG, 1);
  ELSIF (newline) THEN
    FND_FILE.put_line(fnd_file.log,message);
  ELSE
    FND_FILE.put(fnd_file.log,message);
  END IF;
END log;

END XX_CDH_DQM_SYNC;
/
SHOW ERRORS;
EXIT;