create or replace
PACKAGE BODY XX_AR_TRADE_FILE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  XX_AR_TRADE_FILE_PKG  I2097(Defect 2795)      |
-- | Description      :  This Package is used to transmit the Trade    |
-- |                     File to third party Vendors such as           |
-- |                     DNB,EQUIFAX and CRM with the aging Information|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 05-Oct-2009  Vinaykumar S   Initial draft version(CR 600)|
-- | 1.1      15-Oct-2009  Vinaykumar S   Changes made to the code as  |
-- |                                       per subbu's comments        |
-- | 1.2      20-Oct-2009  Vinaykumar S   Changes made to the code     |
-- |                                        to improve the performance |
-- | 2.0      12-JUL-2010  Debra Gaudard  Changes made to the code     |
-- |                                        per CR 785 - removed       |
-- |                                        references to specific     |
-- |                                        agencies and removed the   |
-- |                                        extract of cred card custs |
-- |3 .0       03-JAN-2013 Deepak V         Changes for Defect 27339.  |
-- |                                       Hint removed from query.    |
-- |4.0        28-OCT-2015 Vasu Raparla    Removed Schema References   |
-- |                                        for R12.2                  |
-- +===================================================================+


/* CR 785: removed p_credit_agent as an input parm */
PROCEDURE XX_AR_TRADE_FILE_MAIN(x_errbuf            OUT  NOCOPY VARCHAR2
                               ,x_retcode           OUT  NOCOPY VARCHAR2
                               ,p_thread_count       IN   NUMBER
                               )
AS

  -- Local Variable declaration
   ln_request_id        NUMBER(15);
   lc_request_data      VARCHAR2(15);
   ln_cnt_err_request   NUMBER;
   ln_parent_request_id NUMBER;
     BEGIN

          ln_parent_request_id := fnd_global.conc_request_id;

          lc_request_data :=FND_CONC_GLOBAL.request_data;

  /* CR 785: removed p_credit_agent as a parm */
                 IF ( lc_request_data IS NULL) THEN

                         ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                                      'XXFIN'
                                                                      ,'XXARTRADEFILE'
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,TRUE
                                                                      ,p_thread_count
                                                                     );

                          COMMIT;
                          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request ID '||ln_request_id);
                          FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>'COMPLETE');

                  END IF;



          SELECT count(*)
          INTO ln_cnt_err_request
          FROM fnd_concurrent_requests
          WHERE parent_request_id = ln_parent_request_id
          AND phase_code = 'C'
          AND status_code = 'E';

          IF ln_cnt_err_request <> 0 THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,ln_cnt_err_request ||' Child Requests are Errored Out.Please, Check the Child Requests LOG for Details');
            x_retcode := 2;

          END IF;

     EXCEPTION

      WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in XX_AR_TRADE_FILE_MAIN Procedure'|| SQLERRM);
          x_retcode := 2;

  END XX_AR_TRADE_FILE_MAIN;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        Wipro-Office Depot                         |
-- +===================================================================+
-- | Name             :  XX_AR_TRADE_FILE_EXTRACT                      |
-- | Description      :  This Procedure is called from                 |
-- |                   XX_AR_TRADE_FILE_MAIN and used to used to submit|
-- |                   the OD: AR Trade File Extract - Child concurrent|
-- |                   program in batches depending on the thread count|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date              Author                  Remarks        |
-- |=======   ==========        =============    ======================|
-- |DRAFT 1.0 05-Oct-2009       Vinaykumar S    Initial draft version  |
-- | 1.1      15-Oct-2009       Vinaykumar S   Changes made to the code|
-- |                                            as per subbu's comments|
-- | 1.2      15-Oct-2009       Vinaykumar S   Changes made to the code|
-- |                                             to improve the        |
-- |                                               performance         |
-- | 2.0      12-JUL-2010  Debra Gaudard  Changes made to the code     |
-- |                                        per CR 785 - removed       |
-- |                                        references to specific     |
-- |                                        agencies and removed the   |
-- |                                        extract of cred card custs |
-- +===================================================================+

 /* CR 785: removed p_credit_agent as a parm */
PROCEDURE XX_AR_TRADE_FILE_EXTRACT ( x_errbuf       OUT  NOCOPY    VARCHAR2
                                    ,x_retcode      OUT  NOCOPY    VARCHAR2
                                    ,p_thread_count IN             NUMBER)

AS

---------------------------------
--   VARIABLE DECLARATION      --
---------------------------------

        ln_parent_request_id     NUMBER := 0;
        lc_source_dir_path       VARCHAR2(4000);
        lc_extract_file_path     VARCHAR2(4000);
        lc_copy_file_path        VARCHAR2(4000);
        lc_aging_bucket_name     VARCHAR2(50);

        lc_setup_exception        EXCEPTION;
        ln_cnt_err_request        NUMBER;
        ln_min_cust_acct_id       NUMBER;
        ln_max_cust_acct_id       NUMBER;
        ln_batch_size             NUMBER;
        ln_tot_elg_customers      NUMBER;
        ln_upper_range            NUMBER;
        ln_start_id               NUMBER;
        lc_credit_cust_flag       VARCHAR2(2);
        lc_request_data           VARCHAR2(15);
        lc_filename               VARCHAR2(4000);
        ln_request_id             NUMBER;

        lc_message                VARCHAR2 (2000);
        lc_phase                  VARCHAR2 (50);
        lc_status                 VARCHAR2 (50);
        lc_dev_phase              VARCHAR2 (15);
        lc_dev_status             VARCHAR2 (15);
        ln_error_cnt              NUMBER;
        lb_wait                   BOOLEAN;


        -- pl/sql table to hold all batch Id's created.
        TYPE rec_batch_id IS RECORD (
                                     request_id     NUMBER
                                    ,status   VARCHAR2 (50)
                                    );

        lrec_batch_id                 rec_batch_id;

        TYPE tab_batch_id IS TABLE OF lrec_batch_id%TYPE
        INDEX BY BINARY_INTEGER;

        gtab_batch_id                 tab_batch_id;

----------------------------------------------------------------------------------
-- This procedure is to submit the OD: Create Zip File Concurrent Program to zip--
-- the concatened file and after that OD: Common File Copy Concurrent program   --
-- is submitted to move the zippedfile to FTP folder                            --
----------------------------------------------------------------------------------

      PROCEDURE XX_MOVE_EXTRACT_TO_FTP
          AS
           ln_request_id        NUMBER(15);
           lc_arc_file_path     VARCHAR2(4000);

          BEGIN

                   lc_request_data :=FND_CONC_GLOBAL.request_data;
                    /* CR 785: removed credit agent name from the file name */
                        FND_FILE.PUT_LINE(FND_FILE.LOG,' Started Zipping the File');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,' IN FOLDER ' || lc_source_dir_path||'/'||lc_filename||'.txt');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,' OUT FOLDER ' || lc_source_dir_path);


                  IF  (lc_request_data IS NULL  OR lc_request_data = 'THREAD') THEN

                          ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                                      'XXFIN'
                                                                      ,'XXODARTRADEZIP'
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,TRUE
                                                                      ,lc_source_dir_path||'/'||lc_filename||'.txt'
                                                                      ,lc_source_dir_path
                                                                     );
                         COMMIT;
                          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request ID '||ln_request_id);
                          FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>'ZIPPED');
                  END IF;

           -------------------------------------------------------
           --   Getting the Archive File Path using Translation    --
           -------------------------------------------------------

                   BEGIN

                         SELECT XFTV.target_value6
                         INTO   lc_arc_file_path
                         FROM   xx_fin_translatedefinition XFTD
                               ,xx_fin_translatevalues XFTV
                         WHERE  XFTD.translate_id = xftv.translate_id
                         AND    XFTD.translation_name = 'XX_AR_CUST_EXT_TRADE_FILE'
                         AND     XFTD.target_field6 = 'Archive File Path'
                         AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                         AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                         AND    XFTV.enabled_flag = 'Y'
                         AND    XFTD.enabled_flag = 'Y'
                         AND    XFTV.target_value6 IS NOT NULL;


                     EXCEPTION
                       WHEN OTHERS THEN
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting archive file path from translation '|| SQLERRM);
                          RAISE lc_setup_exception;
                   END;

                    /* CR 785: removed credit agent name from the file name */
                        FND_FILE.PUT_LINE(FND_FILE.LOG,' Moving the Zip File to FTP Folder');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,' IN FOLDER ' || lc_source_dir_path||'/'||lc_filename||'.txt');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,' OUT FOLDER ' || lc_source_dir_path);

                   IF  lc_request_data = 'ZIPPED'  THEN

                          ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                                      'XXFIN'
                                                                      ,'XXCOMFILCOPY'
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,TRUE
                                                                      ,lc_source_dir_path||'/'||lc_filename||'.txt.gz'
                                                                      ,lc_copy_file_path||'/'||lc_filename||'.txt.gz'
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,'Y'
                                                                      ,lc_arc_file_path
                                                                     );
                         COMMIT;
                          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request ID '||ln_request_id);
                          FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>'FTP');

                   END IF;

          EXCEPTION
                    WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in Zipping the Extract File'|| SQLERRM );
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'The File Name  : ' ||lc_filename);

          END  XX_MOVE_EXTRACT_TO_FTP;


     BEGIN

           ln_parent_request_id := fnd_profile.value('CONC_REQUEST_ID');

           ---------------------------------------------------------
           --   Getting the Extract File Path using Translation   --
           ---------------------------------------------------------

              BEGIN

                         SELECT XFTV.target_value4
                         INTO   lc_extract_file_path
                         FROM   xx_fin_translatedefinition XFTD
                               ,xx_fin_translatevalues XFTV
                         WHERE  XFTD.translate_id = xftv.translate_id
                         AND    XFTD.translation_name = 'XX_AR_CUST_EXT_TRADE_FILE'
                        AND     XFTD.target_field4 = 'Extract File Path'
                         AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                         AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                         AND    XFTV.enabled_flag = 'Y'
                         AND    XFTD.enabled_flag = 'Y'
                         AND    XFTV.target_value4 IS NOT NULL;


             EXCEPTION
               WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting directory path from translation '|| SQLERRM);
                  RAISE lc_setup_exception;
             END;


           BEGIN
             SELECT directory_path
             INTO lc_source_dir_path
             FROM   dba_directories
             WHERE  directory_name = lc_extract_file_path;
           EXCEPTION
           WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting directory path '|| SQLERRM);
              RAISE lc_setup_exception;
           END;

           -------------------------------------------------------
           --   Fetching the Bucket Translation Value  --
           -------------------------------------------------------

                   BEGIN

                         SELECT XFTV.target_value1
                         INTO   lc_aging_bucket_name
                         FROM   xx_fin_translatedefinition XFTD
                               ,xx_fin_translatevalues XFTV
                         WHERE  XFTD.translate_id = xftv.translate_id
                         AND    XFTD.translation_name = 'XX_AR_CUST_EXT_TRADE_FILE'
                        AND     XFTD.target_field1 = 'Aging Bucket'
                         AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                         AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                         AND    XFTV.enabled_flag = 'Y'
                         AND    XFTD.enabled_flag = 'Y'
                         AND    XFTV.target_value1 IS NOT NULL;

                   EXCEPTION
                          WHEN OTHERS THEN
                             FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in Getting Bucket Translation '|| SQLERRM);
                             RAISE lc_setup_exception;
                   END;

           -----------------------------------------------------------
           --   Fetching the Min and Max Cust Accounts for Batching
           -----------------------------------------------------------

            --SELECT /*+ PARALLEL(HCA,4)*/MIN(hca.cust_account_id)  Commented for R12upgrade retrofit QC Defect - 27339
            SELECT MIN(hca.cust_account_id)  --Added for R12 upgrade retrofit  QC Defect - 27339
                  ,MAX(hca.cust_account_id)
            INTO  ln_min_cust_acct_id
                 ,ln_max_cust_acct_id
            FROM   hz_cust_accounts hca
            WHERE  hca.status = 'A';

            ln_tot_elg_customers := (ln_max_cust_acct_id - ln_min_cust_acct_id)+1;
            ln_batch_size        := CEIL(ln_tot_elg_customers/NVL(p_thread_count,10));
            ln_start_id          := ln_min_cust_acct_id;

               lc_filename:='OD_AR_Trade_File';

               lc_request_data :=FND_CONC_GLOBAL.request_data;

             IF lc_request_data IS NULL THEN

                ln_error_cnt := 0;

                  FOR I IN 1 .. p_thread_count

                       LOOP

                                 ln_upper_range := least(ln_start_id + ln_batch_size - 1,ln_max_cust_acct_id);
                        /*            FND_FILE.PUT_LINE(FND_FILE.LOG,'From Cust_Account_ID : ' ||ln_start_id);
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,'To Cust_Account_ID : ' ||ln_upper_range);  */

                    /* CR 785: removed p_credit_agent & lc_credit_cust_flag from the parms */
                                  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                                              'XXFIN'
                                                                              ,'XXARTRADECHILD'
                                                                              ,NULL
                                                                              ,NULL
                                                                              ,FALSE
                                                                              ,ln_start_id
                                                                              ,ln_upper_range
                                                                              ,ln_parent_request_id
                                                                              ,lc_extract_file_path
                                                                              ,lc_source_dir_path
                                                                              ,lc_aging_bucket_name
                                                                              ,I
                                                                             );

                                     COMMIT;

                                 ln_start_id     := ln_start_id + ln_batch_size ;
                                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request ID '||ln_request_id);

                                 IF ln_request_id = 0  THEN
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to submit Child request');
                                    RAISE lc_setup_exception;
                                 ELSE
                                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request ID '||ln_request_id);
                                    gtab_batch_id (i).request_id := ln_request_id;
                                 END IF;

                        END LOOP;

                       IF gtab_batch_id.COUNT > 0  THEN

                          FOR i IN gtab_batch_id.FIRST .. gtab_batch_id.LAST

                                LOOP
                                      lb_wait :=
                                      fnd_concurrent.wait_for_request (gtab_batch_id (i).request_id
                                                                       ,10
                                                                       ,NULL
                                                                       ,lc_phase
                                                                       ,lc_status
                                                                       ,lc_dev_phase
                                                                       ,lc_dev_status
                                                                       ,lc_message
                                                                       );

                                       IF lc_dev_status = 'ERROR' THEN
                                          ln_error_cnt := ln_error_cnt + 1;
                                       END IF;

                                       FND_FILE.PUT_LINE(FND_FILE.LOG, 'Child Request ID = '
                                                  || gtab_batch_id (i).request_id
                                                  || ' Status = '
                                                  || lc_dev_status
                                                 );
                                 END LOOP;
                        END IF;

                        IF ln_error_cnt > 0 THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Child Requests are Errored Out.Please, Check the Child Requests LOG for Details');
                           RAISE lc_setup_exception;
                        END IF;


                           ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                                      'XXFIN'
                                                                      ,'XXODCOMJOINFILE'
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,FALSE
                                                                      ,ln_parent_request_id
                                                                      ,lc_filename
                                                                     );
                           COMMIT;

                          lb_wait :=   fnd_concurrent.wait_for_request (
                                                                        ln_request_id
                                                                       ,10
                                                                       ,NULL
                                                                       ,lc_phase
                                                                       ,lc_status
                                                                       ,lc_dev_phase
                                                                       ,lc_dev_status
                                                                       ,lc_message
                                                                       );

                       IF lc_dev_status = 'ERROR' THEN
                          ln_error_cnt := ln_error_cnt + 1;
                       END IF;

                       FND_FILE.PUT_LINE(FND_FILE.LOG, 'Child Request ID = '
                                  || ln_request_id
                                  || ' Status = '
                                  || lc_dev_status
                                 );

                        IF ln_error_cnt > 0 THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Child Requests are Errored Out.Please, Check the Child Requests LOG for Details');
                           RAISE lc_setup_exception;
                        END IF;

             END IF;


            lc_filename:='OD_AR_Trade_File_'||ln_parent_request_id;

                   -------------------------------------------------------
                   --   Getting the Copy File Path using Translation    --
                   -------------------------------------------------------

                        BEGIN

                         SELECT XFTV.target_value5
                         INTO   lc_copy_file_path
                         FROM   xx_fin_translatedefinition XFTD
                               ,xx_fin_translatevalues XFTV
                         WHERE  XFTD.translate_id = xftv.translate_id
                         AND    XFTD.translation_name = 'XX_AR_CUST_EXT_TRADE_FILE'
                        AND     XFTD.target_field5 = 'Copy File Path'
                         AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                         AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                         AND    XFTV.enabled_flag = 'Y'
                         AND    XFTD.enabled_flag = 'Y'
                         AND    XFTV.target_value5 IS NOT NULL;


                        EXCEPTION
                        WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting copy file path from translation '|| SQLERRM);
                        RAISE lc_setup_exception;
                        END;

                   -------------------------------------------------------
                   --   Calling the Move Extract to FTP Procedure  --
                   -------------------------------------------------------

                  ln_parent_request_id := fnd_global.conc_request_id;


                  XX_MOVE_EXTRACT_TO_FTP;

                  SELECT count(*)
                  INTO ln_cnt_err_request
                  FROM fnd_concurrent_requests
                  WHERE parent_request_id = ln_parent_request_id
                  AND phase_code = 'C'
                  AND status_code = 'E';

                  IF ln_cnt_err_request <> 0 THEN

                    FND_FILE.PUT_LINE(FND_FILE.LOG,' Zipping the Extract File has Errored Out. Pls, chk the LOG for Details');
                    x_retcode := 2;

                  END IF;

   EXCEPTION

      WHEN lc_setup_exception THEN
         x_retcode := 2;

      WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in XX_AR_TRADE_FILE_EXTRACT Procedure'|| SQLERRM);
          x_retcode := 2;

 END  XX_AR_TRADE_FILE_EXTRACT;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  XX_AR_TRADE_FILE_EXTRACT_CHILD                |
-- | Description      :  This Procedure is used to Extract Customer    |
-- |                     Information and write all the details         |
-- |                     to the flat file                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 05-Oct-2009  Vinaykumar S    Initial draft version       |
-- | 1.1      15-Oct-2009  Vinaykumar S   Changes made to the code as  |
-- |                                       per subbu's comments        |
-- | 1.2      20-Oct-2009  Vinaykumar S   Changes made to the code     |
-- |                                        to improve the performance |
-- |                                                                   |
-- | 2.0      12-JUL-2010  Debra Gaudard  Changes made to the code     |
-- |                                        per CR 785 - removed       |
-- |                                        references to specific     |
-- |                                        agencies and removed the   |
-- |                                        extract of cred card custs |
-- +===================================================================+

/*  CR 785 removed p_credit_agent & p_credit_cust_flag from the parms */
PROCEDURE XX_AR_TRADE_FILE_EXTRACT_CHILD ( x_errbuf            OUT  NOCOPY    VARCHAR2
                                          ,x_retcode           OUT  NOCOPY    VARCHAR2
                                          ,p_from_cust_acct_id IN             NUMBER
                                          ,p_to_cust_acct_id   IN             NUMBER
                                          ,p_request_id        IN             NUMBER
                                          ,p_extract_file_path IN             VARCHAR2
                                          ,p_source_dir_path   IN             VARCHAR2
                                          ,p_aging_bucket_name IN             VARCHAR2
                                          ,p_file_serial_no    IN             NUMBER
                                          )

AS

-----------------------------------------------------------
-- The Cursor Selects the eligible active customers     --
-----------------------------------------------------------

/*  added " AND rat.name <> 'IMMEDIATE' AND rat.name <> 'CREDIT CARD'+ to the where clause - this will eliminate credit card customers */
CURSOR lcu_main(p_us_org_id IN NUMBER,p_ca_org_id IN NUMBER)
IS
   SELECT /*+ LEADING(HCA HCP RAT HCPA HZAS HPS HL CAR) FULL(CAR) USE_NL(HPS) USE_NL(HCPA)*/
              hca.account_number          cust_acct_no
            ,hca.cust_account_id          cust_acct_id
            ,hca.account_name             cust_acct_name
            ,hl.address1                  cust_addr_line1
            ,hl.address2                  cust_addr_line2
            ,hl.address3                  cust_addr_line3
            ,hl.address4                  cust_addr_line4
            ,hl.city                      cust_city
            ,hl.state                     cust_state
            ,hl.postal_code               cust_postal_code
       --   ,hcps.phone_area_code         cust_area_code           -- Commented for performance Date 20-Oct-09
       --   ,hcps.phone_number            cust_phone_number         -- Commented for performance Date 20-Oct-09
            ,hcpa.overall_credit_limit    cust_credit_limit
            ,rat.description              cust_payment_terms
            ,car.party_id                 party_id                    -- Added for CR 600 Date 20-Oct-09
      FROM   hz_cust_accounts hca
            ,hz_cust_acct_sites_all hzas
            ,hz_customer_profiles hcp
            ,hz_cust_profile_amts hcpa
            ,hz_cust_account_roles car
        --  ,hz_contact_points  hcps                       -- Commented for performance Date 20-Oct-09
            ,hz_party_sites  hps
            ,hz_locations hl
            ,ra_terms_tl rat
      WHERE hca.cust_account_id = hzas.cust_account_id
        AND hzas.status = 'A'
        AND hca.status = 'A'
        AND hca.cust_account_id = hcp.cust_account_id
        AND hcp.cust_account_profile_id = hcpa.cust_account_profile_id
        AND hcp.status = 'A'
        AND hcpa.site_use_id  IS NULL
        AND hcp.site_use_id IS NULL
        AND car.cust_account_id = hcp.cust_account_id
        AND car.status = 'A'
        AND car.primary_flag = 'Y'
        AND car.cust_acct_site_id IS NULL
     -- AND car.party_id = hcps.owner_table_id                  -- Commented for performance Date 20-Oct-09
     -- AND hcps.phone_line_type = 'GEN'                        -- Commented for performance Date 20-Oct-09
        AND hl.location_id = hps.location_id
        AND hzas.party_site_id = hps.party_site_id
        AND hps.identifying_address_flag = 'Y'
        AND hcp.standard_terms = rat.term_id
        AND rat.name not in ('IMMEDIATE', 'CREDIT CARD')
   --     OR   rat.name <> 'CREDIT CARD')
        AND ((hcpa.currency_code = 'USD' AND hzas.org_id = p_us_org_id)
        OR (hcpa.currency_code = 'CAD' AND  hzas.org_id = p_ca_org_id))
        AND (hca.cust_account_id BETWEEN p_from_cust_acct_id
        AND p_to_cust_acct_id);


---------------------------------
--   VARIABLE DECLARATION      --
---------------------------------

        ln_buffer                BINARY_INTEGER  := 32767;
        lt_file_handle           utl_file.file_type;
        lc_filename              VARCHAR2(4000);
        lc_source_dir_path       VARCHAR2(4000);
        lc_extract_file_path     VARCHAR2(4000);
        lc_copy_file_path        VARCHAR2(4000);
        lc_cust_area_code        VARCHAR2(10);            -- Added for CR 600 Date 20-Oct-09
        lc_cust_phone_number     VARCHAR2(40);            -- Added for CR 600 Date 20-Oct-09

        ln_cust_avg_days_topay    VARCHAR2(10);
        ln_cust_avg_days_late     VARCHAR2(10);
        ln_cust_high_credit       VARCHAR2(15);
        ln_standg_balance         NUMBER;
        ln_bucket_titletop_0      VARCHAR2(1000);
        ln_bucket_titlebottom_0   VARCHAR2(1000);
        ln_bucket_amount_0        NUMBER;
        ln_bucket_titletop_1      VARCHAR2(1000);
        ln_bucket_titlebottom_1   VARCHAR2(1000);
        ln_bucket_amount_1        NUMBER;
        ln_bucket_titletop_2      VARCHAR2(1000);
        ln_bucket_titlebottom_2   VARCHAR2(1000);
        ln_bucket_amount_2        NUMBER;
        ln_bucket_titletop_3      VARCHAR2(1000);
        ln_bucket_titlebottom_3   VARCHAR2(1000);
        ln_bucket_amount_3        NUMBER;
        ln_bucket_titletop_4      VARCHAR2(1000);
        ln_bucket_titlebottom_4   VARCHAR2(1000);
        ln_bucket_amount_4        NUMBER;
        ln_bucket_titletop_5      VARCHAR2(1000);
        ln_bucket_titlebottom_5   VARCHAR2(1000);
        ln_bucket_amount_5        NUMBER;
        ln_bucket_titletop_6      VARCHAR2(1000);
        ln_bucket_titlebottom_6   VARCHAR2(1000);
        ln_bucket_amount_6        NUMBER;
        lc_aging_bucket_name      VARCHAR2(50);
        lc_errormsg               VARCHAR2(2000);
        lc_crdtcard_cust_flag     VARCHAR2(2);
        lc_print_cust_flag        VARCHAR2(2);
        ln_cnt_crdt_cust          NUMBER := 0;
        ln_cnt_non_crdt_cust      NUMBER := 0;
        ln_total_customers        NUMBER := 0;
        lc_setup_exception        EXCEPTION;
        ln_cnt_err_request        NUMBER;
        ln_parent_request_id      NUMBER;
        ln_pay_indx               NUMBER := 1;
        ln_bulk_coll_limit        NUMBER;
        ln_us_org_id              NUMBER;
        ln_ca_org_id              NUMBER;


	TYPE ltab_ref_type IS TABLE OF lcu_main%ROWTYPE;

        ltab_ref                     ltab_ref_type;


----------------------------------------------------------------------------------
-- This Procedure is used by to calculate the aging information  using the APIs --
----------------------------------------------------------------------------------

                PROCEDURE XX_AR_CALC_AGING_BUCKETS(p_cust_acct_id  IN NUMBER)
                AS

                    BEGIN

                     ln_cust_avg_days_topay := '0';
                     ln_cust_avg_days_late  := '0';
                     ln_cust_high_credit    := '0';

                          BEGIN

                             --ln_cust_avg_days_topay   :=  iex_coll_ind.get_wtd_days_paid(null,p_cust_acct_id,null);
                               ln_cust_avg_days_topay := null;
                          EXCEPTION
                           WHEN OTHERS THEN
                             FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in validating the Avg Days to Pay Function'|| SQLERRM );
                             FND_FILE.PUT_LINE(FND_FILE.LOG,'The Cust_Account_ID : ' ||p_cust_acct_id);
                          END;

                          BEGIN

                             --ln_cust_avg_days_late    :=  iex_coll_ind.get_avg_days_late(null,p_cust_acct_id,null);
                             ln_cust_avg_days_late    := Null;

                          EXCEPTION
                           WHEN OTHERS THEN
                             FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in validating the Avg Days Late Function'|| SQLERRM );
                             FND_FILE.PUT_LINE(FND_FILE.LOG,'The Cust_Account_ID : ' ||p_cust_acct_id);
                          END;

                          BEGIN

                             --ln_cust_high_credit      :=  iex_coll_ind.get_high_credit_ytd(null,p_cust_acct_id,null);
                             ln_cust_high_credit      :=  Null;

                          EXCEPTION
                           WHEN OTHERS THEN
                             FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in validating the Cust High Credit Function'|| SQLERRM );
                             FND_FILE.PUT_LINE(FND_FILE.LOG,'The Cust_Account_ID : ' ||p_cust_acct_id);
                          END;




                          BEGIN

                                     ARP_CUSTOMER_AGING.CALC_AGING_BUCKETS(
                                                                           p_cust_acct_id,
                                                                           NULL,
                                                                           sysdate,
                                                                          'USD',
                                                                          'AGE',
                                                                           NULL,
                                                                           NULL,
                                                                           0,
                                                                           0,
                                                                           lc_aging_bucket_name,
                                                                           ln_standg_balance,
                                                                           ln_bucket_titletop_0,
                                                                           ln_bucket_titlebottom_0,
                                                                           ln_bucket_amount_0,
                                                                           ln_bucket_titletop_1,
                                                                           ln_bucket_titlebottom_1,
                                                                           ln_bucket_amount_1,
                                                                           ln_bucket_titletop_2,
                                                                           ln_bucket_titlebottom_2,
                                                                           ln_bucket_amount_2  ,
                                                                           ln_bucket_titletop_3,
                                                                           ln_bucket_titlebottom_3,
                                                                           ln_bucket_amount_3,
                                                                           ln_bucket_titletop_4,
                                                                           ln_bucket_titlebottom_4,
                                                                           ln_bucket_amount_4,
                                                                           ln_bucket_titletop_5,
                                                                           ln_bucket_titlebottom_5,
                                                                           ln_bucket_amount_5,
                                                                           ln_bucket_titletop_6,
                                                                           ln_bucket_titlebottom_6,
                                                                           ln_bucket_amount_6
                                                                          );
                            EXCEPTION
                            WHEN OTHERS THEN
                               FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in validating the Aging Buckets Function'|| SQLERRM );
                               FND_FILE.PUT_LINE(FND_FILE.LOG,'The Cust_Account_ID : ' ||p_cust_acct_id);
                            END;

                 END XX_AR_CALC_AGING_BUCKETS;

        --------------------------------------------------------------------------------
        --   This function is used to check whether the customer is a credit card Customer      --
        --------------------------------------------------------------------------------------------

        BEGIN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered into extract');

                 lc_extract_file_path := p_extract_file_path;
                 lc_source_dir_path   := p_source_dir_path;
                 lc_aging_bucket_name := p_aging_bucket_name;


                 ----------------------------------------------------------------------
                 --     Getting the Bulk Collect Limit Value from translation table  --
                 ----------------------------------------------------------------------

                   BEGIN
                 /*       FND_FILE.PUT_LINE(FND_FILE.LOG,'Getting Bulk Collect Limit'); */

                         SELECT XFTV.target_value7
                         INTO   ln_bulk_coll_limit
                         FROM   xx_fin_translatedefinition XFTD
                               ,xx_fin_translatevalues XFTV
                         WHERE  XFTD.translate_id = xftv.translate_id
                         AND    XFTD.translation_name = 'XX_AR_CUST_EXT_TRADE_FILE'
                         AND    XFTD.target_field7 = 'Bulk Collect Limit'
                         AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                         AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                         AND    XFTV.enabled_flag = 'Y'
                         AND    XFTD.enabled_flag = 'Y'
                         AND    XFTV.target_value7 IS NOT NULL;

                   EXCEPTION
                        WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting bulk collect limit from translation '|| SQLERRM);
                        ln_bulk_coll_limit := 10000;
                   END;

                 --------------------------------------------
                 --   Getting the Organization ID Values   --
                 --------------------------------------------

                    BEGIN
               /*         FND_FILE.PUT_LINE(FND_FILE.LOG,'Getting Org ID');  */

                        SELECT hou.organization_id
                        INTO  ln_us_org_id
                        FROM  hr_operating_units hou
                        WHERE hou.name = 'OU_US';


                        SELECT hou.organization_id
                        INTO  ln_ca_org_id
                        FROM  hr_operating_units hou
                        WHERE hou.name = 'OU_CA';

                   EXCEPTION
                          WHEN OTHERS THEN
                             FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in Getting Organization ID '|| SQLERRM);
                             RAISE lc_setup_exception;
                   END;

                lc_filename:='OD_AR_Trade_File_'||p_request_id||'_'||p_file_serial_no;
                lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);

              OPEN lcu_main(ln_us_org_id,ln_ca_org_id);
        /*      FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered getting Account Data'); */

                LOOP

                  FETCH lcu_main BULK COLLECT INTO ltab_ref LIMIT NVL(ln_bulk_coll_limit,10000);

              /*      FND_FILE.PUT_LINE(FND_FILE.LOG,'Getting Account Data');  */

                   IF ltab_ref.COUNT > 0 THEN

                    FOR i IN ltab_ref.FIRST..ltab_ref.LAST

                        LOOP

                                 ln_total_customers := ln_total_customers + 1;
                                 --------------------------------------------------------
                                 --     Reinitializing the amounts for every customer   --
                                 --------------------------------------------------------
                                         ln_cust_avg_days_topay:= '0';
                                         ln_cust_avg_days_late := '0';
                                         ln_cust_high_credit   := '0';
                                         ln_bucket_amount_0    := 0;
                                         ln_bucket_amount_1    := 0;
                                         ln_bucket_amount_2    := 0;
                                         ln_bucket_amount_3    := 0;
                                         ln_bucket_amount_4    := 0;
                                         ln_bucket_amount_5    := 0;
                                         ln_bucket_amount_6    := 0;


                                     -- Added for CR 600 Version 1.2 Date 20-Oct-09
                                         BEGIN
                                                       SELECT  hcps.phone_area_code
                                                               ,hcps.phone_number
                                                        INTO    lc_cust_area_code
                                                               ,lc_cust_phone_number
                                                        FROM    hz_contact_points hcps
                                                        WHERE  hcps.owner_table_id = ltab_ref(i).party_id
                                                        AND    hcps.phone_line_type = 'GEN'
                                                        AND    hcps.primary_flag = 'Y'
                                                        AND    hcps.status = 'A'
                                                        AND    ROWNUM < 2;
                                         EXCEPTION
                                                WHEN TOO_MANY_ROWS THEN
                                                     lc_cust_area_code     := NULL;
                                                     lc_cust_phone_number  := NULL;
                                                WHEN OTHERS THEN
                                                     lc_cust_area_code     := NULL;
                                                     lc_cust_phone_number  := NULL;
                                         END;

                                      --  End of changes for CR 600 Version 1.2 Date 20-Oct-09

                                                XX_AR_CALC_AGING_BUCKETS(ltab_ref(i).cust_acct_id);
                                               ln_cnt_non_crdt_cust := ln_cnt_non_crdt_cust + 1;
                                         /*       fnd_file.put_line (fnd_file.LOG, ltab_ref(i).cust_acct_id); */

                                               BEGIN

                                                   UTL_FILE.put_line
                                                     (lt_file_handle,
                                                        RPAD(NVL(TO_CHAR(ltab_ref(i).cust_acct_no),' '),15, ' ')
                                                      || RPAD(NVL(ltab_ref(i).cust_acct_name, ' '),100, ' ')
                                                      || RPAD(NVL(ltab_ref(i).cust_addr_line1, ' '),100, ' ')
                                                      || RPAD(NVL(ltab_ref(i).cust_addr_line2, ' '),100, ' ')
                                                      || RPAD(NVL(ltab_ref(i).cust_addr_line3, ' '),100, ' ')
                                                      || RPAD(NVL(ltab_ref(i).cust_addr_line4, ' '),100, ' ')
                                                      || RPAD(NVL(ltab_ref(i).cust_city, ' '),60, ' ')
                                                      || RPAD(NVL(ltab_ref(i).cust_state, ' '),2, ' ')
                                                      || RPAD(NVL(ltab_ref(i).cust_postal_code, ' '),10, ' ')
                                                      || RPAD(NVL(lc_cust_area_code, ' '),3, ' ')                    -- Added for CR 600 Date 20-Oct-09
                                                      || RPAD(NVL(lc_cust_phone_number,' '),25, ' ')                 -- Added for CR 600 Date 20-Oct-09
                                                      || RPAD(NVL(ln_cust_avg_days_topay,' '),4, ' ')
                                                      || RPAD(NVL(ln_cust_avg_days_late,' '),4, ' ')
                                                     -- || TO_CHAR (NVL (replace(ln_cust_high_credit,',','') , 0),'999999990.99')
                                                      ||RPAD (NVL (replace(ln_cust_high_credit,',',' ') , ' '),12,' ')
                                                      || TO_CHAR (NVL (ltab_ref(i).cust_credit_limit, 0),'999999990.99')
                                                      || TO_CHAR (NVL (ln_bucket_amount_0, 0),'999999990.99')
                                                      || TO_CHAR (NVL (ln_bucket_amount_1, 0),'999999990.99')
                                                      || TO_CHAR (NVL (ln_bucket_amount_2, 0),'999999990.99')
                                                      || TO_CHAR (NVL (ln_bucket_amount_3, 0),'999999990.99')
                                                      || TO_CHAR (NVL (ln_bucket_amount_4, 0),'999999990.99')
                                                      || TO_CHAR (NVL (ln_bucket_amount_5, 0),'999999990.99')
                                                      || TO_CHAR (NVL (ln_bucket_amount_6, 0),'999999990.99')
                                                      || RPAD(NVL(TO_CHAR(ltab_ref(i).cust_payment_terms), ' '),15, ' ')
                                                      || CHR(13)
                                                      );

                                                  EXCEPTION
                                                    WHEN UTL_FILE.access_denied
                                                      THEN
                                                         lc_errormsg :=
                                                            (  ' access_denied :: '
                                                             || SQLERRM
                                                             || SQLCODE
                                                            );

                                                         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                         ROLLBACK;
                                                         UTL_FILE.fclose_all;
                                                         lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                         UTL_FILE.fclose(lt_file_handle);
                                                         RAISE;

                                                      WHEN UTL_FILE.charsetmismatch
                                                      THEN
                                                         lc_errormsg :=
                                                            (  ' charsetmismatch :: '
                                                             || SQLERRM
                                                             || SQLCODE
                                                            );

                                                         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                         ROLLBACK;
                                                         UTL_FILE.fclose_all;
                                                         lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                         UTL_FILE.fclose(lt_file_handle);
                                                         RAISE;

                                                      WHEN UTL_FILE.file_open
                                                      THEN
                                                         lc_errormsg :=
                                                            (  ' file_open :: '
                                                             || SQLERRM
                                                             || SQLCODE
                                                            );

                                                         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                         ROLLBACK;
                                                         UTL_FILE.fclose_all;
                                                         lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                         UTL_FILE.fclose(lt_file_handle);
                                                         RAISE;

                                                      WHEN UTL_FILE.internal_error
                                                      THEN
                                                         lc_errormsg :=
                                                            (  ' internal_error :: '
                                                             || SQLERRM
                                                             || SQLCODE
                                                            );

                                                         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                         ROLLBACK;
                                                         UTL_FILE.fclose_all;
                                                         lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                         UTL_FILE.fclose(lt_file_handle);
                                                         RAISE;

                                                      WHEN UTL_FILE.invalid_filehandle
                                                      THEN
                                                         lc_errormsg :=
                                                            (  ' invalid_filehandle :: '
                                                             || SQLERRM
                                                             || SQLCODE
                                                            );

                                                         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                         ROLLBACK;
                                                         UTL_FILE.fclose_all;
                                                         lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                         UTL_FILE.fclose(lt_file_handle);
                                                         RAISE;

                                                      WHEN UTL_FILE.invalid_filename
                                                      THEN
                                                         lc_errormsg :=
                                                            (  ' invalid_filename :: '
                                                             || SQLERRM
                                                             || SQLCODE
                                                            );

                                                         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                         ROLLBACK;
                                                         UTL_FILE.fclose_all;
                                                         lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                         UTL_FILE.fclose(lt_file_handle);
                                                         RAISE;

                                                      WHEN UTL_FILE.invalid_maxlinesize
                                                      THEN
                                                         lc_errormsg :=
                                                            (  ' invalid_maxlinesize :: '
                                                             || SQLERRM
                                                             || SQLCODE
                                                            );

                                                         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                         ROLLBACK;
                                                         UTL_FILE.fclose_all;
                                                         lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                         UTL_FILE.fclose(lt_file_handle);
                                                         RAISE;

                                                      WHEN UTL_FILE.invalid_mode
                                                      THEN
                                                         lc_errormsg :=
                                                            (  ' invalid_mode :: '
                                                             || SQLERRM
                                                             || SQLCODE
                                                            );

                                                         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                         ROLLBACK;
                                                         UTL_FILE.fclose_all;
                                                         lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                         UTL_FILE.fclose(lt_file_handle);
                                                         RAISE;


                                                      WHEN UTL_FILE.invalid_operation
                                                      THEN
                                                         lc_errormsg :=
                                                            ( ' invalid_operation :: '
                                                             || SQLERRM
                                                             || SQLCODE
                                                            );

                                                         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                         ROLLBACK;
                                                         UTL_FILE.fclose_all;
                                                         lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                         UTL_FILE.fclose(lt_file_handle);
                                                         RAISE;

                                                      WHEN UTL_FILE.invalid_path
                                                      THEN
                                                         lc_errormsg :=
                                                            (  ' invalid_path :: '
                                                             || SQLERRM
                                                             || SQLCODE
                                                            );

                                                         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                         ROLLBACK;
                                                         UTL_FILE.fclose_all;
                                                         lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                         UTL_FILE.fclose(lt_file_handle);
                                                         RAISE;


                                                      WHEN UTL_FILE.write_error
                                                      THEN
                                                         lc_errormsg :=
                                                            (  ' write_error :: '
                                                             || SQLERRM
                                                             || SQLCODE
                                                            );

                                                         fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                         ROLLBACK;
                                                         UTL_FILE.fclose_all;
                                                         lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                         UTL_FILE.fclose(lt_file_handle);
                                                         RAISE;
                                                     WHEN OTHERS THEN
                                                     FND_FILE.PUT_LINE(FND_FILE.LOG,'The Program exited because of the following error message:' || SQLERRM);
                                                     lc_errormsg := ('  Other Errors : ' || SQLERRM || SQLCODE );
                                                     fnd_file.put_line (fnd_file.LOG, lc_errormsg);
                                                     ROLLBACK;
                                                     UTL_FILE.fclose_all;
                                                     lt_file_handle  := UTL_FILE.fopen(lc_extract_file_path,lc_filename ,'w',ln_buffer);
                                                     UTL_FILE.fclose(lt_file_handle);
                                                     RAISE;
                                                     x_retcode:=2;
                                                     x_errbuf  := lc_errormsg;
                                                    END;


                         END LOOP;
                   ELSE

                      EXIT;

                   END IF;

                END LOOP;

         CLOSE lcu_main;


          UTL_FILE.fclose (lt_file_handle);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'The Total Customers extracted - '|| ln_total_customers);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'The Total Non Credit Card Customers extracted - '|| ln_cnt_non_crdt_cust);

/* CR 785 removed display of the number of credit card customers - these customers are no longer included in the extract */
     /*     IF lc_print_cust_flag = 'Y' THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'The Total Credit Card Customers extracted - ' || ln_cnt_crdt_cust);
          ELSE
                FND_FILE.PUT_LINE(FND_FILE.LOG,'The Total Credit Card Customers extracted - 0 ' );
          END IF;
     */

	  x_errbuf := ln_total_customers;

      EXCEPTION

      WHEN lc_setup_exception THEN

         x_retcode := 2;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Setup Return Code:  '|| x_retcode);

      WHEN OTHERS THEN

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised in XX_AR_TRADE_FILE_EXTRACT_CHILD procedure '|| SQLERRM);
          x_retcode := 2;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Others Return Code:  '|| x_retcode);

    END  XX_AR_TRADE_FILE_EXTRACT_CHILD;

  END XX_AR_TRADE_FILE_PKG;

/
show error