SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_TM_NMDACCT_GDW_PREPROC package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_TM_NMDACCT_GDW_PREPROC
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_TM_NMDACCT_GDW_PREPROC                                     |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM GDW Party Site Named Account Mass Assignment  |
-- |                     Preprocessor Master Program'. This public procedure will      |
-- |                     launch a number of child processes for each of the batch_id's |
-- |                     present in hz_imp_batch_summary table.                        |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    master_main             This is the public procedure                  |
-- |PROCEDURE    child_main              This is the public procedure                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  23-Jun-08   Abhradip Ghosh               Initial draft version           |
-- +===================================================================================+
AS

------------------------------
-- Declaring Global Constants
------------------------------

------------------------------
-- Declaring Global Variables
------------------------------

-------------------------------------
-- Declaring Global Record Variables
-------------------------------------
TYPE grec_insert_preproc      IS TABLE OF xxcrm.xx_tm_nmdactasgn_preprocessor%ROWTYPE INDEX BY PLS_INTEGER;
gt_insert_preproc             grec_insert_preproc;
gt_idx_ins_preproc            grec_insert_preproc;
-----------------------------------------
-- Declaring Global Table Type Variables
-----------------------------------------

-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_log(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the log file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
END write_log;

-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_out(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the output file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
END write_out;

-- +===================================================================+
-- | Name  : master_main                                               |
-- |                                                                   |
-- | Description: This is the public procedure which will get called   |
-- |              from the concurrent program 'OD: TM GDW Named Account|
-- |              Assignment Preprocessor Master Program' to launch a  |
-- |              number of child processes for parallel execution for |
-- |              each of the batch_id's present in                    |
-- |              hz_imp_batch_summary table.                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE master_main
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
            )
IS
-----------------------------
-- Declaring Local Variables
-----------------------------
EX_SUBMIT_CHILD               EXCEPTION;
ln_succ_batch_id              PLS_INTEGER;
ln_batch_size                 PLS_INTEGER;
ln_batch_id                   PLS_INTEGER;
ln_min_range_record_id        PLS_INTEGER;
ln_max_range_record_id        PLS_INTEGER;
ln_value                      PLS_INTEGER;
ln_min_record_id              PLS_INTEGER;
ln_max_record_id              PLS_INTEGER;
ln_request_id                 PLS_INTEGER;
ln_batch_count                PLS_INTEGER := 0;
ln_dpl_resource_id            PLS_INTEGER;
ln_dpl_resource_role_id       PLS_INTEGER;
ln_dpl_group_id               PLS_INTEGER;
ln_count_named_acct_terr_id   PLS_INTEGER := 0;
ln_max_named_acct_terr_id     PLS_INTEGER;
ln_min_named_acct_terr_id     PLS_INTEGER;
ln_entity_id                  PLS_INTEGER;
ln_upd_profile_batch_id       PLS_INTEGER := 0;
lc_error_message              VARCHAR2(2000);
lc_set_message                VARCHAR2(2000);
lc_message                    VARCHAR2(2000);
lc_phase                      VARCHAR2(03);

-- --------------------------------------------------------------------------------
-- Declare cursor to fetch the batch_ids greater than the value stored in profile
-- --------------------------------------------------------------------------------
CURSOR lcu_batch_id
IS
SELECT hibs.batch_id
FROM   hz_imp_batch_summary hibs
WHERE hibs.original_system ='GDW'
AND NOT EXISTS
             ( SELECT 1 
               FROM   xx_tm_nam_gdw_batches x 
               WHERE  x.batch_id = hibs.batch_id)
ORDER BY hibs.batch_id;

-- ----------------------
-- Declaring Table Types
-- ----------------------
TYPE batch_id_tbl_type IS TABLE OF lcu_batch_id%ROWTYPE INDEX BY BINARY_INTEGER;
lt_batch_id      batch_id_tbl_type;
lt_batch_id_init batch_id_tbl_type;

BEGIN
   
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------
   
   WRITE_LOG(RPAD(' ',1,' ')||RPAD('Office Depot',60)||RPAD(' ',23,' ')||'Date: '||trunc(sysdate));
   WRITE_LOG(RPAD(' ',100,'-'));
   WRITE_LOG(RPAD(' ',1,' ')||LPAD('OD: TM GDW Named Account Assignment Preprocessor Master Program',80));
   WRITE_LOG(RPAD(' ',100,'-'));
   WRITE_LOG('');
   
   WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',60)||RPAD(' ',23,' ')||'Date: '||trunc(sysdate));
   WRITE_OUT(RPAD(' ',100,'-'));
   WRITE_OUT(RPAD(' ',1,' ')||LPAD('OD: TM GDW Named Account Assignment Preprocessor Master Program',80));
   WRITE_OUT(RPAD(' ',100,'-'));
   WRITE_OUT('');
   WRITE_OUT(RPAD(' ',100,'-'));
   
   -- Derive the batch Size from the profile
   
   ln_batch_size := NVL(FND_PROFILE.VALUE('XX_TM_PARTY_SITE_BATCH_SIZE'),G_BATCH_SIZE);
   
   -- Fetch the last successfully processed batch_id from the profile value
   
   BEGIN
   
        SELECT FPOV.profile_option_value
        INTO   ln_upd_profile_batch_id
        FROM   fnd_profile_option_values FPOV
               , fnd_profile_options FPO
        WHERE  FPO.profile_option_id = FPOV.profile_option_id
        AND    FPO.application_id = FPOV.application_id
        AND    FPOV.level_id = G_LEVEL_ID
        AND    FPOV.level_value = G_LEVEL_VALUE
        AND    FPOV.profile_option_value IS NOT NULL
        AND    FPO.profile_option_name = 'XX_TM_GDW_BATCH_ID';
   
   EXCEPTION
      WHEN OTHERS THEN
          ln_upd_profile_batch_id := 0;
   END;
   
   -- Fetch all the batch_ids greater than the value derived from the profile
   -- to launch each batch based on the batch size
   --ln_succ_batch_id:=293004;
   --write_out('ln_succ_batch_id =>'||ln_succ_batch_id);
   --OPEN  lcu_batch_id(ln_upd_profile_batch_id);
   --FETCH lcu_batch_id BULK COLLECT INTO lt_batch_id;
   --CLOSE lcu_batch_id;
   
   OPEN lcu_batch_id;
   FETCH lcu_batch_id BULK COLLECT INTO lt_batch_id;
   CLOSE lcu_batch_id;   
   
   IF lt_batch_id.COUNT <> 0 THEN
      
      FOR i IN lt_batch_id.FIRST .. lt_batch_id.LAST
      LOOP
          
          -- Initializing the variable
          ln_batch_id := NULL;
          
          ln_batch_id := lt_batch_id(i).batch_id;
          -- Select minimum and maximum record_id 
          -- from extensible attributes staging table depending upon the batch id
          /*
          SELECT   MIN(XHI.record_id)
                 , MAX(XHI.record_id)
          INTO   ln_min_range_record_id
                 , ln_max_range_record_id
          FROM   xxod_hz_imp_ext_attribs_stg XHI 
          WHERE  XHI.batch_id  = ln_batch_id 
          and    XHI.attribute_group_code='SITE_DEMOGRAPHICS'
          AND    XHI.interface_status ='7';
          */
          
          BEGIN
          
          SELECT min_rec,
                 max_rec
          INTO   ln_min_range_record_id
                ,ln_max_range_record_id         
          FROM(
                 SELECT  MIN(XHI.record_id) OVER (PARTITION BY XHI.batch_id) min_rec 
                        ,MAX(XHI.record_id) OVER (PARTITION BY XHI.batch_id) max_rec 
                 FROM   xxod_hz_imp_ext_attribs_stg XHI 
                 WHERE  XHI.batch_id  = ln_batch_id
                 and    XHI.attribute_group_code='SITE_DEMOGRAPHICS'
                 AND    XHI.interface_status ='7'
              )         
          WHERE ROWNUM = 1;
          
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_min_range_record_id := NULL;
               ln_max_range_record_id := NULL;
            WHEN OTHERS THEN
               ln_min_range_record_id := NULL;
               ln_max_range_record_id := NULL;
          END;
          
            
          
          IF (ln_min_range_record_id IS NOT NULL AND ln_max_range_record_id IS NOT NULL) THEN
             
           ln_value := -1;             
           IF CEIL((ln_max_range_record_id - ln_min_range_record_id) / ln_batch_size) > 0 THEN
           
             FOR j in 1.. CEIL((ln_max_range_record_id - ln_min_range_record_id) / ln_batch_size) 
             LOOP
                 
                 ln_min_record_id := ((ln_min_range_record_id + j + ln_value) + (ln_batch_size * (j-1)));
                 
                 ln_max_record_id := CASE WHEN 
                                          ((ln_min_range_record_id + j + ln_value) + (ln_batch_size * j)) > ln_max_range_record_id
                                                  THEN ln_max_range_record_id
                                          ELSE ((ln_min_range_record_id + j + ln_value) + (ln_batch_size * j)) 
                                     END;
                 
                 -- ---------------------------------------------------------
                 -- Call the custom concurrent program for parallel execution
                 -- ---------------------------------------------------------
                 ln_request_id := FND_REQUEST.submit_request(
                                                             application   => G_APPLICATION_NAME
                                                             , program     => G_CHLD_PROG_EXECUTABLE
                                                             , sub_request => FALSE
                                                             , argument1   => ln_min_record_id
                                                             , argument2   => ln_max_record_id
                                                             , argument3   => ln_batch_id
                                                            ); 
                 
                 IF ln_request_id = 0 THEN
                                           
                    RAISE EX_SUBMIT_CHILD;
                                        
                 ELSE
                                             
                     COMMIT;
                     gn_index_req_id                                    := gn_index_req_id + 1;
                     gt_req_id_batch_id(gn_index_req_id).request_id     := ln_request_id;
                     gt_req_id_batch_id(gn_index_req_id).batch_id       := ln_batch_id;
                     gt_req_id_batch_id(gn_index_req_id).from_record_id := ln_min_record_id;
                     gt_req_id_batch_id(gn_index_req_id).to_record_id   := ln_max_record_id;
                     ln_batch_count                                     := ln_batch_count + 1;
                     
                 END IF; -- ln_request_id = 0 
                 
             END LOOP;
             
           ELSE
                 ln_request_id := FND_REQUEST.submit_request(
                                                             application   => G_APPLICATION_NAME
                                                             , program     => G_CHLD_PROG_EXECUTABLE
                                                             , sub_request => FALSE
                                                             , argument1   => ln_min_range_record_id
                                                             , argument2   => ln_max_range_record_id
                                                             , argument3   => ln_batch_id
                                                            ); 
                 
                 IF ln_request_id = 0 THEN
                                           
                    RAISE EX_SUBMIT_CHILD;
                                        
                 ELSE
                                             
                     COMMIT;
                     gn_index_req_id                                    := gn_index_req_id + 1;
                     gt_req_id_batch_id(gn_index_req_id).request_id     := ln_request_id;
                     gt_req_id_batch_id(gn_index_req_id).batch_id       := ln_batch_id;
                     gt_req_id_batch_id(gn_index_req_id).from_record_id := ln_min_range_record_id;
                     gt_req_id_batch_id(gn_index_req_id).to_record_id   := ln_max_range_record_id;
                     ln_batch_count                                     := ln_batch_count + 1;
                     
                 END IF; -- ln_request_id = 0 
           
           END IF;
           
          ELSE
              
              WRITE_LOG('No Record exists for this batch_id : '||ln_batch_id);
              
          END IF;
          
      END LOOP;
   
   ELSE
       
       WRITE_LOG('No Batch id exists in hz_imp_batch_summary table for GDW ');
       
   END IF; -- lt_batch_id.COUNT <> 0
   
   -- Delete the table type
   lt_batch_id.DELETE;
   lt_batch_id := lt_batch_id_init;
   
   -- ----------------------------------------------------------------------------
   -- Write to output file batch size, the total number of batches launched,
   -- ----------------------------------------------------------------------------
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0234_BATCH_SIZE');
   FND_MESSAGE.SET_TOKEN('P_BATCH_SIZE', ln_batch_size);
   lc_message    := FND_MESSAGE.GET;
   WRITE_OUT(lc_message);
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0235_BATCHES_LAUNCHED');
   FND_MESSAGE.SET_TOKEN('P_BATCH_LAUNCHED', ln_batch_count);
   lc_message    := FND_MESSAGE.GET;
   WRITE_OUT(lc_message);
   
   WRITE_OUT(RPAD('-',100,'-'));
   WRITE_OUT(RPAD('-',100,'-'));
   WRITE_OUT(
             RPAD('Request_Id',20,' ')||RPAD(' ',5,' ')||
             RPAD('Batch_Id',20,' ')||RPAD(' ',5,' ')||
             RPAD('From_Record_Id',20,' ')||RPAD(' ',5,' ')||
             RPAD('To_Record_Id',20,' ')||RPAD(' ',5,' ')
            );
   WRITE_OUT(
             RPAD('-',20,'-')||RPAD(' ',5,' ')||
             RPAD('-',20,'-')||RPAD(' ',5,' ')||
             RPAD('-',20,'-')||RPAD(' ',5,' ')||
             RPAD('-',20,'-')||RPAD(' ',5,' ')
            );
            
   IF gt_req_id_batch_id.COUNT <> 0 THEN
                        
     FOR i IN gt_req_id_batch_id.FIRST .. gt_req_id_batch_id.LAST
     LOOP
                           
         WRITE_OUT(
                   RPAD(gt_req_id_batch_id(i).request_id,20,' ')||RPAD(' ',5,' ')||
                   RPAD(gt_req_id_batch_id(i).batch_id,20,' ')||RPAD(' ',5,' ')||
                   RPAD(gt_req_id_batch_id(i).from_record_id,20,' ')||RPAD(' ',5,' ')||
                   RPAD(gt_req_id_batch_id(i).to_record_id,20,' ')||RPAD(' ',5,' ')
                  );
                        
     END LOOP;
                        
   END IF;
   
   -- --------------------------------------------------
   -- To check whether the child requests have finished
   -- If not then wait
   -- --------------------------------------------------
   IF gt_req_id_batch_id.COUNT <> 0 THEN
   
      FOR i IN gt_req_id_batch_id.FIRST .. gt_req_id_batch_id.LAST
      LOOP

          LOOP

              SELECT FCR.phase_code
              INTO   lc_phase
              FROM   fnd_concurrent_requests FCR
              WHERE  FCR.request_id = gt_req_id_batch_id(i).request_id;

              IF lc_phase = 'C' THEN
                 EXIT;
              ELSE
                  DBMS_LOCK.SLEEP(G_SLEEP);
              END IF;
          END LOOP;
      END LOOP;
      
   END IF;
   
   DBMS_SESSION.free_unused_user_memory;
   
EXCEPTION
   WHEN EX_SUBMIT_CHILD THEN
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0237_SUBMIT_CHILD_ERR');
      lc_error_message := FND_MESSAGE.GET;
      x_retcode   := 2;
      x_errbuf    := lc_error_message;
      WRITE_LOG(lc_error_message);
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating a batch to process the party_site_id';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       x_errbuf         := lc_error_message;
       x_retcode        := 2 ;
       WRITE_LOG(x_errbuf);
END master_main;

-- +===================================================================+
-- | Name  : Insert_Row                                                |
-- |                                                                   |
-- | Description:       This is the public procedure will be used to   |
-- |                    insert record in the custom table              |
-- |                    xx_tm_nmdactasgn_preprocessor                  |
-- |                                                                   |
-- +===================================================================+

PROCEDURE insert_row
            (
               pt_insert_preproc        IN      grec_insert_preproc
             , x_return_status          OUT     NOCOPY VARCHAR2                    
             , x_msg_count              OUT     NOCOPY NUMBER                      
             , x_message_data           OUT     NOCOPY VARCHAR2
             , x_record_inserted        OUT NOCOPY PLS_INTEGER
            )
IS

-----------------------------
-- Declaring local variables
-----------------------------
EX_INSERT_ROW                EXCEPTION;
ln_preprocessor_record_id    NUMBER;
lc_error_message             VARCHAR2(1000);
lc_set_message               VARCHAR2(2000);
lc_record_inserted           PLS_INTEGER := 0;

t_insert_preproc              grec_insert_preproc;
t_insert_preproc_init         grec_insert_preproc;

BEGIN
          
          t_insert_preproc := pt_insert_preproc;
          
          FORALL i IN INDICES OF gt_idx_ins_preproc
          INSERT INTO xx_tm_nmdactasgn_preprocessor VALUES t_insert_preproc(i);
                   
          lc_record_inserted := SQL%ROWCOUNT;                        
 
          x_record_inserted := lc_record_inserted;
          
          t_insert_preproc.DELETE;
          t_insert_preproc := t_insert_preproc_init;
                                 
EXCEPTION
   WHEN OTHERS THEN
       x_return_status  :=  FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message  :=  'In Procedure: INSERT_ROW: Unexpected Error : ';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       FND_MSG_PUB.add;
END insert_row;

-- +===================================================================+
-- | Name  : child_main                                                |
-- |                                                                   |
-- | Description: This is the public procedure which will get          |
-- |              called from the concurrent program 'OD: TM GDW Named |
-- |              Account Assignment Preprocessor Child Program'       |
-- |              with Batch ID as the Input parameters to  create a   |
-- |              party site record in the custom assignments table    |
-- |                                                                   |
-- +===================================================================+

PROCEDURE child_main
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_min_record_id      IN  NUMBER
             , p_max_record_id      IN  NUMBER
             , p_batch_id           IN  NUMBER
            )
IS
-----------------------------
-- Declaring Local Variables
-----------------------------
EX_PARTY_SITE_ERROR          EXCEPTION;
EX_CREATE_ERR                EXCEPTION;
l_squal_num01                NUMBER;
l_squal_num02                NUMBER;
l_squal_num03                NUMBER;
l_squal_num04                NUMBER;
l_squal_num05                NUMBER;
l_squal_num06                NUMBER;
l_squal_num07                NUMBER;
ln_api_version               PLS_INTEGER := 1.0;
ln_msg_count                 PLS_INTEGER;
l_counter                    PLS_INTEGER;
ln_salesforce_id             PLS_INTEGER;
ln_sales_group_id            PLS_INTEGER;
ln_asignee_role_id           PLS_INTEGER;
ln_total_count               PLS_INTEGER := 0;
ln_error_count               PLS_INTEGER := 0;
ln_success_count             PLS_INTEGER := 0;
ln_exists_count              PLS_INTEGER := 0;
ln_named_acct_terr_id        PLS_INTEGER;
ln_count                     PLS_INTEGER;
ln_terr_resource_id          PLS_INTEGER;
ln_terr_role_id              PLS_INTEGER;
ln_terr_group_id             PLS_INTEGER;
ln_acct_terr_id              PLS_INTEGER;
ln_party_site_id             PLS_INTEGER;
ln_min_party_site_id         PLS_INTEGER;
ln_max_party_site_id         PLS_INTEGER;
ln_min_record_id             PLS_INTEGER;
ln_max_record_id             PLS_INTEGER;
ln_party_internal            PLS_INTEGER := 0;
ln_party_site_err            PLS_INTEGER := 0;
ln_admin_count               PLS_INTEGER;
lc_error_message             VARCHAR2(4000);
lc_return_status             VARCHAR2(03);
lc_msg_data                  VARCHAR2(2000);
lc_full_access_flag          VARCHAR2(03);
lc_set_message               VARCHAR2(2000);
lc_total_count               VARCHAR2(1000);
lc_total_success             VARCHAR2(1000);
lc_total_failed              VARCHAR2(1000);
lc_total_exists              VARCHAR2(1000);
lc_pty_site_success          VARCHAR2(03);
lc_role                      VARCHAR2(50);
l_squal_char01               VARCHAR2(4000);
l_squal_char02               VARCHAR2(4000);
l_squal_char03               VARCHAR2(4000);
l_squal_char04               VARCHAR2(4000);
l_squal_char05               VARCHAR2(4000);
l_squal_char06               VARCHAR2(4000);
l_squal_char07               VARCHAR2(4000);
l_squal_char08               VARCHAR2(4000);
l_squal_char09               VARCHAR2(4000);
l_squal_char10               VARCHAR2(4000);
l_squal_char11               VARCHAR2(4000);
l_squal_char50               VARCHAR2(4000);
l_squal_char59               VARCHAR2(4000);
l_squal_char60               VARCHAR2(4000);
l_squal_char61               VARCHAR2(4000);
l_squal_num60                VARCHAR2(4000);
l_squal_curc01               VARCHAR2(4000);
lc_manager_flag              VARCHAR2(03);
lc_message_code              VARCHAR2(30);
lc_party_site_assign_exists  VARCHAR2(10);


lc_concat_rsc_role_grp_id    VARCHAR2(2000);
lc_rsc_role_grp_flag         VARCHAR2(03);
lc_acct_party_site_id_exists VARCHAR2(10);
lc_acct_party_id_exists      VARCHAR2(10);
lc_assignee_admin_flag       VARCHAR2(03);
lc_status                    VARCHAR2(03);
ln_terr_id                   PLS_INTEGER;        
lc_resource_name             VARCHAR2(2000);
lc_terr_name                 VARCHAR2(1000); 
lc_terr_desc                 VARCHAR2(1000);
ln_party_id                  PLS_INTEGER;
lc_party_name                VARCHAR2(1000);
lc_resource_role_code        VARCHAR2(200);
lc_resource_od_role_code     VARCHAR2(250);
lc_cust_prospect             VARCHAR2(50);
lc_postal_code               VARCHAR2(50);
lc_country                   VARCHAR2(50);
lc_od_site_sic_code          VARCHAR2(250);
ln_od_wcw                    PLS_INTEGER;
lc_resource_group_name       VARCHAR2(500);
lc_resource_role_div         VARCHAR2(100);


-----------------------------------
-- Declaring Record Type Variables
-----------------------------------
TYPE terr_rsc_role_grp_id_rec_type IS RECORD
    (
      NAMED_ACCT_TERR_ID   NUMBER
      , RESOURCE_ID        NUMBER
      , ROLE_ID            NUMBER
      , GROUP_ID           NUMBER
      , ENTITY_ID          NUMBER
    );

lp_gen_bulk_rec        JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type;
lx_gen_return_rec      JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;
lx_gen_return_rec_init JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;

-- ------------------------------------------------------------------
-- Declare cursor to fetch the orig_system_reference for the records
-- ------------------------------------------------------------------
CURSOR lcu_party_sites(
                       p_min_record_id   NUMBER
                       , p_max_record_id NUMBER
                       , p_batch_id      NUMBER
                      )
IS
SELECT HPS.party_site_id,XHI.record_id
FROM   xxod_hz_imp_ext_attribs_stg XHI 
       , hz_party_sites HPS
       , hz_parties HP
WHERE  XHI.batch_id  = p_batch_id
AND    XHI.record_id BETWEEN p_min_record_id AND p_max_record_id
--AND    XHI.orig_system_reference = HPS.orig_system_reference
AND    HPS.PARTY_SITE_ID = xhi.owner_table_id
AND    XHI.OWNER_TABLE_NAME='HZ_PARTY_SITES'
and    xhi.attribute_group_code='SITE_DEMOGRAPHICS'
and    xhi.interface_status ='7'
AND    HPS.status = 'A'
AND    HP.party_id = HPS.party_id
AND    HP.party_type = 'ORGANIZATION'
AND    HP.status = 'A'
ORDER BY XHI.record_id;

-- --------------------------------------------------------------------------------------
-- Declare cursor to verify whether the party_site_id already exists in the entity table
-- --------------------------------------------------------------------------------------
CURSOR lcu_party_site_assign_exists(
                       p_min_record_id   NUMBER
                       , p_max_record_id NUMBER
                       , p_batch_id      NUMBER
                                   )
IS
SELECT TERR.named_acct_terr_id named_acct_terr_id
       , TERR_RSC.resource_id resource_id
       , TERR_RSC.resource_role_id role_id
       , TERR_RSC.group_id group_id
       , TERR_ENT.entity_id
FROM   xx_tm_nam_terr_defn          TERR
       , xx_tm_nam_terr_entity_dtls TERR_ENT
       , xx_tm_nam_terr_rsc_dtls    TERR_RSC
       , xxod_hz_imp_ext_attribs_stg XHI 
WHERE  TERR.named_acct_terr_id = TERR_ENT.named_acct_terr_id
AND    TERR.named_acct_terr_id = TERR_RSC.named_acct_terr_id
AND    SYSDATE between TERR.start_date_active AND NVL(TERR.end_date_active,SYSDATE)
AND    SYSDATE between TERR_ENT.start_date_active AND NVL(TERR_ENT.end_date_active,SYSDATE)
AND    SYSDATE between TERR_RSC.start_date_active AND NVL(TERR_RSC.end_date_active,SYSDATE)
AND    NVL(TERR.status,'A')     = 'A'
AND    NVL(TERR_ENT.status,'A') = 'A'
AND    NVL(TERR_RSC.status,'A') = 'A'
AND    TERR_ENT.entity_type = 'PARTY_SITE'
AND    TERR_ENT.entity_id =xhi.owner_table_id
and    XHI.owner_table_name='HZ_PARTY_SITES'
and    xhi.attribute_group_code='SITE_DEMOGRAPHICS'
and    xhi.interface_status ='7'
AND    XHI.BATCH_ID = p_batch_id 
AND    XHI.RECORD_ID BETWEEN P_MIN_RECORD_ID AND P_MAX_RECORD_ID--BETWEEN p_from_party_site_id AND p_to_party_site_id
ORDER BY TERR_ENT.entity_id;

-- -------------------------------------------------------------
-- Declare cursor to fetch the record from the hz_cust_accounts
-- -------------------------------------------------------------
CURSOR lcu_acct_party_site_valid(
                       p_min_record_id   NUMBER
                       , p_max_record_id NUMBER
                       , p_batch_id      NUMBER
                                 
                                )
IS
SELECT HCA.attribute18
       , HCAS.party_site_id
       , HCA.customer_type
FROM   hz_cust_accounts HCA
       , hz_cust_acct_sites HCAS
       , xxod_hz_imp_ext_attribs_stg XHI        
WHERE  HCAS.cust_account_id = HCA.cust_account_id
AND    HCA.status='A'
AND    HCAS.status ='A'
AND    HCA.status = HCAS.status
AND    HCAS.party_site_id=xhi.owner_table_id
and    XHI.owner_table_name='HZ_PARTY_SITES'
and    xhi.attribute_group_code='SITE_DEMOGRAPHICS'
and    xhi.interface_status ='7'
AND    XHI.BATCH_ID = p_batch_id 
AND    XHI.RECORD_ID BETWEEN P_MIN_RECORD_ID AND P_MAX_RECORD_ID
ORDER BY HCAS.party_site_id;

-- ---------------------------------------------------------
-- Declare cursor to check whether the resource is an admin
-- ---------------------------------------------------------
CURSOR lcu_admin(
                 p_resource_id NUMBER
                 , p_group_id  NUMBER DEFAULT NULL
                )
IS
SELECT count(ROL.admin_flag)
FROM   jtf_rs_role_relations JRR
       , jtf_rs_group_members MEM
       , jtf_rs_group_usages JRU
       , jtf_rs_roles_b ROL
WHERE  MEM.resource_id = p_resource_id
AND    NVL(MEM.delete_flag,'N') <> 'Y'
AND    MEM.group_id = NVL(p_group_id,MEM.group_id)
AND    JRU.group_id = MEM.group_id
AND    JRU.usage = 'SALES'
AND    JRR.role_resource_id    = MEM.group_member_id
AND    JRR.role_resource_type  = 'RS_GROUP_MEMBER'
AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) 
                      AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
AND    NVL(JRR.delete_flag,'N') <> 'Y'                          
AND    ROL.role_id = JRR.role_id
AND    ROL.role_type_code='SALES'
AND    ROL.admin_flag = 'Y'
AND    ROL.active_flag = 'Y';

-- -------------------------------
-- Declaring table type variables
-- -------------------------------
TYPE party_sites_tbl_type IS TABLE OF lcu_party_sites%ROWTYPE INDEX BY BINARY_INTEGER;
lt_party_sites             party_sites_tbl_type;
lt_party_sites_initialize  party_sites_tbl_type;

TYPE terr_rsc_role_grp_id_tbl_type IS TABLE OF terr_rsc_role_grp_id_rec_type INDEX BY BINARY_INTEGER;
lt_terr_rsc_role_grp_id terr_rsc_role_grp_id_tbl_type;

TYPE acct_party_site_tbl_type IS TABLE OF lcu_acct_party_site_valid%ROWTYPE INDEX BY BINARY_INTEGER;
lt_acct_party_site_id acct_party_site_tbl_type;

xt_insert_preprocessor        grec_insert_preproc;
xt_insert_index_rec_init      grec_insert_preproc;

ln_insert_count               PLS_INTEGER := 0;
ln_preprocessor_record_id     NUMBER      := 0;
lc_total_rec_inserted         PLS_INTEGER      := 0;

ln_party_site_assign_exists   PLS_INTEGER :=0;
ln_not_cont_cust_exists       PLS_INTEGER :=0;
ln_internal_cust_exists       PLS_INTEGER :=0;


BEGIN
         
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------
   
   WRITE_LOG(RPAD(' ',1,' ')||RPAD('Office Depot',60)||RPAD(' ',23,' ')||'Date: '||trunc(sysdate));
   WRITE_LOG(RPAD(' ',100,'-'));
   WRITE_LOG(RPAD(' ',1,' ')||LPAD('OD: TM GDW Named Account Assignment Preprocessor Child Program',80));
   WRITE_LOG(RPAD(' ',100,'-'));
   WRITE_LOG('');
   
   WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',60)||RPAD(' ',23,' ')||'Date: '||trunc(sysdate));
   WRITE_OUT(RPAD(' ',100,'-'));
   WRITE_OUT(RPAD(' ',1,' ')||LPAD('OD: TM GDW Named Account Assignment Preprocessor Child Program',80));
   WRITE_OUT(RPAD(' ',100,'-'));
   WRITE_OUT('');
   WRITE_OUT(RPAD(' ',100,'-'));
   
   lp_gen_bulk_rec.trans_object_id         := JTF_TERR_NUMBER_LIST(null);
   lp_gen_bulk_rec.trans_detail_object_id  := JTF_TERR_NUMBER_LIST(null);
   
   -- Extend Qualifier Elements
   lp_gen_bulk_rec.squal_char01.EXTEND;
   lp_gen_bulk_rec.squal_char02.EXTEND;
   lp_gen_bulk_rec.squal_char03.EXTEND;
   lp_gen_bulk_rec.squal_char04.EXTEND;
   lp_gen_bulk_rec.squal_char05.EXTEND;
   lp_gen_bulk_rec.squal_char06.EXTEND;
   lp_gen_bulk_rec.squal_char07.EXTEND;
   lp_gen_bulk_rec.squal_char08.EXTEND;
   lp_gen_bulk_rec.squal_char09.EXTEND;
   lp_gen_bulk_rec.squal_char10.EXTEND;
   lp_gen_bulk_rec.squal_char10.EXTEND;
   lp_gen_bulk_rec.squal_char11.EXTEND;
   lp_gen_bulk_rec.squal_char50.EXTEND;
   lp_gen_bulk_rec.squal_char59.EXTEND;
   lp_gen_bulk_rec.squal_char60.EXTEND;
   lp_gen_bulk_rec.squal_char61.EXTEND;
   lp_gen_bulk_rec.squal_num60.EXTEND;
   lp_gen_bulk_rec.squal_num01.EXTEND;
   lp_gen_bulk_rec.squal_num02.EXTEND;
   lp_gen_bulk_rec.squal_num03.EXTEND;
   lp_gen_bulk_rec.squal_num04.EXTEND;
   lp_gen_bulk_rec.squal_num05.EXTEND;
   lp_gen_bulk_rec.squal_num06.EXTEND;
   lp_gen_bulk_rec.squal_num07.EXTEND;
   
   -- Retrieve the records from XXOD_HZ_IMP_EXT_ATTRIBS_STG
   -- based on the three input parameters to the table type
   
   OPEN lcu_party_sites(
                        p_min_record_id   => p_min_record_id
                        , p_max_record_id => p_max_record_id
                        , p_batch_id      => p_batch_id
                       );
   LOOP
       
       -- Initializing the variables
       ln_min_party_site_id := NULL;
       ln_max_party_site_id := NULL;
       lt_party_sites.DELETE;
       
       FETCH lcu_party_sites BULK COLLECT 
       INTO lt_party_sites LIMIT 200;
              
       
       IF lt_party_sites.COUNT > 0 THEN
          
          -- Get the minimum and maximum party_site_id
          
          ln_min_record_id := lt_party_sites(lt_party_sites.FIRST).record_id;
          ln_max_record_id := lt_party_sites(lt_party_sites.LAST).record_id;
          
          -- Fetch the already existing data between the range of party_site_id in a tbl type
          --write_log('ln_min_record_id =>'||ln_min_record_id);
          --write_log('ln_max_record_id =>'||ln_max_record_id);
          /*
          lt_acct_party_site_id.DELETE;
          OPEN lcu_acct_party_site_valid(
                        p_min_record_id   => ln_min_record_id
                        , p_max_record_id => ln_max_record_id
                        , p_batch_id      => p_batch_id
                                        );
          FETCH lcu_acct_party_site_valid BULK COLLECT INTO lt_acct_party_site_id;
          CLOSE lcu_acct_party_site_valid;
          */
          
          FOR i IN lt_party_sites.FIRST .. lt_party_sites.LAST
          LOOP
              
              -- Initializing the variable
              ln_party_site_id             := NULL;
              lc_return_status             := NULL;
              ln_msg_count                 := NULL;
              lc_msg_data                  := NULL;
              lc_error_message             := NULL;
              l_counter                    := NULL;
              lc_pty_site_success          := NULL;
              lc_acct_party_site_id_exists :='N';
              lc_acct_party_id_exists      :='N';
              lc_party_site_assign_exists := 'N';
              -- To count the number of records read
              ln_total_count := ln_total_count + 1;
              
              ln_party_site_id := lt_party_sites(i).party_site_id;
              
              /*
              IF lt_acct_party_site_id.COUNT > 0  THEN
                 FOR k IN lt_acct_party_site_id.FIRST .. lt_acct_party_site_id.LAST
                 LOOP
                     IF lt_acct_party_site_id(k).party_site_id = ln_party_site_id THEN
                        
                        IF lt_acct_party_site_id(k).customer_type='I' THEN
                             
                           lc_acct_party_id_exists:='Y';
                           WRITE_LOG('Party Site ID : '||ln_party_site_id||' is Internal Customer Party Site' );
                           EXIT;
                        END IF;

                        IF NVL(lt_acct_party_site_id(k).attribute18,'0') <> 'CONTRACT' THEN
                           
                           lc_acct_party_site_id_exists:='Y';
                           
                           IF lt_acct_party_site_id(k).attribute18 IS NOT NULL THEN
                              WRITE_LOG('Party Site ID : '||ln_party_site_id||' is ' ||lt_acct_party_site_id(k).attribute18 ||' Customer');
                           ELSE
                              WRITE_LOG('Party Site ID : '||ln_party_site_id||' Customer type attribute18 is null ');
                           END IF;
                           EXIT;
                        END IF;
                        
                     END IF;
                     
                 END LOOP;
                 
              END IF;
              */              
              
              ln_internal_cust_exists := 0;
              --Chk for Internal customers
              SELECT COUNT(1)
              INTO   ln_internal_cust_exists
              FROM   DUAL
              WHERE  EXISTS
              (
              SELECT 1
              FROM   hz_cust_accounts            HCA
                    ,hz_cust_acct_sites          HCAS
                    ,xxod_hz_imp_ext_attribs_stg XHI        
              WHERE  HCAS.party_site_id       = ln_party_site_id
              AND    HCAS.cust_account_id     = HCA.cust_account_id
              AND    HCA.status               = 'A'
              AND    HCAS.status              = 'A'
              AND    HCA.status               =  HCAS.status
              AND    HCA.customer_type        = 'I'
              AND    HCAS.party_site_id       =  xhi.owner_table_id
              and    XHI.owner_table_name     = 'HZ_PARTY_SITES'
              and    xhi.attribute_group_code = 'SITE_DEMOGRAPHICS'
              and    xhi.interface_status     = '7'
              AND    XHI.batch_id             = p_batch_id 
              AND    XHI.record_id BETWEEN ln_min_record_id AND ln_max_record_id
              );
              
              IF ln_internal_cust_exists > 0 THEN
                lc_acct_party_id_exists:='Y';
                WRITE_LOG('Party Site ID : '||ln_party_site_id||' is Internal Customer Party Site' );              
              END IF;
              
              ln_not_cont_cust_exists := 0;
              
              --Chk for customers other than CONTRACT
              SELECT COUNT(1)
              INTO   ln_not_cont_cust_exists
              FROM   DUAL
              WHERE  EXISTS
              (
              SELECT  1
              FROM   hz_cust_accounts              HCA
                     , hz_cust_acct_sites          HCAS
                     , xxod_hz_imp_ext_attribs_stg XHI        
              WHERE  HCAS.party_site_id       = ln_party_site_id
              AND    HCAS.cust_account_id     = HCA.cust_account_id
              AND    HCA.status               = 'A'
              AND    HCAS.status              = 'A'
              AND    HCA.status               =  HCAS.status
              AND    COALESCE(HCA.attribute18,'X') = 'CONTRACT'
              AND    HCAS.party_site_id       =  xhi.owner_table_id
              and    XHI.owner_table_name     = 'HZ_PARTY_SITES'
              and    xhi.attribute_group_code = 'SITE_DEMOGRAPHICS'
              and    xhi.interface_status     = '7'
              AND    XHI.batch_id             = p_batch_id 
              AND    XHI.record_id BETWEEN ln_min_record_id AND ln_max_record_id
              );
              
              IF ln_not_cont_cust_exists = 0 THEN
                lc_acct_party_site_id_exists:='Y';
                WRITE_LOG('Party Site ID : '||ln_party_site_id||' is not a CONTRACT Customer');
              END IF;              
              
              
              -- Check whether the party_site_id already exists in the entity table
              /*
              lt_terr_rsc_role_grp_id.DELETE;
              OPEN lcu_party_site_assign_exists(
                              p_min_record_id   => ln_min_record_id
                            , p_max_record_id => ln_max_record_id
                            , p_batch_id      => p_batch_id
                                               );
              LOOP                                 
              FETCH lcu_party_site_assign_exists BULK COLLECT 
              INTO lt_terr_rsc_role_grp_id LIMIT 200;
              
              EXIT WHEN lt_terr_rsc_role_grp_id.COUNT = 0;
              
              IF lt_terr_rsc_role_grp_id.COUNT > 0
              AND lc_acct_party_id_exists ='N'
              --AND lc_acct_party_site_id_exists='N'
              THEN
                  FOR a IN lt_terr_rsc_role_grp_id.FIRST .. lt_terr_rsc_role_grp_id.LAST
                  LOOP
                      IF lt_terr_rsc_role_grp_id(a).entity_id = ln_party_site_id THEN
                            
                         lc_party_site_assign_exists := 'Y';
                                       
                      END IF; -- lt_terr_rsc_role_grp_id(i).entity_id = ln_party_site_id
                  
                  END LOOP; -- lt_terr_rsc_role_grp_id.FIRST .. lt_terr_rsc_role_grp_id.LAST
              
              END IF; -- lt_terr_rsc_role_grp_id.COUNT <> 0 AND lc_acct_party_id_exists ='N' AND lc_acct_party_site_id_exists='N' THEN
              
              END LOOP;
              CLOSE lcu_party_site_assign_exists;
              lt_terr_rsc_role_grp_id.DELETE;
              */
              
              SELECT COUNT(1)
              INTO   ln_party_site_assign_exists
              FROM DUAL
              WHERE EXISTS
              (
              SELECT 1
              FROM   xx_tm_nam_terr_defn                TERR
                    ,xx_tm_nam_terr_entity_dtls         TERR_ENT
                    ,xx_tm_nam_terr_rsc_dtls            TERR_RSC
                    ,xxod_hz_imp_ext_attribs_stg        XHI 
              WHERE  TERR.named_acct_terr_id           = TERR_ENT.named_acct_terr_id
              AND    TERR.named_acct_terr_id           = TERR_RSC.named_acct_terr_id
              AND    SYSDATE between TERR.start_date_active AND NVL(TERR.end_date_active,SYSDATE)
              AND    SYSDATE between TERR_ENT.start_date_active AND NVL(TERR_ENT.end_date_active,SYSDATE)
              AND    SYSDATE between TERR_RSC.start_date_active AND NVL(TERR_RSC.end_date_active,SYSDATE)
              AND    NVL(TERR.status,'A')              = 'A'
              AND    NVL(TERR_ENT.status,'A')          = 'A'
              AND    NVL(TERR_RSC.status,'A')          = 'A'
              AND    TERR_ENT.entity_type              = 'PARTY_SITE'
              AND    TERR_ENT.entity_id                =  ln_party_site_id
              AND    TERR_ENT.entity_id                =  xhi.owner_table_id
              and    XHI.owner_table_name              = 'HZ_PARTY_SITES'
              and    xhi.attribute_group_code          = 'SITE_DEMOGRAPHICS'
              and    xhi.interface_status              ='7'
              AND    XHI.BATCH_ID                      = p_batch_id 
              AND    XHI.RECORD_ID BETWEEN ln_min_record_id AND ln_max_record_id
              )
              ;
              
              IF ln_party_site_assign_exists > 0 AND 
                 lc_acct_party_id_exists ='N' THEN
              
                 lc_party_site_assign_exists := 'Y';
              
              END IF;
              
              
              IF lc_acct_party_id_exists ='Y' THEN
                  
                ln_party_internal := ln_party_internal + 1;
                  
              ELSIF lc_acct_party_site_id_exists ='Y' THEN
                    
                   ln_party_site_err := ln_party_site_err + 1;
                   
              ELSIF lc_party_site_assign_exists = 'Y' THEN
                     
                   ln_exists_count := ln_exists_count + 1;
              
              ELSE
                  -- Call to JTF_TERR_ASSIGN_PUB.get_winners with the party_site_id
                  
                  lp_gen_bulk_rec.squal_char01(1) := l_squal_char01;
                  lp_gen_bulk_rec.squal_char02(1) := l_squal_char02 ;
                  lp_gen_bulk_rec.squal_char03(1) := l_squal_char03;
                  lp_gen_bulk_rec.squal_char04(1) := l_squal_char04;
                  lp_gen_bulk_rec.squal_char05(1) := l_squal_char05;
                  lp_gen_bulk_rec.squal_char06(1) := l_squal_char06;  --Postal Code
                  lp_gen_bulk_rec.squal_char07(1) := l_squal_char07;  --Country
                  lp_gen_bulk_rec.squal_char08(1) := l_squal_char08;
                  lp_gen_bulk_rec.squal_char09(1) := l_squal_char09;
                  lp_gen_bulk_rec.squal_char10(1) := l_squal_char10;
                  lp_gen_bulk_rec.squal_char11(1) := l_squal_char11;
                  lp_gen_bulk_rec.squal_char50(1) := l_squal_char50;
                  lp_gen_bulk_rec.squal_char59(1) := l_squal_char59;  --SIC Code(Site Level)
                  lp_gen_bulk_rec.squal_char60(1) := l_squal_char60;  --Customer/Prospect
                  lp_gen_bulk_rec.squal_char61(1) := ln_party_site_id;
                  lp_gen_bulk_rec.squal_num60(1)  := l_squal_num60;   --WCW
                  lp_gen_bulk_rec.squal_num01(1)  := l_squal_num01;   --Party Id
                  lp_gen_bulk_rec.squal_num02(1)  := ln_party_site_id; --Party Site Id
                  lp_gen_bulk_rec.squal_num03(1)  := l_squal_num03;
                  lp_gen_bulk_rec.squal_num04(1)  := l_squal_num04;
                  lp_gen_bulk_rec.squal_num05(1)  := l_squal_num05;
                  lp_gen_bulk_rec.squal_num06(1)  := l_squal_num06;
                  lp_gen_bulk_rec.squal_num07(1)  := l_squal_num07;
                  
                  BEGIN
                       
                       JTF_TERR_ASSIGN_PUB.get_winners(
                                                       p_api_version_number  => ln_api_version
                                                       , p_init_msg_list     => FND_API.G_FALSE
                                                       , p_use_type          => 'LOOKUP'
                                                       , p_source_id         => -1001
                                                       , p_trans_id          => -1002
                                                       , p_trans_rec         => lp_gen_bulk_rec
                                                       , p_resource_type     => FND_API.G_MISS_CHAR
                                                       , p_role              => FND_API.G_MISS_CHAR
                                                       , p_top_level_terr_id => FND_API.G_MISS_NUM
                                                       , p_num_winners       => FND_API.G_MISS_NUM
                                                       , x_return_status     => lc_return_status
                                                       , x_msg_count         => ln_msg_count
                                                       , x_msg_data          => lc_msg_data
                                                       , x_winners_rec       => lx_gen_return_rec
                                                      );
                       IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                       
                          FOR l IN 1 .. ln_msg_count
                          LOOP
                              
                              lc_msg_data := FND_MSG_PUB.GET(
                                                             p_encoded     => FND_API.G_FALSE
                                                             , p_msg_index => l
                                                            );
                              WRITE_LOG('Error for the party site id: '||ln_party_site_id||' '||lc_msg_data);
                          END LOOP;
                          RAISE EX_PARTY_SITE_ERROR;
                       
                       END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
                       
                       IF lx_gen_return_rec.resource_id.COUNT = 0 THEN
                           
                          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0121_NO_RES_RETURNED');
                          lc_error_message := FND_MESSAGE.GET;
                          WRITE_LOG(lc_error_message);
                          RAISE EX_PARTY_SITE_ERROR;
                       
                       END IF; -- lx_gen_return_rec.resource_id.COUNT = 0
                       
                       -- For each resource returned from JTF_TERR_ASSIGN_PUB.get_winners
                       --l_counter := lx_gen_return_rec.resource_id.FIRST;
                       
                       --WHILE (l_counter <= lx_gen_return_rec.terr_id.LAST)
                       for l_counter in lx_gen_return_rec.resource_id.FIRST .. lx_gen_return_rec.terr_id.LAST
                       LOOP
                           --WRITE_LOG('Step 14');
                           BEGIN
                              
                              -- Initialize the variables
                              
                              ln_salesforce_id          := NULL;
                              ln_sales_group_id         := NULL;
                              lc_full_access_flag       := NULL;
                              ln_asignee_role_id        := NULL;
                              lc_error_message          := NULL;
                              lc_set_message            := NULL;
                              lc_role                   := NULL;
                              ln_count                  := 0;
                              ln_admin_count            := 0;
                              lc_manager_flag           := NULL;
                              ln_named_acct_terr_id     := NULL;
                              lc_assignee_admin_flag    := NULL;
                              lc_status                 := NULL;
                              ln_terr_id                := NULL;
                              lc_resource_name          := NULL;
                              lc_terr_name              := NULL;
                              lc_terr_desc              := NULL;
                              ln_party_id               := NULL;
                              lc_party_name             := NULL;
                              lc_resource_role_code     := NULL;
                              lc_resource_group_name    := NULL;
                              lc_resource_od_role_code  := NULL;
                              lc_cust_prospect          := NULL;
                              lc_postal_code            := NULL;
                              lc_country                := NULL;
                              lc_od_site_sic_code       := NULL;
                              ln_od_wcw                 := NULL; 
                              lc_resource_role_div      := NULL;
                              
                              -- Fetch the assignee resource_id, sales_group_id, role and full_access_flag
                              
                              ln_salesforce_id    := lx_gen_return_rec.resource_id(l_counter);
                              ln_sales_group_id   := lx_gen_return_rec.group_id(l_counter);
                              lc_full_access_flag := lx_gen_return_rec.full_access_flag(l_counter);
                              lc_role             := lx_gen_return_rec.role(l_counter);
                              ln_terr_id          := lx_gen_return_rec.terr_id(l_counter);
                              lc_resource_name    := lx_gen_return_rec.resource_name(l_counter);
                              
                              -- Check whether the assignee resource is an admin
                              OPEN  lcu_admin(
                                              p_resource_id => ln_salesforce_id
                                              , p_group_id  => ln_sales_group_id
                                             );
                              FETCH lcu_admin INTO ln_admin_count;
                              CLOSE lcu_admin;
                              
                              IF ln_admin_count = 0 THEN
                                                               
                                 lc_assignee_admin_flag := 'N';
                                                            
                              ELSIF ln_admin_count = 1 THEN
                                                                  
                                    lc_assignee_admin_flag := 'Y';
                                                                   
                              ELSE
                                                                
                                  -- The resource has more than one admin role
                                  FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0243_ADM_MORE_THAN_ONE');
                                  FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                  lc_error_message := FND_MESSAGE.GET;
                                  WRITE_LOG(lc_error_message);
                                  RAISE EX_CREATE_ERR;
                                                            
                              END IF; -- ln_admin_count = 0 
                              
                              IF (ln_sales_group_id IS NULL) THEN
                                 
                                 IF lc_assignee_admin_flag = 'Y' THEN
                                                                                     
                                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0244_ADM_GRP_MANDATORY');
                                    FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                    lc_error_message := FND_MESSAGE.GET;
                                    WRITE_LOG(lc_error_message);
                                    RAISE EX_CREATE_ERR;
                                                                                  
                                 END IF; -- lc_assignee_admin_flag = 'Y'
                              
                              END IF; -- ln_sales_group_id IS NULL
                              
                              -- Deriving the role_id and group_id of the resource if lc_role IS NULL
                              IF (lc_role IS NULL) THEN
                                                                                                                     
                                 IF lc_assignee_admin_flag = 'Y' THEN
                                                                                                 
                                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0245_ADM_ROLE_MANDATORY');
                                    FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                    lc_error_message := FND_MESSAGE.GET;
                                    WRITE_LOG(lc_error_message);
                                    RAISE EX_CREATE_ERR;
                                                                                              
                                 END IF; -- lc_assignee_admin_flag = 'Y'
                                                              
                                 -- Check whether the resource is a manager
                                                                                                            
                                 SELECT count(ROL.manager_flag)
                                 INTO   ln_count
                                 FROM   jtf_rs_role_relations JRR
                                        , jtf_rs_group_members MEM
                                        , jtf_rs_group_usages JRU
                                        , jtf_rs_roles_b ROL
                                 WHERE  MEM.resource_id = ln_salesforce_id
                                 AND    NVL(MEM.delete_flag,'N') <> 'Y'
                                 AND    MEM.group_id = NVL(ln_sales_group_id,MEM.group_id)
                                 AND    JRU.group_id = MEM.group_id
                                 AND    JRU.usage = 'SALES'
                                 AND    JRR.role_resource_id    = MEM.group_member_id
                                 AND    JRR.role_resource_type = 'RS_GROUP_MEMBER'
                                 AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) 
                                                       AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
                                 AND    NVL(JRR.delete_flag,'N') <> 'Y'
                                 AND    ROL.role_id = JRR.role_id
                                 AND    ROL.role_type_code='SALES'
                                 AND    ROL.manager_flag = 'Y'
                                 AND    ROL.active_flag = 'Y';
                                 
                                 IF ln_count = 0 THEN
                                           
                                    -- This means the resource is a sales-rep
                                    lc_manager_flag := 'N';
                                      
                                 ELSIF ln_count = 1 THEN
                                       
                                       -- This means the resource is a manager
                                       lc_manager_flag := 'Y';
                                   
                                 ELSE
                                        
                                     -- The resource has more than one manager role
                                     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0219_MGR_MORE_THAN_ONE');
                                     FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                     lc_error_message := FND_MESSAGE.GET;
                                     WRITE_LOG(lc_error_message);
                                     RAISE EX_CREATE_ERR;
                                  
                                 END IF; -- ln_count = 0
                                            
                                 -- Derive the role_id and group_id of assignee resource
                                 -- with the resource_id and group_id derived
                                 BEGIN
                                             
                                      SELECT JRR_ASG.role_id
                                             , MEM_ASG.group_id
                                      INTO   ln_asignee_role_id
                                             , ln_sales_group_id
                                      FROM   jtf_rs_group_members MEM_ASG
                                             , jtf_rs_role_relations JRR_ASG
                                             , jtf_rs_group_usages JRU_ASG
                                             , jtf_rs_roles_b ROL_ASG
                                      WHERE  MEM_ASG.resource_id      = ln_salesforce_id
                                      AND    NVL(MEM_ASG.delete_flag,'N') <> 'Y'
                                      AND    MEM_ASG.group_id         = NVL(ln_sales_group_id,MEM_ASG.group_id)
                                      AND    JRU_ASG.group_id         = MEM_ASG.group_id
                                      AND    JRU_ASG.usage            = 'SALES'
                                      AND    JRR_ASG.role_resource_id = MEM_ASG.group_member_id
                                      AND    JRR_ASG.role_resource_type  = 'RS_GROUP_MEMBER'
                                      AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_ASG.start_date_active) 
                                                                                         AND NVL(TRUNC(JRR_ASG.end_date_active),TRUNC(SYSDATE))
                                      AND    NVL(JRR_ASG.delete_flag,'N') <> 'Y'
                                      AND    ROL_ASG.role_id         = JRR_ASG.role_id
                                      AND    ROL_ASG.role_type_code  = 'SALES'
                                      AND    ROL_ASG.active_flag     = 'Y'
                                      AND    (CASE lc_manager_flag 
                                                   WHEN 'Y' THEN ROL_ASG.attribute14 
                                                   ELSE 'N' 
                                                           END) = (CASE lc_manager_flag 
                                                                        WHEN 'Y' THEN 'HSE' 
                                                                        ELSE 'N' 
                                                                                END);       
                                                                                                      
                                 EXCEPTION
                                    WHEN NO_DATA_FOUND THEN
                                        IF lc_manager_flag = 'Y' THEN
                                           FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0229_AS_MGR_NO_HSE_ROLE');
                                           FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                           lc_error_message := FND_MESSAGE.GET;
                                           lc_message_code  := 'XX_TM_0229_AS_MGR_NO_HSE_ROLE';
                                        ELSE
                                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0122_AS_NO_SALES_ROLE');
                                            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                            lc_error_message := FND_MESSAGE.GET;
                                            lc_message_code  := 'XX_TM_0122_AS_NO_SALES_ROLE';
                                        END IF;
                                        WRITE_LOG(lc_error_message);
                                        RAISE EX_CREATE_ERR;
                                    WHEN TOO_MANY_ROWS THEN
                                        IF lc_manager_flag = 'Y' THEN
                                           FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0230_AS_MGR_HSE_ROLE');
                                           FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                           lc_error_message := FND_MESSAGE.GET;
                                           lc_message_code  := 'XX_TM_0230_AS_MGR_HSE_ROLE';
                                        ELSE
                                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0123_AS_MANY_SALES_ROLE');
                                            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                            lc_error_message := FND_MESSAGE.GET;
                                            lc_message_code  := 'XX_TM_0123_AS_MANY_SALES_ROLE';
                                        END IF;
                                        WRITE_LOG(lc_error_message);
                                        RAISE EX_CREATE_ERR;
                                    WHEN OTHERS THEN
                                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                        lc_set_message     :=  'Unexpected Error while deriving role_id and role_division of the assignee.';
                                        FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                        FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                        lc_error_message := FND_MESSAGE.GET;
                                        --Write_log('step 1');
                                        WRITE_LOG(lc_error_message);
                                        RAISE EX_CREATE_ERR;
                                 END;
                              
                              ELSE
                                  
                                  -- Derive the role_id and group_id of assignee resource
                                  -- with the resource_id, group_id and role_code returned
                                  -- from get_winners
                                  BEGIN
                                                                     
                                     SELECT JRR_ASG.role_id
                                            , MEM_ASG.group_id
                                     INTO   ln_asignee_role_id
                                            , ln_sales_group_id
                                     FROM   jtf_rs_group_members MEM_ASG
                                            , jtf_rs_role_relations JRR_ASG
                                            , jtf_rs_group_usages JRU_ASG
                                            , jtf_rs_roles_b ROL_ASG
                                     WHERE  MEM_ASG.resource_id = ln_salesforce_id
                                     AND    MEM_ASG.group_id    = NVL(ln_sales_group_id,MEM_ASG.group_id)
                                     AND    NVL(MEM_ASG.delete_flag,'N') <> 'Y'
                                     AND    JRU_ASG.group_id    = MEM_ASG.group_id
                                     AND    JRU_ASG.usage       = 'SALES'
                                     AND    JRR_ASG.role_resource_id = MEM_ASG.group_member_id
                                     AND    JRR_ASG.role_resource_type  = 'RS_GROUP_MEMBER'
                                     AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_ASG.start_date_active) 
                                                           AND NVL(TRUNC(JRR_ASG.end_date_active),TRUNC(SYSDATE))
                                     AND    NVL(JRR_ASG.delete_flag,'N') <> 'Y'                      
                                     AND    ROL_ASG.role_id         = JRR_ASG.role_id
                                     AND    ROL_ASG.role_code       = lc_role
                                     AND    ROL_ASG.role_type_code  = 'SALES'
                                     AND    ROL_ASG.active_flag     = 'Y';
                                                                                                      
                                  EXCEPTION
                                     WHEN NO_DATA_FOUND THEN
                                         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0218_NO_SALES_ROLE');
                                         FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                         FND_MESSAGE.SET_TOKEN('P_ROLE_CODE', lc_role);
                                         FND_MESSAGE.SET_TOKEN('P_GROUP_ID', ln_sales_group_id);
                                         lc_error_message := FND_MESSAGE.GET;
                                         WRITE_LOG(lc_error_message);
                                         RAISE EX_CREATE_ERR;
                                     WHEN OTHERS THEN
                                         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                         lc_set_message     :=  'Unexpected Error while deriving role_id of the assignee with the role_code';
                                         FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                         FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                         FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                         lc_error_message := FND_MESSAGE.GET;
                                         WRITE_LOG(lc_error_message);
                                         RAISE EX_CREATE_ERR;
                                  END;
                              
                              END IF; -- lc_role IS NULL
                              
                              BEGIN
                                                            
                                   SELECT name
                                          , description 
                                   INTO   lc_terr_name      
                                          , lc_terr_desc       
                                   FROM   jtf_terr_all
                                   WHERE  terr_id = ln_terr_id;
                              EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                     lc_terr_name := NULL;
                                     lc_terr_desc := NULL;
                                 WHEN OTHERS THEN   
                                     lc_terr_name := NULL;
                                     lc_terr_desc := NULL;
                              END;
                              
                              BEGIN
                                                                               
                                   SELECT P.party_id
                                          , P.party_name 
                                          , P.Attribute13
                                          , (CASE WHEN HL.country = 'US' THEN 
                                                       SUBSTR(HL.postal_code,1,5)
                                                  WHEN HL.country = 'CA' THEN 
                                                       SUBSTR(HL.postal_code,1,3)
                                            END) postal_code    
                                          , HL.country
                                   INTO   ln_party_id
                                          , lc_party_name 
                                          , lc_cust_prospect
                                          , lc_postal_code
                                          , lc_country
                                   FROM   hz_parties     P
                                          , hz_party_sites PS
                                          , hz_locations   HL
                                   WHERE  PS.party_id      = P.party_id
                                   AND    PS.party_site_id = ln_party_site_id
                                   AND    HL.location_id   = PS.location_id;
                                                      
                              EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                     ln_party_id      := NULL;
                                     lc_party_name    := NULL;
                                     lc_cust_prospect := NULL;
                                     lc_postal_code   := NULL;
                                     lc_country       := NULL;
                                 WHEN OTHERS THEN   
                                     ln_party_id      := NULL;
                                     lc_party_name    := NULL;
                                     lc_cust_prospect := NULL;
                                     lc_postal_code   := NULL;
                                     lc_country       := NULL;
                              END;
                              
                              BEGIN
                                                                                 
                                   SELECT UPPER(SUBSTR(HPSEXT.c_ext_attr10,1,INSTR(HPSEXT.c_ext_attr10,':',1)+4))od_site_sic_code
                                          , NVL(HPSEXT.n_ext_attr8,0)   od_wcw
                                   INTO   lc_od_site_sic_code                                      
                                          , ln_od_wcw 
                                   FROM   hz_party_sites_ext_vl HPSEXT
                                   WHERE EXISTS  ( SELECT 1
                                                   FROM DUAL
                                                   WHERE EXISTS
                                                               (   
                                                                SELECT 1 
                                                                FROM   EGO_ATTR_GROUPS_V      EGOV   
                                                                WHERE  EGOV.attr_group_type = 'HZ_PARTY_SITES_GROUP'
                                                                AND    EGOV.attr_group_name = 'SITE_DEMOGRAPHICS'
                                                                AND    EGOV.attr_group_id   = HPSEXT.attr_group_id
                                                               )
                                                  )
                                   AND HPSEXT.party_site_id = ln_party_site_id;          
                                                                               
                              EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                     lc_od_site_sic_code := NULL;
                                     ln_od_wcw  := NULL;
                                 WHEN OTHERS THEN   
                                     lc_od_site_sic_code := NULL;
                                     ln_od_wcw  := NULL;
                              END;
                              
                              BEGIN
                                                      
                                   SELECT JSRV.role_code
                                          , JSRV.attribute14
                                          , JSRV.attribute15
                                   INTO   lc_resource_role_code
                                          , lc_resource_od_role_code
                                          , lc_resource_role_div
                                   FROM   jtf_rs_roles_vl    JSRV
                                   WHERE  JSRV.role_id = ln_asignee_role_id;
                                                            
                              EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                     lc_resource_role_code    := NULL;
                                     lc_resource_od_role_code := NULL;
                                     lc_resource_role_div     := NULL;
                                 WHEN OTHERS THEN   
                                     lc_resource_role_code    := NULL;
                                     lc_resource_od_role_code := NULL;
                                     lc_resource_role_div     := NULL;
                              END;
                              
                              BEGIN
                                                                               
                                   SELECT JRG.group_name
                                   INTO   lc_resource_group_name
                                   FROM   JTF_RS_GROUPS_VL JRG
                                   WHERE  JRG.group_id    = ln_sales_group_id;
                                                                                 
                              EXCEPTION
                                   WHEN NO_DATA_FOUND THEN
                                       lc_resource_group_name := NULL;
                                   WHEN OTHERS THEN   
                                       lc_resource_group_name := NULL;
                              END;
                              
                              ln_insert_count := NVL(ln_insert_count,0) + 1;
                              
                              gt_idx_ins_preproc(ln_insert_count) := NULL;
                              
                              SELECT xx_tm_nmdactasgn_preproc_s.NEXTVAL
                              INTO   ln_preprocessor_record_id
                              FROM   DUAL;
                              
                              xt_insert_preprocessor(ln_insert_count).preprocessor_record_id     := ln_preprocessor_record_id  ;
                              
                              xt_insert_preprocessor(ln_insert_count).rule_based_terr_id         := ln_terr_id   ;
                              xt_insert_preprocessor(ln_insert_count).rule_based_terr_name       := lc_terr_name ;
                              xt_insert_preprocessor(ln_insert_count).rule_based_terr_desc       := lc_terr_desc ;
                              xt_insert_preprocessor(ln_insert_count).resource_id                := ln_salesforce_id ;
                              xt_insert_preprocessor(ln_insert_count).resource_name              := lc_resource_name ;
                              xt_insert_preprocessor(ln_insert_count).resource_role_id           := ln_asignee_role_id ;                              
                              xt_insert_preprocessor(ln_insert_count).resource_role_name         := lc_role  ;
                              xt_insert_preprocessor(ln_insert_count).resource_role_div          := lc_resource_role_div ;
                              xt_insert_preprocessor(ln_insert_count).resource_group_id          := ln_sales_group_id  ;
                              xt_insert_preprocessor(ln_insert_count).resource_group_name        := lc_resource_group_name  ;
                              xt_insert_preprocessor(ln_insert_count).party_site_id              := ln_party_site_id  ;
                              xt_insert_preprocessor(ln_insert_count).party_id                   := ln_party_id  ;
                              xt_insert_preprocessor(ln_insert_count).party_name                 := lc_party_name ;
                              xt_insert_preprocessor(ln_insert_count).resource_od_role_code      := lc_resource_od_role_code  ;
                              xt_insert_preprocessor(ln_insert_count).prospect_customer          := lc_cust_prospect          ;
                              xt_insert_preprocessor(ln_insert_count).postal_code                := lc_postal_code            ;
                              xt_insert_preprocessor(ln_insert_count).country                    := lc_country                ;
                              xt_insert_preprocessor(ln_insert_count).od_site_sic_code           := lc_od_site_sic_code       ;
                              xt_insert_preprocessor(ln_insert_count).od_wcw                     := ln_od_wcw                 ;
                              xt_insert_preprocessor(ln_insert_count).CREATED_BY                 := FND_GLOBAL.USER_ID         ;
                              xt_insert_preprocessor(ln_insert_count).CREATION_DATE              := SYSDATE                    ;
                              
                              --l_counter    := l_counter + 1;
                         
                         EXCEPTION
                            WHEN EX_CREATE_ERR THEN
                                NULL;
                                lc_error_message := 'No Data Found; Party Site Id: '||ln_party_site_id;
                                WRITE_LOG(lc_error_message);
                            WHEN OTHERS THEN
                               FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                               lc_set_message     :=  'Unexpected Error while inserting a party site id : '||ln_party_site_id;
                               FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                               FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                               lc_error_message := FND_MESSAGE.GET;
                               WRITE_LOG(lc_error_message);
                               lc_pty_site_success := 'N';
                         END;
                         
   
                       END LOOP; -- l_counter <= lx_gen_return_rec.terr_id.LAST
                       
                  EXCEPTION
                     WHEN EX_PARTY_SITE_ERROR THEN
                         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0130_BULK_PARTY_SITE_ERR');
                         FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', ln_party_site_id);
                         lc_error_message := FND_MESSAGE.GET;
                         lc_pty_site_success := 'N';
                         WRITE_LOG(lc_error_message);
                         ROLLBACK;
                     WHEN OTHERS THEN
                         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                         lc_set_message     :=  'Unexpected Error while creating list of elligible party sites details.';
                         FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                         FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                         FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                         lc_error_message := FND_MESSAGE.GET;
                         WRITE_LOG(lc_error_message);
                         lc_pty_site_success := 'N';
                         ROLLBACK;
                  END;
              
              END IF; -- lc_acct_party_id_exists ='Y'
              
              IF (lc_pty_site_success = 'S') THEN
                                 
                 ln_success_count := ln_success_count + 1;
                 COMMIT;
                           
              ELSIF (lc_pty_site_success = 'N') THEN
                                       
                    ln_error_count := ln_error_count + 1;
                                 
              END IF; -- lc_pty_site_success = 'S'
  
          END LOOP; -- lt_party_sites.FIRST .. lt_party_sites.LAST
          
       END IF; -- lt_party_sites.COUNT <> 0
       EXIT WHEN lcu_party_sites%NOTFOUND;
   END LOOP; -- lcu_party_sites
   
   CLOSE lcu_party_sites;
   lt_party_sites.DELETE;   
   lt_party_sites := lt_party_sites_initialize;

   BEGIN 
         lc_total_rec_inserted := 0;
         
         INSERT_ROW                                              
           (                                                     
              pt_insert_preproc       => xt_insert_preprocessor
            , x_return_status         => lc_return_status 
            , x_msg_count             => ln_msg_count 
            , x_message_data          => lc_msg_data 
            , x_record_inserted       => lc_total_rec_inserted
           );
         
         xt_insert_preprocessor := xt_insert_index_rec_init;            
         DBMS_SESSION.free_unused_user_memory;
            
            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               
               FOR b IN 1 .. ln_msg_count
               LOOP                   
                   lc_msg_data := FND_MSG_PUB.GET(
                                                  p_encoded     => FND_API.G_FALSE
                                                  , p_msg_index => b
                                                 );
                   WRITE_LOG(lc_msg_data);
                
               END LOOP;
            ELSE
            
                COMMIT;
            
            END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
         
         EXCEPTION
            WHEN OTHERS THEN
                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                lc_set_message     :=  'Unexpected Error while creating a party site id';
                FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                lc_error_message := FND_MESSAGE.GET;
                --Write_log('step 3');
                WRITE_LOG(lc_error_message);
                lc_pty_site_success := 'N';
          
   END;
   
   
   lc_error_message := NULL;
   
   -- ----------------------------------------------------------------------------
   -- Write to output file, the total number of records processed, number of
   -- success and failure records.
   -- ----------------------------------------------------------------------------
   
   WRITE_OUT(' ');
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0131_TOTAL_RECORD_READ');
   FND_MESSAGE.SET_TOKEN('P_RECORD_FETCHED', ln_total_count);
   lc_total_count    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_count);
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0133_TOTAL_RECORD_ERR');
   FND_MESSAGE.SET_TOKEN('P_RECORD_ERROR', ln_error_count);
   lc_total_failed    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_failed);
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0132_TOTAL_RECORD_SUCC');
   FND_MESSAGE.SET_TOKEN('P_RECORD_SUCCESS', lc_total_rec_inserted);
   lc_total_success    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_success);
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0146_TOTAL_RECORDS_EXIST');
   FND_MESSAGE.SET_TOKEN('P_RECORD_EXIST', ln_exists_count);
   lc_total_exists  := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_exists);
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0238_INTERNAL_PARTYSITE');
   FND_MESSAGE.SET_TOKEN('P_RECORDS_INTERNAL', ln_party_internal);
   lc_total_success    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_success);
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0239_NONCONTRACT_PS');
   FND_MESSAGE.SET_TOKEN('P_RECORDS_NONCPS', ln_party_site_err);
   lc_total_exists  := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_exists);
   
   IF ln_error_count <> 0 THEN
   
      -- End the program with warning
      x_retcode := 1;
   
   END IF;


EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating a party site id';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       x_errbuf         := lc_error_message;
       x_retcode        := 2 ;
       WRITE_LOG(x_errbuf);
END child_main;
END XX_TM_NMDACCT_GDW_PREPROC;
/
SHOW ERRORS;
