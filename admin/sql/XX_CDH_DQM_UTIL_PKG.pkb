SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_DQM_UTIL_PKG IS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_CDH_DQM_UTIL_PKG.pkb                                                   |
-- | Description : Functions for DQM utilities                                               |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        21-Feb-2008     Rajeev Kamath        First Version: Error in SyncInterface    |
-- |2.0        11-Jun-2008     Abhradip Ghosh       Added the logic for the procedure        |
-- |                                                Index_Party                              |
-- +=========================================================================================+

-- +================================================================================+
-- | Name        :  Log_Exception                                                   |
-- | Description :  This procedure is used to log any exceptions raised using custom|
-- |                Error Handling Framework                                        |
-- +================================================================================+
PROCEDURE Log_Exception ( p_error_msg         IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;

BEGIN

  XX_COM_ERROR_LOG_PUB.log_error_crm
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XXCRM'
     ,p_program_type            => 'E0259_CDH_DQM'
     ,p_program_name            => 'XX_CDH_DQM_UTIL_PKG'
     ,p_module_name             => 'CDH'
     ,p_error_location          => 'XX_CDH_DQM_UTIL_PKG'
     ,p_error_message_code      => 'XX_CDH_DQM_SYNC_ERR_UPD'
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MEDIUM'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     );

END Log_Exception;

-- +=======================================================================+
-- | Name        : Update_DQMSync_IFace_Errors                             |
-- | Description : Function to reset error flag in HZ_DQM_SYNC_INTERFACE   |
-- |               This is setup as a Conc. Program                        |
-- | Parameters :  x_errbuf                                                |
-- |               x_retcode                                               |
-- +=======================================================================+
PROCEDURE Update_DQMSync_IFace_Errors (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                ,p_reset_error   IN  VARCHAR2
                ,p_reset_pending IN VARCHAR2
                ) 
AS
    updateRowCount number;
BEGIN
    FND_FILE.put_line(FND_FILE.log, '----    Parameters    ----');
    FND_FILE.put_line(FND_FILE.log, 'Reset Error: ' || p_reset_error);
    FND_FILE.put_line(FND_FILE.log, 'Reset Pending: ' || p_reset_pending);
    FND_FILE.put_line(FND_FILE.log, '----    Parameters    ----');
    if (p_reset_error = 'Y') then
        FND_FILE.put_line(FND_FILE.log, 'Begin (E): ' || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
        -- Set count to not be 0 so we enter the loop for the first time
        updateRowCount := -1;
        while (updateRowCount <> 0) loop
            update HZ_DQM_SYNC_INTERFACE 
                set STAGED_FLAG = 'N'
                ,   ERROR_DATA = NULL
            where STAGED_FLAG = 'E' 
            and   rownum <= 10000
            returning count(1) into updateRowCount;
            commit;
            FND_FILE.put_line(FND_FILE.log, 'Updated: ' || updateRowCount || ' rows.');
        end loop;
        FND_FILE.put_line(FND_FILE.log, 'End  (E): ' || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
    end if;
    if (p_reset_pending = 'Y') then
        FND_FILE.put_line(FND_FILE.log, 'Begin (P): ' || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
        -- Set count to not be 0 so we enter the loop for the first time
        updateRowCount := -1;
        while (updateRowCount <> 0) loop
            update HZ_DQM_SYNC_INTERFACE 
                set STAGED_FLAG = 'N'
                ,   ERROR_DATA = NULL
            where STAGED_FLAG = 'P' 
            and   rownum <= 10000
            returning count(1) into updateRowCount;
            commit;
            FND_FILE.put_line(FND_FILE.log, 'Updated: ' || updateRowCount || ' rows.');
        end loop;
        FND_FILE.put_line(FND_FILE.log, 'End  (P): ' || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
    end if;
EXCEPTION
  WHEN OTHERS THEN
    x_retcode        := 2;
    x_errbuf         := SQLERRM;

    FND_MESSAGE.SET_NAME('AR', 'XX_CDH_DQM_SYNC_ERR_UPD');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME' ,'Update_DQMSync_IFace_Errors');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE' , SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Update_DQMSync_IFace_Errors;


-- +===================================================================+
-- | Name       : DQM_REAL_TIME_SYNC                                   |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: This Function will initiate the sync for data in     |
-- |              HZ_DQM_SYNC_INTERFACE where realtime_flag = 'Y'      |
-- |              [This is in the API - not this program explicitly]   |
-- |              oracle.apps.ar.hz.DQM.realtimesync is usually raised |
-- |              by realtime updates by processing thry Workflow      |
-- |              Agent Listeners may take time. This program can run  |
-- |              more often. records are already in Sync Interface    |
-- +===================================================================+   
PROCEDURE DQM_REAL_TIME_SYNC (
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
    l_sync_result := HZ_DQM_SYNC.realtime_sync(null, l_dummy_event);
    
    -- Procedure always returns a value of "SUCCESS" 
    -- so there is no need to check status and set the concurrent program status accordingly
END DQM_REAL_TIME_SYNC;



-- +=======================================================================+
-- | Name        : Purge_DQMSync_IFace_Errors                              |
-- | Description : Function to reset error flag in HZ_DQM_SYNC_INTERFACE   |
-- |               This is setup as a Conc. Program                        |
-- | Parameters :  x_errbuf                                                |
-- |               x_retcode                                               |
-- +=======================================================================+
PROCEDURE Purge_DQMSync_IFace_Errors (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                ) 
AS
    deleteRowCount number;
BEGIN
    FND_FILE.put_line(FND_FILE.log, 'Start: ' || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
    delete from HZ_DQM_SYNC_INTERFACE 
        where STAGED_FLAG = 'E'
        returning count(1) into deleteRowCount;
    commit;
    FND_FILE.put_line(FND_FILE.log, 'Deleted: ' || deleteRowCount || ' rows.');
    FND_FILE.put_line(FND_FILE.log, 'End: ' || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
EXCEPTION
  WHEN OTHERS THEN
    x_retcode        := 2;
    x_errbuf         := SQLERRM;

    FND_MESSAGE.SET_NAME('AR', 'XX_CDH_DQM_SYNC_ERR_UPD');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME' ,'Purge_DQMSync_IFace_Errors');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE' , SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Purge_DQMSync_IFace_Errors;


-- +=======================================================================+
-- | Name        : Update_DQMSync_RealtimeFlag                             |
-- | Description : Function to update the realtime_sync error flag in      |
-- |               HZ_DQM_SYNC_INTERFACE [Performance]                     |
-- |               This is setup as a Conc. Program                        |
-- | Parameters :  x_errbuf                                                |
-- |               x_retcode                                               |
-- +=======================================================================+
PROCEDURE Update_DQMSync_RealtimeFlag (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                ,p_from          IN  VARCHAR2
                ,p_to            IN  VARCHAR2
                ,p_max_records   IN  NUMBER
                )
AS
    updateRowCount number;
BEGIN
    FND_FILE.put_line(FND_FILE.log, '----    Parameters    ----');
    FND_FILE.put_line(FND_FILE.log, 'From:              ' || p_from);
    FND_FILE.put_line(FND_FILE.log, 'To:                ' || p_to);
    FND_FILE.put_line(FND_FILE.log, 'number of Records: ' || p_max_records);
    FND_FILE.put_line(FND_FILE.log, '----    Parameters    ----');

    FND_FILE.put_line(FND_FILE.log, 'Start: ' || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
    update HZ_DQM_SYNC_INTERFACE 
        set REALTIME_SYNC_FLAG = p_to
        where REALTIME_SYNC_FLAG = p_from
              and STAGED_FLAG = 'N'
              and ROWNUM <= p_max_records
        returning count(1) into updateRowCount;
    commit;
    FND_FILE.put_line(FND_FILE.log, 'Updated: ' || updateRowCount || ' rows.');
    FND_FILE.put_line(FND_FILE.log, 'End: ' || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
EXCEPTION
  WHEN OTHERS THEN
    x_retcode        := 2;
    x_errbuf         := SQLERRM;

    FND_MESSAGE.SET_NAME('AR', 'XX_CDH_DQM_SYNC_ERR_UPD');
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME' ,'Update_DQMSync_RealtimeFlag');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE' , SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE' ,SQLERRM);
    FND_MSG_PUB.ADD;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Update_DQMSync_RealtimeFlag;

-- +=======================================================================+
-- | Name        : Create_Update                                           |
-- | Description : Function to count whether the data exists in the staged |
-- |               tables                                                  |
-- | Parameters :                                                          |
-- +=======================================================================+
FUNCTION create_update(
                       p_table_name VARCHAR2
                       , p_table_column VARCHAR2
                       , p_column_value NUMBER
                      )
RETURN VARCHAR2
IS
l_sql  VARCHAR2(2000);
ln_count NUMBER;
BEGIN
   
   IF p_table_name = 'HZ_STAGED_PARTIES' THEN
      
      l_sql := 'SELECT count(1) FROM '
               ||p_table_name
               ||' WHERE '||p_table_column||' = '||p_column_value
               ||' and status = ''A''';
   
   ELSE
       
      l_sql := 'SELECT count(1) FROM '
               ||p_table_name
               ||' WHERE '||p_table_column||' = '||p_column_value||'';
   
   END IF;
            
   EXECUTE IMMEDIATE l_sql INTO ln_count;
   
   CASE ln_count
        WHEN 0 THEN RETURN 'C' ;
        ELSE RETURN 'U' ;
   END CASE;
   
END create_update;

-- +=======================================================================+
-- | Name        : Index_Party                                             |
-- | Description : Function to re-stage parties for indexing incase        |
-- |               they are not staged or due to errors                    |
-- |               This is setup as a Conc. Program                        |
-- | Parameters :  x_errbuf                                                |
-- |               x_retcode                                               |
-- |               p_party_number                                          |
-- |               p_batch_id                                              |
-- |               p_stage_party_sites                                     |
-- |               p_stage_contacts                                        |
-- |               p_stage_contact_points                                  |
-- +=======================================================================+
PROCEDURE Index_Party (
                 x_errbuf                OUT NOCOPY  VARCHAR2
                ,x_retcode               OUT NOCOPY  NUMBER
                ,p_party_number          IN  VARCHAR2
                ,p_batch_id              IN  NUMBER
                ,p_stage_party_sites     IN  VARCHAR2
                ,p_stage_contacts        IN  VARCHAR2
                ,p_stage_contact_points  IN  VARCHAR2
                )
AS
---------------------------
--Declaring local variables
---------------------------
updateRowCount          NUMBER;
lc_exists               VARCHAR2(03) := 'N';
ln_exists_count         NUMBER;
lc_create_update_flag   VARCHAR2(03);
l_stage_party_sites     VARCHAR2(03);
lc_party_site_exists    VARCHAR2(03);
lc_party_contact_exists VARCHAR2(03);
lc_error_message        VARCHAR2(4000);
lc_set_message          VARCHAR2(2000);
ln_party_count          PLS_INTEGER := 0;
ln_party_sites_count    PLS_INTEGER := 0;
ln_contact_count        PLS_INTEGER := 0;
ln_contact_point_count  PLS_INTEGER := 0;

CURSOR lcu_party_id(p_party_number VARCHAR2
                    , p_batch_id   NUMBER
                   )
IS
SELECT HZ.party_id
       , HZ.party_type
FROM   hz_parties HZ    
WHERE  HZ.party_number = NVL(p_party_number,HZ.party_number)
AND    HZ.attribute20  = NVL(TO_CHAR(p_batch_id),HZ.attribute20)
AND    HZ.status       = 'A';

CURSOR lcu_party_site_id(p_party_id NUMBER)
IS
SELECT HPS.party_site_id
FROM   hz_party_sites HPS
WHERE  HPS.party_id = p_party_id
AND    HPS.status   = 'A';

CURSOR lcu_contact_point_id(p_party_id NUMBER)
IS
SELECT HCP.contact_point_id
FROM   hz_contact_points HCP
WHERE  HCP.owner_table_name = 'HZ_PARTIES'
AND    HCP.owner_table_id   = p_party_id
AND    HCP.status           = 'A';

CURSOR lcu_org_contact_id(p_party_id NUMBER)
IS
SELECT HOC.org_contact_id
       , HR.party_id
FROM   hz_relationships HR
       , hz_org_contacts  HOC
WHERE  HR.object_id = p_party_id
AND    HR.subject_table_name = 'HZ_PARTIES' 
AND    HR.object_table_name  = 'HZ_PARTIES' 
AND    HR.subject_type = 'PERSON'
AND    HR.directional_flag = 'F'
AND    HR.relationship_code = 'CONTACT_OF'
AND    NVL(HR.status,'A') = 'A'
AND    HOC.party_relationship_id =  HR.relationship_id
AND    NVL(HOC.status,'A') = 'A';

TYPE org_contact_id_tbl_type IS TABLE OF lcu_org_contact_id%ROWTYPE INDEX BY BINARY_INTEGER;
lt_org_contact_id org_contact_id_tbl_type;

    
BEGIN
   
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------
        
   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD(' ',80,'-'));
   FND_FILE.PUT_LINE(FND_FILE.LOG,LPAD('OD: CDH DQM Index Party',50));
   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD(' ',80,'-'));
   FND_FILE.PUT_LINE(FND_FILE.LOG,'');
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Input Parameters ');
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Stage Party Number         : '||p_party_number);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Stage Batch Id             : '||p_batch_id);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Stage Party Sites          : '||p_stage_party_sites);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Stage Party Contacts       : '||p_stage_contacts);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Stage Party Contact Points : '||p_stage_contact_points);
   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD(' ',80,'-'));
        
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(' ',80,'-'));
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('OD: CDH DQM Index Party',50));
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(' ',80,'-'));
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(' ',80,'-'));
   
   -- Check whether either of the parameters is entered
   IF p_party_number IS NULL AND p_batch_id IS NULL THEN
      
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Either Party Number or Batch Id Needs to be entered.');
   
   ELSE
       
       FOR lrec_party_id IN lcu_party_id(
                                         p_party_number => p_party_number
                                         , p_batch_id     => p_batch_id
                                        )
       LOOP
                                          
           lc_exists             := 'Y';
           ln_exists_count       := NULL;
           lc_create_update_flag := NULL;
           lc_party_site_exists  := NULL;
           lc_party_contact_exists := NULL;
           lt_org_contact_id.DELETE;
           
           -- Check whether the party type is PERSON or ORGANIZATION
           -- and then call the respective DQM package
           IF (lrec_party_id.party_type = 'PERSON') THEN
              
              
              ln_party_count := ln_party_count + 1;
              lc_create_update_flag := create_update(
                                                     p_table_name     => 'HZ_STAGED_PARTIES'
                                                     , p_table_column => 'party_id'
                                                     , p_column_value => lrec_party_id.party_id
                                                    );
              -- Call to the DQM API
              HZ_DQM_SYNC.sync_person(
                                      p_party_id     => lrec_party_id.party_id
                                      , p_create_upd => lc_create_update_flag
                                     );
           
           ELSIF (lrec_party_id.party_type = 'ORGANIZATION') THEN
                 
                 ln_party_count := ln_party_count + 1;
                 lc_create_update_flag := create_update(
                                                        p_table_name     => 'HZ_STAGED_PARTIES'
                                                        , p_table_column => 'party_id'
                                                        , p_column_value => lrec_party_id.party_id
                                                       );
                 -- Call to the DQM API
                 HZ_DQM_SYNC.sync_org(
                                      p_party_id     => lrec_party_id.party_id
                                      , p_create_upd => lc_create_update_flag
                                     );
           END IF;
           
           IF ( NVL(p_stage_party_sites,'N') = 'Y') THEN
              
              -- Fetch all the party sites for the respective party
              FOR lrec_party_site_id IN lcu_party_site_id(lrec_party_id.party_id)
              LOOP
                  
                  lc_party_site_exists :='Y';
                  lc_create_update_flag := NULL;
                  ln_party_sites_count := ln_party_sites_count + 1;
                  lc_create_update_flag := create_update(
                                                         p_table_name     => 'HZ_STAGED_PARTY_SITES'
                                                         , p_table_column => 'party_site_id'
                                                         , p_column_value => lrec_party_site_id.party_site_id
                                                        );
                                                        
                  -- Call to DQM API
                  HZ_DQM_SYNC.sync_party_site(
                                              p_party_site_id => lrec_party_site_id.party_site_id
                                              , p_create_upd  => lc_create_update_flag
                                             );
                  
              END LOOP;
              
              IF (lc_party_site_exists = 'N') THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'No Party Site exists for the party : '||lrec_party_id.party_id);
              END IF;
              
           END IF;
           
           IF (NVL(p_stage_contacts,'N') = 'Y') THEN
              
              OPEN  lcu_org_contact_id(lrec_party_id.party_id);
              FETCH lcu_org_contact_id BULK COLLECT INTO lt_org_contact_id;
              CLOSE lcu_org_contact_id;
              
              IF lt_org_contact_id.COUNT <> 0 THEN
              
                 -- Fetch all the contacts at the relationship level
                 FOR i IN lt_org_contact_id.FIRST .. lt_org_contact_id.LAST
                 LOOP
                  
                     lc_create_update_flag := NULL;
                     ln_contact_count := ln_contact_count + 1;
                     lc_create_update_flag := create_update(
                                                            p_table_name     => 'HZ_STAGED_CONTACTS'
                                                            , p_table_column => 'org_contact_id'
                                                            , p_column_value => lt_org_contact_id(i).org_contact_id
                                                           );
                                                        
                     -- Call to DQM API
                     HZ_DQM_SYNC.sync_contact (
                                               p_org_contact_id => lt_org_contact_id(i).org_contact_id
                                               , p_create_upd   => lc_create_update_flag
                                              );
                                           
                 END LOOP;
                 
              ELSE
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'No Organization Contacts exists for the party : '||lrec_party_id.party_id);
              END IF;
           
           END IF;
           
           IF (NVL(p_stage_contact_points,'N') = 'Y') THEN
              
              -- Fetch all the contact points for the respective parties at the party level
              FOR lrec_contact_point_id IN lcu_contact_point_id(lrec_party_id.party_id)
              LOOP
                                                                    
                  lc_party_contact_exists := 'Y';
                  lc_create_update_flag   := NULL;
                  ln_contact_point_count  := ln_contact_point_count + 1;
                  lc_create_update_flag := create_update(
                                                         p_table_name     => 'HZ_STAGED_CONTACT_POINTS'
                                                         , p_table_column => 'contact_point_id'
                                                         , p_column_value => lrec_contact_point_id.contact_point_id
                                                        );
                                                                          
                  -- Call to DQM API
                  HZ_DQM_SYNC.sync_contact_point (
                                                  p_contact_point_id => lrec_contact_point_id.contact_point_id
                                                  , p_create_upd     => lc_create_update_flag
                                                 );
                                                                       
              END LOOP;
                                                                    
              IF (lc_party_contact_exists = 'N') THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'No Party Level Contact exists for the party : '||lrec_party_id.party_id);
              END IF;
              
              -- Fetch all the contact points for the respective parties at the relationship level
              IF lt_org_contact_id.COUNT <> 0 THEN
                 
                 -- Fetch all the contacts at the relationship level
                 FOR i IN lt_org_contact_id.FIRST .. lt_org_contact_id.LAST
                 LOOP
                     
                     FOR lrec_contact_point_id IN lcu_contact_point_id(lt_org_contact_id(i).party_id)
                     LOOP
                         
                         lc_party_contact_exists := 'Y';
                         lc_create_update_flag   := NULL;
                         ln_contact_point_count  := ln_contact_point_count + 1;                                                                          
                         lc_create_update_flag := create_update(
                                                                p_table_name     => 'HZ_STAGED_CONTACT_POINTS'
                                                                , p_table_column => 'contact_point_id'
                                                                , p_column_value => lrec_contact_point_id.contact_point_id
                                                               );
                                                                                                   
                         -- Call to DQM API
                         HZ_DQM_SYNC.sync_contact_point (
                                                         p_contact_point_id => lrec_contact_point_id.contact_point_id
                                                         , p_create_upd     => lc_create_update_flag
                                                        );
                     END LOOP;
                     
                     IF (lc_party_contact_exists = 'N') THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'No Relationship Level Contact exists for the party : '||lrec_party_id.party_id);
                     END IF;
                 
                 END LOOP;
              
              END IF;
                
           END IF;     
           
       END LOOP;
       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Number of Parties Read        : '||ln_party_count);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Number of Party Sites Read    : '||ln_party_sites_count);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Number of Contacts Read       : '||ln_contact_count);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Number of Contact Points Read : '||ln_contact_point_count);
       
       IF lc_exists = 'N' THEN
          
          FND_FILE.PUT_LINE(FND_FILE.LOG,'No such Party Number or Batch Id exists.');
          
       END IF;
       
   END IF;

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'XX_CDH_DQM_UTIL_PKG.index_party : Unexpected error while indexing a party.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       x_errbuf         := lc_error_message;
       x_retcode        := 2 ;
       FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf);
END Index_Party;
END XX_CDH_DQM_UTIL_PKG;
/
SHOW ERRORS;

