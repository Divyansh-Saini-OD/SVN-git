SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_PARTY_RELATIONSHIPS_PKG
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                         Oracle Consulting                                               |
-- +=========================================================================================+
-- | Name        : XX_CDH_PARTY_RELATIONSHIPS_PKG                                            |
-- | Description : Custom package for party-relationships not handled by bulk import         |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        30-Jul-2007     Rajeev Kamath        Initial version                          |
-- |1.1        29-May-2008     Ambarish Mukherjee   End Date relationship is new relationship|
-- |                                                is found in staging table                |
-- |1.2        18-May-2009     Indra Varada	    End Date relationhip code (1.1) has been |
-- |                                                moved to check in all cases and update   |
-- |                                                rel logic modified to pass g_miss_date   |
-- |                                                for NULL                                 |
-- |1.3        30-July-2012    Dheeraj V            QC 19705, added status='A' when checking |
-- |                                                for existing relationships to inactivate.|
-- |1.4        08-MAR-2014     Arun Gannarapu       Made changes as part of R12 retrofit     |
-- |                                                defect--28030
-- +=========================================================================================+

AS

    gv_init_msg_list              VARCHAR2(1)          := fnd_api.g_true;
    gn_bulk_fetch_limit           NUMBER               := XX_CDH_CONV_MASTER_PKG.g_bulk_fetch_limit;

-- +===================================================================+
-- | Name        : party_relationship_main                             |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE party_relationship_main
    (
         x_errbuf       OUT     VARCHAR2
        ,x_retcode      OUT     VARCHAR2
        ,p_batch_id     IN      NUMBER
        ,p_process_yn   IN      VARCHAR2
    )
AS    
lc_record_count         NUMBER;
lc_worker_count         NUMBER;
le_skip_procedure       EXCEPTION;
BEGIN
   IF p_process_yn = 'N' THEN
      RAISE le_skip_procedure;
   END IF;   
   -- First update the worker-id, error_id, error_text, subject and object_party_id to null 
   --   in case the data was changed
   -- Get count of remaining records in the batch
   -- Get number of workers from HZ: Number of workers
   -- If record-count < number-workers - submit just one worker
   -- Else set the worker-id on the records and submit a worker

   -- Initialize Variables
   lc_record_count := 0;
   lc_worker_count := 1;

   -- Reset existing data that needs to be processed
   UPDATE XXOD_HZ_IMP_RELSHIPS_STG
   SET    error_id          = NULL,
          error_text        = NULL,
          worker_id         = 1,
          interface_status  = 1
   WHERE  batch_id          = p_batch_id
   AND    interface_status IN ('1','4','6');
   /*
   -- Get count of records to process
   SELECT COUNT(record_id) 
   INTO   lc_record_count
   FROM   XXOD_HZ_IMP_RELSHIPS_STG
   WHERE  interface_status IN ('1','4','6');

   IF (lc_record_count > 0) THEN
       -- Get number of workers to run
       lc_worker_count := fnd_profile.VALUE('HZ_IMP_NUM_OF_WORKERS');
       IF (lc_record_count <= lc_worker_count) THEN
           -- Submit just one thread. 
           lc_worker_count := 1;
       END IF;

       -- To handle records that may be left out due to use of the % operator
       -- while splitting records into workers add worker-count to record-count
       -- The first thread(s) may have to process few records more than the last
       lc_record_count := lc_record_count + lc_worker_count;     

   ELSE
       -- Nothing to do
       fnd_file.put_line(fnd_file.output,'============= Party Relationships ============='||CHR(10));
       fnd_file.put_line(fnd_file.output,CHR(10)||'-----------------------------------------------------------');
       fnd_file.put_line(fnd_file.output,'Total no.of records to process: 0');
       fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');  
   END IF; */
   
   party_relationship_worker
      (   x_errbuf    
         ,x_retcode   
         ,p_batch_id  
         ,1 
      );   
EXCEPTION
   WHEN le_skip_procedure THEN
      x_retcode := 0;
      fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
END party_relationship_main;

-- +===================================================================+
-- | Name        : party_relationship_worker                           |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_batch_id                                          |
-- |               p_worker_id                                         |
-- +===================================================================+
PROCEDURE party_relationship_worker
   (   x_errbuf            OUT VARCHAR2
      ,x_retcode           OUT VARCHAR2
      ,p_batch_id          IN  NUMBER
      ,p_worker_id         IN  NUMBER
   )
AS

--Cursor for customer_account_profile
CURSOR lc_fetch_hz_relships_cur 
   ( p_batch_id   NUMBER,
     p_worker_id  NUMBER
   )
IS
SELECT r.relationship_id,
       r.object_version_number,
       a.*
FROM   hz_relationships r,
       (   SELECT s.owner_table_id sub_id, 
                  o.owner_table_id obj_id,
                  hs.party_type    sub_type,
                  ho.party_type    obj_type,
                  h.relationship_code,
                  h.relationship_type,
                  h.start_date,
                  h.end_date,
                  h.record_id,
                  h.interface_status,
                  h.error_text,
                  h.sub_orig_system,
                  h.sub_orig_system_reference,
                  h.created_by_module,
                  hs.party_id,
                  hs.object_version_number
           FROM   xxod_hz_imp_relships_stg h,
                  hz_orig_sys_references s,
                  hz_orig_sys_references o,
                  hz_parties hs,
                  hz_parties ho    
           WHERE  h.batch_id              = p_batch_id
           AND    h.worker_id             = p_worker_id
           AND    h.interface_status     IN ('1','4','6')
           AND    s.orig_system_reference = h.sub_orig_system_reference
           AND    s.orig_system           = h.sub_orig_system
           AND    s.owner_table_name      = 'HZ_PARTIES'
           AND    s.status                = 'A'
           AND    s.owner_table_id        = hs.party_id
           AND    o.orig_system_reference = h.obj_orig_system_reference
           AND    o.orig_system           = h.obj_orig_system
           AND    o.owner_table_name      = 'HZ_PARTIES'
           AND    o.owner_table_id        = ho.party_id
           AND    o.status                = 'A'
       ) a
WHERE  r.subject_id(+)        = a.sub_id
AND    r.object_id(+)         = a.obj_id
AND    r.relationship_type(+) = a.relationship_type
AND    r.status(+)            = 'A';

TYPE lr_hz_imp_relships_rec IS RECORD
   (  relationship_id            hz_relationships.relationship_id%TYPE,
      object_version_number      hz_relationships.object_version_number%TYPE,
      sub_id                     hz_orig_sys_references.owner_table_id%TYPE,
      obj_id                     hz_orig_sys_references.owner_table_id%TYPE,
      sub_type                   hz_parties.party_type%TYPE,
      obj_type                   hz_parties.party_type%TYPE,
      relationship_code          xxod_hz_imp_relships_stg.relationship_code%TYPE,
      relationship_type          xxod_hz_imp_relships_stg.relationship_type%TYPE,
      start_date                 xxod_hz_imp_relships_stg.start_date%TYPE,
      end_date                   xxod_hz_imp_relships_stg.end_date%TYPE,
      record_id                  xxod_hz_imp_relships_stg.record_id%TYPE,
      interface_status           xxod_hz_imp_relships_stg.interface_status%TYPE,
      error_text                 xxod_hz_imp_relships_stg.error_text%TYPE,
      sub_orig_system            xxod_hz_imp_relships_stg.sub_orig_system%TYPE,
      sub_orig_system_reference  xxod_hz_imp_relships_stg.sub_orig_system_reference%TYPE,
      created_by_module          xxod_hz_imp_relships_stg.created_by_module%TYPE,
      party_id                   hz_parties.party_id%TYPE,
      party_obj_ver_number       hz_parties.object_version_number%TYPE
   );
   
CURSOR lc_get_staging_counts_cur ( p_batch_id NUMBER)
IS
SELECT interface_status,COUNT(*) count_rec
FROM   XXOD_HZ_IMP_RELSHIPS_STG
WHERE  batch_id = p_batch_id
GROUP  BY interface_status;  
   
TYPE lt_hz_imp_rel_tbl_type      IS TABLE OF lr_hz_imp_relships_rec INDEX BY BINARY_INTEGER;
lt_hz_imp_rel_tbl                lt_hz_imp_rel_tbl_type;

--lt_hz_imp_rel_def_tbl           lt_hz_imp_rel_tbl_type;

p_relationship_rec               HZ_RELATIONSHIP_V2PUB.relationship_rec_type;
p_def_relationship_rec           HZ_RELATIONSHIP_V2PUB.relationship_rec_type;
x_relationship_id                NUMBER;
x_party_id                       NUMBER;
x_party_number                   VARCHAR2(20);
x_return_status                  VARCHAR2(2000);
x_msg_count                      NUMBER;
x_msg_data                       VARCHAR2(2000);
ln_party_object_version_number   NUMBER;
ln_object_version_number         NUMBER; 
ln_records_read                  NUMBER := 0;
ln_records_success               NUMBER := 0;
ln_records_failed                NUMBER := 0;
le_skip_loop                     EXCEPTION;
ln_msg_text                      VARCHAR2(32000);
le_skip_process                  EXCEPTION;
ln_end_date_failed               NUMBER;
ln_relationship_id               NUMBER;
ln_obj_version_number            NUMBER;
ln_party_obj_ver_number          NUMBER;
ln_party_id                      hz_parties.party_id%TYPE;


BEGIN

   ------------------------------------------------
   -- Validation for Subject Orig System Reference
   ------------------------------------------------
   
   UPDATE xxod_hz_imp_relships_stg i
   SET    interface_status  = 4,
          error_text        = 'Invalid Subject Ref' 
   WHERE  interface_status  <> 7
   AND    batch_id          = p_batch_id
   AND    worker_id         = p_worker_id
   AND    NOT EXISTS        ( SELECT 1 
                              FROM   hz_orig_sys_references hosr
                              WHERE  hosr.orig_system_reference = i.sub_orig_system_reference
                              AND    hosr.orig_system           = i.sub_orig_system
                              AND    hosr.owner_table_name      = 'HZ_PARTIES'
                              AND    hosr.status                = 'A'
                            );
   
   ------------------------------------------------
   -- Validation for Object Orig System Reference
   ------------------------------------------------

   UPDATE xxod_hz_imp_relships_stg i
   SET    interface_status  = 4,
          error_text        = 'Invalid Object Ref' 
   WHERE  interface_status  <> 7
   AND    batch_id          = p_batch_id
   AND    worker_id         = p_worker_id
   AND    NOT EXISTS        ( SELECT 1 
                              FROM   hz_orig_sys_references hosr
                              WHERE  hosr.orig_system_reference = i.obj_orig_system_reference
                              AND    hosr.orig_system           = i.obj_orig_system
                              AND    hosr.owner_table_name      = 'HZ_PARTIES'
                              AND    hosr.status                = 'A'
                            );
                            
   ----------------------------------------
   -- Validation for Invalid Relation Code
   ----------------------------------------
   
   UPDATE xxod_hz_imp_relships_stg i
   SET    interface_status  = 4,
          error_text        = 'Invalid Relation Code' 
   WHERE  interface_status  <> 7
   AND    batch_id          = p_batch_id
   AND    worker_id         = p_worker_id
   AND    NOT EXISTS        ( SELECT 1 
                              FROM   ar_lookups
                              WHERE  lookup_type      = 'PARTY_RELATIONS_TYPE'
                              AND    lookup_code      = i.relationship_code
                              AND    enabled_flag     = 'Y' 
                              AND    end_date_active IS NULL
                            ); 
                            
                            
   ----------------------------------------
   -- Validation for Invalid Relation Type
   ----------------------------------------
   
   UPDATE xxod_hz_imp_relships_stg i
   SET    interface_status = 4,
          error_text       = 'Invalid Relation Type'
   WHERE  interface_status = 1
   AND    batch_id         = p_batch_id
   AND    worker_id        = p_worker_id
   AND    NOT EXISTS       ( SELECT 1 
                             FROM   hz_relationship_types
                             WHERE  relationship_type            = i.relationship_type
                             AND    hierarchical_flag            = 'Y' 
                             AND    allow_circular_relationships = 'N'
                             AND    status                       = 'A'
                           );
                           
   ---------------
   -- Open Cursor
   ---------------
   OPEN  lc_fetch_hz_relships_cur (p_batch_id,p_worker_id);
   LOOP
      FETCH lc_fetch_hz_relships_cur BULK COLLECT INTO lt_hz_imp_rel_tbl LIMIT gn_bulk_fetch_limit;
      
      IF lt_hz_imp_rel_tbl.count = 0 THEN
         log_debug_msg( 'No records exist in the staging table for batch_id - '||p_batch_id||' for party relationships');
         fnd_file.put_line(fnd_file.output, ' ');
         fnd_file.put_line(fnd_file.output, ' ');
         fnd_file.put_line(fnd_file.output, 'Record Statistics after Processing Party Relationships ');
         fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
         fnd_file.put_line(fnd_file.output, 'Staging Table - XXOD_HZ_IMP_RELSHIPS_STG ');
         fnd_file.put_line(fnd_file.output, 'No Of Records Read                   - '||ln_records_read);
         fnd_file.put_line(fnd_file.output, 'No Of Records Processesd Succesfully - '||ln_records_success);
         fnd_file.put_line(fnd_file.output, 'No Of Records Failed                 - '||ln_records_failed);
         fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
         fnd_file.put_line(fnd_file.output, ' ');
         fnd_file.put_line(fnd_file.output, ' ');
         RAISE le_skip_process;
      END IF;
      
      FOR i IN lt_hz_imp_rel_tbl.FIRST .. lt_hz_imp_rel_tbl.LAST
      LOOP
         BEGIN
            
            p_relationship_rec := p_def_relationship_rec;
            x_return_status    := NULL;
            x_msg_count        := 0;
            x_msg_data         := NULL;
            ln_records_read    := ln_records_read + 1; 
            ln_party_obj_ver_number := NULL;
            ln_party_id             := NULL;
            
            IF lt_hz_imp_rel_tbl(i).interface_status = 4 THEN
               log_exception
                  (  p_record_control_id      => lt_hz_imp_rel_tbl(i).record_id
                    ,p_source_system_code     => lt_hz_imp_rel_tbl(i).sub_orig_system
                    ,p_procedure_name         => 'VALIDATE_RELATIONSHIP'
                    ,p_staging_table_name     => 'XXOD_HZ_IMP_RELSHIPS_STG'
                    ,p_staging_column_name    => 'SUB_ORIG_SYSTEM_REFERENCE'
                    ,p_staging_column_value   => lt_hz_imp_rel_tbl(i).sub_orig_system_reference
                    ,p_source_system_ref      => lt_hz_imp_rel_tbl(i).sub_orig_system_reference
                    ,p_batch_id               => p_batch_id
                    ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('Validate Relationship returned Error - '||lt_hz_imp_rel_tbl(i).error_text)
                    ,p_oracle_error_code      => NULL
                    ,p_oracle_error_msg       => NULL
                  );
               
               ln_records_failed := ln_records_failed + 1;
               
               RAISE le_skip_loop;
            END IF;

 
               
            
            IF lt_hz_imp_rel_tbl(i).relationship_id IS NULL THEN
            
               -------------------------------------------------------------------------------
               -- Start Changes by Ambarish on 29-May-2008
               -- Check if another relationship exists for the same subject,relationship_type 
               -- if exists then end-date the relationship
               -------------------------------------------------------------------------------
               BEGIN
               
                  SELECT relationship_id,
                         object_version_number,
                         party_id
                  INTO   ln_relationship_id,
                         ln_obj_version_number,
                         ln_party_id
                  FROM   hz_relationships
                  WHERE  subject_id         = lt_hz_imp_rel_tbl(i).sub_id
                  AND    subject_table_name = 'HZ_PARTIES'
                  AND    object_table_name  = 'HZ_PARTIES'
                  AND    relationship_code  = lt_hz_imp_rel_tbl(i).relationship_code
                  AND    relationship_type  = lt_hz_imp_rel_tbl(i).relationship_type
                  AND    SYSDATE BETWEEN  NVL(start_date,SYSDATE) AND NVL(end_date,SYSDATE)
-- Added below line for QC 19705
                  AND    status='A';
               
               EXCEPTION
                  WHEN OTHERS THEN
                     ln_relationship_id := 0;
               END;  

        
               ln_end_date_failed := 0;
               
               IF ln_relationship_id <> 0 THEN
               
                   -- Get the Party Object version number -- Defect 28030

                  BEGIN 
                    SELECT object_version_number
                    INTO ln_party_obj_ver_number
                    FROM hz_parties
                    WHERE party_id = ln_party_id;
                  END;
               
                  p_relationship_rec.relationship_id    := ln_relationship_id;
                  p_relationship_rec.end_date           := SYSDATE - 1;
                  p_relationship_rec.status             := 'I';
                  ln_object_version_number              := ln_obj_version_number;

                  -- Made changes as per R12 retrofit

                  p_relationship_rec.party_rec.status   := 'I' ;
                  p_relationship_rec.party_rec.party_id := ln_party_id; 

                  HZ_RELATIONSHIP_V2PUB.update_relationship
                        (  p_init_msg_list               => gv_init_msg_list,
                           p_relationship_rec            => p_relationship_rec,
                           p_object_version_number       => ln_object_version_number,
                           p_party_object_version_number => ln_party_obj_ver_number, --ln_party_object_version_number,
                           x_return_status               => x_return_status,
                           x_msg_count                   => x_msg_count,
                           x_msg_data                    => x_msg_data
                        );

                  IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                     log_debug_msg( 'End Date Relationship successful.');
                     log_debug_msg( 'p_object_version_number : '||ln_object_version_number);
                     ln_end_date_failed := 0;
                                 
                  ELSE
                     ln_end_date_failed := 1;
                     UPDATE xxod_hz_imp_relships_stg
                     SET    interface_status = 6
                     WHERE  record_id        = lt_hz_imp_rel_tbl(i).record_id;

                     ln_records_failed := ln_records_failed + 1;

                     ln_msg_text := NULL;
                     IF x_msg_count > 0 THEN
                        log_debug_msg( 'End Date Relationship - API returned Error.');
                        FOR counter IN 1..x_msg_count 
                        LOOP
                           ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                           log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                        END LOOP;
                        FND_MSG_PUB.Delete_Msg;
                        log_exception
                           (  p_record_control_id      => lt_hz_imp_rel_tbl(i).record_id
                             ,p_source_system_code     => lt_hz_imp_rel_tbl(i).sub_orig_system
                             ,p_procedure_name         => 'END_DATE_RELATIONSHIP'
                             ,p_staging_table_name     => 'XXOD_HZ_IMP_RELSHIPS_STG'
                             ,p_staging_column_name    => 'SUB_ORIG_SYSTEM_REFERENCE'
                             ,p_staging_column_value   => lt_hz_imp_rel_tbl(i).sub_orig_system_reference
                             ,p_source_system_ref      => lt_hz_imp_rel_tbl(i).sub_orig_system_reference
                             ,p_batch_id               => p_batch_id
                             ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('End Date Relationship - API returned Error - '||ln_msg_text)
                             ,p_oracle_error_code      => NULL
                             ,p_oracle_error_msg       => NULL
                           );
                     END IF; 
                  END IF;               
                  
               END IF;     
               
               ----------
               -- Create
               ----------
               IF ln_end_date_failed = 0 THEN
               
                  p_relationship_rec := p_def_relationship_rec;
               
                  p_relationship_rec.subject_id         := lt_hz_imp_rel_tbl(i).sub_id;
                  p_relationship_rec.object_id          := lt_hz_imp_rel_tbl(i).obj_id;
                  p_relationship_rec.subject_type       := lt_hz_imp_rel_tbl(i).sub_type;
                  p_relationship_rec.object_type        := lt_hz_imp_rel_tbl(i).obj_type;
                  p_relationship_rec.subject_table_name := 'HZ_PARTIES';
                  p_relationship_rec.object_table_name  := 'HZ_PARTIES';
                  p_relationship_rec.relationship_code  := lt_hz_imp_rel_tbl(i).relationship_code;
                  p_relationship_rec.relationship_type  := lt_hz_imp_rel_tbl(i).relationship_type;
                  p_relationship_rec.start_date         := NVL(lt_hz_imp_rel_tbl(i).start_date,TRUNC(SYSDATE));
                  p_relationship_rec.end_date           := lt_hz_imp_rel_tbl(i).end_date;
                  p_relationship_rec.created_by_module  := NVL(lt_hz_imp_rel_tbl(i).created_by_module,'XXCONV');

                  HZ_RELATIONSHIP_V2PUB.create_relationship
                        (  p_init_msg_list       => gv_init_msg_list,
                           p_relationship_rec    => p_relationship_rec,
                           x_relationship_id     => x_relationship_id,
                           x_party_id            => x_party_id,
                           x_party_number        => x_party_number,
                           x_return_status       => x_return_status,
                           x_msg_count           => x_msg_count,
                           x_msg_data            => x_msg_data
                        );
                  IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                     log_debug_msg( 'Create Relationship API successful.');
                     log_debug_msg( 'x_relationship_id : '||x_relationship_id);

                     UPDATE xxod_hz_imp_relships_stg
                     SET    interface_status = 7
                     WHERE  record_id        = lt_hz_imp_rel_tbl(i).record_id;

                     ln_records_success := ln_records_success + 1;

                  ELSE
                     UPDATE xxod_hz_imp_relships_stg
                     SET    interface_status = 6
                     WHERE  record_id        = lt_hz_imp_rel_tbl(i).record_id;

                     ln_records_failed := ln_records_failed + 1;

                     ln_msg_text := NULL;
                     IF x_msg_count > 0 THEN
                        log_debug_msg( 'Create Relationship API returned Error.');
                        FOR counter IN 1..x_msg_count 
                        LOOP
                           ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                           log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                        END LOOP;
                        FND_MSG_PUB.Delete_Msg;
                        log_exception
                           (  p_record_control_id      => lt_hz_imp_rel_tbl(i).record_id
                             ,p_source_system_code     => lt_hz_imp_rel_tbl(i).sub_orig_system
                             ,p_procedure_name         => 'CREATE_RELATIONSHIP'
                             ,p_staging_table_name     => 'XXOD_HZ_IMP_RELSHIPS_STG'
                             ,p_staging_column_name    => 'SUB_ORIG_SYSTEM_REFERENCE'
                             ,p_staging_column_value   => lt_hz_imp_rel_tbl(i).sub_orig_system_reference
                             ,p_source_system_ref      => lt_hz_imp_rel_tbl(i).sub_orig_system_reference
                             ,p_batch_id               => p_batch_id
                             ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('Create Relationship API returned Error - '||ln_msg_text)
                             ,p_oracle_error_code      => NULL
                             ,p_oracle_error_msg       => NULL
                           );
                     END IF; -- IF x_msg_count > 0 THEN
                  END IF; -- IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
               END IF; -- IF ln_end_date_failed = 0 THEN
            ELSE --IF lt_hz_imp_rel_tbl(i).relationship_id IS NULL THEN
               ----------
               -- Update
               ----------

               log_debug_msg( 'Processing relationship id : '|| lt_hz_imp_rel_tbl(i).relationship_id);
               
               p_relationship_rec.relationship_id    := lt_hz_imp_rel_tbl(i).relationship_id;
               p_relationship_rec.start_date         := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_date(lt_hz_imp_rel_tbl(i).start_date);
               --p_relationship_rec.end_date         := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_date(lt_hz_imp_rel_tbl(i).end_date);
               p_relationship_rec.end_date           := NVL(lt_hz_imp_rel_tbl(i).end_date,FND_API.G_MISS_DATE);
               ln_object_version_number              := lt_hz_imp_rel_tbl(i).object_version_number;
               p_relationship_rec.status             := 'A';
               

              -- R12 Retrofit Defect 28030 

               -- Get party details from Relationship record

               SELECT hr.party_id,
                      hp.object_version_number
               INTO   ln_party_id,
                      ln_party_obj_ver_number
               FROM hz_relationships hr,
                    hz_parties hp
               WHERE hr.party_id = hp.party_id
               AND hr.relationship_id = lt_hz_imp_rel_tbl(i).relationship_id
               AND ROWNUM < 2;

               p_relationship_rec.party_rec.status    := 'A' ;
               p_relationship_rec.party_rec.party_id  := ln_party_id; 
              ln_party_object_version_number          := ln_party_obj_ver_number;


              log_debug_msg( 'party id: '|| ln_party_id);

               HZ_RELATIONSHIP_V2PUB.update_relationship
                     (  p_init_msg_list               => gv_init_msg_list,
                        p_relationship_rec            => p_relationship_rec,
                        p_object_version_number       => ln_object_version_number,
                        p_party_object_version_number => ln_party_object_version_number,
                        x_return_status               => x_return_status,
                        x_msg_count                   => x_msg_count,
                        x_msg_data                    => x_msg_data
                     );
                     
               IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                  log_debug_msg( 'Update Relationship API successful.');
                  log_debug_msg( 'p_object_version_number : '||ln_object_version_number);

                  UPDATE xxod_hz_imp_relships_stg
                  SET    interface_status = 7
                  WHERE  record_id        = lt_hz_imp_rel_tbl(i).record_id;
                  
                  ln_records_success := ln_records_success + 1;

               ELSE
                  UPDATE xxod_hz_imp_relships_stg
                  SET    interface_status = 6
                  WHERE  record_id        = lt_hz_imp_rel_tbl(i).record_id;
                  
                  ln_records_failed := ln_records_failed + 1;
                  
                  ln_msg_text := NULL;
                  IF x_msg_count > 0 THEN
                     log_debug_msg( 'Update Relationship API returned Error.');
                     FOR counter IN 1..x_msg_count 
                     LOOP
                        ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                        log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                     END LOOP;
                     FND_MSG_PUB.Delete_Msg;
                     log_exception
                        (  p_record_control_id      => lt_hz_imp_rel_tbl(i).record_id
                          ,p_source_system_code     => lt_hz_imp_rel_tbl(i).sub_orig_system
                          ,p_procedure_name         => 'UPDATE_RELATIONSHIP'
                          ,p_staging_table_name     => 'XXOD_HZ_IMP_RELSHIPS_STG'
                          ,p_staging_column_name    => 'SUB_ORIG_SYSTEM_REFERENCE'
                          ,p_staging_column_value   => lt_hz_imp_rel_tbl(i).sub_orig_system_reference
                          ,p_source_system_ref      => lt_hz_imp_rel_tbl(i).sub_orig_system_reference
                          ,p_batch_id               => p_batch_id
                          ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('Update Relationship API returned Error - '||ln_msg_text)
                          ,p_oracle_error_code      => NULL
                          ,p_oracle_error_msg       => NULL
                        );
                  END IF; 
               END IF;
               
            END IF;
         
         EXCEPTION
            WHEN le_skip_loop THEN
               NULL;
            WHEN OTHERS THEN
               log_debug_msg( 'Unexpected Error in LOOP - '||SQLERRM);
         END;
      END LOOP;
      
      --------------------
      -- Clear the tables
      --------------------
      lt_hz_imp_rel_tbl.DELETE;
      EXIT WHEN lc_fetch_hz_relships_cur%NOTFOUND;
      
   END LOOP;
   CLOSE lc_fetch_hz_relships_cur;
   
   --ln_records_failed := (ln_records_read - ln_records_success);
   
   log_debug_msg( ' ');
   log_debug_msg( ' ');
   log_debug_msg( 'Record Statistics after Processing Party Relationships ');
   log_debug_msg( '-------------------------------------------------------------');
   log_debug_msg( 'Staging Table - XXOD_HZ_IMP_RELSHIPS_STG ');
   log_debug_msg( 'No Of Records Read                   - '||ln_records_read);
   log_debug_msg( 'No Of Records Processesd Succesfully - '||ln_records_success);
   log_debug_msg( 'No Of Records Failed                 - '||ln_records_failed);
   log_debug_msg( '-------------------------------------------------------------');
   log_debug_msg( ' ');
   log_debug_msg( ' ');

   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, 'Record Statistics after Processing Processing Party Relationships ');
   fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
   fnd_file.put_line(fnd_file.output, 'Staging Table - XXOD_HZ_IMP_RELSHIPS_STG ');
   --fnd_file.put_line(fnd_file.output, 'No Of Records Read                   - '||ln_records_read);
   --fnd_file.put_line(fnd_file.output, 'No Of Records Processesd Succesfully - '||ln_records_success);
   --fnd_file.put_line(fnd_file.output, 'No Of Records Failed                 - '||ln_records_failed);
   --fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
   
   
   FOR lc_get_staging_counts_rec IN lc_get_staging_counts_cur (p_batch_id)
   LOOP
   
      fnd_file.put_line(fnd_file.output, lc_get_staging_counts_rec.interface_status ||'   -   '||lc_get_staging_counts_rec.count_rec );   
   
   END LOOP;
   fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, ' ');

   
EXCEPTION
   WHEN le_skip_process THEN 
      NULL;
   WHEN OTHERS THEN
      log_debug_msg( 'Unexpected Error in procedure party_relationship_worker - '||SQLERRM);
      x_retcode := 2;
      x_errbuf  := 'Unexpected Error in procedure party_relationship_worker - '||SQLERRM;
END party_relationship_worker;
-- +===================================================================+
-- | Name        : log_debug_msg                                       |
-- |                                                                   |
-- | Description : Procedure used to store the count of records that   |
-- |               are processed/failed/succeeded                      |
-- | Parameters  : p_debug_msg                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE log_debug_msg
    ( p_debug_msg  IN  VARCHAR2 )
AS

BEGIN
    XX_CDH_CONV_MASTER_PKG.write_conc_log_message( p_debug_msg);
END log_debug_msg;

-- +===================================================================+
-- | Name        : log_exception                                       |
-- | Description : This procedure is used for logging exceptions into  |
-- |               conversion common elements tables.                  |
-- |                                                                   |
-- | Parameters  : p_conversion_id,p_record_control_id,p_procedure_name|
-- |               p_batch_id,p_exception_log,p_oracle_error_msg       |
-- +===================================================================+
PROCEDURE log_exception
    (
         p_record_control_id      IN NUMBER
        ,p_source_system_code     IN VARCHAR2
        ,p_source_system_ref      IN VARCHAR2
        ,p_procedure_name         IN VARCHAR2
        ,p_staging_table_name     IN VARCHAR2
        ,p_staging_column_name    IN VARCHAR2
        ,p_staging_column_value   IN VARCHAR2
        ,p_batch_id               IN NUMBER
        ,p_exception_log          IN VARCHAR2
        ,p_oracle_error_code      IN VARCHAR2
        ,p_oracle_error_msg       IN VARCHAR2
    )

AS
lc_package_name             VARCHAR2(32) := 'XX_CDH_PARTY_RELATIONSHIPS_PKG';
ln_conversion_id            NUMBER        := 00247;
BEGIN

    XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
        (
             p_conversion_id          => ln_conversion_id
            ,p_record_control_id      => p_record_control_id
            ,p_source_system_code     => p_source_system_code
            ,p_package_name           => lc_package_name
            ,p_procedure_name         => p_procedure_name
            ,p_staging_table_name     => p_staging_table_name
            ,p_staging_column_name    => p_staging_column_name
            ,p_staging_column_value   => p_staging_column_value
            ,p_source_system_ref      => p_source_system_ref
            ,p_batch_id               => p_batch_id
            ,p_exception_log          => p_exception_log
            ,p_oracle_error_code      => p_oracle_error_code
            ,p_oracle_error_msg       => p_oracle_error_msg
        );
EXCEPTION
    WHEN OTHERS THEN
        log_debug_msg('LOG_EXCEPTION: Error in logging exception :'||SQLERRM);
 
END log_exception;


END XX_CDH_PARTY_RELATIONSHIPS_PKG;
/
SHOW ERRORS;