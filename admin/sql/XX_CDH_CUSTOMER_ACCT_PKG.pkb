--SET VERIFY OFF;
--WHENEVER SQLERROR CONTINUE;
--WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_CUSTOMER_ACCT_PKG
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                 Oracle NAIO Consulting Organization                                     |
-- +=========================================================================================+
-- | Name        : XX_CDH_CUSTOMER_ACCT_PKG                                                  |
-- | Description :                                                                           |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   19-Apr-2007     Prakash Sowriraj     Initial draft version                    |
-- |Draft 1b   15-May-2007     Prakash Sowriraj     Modified to include update part          |
-- |Draft 1c   26-Jun-2007     Ambarish Mukherjee   Modified to include primary flag for site|
-- |                                                use. Also added org_id changes.          |
-- |Draft 1d   19-Jul-2007     Ambarish Mukherjee   Modified to have different programs for  |
-- |                                                Accounts, Account Sites, Acct Site Uses  |
-- |Draft 1d   27-Aug-2007     Ambarish Mukherjee   Multi-threaded for Account Site Uses     | 
-- |2.1        29-OCT-2008     Indra Varada         Modified site use OSR generation logic   | 
-- |3.1        08-MAR-2014     Arun Gannarapu       Made changes as per R12 retrofit         |
-- |                                                defect # 28030                           |
-- |4.1        05-Jan-2016     Manikant Kasu        Removed schema alias as  part of GSCC    | 
-- |                                                R12.2.2  Retrofit                        |
-- +=========================================================================================+

AS
    gn_application_id   CONSTANT NUMBER:=222;--AR Account Receivable
    gn_batch_id         NUMBER;
    
-- +===================================================================+
-- | Name        : process_accounts                                    |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: CDH Customer Account Conversion'       |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_accounts  
   (   x_errbuf       OUT     VARCHAR2
      ,x_retcode      OUT     VARCHAR2
      ,p_batch_id     IN      NUMBER
      ,p_process_yn   IN      VARCHAR2 
   )
AS
--Cursor to fecth account records from stagging table
CURSOR C_XXOD_HZ_IMP_ACCOUNTS_STG
    ( cp_batch_id   NUMBER )
IS
SELECT  *
FROM    XXOD_HZ_IMP_ACCOUNTS_STG
WHERE   batch_id = cp_batch_id
AND     interface_status IN ('1','4','6');

--Variables for CUSTOMER_ACCOUNT creation
TYPE xx_account_table           IS TABLE OF XXOD_HZ_IMP_ACCOUNTS_STG%ROWTYPE INDEX BY BINARY_INTEGER;
lc_account_table                xx_account_table;

TYPE xx_upd_record_table        IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
TYPE xx_upd_interface_table     IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;

lc_acct_record_table            xx_upd_record_table;
lc_acct_interface_table         xx_upd_interface_table;

ln_cust_acct_id                 NUMBER          := NULL;
lc_acct_return_status           VARCHAR(1)      := 'E';
ln_conversion_acct_id           NUMBER          := 00241.1;
lc_procedure_name               VARCHAR2(50)    := 'account_main';

ln_acct_rec_pro_succ            NUMBER := 0;
ln_acct_rec_pro_fail            NUMBER := 0;
lc_num_pro_rec_read             NUMBER := 0;
ln_bulk_limit                   NUMBER := XX_CDH_CONV_MASTER_PKG.g_bulk_fetch_limit;
lv_errbuf                       VARCHAR2(2000);
lv_retcode                      VARCHAR2(10);
l_cust_acct_rel_rec             XX_CDH_CUST_REL_SITE_PKG.gt_cust_acct_rel_rec_type;
le_skip_procedure               EXCEPTION; 


BEGIN
   IF p_process_yn = 'N' THEN
      RAISE le_skip_procedure;
   END IF;
   --************************** Part:1 Customer Account ****************************--
   gn_batch_id := p_batch_id;
   log_debug_msg('=====================       BEGIN       =======================');
   log_debug_msg('================ Create Customer Account Main ================='||CHR(10));
   
   log_debug_msg('Batch_id = '||gn_batch_id);
   --Main cursor to loop through each accout
   OPEN c_xxod_hz_imp_accounts_stg (  cp_batch_id => p_batch_id);
   LOOP
      FETCH c_xxod_hz_imp_accounts_stg BULK COLLECT INTO lc_account_table LIMIT ln_bulk_limit;
      lc_acct_interface_table.DELETE;
      lc_acct_record_table.DELETE;
      IF lc_account_table.COUNT < 1 THEN
         fnd_file.put_line(fnd_file.output,'No records found for the batch_id : '||gn_batch_id);
      ELSE
         --Calling Log_control_info_proc API
         FOR i IN lc_account_table.first .. lc_account_table.last
         LOOP
            lc_acct_return_status       := 'E';

            log_debug_msg(CHR(10)||'Record-id:'||lc_account_table(i).record_id);
            log_debug_msg('=====================');

            --Creating a new Customer Profile
            create_account
               (   l_hz_imp_accounts_stg  => lc_account_table(i)
                  ,x_cust_account_id      => ln_cust_acct_id
                  ,x_acct_return_status   => lc_acct_return_status
               );

            lc_acct_record_table(i) := lc_account_table(i).record_id;

            IF (lc_acct_return_status = 'S') THEN
               --Update Interface_Status
               lc_acct_interface_table(i) := '7';--SUCCESS
               ln_acct_rec_pro_succ       := ln_acct_rec_pro_succ+1;

               l_cust_acct_rel_rec        := NULL;
               IF lc_account_table(i).relate_interface_status IN ('1','4','6') AND lc_account_table(i).related_account_ref IS NOT NULL THEN
                  --Creating customer account relationships
                  l_cust_acct_rel_rec.record_id                      := lc_account_table(i).record_id;
                  l_cust_acct_rel_rec.batch_id                       := gn_batch_id;
                  l_cust_acct_rel_rec.account_orig_system            := lc_account_table(i).account_orig_system;
                  l_cust_acct_rel_rec.account_orig_system_reference  := lc_account_table(i).account_orig_system_reference;
                  l_cust_acct_rel_rec.related_account_ref            := lc_account_table(i).related_account_ref;
                  l_cust_acct_rel_rec.related_acc_ref_f_bill_to_flag := lc_account_table(i).related_acc_ref_f_bill_to_flag;
                  l_cust_acct_rel_rec.related_acc_ref_f_ship_to_flag := lc_account_table(i).related_acc_ref_f_ship_to_flag;
                  l_cust_acct_rel_rec.related_acc_ref_b_bill_to_flag := lc_account_table(i).related_acc_ref_b_bill_to_flag;
                  l_cust_acct_rel_rec.related_acc_ref_b_ship_to_flag := lc_account_table(i).related_acc_ref_b_ship_to_flag;
                  l_cust_acct_rel_rec.created_by_module              := lc_account_table(i).created_by_module;
                  l_cust_acct_rel_rec.program_application_id         := lc_account_table(i).program_application_id;

                  XX_CDH_CUST_REL_SITE_PKG.process_cust_acct_relate
                     (  x_errbuf            => lv_errbuf
                       ,x_retcode           => lv_retcode
                       ,p_cust_acct_rel_rec => l_cust_acct_rel_rec
                     );

                  IF lv_retcode = FND_API.G_RET_STS_SUCCESS THEN
                     fnd_file.put_line(fnd_file.LOG, 'Cust Account Relationship is successfully created !!!');
                  ELSE
                     fnd_file.put_line(fnd_file.LOG, 'Error while creating Cust Account Relationship');
                     fnd_file.put_line(fnd_file.LOG, 'Error - '||lv_errbuf);
                  END IF;
               END IF;
            ELSE
               --Update Interface_Status
               lc_acct_interface_table(i) := '6';--FAILED
               ln_acct_rec_pro_fail       := ln_acct_rec_pro_fail+1;
            END IF;

         END LOOP;

         --Bulk update of interface_status column
         IF lc_acct_record_table.last > 0 THEN
            FORALL i IN 1 .. lc_acct_record_table.LAST
               UPDATE xxod_hz_imp_accounts_stg
               SET    interface_status = lc_acct_interface_table(i)
               WHERE  record_id        = lc_acct_record_table(i);
         END IF;

         COMMIT;
      END IF;
      EXIT WHEN C_XXOD_HZ_IMP_ACCOUNTS_STG%NOTFOUND;
   END LOOP;
   CLOSE C_XXOD_HZ_IMP_ACCOUNTS_STG;

   IF (ln_acct_rec_pro_succ + ln_acct_rec_pro_fail) > 0 THEN
      xx_com_conv_elements_pkg.log_control_info_proc
         (   p_conversion_id            => ln_conversion_acct_id
            ,p_batch_id                 => gn_batch_id
            ,p_num_bus_objs_processed   => lc_account_table.COUNT
         );

      --No.of processed,failed,succeeded records - start
      lc_num_pro_rec_read := (ln_acct_rec_pro_succ + ln_acct_rec_pro_fail);
      log_debug_msg(CHR(10)||'-----------------------------------------------------------');
      log_debug_msg('Total no.of records read = '||lc_num_pro_rec_read);
      log_debug_msg('Total no.of records succeded = '||ln_acct_rec_pro_succ);
      log_debug_msg('Total no.of records failed = '||ln_acct_rec_pro_fail);
      log_debug_msg('-----------------------------------------------------------');

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'================ Create Customer Account Main =================');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no.of records read = '||lc_num_pro_rec_read);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no.of records succeded = '||ln_acct_rec_pro_succ);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no.of records failed = '||ln_acct_rec_pro_fail);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------------------------');

      XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
         (   p_conc_mst_req_id             => FND_GLOBAL.CONC_REQUEST_ID
            ,p_batch_id                    => gn_batch_id
            ,p_conversion_id               => ln_conversion_acct_id
            ,p_num_bus_objs_failed_valid   => 0
            ,p_num_bus_objs_failed_process => ln_acct_rec_pro_fail
            ,p_num_bus_objs_succ_process   => ln_acct_rec_pro_succ
         );
   END IF;
  
   log_debug_msg(CHR(10)||'-----------------------       END        ----------------------');
   x_retcode := 0;
EXCEPTION
   WHEN le_skip_procedure THEN
      x_retcode :='0';
      fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
   WHEN OTHERS THEN
      x_errbuf  :='Unexpected Error in process_accounts procedure '||SQLERRM;
      x_retcode :='2';
END process_accounts;

-- +===================================================================+
-- | Name        : process_account_sites                               |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: CDH Customer Account Conversion'       |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_account_sites  
   (   x_errbuf       OUT     VARCHAR2
      ,x_retcode      OUT     VARCHAR2
      ,p_batch_id     IN      NUMBER
      ,p_process_yn   IN      VARCHAR2
   )
AS
lt_conc_request_id     NUMBER;
ln_no_of_workers       NUMBER;
lv_request_data        VARCHAR2(100);
le_skip_procedure      EXCEPTION;

BEGIN
   
   IF p_process_yn = 'N' THEN
      RAISE le_skip_procedure;
   END IF;   
   
   ln_no_of_workers := fnd_profile.value('XX_CDH_CONV_WORKERS');
   
   lv_request_data := fnd_conc_global.request_data;
   
   IF lv_request_data IS NULL THEN
      
      FOR i IN 1..ln_no_of_workers
      LOOP

         lt_conc_request_id := FND_REQUEST.submit_request 
                                       (   application => 'XXCNV',
                                           program     => 'XX_CDH_ACCT_SITE_WORKER',
                                           description => i,
                                           start_time  => NULL,
                                           sub_request => TRUE, 
                                           argument1   => p_batch_id,
                                           argument2   => i
                                       );
         IF lt_conc_request_id = 0 THEN
            x_errbuf  := fnd_message.get;
            x_retcode := 2;
            fnd_file.put_line (fnd_file.log, 'Customer Account Site Worker '||i||' Program failed to submit: ' || x_errbuf);
            x_errbuf  := 'Customer Account Site Worker '||i||' Program failed to submit: ' || x_errbuf;
         ELSE
            fnd_file.put_line (fnd_file.log, ' ');
            fnd_file.put_line (fnd_file.log, 'Customer Account Site Worker '||i||' Program submitted with request id: '|| TO_CHAR( lt_conc_request_id ));
            COMMIT;
         END IF;

      END LOOP;
   
      fnd_conc_global.set_req_globals 
            (  conc_status  => 'PAUSED',
               request_data => TO_CHAR( ln_no_of_workers )
            );
   END IF;
   
   IF lv_request_data IS NOT NULL THEN --Restart of the main / parent request
      fnd_file.put_line(fnd_file.log, 'ReStart of CDH Account Site Master Program');
   END IF;

EXCEPTION
   WHEN le_skip_procedure THEN
      x_retcode := 0;
      fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
   WHEN OTHERS THEN
      log_debug_msg( 'Unexpected Error in procedure process_account_sites - '||SQLERRM);
      x_retcode := 2;
      x_errbuf  := 'Unexpected Error in procedure process_account_sites - '||SQLERRM;

END process_account_sites;


-- +===================================================================+
-- | Name        : process_account_sites_worker                        |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: CDH Customer Account Conversion'       |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_account_sites_worker  
   (   x_errbuf       OUT     VARCHAR2
      ,x_retcode      OUT     VARCHAR2
      ,p_batch_id     IN      NUMBER
      ,p_worker_id    IN      NUMBER
   )
AS

--Cursor to fecth account site records from stagging table
CURSOR C_XXOD_HZ_IMP_ACCT_SITES_STG
    ( cp_batch_id   NUMBER )
IS
SELECT  *
FROM    XXOD_HZ_IMP_ACCT_SITES_STG
WHERE   batch_id = cp_batch_id
AND     org_id   = FND_GLOBAL.org_id         -- Added by Ambarish
AND     MOD(NVL(TO_NUMBER(REGEXP_SUBSTR(account_orig_system_reference, '[123456789]{1,7}')), ASCII(account_orig_system_reference)), fnd_profile.value('XX_CDH_CONV_WORKERS')) = DECODE(p_worker_id,fnd_profile.value('XX_CDH_CONV_WORKERS'),0,p_worker_id)
--AND     MOD(ASCII(account_orig_system_reference),fnd_profile.value('XX_CDH_CONV_WORKERS')) = DECODE(p_worker_id,fnd_profile.value('XX_CDH_CONV_WORKERS'),0,p_worker_id)
AND     interface_status IN ('1','4','6');

--variables for CUSTOMER_ACCOUNT_SITE creation
TYPE xx_account_site_table      IS TABLE OF XXOD_HZ_IMP_ACCT_SITES_STG%ROWTYPE INDEX BY BINARY_INTEGER;
lc_acct_site_table              xx_account_site_table;

TYPE xx_upd_record_table        IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
TYPE xx_upd_interface_table     IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;

lc_acct_site_record_table       xx_upd_record_table;
lc_acct_site_interface_table    xx_upd_interface_table;

ln_acct_site_id                 NUMBER          := NULL;
lc_acct_site_return_status      VARCHAR(1)      := 'E';
ln_conversion_acct_site_id      NUMBER          := 00241.2;
ln_acct_site_rec_pro_succ       NUMBER          := 0;
ln_acct_site_rec_pro_fail       NUMBER          := 0;
-- Ambarish -7-Jan-08 -- Changed to have different commit size for Account Sites to take care of U1 Issue
ln_bulk_limit                   NUMBER          := fnd_profile.value('XX_CDH_CONV_SITE_COMMIT_SIZE');
--
lc_num_pro_rec_read             NUMBER          := 0;

BEGIN

   --*********************** Part:2 Customer Account Site *************************--
   gn_batch_id := p_batch_id;
   log_debug_msg(CHR(10)||'========================       BEGIN      ==========================');
   log_debug_msg('================ Create Customer Account Site Main ================='||CHR(10));

   --Main cursor to loop through each accout
   OPEN C_XXOD_HZ_IMP_ACCT_SITES_STG ( cp_batch_id => gn_batch_id);
   LOOP
      FETCH c_xxod_hz_imp_acct_sites_stg BULK COLLECT INTO lc_acct_site_table LIMIT ln_bulk_limit;
      lc_acct_site_interface_table.DELETE;
      lc_acct_site_record_table.DELETE;

      IF lc_acct_site_table.COUNT < 1 THEN
         fnd_file.put_line(fnd_file.output,'No Account Site records found for the batch_id : '||gn_batch_id);
      ELSE
         FOR i IN lc_acct_site_table.first .. lc_acct_site_table.last
         LOOP
            lc_acct_site_return_status       := 'E';

            log_debug_msg(CHR(10)||'Record-id:'||lc_acct_site_table(i).record_id);
            log_debug_msg('=====================');

            --Creating a new Customer Profile
            create_account_site
               (   l_hz_imp_acct_sites_stg    => lc_acct_site_table(i)
                  ,x_acct_site_id             => ln_acct_site_id
                  ,x_acct_site_return_status  => lc_acct_site_return_status
               );

            lc_acct_site_record_table(i) := lc_acct_site_table(i).record_id;

            IF(lc_acct_site_return_status = 'S') THEN
                --Update Interface_Status
                lc_acct_site_interface_table(i) := '7';--SUCCESS
                ln_acct_site_rec_pro_succ := ln_acct_site_rec_pro_succ+1;           
                
            ELSE
                --Update Interface_Status
                lc_acct_site_interface_table(i) := '6';--FAILED
                ln_acct_site_rec_pro_fail := ln_acct_site_rec_pro_fail+1;
            END IF;
         END LOOP;

         --Bulk update of interface_status column
         IF lc_acct_site_record_table.LAST > 0 THEN
            FORALL i IN 1 .. lc_acct_site_record_table.LAST
               UPDATE XXOD_HZ_IMP_ACCT_SITES_STG
               SET    interface_status  = lc_acct_site_interface_table(i)
               WHERE  record_id = lc_acct_site_record_table(i);
         END IF;

         COMMIT;

      END IF;
      EXIT WHEN C_XXOD_HZ_IMP_ACCT_SITES_STG%NOTFOUND;
   END LOOP;
   CLOSE C_XXOD_HZ_IMP_ACCT_SITES_STG;

   IF (ln_acct_site_rec_pro_succ + ln_acct_site_rec_pro_fail) > 0 THEN
      xx_com_conv_elements_pkg.log_control_info_proc
         (   p_conversion_id          => ln_conversion_acct_site_id
            ,p_batch_id               => gn_batch_id
            ,p_num_bus_objs_processed => lc_acct_site_table.COUNT
         );

      lc_num_pro_rec_read := (ln_acct_site_rec_pro_succ + ln_acct_site_rec_pro_fail);
      log_debug_msg(CHR(10)||'-----------------------------------------------------------');
      log_debug_msg('Total no.of records read = '||lc_num_pro_rec_read);
      log_debug_msg('Total no.of records succeded = '||ln_acct_site_rec_pro_succ);
      log_debug_msg('Total no.of records failed = '||ln_acct_site_rec_pro_fail);
      log_debug_msg('-----------------------------------------------------------');

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'================ Create Customer Account Site Main ================='||CHR(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10)||'-----------------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no.of records read = '||lc_num_pro_rec_read);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no.of records succeded = '||ln_acct_site_rec_pro_succ);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no.of records failed = '||ln_acct_site_rec_pro_fail);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------------------------');

      XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
         (   p_conc_mst_req_id              => FND_GLOBAL.CONC_REQUEST_ID
            ,p_batch_id                     => gn_batch_id
            ,p_conversion_id                => ln_conversion_acct_site_id
            ,p_num_bus_objs_failed_valid    => 0
            ,p_num_bus_objs_failed_process  => ln_acct_site_rec_pro_fail
            ,p_num_bus_objs_succ_process    => ln_acct_site_rec_pro_succ
         );
   END IF;
   log_debug_msg(CHR(10)||'-------------------------       END        -------------------------');
   x_retcode := 0;
EXCEPTION
   WHEN OTHERS THEN
      x_errbuf    := 'Unexpected Error in process_account_sites procedure '||SQLERRM;
      x_retcode   := '2';
END process_account_sites_worker;

-- +===================================================================+
-- | Name        : process_account_site_uses                           |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: CDH Customer Account Conversion'       |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_account_site_uses  
   (   x_errbuf       OUT     VARCHAR2
      ,x_retcode      OUT     VARCHAR2
      ,p_batch_id     IN      NUMBER
      ,p_process_yn   IN      VARCHAR2
   )
AS
lt_conc_request_id     NUMBER;
ln_no_of_workers       NUMBER;
le_skip_procedure      EXCEPTION;
lv_request_data        VARCHAR2(100);

BEGIN
   
   IF p_process_yn = 'N' THEN
      RAISE le_skip_procedure;
   END IF;   
   
   ln_no_of_workers := fnd_profile.value('XX_CDH_CONV_WORKERS');
   lv_request_data := fnd_conc_global.request_data;
   
   IF lv_request_data IS NULL THEN
   
      FOR i IN 1..ln_no_of_workers
      LOOP

         lt_conc_request_id := FND_REQUEST.submit_request 
                                       (   application => 'XXCNV',
                                           program     => 'XX_CDH_ACCT_SITE_USES_WORKER',
                                           description => i,
                                           start_time  => NULL,
                                           sub_request => TRUE, 
                                           argument1   => p_batch_id,
                                           argument2   => i
                                       );
         IF lt_conc_request_id = 0 THEN
            x_errbuf  := fnd_message.get;
            x_retcode := 2;
            fnd_file.put_line (fnd_file.log, 'Customer Account Site Use Worker '||i||' Program failed to submit: ' || x_errbuf);
            x_errbuf  := 'Customer Account Site Use Worker '||i||' Program failed to submit: ' || x_errbuf;
         ELSE
            fnd_file.put_line (fnd_file.log, ' ');
            fnd_file.put_line (fnd_file.log, 'Customer Account Site Use Worker '||i||' Program submitted with request id: '|| TO_CHAR( lt_conc_request_id ));
            COMMIT;
         END IF;
         
         fnd_conc_global.set_req_globals 
            (  conc_status  => 'PAUSED',
               request_data => TO_CHAR( ln_no_of_workers )
            );

      END LOOP;
   END IF;   
      
   IF lv_request_data IS NOT NULL THEN --Restart of the main / parent request
      fnd_file.put_line(fnd_file.log, 'ReStart of CDH Account Site Uses Master Program');
   END IF;

EXCEPTION
   WHEN le_skip_procedure THEN
      x_retcode := 0;
      fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
   WHEN OTHERS THEN
      log_debug_msg( 'Unexpected Error in procedure process_account_site_uses - '||SQLERRM);
      x_retcode := 2;
      x_errbuf  := 'Unexpected Error in procedure process_account_site_uses - '||SQLERRM;

END process_account_site_uses;

-- +===================================================================+
-- | Name        : process_acc_site_uses_worker                        |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: CDH Customer Account Conversion'       |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_acc_site_uses_worker  
   (   x_errbuf       OUT     VARCHAR2
      ,x_retcode      OUT     VARCHAR2
      ,p_batch_id     IN      NUMBER
      ,p_worker_id    IN      NUMBER
   )
AS
--Cursor to fecth account site uses
CURSOR C_XXOD_HZ_IMP_SITE_USES_STG
    ( cp_batch_id    NUMBER )
IS
SELECT  *
FROM    XXOD_HZ_IMP_ACCT_SITE_USES_STG
WHERE   batch_id = cp_batch_id
AND     interface_status IN ('1','4','6')
AND     org_id = FND_GLOBAL.org_id         -- Added by Ambarish
AND     MOD(NVL(TO_NUMBER(REGEXP_SUBSTR(account_orig_system_reference, '[123456789]{1,7}')), ASCII(account_orig_system_reference)), fnd_profile.value('XX_CDH_CONV_WORKERS')) = DECODE(p_worker_id,fnd_profile.value('XX_CDH_CONV_WORKERS'),0,p_worker_id)
--AND     MOD(ascii(account_orig_system_reference),fnd_profile.value('XX_CDH_CONV_WORKERS')) = DECODE(p_worker_id,fnd_profile.value('XX_CDH_CONV_WORKERS'),0,p_worker_id)
ORDER BY DECODE(site_use_code,'BILL_TO',0,1);

--variables for CUSTOMER_ACCOUNT_SITE_USE creation
TYPE xx_site_use_table          IS TABLE OF XXOD_HZ_IMP_ACCT_SITE_USES_STG%ROWTYPE INDEX BY BINARY_INTEGER;
lc_site_use_table               xx_site_use_table;

TYPE xx_upd_record_table        IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
TYPE xx_upd_interface_table     IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;

lc_site_use_record_table        xx_upd_record_table;
lc_site_use_interface_table     xx_upd_interface_table;

ln_site_use_id                 NUMBER          := NULL;
lc_site_use_return_status      VARCHAR(1)      := 'E';
ln_conversion_site_use_id      NUMBER          := 00241.3;
ln_site_use_rec_pro_succ       NUMBER := 0;
ln_site_use_rec_pro_fail       NUMBER := 0;
ln_bulk_limit                  NUMBER := XX_CDH_CONV_MASTER_PKG.g_bulk_fetch_limit;
lc_num_pro_rec_read            NUMBER := 0;
l_upd_cust_site_use_rec        XX_CDH_CUST_REL_SITE_PKG.gt_upd_cust_site_use_rec_type;
lv_errbuf                      VARCHAR2(2000);
lv_retcode                     VARCHAR2(10);


BEGIN
   gn_batch_id := p_batch_id;
   --********************* Part:3 Customer Account Site Use ***********************--
   log_debug_msg(CHR(10)||'========================     BEGIN      ========================');
   log_debug_msg('================ Create Customer Site Use Main ================='||CHR(10));
   
   --Main cursor to loop through each accout
   OPEN C_XXOD_HZ_IMP_SITE_USES_STG (   cp_batch_id => gn_batch_id);
   LOOP
      FETCH C_XXOD_HZ_IMP_SITE_USES_STG BULK COLLECT INTO lc_site_use_table LIMIT ln_bulk_limit;
      lc_site_use_record_table.DELETE;
      lc_site_use_interface_table.DELETE;
      
      IF lc_site_use_table.COUNT < 1 THEN
         fnd_file.put_line(fnd_file.output,'No records found for the batch_id : '||gn_batch_id);
      ELSE
         FOR i IN lc_site_use_table.first .. lc_site_use_table.last
         LOOP
            lc_site_use_return_status       := 'E';
   
            log_debug_msg(CHR(10)||'Record-id:'||lc_site_use_table(i).record_id);
            log_debug_msg('=====================');
   
            --Creating a new Customer Profile
            create_account_site_use
               (   l_hz_imp_acct_site_uses_stg    => lc_site_use_table(i)
                  ,x_site_use_id                  => ln_site_use_id
                  ,x_site_use_return_status       => lc_site_use_return_status
               );
            lc_site_use_record_table(i) := lc_site_use_table(i).record_id;
            l_upd_cust_site_use_rec := NULL;
            IF (lc_site_use_return_status = 'S') THEN
               --Update Interface_Status
               lc_site_use_interface_table(i) := '7';--SUCCESS
               ln_site_use_rec_pro_succ := ln_site_use_rec_pro_succ+1;

               --------------------------------------------------------
               -- Call update site use proc to update bill-to site use
               --------------------------------------------------------
               l_upd_cust_site_use_rec.record_id                    := lc_site_use_table(i).record_id;
               l_upd_cust_site_use_rec.batch_id                     := lc_site_use_table(i).batch_id;
               l_upd_cust_site_use_rec.acct_site_orig_system        := lc_site_use_table(i).acct_site_orig_system;
               l_upd_cust_site_use_rec.acct_site_orig_sys_reference := lc_site_use_table(i).acct_site_orig_sys_reference;
               l_upd_cust_site_use_rec.site_use_code                := lc_site_use_table(i).site_use_code;
               l_upd_cust_site_use_rec.bill_to_orig_system          := lc_site_use_table(i).bill_to_orig_system;
               l_upd_cust_site_use_rec.bill_to_acct_site_ref        := lc_site_use_table(i).bill_to_acct_site_ref;
   
               XX_CDH_CUST_REL_SITE_PKG.update_cust_site_use
                  (   x_errbuf                 => lv_errbuf,
                      x_retcode                => lv_retcode,
                      p_upd_cust_site_use_rec  => l_upd_cust_site_use_rec
                  );
            ELSE
               --Update Interface_Status
               lc_site_use_interface_table(i) := '6';--FAILED
               ln_site_use_rec_pro_fail := ln_site_use_rec_pro_fail+1;
            END IF;
         END LOOP;
 
         --Bulk update of interface_status column
         IF lc_site_use_record_table.last > 0 THEN
            FORALL i IN 1 .. lc_site_use_record_table.last
               UPDATE XXOD_HZ_IMP_ACCT_SITE_USES_STG
               SET    interface_status  = lc_site_use_interface_table(i)
               WHERE  record_id = lc_site_use_record_table(i);
         END IF;
   
         COMMIT;
      END IF;
      EXIT WHEN C_XXOD_HZ_IMP_SITE_USES_STG%NOTFOUND;
   END LOOP;
   CLOSE C_XXOD_HZ_IMP_SITE_USES_STG;
   
   IF (ln_site_use_rec_pro_succ + ln_site_use_rec_pro_fail) > 0 THEN
      XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc
         (   p_conversion_id            => ln_conversion_site_use_id
            ,p_batch_id                 => gn_batch_id
            ,p_num_bus_objs_processed   => lc_site_use_table.COUNT
         );
      --No.of processed,failed,succeeded records - start
      lc_num_pro_rec_read := (ln_site_use_rec_pro_succ + ln_site_use_rec_pro_fail);
      log_debug_msg(CHR(10)||'-----------------------------------------------------------');
      log_debug_msg('Total no.of records read = '||lc_num_pro_rec_read);
      log_debug_msg('Total no.of records succeded = '||ln_site_use_rec_pro_succ);
      log_debug_msg('Total no.of records failed = '||ln_site_use_rec_pro_fail);
      log_debug_msg('-----------------------------------------------------------');
   
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'================ Create Customer Site Use Main ================='||CHR(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10)||'-----------------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no.of records read = '||lc_num_pro_rec_read);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no.of records succeded = '||ln_site_use_rec_pro_succ);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no.of records failed = '||ln_site_use_rec_pro_fail);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------------------------');
      
      XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
         (   p_conc_mst_req_id              => FND_GLOBAL.CONC_REQUEST_ID
            ,p_batch_id                     => gn_batch_id
            ,p_conversion_id                => ln_conversion_site_use_id
            ,p_num_bus_objs_failed_valid    => 0
            ,p_num_bus_objs_failed_process  => ln_site_use_rec_pro_fail
            ,p_num_bus_objs_succ_process    => ln_site_use_rec_pro_succ
         );
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      x_errbuf    := 'Unexpected Error in process_account_sites procedure '||SQLERRM;
      x_retcode   := '2';
END process_acc_site_uses_worker;

-- +===================================================================+
-- | Name        : account_main                                        |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: CDH Customer Account Conversion'       |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE account_main
    (
         x_errbuf       OUT     VARCHAR2
        ,x_retcode      OUT     VARCHAR2
        ,p_batch_id     IN      NUMBER
    )
AS
BEGIN

    --DBMS_APPLICATION_INFO.set_client_info('141');
    gn_batch_id := p_batch_id;

    NULL;
END account_main;

-- +===================================================================+
-- | Name        : create_account                                      |
-- | Description : Procedure to create a new customer account          |
-- |                                                                   |
-- | Parameters  : l_hz_imp_accounts_stg                               |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_account
    (
         l_hz_imp_accounts_stg      IN      XXOD_HZ_IMP_ACCOUNTS_STG%ROWTYPE
        ,x_cust_account_id          OUT     NUMBER
        ,x_acct_return_status       OUT     VARCHAR
    )

AS

lc_party_orig_sys_ref       VARCHAR2(2000);
lc_party_orig_sys           VARCHAR2(2000);
lc_acct_orig_sys            VARCHAR2(2000);
lc_acct_orig_sys_ref        VARCHAR2(2000);
cust_account_rec_type       HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
organization_rec_type       HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
person_rec_type             HZ_PARTY_V2PUB.PERSON_REC_TYPE;
lc_return_status            VARCHAR(1);
ln_msg_count                NUMBER;
lc_msg_data                 VARCHAR2(4000);
ln_cust_account_id          NUMBER;
lc_account_number           VARCHAR2(30);
ln_party_id                 NUMBER;
lc_party_number             VARCHAR2(30);
ln_profile_id               NUMBER;
ln_party_number             NUMBER;
lc_party_type               VARCHAR2(200);

ln_conversion_acct_id       NUMBER := 00241.1;
ln_record_control_id        NUMBER;
lc_procedure_name           VARCHAR2(32) := 'create_account';
lc_staging_table_name       VARCHAR2(32) := 'XXOD_HZ_IMP_ACCOUNTS_STG';
lc_staging_column_name      VARCHAR2(32);
lc_staging_column_value     VARCHAR2(500);
lc_exception_log            VARCHAR2(2000);
lc_oracle_error_msg         VARCHAR2(2000);

lb_create_account_flag      BOOLEAN := TRUE;
lb_update_account_flag      BOOLEAN := FALSE;
ln_object_version_number    NUMBER;

l_msg_text                  VARCHAR2(4200);

--Cursor to get party_id,party_number,party_type
CURSOR LCU_CUR1
    (
        cp_party_orig_sys       IN  VARCHAR
       ,cp_party_orig_sys_ref   IN  VARCHAR
    )
IS
SELECT party_id
      ,party_number
      ,party_type
FROM   HZ_PARTIES
WHERE  party_id = ( SELECT OWNER_TABLE_ID
                    FROM   HZ_ORIG_SYS_REFERENCES
                    WHERE  orig_system           = cp_party_orig_sys
                    AND    orig_system_reference = cp_party_orig_sys_ref
                    AND    owner_table_name      = 'HZ_PARTIES'
                    AND    status                = 'A'
                  );

BEGIN

    x_acct_return_status :='E';
    ln_record_control_id                         := l_hz_imp_accounts_stg.record_id;
    lc_party_orig_sys                            := l_hz_imp_accounts_stg.party_orig_system;
    lc_party_orig_sys_ref                        := l_hz_imp_accounts_stg.party_orig_system_reference;
    lc_acct_orig_sys                             := l_hz_imp_accounts_stg.account_orig_system;
    lc_acct_orig_sys_ref                         := l_hz_imp_accounts_stg.account_orig_system_reference;

    log_debug_msg('lc_acct_orig_sys = '||lc_acct_orig_sys);
    log_debug_msg('lc_acct_orig_sys_ref = '||lc_acct_orig_sys_ref);

    IF l_hz_imp_accounts_stg.party_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_orig_system is NULL');
        lc_staging_column_name                   := 'party_orig_system';
        lc_staging_column_value                  := l_hz_imp_accounts_stg.party_orig_system;
        lc_exception_log                         := 'party_orig_system is NULL';
        lc_oracle_error_msg                      := 'party_orig_system is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_id
               ,p_record_control_id             => l_hz_imp_accounts_stg.record_id
               ,p_source_system_code            => l_hz_imp_accounts_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_accounts_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_flag := FALSE;
    END IF;

    IF l_hz_imp_accounts_stg.party_orig_system_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_orig_system_reference is NULL');
        lc_staging_column_name                   := 'party_orig_system_reference';
        lc_staging_column_value                  := l_hz_imp_accounts_stg.party_orig_system_reference;
        lc_exception_log                         := 'party_orig_system_reference is NULL ';
        lc_oracle_error_msg                      := 'party_orig_system_reference is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_id
               ,p_record_control_id             => l_hz_imp_accounts_stg.record_id
               ,p_source_system_code            => l_hz_imp_accounts_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_accounts_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_flag := FALSE;
    END IF;

    IF l_hz_imp_accounts_stg.account_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': account_orig_system is NULL');
        lc_staging_column_name                   := 'account_orig_system';
        lc_staging_column_value                  := l_hz_imp_accounts_stg.account_orig_system;
        lc_exception_log                         := 'account_orig_system is NULL';
        lc_oracle_error_msg                      := 'account_orig_system is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_id
               ,p_record_control_id             => l_hz_imp_accounts_stg.record_id
               ,p_source_system_code            => l_hz_imp_accounts_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_accounts_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_flag := FALSE;
    END IF;

    IF l_hz_imp_accounts_stg.account_orig_system_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': account_orig_system_reference is NULL');
        lc_staging_column_name                   := 'account_orig_system_reference';
        lc_staging_column_value                  := l_hz_imp_accounts_stg.account_orig_system_reference;
        lc_exception_log                         := 'account_orig_system_reference is NULL ';
        lc_oracle_error_msg                      := 'account_orig_system_reference is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_id
               ,p_record_control_id             => l_hz_imp_accounts_stg.record_id
               ,p_source_system_code            => l_hz_imp_accounts_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_accounts_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_flag := FALSE;
    END IF;

    OPEN lcu_cur1
        (
             cp_party_orig_sys          => lc_party_orig_sys
            ,cp_party_orig_sys_ref      => lc_party_orig_sys_ref
        );

    FETCH lcu_cur1 INTO ln_party_id,ln_party_number,lc_party_type;

    IF lcu_cur1%NOTFOUND THEN
        log_debug_msg(lc_procedure_name||': party does not exist');
        lc_staging_column_name                  := 'party_orig_system_reference';
        lc_staging_column_value                 := l_hz_imp_accounts_stg.party_orig_system_reference;
        lc_exception_log                        := 'Party does not exist';
        lc_oracle_error_msg                     := 'Party does not exist';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_id
               ,p_record_control_id             => l_hz_imp_accounts_stg.record_id
               ,p_source_system_code            => l_hz_imp_accounts_stg.party_orig_system
               ,p_source_system_ref             => l_hz_imp_accounts_stg.party_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );

        lb_create_account_flag := FALSE;
    END IF;

    CLOSE lcu_cur1;


    ln_cust_account_id  := is_account_exists(lc_acct_orig_sys_ref,lc_acct_orig_sys);

    IF  ln_cust_account_id IS NOT NULL AND
        ln_cust_account_id = 0 THEN

        Log_Debug_Msg(lc_procedure_name||':acct_site_orig_sys_reference returns more than one cust_account_id');
        lc_staging_column_name                  := 'account_orig_system_reference';
        lc_staging_column_value                 := l_hz_imp_accounts_stg.account_orig_system_reference;
        lc_exception_log                        := 'account_orig_system_reference returns more than one cust_account_id';
        lc_oracle_error_msg                     := 'account_orig_system_reference returns more than one cust_account_id';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_id
               ,p_record_control_id             => l_hz_imp_accounts_stg.record_id
               ,p_source_system_code            => l_hz_imp_accounts_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_accounts_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );


        lb_create_account_flag := FALSE;

    END IF;


    IF ln_cust_account_id IS NOT NULL AND
       ln_cust_account_id <> 0 THEN

        -------------------------
        -- Update customer account
        -------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': account already exists');
        log_debug_msg('-------------------------------------');
        log_debug_msg(CHR(10)||lc_procedure_name||': update the account(account_id) = '||ln_cust_account_id);
        lb_update_account_flag := TRUE;

        cust_account_rec_type.cust_account_id           := ln_cust_account_id;
        cust_account_rec_type.attribute_category        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute_category);
        cust_account_rec_type.attribute1                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute1);
        cust_account_rec_type.attribute2                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute2);
        cust_account_rec_type.attribute3                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute3);
        cust_account_rec_type.attribute4                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute4);
        cust_account_rec_type.attribute5                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute5);
        cust_account_rec_type.attribute6                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute6);
        cust_account_rec_type.attribute7                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute7);
        cust_account_rec_type.attribute8                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute8);
        cust_account_rec_type.attribute9                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute9);
        cust_account_rec_type.attribute10               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute10);
        cust_account_rec_type.attribute11               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute11);
        cust_account_rec_type.attribute12               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute12);
        cust_account_rec_type.attribute13               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute13);
        cust_account_rec_type.attribute14               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute14);
        cust_account_rec_type.attribute15               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute15);
        cust_account_rec_type.attribute16               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute16);
        cust_account_rec_type.attribute17               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute17);
        cust_account_rec_type.attribute18               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute18);
        cust_account_rec_type.attribute19               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute19);
        cust_account_rec_type.attribute20               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute20);
        cust_account_rec_type.global_attribute_category := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute_category);
        cust_account_rec_type.global_attribute1         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute1);
        cust_account_rec_type.global_attribute2         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute2);
        cust_account_rec_type.global_attribute3         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute3);
        cust_account_rec_type.global_attribute4         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute4);
        cust_account_rec_type.global_attribute5         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute5);
        cust_account_rec_type.global_attribute6         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute6);
        cust_account_rec_type.global_attribute7         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute7);
        cust_account_rec_type.global_attribute8         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute8);
        cust_account_rec_type.global_attribute9         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute9);
        cust_account_rec_type.global_attribute10        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute10);
        cust_account_rec_type.global_attribute11        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute11);
        cust_account_rec_type.global_attribute12        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute12);
        cust_account_rec_type.global_attribute13        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute13);
        cust_account_rec_type.global_attribute14        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute14);
        cust_account_rec_type.global_attribute15        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute15);
        cust_account_rec_type.global_attribute16        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute16);
        cust_account_rec_type.global_attribute17        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute17);
        cust_account_rec_type.global_attribute18        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute18);
        cust_account_rec_type.global_attribute19        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute19);
        cust_account_rec_type.global_attribute20        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute20);
        cust_account_rec_type.tax_code                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.cust_tax_code);
        cust_account_rec_type.customer_type             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_type);
        cust_account_rec_type.customer_class_code       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_class_code);
        cust_account_rec_type.ship_via                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.cust_ship_via_code);
        cust_account_rec_type.account_name              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.account_name);
        cust_account_rec_type.sales_channel_code        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.sales_channel_code);
        cust_account_rec_type.status                    := l_hz_imp_accounts_stg.customer_status; -- modified by ivarada, handling status
    ELSIF ln_cust_account_id IS NULL THEN

        -----------------------------
        -- Create customer account
        -----------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': create a new account');
        log_debug_msg('-------------------------------------');

        --cust_account_rec_type.cust_account_id       := FND_API.G_MISS_NUM;
        cust_account_rec_type.created_by_module         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.created_by_module);
        cust_account_rec_type.attribute_category        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute_category);
        cust_account_rec_type.attribute1                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute1);
        cust_account_rec_type.attribute2                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute2);
        cust_account_rec_type.attribute3                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute3);
        cust_account_rec_type.attribute4                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute4);
        cust_account_rec_type.attribute5                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute5);
        cust_account_rec_type.attribute6                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute6);
        cust_account_rec_type.attribute7                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute7);
        cust_account_rec_type.attribute8                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute8);
        cust_account_rec_type.attribute9                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute9);
        cust_account_rec_type.attribute10               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute10);
        cust_account_rec_type.attribute11               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute11);
        cust_account_rec_type.attribute12               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute12);
        cust_account_rec_type.attribute13               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute13);
        cust_account_rec_type.attribute14               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute14);
        cust_account_rec_type.attribute15               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute15);
        cust_account_rec_type.attribute16               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute16);
        cust_account_rec_type.attribute17               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute17);
        cust_account_rec_type.attribute18               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute18);
        cust_account_rec_type.attribute19               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute19);
        cust_account_rec_type.attribute20               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_attribute20);
        cust_account_rec_type.global_attribute_category := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute_category);
        cust_account_rec_type.global_attribute1         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute1);
        cust_account_rec_type.global_attribute2         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute2);
        cust_account_rec_type.global_attribute3         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute3);
        cust_account_rec_type.global_attribute4         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute4);
        cust_account_rec_type.global_attribute5         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute5);
        cust_account_rec_type.global_attribute6         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute6);
        cust_account_rec_type.global_attribute7         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute7);
        cust_account_rec_type.global_attribute8         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute8);
        cust_account_rec_type.global_attribute9         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute9);
        cust_account_rec_type.global_attribute10        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute10);
        cust_account_rec_type.global_attribute11        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute11);
        cust_account_rec_type.global_attribute12        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute12);
        cust_account_rec_type.global_attribute13        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute13);
        cust_account_rec_type.global_attribute14        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute14);
        cust_account_rec_type.global_attribute15        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute15);
        cust_account_rec_type.global_attribute16        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute16);
        cust_account_rec_type.global_attribute17        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute17);
        cust_account_rec_type.global_attribute18        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute18);
        cust_account_rec_type.global_attribute19        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute19);
        cust_account_rec_type.global_attribute20        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.global_attribute20);
        cust_account_rec_type.tax_code                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.cust_tax_code);
        cust_account_rec_type.customer_type             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_type);
        cust_account_rec_type.customer_class_code       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.customer_class_code);
        cust_account_rec_type.ship_via                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.cust_ship_via_code);
        cust_account_rec_type.account_name              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.account_name);
        cust_account_rec_type.sales_channel_code        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_accounts_stg.sales_channel_code);

        -- If orig_system_reference is not null then API will create a new record in HZ_ORIG_SYS_REFERENCES
        --orig_system+orig_system_reference+owner_table_name must be unique in HZ_ORIG_SYS_REFERENCES table
        cust_account_rec_type.orig_system_reference     := lc_acct_orig_sys_ref;
        cust_account_rec_type.orig_system               := lc_acct_orig_sys;
        cust_account_rec_type.status                    := l_hz_imp_accounts_stg.customer_status;
        cust_account_rec_type.application_id            := gn_application_id;

    END IF;

    IF lb_create_account_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||':Cannot create/update account - Error Occurred');
        RETURN;
    END IF;

    ------------------------------
    -- Updating customer account
    ------------------------------

    IF lb_update_account_flag = TRUE THEN

        -----------------------------
        -- Get Object Version Number
        -----------------------------

        BEGIN

            ln_object_version_number := NULL;

            SELECT object_version_number
            INTO   ln_object_version_number
            FROM   hz_cust_accounts
            WHERE  cust_account_id =  ln_cust_account_id;

        EXCEPTION
           WHEN OTHERS THEN
            log_debug_msg(lc_procedure_name||': Error while fetching object_version_number for cust_account_id - '||ln_cust_account_id);
            log_debug_msg(lc_procedure_name||': Error - '||SQLERRM);
            lc_staging_column_name                  := 'account_orig_system_reference';
            lc_staging_column_value                 := l_hz_imp_accounts_stg.account_orig_system_reference;
            lc_exception_log                        := 'Error while fetching object_version_number for cust_account_role_id - '||ln_cust_account_id;
            lc_oracle_error_msg                     := 'Error while fetching object_version_number for cust_account_role_id - '||ln_cust_account_id;
            log_exception
                (
                    p_conversion_id                 => ln_conversion_acct_id
                   ,p_record_control_id             => l_hz_imp_accounts_stg.record_id
                   ,p_source_system_code            => l_hz_imp_accounts_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_accounts_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => lc_staging_column_value
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
            );

            RETURN;
        END;


        HZ_CUST_ACCOUNT_V2PUB.update_cust_account
            (
                p_init_msg_list          => FND_API.G_TRUE,
                p_cust_account_rec       => cust_account_rec_type,
                p_object_version_number  => ln_object_version_number,
                x_return_status          => lc_return_status,
                x_msg_count              => ln_msg_count,
                x_msg_data               => lc_msg_data
            );
            
        x_cust_account_id          := ln_cust_account_id;
        x_acct_return_status       := lc_return_status;

        log_debug_msg(CHR(10)||'=====================================');
        log_debug_msg('After calling update_cust_account API');
        log_debug_msg('======================================');
        log_debug_msg('ln_object_version_number = '||ln_object_version_number);
        log_debug_msg('x_acct_return_status = '||x_acct_return_status);

        IF(x_acct_return_status = 'S') THEN
            log_debug_msg(CHR(10)||'Customer Account is successfully updated !!!');
        ELSE
            log_debug_msg(CHR(10)||'Customer Account is not updated !!!');
            IF ln_msg_count >= 1 THEN
                log_debug_msg(CHR(10)||lc_procedure_name||': Errors in updating Customer Account');
                log_debug_msg('------------------------------------------------------------');
                FOR I IN 1..ln_msg_count
                LOOP
                    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(I, FND_API.G_FALSE); 
                    Log_Debug_Msg('Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE)); 
                END LOOP;
                log_debug_msg('------------------------------------------------------------'||CHR(10));
            END IF;

            log_exception
                (
                    p_conversion_id                 => ln_conversion_acct_id
                   ,p_record_control_id             => l_hz_imp_accounts_stg.record_id
                   ,p_source_system_code            => l_hz_imp_accounts_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_accounts_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => 'RECORD_ID'
                   ,p_staging_column_value          => l_hz_imp_accounts_stg.record_id
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => XX_CDH_CONV_MASTER_PKG.trim_input_msg(l_msg_text) 
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        END IF;

    ELSE
        ---------------------------------------------
        -- Creating customer account for Organization
        ---------------------------------------------
        IF lc_party_type IS NOT NULL AND lc_party_type = 'ORGANIZATION' THEN

            organization_rec_type.created_by_module := cust_account_rec_type.created_by_module;
            organization_rec_type.application_id := gn_application_id;
            organization_rec_type.party_rec.party_id    := ln_party_id;
            organization_rec_type.party_rec.party_number:= ln_party_number;

            log_debug_msg(CHR(10)||'============================================');
            log_debug_msg('Key attribute values of organization record');
            log_debug_msg('============================================');
            log_debug_msg('party_id = '||organization_rec_type.party_rec.party_id);
            log_debug_msg('party_number = '||organization_rec_type.party_rec.party_number);
            log_debug_msg('organization_type = '||organization_rec_type.organization_type);

            HZ_CUST_ACCOUNT_V2PUB.create_cust_account
                (
                    p_init_msg_list        => FND_API.G_TRUE,
                    p_cust_account_rec     => cust_account_rec_type,
                    p_organization_rec     => organization_rec_type,
                    p_customer_profile_rec => NULL,
                    p_create_profile_amt   => FND_API.G_FALSE,
                    x_cust_account_id      => ln_cust_account_id,
                    x_account_number       => lc_account_number,
                    x_party_id             => ln_party_id,
                    x_party_number         => lc_party_number,
                    x_profile_id           => ln_profile_id,
                    x_return_status        => lc_return_status,
                    x_msg_count            => ln_msg_count,
                    x_msg_data             => lc_msg_data
                );

            x_cust_account_id          := ln_cust_account_id;
            x_acct_return_status       := lc_return_status;
        END IF;

        ---------------------------------------
        -- Creating customer account for Person
        ---------------------------------------
        IF lc_party_type IS NOT NULL AND lc_party_type = 'PERSON' THEN

            person_rec_type.created_by_module       := cust_account_rec_type.created_by_module;
            person_rec_type.application_id          := gn_application_id;
            person_rec_type.party_rec.party_id      := ln_party_id;
            person_rec_type.party_rec.party_number  := ln_party_number;

            log_debug_msg(CHR(10)||'=====================================');
            log_debug_msg('Key attribute values of person record');
            log_debug_msg('=====================================');
            log_debug_msg('party_id = '||person_rec_type.party_rec.party_id);
            log_debug_msg('party_number = '||person_rec_type.party_rec.party_number);

            HZ_CUST_ACCOUNT_V2PUB.create_cust_account
                (
                    p_init_msg_list        => FND_API.G_TRUE,
                    p_cust_account_rec     => cust_account_rec_type,
                    p_person_rec           => person_rec_type,
                    p_customer_profile_rec => NULL,
                    p_create_profile_amt   => FND_API.G_FALSE,
                    x_cust_account_id      => ln_cust_account_id,
                    x_account_number       => lc_account_number,
                    x_party_id             => ln_party_id,
                    x_party_number         => lc_party_number,
                    x_profile_id           => ln_profile_id,
                    x_return_status        => lc_return_status,
                    x_msg_count            => ln_msg_count,
                    x_msg_data             => lc_msg_data
                );

            x_cust_account_id          := ln_cust_account_id;
            x_acct_return_status       := lc_return_status;

        END IF;

        log_debug_msg(CHR(10)||'=====================================');
        log_debug_msg('After calling create_cust_account API');
        log_debug_msg('======================================');
        log_debug_msg('x_cust_account_id = '||x_cust_account_id);
        log_debug_msg('x_acct_return_status = '||x_acct_return_status);

        IF(x_acct_return_status = 'S') THEN
            log_debug_msg(CHR(10)||'Customer Account is successfully created !!!');
        ELSE
            log_debug_msg(CHR(10)||'Customer Account is not created !!!');
            IF ln_msg_count >= 1 THEN
                log_debug_msg(CHR(10)||lc_procedure_name||': Errors in creating Customer Account');
                log_debug_msg('------------------------------------------------------------');
                FOR I IN 1..ln_msg_count
                LOOP
                   l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(I, FND_API.G_FALSE); 
                   Log_Debug_Msg('Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE)); 
                END LOOP;
                log_debug_msg('------------------------------------------------------------'||CHR(10));
            END IF;
            log_exception
                (
                    p_conversion_id                 => ln_conversion_acct_id
                   ,p_record_control_id             => l_hz_imp_accounts_stg.record_id
                   ,p_source_system_code            => l_hz_imp_accounts_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_accounts_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => 'RECORD_ID'
                   ,p_staging_column_value          => l_hz_imp_accounts_stg.record_id
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => XX_CDH_CONV_MASTER_PKG.trim_input_msg(l_msg_text) 
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        END IF;
    END IF;
END create_account;


-- +===================================================================+
-- | Name        : create_account_site                                 |
-- | Description : Procedure to create a new customer account site     |
-- |                                                                   |
-- | Parameters  : l_hz_imp_acct_sites_stg,p_cust_account_id           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_account_site
    (
         l_hz_imp_acct_sites_stg        IN      XXOD_HZ_IMP_ACCT_SITES_STG%ROWTYPE
        ,x_acct_site_id                 OUT     NUMBER
        ,x_acct_site_return_status      OUT     VARCHAR
    )
AS

cust_acct_site_rec_type         HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
lc_return_status                VARCHAR(1);
ln_msg_count                    NUMBER;
lc_msg_data                     VARCHAR2(4000);
ln_cust_account_id              NUMBER;
ln_cust_acct_site_id            NUMBER;
ln_party_id                     NUMBER;
lc_party_number                 VARCHAR2(30);
ln_profile_id                   NUMBER;
ln_party_site_id                NUMBER;
ln_conversion_acct_site_id      NUMBER := 00241.2;
ln_record_control_id            NUMBER;
lc_procedure_name               VARCHAR2(32) := 'create_account_site';
lc_staging_table_name           VARCHAR2(32) := 'XXOD_HZ_IMP_ACCT_SITES_STG';
lc_staging_column_name          VARCHAR2(32);
lc_staging_column_value         VARCHAR2(500);
lc_exception_log                VARCHAR2(2000);
lc_oracle_error_msg             VARCHAR2(2000);
lc_party_orig_system            VARCHAR2(200)   := l_hz_imp_acct_sites_stg.party_orig_system;
lc_acct_orig_system             VARCHAR2(200)   := l_hz_imp_acct_sites_stg.account_orig_system;
lc_site_orig_system             VARCHAR2(200)   := l_hz_imp_acct_sites_stg.acct_site_orig_system;
lc_acct_orig_sys_ref            VARCHAR2(200)   := l_hz_imp_acct_sites_stg.account_orig_system_reference;
lc_site_orig_sys_ref            VARCHAR2(2000)  := l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference;
lc_party_site_orig_system       VARCHAR2(200)   := l_hz_imp_acct_sites_stg.party_site_orig_system;
lc_party_site_orig_sys_ref      VARCHAR2(200)   := l_hz_imp_acct_sites_stg.party_site_orig_sys_reference;
ln_owner_table_id               NUMBER;
ln_retcode                      NUMBER;
ln_errbuf                       VARCHAR2(2000);

lb_create_account_site_flag     BOOLEAN := TRUE;
lb_update_acct_site_flag        BOOLEAN := FALSE;

ln_object_version_number        NUMBER;
l_msg_text                      VARCHAR2(4200);

--Cursor to get party_site_id
CURSOR LCU_CUR1
    (
        cp_orig_sys           IN  VARCHAR
       ,cp_site_orig_sys_ref  IN  VARCHAR
    )
IS
SELECT  owner_table_id
FROM    hz_orig_sys_references
WHERE   orig_system = cp_orig_sys
AND     orig_system_reference = cp_site_orig_sys_ref
AND     owner_table_name = 'HZ_PARTY_SITES'
AND     status ='A';

BEGIN
    x_acct_site_return_status       := 'E';
    ln_record_control_id            := l_hz_imp_acct_sites_stg.record_id;

    Log_Debug_Msg('lc_site_orig_system  = '||lc_site_orig_system);
    Log_Debug_Msg('lc_site_orig_sys_ref = '||lc_site_orig_sys_ref);

    IF l_hz_imp_acct_sites_stg.party_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_orig_system is NULL');
        lc_staging_column_name                   := 'party_orig_system';
        lc_staging_column_value                  := l_hz_imp_acct_sites_stg.party_orig_system;
        lc_exception_log                         := 'party_orig_system is NULL';
        lc_oracle_error_msg                      := 'party_orig_system is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_site_id
               ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_sites_stg.party_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_sites_stg.party_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_site_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_sites_stg.party_orig_system_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_orig_system_reference is NULL');
        lc_staging_column_name                   := 'party_orig_system_reference';
        lc_staging_column_value                  := l_hz_imp_acct_sites_stg.party_orig_system_reference;
        lc_exception_log                         := 'party_orig_system_reference is NULL ';
        lc_oracle_error_msg                      := 'party_orig_system_reference is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_site_id
               ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_sites_stg.party_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_sites_stg.party_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_site_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_sites_stg.account_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': account_orig_system is NULL');
        lc_staging_column_name                   := 'account_orig_system';
        lc_staging_column_value                  := l_hz_imp_acct_sites_stg.account_orig_system;
        lc_exception_log                         := 'account_orig_system is NULL';
        lc_oracle_error_msg                      := 'account_orig_system is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_site_id
               ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_sites_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_sites_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_site_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_sites_stg.account_orig_system_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': account_orig_system_reference is NULL');
        lc_staging_column_name                   := 'account_orig_system_reference';
        lc_staging_column_value                  := l_hz_imp_acct_sites_stg.account_orig_system_reference;
        lc_exception_log                         := 'account_orig_system_reference is NULL ';
        lc_oracle_error_msg                      := 'account_orig_system_reference is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_site_id
               ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_sites_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_sites_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_site_flag := FALSE;
    END IF;


    IF l_hz_imp_acct_sites_stg.party_site_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_site_orig_system is NULL');
        lc_staging_column_name                   := 'party_site_orig_system';
        lc_staging_column_value                  := l_hz_imp_acct_sites_stg.party_site_orig_system;
        lc_exception_log                         := 'party_site_orig_system is NULL';
        lc_oracle_error_msg                      := 'party_site_orig_system is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_site_id
               ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_sites_stg.party_site_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_sites_stg.party_site_orig_sys_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_site_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_sites_stg.party_site_orig_sys_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_site_orig_sys_reference is NULL');
        lc_staging_column_name                   := 'party_site_orig_sys_reference';
        lc_staging_column_value                  := l_hz_imp_acct_sites_stg.party_site_orig_sys_reference;
        lc_exception_log                         := 'party_site_orig_sys_reference is NULL ';
        lc_oracle_error_msg                      := 'party_site_orig_sys_reference is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_site_id
               ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_sites_stg.party_site_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_sites_stg.party_site_orig_sys_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_site_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_sites_stg.acct_site_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': acct_site_orig_system is NULL');
        lc_staging_column_name                   := 'acct_site_orig_system';
        lc_staging_column_value                  := l_hz_imp_acct_sites_stg.acct_site_orig_system;
        lc_exception_log                         := 'acct_site_orig_system is NULL';
        lc_oracle_error_msg                      := 'acct_site_orig_system is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_site_id
               ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_sites_stg.acct_site_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_site_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': acct_site_orig_sys_reference is NULL');
        lc_staging_column_name                   := 'acct_site_orig_sys_reference';
        lc_staging_column_value                  := l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference;
        lc_exception_log                         := 'acct_site_orig_sys_reference is NULL ';
        lc_oracle_error_msg                      := 'acct_site_orig_sys_reference is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_site_id
               ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_sites_stg.acct_site_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_site_flag := FALSE;
    END IF;


    XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
        (
             p_orig_system         => l_hz_imp_acct_sites_stg.account_orig_system
            ,p_orig_sys_reference  => l_hz_imp_acct_sites_stg.account_orig_system_reference
            ,p_owner_table_name    => 'HZ_CUST_ACCOUNTS'
            ,x_owner_table_id      => ln_owner_table_id
            ,x_retcode             => ln_retcode
            ,x_errbuf              => ln_errbuf
        );

    IF ln_owner_table_id IS NULL THEN
        log_debug_msg(lc_procedure_name||': account_id is not found');
        lc_staging_column_name                  := 'account_orig_system_reference';
        lc_staging_column_value                 := cust_acct_site_rec_type.cust_account_id;
        lc_exception_log                        := 'cust_account_id is not found';
        lc_oracle_error_msg                     := 'cust_account_id is not found';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_site_id
               ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_sites_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_sites_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_site_flag := FALSE;
    END IF;
    ln_cust_account_id   := ln_owner_table_id;

    --Cursor to retrieve party_site_id
    OPEN LCU_CUR1
        (
             cp_orig_sys                => lc_party_site_orig_system
            ,cp_site_orig_sys_ref       => lc_party_site_orig_sys_ref
        );

    FETCH LCU_CUR1 INTO ln_party_site_id;

    IF LCU_CUR1%NOTFOUND THEN
        Log_Debug_Msg(lc_procedure_name||':Party Site Info not found in HZ_ORIG_SYS_REFERENCES table');
        Log_Debug_Msg('Log error message cannot create account site');
        lc_staging_column_name                  := 'acct_site_orig_sys_reference';
        lc_staging_column_value                 := l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference;
        lc_exception_log                        := 'party site information is not found';
        lc_oracle_error_msg                     := 'party site information is not found';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_site_id
               ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
               ,p_source_system_code            => NULL
               ,p_source_system_ref             => l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => NULL
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_account_site_flag := FALSE;
    END IF;
    CLOSE LCU_CUR1;

    ln_cust_acct_site_id            := is_acct_site_exists(lc_site_orig_sys_ref,lc_site_orig_system);
    
    IF  ln_cust_acct_site_id IS NOT NULL AND
        ln_cust_acct_site_id = 0 THEN

        Log_Debug_Msg(lc_procedure_name||':acct_site_orig_sys_reference returns more than one cust_acct_site_id');
        lc_staging_column_name                  := 'acct_site_orig_sys_reference';
        lc_staging_column_value                 := l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference;
        lc_exception_log                        := 'acct_site_orig_sys_reference returns more than one cust_acct_site_id';
        lc_oracle_error_msg                     := 'acct_site_orig_sys_reference returns more than one cust_acct_site_id';
        log_exception
            (
                p_conversion_id                 => ln_conversion_acct_site_id
               ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_sites_stg.acct_site_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );


        lb_create_account_site_flag := FALSE;

    END IF;


    IF  ln_cust_acct_site_id IS NOT NULL AND
        ln_cust_acct_site_id <> 0 THEN

        ---------------------------
        -- Update account site
        ---------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': account site already exists');
        log_debug_msg('---------------------------');
        log_debug_msg(CHR(10)||lc_procedure_name||': update the account site (account_site_id) = '||ln_cust_acct_site_id);
        lb_update_acct_site_flag := TRUE;

        cust_acct_site_rec_type.cust_acct_site_id         := ln_cust_acct_site_id;
        cust_acct_site_rec_type.cust_account_id           := ln_cust_account_id;
        cust_acct_site_rec_type.party_site_id             := ln_party_site_id;
        cust_acct_site_rec_type.attribute_category        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute_category);
        cust_acct_site_rec_type.attribute1                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute1);
        cust_acct_site_rec_type.attribute2                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute2);
        cust_acct_site_rec_type.attribute3                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute3);
        cust_acct_site_rec_type.attribute4                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute4);
        cust_acct_site_rec_type.attribute5                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute5);
        cust_acct_site_rec_type.attribute6                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute6);
        cust_acct_site_rec_type.attribute7                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute7);
        cust_acct_site_rec_type.attribute8                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute8);
        cust_acct_site_rec_type.attribute9                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute9);
        cust_acct_site_rec_type.attribute10               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute10);
        cust_acct_site_rec_type.attribute11               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute11);
        cust_acct_site_rec_type.attribute12               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute12);
        cust_acct_site_rec_type.attribute13               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute13);
        cust_acct_site_rec_type.attribute14               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute14);
        cust_acct_site_rec_type.attribute15               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute15);
        cust_acct_site_rec_type.attribute16               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute16);
        cust_acct_site_rec_type.attribute17               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute17);
        cust_acct_site_rec_type.attribute18               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute18);
        cust_acct_site_rec_type.attribute19               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute19);
        cust_acct_site_rec_type.attribute20               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute20);
        cust_acct_site_rec_type.global_attribute_category := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attr_cat);
        cust_acct_site_rec_type.global_attribute1         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute1);
        cust_acct_site_rec_type.global_attribute2         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute2);
        cust_acct_site_rec_type.global_attribute3         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute3);
        cust_acct_site_rec_type.global_attribute4         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute4);
        cust_acct_site_rec_type.global_attribute5         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute5);
        cust_acct_site_rec_type.global_attribute6         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute6);
        cust_acct_site_rec_type.global_attribute7         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute7);
        cust_acct_site_rec_type.global_attribute8         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute8);
        cust_acct_site_rec_type.global_attribute9         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute9);
        cust_acct_site_rec_type.global_attribute10        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute10);
        cust_acct_site_rec_type.global_attribute11        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute11);
        cust_acct_site_rec_type.global_attribute12        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute12);
        cust_acct_site_rec_type.global_attribute13        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute13);
        cust_acct_site_rec_type.global_attribute14        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute14);
        cust_acct_site_rec_type.global_attribute15        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute15);
        cust_acct_site_rec_type.global_attribute16        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute16);
        cust_acct_site_rec_type.global_attribute17        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute17);
        cust_acct_site_rec_type.global_attribute18        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute18);
        cust_acct_site_rec_type.global_attribute19        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute19);
        cust_acct_site_rec_type.global_attribute20        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute20);
        cust_acct_site_rec_type.status                    := 'A'; -- modified by ivarada, hardcoding status to 'A'
 
    ELSIF ln_cust_acct_site_id IS NULL THEN

        ----------------------------
        -- Create account site
        ----------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': create a new account site');
        log_debug_msg('-------------------------');

        --cust_acct_site_rec_type.cust_acct_site_id       := FND_API.G_MISS_NUM;
        cust_acct_site_rec_type.cust_account_id           := ln_cust_account_id;
        cust_acct_site_rec_type.party_site_id             := ln_party_site_id;
        cust_acct_site_rec_type.attribute_category        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute_category);
        cust_acct_site_rec_type.attribute1                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute1);
        cust_acct_site_rec_type.attribute2                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute2);
        cust_acct_site_rec_type.attribute3                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute3);
        cust_acct_site_rec_type.attribute4                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute4);
        cust_acct_site_rec_type.attribute5                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute5);
        cust_acct_site_rec_type.attribute6                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute6);
        cust_acct_site_rec_type.attribute7                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute7);
        cust_acct_site_rec_type.attribute8                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute8);
        cust_acct_site_rec_type.attribute9                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute9);
        cust_acct_site_rec_type.attribute10               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute10);
        cust_acct_site_rec_type.attribute11               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute11);
        cust_acct_site_rec_type.attribute12               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute12);
        cust_acct_site_rec_type.attribute13               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute13);
        cust_acct_site_rec_type.attribute14               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute14);
        cust_acct_site_rec_type.attribute15               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute15);
        cust_acct_site_rec_type.attribute16               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute16);
        cust_acct_site_rec_type.attribute17               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute17);
        cust_acct_site_rec_type.attribute18               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute18);
        cust_acct_site_rec_type.attribute19               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute19);
        cust_acct_site_rec_type.attribute20               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.address_attribute20);
        cust_acct_site_rec_type.global_attribute_category := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attr_cat);
        cust_acct_site_rec_type.global_attribute1         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute1);
        cust_acct_site_rec_type.global_attribute2         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute2);
        cust_acct_site_rec_type.global_attribute3         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute3);
        cust_acct_site_rec_type.global_attribute4         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute4);
        cust_acct_site_rec_type.global_attribute5         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute5);
        cust_acct_site_rec_type.global_attribute6         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute6);
        cust_acct_site_rec_type.global_attribute7         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute7);
        cust_acct_site_rec_type.global_attribute8         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute8);
        cust_acct_site_rec_type.global_attribute9         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute9);
        cust_acct_site_rec_type.global_attribute10        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute10);
        cust_acct_site_rec_type.global_attribute11        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute11);
        cust_acct_site_rec_type.global_attribute12        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute12);
        cust_acct_site_rec_type.global_attribute13        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute13);
        cust_acct_site_rec_type.global_attribute14        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute14);
        cust_acct_site_rec_type.global_attribute15        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute15);
        cust_acct_site_rec_type.global_attribute16        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute16);
        cust_acct_site_rec_type.global_attribute17        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute17);
        cust_acct_site_rec_type.global_attribute18        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute18);
        cust_acct_site_rec_type.global_attribute19        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute19);
        cust_acct_site_rec_type.global_attribute20        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_sites_stg.gdf_address_attribute20);
        cust_acct_site_rec_type.orig_system_reference     := l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference;
        cust_acct_site_rec_type.orig_system               := lc_site_orig_system;

        --cust_acct_site_rec_type.status                  := FND_API.G_MISS_CHAR;
        --cust_acct_site_rec_type.customer_category_code  := FND_API.G_MISS_CHAR;
        --cust_acct_site_rec_type.LANGUAGE                := FND_API.G_MISS_CHAR;
        --cust_acct_site_rec_type.key_account_flag        := FND_API.G_MISS_CHAR;
        --cust_acct_site_rec_type.tp_header_id            := FND_API.G_MISS_NUM;
        --cust_acct_site_rec_type.ece_tp_location_code    := FND_API.G_MISS_CHAR;
        --cust_acct_site_rec_type.primary_specialist_id   := FND_API.G_MISS_NUM;
        --cust_acct_site_rec_type.secondary_specialist_id := FND_API.G_MISS_NUM;
        --cust_acct_site_rec_type.territory_id            := FND_API.G_MISS_NUM;
        --cust_acct_site_rec_type.territory               := FND_API.G_MISS_CHAR;
        --cust_acct_site_rec_type.translated_customer_name:= FND_API.G_MISS_CHAR;

        cust_acct_site_rec_type.created_by_module       := l_hz_imp_acct_sites_stg.created_by_module;
        cust_acct_site_rec_type.application_id          := gn_application_id;

    END IF;


    IF lb_create_account_site_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||':Cannot create/update account site - Error occurred');
        RETURN;
    END IF;

    Log_Debug_Msg(CHR(10)||'===============================================');
    Log_Debug_Msg('Key attribute values of customer account site record');
    Log_Debug_Msg('===============================================');
    Log_Debug_Msg('cust_account_id = '||cust_acct_site_rec_type.cust_account_id);
    Log_Debug_Msg('party_site_id = '||cust_acct_site_rec_type.party_site_id);


    IF lb_update_acct_site_flag = TRUE THEN

        ---------------------------------------
        -- Updating the existing account site
        --------------------------------------

        -----------------------------
        -- Get Object Version Number
        -----------------------------

        BEGIN

            ln_object_version_number := NULL;

            SELECT  object_version_number,
                    cust_acct_site_id
            INTO    ln_object_version_number,
                    cust_acct_site_rec_type.cust_acct_site_id
            FROM    hz_cust_acct_sites_all
            WHERE   cust_acct_site_id =  ln_cust_acct_site_id;

        EXCEPTION
           WHEN OTHERS THEN
            log_debug_msg(lc_procedure_name||': Error while fetching object_version_number for cust_acct_site_id - '||ln_cust_acct_site_id);
            log_debug_msg(lc_procedure_name||': Error - '||SQLERRM);
            lc_staging_column_name                  := 'account_orig_system_reference';
            lc_staging_column_value                 := l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference;
            lc_exception_log                        := 'Error while fetching object_version_number for cust_acct_site_id - '||ln_cust_acct_site_id;
            lc_oracle_error_msg                     := 'Error while fetching object_version_number for cust_acct_site_id - '||ln_cust_acct_site_id;
            log_exception
                (
                    p_conversion_id                 => ln_conversion_acct_site_id
                   ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_sites_stg.acct_site_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => lc_staging_column_value
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
            );

            RETURN;
        END;


        hz_cust_account_site_v2pub.update_cust_acct_site
            (
                p_init_msg_list             => FND_API.G_TRUE,
                p_cust_acct_site_rec        => cust_acct_site_rec_type,
                p_object_version_number     => ln_object_version_number,
                x_return_status             => lc_return_status,
                x_msg_count                 => ln_msg_count,
                x_msg_data                  => lc_msg_data
            );

        x_acct_site_id              := ln_cust_acct_site_id;
        x_acct_site_return_status   := lc_return_status;

        Log_Debug_Msg(CHR(10)||'==============================================');
        Log_Debug_Msg('Output After calling update_cust_acct_site API');
        Log_Debug_Msg('==============================================');

        Log_Debug_Msg('ln_object_version_number  = '||ln_object_version_number);
        Log_Debug_Msg('x_acct_site_return_status = '||x_acct_site_return_status);

        IF (x_acct_site_return_status = 'S') THEN
            log_debug_msg(CHR(10)||'Customer Account Site is successfully updated !!!');
        ELSE
            log_debug_msg(CHR(10)||'Customer Account Site is not updated !!!');
            IF ln_msg_count >= 1 THEN
                log_debug_msg(CHR(10)||lc_procedure_name||': Errors in updating Customer Account Site');
                log_debug_msg('------------------------------------------------------------');
                FOR I IN 1..ln_msg_count
                LOOP
                    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE); 
                    Log_Debug_Msg('Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE)); 
                END LOOP;
                log_debug_msg('------------------------------------------------------------'||CHR(10));
            END IF;        
        
            log_exception
               (   p_conversion_id                 => ln_conversion_acct_site_id
                  ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
                  ,p_source_system_code            => l_hz_imp_acct_sites_stg.acct_site_orig_system
                  ,p_source_system_ref             => l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference
                  ,p_procedure_name                => lc_procedure_name
                  ,p_staging_table_name            => lc_staging_table_name
                  ,p_staging_column_name           => 'RECORD_ID'
                  ,p_staging_column_value          => l_hz_imp_acct_sites_stg.record_id
                  ,p_batch_id                      => gn_batch_id
                  ,p_exception_log                 => XX_CDH_CONV_MASTER_PKG.trim_input_msg(l_msg_text) 
                  ,p_oracle_error_code             => SQLCODE
                  ,p_oracle_error_msg              => lc_oracle_error_msg
               );
        END IF;

    ELSE
        ------------------------------
        -- Creating a new account site
        ------------------------------
        hz_cust_account_site_v2pub.create_cust_acct_site
            (
                p_init_msg_list         => FND_API.G_TRUE,
                p_cust_acct_site_rec    => cust_acct_site_rec_type,
                x_cust_acct_site_id     => ln_cust_acct_site_id,
                x_return_status         => lc_return_status,
                x_msg_count             => ln_msg_count,
                x_msg_data              => lc_msg_data
            );
        Log_Debug_Msg(CHR(10)||'==============================================');
        Log_Debug_Msg('Output After calling create_cust_acct_site API');
        Log_Debug_Msg('==============================================');
        Log_Debug_Msg('ln_cust_acct_site_id = '||ln_cust_acct_site_id);
        Log_Debug_Msg('lc_return_status = '||lc_return_status);
        Log_Debug_Msg('ln_msg_count = '||ln_msg_count);
        Log_Debug_Msg('lc_msg_data = '||lc_msg_data);

        x_acct_site_id              := ln_cust_acct_site_id;
        x_acct_site_return_status   := lc_return_status;

        IF (lc_return_status = 'S') THEN
            log_debug_msg(CHR(10)||'Customer Account Site is successfully created !!!');
        ELSE
            log_debug_msg(CHR(10)||'Customer Account Site is not created !!!');
            IF ln_msg_count >= 1 THEN
                log_debug_msg(CHR(10)||lc_procedure_name||': Errors in creating Customer Account Site');
                log_debug_msg('------------------------------------------------------------');
                FOR I IN 1..ln_msg_count
                LOOP
                    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE); 
                    Log_Debug_Msg('Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE)); 
                END LOOP;
                log_debug_msg('------------------------------------------------------------'||CHR(10));
            END IF;
            log_exception
                (
                    p_conversion_id                 => ln_conversion_acct_site_id
                   ,p_record_control_id             => l_hz_imp_acct_sites_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_sites_stg.acct_site_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_sites_stg.acct_site_orig_sys_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => 'RECORD_ID'
                   ,p_staging_column_value          => l_hz_imp_acct_sites_stg.record_id
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => XX_CDH_CONV_MASTER_PKG.trim_input_msg(l_msg_text) 
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
                );
        END IF;
    END IF;
    
END create_account_site;


-- +===================================================================+
-- | Name        : create_account_site_use                             |
-- | Description : Procedure to create a new site use                  |
-- |                                                                   |
-- | Parameters  : l_hz_imp_acct_site_uses_stg                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_account_site_use
    (
             l_hz_imp_acct_site_uses_stg        IN      XXOD_HZ_IMP_ACCT_SITE_USES_STG%ROWTYPE
            ,x_site_use_id                      OUT     NUMBER
            ,x_site_use_return_status           OUT     VARCHAR
    )
AS

ln_cust_acct_site_id            NUMBER;
cust_site_use_rec_type          HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
lc_site_code                    VARCHAR2(200);
ln_site_use_id                  NUMBER;
lc_return_status                VARCHAR2(2000);
ln_msg_count                    NUMBER;
lc_msg_data                     VARCHAR2(4000);
lc_cust_err_status              VARCHAR2(2000);
lc_addr_proc_err_status         VARCHAR2(2000);

ln_party_id                     NUMBER;
lc_party_number                 VARCHAR2(30);
ln_profile_id                   NUMBER;
lc_sql_err_text                 VARCHAR2(2000);
gn_application_id               NUMBER:=222;
ln_rec_count                    NUMBER DEFAULT 0;
ln_cust_site_use_id             NUMBER;
lc_bill_to_orig_sys             VARCHAR2(200);
lc_bill_to_orig_add_ref         VARCHAR2(200);

ln_conversion_site_use_id       NUMBER := 00241.3;
ln_record_control_id            NUMBER;
lc_procedure_name               VARCHAR2(32) := 'create_account_site_use';
lc_staging_table_name           VARCHAR2(32) := 'XXOD_HZ_IMP_ACCT_SITE_USES_STG';
lc_staging_column_name          VARCHAR2(32);
lc_staging_column_value         VARCHAR2(500);
ln_batch_id                     NUMBER;
lc_exception_log                VARCHAR2(2000);
lc_oracle_error_msg             VARCHAR2(2000);

lc_party_orig_sys               VARCHAR2(200)   := l_hz_imp_acct_site_uses_stg.party_orig_system;
lc_account_orig_sys             VARCHAR2(200)   := l_hz_imp_acct_site_uses_stg.account_orig_system;
lc_site_orig_sys                VARCHAR2(200)   := l_hz_imp_acct_site_uses_stg.acct_site_orig_system;
lc_site_orig_sys_ref            VARCHAR2(200);

lb_create_site_use_flag         BOOLEAN := TRUE;
lb_update_site_use_flag         BOOLEAN := FALSE;
ln_object_version_number        NUMBER;

l_msg_text                      VARCHAR2(4200);

BEGIN
    x_site_use_return_status    := 'E';

    ln_record_control_id                            := l_hz_imp_acct_site_uses_stg.record_id;
    ln_batch_id                                     := gn_batch_id;
    lc_site_code                                    := l_hz_imp_acct_site_uses_stg.site_use_code;

    IF l_hz_imp_acct_site_uses_stg.site_use_code = 'BILL_TO' THEN
      lc_site_orig_sys_ref                            := l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference||'-'||l_hz_imp_acct_site_uses_stg.site_use_code;
    ELSE
      lc_site_orig_sys_ref                            := RTRIM(l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference,'CA')||'-'||l_hz_imp_acct_site_uses_stg.site_use_code; 
    END IF;

    Log_Debug_Msg('lc_site_orig_sys  = '||lc_site_orig_sys);
    Log_Debug_Msg('lc_site_orig_sys_ref = '||lc_site_orig_sys_ref);

    IF l_hz_imp_acct_site_uses_stg.party_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_orig_system is NULL');
        lc_staging_column_name                   := 'party_orig_system';
        lc_staging_column_value                  := l_hz_imp_acct_site_uses_stg.party_orig_system;
        lc_exception_log                         := 'party_orig_system is NULL';
        lc_oracle_error_msg                      := 'party_orig_system is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_site_use_id
               ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.party_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_site_uses_stg.party_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_site_use_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_site_uses_stg.party_orig_system_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_orig_system_reference is NULL');
        lc_staging_column_name                   := 'party_orig_system_reference';
        lc_staging_column_value                  := l_hz_imp_acct_site_uses_stg.party_orig_system_reference;
        lc_exception_log                         := 'party_orig_system_reference is NULL ';
        lc_oracle_error_msg                      := 'party_orig_system_reference is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_site_use_id
               ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.party_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_site_uses_stg.party_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_site_use_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_site_uses_stg.account_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': account_orig_system is NULL');
        lc_staging_column_name                   := 'account_orig_system';
        lc_staging_column_value                  := l_hz_imp_acct_site_uses_stg.account_orig_system;
        lc_exception_log                         := 'account_orig_system is NULL';
        lc_oracle_error_msg                      := 'account_orig_system is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_site_use_id
               ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_site_uses_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_site_use_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_site_uses_stg.account_orig_system_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': account_orig_system_reference is NULL');
        lc_staging_column_name                   := 'account_orig_system_reference';
        lc_staging_column_value                  := l_hz_imp_acct_site_uses_stg.account_orig_system_reference;
        lc_exception_log                         := 'account_orig_system_reference is NULL ';
        lc_oracle_error_msg                      := 'account_orig_system_reference is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_site_use_id
               ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_site_uses_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_site_use_flag := FALSE;
    END IF;


    IF l_hz_imp_acct_site_uses_stg.acct_site_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': acct_site_orig_system is NULL');
        lc_staging_column_name                   := 'acct_site_orig_system';
        lc_staging_column_value                  := l_hz_imp_acct_site_uses_stg.acct_site_orig_system;
        lc_exception_log                         := 'acct_site_orig_system is NULL';
        lc_oracle_error_msg                      := 'acct_site_orig_system is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_site_use_id
               ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.acct_site_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_site_use_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': acct_site_orig_sys_reference is NULL');
        lc_staging_column_name                   := 'acct_site_orig_sys_reference';
        lc_staging_column_value                  := l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference;
        lc_exception_log                         := 'acct_site_orig_sys_reference is NULL ';
        lc_oracle_error_msg                      := 'acct_site_orig_sys_reference is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_site_use_id
               ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.acct_site_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_site_use_flag := FALSE;
    END IF;

    IF lc_site_code IS NULL THEN
        log_debug_msg(lc_procedure_name||': site_use_code is NULL');
        lc_staging_column_name                   := 'site_use_code';
        lc_staging_column_value                  := l_hz_imp_acct_site_uses_stg.site_use_code;
        lc_exception_log                         := 'site_use_code is NULL ';
        lc_oracle_error_msg                      := 'site_use_code is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_site_use_id
               ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.acct_site_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_site_use_flag := FALSE;
    END IF;

    ln_cust_acct_site_id := is_acct_site_exists(l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference,lc_site_orig_sys) ;

    IF (ln_cust_acct_site_id IS NULL) THEN
        Log_Debug_Msg(lc_procedure_name||':cust_acct_site_id is not found');
        lc_staging_column_name                  := 'acct_site_orig_sys_reference';
        lc_staging_column_value                 := l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference;
        lc_exception_log                        := 'cust_acct_site_id is not found';
        lc_oracle_error_msg                     := 'cust_acct_site_id is not found';
        log_exception
            (
                p_conversion_id                 => ln_conversion_site_use_id
               ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.acct_site_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_create_site_use_flag := FALSE;
    END IF;

    ln_site_use_id      := is_acct_site_use_exists(l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference,lc_site_orig_sys,lc_site_code);

    IF  ln_site_use_id IS NOT NULL AND
        ln_site_use_id = 0 THEN

        Log_Debug_Msg(lc_procedure_name||':acct_site_orig_sys_reference returns more than one site_use_id');
        lc_staging_column_name                  := 'acct_site_orig_sys_reference';
        lc_staging_column_value                 := lc_site_orig_sys_ref;
        lc_exception_log                        := 'acct_site_orig_sys_reference returns more than one site_use_id';
        lc_oracle_error_msg                     := 'acct_site_orig_sys_reference returns more than one site_use_id';
        log_exception
            (
                p_conversion_id                 => ln_conversion_site_use_id
               ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.acct_site_orig_system
               ,p_source_system_ref             => lc_site_orig_sys_ref
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );


        lb_create_site_use_flag := FALSE;

    END IF;

    IF  ln_site_use_id IS NOT NULL AND
        ln_site_use_id <> 0 THEN

        ----------------------------
        -- Update account site use
        ----------------------------

        Log_Debug_Msg(CHR(10)||lc_procedure_name||': site use already exists');
        Log_Debug_Msg(lc_procedure_name||'Updating site use id (site_use_id) = '||ln_site_use_id);

        lb_update_site_use_flag := TRUE;

        cust_site_use_rec_type.site_use_id              := ln_site_use_id;
        cust_site_use_rec_type.location                 := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.location);
        cust_site_use_rec_type.tax_reference            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_tax_reference);
        cust_site_use_rec_type.tax_code                 := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_tax_code);
        cust_site_use_rec_type.attribute_category       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute_category);
        cust_site_use_rec_type.attribute1               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute1);
        cust_site_use_rec_type.attribute2               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute2);
        cust_site_use_rec_type.attribute3               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute3);
        cust_site_use_rec_type.attribute4               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute4);
        cust_site_use_rec_type.attribute5               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute5);
        cust_site_use_rec_type.attribute6               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute6);
        cust_site_use_rec_type.attribute7               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute7);
        cust_site_use_rec_type.attribute8               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute8);
        cust_site_use_rec_type.attribute9               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute9);
        cust_site_use_rec_type.attribute10              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute10);
        cust_site_use_rec_type.attribute11              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute11);
        cust_site_use_rec_type.attribute12              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute12);
        cust_site_use_rec_type.attribute13              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute13);
        cust_site_use_rec_type.attribute14              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute14);
        cust_site_use_rec_type.attribute15              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute15);
        cust_site_use_rec_type.attribute16              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute16);
        cust_site_use_rec_type.attribute17              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute17);
        cust_site_use_rec_type.attribute18              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute18);
        cust_site_use_rec_type.attribute19              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute19);
        cust_site_use_rec_type.attribute20              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute20);
        cust_site_use_rec_type.attribute21              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute21);
        cust_site_use_rec_type.attribute22              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute22);
        cust_site_use_rec_type.attribute23              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute23);
        cust_site_use_rec_type.attribute24              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute24);
        cust_site_use_rec_type.attribute25              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute25);
        cust_site_use_rec_type.demand_class_code        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.demand_class_code);
        cust_site_use_rec_type.global_attribute1        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute1);
        cust_site_use_rec_type.global_attribute2        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute2);
        cust_site_use_rec_type.global_attribute3        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute3);
        cust_site_use_rec_type.global_attribute4        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute4);
        cust_site_use_rec_type.global_attribute5        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute5);
        cust_site_use_rec_type.global_attribute6        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute6);
        cust_site_use_rec_type.global_attribute7        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute7);
        cust_site_use_rec_type.global_attribute8        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute8);
        cust_site_use_rec_type.global_attribute9        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute9);
        cust_site_use_rec_type.global_attribute10       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute10);
        cust_site_use_rec_type.global_attribute11       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute11);
        cust_site_use_rec_type.global_attribute12       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute12);
        cust_site_use_rec_type.global_attribute13       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute13);
        cust_site_use_rec_type.global_attribute14       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute14);
        cust_site_use_rec_type.global_attribute15       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute15);
        cust_site_use_rec_type.global_attribute16       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute16);
        cust_site_use_rec_type.global_attribute17       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute17);
        cust_site_use_rec_type.global_attribute18       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute18);
        cust_site_use_rec_type.global_attribute19       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute19);
        cust_site_use_rec_type.global_attribute20       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute20);
        cust_site_use_rec_type.global_attribute_category:= xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attr_cat);
        cust_site_use_rec_type.gl_id_rec                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_site_uses_stg.gl_id_rec);
        cust_site_use_rec_type.gl_id_rev                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_site_uses_stg.gl_id_rev);
        cust_site_use_rec_type.gl_id_tax                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_site_uses_stg.gl_id_tax);
        cust_site_use_rec_type.gl_id_freight            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_site_uses_stg.gl_id_freight);
        cust_site_use_rec_type.gl_id_clearing           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_site_uses_stg.gl_id_clearing);
        cust_site_use_rec_type.gl_id_unbilled           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_site_uses_stg.gl_id_unbilled);
        cust_site_use_rec_type.gl_id_unearned           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_site_uses_stg.gl_id_unearned);
        cust_site_use_rec_type.gl_id_unpaid_rec         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_site_uses_stg.gl_id_unpaid_rec);
        cust_site_use_rec_type.gl_id_remittance         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_site_uses_stg.gl_id_remittance);
        cust_site_use_rec_type.gl_id_factor             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_site_uses_stg.gl_id_factor);
        cust_site_use_rec_type.status                   := 'A'; -- modified by ivarada, hardcoding status to 'A'
     -- Start Modification by Ambarish   
        cust_site_use_rec_type.primary_flag             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.primary_flag);
        Log_Debug_Msg('site use primary flag :'||cust_site_use_rec_type.primary_flag);
     -- End   Modification by Ambarish   
    ELSIF ln_site_use_id IS NULL THEN

        ---------------------------
        -- Create account site use
        ---------------------------

        Log_Debug_Msg(CHR(10)||lc_procedure_name||'Create a new account site use');
        Log_Debug_Msg('-----------------------------');

        cust_site_use_rec_type.cust_acct_site_id        := ln_cust_acct_site_id;
        cust_site_use_rec_type.site_use_code            := lc_site_code;
        cust_site_use_rec_type.location                 := l_hz_imp_acct_site_uses_stg.location;
        --lc_bill_to_orig_sys                             := l_hz_imp_acct_site_uses_stg.bill_to_orig_system;
        --lc_bill_to_orig_add_ref                         := l_hz_imp_acct_site_uses_stg.bill_to_acct_site_ref;
        cust_site_use_rec_type.orig_system_reference    := lc_site_orig_sys_ref;
        cust_site_use_rec_type.orig_system              := l_hz_imp_acct_site_uses_stg.acct_site_orig_system;
        cust_site_use_rec_type.tax_reference            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_tax_reference);
        cust_site_use_rec_type.tax_code                 := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_tax_code);
        cust_site_use_rec_type.attribute_category       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute_category);
        cust_site_use_rec_type.attribute1               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute1);
        cust_site_use_rec_type.attribute2               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute2);
        cust_site_use_rec_type.attribute3               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute3);
        cust_site_use_rec_type.attribute4               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute4);
        cust_site_use_rec_type.attribute5               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute5);
        cust_site_use_rec_type.attribute6               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute6);
        cust_site_use_rec_type.attribute7               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute7);
        cust_site_use_rec_type.attribute8               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute8);
        cust_site_use_rec_type.attribute9               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute9);
        cust_site_use_rec_type.attribute10              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute10);
        cust_site_use_rec_type.attribute11              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute11);
        cust_site_use_rec_type.attribute12              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute12);
        cust_site_use_rec_type.attribute13              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute13);
        cust_site_use_rec_type.attribute14              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute14);
        cust_site_use_rec_type.attribute15              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute15);
        cust_site_use_rec_type.attribute16              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute16);
        cust_site_use_rec_type.attribute17              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute17);
        cust_site_use_rec_type.attribute18              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute18);
        cust_site_use_rec_type.attribute19              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute19);
        cust_site_use_rec_type.attribute20              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute20);
        cust_site_use_rec_type.attribute21              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute21);
        cust_site_use_rec_type.attribute22              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute22);
        cust_site_use_rec_type.attribute23              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute23);
        cust_site_use_rec_type.attribute24              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute24);
        cust_site_use_rec_type.attribute25              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.site_use_attribute25);
        cust_site_use_rec_type.demand_class_code        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.demand_class_code);
        cust_site_use_rec_type.global_attribute1        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute1);
        cust_site_use_rec_type.global_attribute2        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute2);
        cust_site_use_rec_type.global_attribute3        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute3);
        cust_site_use_rec_type.global_attribute4        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute4);
        cust_site_use_rec_type.global_attribute5        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute5);
        cust_site_use_rec_type.global_attribute6        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute6);
        cust_site_use_rec_type.global_attribute7        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute7);
        cust_site_use_rec_type.global_attribute8        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute8);
        cust_site_use_rec_type.global_attribute9        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute9);
        cust_site_use_rec_type.global_attribute10       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute10);
        cust_site_use_rec_type.global_attribute11       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute11);
        cust_site_use_rec_type.global_attribute12       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute12);
        cust_site_use_rec_type.global_attribute13       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute13);
        cust_site_use_rec_type.global_attribute14       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute14);
        cust_site_use_rec_type.global_attribute15       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute15);
        cust_site_use_rec_type.global_attribute16       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute16);
        cust_site_use_rec_type.global_attribute17       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute17);
        cust_site_use_rec_type.global_attribute18       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute18);
        cust_site_use_rec_type.global_attribute19       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute19);
        cust_site_use_rec_type.global_attribute20       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attribute20);
        cust_site_use_rec_type.global_attribute_category:= xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.gdf_site_use_attr_cat);
        cust_site_use_rec_type.gl_id_rec                := l_hz_imp_acct_site_uses_stg.gl_id_rec;
        cust_site_use_rec_type.gl_id_rev                := l_hz_imp_acct_site_uses_stg.gl_id_rev;
        cust_site_use_rec_type.gl_id_tax                := l_hz_imp_acct_site_uses_stg.gl_id_tax;
        cust_site_use_rec_type.gl_id_freight            := l_hz_imp_acct_site_uses_stg.gl_id_freight;
        cust_site_use_rec_type.gl_id_clearing           := l_hz_imp_acct_site_uses_stg.gl_id_clearing;
        cust_site_use_rec_type.gl_id_unbilled           := l_hz_imp_acct_site_uses_stg.gl_id_unbilled;
        cust_site_use_rec_type.gl_id_unearned           := l_hz_imp_acct_site_uses_stg.gl_id_unearned;
        cust_site_use_rec_type.gl_id_unpaid_rec         := l_hz_imp_acct_site_uses_stg.gl_id_unpaid_rec;
        cust_site_use_rec_type.gl_id_remittance         := l_hz_imp_acct_site_uses_stg.gl_id_remittance;
        cust_site_use_rec_type.gl_id_factor             := l_hz_imp_acct_site_uses_stg.gl_id_factor;
        cust_site_use_rec_type.created_by_module        := l_hz_imp_acct_site_uses_stg.created_by_module;
        cust_site_use_rec_type.application_id           := gn_application_id;
    -- Start Modification by Ambarish    
        cust_site_use_rec_type.primary_flag             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_site_uses_stg.primary_flag);
        Log_Debug_Msg('site use primary flag :'||cust_site_use_rec_type.primary_flag);
    -- End   Modification by Ambarish    
        /*
        cust_site_use_rec_type.status                   := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.contact_id               := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.bill_to_site_use_id      := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.sic_code                 := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.payment_term_id          := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.gsa_indicator            := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.ship_partial             := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.ship_via                 := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.fob_point                := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.order_type_id            := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.price_list_id            := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.freight_term             := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.warehouse_id             := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.territory_id             := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.sort_priority            := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.tax_header_level_flag    := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.tax_rounding_rule        := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.primary_salesrep_id      := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.finchrg_receivables_trx_id := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.dates_negative_tolerance := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.dates_positive_tolerance := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.date_type_preference     := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.over_shipment_tolerance  := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.under_shipment_tolerance := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.item_cross_ref_pref      := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.over_return_tolerance    := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.under_return_tolerance   := FND_API.G_MISS_NUM;
        cust_site_use_rec_type.ship_sets_include_lines_flag := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.arrivalsets_include_lines_flag := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.sched_date_push_flag     := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.invoice_quantity_rule    := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.pricing_event            := FND_API.G_MISS_CHAR;
        cust_site_use_rec_type.tax_classification       := FND_API.G_MISS_CHAR;


        -- cust_site_use_rec_type.bill_to_site_use_id
        IF(lc_bill_to_orig_sys IS NOT NULL AND lc_bill_to_orig_add_ref IS NOT NULL) THEN
            cust_site_use_rec_type.bill_to_site_use_id  := bill_to_use_id_val
                (
                    p_bill_to_orig_sys                     => lc_bill_to_orig_sys
                    ,p_bill_to_orig_add_ref                 => lc_bill_to_orig_add_ref||'-'||'BILL_TO'
                );
        END IF;
        */

    END IF;




    IF lb_create_site_use_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||':Cannot create/update account site use - Error Occurred');
        RETURN;
    END IF;

    Log_Debug_Msg(CHR(10)||'===============================================');
    Log_Debug_Msg('Key attribute values of customer site use record');
    Log_Debug_Msg('===============================================');
    Log_Debug_Msg('attribute_category = '||cust_site_use_rec_type.attribute_category);
    Log_Debug_Msg('site_use_code:'||cust_site_use_rec_type.site_use_code);
    Log_Debug_Msg('location:'||cust_site_use_rec_type.location);
    Log_Debug_Msg('bill_to_site_use_id:'||cust_site_use_rec_type.bill_to_site_use_id);

    IF lb_update_site_use_flag = TRUE THEN

        ------------------------------------------
        -- Updating the existing account site use
        ------------------------------------------


        -----------------------------
        -- Get Object Version Number
        -----------------------------

        BEGIN

            ln_object_version_number := NULL;

            SELECT  object_version_number,
                    cust_acct_site_id
            INTO    ln_object_version_number,
                    cust_site_use_rec_type.cust_acct_site_id    -- Defect 28030
            FROM    hz_cust_site_uses_all
            WHERE   site_use_id =  ln_site_use_id;

        EXCEPTION
           WHEN OTHERS THEN
            log_debug_msg(lc_procedure_name||': Error while fetching object_version_number for site_use_id - '||ln_site_use_id);
            log_debug_msg(lc_procedure_name||': Error - '||SQLERRM);
            lc_staging_column_name                  := 'account_orig_system_reference';
            lc_staging_column_value                 := l_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference;
            lc_exception_log                        := 'Error while fetching object_version_number for site_use_id - '||ln_site_use_id;
            lc_oracle_error_msg                     := 'Error while fetching object_version_number for site_use_id - '||ln_site_use_id;
            log_exception
                (
                    p_conversion_id                 => ln_conversion_site_use_id
                   ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.acct_site_orig_system
                   ,p_source_system_ref             => lc_site_orig_sys_ref
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => lc_staging_column_value
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
            );

            RETURN;
        END;

        hz_cust_account_site_v2pub.update_cust_site_use
            (
                p_init_msg_list             => FND_API.G_TRUE,
                p_cust_site_use_rec         => cust_site_use_rec_type,
                p_object_version_number     => ln_object_version_number,
                x_return_status             => lc_return_status,
                x_msg_count                 => ln_msg_count,
                x_msg_data                  => lc_msg_data
            );

        Log_Debug_Msg(CHR(10)||'=============================================');
        Log_Debug_Msg('Output After calling update_cust_site_use API');
        Log_Debug_Msg('=============================================');

        Log_Debug_Msg('ln_object_version_number = '||ln_object_version_number);
        Log_Debug_Msg('lc_return_status = '||lc_return_status);

        x_site_use_return_status        := lc_return_status;
        x_site_use_id                   := ln_cust_site_use_id;


        IF lc_return_status = 'S' THEN
            log_debug_msg(CHR(10)||'Customer Account Site Use is successfully updated !!!');
        ELSE
            log_debug_msg(CHR(10)||'Customer Account Site Use is not updated !!!');
            IF ln_msg_count >= 1 THEN
                log_debug_msg(CHR(10)||lc_procedure_name||': Errors in updating Customer Account Site Use');
                log_debug_msg('------------------------------------------------------------');
                FOR I IN 1..ln_msg_count
                LOOP
                    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE); 
                    Log_Debug_Msg('Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE)); 
                END LOOP;
                log_debug_msg('------------------------------------------------------------'||CHR(10));
            END IF;
            log_exception
                (
                    p_conversion_id                 => ln_conversion_site_use_id
                   ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.acct_site_orig_system
                   ,p_source_system_ref             => lc_site_orig_sys_ref
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => 'RECORD_ID'
                   ,p_staging_column_value          => l_hz_imp_acct_site_uses_stg.record_id
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => XX_CDH_CONV_MASTER_PKG.trim_input_msg(l_msg_text) 
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
            );  
            
        END IF;

    ELSE
        -----------------------------------
        -- Creating a new account site use
        -----------------------------------
        hz_cust_account_site_v2pub.create_cust_site_use
            (
                p_init_msg_list           => FND_API.G_TRUE,
                p_cust_site_use_rec       => cust_site_use_rec_type,
                p_customer_profile_rec    => NULL,
                p_create_profile          => FND_API.G_FALSE,
                p_create_profile_amt      => FND_API.G_FALSE,
                x_site_use_id             => ln_cust_site_use_id,
                x_return_status           => lc_return_status,
                x_msg_count               => ln_msg_count,
                x_msg_data                => lc_msg_data
            );

        x_site_use_return_status        := lc_return_status;
        x_site_use_id                   := ln_cust_site_use_id;

        Log_Debug_Msg(CHR(10)||'=============================================');
        Log_Debug_Msg('Output After calling create_cust_site_use API');
        Log_Debug_Msg('=============================================');
        Log_Debug_Msg('ln_cust_site_use_id = '||ln_cust_site_use_id);
        Log_Debug_Msg('lc_return_status = '||lc_return_status);

        IF lc_return_status = 'S' THEN
            log_debug_msg(CHR(10)||'Customer Account Site Use is successfully created !!!');
        ELSE
            log_debug_msg(CHR(10)||'Customer Account Site Use is not created !!!');
            IF ln_msg_count >= 1 THEN
                log_debug_msg(CHR(10)||lc_procedure_name||': Errors in creating Customer Account Site Use');
                log_debug_msg('------------------------------------------------------------');
                FOR I IN 1..ln_msg_count
                LOOP
                    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE); 
                    Log_Debug_Msg('Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE)); 
                END LOOP;
                log_debug_msg('------------------------------------------------------------'||CHR(10));
            END IF;
            log_exception
                (
                    p_conversion_id                 => ln_conversion_site_use_id
                   ,p_record_control_id             => l_hz_imp_acct_site_uses_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_site_uses_stg.acct_site_orig_system
                   ,p_source_system_ref             => lc_site_orig_sys_ref
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => 'RECORD_ID'
                   ,p_staging_column_value          => l_hz_imp_acct_site_uses_stg.record_id
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => XX_CDH_CONV_MASTER_PKG.trim_input_msg(l_msg_text) 
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
            );  
        END IF;

    END IF;

END create_account_site_use;


-- +===================================================================+
-- | Name        : log_debug_msg                                       |
-- | Description :                                                     |
-- |                                                                   |
-- | Parameters  :  p_debug_msg                                        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE log_debug_msg
    (
         p_debug_msg              IN        VARCHAR2
    )
AS

BEGIN
    --IF fnd_profile.value ('') = 'Y' THEN
    --DBMS_OUTPUT.PUT_LINE(p_debug_msg);
    --FND_FILE.PUT_LINE(FND_FILE.LOG,p_debug_msg);
    --END IF;
    XX_CDH_CONV_MASTER_PKG.write_conc_log_message( p_debug_msg);
END log_debug_msg;


-- +===================================================================+
-- | Name        : validate_date_value                                 |
-- | Description :                                                     |
-- |                                                                   |
-- | Parameters  :  p_date                                             |
-- |                                                                   |
-- +===================================================================+
FUNCTION validate_date_value
    (
        p_date              IN VARCHAR2

    )   RETURN BOOLEAN
IS

lc_date DATE;

BEGIN

    SELECT  TO_DATE(p_date)
    INTO    lc_date
    FROM    DUAL;
    IF (lc_date IS NULL) THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;

EXCEPTION
WHEN OTHERS THEN
    RETURN FALSE;

END validate_date_value;


-- +===================================================================+
-- | Name        : validate_flex_value                                 |
-- | Description :                                                     |
-- |                                                                   |
-- | Parameters  :  p_flex_value_set_name,p_flex_value                 |
-- |                                                                   |
-- +===================================================================+
FUNCTION validate_flex_value
    (
         p_flex_value_set_name      IN VARCHAR2
        ,p_flex_value               IN VARCHAR2

     )  RETURN BOOLEAN
IS

lc_temp_var VARCHAR(1);

BEGIN

    IF(p_flex_value IS NOT NULL) THEN

        BEGIN
            SELECT  '1'
            INTO    lc_temp_var
            FROM    fnd_flex_value_sets ffvs,
                    fnd_flex_values ffv
            WHERE   ffv.flex_value_set_id = ffvs.flex_value_set_id
            AND     ffvs.flex_value_set_name IN (p_flex_value_set_name)
            AND     SYSDATE BETWEEN NVL(ffv.start_date_active,SYSDATE)
            AND     NVL(ffv.end_date_active,SYSDATE)
            AND     ffv.enabled_flag = 'Y'
            AND     ffv.flex_value = p_flex_value;
            RETURN TRUE;

            EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END;
    END IF;

    RETURN TRUE;

END validate_flex_value;


-- +===================================================================+
-- | Name        : is_account_exists                                   |
-- | Description : Function to checks whether customer account         |
-- |               already exists or not                               |
-- | Parameters  : p_acct_orig_sys_ref,p_orig_sys                      |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_account_exists
    (
        p_acct_orig_sys_ref                VARCHAR2
       ,p_acct_orig_sys                    VARCHAR2

    )
RETURN NUMBER
IS

lc_acct_orig_sys_ref    VARCHAR2(2000) := p_acct_orig_sys_ref;
lc_acct_orig_sys        VARCHAR2(2000) := p_acct_orig_sys;
ln_cust_account_id      NUMBER;

BEGIN

   SELECT owner_table_id
   INTO   ln_cust_account_id
   FROM   hz_orig_sys_references
   WHERE  orig_system_reference = lc_acct_orig_sys_ref
   AND    orig_system           = lc_acct_orig_sys
   AND    owner_table_name      = 'HZ_CUST_ACCOUNTS'
   AND    status                = 'A';

   RETURN ln_cust_account_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;

END is_account_exists;


-- +===================================================================+
-- | Name        : is_acct_site_exists                                 |
-- | Description : Function to check whether customer account site     |
-- |               already exists or not                               |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys                      |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_acct_site_exists
    (
        p_site_orig_sys_ref  VARCHAR2
       ,p_site_orig_sys      VARCHAR2

    )
RETURN NUMBER
IS

lc_site_orig_sys_ref    VARCHAR2(2000) := p_site_orig_sys_ref;
lc_site_orig_sys        VARCHAR2(2000) := p_site_orig_sys;
ln_acct_site_id         NUMBER;

BEGIN

   SELECT hosr.owner_table_id
   INTO   ln_acct_site_id
   FROM   hz_orig_sys_references hosr,
          hz_cust_acct_sites     hcas
   WHERE  hosr.orig_system_reference  = lc_site_orig_sys_ref
   AND    hosr.orig_system            = lc_site_orig_sys
   AND    hosr.owner_table_name       = 'HZ_CUST_ACCT_SITES_ALL'
   AND    hosr.status                 = 'A'
   AND    hcas.cust_acct_site_id      = hosr.owner_table_id;

   RETURN   ln_acct_site_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;


END is_acct_site_exists ;


-- +===================================================================+
-- | Name        : is_acct_site_use_exists                             |
-- | Description : Function to check whether customer account site use |
-- |               already exists or not                               |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys,p_site_code          |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_acct_site_use_exists
    (
        p_site_orig_sys_ref                VARCHAR2
       ,p_orig_sys                         VARCHAR2
       ,p_site_code                        VARCHAR2

    )
RETURN NUMBER
IS

lc_site_orig_sys_ref    VARCHAR2(2000) := p_site_orig_sys_ref;
lc_orig_sys             VARCHAR2(2000) := p_orig_sys;
ln_site_use_id          NUMBER;

BEGIN

   SELECT hcsu.site_use_id
   INTO   ln_site_use_id
   FROM   hz_orig_sys_references hosr,
          hz_cust_acct_sites     hcs,
          hz_cust_site_uses      hcsu
   WHERE  hosr.orig_system_reference  = p_site_orig_sys_ref
   AND    hosr.orig_system            = p_orig_sys
   AND    hcs.status                  = 'A'
   AND    hosr.owner_table_name       = 'HZ_CUST_ACCT_SITES_ALL'
   AND    hosr.status                 = 'A'
   AND    hcsu.status                 = 'A'
   AND    hcs.cust_acct_site_id       = hosr.owner_table_id
   AND    hcs.cust_acct_site_id       = hcsu.cust_acct_site_id
   AND    hcsu.site_use_code          = p_site_code;

   RETURN ln_site_use_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;

END is_acct_site_use_exists;


-- +===================================================================+
-- | Name        : orig_sys_val                                        |
-- |                                                                   |
-- | Description : Function checks whether the p_orig_sys is a valid   |
-- |               reference key of HZ_ORIG_SYSTEM_B table             |
-- | Parameters  : p_orig_sys                                          |
-- |                                                                   |
-- +===================================================================+
FUNCTION orig_sys_val
    (
         p_orig_sys                             IN      VARCHAR2

    )   RETURN NUMBER

AS

lc_orig_sys_id  NUMBER := NULL;

BEGIN

    SELECT  orig_system_id
    INTO    lc_orig_sys_id
    FROM    HZ_ORIG_SYSTEMS_B
    WHERE   ORIG_SYSTEM = p_orig_sys;
    RETURN  lc_orig_sys_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END orig_sys_val;


-- +===================================================================+
-- | Name        : bill_to_use_id_val                                  |
-- | Description : Funtion to get bill_to_use_id                       |
-- |                                                                   |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys,p_site_code          |
-- |                                                                   |
-- +===================================================================+
FUNCTION bill_to_use_id_val
    (
         p_bill_to_orig_sys                     IN      VARCHAR2
        ,p_bill_to_orig_add_ref                 IN      VARCHAR2
    )

RETURN NUMBER
AS
ln_site_use_id  NUMBER := NULL;
BEGIN

    IF(p_bill_to_orig_sys IS NOT NULL AND p_bill_to_orig_add_ref IS NOT NULL)THEN

        BEGIN
            SELECT hosr.owner_table_id
            INTO   ln_site_use_id
            FROM   hz_orig_sys_references hosr,
                   hz_cust_site_uses      hcsu
            WHERE  hosr.orig_system           = p_bill_to_orig_sys
            AND    hosr.orig_system_reference = p_bill_to_orig_add_ref
            AND    hosr.owner_table_name      = 'HZ_CUST_SITE_USES_ALL'
            AND    hosr.status                = 'A'
            AND    hcsu.site_use_id           = hosr.owner_table_id;

            RETURN ln_site_use_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN NULL;
            WHEN OTHERS THEN
                RETURN NULL;
        END;

    END IF;

END bill_to_use_id_val;

-- +====================================================================+
-- | Name        : log_exception                                        |
-- | Description : This procedure is used for logging exceptions into   |
-- |               conversion common elements tables.                   |
-- |                                                                    |
-- | Parameters  : p_conversion_id,p_record_control_id,p_procedure_name |
-- |               p_batch_id,p_exception_log,p_oracle_error_msg        |
-- +====================================================================+
PROCEDURE log_exception
    (
         p_conversion_id          IN NUMBER
        ,p_record_control_id      IN NUMBER
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

lc_package_name           VARCHAR2(32)  := 'XX_CDH_CUSTOMER_ACCT_PKG';

BEGIN
    XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
        (
             p_conversion_id          => p_conversion_id
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



-- +===================================================================+
-- | Name        : ar_lookup_val                                       |
-- | Description : This procedure checks for the lookup value from     |
-- |               AR_LOOKUPS table                                    |
-- |                                                                   |
-- | Parameters  : p_lookup_type,p_lookup_code                         |
-- |                                                                   |
-- +===================================================================+
FUNCTION ar_lookup_val
    (
         p_lookup_type     IN VARCHAR2
        ,p_lookup_code     IN VARCHAR2

    )

RETURN BOOLEAN

AS
lc_temp_var VARCHAR(1);
BEGIN
    IF (p_lookup_code IS NOT NULL) THEN
        BEGIN
            SELECT  '1'
            INTO    lc_temp_var
            FROM    ar_lookups
            WHERE   lookup_type = p_lookup_type
            AND     lookup_code = p_lookup_code;
            RETURN TRUE;
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN FALSE;
        END;
    END IF;
    RETURN TRUE;
END ar_lookup_val;

END XX_CDH_CUSTOMER_ACCT_PKG;
/
SHOW ERRORS;