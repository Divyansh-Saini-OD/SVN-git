SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK


CREATE OR REPLACE PACKAGE BODY XX_TM_NAMED_ACCT_PREPROCESSOR
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_TM_NAMED_ACCT_PREPROCESSOR                                 |
-- |                                                                                   |
-- | Description      :  This custom package will display the future assignments of the|
-- |                     unassigned Party Site.                                        |
-- |                     This program will be multithreaded.                           |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  11-Jun-2008 Nabarun Ghosh                Initial draft version           |
-- +===================================================================================+
AS


  --Declaring Global Variables
  ----------------------------
  gn_index    PLS_INTEGER := 0;
  
  --Declaring Global Record Variables
  -----------------------------------
  TYPE rsc_role_grp_terr_id_rec_type IS RECORD
      (
          rsc_role_group_id    VARCHAR2(2000)
        , named_acct_terr_id NUMBER
      );

  --Declaring Global Table Type Variables
  ---------------------------------------
  TYPE rsc_role_grp_terr_id_tbl_type IS TABLE OF rsc_role_grp_terr_id_rec_type INDEX BY BINARY_INTEGER;
  gt_rsc_role_grp_terr_id rsc_role_grp_terr_id_tbl_type;
  
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
       FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
       
  END write_out;

  FUNCTION Pipelined_Party_Sites (
                                   lcu_party_sites_in IN SYS_REFCURSOR
                                 ) RETURN xx_tm_named_acct_preprocessor.lt_pipelined_sites
                                   PIPELINED
                                   PARALLEL_ENABLE (PARTITION lcu_party_sites_in BY ANY) 
  IS
      ln_limit                     PLS_INTEGER := 75;
     
  BEGIN
     
     LOOP
     
        FETCH lcu_party_sites_in BULK COLLECT 
        INTO xx_tm_named_acct_preprocessor.l_tab_pipelined_incoming 
        LIMIT ln_limit;
     
        FOR i IN 1 .. l_tab_pipelined_incoming.COUNT 
        LOOP
        
          xx_tm_named_acct_preprocessor.l_tab_pipelined_outgoing.party_site_id   :=  xx_tm_named_acct_preprocessor.l_tab_pipelined_incoming(i).party_site_id             ;
     
          PIPE ROW (xx_tm_named_acct_preprocessor.l_tab_pipelined_outgoing);
     
        END LOOP;
     
           EXIT WHEN lcu_party_sites_in%NOTFOUND;
     
     END LOOP;
     CLOSE lcu_party_sites_in;
     
     RETURN;
  
  END Pipelined_Party_Sites;

  FUNCTION Pipelined_Site_Loc_Dtls (
                                     lcu_party_siteloc_in IN SYS_REFCURSOR
                                   ) RETURN xx_tm_named_acct_preprocessor.lt_pipelin_siteloc
                                     PIPELINED
                                     PARALLEL_ENABLE (PARTITION lcu_party_siteloc_in BY ANY)  
  IS
      ln_limit                     PLS_INTEGER := 75;
     
  BEGIN
     
     LOOP
     
        FETCH lcu_party_siteloc_in BULK COLLECT 
        INTO xx_tm_named_acct_preprocessor.l_tab_pipelin_in_siteloc 
        LIMIT ln_limit;
     
        FOR i IN 1 .. l_tab_pipelin_in_siteloc.COUNT 
        LOOP
        
          xx_tm_named_acct_preprocessor.l_tab_pipelin_out_siteloc.party_site_id   :=  xx_tm_named_acct_preprocessor.l_tab_pipelin_in_siteloc(i).party_site_id;
          xx_tm_named_acct_preprocessor.l_tab_pipelin_out_siteloc.attribute13     :=  xx_tm_named_acct_preprocessor.l_tab_pipelin_in_siteloc(i).attribute13  ;
          xx_tm_named_acct_preprocessor.l_tab_pipelin_out_siteloc.country         :=  xx_tm_named_acct_preprocessor.l_tab_pipelin_in_siteloc(i).country      ;
          
     
          PIPE ROW (xx_tm_named_acct_preprocessor.l_tab_pipelin_out_siteloc);
     
        END LOOP;
     
           EXIT WHEN lcu_party_siteloc_in%NOTFOUND;
     
     END LOOP;
     CLOSE lcu_party_siteloc_in;
  
     RETURN;
  
  END Pipelined_Site_Loc_Dtls;

  FUNCTION Pipelined_Site_Cust_Type_Dtls (
                                           lcu_party_sitecustype_in IN SYS_REFCURSOR
                                         ) RETURN xx_tm_named_acct_preprocessor.lt_pipelin_sitecustype
                                           PIPELINED
                                           PARALLEL_ENABLE (PARTITION lcu_party_sitecustype_in BY ANY)  

  IS
      ln_limit       PLS_INTEGER := 75;
     
  BEGIN
     
     LOOP
     
        FETCH lcu_party_sitecustype_in BULK COLLECT 
        INTO xx_tm_named_acct_preprocessor.l_tab_pipelin_in_sitecustype 
        LIMIT ln_limit;
     
        FOR i IN 1 .. l_tab_pipelin_in_sitecustype.COUNT 
        LOOP
        
          xx_tm_named_acct_preprocessor.l_tab_pipelin_out_sitecustype.attribute18     :=  xx_tm_named_acct_preprocessor.l_tab_pipelin_in_sitecustype(i).attribute18  ;
          xx_tm_named_acct_preprocessor.l_tab_pipelin_out_sitecustype.party_site_id   :=  xx_tm_named_acct_preprocessor.l_tab_pipelin_in_sitecustype(i).party_site_id;
          xx_tm_named_acct_preprocessor.l_tab_pipelin_out_sitecustype.customer_type   :=  xx_tm_named_acct_preprocessor.l_tab_pipelin_in_sitecustype(i).customer_type;
          
     
          PIPE ROW (xx_tm_named_acct_preprocessor.l_tab_pipelin_out_sitecustype);
     
        END LOOP;
     
           EXIT WHEN lcu_party_sitecustype_in%NOTFOUND;
     
     END LOOP;
     CLOSE lcu_party_sitecustype_in;
  
     RETURN;
  
  END Pipelined_Site_Cust_Type_Dtls;
  
  
-- +===================================================================+
-- | Name  : master_main                                               |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: Party  |
-- |                    Site Named Account Mass Assignment' with       |
-- |                    Party Site ID From and Party Site ID To as the |
-- |                    Input parameters to launch a number of         |
-- |                    child processes for parallel execution         |
-- |                    depending upon the batch size                  |
-- |                                                                   |
-- +===================================================================+

PROCEDURE master_main
            (
               x_errbuf             OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_from_party_site_id IN  NUMBER
             , p_to_party_site_id   IN  NUMBER
             , p_gdw_validate_YN    IN  VARCHAR2             
            )
IS
  
  --Declaring local variables
  ---------------------------
  EX_PARAM_ERROR                  EXCEPTION;
  EX_SUBMIT_CHILD                 EXCEPTION;
  ln_batch_size                   PLS_INTEGER;
  ln_succ_party_site_id           PLS_INTEGER;
  ln_min_party_site_id            PLS_INTEGER;
  ln_max_party_site_id            PLS_INTEGER;
  ln_batch_size_count             PLS_INTEGER := 0;
  ln_record_count                 PLS_INTEGER := 0;
  ln_batch_count                  PLS_INTEGER := 0;
  ln_min_index                    PLS_INTEGER;
  ln_max_index                    PLS_INTEGER;
  ln_request_id                   PLS_INTEGER;
  ln_dpl_resource_id              PLS_INTEGER;
  ln_dpl_resource_role_id         PLS_INTEGER;
  ln_dpl_group_id                 PLS_INTEGER;
  ln_max_named_acct_terr_id       PLS_INTEGER;
  ln_min_named_acct_terr_id       PLS_INTEGER;
  ln_entity_id                    PLS_INTEGER;
  ln_count_named_acct_terr_id     PLS_INTEGER := 0;
  lc_error_message                VARCHAR2(4000);
  lc_set_message                  VARCHAR2(2000);
  lc_message                      VARCHAR2(2000);
  lc_phase                        VARCHAR2(03);
  ln_psit_crtn_scs_id             PLS_INTEGER;
  ln_profile_min_pty_site_id      PLS_INTEGER;
  ln_profile_max_pty_site_id      PLS_INTEGER;
  lc_update_profile_flag          VARCHAR2(03) := 'N';
  
  --Declaring Table Type Variables
  --------------------------------
  TYPE party_sites_tbl_type IS TABLE OF hz_party_sites.party_site_id%TYPE INDEX BY PLS_INTEGER;
  lt_party_sites            party_sites_tbl_type;
  lt_party_sites_initialize party_sites_tbl_type;
  
  
  -- Declare cursor to fetch the records from hz_party_sites when both the parameters
  -- are passed as NULL
  -- ---------------------------------------------------------------------------------
  CURSOR lcu_param_null_party_sites(p_succ_party_site_id IN PLS_INTEGER)
  IS
  SELECT  pe.party_site_id             
    FROM  TABLE(
                  xx_tm_named_acct_preprocessor.Pipelined_Party_Sites
                    (                                                  
                      CURSOR (                                                 
                               SELECT   /*+ first_rows(10) */
                      		         HPS.party_site_id                      
                              	  FROM   hz_party_sites HPS                       
                      		         , hz_parties HP                      
                      		  WHERE  HP.party_id = HPS.party_id         
                      		  AND    HP.party_type = 'ORGANIZATION'           
                      		  AND    HPS.status = 'A'                                                 
                      		AND    HP.status = 'A'                                                
                      		AND    HPS.party_site_id > p_succ_party_site_id
                      		ORDER BY 1                 
                              )                                                 
                    )                                                 
                ) PE;
  
  -- Declare cursor to fetch the records from hz_party_sites when both the parameters
  -- are passed
  -- ---------------------------------------------------------------------------------
  CURSOR lcu_param_party_sites(
                                p_from_party_site_id IN PLS_INTEGER
                               ,p_to_party_site_id   IN PLS_INTEGER
                              )
  IS
  SELECT pe.party_site_id             
  FROM   TABLE(
               xx_tm_named_acct_preprocessor.Pipelined_Party_Sites
                    (                                                  
                      CURSOR (                                                 
                               SELECT  /*+ first_rows(10) */
                      		       HPS.party_site_id 
                              	FROM   hz_party_sites HPS   
                      		     , hz_parties HP
                      		WHERE  HP.party_id = HPS.party_id
                      		AND    HP.party_type = 'ORGANIZATION'   
                      		AND    HPS.status = 'A'                           
                      		AND    HP.status = 'A'                       
                      		AND    HPS.party_site_id BETWEEN p_from_party_site_id AND p_to_party_site_id
                      		ORDER BY 1
                              )                                                 
                   )                                                 
              ) PE;  
  
BEGIN
  
     -- --------------------------------------
     -- DISPLAY PROJECT NAME AND PROGRAM NAME
     -- --------------------------------------
     DBMS_SESSION.free_unused_user_memory;
     WRITE_LOG(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
     WRITE_LOG(RPAD(' ',80,'-'));
     WRITE_LOG(LPAD('OD: Named Account Mass Assignment Preprocessor',52));
     WRITE_LOG(RPAD(' ',80,'-'));
     WRITE_LOG('');
     WRITE_LOG('Input Parameters ');
     WRITE_LOG('Party Site ID From : '||p_from_party_site_id);
     WRITE_LOG('Party Site ID To   : '||p_to_party_site_id);
     WRITE_LOG(RPAD(' ',80,'-'));
  
     WRITE_OUT(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
     WRITE_OUT(RPAD(' ',80,'-'));
     WRITE_OUT(LPAD('OD: Named Account Mass Assignment Preprocessor',52));
     WRITE_OUT(RPAD(' ',80,'-'));
   WRITE_OUT('');
     WRITE_OUT(RPAD(' ',80,'-'));
  
     -- Derive the batch Size from the profile
  
     ln_batch_size := NVL(FND_PROFILE.VALUE('XX_TM_PARTY_SITE_BATCH_SIZE'),G_BATCH_SIZE);
     
   -- To check whether both the parameters or none are entered

   IF (p_from_party_site_id IS NULL AND p_to_party_site_id IS NULL) THEN

     -- Fetch the last successfully processed party_site_id from the profile value
     
     --lc_update_profile_flag := 'Y'; 
     BEGIN

          SELECT FPOV.profile_option_value
          INTO   ln_succ_party_site_id
          FROM   fnd_profile_option_values FPOV
                 , fnd_profile_options FPO
          WHERE  FPO.profile_option_id = FPOV.profile_option_id
          AND    FPO.application_id = FPOV.application_id
          AND    FPOV.level_id = G_LEVEL_ID
          AND    FPOV.level_value = G_LEVEL_VALUE
          AND    FPOV.profile_option_value IS NOT NULL
          AND    FPO.profile_option_name = 'XX_TM_AUTO_MAX_PARTY_SITE_ID';

     EXCEPTION
        WHEN OTHERS THEN
            ln_succ_party_site_id := 0;
     END;
     
     -- Fetch all the party_site_ids greater than the value derived from the profile
     -- to launch each batch based on the batch size

     OPEN lcu_param_null_party_sites(ln_succ_party_site_id);
     LOOP

         -- Initializing the variables
         ln_min_index         := NULL;
         ln_max_index         := NULL;
         ln_min_party_site_id := NULL;
         ln_max_party_site_id := NULL;
         ln_batch_size_count  := NULL;
         
         lt_party_sites.DELETE;

         FETCH lcu_param_null_party_sites BULK COLLECT 
         INTO lt_party_sites LIMIT ln_batch_size;
                  
         IF lt_party_sites.COUNT > 0 THEN

            -- Get the minimum and maximum index of the table type

            ln_min_index := lt_party_sites.FIRST;
            ln_max_index := lt_party_sites.LAST;

            -- Get the minimum and maximum party_site_id

            ln_min_party_site_id := lt_party_sites(ln_min_index);
            ln_max_party_site_id := lt_party_sites(ln_max_index);

            -- Get the count of the total number of records for the batch to be launched
            ln_batch_size_count := lt_party_sites.COUNT;

            -- Get the count of the total number of records
            ln_record_count := ln_record_count + ln_batch_size_count;

            -- ---------------------------------------------------------
            -- Call the custom concurrent program for parallel execution
            -- ---------------------------------------------------------
            ln_request_id := FND_REQUEST.submit_request(
                                                         application  => G_CHLD_PROG_APPLICATION
                                                        ,program     => G_CHLD_PROG_EXECUTABLE
                                                        ,sub_request => FALSE
                                                        ,argument1   => ln_min_party_site_id
                                                        ,argument2   => ln_max_party_site_id
                                                        ,argument3   => 'Y'
                                                        ,argument4   => p_gdw_validate_YN
                                                       );

            IF ln_request_id = 0 THEN

               RAISE EX_SUBMIT_CHILD;

            ELSE

                COMMIT;
                gn_index_req_id                                           := gn_index_req_id + 1;
                gt_req_id_pty_site_id(gn_index_req_id).request_id         := ln_request_id;
                gt_req_id_pty_site_id(gn_index_req_id).from_party_site_id := ln_min_party_site_id;
                gt_req_id_pty_site_id(gn_index_req_id).to_party_site_id   := ln_max_party_site_id;
                gt_req_id_pty_site_id(gn_index_req_id).record_count       := ln_batch_size_count;
                ln_batch_count                                            := ln_batch_count + 1;

                -- To fetch the minimum and maximum party_site_id to update the profile
                -- if both the parameters are entered as NULL

                IF (ln_batch_count = 1) THEN

                   ln_profile_min_pty_site_id  := ln_min_party_site_id;
                   ln_profile_max_pty_site_id  := ln_max_party_site_id;

                ELSE

                    IF (ln_profile_max_pty_site_id < ln_max_party_site_id) THEN

                       ln_profile_max_pty_site_id := ln_max_party_site_id;

                    END IF; -- ln_profile_max_pty_site_id < ln_max_party_site_id

                END IF; -- (ln_batch_count = 1)

            END IF; -- ln_request_id = 0

         END IF; -- lt_party_sites.COUNT <> 0

         EXIT WHEN lcu_param_null_party_sites%NOTFOUND;

     END LOOP; -- lcu_param_null_party_sites
     
     CLOSE lcu_param_null_party_sites;
     lt_party_sites.DELETE;     
     
   ELSIF (p_from_party_site_id IS NOT NULL AND p_to_party_site_id IS NOT NULL) THEN

        -- Fetch all the party_site_ids within the range of the parameters
        -- passed as p_from_party_site_id and p_to_party_site_id

        OPEN lcu_param_party_sites(
                                   p_from_party_site_id => p_from_party_site_id
                                  , p_to_party_site_id => p_to_party_site_id
                                  );
        LOOP

           -- Initializing the variables
           ln_min_index         := NULL;
           ln_max_index         := NULL;
           ln_min_party_site_id := NULL;
           ln_max_party_site_id := NULL;
           ln_batch_size_count  := NULL;
           
           lt_party_sites.DELETE;

           FETCH lcu_param_party_sites BULK COLLECT 
           INTO lt_party_sites LIMIT ln_batch_size;
           
           IF lt_party_sites.COUNT > 0 THEN

              -- Get the minimum and maximum index of the table type

              ln_min_index := lt_party_sites.FIRST;
              ln_max_index := lt_party_sites.LAST;

              -- Get the minimum and maximum party_site_id

              ln_min_party_site_id := lt_party_sites(ln_min_index);
              ln_max_party_site_id := lt_party_sites(ln_max_index);

              -- Get the count of the total number of records for the batch to be launched
              ln_batch_size_count := lt_party_sites.COUNT;

              -- Get the count of the total number of records
              ln_record_count := ln_record_count + ln_batch_size_count;


              -- ---------------------------------------------------------
              -- Call the custom concurrent program for parallel execution
              -- ---------------------------------------------------------
              ln_request_id := FND_REQUEST.submit_request(
                                                           application  => G_CHLD_PROG_APPLICATION
                                                           ,program     => G_CHLD_PROG_EXECUTABLE
                                                           ,sub_request => FALSE
                                                           ,argument1   => ln_min_party_site_id
                                                           ,argument2   => ln_max_party_site_id
                                                           ,argument3   => 'N'
                                                           ,argument4   => p_gdw_validate_YN
                                                         );

              IF ln_request_id = 0 THEN

                 RAISE EX_SUBMIT_CHILD;

              ELSE

                  COMMIT;
                  ln_batch_count  := ln_batch_count + 1;
                  gn_index_req_id    := gn_index_req_id + 1;
                  gt_req_id_pty_site_id(gn_index_req_id).request_id         := ln_request_id;
                  gt_req_id_pty_site_id(gn_index_req_id).from_party_site_id := ln_min_party_site_id;
                  gt_req_id_pty_site_id(gn_index_req_id).to_party_site_id   := ln_max_party_site_id;
                  gt_req_id_pty_site_id(gn_index_req_id).record_count       := ln_batch_size_count;

              END IF; -- ln_request_id = 0

           END IF; -- lt_party_sites.COUNT <> 0

           EXIT WHEN lcu_param_party_sites%NOTFOUND;

        END LOOP; -- lcu_param_null_party_sites

        CLOSE lcu_param_party_sites;
        
   ELSE

       RAISE EX_PARAM_ERROR;

   END IF;
   
   -- Delete the table type
   lt_party_sites.DELETE;
   
   lt_party_sites := lt_party_sites_initialize;
   
   --DBMS_SESSION.free_unused_user_memory;

   IF ln_record_count = 0 THEN

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0129_NO_RECORDS');
      FND_MESSAGE.SET_TOKEN('P_FROM_PARTY_SITE_ID', p_from_party_site_id );
      FND_MESSAGE.SET_TOKEN('P_TO_PARTY_SITE_ID', p_to_party_site_id );
      lc_error_message := FND_MESSAGE.GET;
      WRITE_LOG(lc_error_message);
   END IF; -- ln_total_count = 0


   -- ----------------------------------------------------------------------------
   -- Write to output file batch size, the total number of batches launched,
   -- number of records fetched
   -- ----------------------------------------------------------------------------
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0234_BATCH_SIZE');
   FND_MESSAGE.SET_TOKEN('P_BATCH_SIZE', ln_batch_size);
   lc_message    := FND_MESSAGE.GET;
   WRITE_OUT(lc_message);

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0235_BATCHES_LAUNCHED');
   FND_MESSAGE.SET_TOKEN('P_BATCH_LAUNCHED', ln_batch_count);
   lc_message    := FND_MESSAGE.GET;
   WRITE_OUT(lc_message);

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0236_TOTAL_RECORDS');
   FND_MESSAGE.SET_TOKEN('P_RECORDS_READ', ln_record_count);
   lc_message    := FND_MESSAGE.GET;
   WRITE_OUT(lc_message);

   WRITE_OUT(RPAD('-',78,'-'));
   WRITE_OUT(RPAD('-',78,'-'));
   WRITE_OUT(
             RPAD('Request_Id',15,' ')||RPAD(' ',3,' ')||
             RPAD('From_Party_Site_Id',18,' ')||RPAD(' ',3,' ')||
             RPAD('To_Party_Site_Id',18,' ')||RPAD(' ',3,' ')||
             RPAD('Record Count',15,' ')||RPAD(' ',3,' ')
            );
   WRITE_OUT(
             RPAD('-',15,'-')||RPAD(' ',3,' ')||
             RPAD('-',18,'-')||RPAD(' ',3,' ')||
             RPAD('-',18,'-')||RPAD(' ',3,' ')||
             RPAD('-',18,'-')||RPAD(' ',3,' ')
            );
   IF gt_req_id_pty_site_id.COUNT <> 0 THEN

     FOR i IN gt_req_id_pty_site_id.FIRST .. gt_req_id_pty_site_id.LAST
     LOOP

         WRITE_OUT(
                   RPAD(gt_req_id_pty_site_id(i).request_id,15,' ')||RPAD(' ',3,' ')||
                   RPAD(gt_req_id_pty_site_id(i).from_party_site_id,18,' ')||RPAD(' ',3,' ')||
                   RPAD(gt_req_id_pty_site_id(i).to_party_site_id,18,' ')||RPAD(' ',3,' ')||
                   RPAD(gt_req_id_pty_site_id(i).record_count,15,' ')||RPAD(' ',3,' ')
                  );

     END LOOP;

   END IF;

   -- --------------------------------------------------
   -- To check whether the child requests have finished
   -- If not then wait
   -- --------------------------------------------------
   FOR i IN gt_req_id_pty_site_id.FIRST .. gt_req_id_pty_site_id.LAST
   LOOP

       LOOP

           SELECT FCR.phase_code
           INTO   lc_phase
           FROM   fnd_concurrent_requests FCR
           WHERE  FCR.request_id = gt_req_id_pty_site_id(i).request_id;

           IF lc_phase = 'C' THEN
              EXIT;
           ELSE
               DBMS_LOCK.SLEEP(G_SLEEP);
           END IF;
       END LOOP;
   END LOOP;
   
   -- To update the profile
EXCEPTION
   WHEN EX_SUBMIT_CHILD THEN
       IF lcu_param_null_party_sites%ISOPEN THEN
          CLOSE lcu_param_null_party_sites;
       ELSIF lcu_param_party_sites%ISOPEN THEN
             CLOSE lcu_param_party_sites;
       END IF;
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0237_SUBMIT_CHILD_ERR');
       lc_error_message := FND_MESSAGE.GET;
       x_retcode   := 2;
       x_errbuf    := lc_error_message;
       WRITE_LOG(lc_error_message);

   WHEN EX_PARAM_ERROR THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0145_INPUT_PARAMETER_ERR');
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
               x_return_status          OUT NOCOPY VARCHAR2						    
             , x_msg_count              OUT NOCOPY NUMBER						    
             , x_message_data           OUT NOCOPY VARCHAR2
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

BEGIN

         FORALL i IN INDICES OF gt_insert_index_rec
         INSERT INTO xx_tm_nmdactasgn_preprocessor VALUES gt_insert_preprocessor(i);
                  
         lc_record_inserted := SQL%ROWCOUNT;                        

         x_record_inserted := lc_record_inserted;
         
         gt_insert_preprocessor.DELETE;
         gt_insert_preprocessor := gt_insert_index_rec_init;
         
EXCEPTION

   WHEN OTHERS THEN
       x_return_status  :=  FND_API.G_RET_STS_ERROR;
       x_record_inserted := 0;
       FND_MESSAGE.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message  :=  'In Procedure: INSERT_ROW: Unexpected Error : ';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       x_message_data   := lc_error_message;
       
       WRITE_LOG(lc_error_message);
       FND_MSG_PUB.add;

END insert_row;



-- +===================================================================+
-- | Name  : child_main                                                |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: Party  |
-- |                    Site Named Account Mass Assignment Child       |
-- |                    Program' with Party Site ID From and Party Site|
-- |                    ID To as the Input parameters to  create a     |
-- |                    party site record in the custom assignments    |
-- |                    table                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE child_main
            (
               x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_from_party_site_id IN  NUMBER
             , p_to_party_site_id   IN  NUMBER
             , p_upd_profile_value  IN  VARCHAR2
             , p_gdw_validate_YN    IN  VARCHAR2             
            )
IS
---------------------------
--Declaring local variables
---------------------------
EX_CREATE_ERR                EXCEPTION;
EX_PARTY_SITE_ERROR          EXCEPTION;
lc_error_message             VARCHAR2(4000);
ln_api_version               PLS_INTEGER := 1.0;
lc_return_status             VARCHAR2(03);
ln_msg_count                 PLS_INTEGER;
lc_msg_data                  VARCHAR2(2000);
l_counter                    PLS_INTEGER;
ln_salesforce_id             PLS_INTEGER;
ln_sales_group_id            PLS_INTEGER;
ln_asignee_role_id           PLS_INTEGER;
lc_set_message               VARCHAR2(2000);
lc_status                    VARCHAR2(03);
ln_total_count               PLS_INTEGER := 0;
ln_error_count               PLS_INTEGER := 0;
ln_success_count             PLS_INTEGER := 0;
ln_exists_count              PLS_INTEGER := 0;
lc_total_count               VARCHAR2(1000);
lc_total_success             VARCHAR2(1000);
lc_total_failed              VARCHAR2(1000);
lc_total_exists              VARCHAR2(1000);
ln_named_acct_terr_id        PLS_INTEGER;
lc_pty_site_success          VARCHAR2(03);
lc_role                      VARCHAR2(50);

ln_terr_id                   PLS_INTEGER;        
lc_resource_name             VARCHAR2(2000);
lc_terr_name                 VARCHAR2(1000); 
lc_terr_desc                 VARCHAR2(1000);
ln_party_id                  PLS_INTEGER;
lc_party_name                VARCHAR2(1000);
lc_resource_od_role_code     VARCHAR2(250);
lc_cust_prospect             VARCHAR2(50);
lc_postal_code               VARCHAR2(50);
lc_country                   VARCHAR2(50);
lc_od_site_sic_code          VARCHAR2(250);
ln_od_wcw                    PLS_INTEGER;

lc_resource_group_name       VARCHAR2(500);
lc_resource_role_div         VARCHAR2(500);
ln_res_role_id               PLS_INTEGER;  

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
l_squal_num01                NUMBER;
l_squal_num02                NUMBER;
l_squal_num03                NUMBER;
l_squal_num04                NUMBER;
l_squal_num05                NUMBER;
l_squal_num06                NUMBER;
l_squal_num07                NUMBER;
ln_count                     PLS_INTEGER;
lc_manager_flag              VARCHAR2(03);
lc_message_code              VARCHAR2(30);
ln_party_site_id             PLS_INTEGER;
lc_party_site_assign_exists  VARCHAR2(10);
ln_terr_resource_id          PLS_INTEGER;
ln_terr_role_id              PLS_INTEGER;
ln_terr_group_id             PLS_INTEGER;
ln_acct_terr_id              PLS_INTEGER;
lc_concat_rsc_role_grp_id    VARCHAR2(2000);
lc_rsc_role_grp_flag         VARCHAR2(03);
ln_min_index                 PLS_INTEGER;
ln_max_index                 PLS_INTEGER;
ln_min_party_site_id         PLS_INTEGER;
ln_max_party_site_id         PLS_INTEGER;
lc_acct_party_site_id_exists VARCHAR2(10);
lc_acct_party_id_exists      VARCHAR2(10);
ln_party_internal            PLS_INTEGER := 0;
ln_party_site_err            PLS_INTEGER := 0;
lc_assignee_admin_flag       VARCHAR2(03);
ln_admin_count               PLS_INTEGER;
lc_party_site_enrich_exists  VARCHAR2(10);
ln_party_site_enrich         NUMBER := 0;

-----------------------------------
-- Declaring Record Type Variables
-----------------------------------
TYPE terr_rsc_role_grp_id_rec_type IS RECORD
    (
        NAMED_ACCT_TERR_ID   NUMBER
      , RESOURCE_ID          NUMBER
      , ROLE_ID              NUMBER
      , GROUP_ID             NUMBER
      , ENTITY_ID            NUMBER
    );

lp_gen_bulk_rec    JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type;
lx_gen_return_rec  JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;
lx_gen_return_rec_init  JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;

-- ---------------------------------------------------------------------------
-- Declare cursor to fetch the records from hz_party_sites based on the range
-- ---------------------------------------------------------------------------
CURSOR lcu_party_sites(
                       p_from_party_site_id NUMBER
                       , p_to_party_site_id NUMBER
                      )
IS
SELECT  pe.party_site_id   
       ,pe.attribute13       
       ,pe.country           
  FROM  TABLE(
                xx_tm_named_acct_preprocessor.Pipelined_Site_Loc_Dtls
                  (                                                  
                    CURSOR (                                                 
                             SELECT   /*+ first_rows(10) */
                    		      HPS.party_site_id
                                    , HP.attribute13
                    		    , HL.country
                    		FROM     hz_party_sites HPS
                    		       , hz_parties HP
                    		       , hz_locations HL
                    		WHERE  HP.party_id = HPS.party_id
                    		AND    HP.party_type = 'ORGANIZATION'
                    		AND    HPS.status = 'A'
                    		AND    HP.status = 'A'
                    		AND    HL.location_id =HPS.location_id
                    		AND    HPS.party_site_id BETWEEN p_from_party_site_id AND p_to_party_site_id
                    		ORDER BY 1
                            )                                                 
                  )                                                 
              ) PE;

--Added for New Changes
CURSOR lcu_acct_party_site_valid(
                                 p_party_site_id IN NUMBER
                                )
IS
SELECT pe.attribute18   
      ,pe.party_site_id
      ,pe.customer_type   
FROM   TABLE(
             xx_tm_named_acct_preprocessor.Pipelined_Site_Cust_Type_Dtls
                  (                                                  
                    CURSOR (                                                 
                             SELECT   HCA.attribute18
                    	            , HCAS.party_site_id
                                    , HCA.customer_type
                    	     FROM   hz_cust_accounts HCA
                    	            , hz_cust_acct_sites HCAS
                    	     WHERE  HCAS.cust_account_id = HCA.cust_account_id
                    	     AND    HCA.status='A'
                    	     AND    HCAS.status ='A'
                    	     AND    HCA.status = HCAS.status
                    	     AND    HCAS.party_site_id = p_party_site_id
                            )                                                 
                 )                                                 
            ) PE;  


--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE party_sites_tbl_type IS TABLE OF lcu_party_sites%ROWTYPE INDEX BY PLS_INTEGER;
lt_party_sites            party_sites_tbl_type;
lt_party_sites_initialize party_sites_tbl_type;


TYPE acct_party_site_tbl_type IS TABLE OF lcu_acct_party_site_valid%ROWTYPE INDEX BY PLS_INTEGER;
lt_acct_party_site_id         acct_party_site_tbl_type;
lt_acct_party_site_id_init    acct_party_site_tbl_type;

ln_enrichment_exists          PLS_INTEGER := 0;
ln_acct_party_site_valid      PLS_INTEGER := 0;
ln_insert_count               PLS_INTEGER := 0;
ln_gt_tab_count               PLS_INTEGER := 0;
ln_preprocessor_record_id     NUMBER := 0;
lc_total_rec_inserted         PLS_INTEGER := 0;
ln_terr_rsc_role_grp          PLS_INTEGER := 0;

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

BEGIN

   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------
   DBMS_SESSION.free_unused_user_memory;
   
   WRITE_LOG(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG(LPAD('OD: Party Site Named Account Mass Assignment',52));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG('');
   WRITE_LOG('Input Parameters ');
   WRITE_LOG('Party Site ID From : '||p_from_party_site_id);
   WRITE_LOG('Party Site ID To   : '||p_to_party_site_id);
   WRITE_LOG(RPAD(' ',80,'-'));

   WRITE_OUT(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   WRITE_OUT(RPAD(' ',80,'-'));
   WRITE_OUT(LPAD('OD: Party Site Named Account Mass Assignment',52));
   WRITE_OUT(RPAD(' ',80,'-'));
   WRITE_OUT('');
   WRITE_OUT(RPAD(' ',80,'-'));

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

   -- Retrieve the records from HZ_PARTY_SITES based on the two input parameters to the table type
   
   
   OPEN lcu_party_sites(
                        p_from_party_site_id => p_from_party_site_id
                        , p_to_party_site_id => p_to_party_site_id
                       );
   LOOP

       -- Initializing the variables
       ln_min_index         := NULL;
       ln_max_index         := NULL;
       ln_min_party_site_id := NULL;
       ln_max_party_site_id := NULL;
       lt_party_sites.DELETE;
       

       FETCH lcu_party_sites BULK COLLECT 
       INTO lt_party_sites LIMIT G_LIMIT;
       
       EXIT WHEN lt_party_sites.COUNT = 0;
       
       IF lt_party_sites.COUNT > 0 THEN

          -- Get the minimum and maximum index of the table type

          ln_min_index := lt_party_sites.FIRST;
          ln_max_index := lt_party_sites.LAST;

          -- Get the minimum and maximum party_site_id

          ln_min_party_site_id := lt_party_sites(ln_min_index).party_site_id;
          ln_max_party_site_id := lt_party_sites(ln_max_index).party_site_id;

          -- Fetch the already existing data between the range of party_site_id in a tbl type
          
       
          FOR i IN lt_party_sites.FIRST .. lt_party_sites.LAST
          LOOP

              -- Initializing the variable
              ln_enrichment_exists  := 0;
              ln_party_site_id      := NULL;
              ln_named_acct_terr_id := NULL;
              lc_return_status      := NULL;
              ln_msg_count          := NULL;
              lc_msg_data           := NULL;
              lc_error_message      := NULL;
              l_counter             := NULL;
              lc_pty_site_success   := NULL;
              lc_party_site_enrich_exists := NULL;
              
              -- To count the number of records read
              ln_total_count := ln_total_count + 1;

              ln_party_site_id := lt_party_sites(i).party_site_id;
              
              IF nvl(p_gdw_validate_YN,'N') = 'Y' OR lt_party_sites(i).country ='CA' Then
              lc_party_site_enrich_exists :='Y';
              
                 IF lt_party_sites(i).attribute13='PROSPECT' THEN
                   
                    SELECT COUNT(1)
                    INTO   ln_enrichment_exists
                    FROM    DUAL
                    WHERE   EXISTS
                    ( 
                      SELECT 1
                       FROM   hz_party_sites_ext_b HPSB
                            , hz_imp_batch_summary HIBS
                            , ego_attr_groups_v    EAGV
                       WHERE EAGV.attr_group_type = 'HZ_PARTY_SITES_GROUP'
                       AND   EAGV.attr_group_name = 'SITE_DEMOGRAPHICS'
                       AND   HPSB.attr_group_id = EAGV.attr_group_id
                       AND   HPSB.party_site_id = ln_party_site_id
                       AND   HIBS.batch_id = HPSB.n_ext_attr20
                       AND   HIBS.original_system='GDW'                       
                      );
                      
                      IF ln_enrichment_exists > 0  THEN
                        
                         lc_party_site_enrich_exists:='N';
                         
                      END IF;   
                 
                 ELSE
                   lc_party_site_enrich_exists :='Y';
                 END IF;
              ELSE
              lc_party_site_enrich_exists :='N';
              END IF;
              
              lc_acct_party_site_id_exists :='N';
              lc_acct_party_id_exists :='N';
             
              lt_acct_party_site_id.DELETE;
              OPEN lcu_acct_party_site_valid(
                                             p_party_site_id => ln_party_site_id
                                            );
              LOOP
                FETCH lcu_acct_party_site_valid BULK COLLECT 
                INTO lt_acct_party_site_id LIMIT 100;
                
                EXIT WHEN  lt_acct_party_site_id.count = 0;
                
                IF lt_acct_party_site_id.count > 0  THEN
                
                   FOR i IN lt_acct_party_site_id.FIRST .. lt_acct_party_site_id.LAST
                   LOOP
                       
                         IF lt_acct_party_site_id(i).customer_type='I' THEN
  
                          lc_acct_party_id_exists:='Y';
                          EXIT;
                         END IF;
                         
                         IF nvl(lt_acct_party_site_id(i).attribute18,'0') <> 'CONTRACT' THEN
                          lc_acct_party_site_id_exists:='Y';
                          
                          --IF lt_acct_party_site_id(i).attribute18 IS NOT NULL THEN
                          --   WRITE_LOG('Party Site ID : '||ln_party_site_id||' is ' ||lt_acct_party_site_id(i).attribute18 ||' Customer');
                          --ELSE
                          --   WRITE_LOG('Party Site ID : '||ln_party_site_id||' Customer type attribute18 is null ');
                          --END IF;
                          
                          EXIT;
                          
                         END IF;
                         
                   END LOOP;
                   
                END IF;
                
              END LOOP;
              CLOSE lcu_acct_party_site_valid;
              lt_acct_party_site_id.delete;
              lt_acct_party_site_id := lt_acct_party_site_id_init;
              
              --End of Additional validation added by jeevan
              lc_party_site_assign_exists := 'N';

              -- Check whether the party_site_id already exists in the entity table

              IF (lc_party_site_enrich_exists='N' OR lt_party_sites(i).attribute13='CUSTOMER' )
              AND lc_acct_party_id_exists ='N'                
              AND lc_acct_party_site_id_exists='N' THEN
               
                 ln_terr_rsc_role_grp := 0;
               
                 SELECT COUNT(1)
                 INTO ln_terr_rsc_role_grp
                 FROM DUAL
                 WHERE EXISTS
                 (
                 SELECT  
                         1      
                 FROM    apps.xx_tm_nam_terr_rsc_dtls terr_rsc,
                         apps.xx_tm_nam_terr_defn terr        ,
                         apps.xx_tm_nam_terr_entity_dtls terr_ent
                 WHERE   terr.named_acct_terr_id     = terr_rsc.named_acct_terr_id
                     AND terr_ent.named_acct_terr_id = terr_rsc.named_acct_terr_id
                     AND terr_ent.named_acct_terr_id = terr.named_acct_terr_id
                     AND SYSDATE BETWEEN NVL (terr.start_date_active, SYSDATE     - 1) AND NVL (terr.end_date_active, SYSDATE + 1)
                     AND SYSDATE BETWEEN NVL (terr_ent.start_date_active, SYSDATE - 1) AND NVL (terr_ent.end_date_active, SYSDATE + 1)
                     AND SYSDATE BETWEEN NVL (terr_rsc.start_date_active, SYSDATE - 1) AND NVL (terr_rsc.end_date_active, SYSDATE + 1)
                     AND NVL (terr.status, 'A')     = 'A'
                     AND NVL (terr_ent.status, 'A') = 'A'
                     AND NVL (terr_rsc.status, 'A') = 'A'
                     AND terr_ent.entity_type = 'PARTY_SITE' 
                     AND terr_ent.entity_id = ln_party_site_id
                 );     
               
                 IF  ln_terr_rsc_role_grp > 0 THEN
                    lc_party_site_assign_exists := 'Y';
                 END IF; 
               
                
              END IF;
              
              --Additional validation logic added by jeevan
              IF  lc_party_site_enrich_exists ='Y' THEN
              
                  --WRITE_LOG('Party Site ID : '||ln_party_site_id||' data not enriched' );
                  
                  ln_party_site_enrich := ln_party_site_enrich + 1;
                  
              ELSIF  lc_acct_party_id_exists ='Y' THEN
              
                 ln_party_internal := ln_party_internal + 1;
                 
              ELSIF lc_acct_party_site_id_exists ='Y' THEN
              
                 ln_party_site_err := ln_party_site_err + 1;
              --Additional validation logic added by jeevan

              ELSIF lc_party_site_assign_exists = 'Y' THEN

                 ln_exists_count := ln_exists_count + 1;

              ELSE

                  -- Call to JTF_TERR_ASSIGN_PUB.get_winners with the party_site_id

                     lp_gen_bulk_rec.squal_char01(1) := l_squal_char01;
                     lp_gen_bulk_rec.squal_char02(1) := l_squal_char02 ;
                     lp_gen_bulk_rec.squal_char03(1) := l_squal_char03;
                     lp_gen_bulk_rec.squal_char04(1) := l_squal_char04;
                     lp_gen_bulk_rec.squal_char05(1) := l_squal_char05;
                     lp_gen_bulk_rec.squal_char06(1) := l_squal_char06;  
                     lp_gen_bulk_rec.squal_char07(1) := l_squal_char07;  
                     lp_gen_bulk_rec.squal_char08(1) := l_squal_char08;
                     lp_gen_bulk_rec.squal_char09(1) := l_squal_char09;
                     lp_gen_bulk_rec.squal_char10(1) := l_squal_char10;
                     lp_gen_bulk_rec.squal_char11(1) := l_squal_char11;
                     lp_gen_bulk_rec.squal_char50(1) := l_squal_char50;
                     lp_gen_bulk_rec.squal_char59(1) := l_squal_char59;  
                     lp_gen_bulk_rec.squal_char60(1) := l_squal_char60;  
                     lp_gen_bulk_rec.squal_char61(1) := ln_party_site_id; --Party Site Id
                     lp_gen_bulk_rec.squal_num60(1)  := l_squal_num60;  
                     lp_gen_bulk_rec.squal_num01(1)  := l_squal_num01;   
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

                             FOR k IN 1 .. ln_msg_count
                             LOOP

                                 lc_msg_data := FND_MSG_PUB.GET(
                                                                p_encoded     => FND_API.G_FALSE
                                                                , p_msg_index => k
                                                               );
                                 --WRITE_LOG('Error for the party site id: '||ln_party_site_id||' '||lc_msg_data);
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

                          l_counter := lx_gen_return_rec.resource_id.FIRST;

                          WHILE (l_counter <= lx_gen_return_rec.terr_id.LAST)
                          LOOP

                              BEGIN
                              
                              -- Initialize the variables

                              ln_salesforce_id          := NULL;
                              ln_sales_group_id         := NULL;
                              ln_asignee_role_id        := NULL;
                              lc_error_message          := NULL;
                              lc_set_message            := NULL;
                              lc_status                 := NULL;
                              lc_role                   := NULL;
                              ln_count                  := 0;
                              lc_manager_flag           := NULL;
                              ln_terr_id                := NULL;
                              lc_resource_name          := NULL;
                              
                              lc_terr_name              := NULL;
                              lc_terr_desc    		:= NULL;
                              ln_party_id     		:= NULL;
                              lc_party_name   		:= NULL;
                              
                              

                              -- Fetch territory definition properties
                              ln_terr_id           := lx_gen_return_rec.terr_id(l_counter);  
                              
                              -- Fetch resource definition properties
                              ln_salesforce_id    := lx_gen_return_rec.resource_id(l_counter);      
                              ln_sales_group_id   := lx_gen_return_rec.group_id(l_counter);         
                              lc_role             := lx_gen_return_rec.role(l_counter);             
                              lc_resource_name    := lx_gen_return_rec.resource_name(l_counter);    
                              
                              
                              -- Check whether the assignee resource is an admin
                              OPEN  lcu_admin(
                                                p_resource_id => ln_salesforce_id
                                              , p_group_id    => ln_sales_group_id
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

                              END IF;
                              
                              -- Deriving the group id of the resource if ln_sales_group_id IS NULL
                                                                  
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
                                
                                -- First check whether the resource is a manager
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
                                           ,ln_sales_group_id
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
                                          WRITE_LOG(lc_error_message);
                                       ELSE
                                           FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0122_AS_NO_SALES_ROLE');
                                           FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                           lc_error_message := FND_MESSAGE.GET;
                                           lc_message_code  := 'XX_TM_0122_AS_NO_SALES_ROLE';
                                           WRITE_LOG(lc_error_message);
                                       END IF;
                                       WRITE_LOG(lc_error_message);
                                       RAISE EX_CREATE_ERR;
                                   WHEN TOO_MANY_ROWS THEN
                                       IF lc_manager_flag = 'Y' THEN
                                          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0230_AS_MGR_HSE_ROLE');
                                          FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                          lc_error_message := FND_MESSAGE.GET;
                                          lc_message_code  := 'XX_TM_0230_AS_MGR_HSE_ROLE';
                                          WRITE_LOG(lc_error_message);
                                          
                                       ELSE
                                           FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0123_AS_MANY_SALES_ROLE');
                                           FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                           lc_error_message := FND_MESSAGE.GET;
                                           lc_message_code  := 'XX_TM_0123_AS_MANY_SALES_ROLE';
                                           WRITE_LOG(lc_error_message);
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
                                             ,ln_sales_group_id
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
                                      ,description 
                                INTO   lc_terr_name      
                                      ,lc_terr_desc       
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
                                      ,P.party_name 
                                      ,P.Attribute13
                                      ,(CASE WHEN HL.country = 'US' THEN 
                                             SUBSTR(HL.postal_code,1,5)
                                         WHEN HL.country = 'CA' THEN 
                                           SUBSTR(HL.postal_code,1,3)
                                        END		  
                                       ) postal_code	  
                                      ,HL.country
                                INTO   ln_party_id
                                      ,lc_party_name 
                                      ,lc_cust_prospect
                                      ,lc_postal_code
                                      ,lc_country
                                FROM   hz_parties     P
                                      ,hz_party_sites PS
                                      ,hz_locations   HL
                                WHERE PS.party_id      = P.party_id
                                AND   PS.party_site_id = ln_party_site_id
                                AND   HL.location_id   = PS.location_id;
                                
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
                                
                                SELECT 
                              	       UPPER(
                              	              SUBSTR(
                              	                       HPSEXT.c_ext_attr10
                              	                      ,1
                              	                      ,INSTR(HPSEXT.c_ext_attr10,':',1)+4
                              	                    )
                              	             )                    od_site_sic_code
                              	     ,NVL(HPSEXT.n_ext_attr8,0)   od_wcw
                                INTO  lc_od_site_sic_code                              	      
                              	     ,ln_od_wcw 
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
                                 SELECT JSRV.attribute14
                                       ,JSRV.attribute15
                                       ,JSRV.role_id
                                 INTO  lc_resource_od_role_code
                                      ,lc_resource_role_div
                                      ,ln_res_role_id
			         from jtf_rs_roles_vl    JSRV
                                 where role_id      = ln_asignee_role_id;
                              
                              EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                   lc_resource_role_div := NULL;
                                   ln_res_role_id       := NULL;
                                WHEN OTHERS THEN   
                                   lc_resource_role_div := NULL;
                                   ln_res_role_id       := NULL;
                              END;                     
                              
                              BEGIN
                              
                                SELECT GRPVL.group_name
                                INTO   lc_resource_group_name
			        FROM   JTF_RS_GROUPS_vL GRPVL
			        WHERE  GRPVL.group_id    = ln_sales_group_id;
			       
                                
                              EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                   lc_resource_group_name := NULL;
                                WHEN OTHERS THEN   
                                   lc_resource_group_name := NULL;
                              END;                     
                              
                              ln_insert_count := NVL(ln_insert_count,0) + 1;
                              
                              gt_insert_index_rec(ln_insert_count) := NULL;
                              
                              SELECT xx_tm_nmdactasgn_preproc_s.NEXTVAL
                              INTO   ln_preprocessor_record_id
                              FROM   DUAL;
                              
                              gt_insert_preprocessor(ln_insert_count).preprocessor_record_id     := ln_preprocessor_record_id              ;
                              
                              gt_insert_preprocessor(ln_insert_count).rule_based_terr_id          := ln_terr_id              ;
                              gt_insert_preprocessor(ln_insert_count).rule_based_terr_name  	 := lc_terr_name ;
                              gt_insert_preprocessor(ln_insert_count).rule_based_terr_desc  	 := lc_terr_desc ;
                              gt_insert_preprocessor(ln_insert_count).resource_id           	 := ln_salesforce_id ;
                              gt_insert_preprocessor(ln_insert_count).resource_name         	 := lc_resource_name ;
                              gt_insert_preprocessor(ln_insert_count).resource_role_id      	 := ln_asignee_role_id      ;
                              gt_insert_preprocessor(ln_insert_count).resource_role_name    	 := lc_role ;
                              gt_insert_preprocessor(ln_insert_count).resource_role_div     	 := lc_resource_role_div;
                              gt_insert_preprocessor(ln_insert_count).resource_group_id     	 := ln_sales_group_id       ;
                              gt_insert_preprocessor(ln_insert_count).resource_group_name   	 := lc_resource_group_name;
                              gt_insert_preprocessor(ln_insert_count).party_site_id         	 := ln_party_site_id ;
                              gt_insert_preprocessor(ln_insert_count).party_id              	 := ln_party_id ;
                              gt_insert_preprocessor(ln_insert_count).party_name 	         := lc_party_name ;
                              gt_insert_preprocessor(ln_insert_count).resource_od_role_code	 := lc_resource_od_role_code;
                              gt_insert_preprocessor(ln_insert_count).prospect_customer     	 := lc_cust_prospect        ;
                              gt_insert_preprocessor(ln_insert_count).postal_code          	 := lc_postal_code          ;
                              gt_insert_preprocessor(ln_insert_count).country              	 := lc_country              ;
                              gt_insert_preprocessor(ln_insert_count).od_site_sic_code     	 := lc_od_site_sic_code     ;
                              gt_insert_preprocessor(ln_insert_count).od_wcw               	 := ln_od_wcw               ;
                              gt_insert_preprocessor(ln_insert_count).CREATED_BY               	 := FND_GLOBAL.USER_ID                ;
                              gt_insert_preprocessor(ln_insert_count).CREATION_DATE              := SYSDATE               ;
                              
                              
                              
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
                          l_counter    := l_counter + 1;

                          END LOOP; -- l_counter <= lx_gen_return_rec.terr_id.LAST
                                                    
                          lx_gen_return_rec := lx_gen_return_rec_init;
                          
                     EXCEPTION
                        WHEN EX_PARTY_SITE_ERROR THEN
                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0130_BULK_PARTY_SITE_ERR');
                            FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', ln_party_site_id);
                            lc_error_message := FND_MESSAGE.GET;
                            lc_pty_site_success := 'N';
                            WRITE_LOG(lc_error_message);
                            ROLLBACK;
                        WHEN NO_DATA_FOUND THEN
                           NULL;
                           lc_error_message := 'No Data Found2; Party Site Id: '||ln_party_site_id;
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
                           ROLLBACK;
                     END;

                 END IF; -- ln_named_acct_terr_id IS NOT NULL

                 IF (lc_pty_site_success = 'S') THEN

                     -- Storing the value of the last successful created opportunity record
                     ln_success_count := ln_success_count + 1;

                 ELSIF (lc_pty_site_success = 'N') THEN

                       ln_error_count := ln_error_count + 1;

                 END IF; -- lc_pty_site_success = 'S'

          END LOOP; -- lt_party_sites.FIRST .. lt_party_sites.LAST

       END IF; -- lt_party_sites.COUNT <> 0

       

   END LOOP; -- lcu_party_sites
   CLOSE lcu_party_sites;
   lt_party_sites.DELETE;   
   lt_party_sites := lt_party_sites_initialize;
   
   
   ln_gt_tab_count := gt_insert_preprocessor.COUNT;
   
   BEGIN 
         lc_total_rec_inserted := 0;
         
         INSERT_ROW						 
           (							 
              x_return_status         => lc_return_status 
            , x_msg_count             => ln_msg_count 
            , x_message_data          => lc_msg_data 
            , x_record_inserted       => lc_total_rec_inserted
           );
         
   
               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
   
                  FOR b IN 1 .. ln_msg_count
                  LOOP
   
                      lc_msg_data := FND_MSG_PUB.GET(
                                                     p_encoded     => FND_API.G_FALSE
                                                     , p_msg_index => b
                                                    );
                      WRITE_LOG(lc_msg_data);
                      
   
                      END LOOP;
                      RAISE EX_CREATE_ERR; 
               ELSE
                   COMMIT;
               END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
   
         
     EXCEPTION
        WHEN EX_CREATE_ERR THEN
            NULL;
            lc_error_message := 'Error creating Preprocessor records. ';
            WRITE_LOG(lc_error_message);
        WHEN OTHERS THEN
           FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
           lc_set_message     :=  'Unexpected Error while bulk inserting. ';
           FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
           FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
           FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
           lc_error_message := FND_MESSAGE.GET;
           WRITE_LOG(lc_error_message);
           lc_pty_site_success := 'N';
     END;
   
     --DBMS_SESSION.free_unused_user_memory;
     
   lc_error_message := NULL;

   -- ----------------------------------------------------------------------------
   -- Write to output file, the total number of records processed, number of
   -- success and failure records.
   -- ----------------------------------------------------------------------------

   WRITE_OUT(' ');
   
   WRITE_OUT('Count of Global Tab: '||ln_gt_tab_count);
   
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
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0262_UNRICH_PS_ERR');
   FND_MESSAGE.SET_TOKEN('P_UNRICH_COUNT', ln_party_site_enrich);
   lc_total_exists  := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_exists); 
   
   IF ln_error_count <> 0 THEN

     -- End the program with warning
     x_retcode := 1;

   END IF;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      NULL;
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
END XX_TM_NAMED_ACCT_PREPROCESSOR;
/
SHOW ERRORS;
