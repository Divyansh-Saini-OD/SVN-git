SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_CUSTOMER_PROFILE_PKG
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                Oracle NAIO Consulting Organization                                      |
-- +=========================================================================================+
-- | Name        : XX_CDH_CUSTOMER_PROFILE_PKG                                               |
-- | Description : Custom package to create/update customer profile and amount               |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   12-Apr-2007     Prakash Sowriraj     Initial draft version                    |
-- |Draft 1b   15-May-2007     Prakash Sowriraj     Modified to include update part          |
-- |Draft 1c   03-Jul-2007     Ambarish Mukherjee   Modified to include org_id changes       |
-- |1.1        29-May-2009     Indra Varada         Do not set credit limit when value is 0  |
-- |1.2        05-Jun-2009     Indra Varada         Fix to NULL Statement_cycle_id if value  |
-- |                                                for statements is 'N'                    |
-- |1.3        11-Nov-2013     Shubhashree R        Added the logic to pass the bill level   |
-- |                                                to the API.                              |
-- |1.4        10-Dec-2013     Shubhashree R        Added the logic to set the Override Terms|
-- |                                                to Y if Consolidated billing is enabled. |
-- |                                                Added procedure update_profile_override_terms. |
-- |1.5        08-Jan-2014     Jay Gupta            Caling update API again for updating     |
-- |                                                the Standard Terms                       |
-- |                                                Search the changes using word "V1.5"     |
-- +=========================================================================================+

AS

    gn_application_id   CONSTANT    NUMBER:=222;--AR Account Receivable
    gn_batch_id         NUMBER;

-- +===================================================================+
-- | Name        : profile_main                                        |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE profile_main
    (
         x_errbuf       OUT     VARCHAR2
        ,x_retcode      OUT     VARCHAR2
        ,p_batch_id     IN      NUMBER
        ,p_process_yn   IN      VARCHAR2
    )
AS

--Cursor for customer_account_profile
CURSOR C_XXOD_HZ_IMP_ACCT_PROF_STG
    ( cp_batch_id   NUMBER )
IS
SELECT  *
FROM    XXOD_HZ_IMP_ACCOUNT_PROF_STG
WHERE   batch_id = cp_batch_id
AND     org_id   = FND_GLOBAL.org_id       -- Added By Ambarish
AND     interface_status IN ('1','4','6');

--Cursor for customer_account_profile_amount
CURSOR C_XXOD_HZ_IMP_PROF_AMT_STG
    ( cp_batch_id   NUMBER )
IS
SELECT  *
FROM    XXOD_HZ_IMP_ACCOUNT_PROF_STG
WHERE   batch_id = cp_batch_id
AND     org_id   = FND_GLOBAL.org_id       -- Added By Ambarish
AND     profile_amt_interface_status IN ('1','4','6');

l_hz_imp_acct_prof_stg          C_XXOD_HZ_IMP_ACCT_PROF_STG%ROWTYPE ;
ln_conversion_prof_id           NUMBER := 00243.1;
ln_conversion_prof_amt_id       NUMBER := 00243.2;
ln_cust_prof_id                 NUMBER;
ln_cust_prof_amt_id             NUMBER;
lc_prof_return_status           VARCHAR(1);
lc_prof_amt_return_status       VARCHAR(1);

--Table type variables for Customer_Profile creation
TYPE xx_cust_prof_table IS TABLE OF XXOD_HZ_IMP_ACCOUNT_PROF_STG%ROWTYPE INDEX BY BINARY_INTEGER;
lc_cust_prof_table xx_cust_prof_table;

TYPE xx_upd_record_table IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
TYPE xx_upd_interface_table IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;

lc_cust_prof_record_table xx_upd_record_table;
lc_cust_prof_interface_table xx_upd_interface_table;

--Table type variables for Customer_Profile_Amount creation
TYPE xx_cust_prof_amt_table IS TABLE OF XXOD_HZ_IMP_ACCOUNT_PROF_STG%ROWTYPE INDEX BY BINARY_INTEGER;
lc_cust_prof_amt_table xx_cust_prof_amt_table;

lc_prof_amt_record_table xx_upd_record_table;
lc_prof_amt_interface_table xx_upd_interface_table;

ln_cust_prof_rec_pro_succ       NUMBER := 0;
ln_cust_prof_rec_pro_fail       NUMBER := 0;
lc_num_pro_rec_read             NUMBER := 0;
le_skip_procedure               EXCEPTION;

BEGIN

   IF p_process_yn = 'N' THEN
      RAISE le_skip_procedure;
   END IF;

    --DBMS_APPLICATION_INFO.set_client_info('141');
    gn_batch_id := p_batch_id;

    log_debug_msg('=====================       BEGIN       =======================');
    log_debug_msg('================ Create Customer Profile Main ================='||CHR(10));
    BEGIN

        log_debug_msg('Batch-id = '||gn_batch_id);

        --Main cursor to loop through each accout
        OPEN C_XXOD_HZ_IMP_ACCT_PROF_STG (
                cp_batch_id                 => p_batch_id);
        FETCH C_XXOD_HZ_IMP_ACCT_PROF_STG BULK COLLECT INTO lc_cust_prof_table;
        CLOSE C_XXOD_HZ_IMP_ACCT_PROF_STG;

        IF lc_cust_prof_table.count < 1 THEN
            log_debug_msg('No records found for the batch_id : '||gn_batch_id);
        ELSE
            --Calling Log_control_info_proc API
            XX_COM_CONV_ELEMENTS_PKG.Log_control_info_proc(
                 p_conversion_id            => ln_conversion_prof_id
                ,p_batch_id                 => gn_batch_id
                ,p_num_bus_objs_processed   => lc_cust_prof_table.count);

            FOR i IN lc_cust_prof_table.first .. lc_cust_prof_table.last
            LOOP
                lc_prof_return_status       := 'E';
                log_debug_msg(CHR(10)||'Record-id:'||lc_cust_prof_table(i).record_id);
                log_debug_msg('=====================');

                --Creating a new Customer Profile
                create_profile(
                     l_hz_imp_acct_prof_stg => lc_cust_prof_table(i)
                    ,x_cust_acct_prof_id    => ln_cust_prof_id
                    ,x_prof_return_status   => lc_prof_return_status);
                lc_cust_prof_record_table(i) := lc_cust_prof_table(i).record_id;

                IF(lc_prof_return_status = 'S') THEN
                    --Update Interface_Status
                    lc_cust_prof_interface_table(i) := '7';--SUCCESS
                    ln_cust_prof_rec_pro_succ := ln_cust_prof_rec_pro_succ+1;
                ELSE
                    --Update Interface_Status
                    lc_cust_prof_interface_table(i) := '6';--FAILED
                    ln_cust_prof_rec_pro_fail := ln_cust_prof_rec_pro_fail+1;
                END IF;
                --Commiting records each after 10 iteration
                IF MOD(i,10) = 0 THEN
                    COMMIT;
                END IF;
            END LOOP;

            --Bulk update of interface_status column
            IF lc_cust_prof_record_table.last > 0 THEN
                FORALL i IN 1 .. lc_cust_prof_record_table.last
                    UPDATE XXOD_HZ_IMP_ACCOUNT_PROF_STG
                    SET    interface_status  = lc_cust_prof_interface_table(i)
                    WHERE  record_id = lc_cust_prof_record_table(i);
            END IF;

            COMMIT;

            --No.of processed,failed,succeeded records - start
            lc_num_pro_rec_read := (ln_cust_prof_rec_pro_succ + ln_cust_prof_rec_pro_fail);
            log_debug_msg(CHR(10)||'-----------------------------------------------------------');
            log_debug_msg('Total no.of records read = '||lc_num_pro_rec_read);
            log_debug_msg('Total no.of records succeded = '||ln_cust_prof_rec_pro_succ);
            log_debug_msg('Total no.of records failed = '||ln_cust_prof_rec_pro_fail);
            log_debug_msg('-----------------------------------------------------------');
  -- Start Mod By Ambarish
            fnd_file.put_line(fnd_file.output,'================ Customer Profile ================='||CHR(10));
            fnd_file.put_line(fnd_file.output,CHR(10)||'-----------------------------------------------------------');
            fnd_file.put_line(fnd_file.output,'Total no.of records read = '||lc_num_pro_rec_read);
            fnd_file.put_line(fnd_file.output,'Total no.of records succeded = '||ln_cust_prof_rec_pro_succ);
            fnd_file.put_line(fnd_file.output,'Total no.of records failed = '||ln_cust_prof_rec_pro_fail);
            fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');
  -- End Mod By Ambarish
            XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc(
                 p_conc_mst_req_id              => APPS.FND_GLOBAL.CONC_REQUEST_ID
                ,p_batch_id                     => gn_batch_id
                ,p_conversion_id                => ln_conversion_prof_id
                ,p_num_bus_objs_failed_valid    => 0
                ,p_num_bus_objs_failed_process  => ln_cust_prof_rec_pro_fail
                ,p_num_bus_objs_succ_process    => ln_cust_prof_rec_pro_succ);

        END IF;

    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf    :='Others Exception in PROFILE_MAIN procedure '||SQLERRM;
        x_retcode   :='2';

    END;

    log_debug_msg(CHR(10)||'=======================       END        ======================');

    log_debug_msg(CHR(10)||'=====================       BEGIN       =======================');
    log_debug_msg('============= Create Customer Profile Amount Main ============='||CHR(10));
    BEGIN

        ln_cust_prof_rec_pro_succ := 0;
        ln_cust_prof_rec_pro_fail := 0;
        lc_num_pro_rec_read       := 0;

        --Main cursor to loop through each accout
        OPEN C_XXOD_HZ_IMP_PROF_AMT_STG (
                cp_batch_id                 => p_batch_id);
        FETCH C_XXOD_HZ_IMP_PROF_AMT_STG BULK COLLECT INTO lc_cust_prof_amt_table;
        CLOSE C_XXOD_HZ_IMP_PROF_AMT_STG;

        IF lc_cust_prof_amt_table.count < 1 THEN
            log_debug_msg('No records found for the batch_id : '||gn_batch_id);
        ELSE
            --Calling Log_control_info_proc API
            XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc(
                 p_conversion_id            => ln_conversion_prof_amt_id
                ,p_batch_id                 => gn_batch_id
                ,p_num_bus_objs_processed   => lc_cust_prof_amt_table.count);

            FOR i IN lc_cust_prof_amt_table.first .. lc_cust_prof_amt_table.last
            LOOP
                lc_prof_amt_return_status       := 'E';
                log_debug_msg(CHR(10)||'Record-id:'||lc_cust_prof_amt_table(i).record_id);
                log_debug_msg('======================');

                --Creating a new Customer Profile Amount record
                create_profile_amount(
                     l_hz_imp_prof_amt_stg      => lc_cust_prof_amt_table(i)
                    ,x_prof_amt_id              => ln_cust_prof_amt_id
                    ,x_prof_amt_return_status   => lc_prof_amt_return_status);

                lc_prof_amt_record_table(i) := lc_cust_prof_amt_table(i).record_id;
                IF(lc_prof_amt_return_status = 'S') THEN
                    --Update column PROFILE_AMT_INTERFACE_STATUS
                    lc_prof_amt_interface_table(i) := '7';--SUCCESS
                    ln_cust_prof_rec_pro_succ := ln_cust_prof_rec_pro_succ+1;
                ELSE
                    --Update column PROFILE_AMT_INTERFACE_STATUS
                    lc_prof_amt_interface_table(i) := '6';--FAILED
                    ln_cust_prof_rec_pro_fail := ln_cust_prof_rec_pro_fail+1;
                END IF;

                --Commiting records each after 10 iteration
                IF MOD(i,10) = 0 THEN
                    COMMIT;
                END IF;
            END LOOP;

            --PROFILE_AMT_INTERFACE_STATUS column bulk update for customer profile amount
            IF lc_prof_amt_record_table.last > 0 THEN
                FORALL i IN 1 .. lc_prof_amt_record_table.last
                    UPDATE XXOD_HZ_IMP_ACCOUNT_PROF_STG
                    SET    profile_amt_interface_status  = lc_prof_amt_interface_table(i)
                    WHERE  record_id = lc_prof_amt_record_table(i);
            END IF;

            COMMIT;

            --No.of processed,failed,succeeded records - start
            lc_num_pro_rec_read := (ln_cust_prof_rec_pro_succ + ln_cust_prof_rec_pro_fail);
            log_debug_msg(CHR(10)||'-----------------------------------------------------------');
            log_debug_msg('Total no.of records read = '||lc_num_pro_rec_read);
            log_debug_msg('Total no.of records succeded = '||ln_cust_prof_rec_pro_succ);
            log_debug_msg('Total no.of records failed = '||ln_cust_prof_rec_pro_fail);
            log_debug_msg('-----------------------------------------------------------');
  -- Start Mod By Ambarish
            fnd_file.put_line(fnd_file.output,'============= Customer Profile Amount ============='||CHR(10));
            fnd_file.put_line(fnd_file.output,CHR(10)||'-----------------------------------------------------------');
            fnd_file.put_line(fnd_file.output,'Total no.of records read = '||lc_num_pro_rec_read);
            fnd_file.put_line(fnd_file.output,'Total no.of records succeded = '||ln_cust_prof_rec_pro_succ);
            fnd_file.put_line(fnd_file.output,'Total no.of records failed = '||ln_cust_prof_rec_pro_fail);
            fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');
  -- End Mod By Ambarish
            XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc(
                 p_conc_mst_req_id              => APPS.FND_GLOBAL.CONC_REQUEST_ID
                ,p_batch_id                     => gn_batch_id
                ,p_conversion_id                => ln_conversion_prof_amt_id
                ,p_num_bus_objs_failed_valid    => 0
                ,p_num_bus_objs_failed_process  => ln_cust_prof_rec_pro_fail
                ,p_num_bus_objs_succ_process    => ln_cust_prof_rec_pro_succ);

        END IF;

    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf    :='Others Exception in PROFILE_MAIN procedure '||SQLERRM;
        x_retcode   :='2';
    END;

    log_debug_msg(CHR(10)||'=======================       END        ======================');
EXCEPTION
   WHEN le_skip_procedure THEN
      x_retcode := 0;
      fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
END Profile_Main;

-- +===================================================================+
-- | Name        : create_profile                                      |
-- |                                                                   |
-- | Description : Procdedure to create a new customer profile         |
-- |                                                                   |
-- | Parameters  :  l_hz_imp_acct_prof_stg                             |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_profile
    (
         l_hz_imp_acct_prof_stg     IN      XXOD_HZ_IMP_ACCOUNT_PROF_STG%ROWTYPE
        ,x_cust_acct_prof_id        OUT     NUMBER
        ,x_prof_return_status       OUT     VARCHAR2
    )
AS
cust_prof_rec_type              HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
ln_owner_table_id               HZ_ORIG_SYS_REFERENCES.OWNER_TABLE_ID%TYPE;
ln_cust_prof_id                 NUMBER := NULL;
ln_cust_acct_prof_id            NUMBER;
lc_prof_return_status           VARCHAR(1);
ln_msg_count                    NUMBER;
lc_msg_data                     VARCHAR2(2000);
ln_conversion_prof_id           NUMBER := 00243.1;
lc_procedure_name               VARCHAR2(32) := 'Create_Profile';
lc_staging_table_name           VARCHAR2(32) := 'XXOD_HZ_IMP_ACCOUNT_PROF_STG';
lc_staging_column_name          VARCHAR2(32);
lc_staging_column_value         VARCHAR2(500);
lc_exception_log                VARCHAR2(2000);
lc_oracle_error_msg             VARCHAR2(2000);
ln_retcode                      NUMBER;
ln_errbuf                       VARCHAR2(2000);
lc_status                       VARCHAR2(3);

ln_object_version_number        NUMBER := NULL;
lc_profile_id                   NUMBER;

ln_profile_class_id             NUMBER ;
lc_ret_prof_class_status        VARCHAR2(1);

ln_collector_id                 NUMBER ;
lc_collector_ret_status         VARCHAR2(1);

ln_standard_terms               NUMBER;
lc_ret_standard_terms_status    VARCHAR2(1);

ln_dunning_letter_set_id        NUMBER;
ln_ret_dun_letter_status        VARCHAR2(1);

ln_statement_cycle_id           NUMBER;
lc_ret_statement_status         VARCHAR2(1);

ln_autocash_hierarchy_id        NUMBER;
lc_autocash_hierarchy_status    VARCHAR2(1);

ln_grouping_rule_id             NUMBER;
lc_grouping_rule_status         VARCHAR2(1);

ln_hierarchy_id_for_adr         NUMBER;
lc_hierarchy_status             VARCHAR2(1);

lb_profile_create_flag          BOOLEAN := TRUE;
lb_profile_update               BOOLEAN := FALSE;

l_msg_text                      VARCHAR2(4200);

--jp V1.5
ln_new_object_version_number NUMBER;
ln_new_standard_terms NUMBER;

BEGIN
    x_prof_return_status := 'E';
    cust_prof_rec_type.cust_account_profile_id                  := NULL;
    cust_prof_rec_type.cust_account_id                          := NULL;

    log_debug_msg('account_orig_system: '||l_hz_imp_acct_prof_stg.account_orig_system);
    log_debug_msg('account_orig_system_reference: '||l_hz_imp_acct_prof_stg.account_orig_system_reference);

    IF l_hz_imp_acct_prof_stg.party_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_orig_system is NULL');
        lc_staging_column_name                   := 'party_orig_system';
        lc_staging_column_value                  := l_hz_imp_acct_prof_stg.party_orig_system;
        lc_exception_log                         := 'party_orig_system is NULL';
        lc_oracle_error_msg                      := 'party_orig_system is NULL';

        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_id
               ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_prof_stg.party_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_prof_stg.party_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_profile_create_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_prof_stg.party_orig_system_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_orig_system_reference is NULL');
        lc_staging_column_name                   := 'party_orig_system_reference';
        lc_staging_column_value                  := l_hz_imp_acct_prof_stg.party_orig_system_reference;
        lc_exception_log                         := 'party_orig_system_reference is NULL ';
        lc_oracle_error_msg                      := 'party_orig_system_reference is NULL';

        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_id
               ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_prof_stg.party_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_prof_stg.party_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_profile_create_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_prof_stg.account_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': account_orig_system is NULL');
        lc_staging_column_name                   := 'account_orig_system';
        lc_staging_column_value                  := l_hz_imp_acct_prof_stg.account_orig_system;
        lc_exception_log                         := 'account_orig_system is NULL';
        lc_oracle_error_msg                      := 'account_orig_system is NULL';

        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_id
               ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_profile_create_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_prof_stg.account_orig_system_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': account_orig_system_reference is NULL');
        lc_staging_column_name                   := 'account_orig_system_reference';
        lc_staging_column_value                  := l_hz_imp_acct_prof_stg.account_orig_system_reference;
        lc_exception_log                         := 'account_orig_system_reference is NULL ';
        lc_oracle_error_msg                      := 'account_orig_system_reference is NULL';

        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_id
               ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_profile_create_flag := FALSE;
    END IF;

    IF l_hz_imp_acct_prof_stg.account_orig_system IS NOT NULL AND l_hz_imp_acct_prof_stg.account_orig_system_reference IS NOT NULL THEN
        XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
            (
                 p_orig_system         => l_hz_imp_acct_prof_stg.account_orig_system
                ,p_orig_sys_reference  => l_hz_imp_acct_prof_stg.account_orig_system_reference
                ,p_owner_table_name    => 'HZ_CUST_ACCOUNTS'
                ,x_owner_table_id      => ln_owner_table_id
                ,x_retcode             => ln_retcode
                ,x_errbuf              => ln_errbuf
            );

        IF(ln_owner_table_id IS NULL ) THEN
            log_debug_msg(lc_procedure_name||': account_id is not found');
            lc_staging_column_name                  := 'account_orig_system_reference';
            lc_staging_column_value                 := l_hz_imp_acct_prof_stg.account_orig_system_reference;
            lc_exception_log                        := 'cust_account_id is not found';
            lc_oracle_error_msg                     := 'cust_account_id is not found';

           log_exception
                (
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
                );

            lb_profile_create_flag := FALSE;
        ELSE
            cust_prof_rec_type.cust_account_id      := ln_owner_table_id;
            log_debug_msg(lc_procedure_name||': account_id = '||cust_prof_rec_type.cust_account_id);
        END IF;
    END IF;

    IF l_hz_imp_acct_prof_stg.party_orig_system IS NOT NULL AND l_hz_imp_acct_prof_stg.party_orig_system_reference IS NOT NULL THEN
       XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
            (
                 p_orig_system         => l_hz_imp_acct_prof_stg.party_orig_system
                ,p_orig_sys_reference  => l_hz_imp_acct_prof_stg.party_orig_system_reference
                ,p_owner_table_name    => 'HZ_PARTIES'
                ,x_owner_table_id      => ln_owner_table_id
                ,x_retcode             => ln_retcode
                ,x_errbuf              => ln_errbuf
            );
        cust_prof_rec_type.party_id := ln_owner_table_id;
     END IF;

    --cust_prof_rec_type.collector_id                             := l_hz_imp_acct_prof_stg.collector_name;
    IF l_hz_imp_acct_prof_stg.collector_name IS NOT NULL THEN

        get_collector_id
            (
                  p_collector_name                       => l_hz_imp_acct_prof_stg.collector_name
                 ,x_collector_id                         => ln_collector_id
                 ,x_ret_status                           => lc_collector_ret_status
             );

        IF (lc_collector_ret_status = 'E') THEN

            log_debug_msg('lc_collector_ret_status:'||lc_collector_ret_status);
            log_debug_msg(lc_procedure_name||': More than one collector_id found');
            lc_staging_column_name                  := 'collector_name';
            lc_staging_column_value                 := l_hz_imp_acct_prof_stg.collector_name;
            lc_exception_log                        := 'More than one collector_id found';
            lc_oracle_error_msg                     := 'More than one collector_id found';

            log_exception
                (
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => lc_staging_column_value
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
                );

            lb_profile_create_flag := FALSE;
        END IF;
        cust_prof_rec_type.collector_id := ln_collector_id;
    END IF;

    --cust_prof_rec_type.profile_class_id                         := l_hz_imp_acct_prof_stg.customer_profile_class_name;
    IF l_hz_imp_acct_prof_stg.customer_profile_class_name IS NOT NULL THEN

        get_profile_class_id
            (
                 p_profile_class_name                => l_hz_imp_acct_prof_stg.customer_profile_class_name
                ,x_profile_class_id                  => ln_profile_class_id
                ,x_ret_status                        => lc_ret_prof_class_status
            );

        log_debug_msg('ln_profile_class_id:'||ln_profile_class_id);
        log_debug_msg('lc_ret_prof_class_status:'||lc_ret_prof_class_status);

        IF (lc_ret_prof_class_status = 'E') THEN

            log_debug_msg('lc_ret_prof_class_status:'||lc_ret_prof_class_status);
            log_debug_msg(lc_procedure_name||': More than one profile_class_id returned');
            lc_staging_column_name                  := 'customer_profile_class_name';
            lc_staging_column_value                 := l_hz_imp_acct_prof_stg.customer_profile_class_name;
            lc_exception_log                        := 'More than one profile_class_id returned';
            lc_oracle_error_msg                     := 'More than one profile_class_id returned';

            log_exception
                (
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => lc_staging_column_value
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
                );

            lb_profile_create_flag := FALSE;
        END IF;
        cust_prof_rec_type.profile_class_id := ln_profile_class_id;
    END IF;

    --cust_prof_rec_type.standard_terms                           := l_hz_imp_acct_prof_stg.standard_term_name;
    IF l_hz_imp_acct_prof_stg.standard_term_name IS NOT NULL THEN

        get_standard_terms
            (
                 p_standard_term_name               => l_hz_imp_acct_prof_stg.standard_term_name
                ,x_standard_terms                   => ln_standard_terms
                ,x_ret_status                       => lc_ret_standard_terms_status
            );

        IF (lc_ret_standard_terms_status = 'E') THEN
            log_debug_msg('lc_ret_standard_terms_status:'||lc_ret_standard_terms_status);
            log_debug_msg(lc_procedure_name||': More than standard_terms_status found');
            lc_staging_column_name                  := 'standard_term_name';
            lc_staging_column_value                 := l_hz_imp_acct_prof_stg.standard_term_name;
            lc_exception_log                        := 'More than standard_terms_status found';
            lc_oracle_error_msg                     := 'More than standard_terms_status found';

            log_exception
                (
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => lc_staging_column_value
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
                );

            lb_profile_create_flag := FALSE;
        END IF;
        cust_prof_rec_type.standard_terms := ln_standard_terms;
    END IF;

    --cust_prof_rec_type.dunning_letter_set_id                    := l_hz_imp_acct_prof_stg.dunning_letter_set_name;
    IF l_hz_imp_acct_prof_stg.dunning_letter_set_name IS NOT NULL THEN

        get_dunning_letter_set_id
            (
                 p_dunning_letter_set_name          => l_hz_imp_acct_prof_stg.dunning_letter_set_name
                ,x_dunning_letter_set_id            => ln_dunning_letter_set_id
                ,x_ret_dun_letter_status            => ln_ret_dun_letter_status
            );

        IF (ln_ret_dun_letter_status = 'E') THEN
            log_debug_msg('lc_ret_standard_terms_status:'||ln_ret_dun_letter_status);
            log_debug_msg(lc_procedure_name||': More than one dunning_letter_set_id found');
            lc_staging_column_name                  := 'dunning_letter_set_name';
            lc_staging_column_value                 := l_hz_imp_acct_prof_stg.dunning_letter_set_name;
            lc_exception_log                        := 'More than one dunning_letter_set_id found';
            lc_oracle_error_msg                     := 'More than one dunning_letter_set_id found';
            log_exception
                (
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => lc_staging_column_value
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
                );

            lb_profile_create_flag := FALSE;
        END IF;
        cust_prof_rec_type.dunning_letter_set_id := ln_dunning_letter_set_id;
    END IF;

    --cust_prof_rec_type.statement_cycle_id                       := l_hz_imp_acct_prof_stg.statement_cycle_name;
    IF l_hz_imp_acct_prof_stg.statement_cycle_name IS NOT NULL THEN
        get_statement_cycle_id
            (
                 p_statement_cycle_name          => l_hz_imp_acct_prof_stg.statement_cycle_name
                ,x_statement_cycle_id            => ln_statement_cycle_id
                ,x_ret_statement_status          => lc_ret_statement_status
            );

        IF (lc_ret_statement_status = 'E') THEN
            log_debug_msg('lc_ret_statement_status:'||lc_ret_statement_status);
            log_debug_msg(lc_procedure_name||': More than one statement_cycle_id found');
            lc_staging_column_name                  := 'statement_cycle_name';
            lc_staging_column_value                 := l_hz_imp_acct_prof_stg.statement_cycle_name;
            lc_exception_log                        := 'More than one statement_cycle_id found';
            lc_oracle_error_msg                     := 'More than one statement_cycle_id found';

            log_exception
                (
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => lc_staging_column_value
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
                );

            lb_profile_create_flag := FALSE;
        END IF;
        cust_prof_rec_type.statement_cycle_id := ln_statement_cycle_id;
    END IF;

    IF l_hz_imp_acct_prof_stg.statements = 'N' THEN
          cust_prof_rec_type.statement_cycle_id := FND_API.G_MISS_NUM;
    END IF;

    --cust_prof_rec_type.autocash_hierarchy_id                    := l_hz_imp_acct_prof_stg.autocash_hierarchy_name;
    IF l_hz_imp_acct_prof_stg.autocash_hierarchy_name IS NOT NULL THEN

        get_autocash_hierarchy_id
            (
                 p_autocash_hierarchy_name       => l_hz_imp_acct_prof_stg.autocash_hierarchy_name
                ,x_autocash_hierarchy_id         => ln_autocash_hierarchy_id
                ,x_autocash_hierarchy_status     => lc_autocash_hierarchy_status
            );

        IF (lc_autocash_hierarchy_status = 'E') THEN
            log_debug_msg('lc_autocash_hierarchy_status:'||lc_autocash_hierarchy_status);
            log_debug_msg(lc_procedure_name||': More than one autocash_hierarchy_id found');
            lc_staging_column_name                  := 'autocash_hierarchy_name';
            lc_staging_column_value                 := l_hz_imp_acct_prof_stg.autocash_hierarchy_name;
            lc_exception_log                        := 'More than one autocash_hierarchy_id found';
            lc_oracle_error_msg                     := 'More than one autocash_hierarchy_id found';
            log_exception
                (
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => lc_staging_column_value
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
                );

            lb_profile_create_flag := FALSE;
        END IF;
        cust_prof_rec_type.autocash_hierarchy_id := ln_autocash_hierarchy_id;
    END IF;

    --cust_prof_rec_type.grouping_rule_id                         := l_hz_imp_acct_prof_stg.grouping_rule_name;
    IF l_hz_imp_acct_prof_stg.grouping_rule_name IS NOT NULL THEN

        get_grouping_rule_id
            (
                 p_grouping_rule_name       => l_hz_imp_acct_prof_stg.grouping_rule_name
                ,x_grouping_rule_id         => ln_grouping_rule_id
                ,x_grouping_rule_status     => lc_grouping_rule_status
            );

        IF (lc_grouping_rule_status = 'E') THEN
            log_debug_msg('lc_grouping_rule_status:'||lc_grouping_rule_status);
            log_debug_msg(lc_procedure_name||': More than one grouping_rule_id found');
            lc_staging_column_name                  := 'grouping_rule_name';
            lc_staging_column_value                 := l_hz_imp_acct_prof_stg.grouping_rule_name;
            lc_exception_log                        := 'More than one grouping_rule_id found';
            lc_oracle_error_msg                     := 'More than one grouping_rule_id found';
            log_exception
                (
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => lc_staging_column_value
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
                );

            lb_profile_create_flag := FALSE;
        END IF;
        cust_prof_rec_type.grouping_rule_id := ln_grouping_rule_id;
    END IF;

    --cust_prof_rec_type.autocash_hierarchy_id_for_adr            := l_hz_imp_acct_prof_stg.autocash_hierarchy_name_adr;
    IF l_hz_imp_acct_prof_stg.autocash_hierarchy_name_adr IS NOT NULL THEN

        get_hierarchy_id_for_adr
            (
                 p_hierarchy_name_adr       => l_hz_imp_acct_prof_stg.autocash_hierarchy_name_adr
                ,x_hierarchy_id_for_adr     => ln_hierarchy_id_for_adr
                ,x_hierarchy_status         => lc_hierarchy_status
            );

        IF (lc_hierarchy_status = 'E') THEN
            log_debug_msg('lc_hierarchy_status:'||lc_hierarchy_status);
            log_debug_msg(lc_procedure_name||': More than one hierarchy_id_for_adr found');
            lc_staging_column_name                  := 'autocash_hierarchy_name_adr';
            lc_staging_column_value                 := l_hz_imp_acct_prof_stg.autocash_hierarchy_name_adr;
            lc_exception_log                        := 'More than one hierarchy_id_for_adr found';
            lc_oracle_error_msg                     := 'More than one hierarchy_id_for_adr found';
            log_exception
                (
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => lc_staging_column_name
                   ,p_staging_column_value          => lc_staging_column_value
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => lc_exception_log
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
                );

            lb_profile_create_flag := FALSE;
        END IF;
        cust_prof_rec_type.autocash_hierarchy_id_for_adr := ln_hierarchy_id_for_adr;
    END IF;


   lc_profile_id := is_customer_profile_exists
            (
                cust_prof_rec_type.cust_account_id
            );

    IF  lc_profile_id IS NOT NULL AND
        lc_profile_id = 0 THEN

        Log_Debug_Msg(lc_procedure_name||':account_orig_system_reference returns more than one profile_id');
        lc_staging_column_name                  := 'account_orig_system_reference';
        lc_staging_column_value                 := l_hz_imp_acct_prof_stg.account_orig_system_reference;
        lc_exception_log                        := 'account_orig_system_reference returns more than one profile_id';
        lc_oracle_error_msg                     := 'account_orig_system_reference returns more than one profile_id';
        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_id
               ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
               ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );

        lb_profile_create_flag := FALSE;

    END IF;

    --Validation added by Shubhashree 
    --If cons_inv_flag is Y then cons_bill_level should be Account / Site
    IF  l_hz_imp_acct_prof_stg.cons_inv_flag = 'Y' THEN
       
       ------------------------------
       -- Validate the Bill Level 
       ------------------------------
       IF l_hz_imp_acct_prof_stg.cons_bill_level != 'Account' AND
          l_hz_imp_acct_prof_stg.cons_bill_level != 'Site' THEN
          --------------------------------------------------
          -- Log an exception and stop processing the record.
          --------------------------------------------------
          Log_Debug_Msg(lc_procedure_name||':cons_bill_level should be either Account or Site');
	          lc_staging_column_name                  := 'cons_bill_level';
	          lc_staging_column_value                 := l_hz_imp_acct_prof_stg.cons_bill_level;
	          lc_exception_log                        := 'cons_bill_level should be either Account or Site';
	          lc_oracle_error_msg                     := 'cons_bill_level should be either Account or Site';
	          log_exception
	              (
	                  p_conversion_id                 => ln_conversion_prof_id
	                 ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
	                 ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
	                 ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
	                 ,p_procedure_name                => lc_procedure_name
	                 ,p_staging_table_name            => lc_staging_table_name
	                 ,p_staging_column_name           => lc_staging_column_name
	                 ,p_staging_column_value          => lc_staging_column_value
	                 ,p_batch_id                      => gn_batch_id
	                 ,p_exception_log                 => lc_exception_log
	                 ,p_oracle_error_code             => SQLCODE
	                 ,p_oracle_error_msg              => lc_oracle_error_msg
	              );
	  
        lb_profile_create_flag := FALSE;
       END IF;
    END IF;

    IF  lc_profile_id IS NOT NULL AND
        lc_profile_id <> 0 THEN

        ---------------------------
        -- Update customer profile
        ---------------------------

        log_debug_msg(lc_procedure_name||': Updating customer profile (profile_id) =  ' ||lc_profile_id);
        lb_profile_update := TRUE;

        cust_prof_rec_type.cust_account_profile_id                  := lc_profile_id;

        cust_prof_rec_type.credit_checking                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.credit_checking);
        cust_prof_rec_type.tolerance                                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_prof_stg.tolerance);
        cust_prof_rec_type.discount_terms                           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.discount_terms);
        cust_prof_rec_type.dunning_letters                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.dunning_letters);
        cust_prof_rec_type.interest_charges                         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.interest_charges);
        cust_prof_rec_type.send_statements                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.statements);
        cust_prof_rec_type.credit_balance_statements                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.credit_balance_statements);
        cust_prof_rec_type.credit_hold                              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.credit_hold);
        cust_prof_rec_type.credit_rating                            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.credit_rating);
        cust_prof_rec_type.risk_code                                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.risk_code);
        cust_prof_rec_type.override_terms                           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.override_terms);
        cust_prof_rec_type.interest_period_days                     := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_prof_stg.interest_period_days);
        cust_prof_rec_type.payment_grace_days                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_prof_stg.payment_grace_days);
        cust_prof_rec_type.discount_grace_days                      := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_prof_stg.discount_grace_days);
        cust_prof_rec_type.account_status                           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.account_status);
        cust_prof_rec_type.percent_collectable                      := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_prof_stg.percent_collectable);
        cust_prof_rec_type.attribute_category                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute_category);
        cust_prof_rec_type.attribute1                               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute1);
        cust_prof_rec_type.attribute2                               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute2);
        cust_prof_rec_type.attribute3                               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute3);
        cust_prof_rec_type.attribute4                               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute4);
        cust_prof_rec_type.attribute5                               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute5);
        cust_prof_rec_type.attribute6                               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute6);
        cust_prof_rec_type.attribute7                               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute7);
        cust_prof_rec_type.attribute8                               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute8);
        cust_prof_rec_type.attribute9                               := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute9);
        cust_prof_rec_type.attribute10                              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute10);
        cust_prof_rec_type.attribute11                              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute11);
        cust_prof_rec_type.attribute12                              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute12);
        cust_prof_rec_type.attribute13                              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute13);
        cust_prof_rec_type.attribute14                              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute14);
        cust_prof_rec_type.attribute15                              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.attribute15);
        --cust_prof_rec_type.auto_rec_incl_disputed_flag              := l_hz_imp_acct_prof_stg.auto_rec_incl_disputed_flag;
        cust_prof_rec_type.tax_printing_option                      := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.tax_printing_option);
        cust_prof_rec_type.charge_on_finance_charge_flag            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.charge_on_finance_charge_flag);
        cust_prof_rec_type.clearing_days                            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_acct_prof_stg.clearing_days);
        cust_prof_rec_type.jgzz_attribute_category                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attr_cat);
        cust_prof_rec_type.jgzz_attribute1                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute1);
        cust_prof_rec_type.jgzz_attribute2                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute2);
        cust_prof_rec_type.jgzz_attribute3                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute3);
        cust_prof_rec_type.jgzz_attribute4                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute4);
        cust_prof_rec_type.jgzz_attribute5                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute5);
        cust_prof_rec_type.jgzz_attribute6                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute6);
        cust_prof_rec_type.jgzz_attribute7                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute7);
        cust_prof_rec_type.jgzz_attribute8                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute8);
        cust_prof_rec_type.jgzz_attribute9                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute9);
        cust_prof_rec_type.jgzz_attribute10                         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute10);
        cust_prof_rec_type.jgzz_attribute11                         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute11);
        cust_prof_rec_type.jgzz_attribute12                         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute12);
        cust_prof_rec_type.jgzz_attribute13                         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute13);
        cust_prof_rec_type.jgzz_attribute14                         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute14);
        cust_prof_rec_type.jgzz_attribute15                         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute15);
        cust_prof_rec_type.global_attribute1                        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute1);
        cust_prof_rec_type.global_attribute2                        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute2);
        cust_prof_rec_type.global_attribute3                        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute3);
        cust_prof_rec_type.global_attribute4                        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute4);
        cust_prof_rec_type.global_attribute5                        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute5);
        cust_prof_rec_type.global_attribute6                        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute6);
        cust_prof_rec_type.global_attribute7                        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute7);
        cust_prof_rec_type.global_attribute8                        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute8);
        cust_prof_rec_type.global_attribute9                        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute9);
        cust_prof_rec_type.global_attribute10                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute10);
        cust_prof_rec_type.global_attribute11                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute11);
        cust_prof_rec_type.global_attribute12                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute12);
        cust_prof_rec_type.global_attribute13                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute13);
        cust_prof_rec_type.global_attribute14                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute14);
        cust_prof_rec_type.global_attribute15                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute15);
        cust_prof_rec_type.global_attribute16                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute16);
        cust_prof_rec_type.global_attribute17                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute17);
        cust_prof_rec_type.global_attribute18                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute18);
        cust_prof_rec_type.global_attribute19                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute19);
        cust_prof_rec_type.global_attribute20                       := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute20);
        cust_prof_rec_type.global_attribute_category                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.global_attribute_category);
        cust_prof_rec_type.cons_inv_flag                            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.cons_inv_flag);
        cust_prof_rec_type.cons_inv_type                            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.cons_inv_type);
        --Added by Shubhashree to update the cons_bill_level 12-11-2013
        cust_prof_rec_type.cons_bill_level                          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(UPPER(l_hz_imp_acct_prof_stg.cons_bill_level));
        IF l_hz_imp_acct_prof_stg.cons_inv_flag = 'Y' THEN
           cust_prof_rec_type.override_terms                           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char('Y');
        ELSE
           cust_prof_rec_type.override_terms                           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char('N');
        END IF;
        cust_prof_rec_type.lockbox_matching_option                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.lockbox_matching_option);
        cust_prof_rec_type.credit_classification                    := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_acct_prof_stg.credit_classification);

    ELSE

        ---------------------------
        -- Create customer profile
        ---------------------------

        log_debug_msg(lc_procedure_name||': Creating a new customer profile');

        --cust_prof_rec_type.status                                 := FND_API.G_MISS_CHAR;
        --cust_prof_rec_type.credit_analyst_id                      := FND_API.G_MISS_NUM;
        cust_prof_rec_type.credit_checking                          := l_hz_imp_acct_prof_stg.credit_checking;
        --cust_prof_rec_type.next_credit_review_date                  := FND_API.G_MISS_DATE;
        cust_prof_rec_type.tolerance                                := l_hz_imp_acct_prof_stg.tolerance;
        cust_prof_rec_type.discount_terms                           := l_hz_imp_acct_prof_stg.discount_terms;
        cust_prof_rec_type.dunning_letters                          := l_hz_imp_acct_prof_stg.dunning_letters;
        cust_prof_rec_type.interest_charges                         := l_hz_imp_acct_prof_stg.interest_charges;
        cust_prof_rec_type.send_statements                          := l_hz_imp_acct_prof_stg.statements;
        cust_prof_rec_type.credit_balance_statements                := l_hz_imp_acct_prof_stg.credit_balance_statements;
        cust_prof_rec_type.credit_hold                              := l_hz_imp_acct_prof_stg.credit_hold;
        cust_prof_rec_type.credit_rating                            := l_hz_imp_acct_prof_stg.credit_rating;
        cust_prof_rec_type.risk_code                                := l_hz_imp_acct_prof_stg.risk_code;
        cust_prof_rec_type.override_terms                           := l_hz_imp_acct_prof_stg.override_terms;
        cust_prof_rec_type.interest_period_days                     := l_hz_imp_acct_prof_stg.interest_period_days;
        cust_prof_rec_type.payment_grace_days                       := l_hz_imp_acct_prof_stg.payment_grace_days;
        cust_prof_rec_type.discount_grace_days                      := l_hz_imp_acct_prof_stg.discount_grace_days;
        cust_prof_rec_type.account_status                           := l_hz_imp_acct_prof_stg.account_status;
        cust_prof_rec_type.percent_collectable                      := l_hz_imp_acct_prof_stg.percent_collectable;
        cust_prof_rec_type.attribute_category                       := l_hz_imp_acct_prof_stg.attribute_category;
        cust_prof_rec_type.attribute1                               := l_hz_imp_acct_prof_stg.attribute1;
        cust_prof_rec_type.attribute2                               := l_hz_imp_acct_prof_stg.attribute2;
        cust_prof_rec_type.attribute3                               := l_hz_imp_acct_prof_stg.attribute3;
        cust_prof_rec_type.attribute4                               := l_hz_imp_acct_prof_stg.attribute4;
        cust_prof_rec_type.attribute5                               := l_hz_imp_acct_prof_stg.attribute5;
        cust_prof_rec_type.attribute6                               := l_hz_imp_acct_prof_stg.attribute6;
        cust_prof_rec_type.attribute7                               := l_hz_imp_acct_prof_stg.attribute7;
        cust_prof_rec_type.attribute8                               := l_hz_imp_acct_prof_stg.attribute8;
        cust_prof_rec_type.attribute9                               := l_hz_imp_acct_prof_stg.attribute9;
        cust_prof_rec_type.attribute10                              := l_hz_imp_acct_prof_stg.attribute10;
        cust_prof_rec_type.attribute11                              := l_hz_imp_acct_prof_stg.attribute11;
        cust_prof_rec_type.attribute12                              := l_hz_imp_acct_prof_stg.attribute12;
        cust_prof_rec_type.attribute13                              := l_hz_imp_acct_prof_stg.attribute13;
        cust_prof_rec_type.attribute14                              := l_hz_imp_acct_prof_stg.attribute14;
        cust_prof_rec_type.attribute15                              := l_hz_imp_acct_prof_stg.attribute15;
        --cust_prof_rec_type.auto_rec_incl_disputed_flag              := l_hz_imp_acct_prof_stg.auto_rec_incl_disputed_flag;
        cust_prof_rec_type.tax_printing_option                      := l_hz_imp_acct_prof_stg.tax_printing_option;
        cust_prof_rec_type.charge_on_finance_charge_flag            := l_hz_imp_acct_prof_stg.charge_on_finance_charge_flag;
        cust_prof_rec_type.clearing_days                            := l_hz_imp_acct_prof_stg.clearing_days;
        cust_prof_rec_type.jgzz_attribute_category                  := l_hz_imp_acct_prof_stg.gdf_cust_prof_attr_cat;
        cust_prof_rec_type.jgzz_attribute1                          := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute1;
        cust_prof_rec_type.jgzz_attribute2                          := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute2;
        cust_prof_rec_type.jgzz_attribute3                          := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute3;
        cust_prof_rec_type.jgzz_attribute4                          := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute4;
        cust_prof_rec_type.jgzz_attribute5                          := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute5;
        cust_prof_rec_type.jgzz_attribute6                          := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute6;
        cust_prof_rec_type.jgzz_attribute7                          := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute7;
        cust_prof_rec_type.jgzz_attribute8                          := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute8;
        cust_prof_rec_type.jgzz_attribute9                          := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute9;
        cust_prof_rec_type.jgzz_attribute10                         := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute10;
        cust_prof_rec_type.jgzz_attribute11                         := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute11;
        cust_prof_rec_type.jgzz_attribute12                         := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute12;
        cust_prof_rec_type.jgzz_attribute13                         := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute13;
        cust_prof_rec_type.jgzz_attribute14                         := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute14;
        cust_prof_rec_type.jgzz_attribute15                         := l_hz_imp_acct_prof_stg.gdf_cust_prof_attribute15;
        cust_prof_rec_type.global_attribute1                        := l_hz_imp_acct_prof_stg.global_attribute1;
        cust_prof_rec_type.global_attribute2                        := l_hz_imp_acct_prof_stg.global_attribute2;
        cust_prof_rec_type.global_attribute3                        := l_hz_imp_acct_prof_stg.global_attribute3;
        cust_prof_rec_type.global_attribute4                        := l_hz_imp_acct_prof_stg.global_attribute4;
        cust_prof_rec_type.global_attribute5                        := l_hz_imp_acct_prof_stg.global_attribute5;
        cust_prof_rec_type.global_attribute6                        := l_hz_imp_acct_prof_stg.global_attribute6;
        cust_prof_rec_type.global_attribute7                        := l_hz_imp_acct_prof_stg.global_attribute7;
        cust_prof_rec_type.global_attribute8                        := l_hz_imp_acct_prof_stg.global_attribute8;
        cust_prof_rec_type.global_attribute9                        := l_hz_imp_acct_prof_stg.global_attribute9;
        cust_prof_rec_type.global_attribute10                       := l_hz_imp_acct_prof_stg.global_attribute10;
        cust_prof_rec_type.global_attribute11                       := l_hz_imp_acct_prof_stg.global_attribute11;
        cust_prof_rec_type.global_attribute12                       := l_hz_imp_acct_prof_stg.global_attribute12;
        cust_prof_rec_type.global_attribute13                       := l_hz_imp_acct_prof_stg.global_attribute13;
        cust_prof_rec_type.global_attribute14                       := l_hz_imp_acct_prof_stg.global_attribute14;
        cust_prof_rec_type.global_attribute15                       := l_hz_imp_acct_prof_stg.global_attribute15;
        cust_prof_rec_type.global_attribute16                       := l_hz_imp_acct_prof_stg.global_attribute16;
        cust_prof_rec_type.global_attribute17                       := l_hz_imp_acct_prof_stg.global_attribute17;
        cust_prof_rec_type.global_attribute18                       := l_hz_imp_acct_prof_stg.global_attribute18;
        cust_prof_rec_type.global_attribute19                       := l_hz_imp_acct_prof_stg.global_attribute19;
        cust_prof_rec_type.global_attribute20                       := l_hz_imp_acct_prof_stg.global_attribute20;
        cust_prof_rec_type.global_attribute_category                := l_hz_imp_acct_prof_stg.global_attribute_category;
        cust_prof_rec_type.cons_inv_flag                            := l_hz_imp_acct_prof_stg.cons_inv_flag;
        cust_prof_rec_type.cons_inv_type                            := l_hz_imp_acct_prof_stg.cons_inv_type;
        --Added by Shubhashree to add the bill_level 12-11-2013
        cust_prof_rec_type.cons_bill_level                          := UPPER(l_hz_imp_acct_prof_stg.cons_bill_level);
        IF l_hz_imp_acct_prof_stg.cons_inv_flag = 'Y' THEN
           cust_prof_rec_type.override_terms                           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char('Y');
        ELSE
           cust_prof_rec_type.override_terms                           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char('N');
        END IF;
        cust_prof_rec_type.lockbox_matching_option                  := l_hz_imp_acct_prof_stg.lockbox_matching_option;
        cust_prof_rec_type.created_by_module                        := l_hz_imp_acct_prof_stg.created_by_module;
        cust_prof_rec_type.application_id                           := gn_application_id;
        --cust_prof_rec_type.review_cycle                             := FND_API.G_MISS_CHAR;
        --cust_prof_rec_type.last_credit_review_date                  := FND_API.G_MISS_DATE;
        cust_prof_rec_type.credit_classification                    := l_hz_imp_acct_prof_stg.credit_classification;

    END IF;


    IF lb_profile_create_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||': Cannot create/update account profile - Error occurred');
        RETURN;
    END IF;

    log_debug_msg(CHR(10)||'===============================================');
    log_debug_msg('Key attribute values of customer profile record');
    log_debug_msg('===============================================');

    --log_debug_msg('cust_account_id = '||cust_prof_rec_type.cust_account_id);
    log_debug_msg('party_id = '||cust_prof_rec_type.party_id);
    log_debug_msg('site_use_id = '||cust_prof_rec_type.site_use_id);
    log_debug_msg('credit_checking = '||cust_prof_rec_type.credit_checking);
    log_debug_msg('tolerance = '||cust_prof_rec_type.tolerance);
    log_debug_msg('discount_terms = '||cust_prof_rec_type.discount_terms);
    log_debug_msg('dunning_letters = '||cust_prof_rec_type.dunning_letters);
    log_debug_msg('interest_charges = '||cust_prof_rec_type.interest_charges);
    log_debug_msg('send_statements = '||cust_prof_rec_type.send_statements);
    log_debug_msg('credit_balance_statements = '||cust_prof_rec_type.credit_balance_statements);
    log_debug_msg('credit_hold = '||cust_prof_rec_type.credit_hold);
    log_debug_msg('auto_rec_incl_disputed_flag = '||cust_prof_rec_type.auto_rec_incl_disputed_flag);

    IF lb_profile_update = TRUE THEN

        -------------------------------
        --Updating the customer profile
        -------------------------------


        -----------------------------
        -- Get Object Version Number
        -----------------------------

        BEGIN

            ln_object_version_number := NULL;

            SELECT  object_version_number
            INTO    ln_object_version_number
            FROM    hz_customer_profiles
            WHERE   cust_account_profile_id = lc_profile_id;

        EXCEPTION
           WHEN OTHERS THEN
            log_debug_msg(lc_procedure_name||': Error while fetching object_version_number for cust_account_profile_id - '||cust_prof_rec_type.cust_account_profile_id);
            log_debug_msg(lc_procedure_name||': Error - '||SQLERRM);
            lc_staging_column_name                  := 'account_orig_system_reference';
            lc_staging_column_value                 := l_hz_imp_acct_prof_stg.account_orig_system_reference;
            lc_exception_log                        := 'Error while fetching object_version_number for cust_account_profile_id - '||cust_prof_rec_type.cust_account_profile_id;
            lc_oracle_error_msg                     := 'Error while fetching object_version_number for cust_account_profile_id - '||cust_prof_rec_type.cust_account_profile_id;
            log_exception
                (
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
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
        
        --V1.5, to capture the standard terms before it wiped out
        log_debug_msg('ln_standard_terms= '||ln_standard_terms);
        BEGIN
          SELECT standard_terms
          INTO ln_new_standard_terms
          FROM hz_customer_profiles
          WHERE cust_account_profile_id = cust_prof_rec_type.cust_account_profile_id;
          log_debug_msg('ln_new_standard_terms: '||ln_new_standard_terms);
        EXCEPTION
        WHEN OTHERS THEN
          log_debug_msg('Error while fetching Standard Terms: '||SQLERRM);
        END;
        --V1.5 partly end
  
        
        hz_customer_profile_v2pub.update_customer_profile
            (
                p_init_msg_list             => FND_API.G_TRUE,
                p_customer_profile_rec      => cust_prof_rec_type,
                p_object_version_number     => ln_object_version_number,
                x_return_status             => lc_prof_return_status,
                x_msg_count                 => ln_msg_count,
                x_msg_data                  => lc_msg_data
            );

        x_prof_return_status := lc_prof_return_status;

        log_debug_msg(CHR(10)||'============================================');
        log_debug_msg('After calling update_customer_profile');
        log_debug_msg('=========================================');
        log_debug_msg('lc_prof_return_status = '||lc_prof_return_status);

        IF(x_prof_return_status = 'S') THEN
            log_debug_msg(CHR(10)||'Customer Profile is successfully updated !!!');
            
        --V1.5 if standard terms passed NULL then only calling 
        IF cust_prof_rec_type.standard_terms IS NULL THEN
        BEGIN
          SELECT object_version_number
          INTO ln_new_object_version_number
          FROM hz_customer_profiles
          WHERE cust_account_profile_id = cust_prof_rec_type.cust_account_profile_id;
          
          log_debug_msg('ln_new_object_version_number: '||ln_new_object_version_number);
          cust_prof_rec_type.standard_terms := ln_new_standard_terms;
          
          hz_customer_profile_v2pub.update_customer_profile
            (
                p_init_msg_list             => FND_API.G_TRUE,
                p_customer_profile_rec      => cust_prof_rec_type,
                p_object_version_number     => ln_object_version_number,
                x_return_status             => lc_prof_return_status,
                x_msg_count                 => ln_msg_count,
                x_msg_data                  => lc_msg_data
            );
            x_prof_return_status := lc_prof_return_status;
          IF(x_prof_return_status = 'S') THEN
            log_debug_msg(CHR(10)||'Customer Profile is successfully updated for Standard Terms!!!');            
        ELSE
            log_debug_msg(CHR(10)||'Customer Profile is not updated for Standard Terms!!!');
            IF ln_msg_count >= 1 THEN
                log_debug_msg(CHR(10)||lc_procedure_name||': Errors in creating Customer Profile');
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
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => 'RECORD_ID'
                   ,p_staging_column_value          => l_hz_imp_acct_prof_stg.record_id
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => XX_CDH_CONV_MASTER_PKG.trim_input_msg(l_msg_text)
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        END IF;   
          
        EXCEPTION
        WHEN OTHERS THEN
          log_debug_msg('Error while fetching Standard Terms: '||SQLERRM);
        END;
        END IF;        
        --V1.5 complete end 
            
        ELSE
            log_debug_msg(CHR(10)||'Customer Profile is not updated !!!');
            IF ln_msg_count >= 1 THEN
                log_debug_msg(CHR(10)||lc_procedure_name||': Errors in creating Customer Profile');
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
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => 'RECORD_ID'
                   ,p_staging_column_value          => l_hz_imp_acct_prof_stg.record_id
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => XX_CDH_CONV_MASTER_PKG.trim_input_msg(l_msg_text)
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        END IF;

    ELSE

        -------------------------------
        --Updating the customer profile
        -------------------------------

        hz_customer_profile_v2pub.create_customer_profile
            (
                p_init_msg_list              => FND_API.G_TRUE,
                p_customer_profile_rec       => cust_prof_rec_type,
                p_create_profile_amt         => FND_API.G_TRUE,
                x_cust_account_profile_id    => ln_cust_prof_id,
                x_return_status              => lc_prof_return_status,
                x_msg_count                  => ln_msg_count,
                x_msg_data                   => lc_msg_data
           );

        x_prof_return_status := lc_prof_return_status;

        log_debug_msg(CHR(10)||'============================================');
        log_debug_msg('After calling create_customer_profile API');
        log_debug_msg('=========================================');
        log_debug_msg('ln_cust_prof_id = '||ln_cust_prof_id);
        log_debug_msg('x_prof_return_status = '||x_prof_return_status);

        IF(x_prof_return_status = 'S') THEN
            log_debug_msg(CHR(10)||'Customer Profile is successfully created !!!');
        ELSE
            log_debug_msg(CHR(10)||'Customer Profile is not created !!!');

            IF ln_msg_count >= 1 THEN
                log_debug_msg(CHR(10)||lc_procedure_name||': Errors in creating Customer Profile');
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
                    p_conversion_id                 => ln_conversion_prof_id
                   ,p_record_control_id             => l_hz_imp_acct_prof_stg.record_id
                   ,p_source_system_code            => l_hz_imp_acct_prof_stg.account_orig_system
                   ,p_source_system_ref             => l_hz_imp_acct_prof_stg.account_orig_system_reference
                   ,p_procedure_name                => lc_procedure_name
                   ,p_staging_table_name            => lc_staging_table_name
                   ,p_staging_column_name           => 'RECORD_ID'
                   ,p_staging_column_value          => l_hz_imp_acct_prof_stg.record_id
                   ,p_batch_id                      => gn_batch_id
                   ,p_exception_log                 => XX_CDH_CONV_MASTER_PKG.trim_input_msg(l_msg_text)
                   ,p_oracle_error_code             => SQLCODE
                   ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        END IF;

    END IF;

EXCEPTION
WHEN OTHERS THEN
    log_debug_msg(lc_procedure_name||': Record_id = '||l_hz_imp_acct_prof_stg.record_id||': Others Exception'||SQLERRM);

END create_profile;


-- +===================================================================+
-- | Name        : create_profile_amount                               |
-- |                                                                   |
-- | Description : Procdedure to create a new customer profile amount  |
-- |                                                                   |
-- | Parameters  : l_hz_imp_prof_amt_stg                               |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_profile_amount
    (
         l_hz_imp_prof_amt_stg          IN      XXOD_HZ_IMP_ACCOUNT_PROF_STG%ROWTYPE
        ,x_prof_amt_id                  OUT     NUMBER
        ,x_prof_amt_return_status       OUT     VARCHAR2
    )

AS

    cust_prof_amt_rec_type      HZ_CUSTOMER_PROFILE_V2PUB.CUST_PROFILE_AMT_REC_TYPE;
    ln_owner_table_id           HZ_ORIG_SYS_REFERENCES.OWNER_TABLE_ID%TYPE;
    ln_cust_prof_amt_id         NUMBER := NULL;
    lc_prof_amt_return_status   VARCHAR(1);
    ln_msg_count                NUMBER;
    lc_msg_data                 VARCHAR2(2000);
    ln_conversion_prof_amt_id   NUMBER := 00243.2;
    lc_procedure_name           VARCHAR2(32) := 'Create_Profile_Amount';
    lc_staging_table_name       VARCHAR2(32) := 'XXOD_HZ_IMP_ACCOUNT_PROF_STG';
    lc_staging_column_name      VARCHAR2(32);
    lc_staging_column_value     VARCHAR2(500);
    lc_exception_log            VARCHAR2(2000);
    lc_oracle_error_msg         VARCHAR2(2000);
    ln_retcode                  NUMBER;
    ln_errbuf                   VARCHAR2(2000);
    lc_status                   VARCHAR2(3);
    ln_party_id                 NUMBER;

    lb_profile_amt_flag         BOOLEAN := TRUE;
    lb_profile_amt_update       BOOLEAN := FALSE;
    ln_object_version_number    NUMBER;
    l_msg_text                  VARCHAR2(4200);

BEGIN

    x_prof_amt_return_status := 'E';
    cust_prof_amt_rec_type.cust_acct_profile_amt_id                 := NULL;
    cust_prof_amt_rec_type.cust_account_profile_id                  := NULL;
    log_debug_msg('ACCOUNT_ORIG_SYSTEM = '||l_hz_imp_prof_amt_stg.account_orig_system);
    log_debug_msg('ACCOUNT_ORIG_SYSTEM_REFERENCE = '||l_hz_imp_prof_amt_stg.account_orig_system_reference);

    IF l_hz_imp_prof_amt_stg.party_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_orig_system is NULL');
        lc_staging_column_name                  := 'party_orig_system';
        lc_staging_column_value                 := l_hz_imp_prof_amt_stg.party_orig_system;
        lc_exception_log                        := 'party_orig_system is NULL';
        lc_oracle_error_msg                     := 'party_orig_system is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_amt_id
               ,p_record_control_id             => l_hz_imp_prof_amt_stg.record_id
               ,p_source_system_code            => l_hz_imp_prof_amt_stg.party_orig_system
               ,p_source_system_ref             => l_hz_imp_prof_amt_stg.party_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_profile_amt_flag := FALSE;
    END IF;

    IF l_hz_imp_prof_amt_stg.party_orig_system_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': party_orig_system_reference is NULL');
        lc_staging_column_name                  := 'party_orig_system_reference';
        lc_staging_column_value                 := l_hz_imp_prof_amt_stg.party_orig_system_reference;
        lc_exception_log                        := 'party_orig_system_reference is NULL ';
        lc_oracle_error_msg                     := 'party_orig_system_reference is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_amt_id
               ,p_record_control_id             => l_hz_imp_prof_amt_stg.record_id
               ,p_source_system_code            => l_hz_imp_prof_amt_stg.party_orig_system
               ,p_source_system_ref             => l_hz_imp_prof_amt_stg.party_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_profile_amt_flag := FALSE;
    END IF;


   IF l_hz_imp_prof_amt_stg.account_orig_system IS NULL THEN
        log_debug_msg(lc_procedure_name||': account_orig_system is NULL');
        lc_staging_column_name                  := 'account_orig_system';
        lc_staging_column_value                 := l_hz_imp_prof_amt_stg.account_orig_system;
        lc_exception_log                        := 'account_orig_system is NULL';
        lc_oracle_error_msg                     := 'account_orig_system is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_amt_id
               ,p_record_control_id             => l_hz_imp_prof_amt_stg.record_id
               ,p_source_system_code            => l_hz_imp_prof_amt_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_prof_amt_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_profile_amt_flag := FALSE;
    END IF;

    IF l_hz_imp_prof_amt_stg.account_orig_system_reference IS NULL THEN
        log_debug_msg(lc_procedure_name||': account_orig_system_reference is NULL');
        lc_staging_column_name                  := 'account_orig_system_reference';
        lc_staging_column_value                 := l_hz_imp_prof_amt_stg.account_orig_system_reference;
        lc_exception_log                        := 'account_orig_system_reference is NULL ';
        lc_oracle_error_msg                     := 'account_orig_system_reference is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_amt_id
               ,p_record_control_id             => l_hz_imp_prof_amt_stg.record_id
               ,p_source_system_code            => l_hz_imp_prof_amt_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_prof_amt_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_profile_amt_flag := FALSE;
    END IF;

    IF l_hz_imp_prof_amt_stg.party_orig_system IS NOT NULL AND l_hz_imp_prof_amt_stg.party_orig_system_reference IS NOT NULL THEN
        XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
            (
                 p_orig_system         => l_hz_imp_prof_amt_stg.party_orig_system
                ,p_orig_sys_reference  => l_hz_imp_prof_amt_stg.party_orig_system_reference
                ,p_owner_table_name    => 'HZ_PARTIES'
                ,x_owner_table_id      => ln_party_id
                ,x_retcode             => ln_retcode
                ,x_errbuf              => ln_errbuf
            );
    END IF;

    IF l_hz_imp_prof_amt_stg.account_orig_system IS NOT NULL AND l_hz_imp_prof_amt_stg.account_orig_system_reference IS NOT NULL THEN
        XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
            (
                 p_orig_system         => l_hz_imp_prof_amt_stg.account_orig_system
                ,p_orig_sys_reference  => l_hz_imp_prof_amt_stg.account_orig_system_reference
                ,p_owner_table_name    => 'HZ_CUST_ACCOUNTS'
                ,x_owner_table_id      => ln_owner_table_id
                ,x_retcode             => ln_retcode
                ,x_errbuf              => ln_errbuf
            );
    END IF;

    IF(ln_owner_table_id IS NULL ) THEN
        log_debug_msg(lc_procedure_name||': account_id is not found');
        lc_staging_column_name                  := 'account_orig_system_reference';
        lc_staging_column_value                 := l_hz_imp_prof_amt_stg.account_orig_system_reference;
        lc_exception_log                        := 'cust_account_id is not found';
        lc_oracle_error_msg                     := 'cust_account_id is not found';
        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_amt_id
               ,p_record_control_id             => l_hz_imp_prof_amt_stg.record_id
               ,p_source_system_code            => l_hz_imp_prof_amt_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_prof_amt_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_profile_amt_flag := FALSE;
    ELSE
        cust_prof_amt_rec_type.cust_account_id  := ln_owner_table_id;
    END IF;



    cust_prof_amt_rec_type.cust_account_profile_id:= is_customer_profile_exists(
                cust_prof_amt_rec_type.cust_account_id);

    IF cust_prof_amt_rec_type.cust_account_profile_id IS NULL THEN
        log_debug_msg(lc_procedure_name||': Customer account profile id  is not found');
        lc_staging_column_name                  := 'account_orig_system_reference';
        lc_staging_column_value                 := l_hz_imp_prof_amt_stg.account_orig_system_reference;
        lc_exception_log                        := 'Customer account profile id  is not found';
        lc_oracle_error_msg                     := 'Customer account profile id  is not found';
        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_amt_id
               ,p_record_control_id             => l_hz_imp_prof_amt_stg.record_id
               ,p_source_system_code            => l_hz_imp_prof_amt_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_prof_amt_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_profile_amt_flag := FALSE;
    END IF;

    cust_prof_amt_rec_type.currency_code                            := l_hz_imp_prof_amt_stg.currency_code;
    IF cust_prof_amt_rec_type.currency_code IS NULL THEN
        log_debug_msg(lc_procedure_name||': currency_code is NULL');
        lc_staging_column_name                  := 'currency_code';
        lc_staging_column_value                 := cust_prof_amt_rec_type.currency_code;
        lc_exception_log                        := 'currency_code is NULL';
        lc_oracle_error_msg                     := 'currency_code is NULL';
        log_exception
            (
                p_conversion_id                 => ln_conversion_prof_amt_id
               ,p_record_control_id             => l_hz_imp_prof_amt_stg.record_id
               ,p_source_system_code            => l_hz_imp_prof_amt_stg.account_orig_system
               ,p_source_system_ref             => l_hz_imp_prof_amt_stg.account_orig_system_reference
               ,p_procedure_name                => lc_procedure_name
               ,p_staging_table_name            => lc_staging_table_name
               ,p_staging_column_name           => lc_staging_column_name
               ,p_staging_column_value          => lc_staging_column_value
               ,p_batch_id                      => gn_batch_id
               ,p_exception_log                 => lc_exception_log
               ,p_oracle_error_code             => SQLCODE
               ,p_oracle_error_msg              => lc_oracle_error_msg
            );
        lb_profile_amt_flag := FALSE;
    END IF;

    IF cust_prof_amt_rec_type.cust_account_profile_id IS NOT NULL AND cust_prof_amt_rec_type.currency_code IS NOT NULL THEN
        ln_cust_prof_amt_id := is_profile_amt_exists
            (
                cust_prof_amt_rec_type.cust_account_profile_id,
                cust_prof_amt_rec_type.currency_code
            );


            IF  ln_cust_prof_amt_id IS NOT NULL AND
                ln_cust_prof_amt_id = 0 THEN

                Log_Debug_Msg(lc_procedure_name||':account_orig_system_reference returns more than one profile_id');
                lc_staging_column_name                  := 'account_orig_system_reference';
                lc_staging_column_value                 := l_hz_imp_prof_amt_stg.account_orig_system_reference;
                lc_exception_log                        := 'account_orig_system_reference returns more than one profile_id';
                lc_oracle_error_msg                     := 'account_orig_system_reference returns more than one profile_id';
                log_exception
                    (
                        p_conversion_id                 => ln_conversion_prof_amt_id
                       ,p_record_control_id             => l_hz_imp_prof_amt_stg.record_id
                       ,p_source_system_code            => l_hz_imp_prof_amt_stg.account_orig_system
                       ,p_source_system_ref             => l_hz_imp_prof_amt_stg.account_orig_system_reference
                       ,p_procedure_name                => lc_procedure_name
                       ,p_staging_table_name            => lc_staging_table_name
                       ,p_staging_column_name           => lc_staging_column_name
                       ,p_staging_column_value          => lc_staging_column_value
                       ,p_batch_id                      => gn_batch_id
                       ,p_exception_log                 => lc_exception_log
                       ,p_oracle_error_code             => SQLCODE
                       ,p_oracle_error_msg              => lc_oracle_error_msg
                    );

                lb_profile_amt_flag := FALSE;

            END IF;



            IF  ln_cust_prof_amt_id IS NOT NULL AND
                ln_cust_prof_amt_id <> 0 THEN

                --------------------------
                -- Update profile amount
                --------------------------

                log_debug_msg(lc_procedure_name||': Customer profile amount already exists');
                log_debug_msg(lc_procedure_name||': Updating profile amount (profile_amount_id) = '||ln_cust_prof_amt_id);

                lb_profile_amt_update := TRUE;

                cust_prof_amt_rec_type.cust_acct_profile_amt_id     := ln_cust_prof_amt_id;

                IF TRIM(l_hz_imp_prof_amt_stg.trx_credit_limit) <> 0 THEN
                   cust_prof_amt_rec_type.trx_credit_limit             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_prof_amt_stg.trx_credit_limit);
                END IF;

                IF TRIM(l_hz_imp_prof_amt_stg.overall_credit_limit) <> 0 THEN
                   cust_prof_amt_rec_type.overall_credit_limit         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_prof_amt_stg.overall_credit_limit);
                END IF;

                cust_prof_amt_rec_type.min_dunning_amount           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_prof_amt_stg.min_dunning_amount);
                cust_prof_amt_rec_type.min_dunning_invoice_amount   := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_prof_amt_stg.min_dunning_invoice_amount);
                cust_prof_amt_rec_type.max_interest_charge          := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_prof_amt_stg.max_interest_charge);
                cust_prof_amt_rec_type.min_statement_amount         := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_prof_amt_stg.min_statement_amount);
                cust_prof_amt_rec_type.auto_rec_min_receipt_amount  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_prof_amt_stg.auto_rec_min_receipt_amount);
                cust_prof_amt_rec_type.interest_rate                := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_prof_amt_stg.interest_rate);
                cust_prof_amt_rec_type.attribute_category           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute_category);
                cust_prof_amt_rec_type.attribute1                   := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute1);
                cust_prof_amt_rec_type.attribute2                   := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute2);
                cust_prof_amt_rec_type.attribute3                   := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute3);
                cust_prof_amt_rec_type.attribute4                   := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute4);
                cust_prof_amt_rec_type.attribute5                   := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute5);
                cust_prof_amt_rec_type.attribute6                   := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute6);
                cust_prof_amt_rec_type.attribute7                   := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute7);
                cust_prof_amt_rec_type.attribute8                   := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute8);
                cust_prof_amt_rec_type.attribute9                   := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute9);
                cust_prof_amt_rec_type.attribute10                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute10);
                cust_prof_amt_rec_type.attribute11                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute11);
                cust_prof_amt_rec_type.attribute12                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute12);
                cust_prof_amt_rec_type.attribute13                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute13);
                cust_prof_amt_rec_type.attribute14                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute14);
                cust_prof_amt_rec_type.attribute15                  := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.amount_attribute15);
                cust_prof_amt_rec_type.min_fc_balance_amount        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_prof_amt_stg.min_fc_balance_amount);
                cust_prof_amt_rec_type.min_fc_invoice_amount        := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_num(l_hz_imp_prof_amt_stg.min_fc_invoice_amount);
                -- cust_prof_amt_rec_type.jgzz_attribute_category      := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attr_cat);
                -- cust_prof_amt_rec_type.jgzz_attribute1              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute1);
                -- cust_prof_amt_rec_type.jgzz_attribute2              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute2);
                -- cust_prof_amt_rec_type.jgzz_attribute3              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute3);
                -- cust_prof_amt_rec_type.jgzz_attribute4              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute4);
                -- cust_prof_amt_rec_type.jgzz_attribute5              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute5);
                -- cust_prof_amt_rec_type.jgzz_attribute6              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute6);
                -- cust_prof_amt_rec_type.jgzz_attribute7              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute7);
                -- cust_prof_amt_rec_type.jgzz_attribute8              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute8);
                -- cust_prof_amt_rec_type.jgzz_attribute9              := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute9);
                -- cust_prof_amt_rec_type.jgzz_attribute10             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute10);
                -- cust_prof_amt_rec_type.jgzz_attribute11             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute11);
                -- cust_prof_amt_rec_type.jgzz_attribute12             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute12);
                -- cust_prof_amt_rec_type.jgzz_attribute13             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute13);
                -- cust_prof_amt_rec_type.jgzz_attribute14             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute14);
                -- cust_prof_amt_rec_type.jgzz_attribute15             := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute15);
                -- cust_prof_amt_rec_type.global_attribute1            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute1);
                -- cust_prof_amt_rec_type.global_attribute2            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute2);
                -- cust_prof_amt_rec_type.global_attribute3            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute3);
                -- cust_prof_amt_rec_type.global_attribute4            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute4);
                -- cust_prof_amt_rec_type.global_attribute5            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute5);
                -- cust_prof_amt_rec_type.global_attribute6            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute6);
                -- cust_prof_amt_rec_type.global_attribute7            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute7);
                -- cust_prof_amt_rec_type.global_attribute8            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute8);
                -- cust_prof_amt_rec_type.global_attribute9            := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute9);
                -- cust_prof_amt_rec_type.global_attribute10           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute10);
                -- cust_prof_amt_rec_type.global_attribute11           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute11);
                -- cust_prof_amt_rec_type.global_attribute12           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute12);
                -- cust_prof_amt_rec_type.global_attribute13           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute13);
                -- cust_prof_amt_rec_type.global_attribute14           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute14);
                -- cust_prof_amt_rec_type.global_attribute15           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute15);
                -- cust_prof_amt_rec_type.global_attribute16           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute16);
                -- cust_prof_amt_rec_type.global_attribute17           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute17);
                -- cust_prof_amt_rec_type.global_attribute18           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute18);
                -- cust_prof_amt_rec_type.global_attribute19           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute19);
                -- cust_prof_amt_rec_type.global_attribute20           := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute20);
                -- cust_prof_amt_rec_type.global_attribute_category    := xx_cdh_conv_master_pkg.get_hz_imp_g_miss_char(l_hz_imp_prof_amt_stg.global_attribute_category);


            ELSE

                -------------------------
                -- Create profile amount
                -------------------------

                log_debug_msg(lc_procedure_name||': Creating a new customer profile amount ');

                IF TRIM(l_hz_imp_prof_amt_stg.trx_credit_limit) <> 0 THEN
                    cust_prof_amt_rec_type.trx_credit_limit                         := l_hz_imp_prof_amt_stg.trx_credit_limit;
                END IF;

                IF TRIM(l_hz_imp_prof_amt_stg.overall_credit_limit) <> 0 THEN
                    cust_prof_amt_rec_type.overall_credit_limit                     := l_hz_imp_prof_amt_stg.overall_credit_limit;
                END IF;

                cust_prof_amt_rec_type.min_dunning_amount                       := l_hz_imp_prof_amt_stg.min_dunning_amount;
                cust_prof_amt_rec_type.min_dunning_invoice_amount               := l_hz_imp_prof_amt_stg.min_dunning_invoice_amount;
                cust_prof_amt_rec_type.max_interest_charge                      := l_hz_imp_prof_amt_stg.max_interest_charge;
                cust_prof_amt_rec_type.min_statement_amount                     := l_hz_imp_prof_amt_stg.min_statement_amount;
                cust_prof_amt_rec_type.auto_rec_min_receipt_amount              := l_hz_imp_prof_amt_stg.auto_rec_min_receipt_amount;
                cust_prof_amt_rec_type.interest_rate                            := l_hz_imp_prof_amt_stg.interest_rate;
                cust_prof_amt_rec_type.attribute_category                       := l_hz_imp_prof_amt_stg.amount_attribute_category;
                cust_prof_amt_rec_type.attribute1                               := l_hz_imp_prof_amt_stg.amount_attribute1;
                cust_prof_amt_rec_type.attribute2                               := l_hz_imp_prof_amt_stg.amount_attribute2;
                cust_prof_amt_rec_type.attribute3                               := l_hz_imp_prof_amt_stg.amount_attribute3;
                cust_prof_amt_rec_type.attribute4                               := l_hz_imp_prof_amt_stg.amount_attribute4;
                cust_prof_amt_rec_type.attribute5                               := l_hz_imp_prof_amt_stg.amount_attribute5;
                cust_prof_amt_rec_type.attribute6                               := l_hz_imp_prof_amt_stg.amount_attribute6;
                cust_prof_amt_rec_type.attribute7                               := l_hz_imp_prof_amt_stg.amount_attribute7;
                cust_prof_amt_rec_type.attribute8                               := l_hz_imp_prof_amt_stg.amount_attribute8;
                cust_prof_amt_rec_type.attribute9                               := l_hz_imp_prof_amt_stg.amount_attribute9;
                cust_prof_amt_rec_type.attribute10                              := l_hz_imp_prof_amt_stg.amount_attribute10;
                cust_prof_amt_rec_type.attribute11                              := l_hz_imp_prof_amt_stg.amount_attribute11;
                cust_prof_amt_rec_type.attribute12                              := l_hz_imp_prof_amt_stg.amount_attribute12;
                cust_prof_amt_rec_type.attribute13                              := l_hz_imp_prof_amt_stg.amount_attribute13;
                cust_prof_amt_rec_type.attribute14                              := l_hz_imp_prof_amt_stg.amount_attribute14;
                cust_prof_amt_rec_type.attribute15                              := l_hz_imp_prof_amt_stg.amount_attribute15;
                cust_prof_amt_rec_type.min_fc_balance_amount                    := l_hz_imp_prof_amt_stg.min_fc_balance_amount;
                cust_prof_amt_rec_type.min_fc_invoice_amount                    := l_hz_imp_prof_amt_stg.min_fc_invoice_amount;
                -- cust_prof_amt_rec_type.site_use_id                              := FND_API.G_MISS_NUM;
                -- cust_prof_amt_rec_type.expiration_date                          := fnd_api.g_miss_date;
                -- cust_prof_amt_rec_type.jgzz_attribute_category                  := l_hz_imp_prof_amt_stg.gdf_cust_prof_attr_cat;
                -- cust_prof_amt_rec_type.jgzz_attribute1                          := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute1;
                -- cust_prof_amt_rec_type.jgzz_attribute2                          := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute2;
                -- cust_prof_amt_rec_type.jgzz_attribute3                          := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute3;
                -- cust_prof_amt_rec_type.jgzz_attribute4                          := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute4;
                -- cust_prof_amt_rec_type.jgzz_attribute5                          := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute5;
                -- cust_prof_amt_rec_type.jgzz_attribute6                          := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute6;
                -- cust_prof_amt_rec_type.jgzz_attribute7                          := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute7;
                -- cust_prof_amt_rec_type.jgzz_attribute8                          := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute8;
                -- cust_prof_amt_rec_type.jgzz_attribute9                          := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute9;
                -- cust_prof_amt_rec_type.jgzz_attribute10                         := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute10;
                -- cust_prof_amt_rec_type.jgzz_attribute11                         := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute11;
                -- cust_prof_amt_rec_type.jgzz_attribute12                         := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute12;
                -- cust_prof_amt_rec_type.jgzz_attribute13                         := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute13;
                -- cust_prof_amt_rec_type.jgzz_attribute14                         := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute14;
                -- cust_prof_amt_rec_type.jgzz_attribute15                         := l_hz_imp_prof_amt_stg.gdf_cust_prof_attribute15;
                -- cust_prof_amt_rec_type.global_attribute1                        := l_hz_imp_prof_amt_stg.global_attribute1;
                -- cust_prof_amt_rec_type.global_attribute2                        := l_hz_imp_prof_amt_stg.global_attribute2;
                -- cust_prof_amt_rec_type.global_attribute3                        := l_hz_imp_prof_amt_stg.global_attribute3;
                -- cust_prof_amt_rec_type.global_attribute4                        := l_hz_imp_prof_amt_stg.global_attribute4;
                -- cust_prof_amt_rec_type.global_attribute5                        := l_hz_imp_prof_amt_stg.global_attribute5;
                -- cust_prof_amt_rec_type.global_attribute6                        := l_hz_imp_prof_amt_stg.global_attribute6;
                -- cust_prof_amt_rec_type.global_attribute7                        := l_hz_imp_prof_amt_stg.global_attribute7;
                -- cust_prof_amt_rec_type.global_attribute8                        := l_hz_imp_prof_amt_stg.global_attribute8;
                -- cust_prof_amt_rec_type.global_attribute9                        := l_hz_imp_prof_amt_stg.global_attribute9;
                -- cust_prof_amt_rec_type.global_attribute10                       := l_hz_imp_prof_amt_stg.global_attribute10;
                -- cust_prof_amt_rec_type.global_attribute11                       := l_hz_imp_prof_amt_stg.global_attribute11;
                -- cust_prof_amt_rec_type.global_attribute12                       := l_hz_imp_prof_amt_stg.global_attribute12;
                -- cust_prof_amt_rec_type.global_attribute13                       := l_hz_imp_prof_amt_stg.global_attribute13;
                -- cust_prof_amt_rec_type.global_attribute14                       := l_hz_imp_prof_amt_stg.global_attribute14;
                -- cust_prof_amt_rec_type.global_attribute15                       := l_hz_imp_prof_amt_stg.global_attribute15;
                -- cust_prof_amt_rec_type.global_attribute16                       := l_hz_imp_prof_amt_stg.global_attribute16;
                -- cust_prof_amt_rec_type.global_attribute17                       := l_hz_imp_prof_amt_stg.global_attribute17;
                -- cust_prof_amt_rec_type.global_attribute18                       := l_hz_imp_prof_amt_stg.global_attribute18;
                -- cust_prof_amt_rec_type.global_attribute19                       := l_hz_imp_prof_amt_stg.global_attribute19;
                -- cust_prof_amt_rec_type.global_attribute20                       := l_hz_imp_prof_amt_stg.global_attribute20;
                -- cust_prof_amt_rec_type.global_attribute_category                := l_hz_imp_prof_amt_stg.global_attribute_category;
                cust_prof_amt_rec_type.created_by_module                        := l_hz_imp_prof_amt_stg.created_by_module;
                cust_prof_amt_rec_type.application_id                           := gn_application_id;
            END IF;
    END IF;


    IF lb_profile_amt_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||':Cannot create profile amount - Error occurred');
        RETURN;
    END IF;

    log_debug_msg(CHR(10)||'===============================================');
    log_debug_msg('Key attribute values of cust_prof_amt_rec_type record');
    log_debug_msg('======================================================');
    log_debug_msg('cust_account_profile_id = '||cust_prof_amt_rec_type.cust_account_profile_id);
    log_debug_msg('currency_code = '||cust_prof_amt_rec_type.currency_code);
    log_debug_msg('cust_account_id = '||cust_prof_amt_rec_type.cust_account_id);

    IF lb_profile_amt_update = TRUE THEN

        ----------------------------------------
        -- Updating customer profile amount
        ----------------------------------------


       -----------------------------
       -- Get Object Version Number
       -----------------------------

        BEGIN

            ln_object_version_number := NULL;

            SELECT  object_version_number
            INTO    ln_object_version_number
            FROM    hz_cust_profile_amts
            WHERE   cust_acct_profile_amt_id = ln_cust_prof_amt_id;

        EXCEPTION
          WHEN OTHERS THEN
           log_debug_msg(lc_procedure_name||': Error while fetching object_version_number for cust_prof_amt_id - '||ln_cust_prof_amt_id);
           log_debug_msg(lc_procedure_name||': Error - '||SQLERRM);
           lc_staging_column_name                  := 'account_orig_system_reference';
           lc_staging_column_value                 := l_hz_imp_prof_amt_stg.account_orig_system_reference;
           lc_exception_log                        := 'Error while fetching object_version_number for cust_prof_amt_id - '||ln_cust_prof_amt_id;
           lc_oracle_error_msg                     := 'Error while fetching object_version_number for cust_prof_amt_id - '||ln_cust_prof_amt_id;
           log_exception
               (
                   p_conversion_id                 => ln_conversion_prof_amt_id
                  ,p_record_control_id             => l_hz_imp_prof_amt_stg.record_id
                  ,p_source_system_code            => l_hz_imp_prof_amt_stg.account_orig_system
                  ,p_source_system_ref             => l_hz_imp_prof_amt_stg.account_orig_system_reference
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

        hz_customer_profile_v2pub.update_cust_profile_amt
            (
                p_init_msg_list             => FND_API.G_TRUE,
                p_cust_profile_amt_rec      => cust_prof_amt_rec_type,
                p_object_version_number     => ln_object_version_number,
                x_return_status             => lc_prof_amt_return_status,
                x_msg_count                 => ln_msg_count,
                x_msg_data                  => lc_msg_data
            );

        x_prof_amt_return_status := lc_prof_amt_return_status;

        log_debug_msg(CHR(10)||'============================================');
        log_debug_msg('After calling update_cust_profile_amt API');
        log_debug_msg('============================================');

        log_debug_msg('lc_prof_amt_return_status = '||lc_prof_amt_return_status);

        IF lc_prof_amt_return_status = 'S' THEN
            log_debug_msg(CHR(10)||'Customer Profile Amount is successfully updated !!!');
        ELSE
            log_debug_msg(CHR(10)||'Customer Profile Amount is not updated !!!');

            IF ln_msg_count >= 1 THEN
                log_debug_msg(CHR(10)||lc_procedure_name||': Errors in updating Customer Profile Amount');
                log_debug_msg('------------------------------------------------------------------');
                FOR I IN 1..ln_msg_count
                LOOP
                    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                    Log_Debug_Msg('Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                END LOOP;
                log_debug_msg('------------------------------------------------------------------'||CHR(10));
            END IF;
            log_exception
               (
                   p_conversion_id                 => ln_conversion_prof_amt_id
                  ,p_record_control_id             => l_hz_imp_prof_amt_stg.record_id
                  ,p_source_system_code            => l_hz_imp_prof_amt_stg.account_orig_system
                  ,p_source_system_ref             => l_hz_imp_prof_amt_stg.account_orig_system_reference
                  ,p_procedure_name                => lc_procedure_name
                  ,p_staging_table_name            => lc_staging_table_name
                  ,p_staging_column_name           => 'RECORD_ID'
                  ,p_staging_column_value          => l_hz_imp_prof_amt_stg.record_id
                  ,p_batch_id                      => gn_batch_id
                  ,p_exception_log                 => XX_CDH_CONV_MASTER_PKG.trim_input_msg(l_msg_text)
                  ,p_oracle_error_code             => SQLCODE
                  ,p_oracle_error_msg              => lc_oracle_error_msg
           );
        END IF;

    ELSE

        ------------------------------------------
        -- Creating a new customer profile amount
        ------------------------------------------

        hz_customer_profile_v2pub.create_cust_profile_amt
            (
                p_init_msg_list              => FND_API.G_TRUE,
                p_check_foreign_key          => FND_API.G_TRUE,
                p_cust_profile_amt_rec       => cust_prof_amt_rec_type,
                x_cust_acct_profile_amt_id   => ln_cust_prof_amt_id,
                x_return_status              => lc_prof_amt_return_status,
                x_msg_count                  => ln_msg_count,
                x_msg_data                   => lc_msg_data
            );

        x_prof_amt_id               := ln_cust_prof_amt_id;
        x_prof_amt_return_status    := lc_prof_amt_return_status;

        log_debug_msg(CHR(10)||'============================================');
        log_debug_msg('After calling create_cust_profile_amt API');
        log_debug_msg('============================================');
        log_debug_msg('ln_cust_prof_amt_id = '||ln_cust_prof_amt_id);
        log_debug_msg('lc_prof_amt_return_status = '||lc_prof_amt_return_status);

        IF lc_prof_amt_return_status = 'S' THEN
            log_debug_msg(CHR(10)||'Customer Profile Amount is successfully created !!!');
        ELSE
            log_debug_msg(CHR(10)||'Customer Profile Amount is not created !!!');

            IF ln_msg_count >= 1 THEN
                log_debug_msg(CHR(10)||lc_procedure_name||': Errors in creating Customer Profile Amount');
                log_debug_msg('------------------------------------------------------------------');
                FOR I IN 1..ln_msg_count
                LOOP
                    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                    Log_Debug_Msg('Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                END LOOP;
                log_debug_msg('------------------------------------------------------------------'||CHR(10));
            END IF;
           log_exception
               (
                   p_conversion_id                 => ln_conversion_prof_amt_id
                  ,p_record_control_id             => l_hz_imp_prof_amt_stg.record_id
                  ,p_source_system_code            => l_hz_imp_prof_amt_stg.account_orig_system
                  ,p_source_system_ref             => l_hz_imp_prof_amt_stg.account_orig_system_reference
                  ,p_procedure_name                => lc_procedure_name
                  ,p_staging_table_name            => lc_staging_table_name
                  ,p_staging_column_name           => 'RECORD_ID'
                  ,p_staging_column_value          => l_hz_imp_prof_amt_stg.record_id
                  ,p_batch_id                      => gn_batch_id
                  ,p_exception_log                 => XX_CDH_CONV_MASTER_PKG.trim_input_msg(l_msg_text)
                  ,p_oracle_error_code             => SQLCODE
                  ,p_oracle_error_msg              => lc_oracle_error_msg
           );
        END IF;

    END IF;

EXCEPTION
WHEN OTHERS THEN
    log_debug_msg(lc_procedure_name||': Record_id = '||l_hz_imp_prof_amt_stg.record_id||': Others Exception'||SQLERRM);

END create_profile_amount;


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
    --IF fnd_profile.value ('') = 'Y' THEN
    --DBMS_OUTPUT.PUT_LINE(p_debug_msg);
    --FND_FILE.PUT_LINE(FND_FILE.LOG,p_debug_msg);
    XX_CDH_CONV_MASTER_PKG.write_conc_log_message( p_debug_msg);
    --END IF;
END log_debug_msg;


-- +===================================================================+
-- | Name        : is_customer_profile_exists                          |
-- |                                                                   |
-- | Description : Function checks whether customer profile already    |
-- |               exists or not                                       |
-- |                                                                   |
-- | Parameters  : p_cust_account_id                                   |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_customer_profile_exists
    ( p_cust_account_id  IN NUMBER )

RETURN NUMBER
AS
ln_cust_prof_id  NUMBER := NULL;
BEGIN

    SELECT  cust_account_profile_id
    INTO    ln_cust_prof_id
    FROM    hz_customer_profiles
    WHERE   cust_account_id = p_cust_account_id
    AND     site_use_id IS NULL;

    RETURN ln_cust_prof_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;

END is_customer_profile_exists;


-- +===================================================================+
-- | Name        : is_profile_amt_exists                               |
-- |                                                                   |
-- | Description : Function checks whether customer profile amount     |
-- |               already exists or not                               |
-- |                                                                   |
-- | Parameters  : p_cust_acct_prof_id , p_currency_code               |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_profile_amt_exists
    (
         p_cust_acct_prof_id    IN NUMBER
        ,p_currency_code        IN VARCHAR

    )
RETURN NUMBER
AS
ln_prof_amt_id  NUMBER;
BEGIN

    SELECT  cust_acct_profile_amt_id
    INTO    ln_prof_amt_id
    FROM    hz_cust_profile_amts
    WHERE   cust_account_profile_id = p_cust_acct_prof_id
    AND     currency_code  = p_currency_code;

    RETURN  ln_prof_amt_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;

END is_profile_amt_exists;

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
lc_package_name  VARCHAR2(32) := 'XX_CDH_CUSTOMER_PROFILE_PKG';
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
-- | Name        : orig_sys_val                                        |
-- |                                                                   |
-- | Description : Function checks whether the p_orig_sys is a valid   |
-- |               reference key of HZ_ORIG_SYSTEM_B table             |
-- | Parameters  : p_orig_sys                                          |
-- |                                                                   |
-- +===================================================================+
FUNCTION orig_sys_val
    ( p_orig_sys  IN  VARCHAR2 )

RETURN NUMBER

AS
lc_orig_sys_id  NUMBER := NULL;
BEGIN

    SELECT ORIG_SYSTEM_ID
    INTO lc_orig_sys_id
    FROM  HZ_ORIG_SYSTEMS_B
    WHERE ORIG_SYSTEM = p_orig_sys;

    RETURN lc_orig_sys_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;

END orig_sys_val;

-- +===================================================================+
-- | Name        : get_party_id                                        |
-- |                                                                   |
-- | Description : Function to get party_id from p_cust_account_id     |
-- |                                                                   |
-- | Parameters  : p_cust_account_id                                   |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_party_id
    ( p_cust_account_id   IN  NUMBER )

RETURN NUMBER

IS
ln_party_id     NUMBER := NULL;
BEGIN

    SELECT  party_id
    INTO    ln_party_id
    FROM    hz_cust_accounts
    WHERE   cust_account_id = p_cust_account_id;

    RETURN  ln_party_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;

END get_party_id;

-- +===================================================================+
-- | Name        : get_collector_id                                    |
-- |                                                                   |
-- | Description : Procedure to get collector_id from                  |
-- |               p_collector_name passed                             |
-- | Parameters  : p_collector_name                                    |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_collector_id
    (
         p_collector_name   IN      VARCHAR2
        ,x_collector_id     OUT     NUMBER
        ,x_ret_status       OUT     VARCHAR2
    )

IS
    /*
    cursor lcu_cur
    IS
    SELECT  collector_id
    FROM    ar_collectors
    WHERE   name = p_collector_name;
    */

BEGIN

    /*
    open    lcu_cur;
    fetch   lcu_cur into x_collector_id;
    close   lcu_cur;
    */

    SELECT  collector_id
    INTO    x_collector_id
    FROM    ar_collectors
    WHERE   name = p_collector_name;

EXCEPTION

WHEN TOO_MANY_ROWS THEN
    x_ret_status := 'E';
    x_collector_id := NULL;

WHEN OTHERS THEN
    x_collector_id := NULL;

END get_collector_id;


-- +===================================================================+
-- | Name        : get_profile_class_id                                |
-- |                                                                   |
-- | Description : Procedure to get profile_class_id from              |
-- |               p_profile_class_name passed                         |
-- | Parameters  : p_profile_class_name                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_profile_class_id
    (
         p_profile_class_name   IN      VARCHAR2
        ,x_profile_class_id     OUT     NUMBER
        ,x_ret_status           OUT     VARCHAR2
    )

IS

    /*
    cursor lcu_cur
    IS
    SELECT  profile_class_id
    FROM    hz_cust_profile_classes
    WHERE   name = p_profile_class_name;
    */

BEGIN

    /*
    open    lcu_cur;
    fetch   lcu_cur into x_profile_class_id;
    close   lcu_cur;
    */

    SELECT  profile_class_id
    INTO    x_profile_class_id
    FROM    hz_cust_profile_classes
    WHERE   name = p_profile_class_name;

EXCEPTION

WHEN TOO_MANY_ROWS THEN
    x_ret_status := 'E';
    x_profile_class_id := NULL;

WHEN OTHERS THEN
    x_profile_class_id := NULL;

END get_profile_class_id;


-- +===================================================================+
-- | Name        : get_standard_terms                                  |
-- |                                                                   |
-- | Description : Function to get standard_terms from                 |
-- |               p_standard_term_name passed                         |
-- | Parameters  : p_standard_term_name                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_standard_terms
    (
         p_standard_term_name   IN      VARCHAR2
        ,x_standard_terms       OUT     NUMBER
        ,x_ret_status           OUT     VARCHAR2
    )
IS

    /*
    cursor lcu_cur
    IS
    SELECT  term_id
    FROM    ra_terms
    WHERE   name = p_standard_term_name;
    */

BEGIN

    /*
    open    lcu_cur;
    fetch   lcu_cur into x_standard_terms;
    close   lcu_cur;
    */

    SELECT  term_id
    INTO    x_standard_terms
    FROM    ra_terms
    WHERE   name = p_standard_term_name;

EXCEPTION

WHEN TOO_MANY_ROWS THEN
    x_ret_status := 'E';
    x_standard_terms := NULL;

WHEN OTHERS THEN
    x_standard_terms := NULL;

END get_standard_terms;

-- +===================================================================+
-- | Name        : get_dunning_letter_set_id                           |
-- |                                                                   |
-- | Description : Procedure to get dunning_letter_set_id from         |
-- |               p_dunning_letter_set_name passed                    |
-- | Parameters  : p_dunning_letter_set_name                           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_dunning_letter_set_id
    (
         p_dunning_letter_set_name  IN      VARCHAR2
        ,x_dunning_letter_set_id    OUT     NUMBER
        ,x_ret_dun_letter_status    OUT     VARCHAR2
    )
IS

    /*
    cursor lcu_cur
    IS
    SELECT  dunning_letter_set_id
    FROM    ar_dunning_letter_sets
    WHERE   name = p_dunning_letter_set_name;
    */

BEGIN

    /*
    open    lcu_cur;
    fetch   lcu_cur into x_dunning_letter_set_id;
    close   lcu_cur;
    */

    SELECT  dunning_letter_set_id
    INTO    x_dunning_letter_set_id
    FROM    ar_dunning_letter_sets
    WHERE   name = p_dunning_letter_set_name;

EXCEPTION

WHEN TOO_MANY_ROWS THEN
    x_ret_dun_letter_status := 'E';
    x_dunning_letter_set_id := NULL;

WHEN OTHERS THEN
    x_dunning_letter_set_id := NULL;

END get_dunning_letter_set_id;


-- +===================================================================+
-- | Name        : get_statement_cycle_id                              |
-- |                                                                   |
-- | Description : Procedure to get statement_cycle_id from            |
-- |               p_statement_cycle_name passed                       |
-- | Parameters  : p_statement_cycle_name                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_statement_cycle_id
    (
         p_statement_cycle_name     IN      VARCHAR2
        ,x_statement_cycle_id       OUT     NUMBER
        ,x_ret_statement_status     OUT     VARCHAR2
    )
IS

 /*
    cursor lcu_cur
    IS
    SELECT  statement_cycle_id
    FROM    ar_statement_cycles
    WHERE   name = p_statement_cycle_name;
    */

BEGIN

   /*
    open    lcu_cur;
    fetch   lcu_cur into x_statement_cycle_id;
    close   lcu_cur;
    */

    SELECT  statement_cycle_id
    INTO    x_statement_cycle_id
    FROM    ar_statement_cycles
    WHERE   name = p_statement_cycle_name;

EXCEPTION

WHEN TOO_MANY_ROWS THEN
    x_ret_statement_status := 'E';
    x_statement_cycle_id := NULL;

WHEN OTHERS THEN
    x_statement_cycle_id := NULL;

END get_statement_cycle_id;

-- +===================================================================+
-- | Name        : get_autocash_hierarchy_id                           |
-- |                                                                   |
-- | Description : Procedure to get autocash_hierarchy_id from         |
-- |               p_autocash_hierarchy_name passed                    |
-- | Parameters  : p_autocash_hierarchy_name                           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_autocash_hierarchy_id
    (
         p_autocash_hierarchy_name          IN      VARCHAR2
        ,x_autocash_hierarchy_id            OUT     NUMBER
        ,x_autocash_hierarchy_status        OUT     VARCHAR2
)

IS
    /*
    cursor  lcu_cur
    IS
    SELECT  autocash_hierarchy_id
    FROM    ar_autocash_hierarchies
    WHERE   hierarchy_name = p_autocash_hierarchy_name;
    */

BEGIN
   /*
    OPEN    lcu_cur;
    FETCH   lcu_cur into x_statement_cycle_id;
    CLOSE   lcu_cur;
    */
    SELECT  autocash_hierarchy_id
    INTO    x_autocash_hierarchy_id
    FROM    ar_autocash_hierarchies
    WHERE   hierarchy_name = p_autocash_hierarchy_name;

EXCEPTION

WHEN TOO_MANY_ROWS THEN
    x_autocash_hierarchy_status := 'E';
    x_autocash_hierarchy_id := NULL;

WHEN OTHERS THEN
    x_autocash_hierarchy_id := NULL;

END get_autocash_hierarchy_id;

-- +===================================================================+
-- | Name        : get_grouping_rule_id                                |
-- |                                                                   |
-- | Description : Procedure to get grouping_rule_id from              |
-- |               p_grouping_rule_name passed                         |
-- | Parameters  : p_grouping_rule_name                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_grouping_rule_id
    (
         p_grouping_rule_name       IN      VARCHAR2
        ,x_grouping_rule_id         OUT     NUMBER
        ,x_grouping_rule_status     OUT     VARCHAR2
    )

IS
    /*
    CURSOR  lcu_cur
    IS
    SELECT  grouping_rule_id
    FROM    ra_grouping_rules
    WHERE   name = p_grouping_rule_name;
    */
BEGIN
    /*
    OPEN    lcu_cur
    FETCH   lcu_cur INTO x_grouping_rule_id;
    CLOSE   lcu_cur;
    */
    SELECT  grouping_rule_id
    INTO    x_grouping_rule_id
    FROM    ra_grouping_rules
    WHERE   name = p_grouping_rule_name;

EXCEPTION

WHEN TOO_MANY_ROWS THEN
    x_grouping_rule_status := 'E';
    x_grouping_rule_status := NULL;

WHEN OTHERS THEN
    x_grouping_rule_status := NULL;

END get_grouping_rule_id;


-- +===================================================================+
-- | Name        : get_hierarchy_id_for_adr                            |
-- |                                                                   |
-- | Description : Procedure to get hierarchy_id_for_adr from          |
-- |               p_hierarchy_name_adr passed                         |
-- | Parameters  : p_hierarchy_name_adr                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_hierarchy_id_for_adr
    (
         p_hierarchy_name_adr       IN      VARCHAR2
        ,x_hierarchy_id_for_adr     OUT     NUMBER
        ,x_hierarchy_status         OUT     VARCHAR2
    )
IS
   /*
    CURSOR  lcu_cur
    IS
    SELECT  autocash_hierarchy_id_for_adr
    FROM    hz_customer_profiles
    WHERE   autocash_hierarchy_id = (SELECT autocash_hierarchy_id
        FROM    ar_autocash_hierarchies
        WHERE   hierarchy_name = p_hierarchy_name_adr
    );
    */

BEGIN

    /*
    OPEN    lcu_cur
    FETCH   lcu_cur INTO x_grouping_rule_id;
    CLOSE   lcu_cur;
    */
    SELECT  autocash_hierarchy_id_for_adr
    INTO    x_hierarchy_id_for_adr
    FROM    hz_customer_profiles
    WHERE   autocash_hierarchy_id = (SELECT autocash_hierarchy_id
        FROM    ar_autocash_hierarchies
        WHERE   hierarchy_name = p_hierarchy_name_adr
    );

EXCEPTION

WHEN TOO_MANY_ROWS THEN
    x_hierarchy_status := 'E';
    x_hierarchy_id_for_adr := NULL;

WHEN OTHERS THEN
    x_hierarchy_id_for_adr := NULL;

END get_hierarchy_id_for_adr;

PROCEDURE update_profile_override_terms (custAcctId                  IN      NUMBER
                                         ,p_override_terms           IN      VARCHAR2
                                         ,x_prof_return_status       OUT     VARCHAR2)
IS
   p_customer_profile_rec_type HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
   p_cust_account_profile_id NUMBER;
   p_object_version_number   NUMBER;
   x_return_status           VARCHAR2 ( 2000 ) ;
   x_msg_count               NUMBER;
   x_msg_data                VARCHAR2 ( 2000 ) ;
BEGIN
   --Get the Customer Account Profile Id
   SELECT cust_account_profile_id 
          ,object_version_number
   INTO   p_cust_account_profile_id
          ,p_object_version_number
   FROM   hz_customer_profiles
   WHERE  cust_account_id = custAcctId
   AND    site_use_id IS NULL;
   dbms_output.put_line ( 'p_cust_account_profile_id = '||p_cust_account_profile_id ) ;
   dbms_output.put_line ( 'custAcctId = '||custAcctId ) ;
   p_customer_profile_rec_type.cust_account_profile_id := p_cust_account_profile_id;
   --p_customer_profile_rec_type.override_terms          := 'Y';
   p_customer_profile_rec_type.override_terms          := p_override_terms;
   dbms_output.put_line ( 'Calling the API' ) ;
   hz_customer_profile_v2pub.update_customer_profile (  p_init_msg_list         => 'T'                         , 
                                                        p_customer_profile_rec  => p_customer_profile_rec_type , 
                                                        p_object_version_number => p_object_version_number     , 
                                                        x_return_status         => x_return_status             , 
                                                        x_msg_count             => x_msg_count                 , 
                                                        x_msg_data              => x_msg_data 
                                                      );
   dbms_output.put_line ( 'After Calling the API' ) ;   
   dbms_output.put_line ( 'x_return_status = '||SUBSTR ( x_return_status, 1, 255 ) ) ;
   dbms_output.put_line ( 'Object Version Number = '||TO_CHAR ( p_object_version_number ) ) ;
   --dbms_output.put_line ( 'Credit Rating = '||p_customer_profile_rec_type.credit_rating ) ;
   dbms_output.put_line ( 'x_msg_count = '||TO_CHAR ( x_msg_count ) ) ;
   dbms_output.put_line ( 'x_msg_data = '|| SUBSTR ( x_msg_data, 1, 255 ) ) ;
   commit;
   IF x_msg_count >1 THEN
      FOR I      IN 1..x_msg_count
      LOOP
         dbms_output.put_line ( I||'.'||SUBSTR ( FND_MSG_PUB.Get ( p_encoded=> FND_API.G_FALSE ), 1, 255 ) ) ;
      END LOOP;
   END IF;  
   x_prof_return_status := 'S';
EXCEPTION
WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE ( 'Error: '||SQLERRM ) ;   
END update_profile_override_terms;

END XX_CDH_CUSTOMER_PROFILE_PKG;
/
SHOW ERRORS;