SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_JTF_NOTES_PKG
-- +====================================================================================+
-- |                        Office Depot - Project Simplify                             |
-- |                      Oracle NAIO Consulting Organization                           |
-- +====================================================================================+
-- | Name        : XX_JTF_NOTES_PKG                                                     |
-- | Description : Package to create Notes and Notes Context                            |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version     Date           Author               Remarks                             |
-- |=======    ==========      ================     ====================================|
-- |Draft 1a   19-Apr-2007     Prakash Sowriraj     Initial draft version               |
-- |Draft 1b   03-Aug-2007     Prakash Sowriraj     Object Source Code 'TASK'           |
-- |                                                has been added                      |
-- |Draft 1c   08-FEB-2008     Piyush Khandelwal    Added record count for Duplicate    |
-- |                                                records                             |
-- |Draft 1d   14-MAR-2008     Piyush Khandelwal    Added DBMS_LOCK.SLEEP Command to    |
-- |                                                introduce wait between two notes    |
-- |                                                creation(SOLAR conversion)          |
-- |Draft 1e   04-APR-2008     Hema Chikkanna       Included Batch ID Parameter in Log  |
-- |                                                Exception Procedure                 |
-- |Draft 1c   16-Jul-2008     Satyasrinivas        Changes for the error               |
-- |                                                message for notes.                  |
-- |Draft 1g   02-Aug-2008     Satyasrinivas        Modified code to log duplicate notes|
-- |                                                message in the error log table.     |
-- +====================================================================================+

AS
    g_batch_id                       NUMBER;

-- +===================================================================+
-- | Name        : create_notes_main                                   |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: JTF Notes Creation Program'            |
-- | Parameters  : p_batch_id_from,p_batch_id_to                       |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_notes_main
    (
         x_errbuf           OUT NOCOPY  VARCHAR2
        ,x_retcode          OUT NOCOPY  VARCHAR2
        ,p_batch_id_from    IN          NUMBER
        ,p_batch_id_to      IN          NUMBER
    )
AS

--Cursor to fecth distinct batch_ids from XX_JTF_NOTES_INT table
CURSOR lcu_get_notes_batch_id
    (
          cp_batch_id_from  NUMBER
        , cp_batch_id_to    NUMBER
    )
IS
SELECT   DISTINCT batch_id
FROM     XX_JTF_NOTES_INT
WHERE    batch_id BETWEEN cp_batch_id_from AND cp_batch_id_to
AND      interface_status IN ('1','4','6') 
ORDER BY batch_id ASC;

--Cursor to fecth notes records from XX_JTF_NOTES_INT table
CURSOR lcu_get_note_recs
    (
         cp_batch_id        NUMBER

    )
IS
SELECT  *
FROM    XX_JTF_NOTES_INT
WHERE   batch_id = cp_batch_id
AND     interface_status IN ('1','4','6')
ORDER BY parent_note_orig_system_ref,jtf_note_orig_system_ref desc; -- Added order by clause on March 14 2008

--Cursor to fecth distinct batch_ids from XX_JTF_NOTE_CTX_INT table
CURSOR lcu_get_note_ctx_batch_id
    (
          cp_batch_id_from  NUMBER
        , cp_batch_id_to    NUMBER
    )
IS
SELECT   DISTINCT batch_id
FROM     XX_JTF_NOTE_CTX_INT
WHERE    batch_id BETWEEN cp_batch_id_from AND cp_batch_id_to
AND      interface_status IN ('1','4','6') 
ORDER BY batch_id ASC;

--Cursor to fecth notes records from XX_JTF_NOTE_CTX_INT table
CURSOR lcu_get_note_ctx_recs
    (
         cp_batch_id        NUMBER
    )
IS
SELECT  *
FROM    XX_JTF_NOTE_CTX_INT
WHERE   batch_id = cp_batch_id
AND     interface_status IN ('1','4','6');

--------------------
-- note
--------------------
TYPE notes_tbl_type             IS TABLE OF xx_jtf_notes_int%ROWTYPE;
lt_notes                        notes_tbl_type;
TYPE update_rec_tbl_type        IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
TYPE upd_interface_tbl_type     IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;
lt_notes_update                 update_rec_tbl_type;
lt_notes_interface              upd_interface_tbl_type;
lc_notes_return_status          VARCHAR2(1)      := 'E';
ln_notes_rec_pro_succ           NUMBER := 0;
ln_notes_rec_pro_fail           NUMBER := 0;
ln_notes_rec_duplicated         NUMBER := 0;
ln_notes_rec_validation         NUMBER := 0;
ln_conversion_note_id           NUMBER := 1381.1;
--------------------
-- note_context
--------------------
TYPE note_contxt_tbl_type       IS TABLE OF xx_jtf_note_ctx_int%ROWTYPE;
lt_note_contxts                 note_contxt_tbl_type;
lt_note_ctxt_update             update_rec_tbl_type;
lt_note_ctxt_interface          upd_interface_tbl_type;
lc_note_context_return_status   VARCHAR2(1)      := 'E';
ln_note_context_rec_pro_succ    NUMBER;
ln_note_context_rec_pro_fail    NUMBER;
ln_note_ctx_rec_duplicated      NUMBER;
ln_note_ctx_rec_validation      NUMBER := 0;
ln_conversion_note_context_id   NUMBER := 1381.2;

lc_procedure_name               VARCHAR2(50)    := 'create_notes_main';
lc_num_pro_rec_read             NUMBER := 0;
lv_errbuf                       VARCHAR2(2000);
lv_retcode                      VARCHAR2(10);
ln_batch_id                     NUMBER;
ln_bulk_limit                   NUMBER := XX_CDH_CONV_MASTER_PKG.g_bulk_fetch_limit;

BEGIN
    
    --************************** Part:1 Create Notes ****************************--
    log_debug_msg('==================   BEGIN  =======================');
    log_debug_msg('================ Create Notes ================='||CHR(10));

    BEGIN

        log_debug_msg('p_batch_id_from = '||p_batch_id_from);
        log_debug_msg('p_batch_id_to = '||p_batch_id_to);

        FOR idx IN lcu_get_notes_batch_id
            (     cp_batch_id_from  => p_batch_id_from
                , cp_batch_id_to    => p_batch_id_to
            )
        LOOP

            ln_batch_id := idx.batch_id;

            ln_notes_rec_pro_succ   := 0;
            ln_notes_rec_pro_fail   := 0;
            ln_notes_rec_duplicated := 0;

            lt_notes_interface.DELETE;
            lt_notes_update.DELETE;

            log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.BEGIN *********************'||CHR(10));

            OPEN lcu_get_note_recs
                (
                     cp_batch_id   => ln_batch_id
                );
            FETCH lcu_get_note_recs BULK COLLECT INTO lt_notes;
            CLOSE lcu_get_note_recs;



            IF  lt_notes.COUNT < 1 THEN
                log_debug_msg('No records found for the batch_id = '||ln_batch_id);
            ELSE

                log_debug_msg('Records found for the batch_id ('||ln_batch_id||')'||'= '||lt_notes.COUNT||CHR(10));

                XX_COM_CONV_ELEMENTS_PKG.Log_control_info_proc
                    (
                          p_conversion_id            => ln_conversion_note_id
                        , p_batch_id                 => ln_batch_id
                        , p_num_bus_objs_processed   => 0
                    );

                FOR i IN lt_notes.first .. lt_notes.last
                LOOP
                    lc_notes_return_status       := 'E';
                    log_debug_msg(CHR(10)||'Record-id:'||lt_notes(i).record_id);
                    log_debug_msg('=====================');
                    
                    ----------------------------------------------
                    -- Added DBMS_LOCK.SLEEP command to introduce 
                    -- wait time between two notes creation
                    -- Changes made on 14-March-2008
                    ----------------------------------------------
                    
                    DBMS_LOCK.SLEEP(1);
                    
                    --End of changes on 14-March-2008
                    
                    
                    --Creating a new customer notes
                    create_note
                        (
                            l_jtf_notes_int         => lt_notes(i)
                          , x_notes_return_status   => lc_notes_return_status
                        );

                    lt_notes_update(i) := lt_notes(i).record_id;

                    IF lc_notes_return_status = 'S' THEN
                        --Processing Successful
                        lt_notes_interface(i) := '7';
                        ln_notes_rec_pro_succ := ln_notes_rec_pro_succ+1;

                    ELSIF lc_notes_return_status = 'V' THEN
                        -- Validation Falied
                        lt_notes_interface(i) := '3';
                        ln_notes_rec_validation := ln_notes_rec_validation+1;
                        
                    ELSIF lc_notes_return_status = 'D' THEN
                        -- Duplicate Records
                        lt_notes_interface(i) := '3';
                        ln_notes_rec_duplicated := ln_notes_rec_duplicated+1;
                    ELSE
                        --Processing Failed
                        lt_notes_interface(i) := '6';
                        ln_notes_rec_pro_fail := ln_notes_rec_pro_fail+1;
                    END IF;

                END LOOP;
                COMMIT;
                --Bulk update of interface_status column
                IF lt_notes_update.last > 0 THEN
                  FORALL i IN 1 .. lt_notes_update.last
                      UPDATE xx_jtf_notes_int
                      SET    interface_status  = lt_notes_interface(i)
                      WHERE  record_id = lt_notes_update(i);
                END IF;

                COMMIT;
                --No.of processed,failed,succeeded records - start
                lc_num_pro_rec_read := (ln_notes_rec_pro_succ + ln_notes_rec_pro_fail+ln_notes_rec_duplicated+ln_notes_rec_validation);
                log_debug_msg(CHR(10)||'-----------------------------------------------------------');
                log_debug_msg('Total no.of records read = '||lc_num_pro_rec_read);
                log_debug_msg('Total no.of records succeded = '||ln_notes_rec_pro_succ);
                log_debug_msg('Total no.of records failed = '||ln_notes_rec_pro_fail);
                log_debug_msg('Total no.of records validation failed = '||ln_notes_rec_validation);
                log_debug_msg('Total no.of records duplicated = '||ln_notes_rec_duplicated);
                log_debug_msg('-----------------------------------------------------------');

                fnd_file.put_line(fnd_file.output,'================ Create Notes =================');
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');
                fnd_file.put_line(fnd_file.output,'Total no.of records read = '||lc_num_pro_rec_read);
                fnd_file.put_line(fnd_file.output,'Total no.of records succeded = '||ln_notes_rec_pro_succ);
                fnd_file.put_line(fnd_file.output,'Total no.of records failed = '||ln_notes_rec_pro_fail);
                fnd_file.put_line(fnd_file.output,'Total no.of records validation failed = '||ln_notes_rec_validation);
                fnd_file.put_line(fnd_file.output,'Total no.of records duplicated = '||ln_notes_rec_duplicated);
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');

                XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
                    (
                          p_conc_mst_req_id              => APPS.FND_GLOBAL.CONC_REQUEST_ID
                        , p_batch_id                     => ln_batch_id
                        , p_conversion_id                => ln_conversion_note_id
                        , p_num_bus_objs_failed_valid    => 0
                        , p_num_bus_objs_failed_process  => ln_notes_rec_pro_fail
                        , p_num_bus_objs_succ_process    => ln_notes_rec_pro_succ
                    );
            log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.END *********************'||CHR(10));

           END IF;

       END LOOP;

    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf    :='Others Exception in create_notes_main procedure '||SQLERRM;
        x_retcode   :='2';
    END;

    log_debug_msg(CHR(10)||'-----------------------       END        ----------------------');


    --************************** Part:1 Create Notes ****************************--
    log_debug_msg('==================   BEGIN  =======================');
    log_debug_msg('================ Create Note Contexts ================='||CHR(10));

    BEGIN

        log_debug_msg('p_batch_id_from = '||p_batch_id_from);
        log_debug_msg('p_batch_id_to = '||p_batch_id_to);

        FOR idx IN lcu_get_note_ctx_batch_id
            (     cp_batch_id_from  => p_batch_id_from
                , cp_batch_id_to    => p_batch_id_to
            )
        LOOP

            ln_batch_id := idx.batch_id;

            ln_note_context_rec_pro_succ := 0;
            ln_note_context_rec_pro_fail := 0;
            ln_note_ctx_rec_duplicated   := 0;
            ln_note_ctx_rec_validation   := 0;

            log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.BEGIN *********************'||CHR(10));

            OPEN lcu_get_note_ctx_recs
                (
                     cp_batch_id   => ln_batch_id
                );
            FETCH lcu_get_note_ctx_recs BULK COLLECT INTO lt_note_contxts;
            CLOSE lcu_get_note_ctx_recs;

            lt_note_ctxt_update.DELETE;
            lt_note_ctxt_interface.DELETE;

            IF  lt_note_contxts.COUNT < 1 THEN
                log_debug_msg('No records found for the batch_id = '||ln_batch_id);
            ELSE

                XX_COM_CONV_ELEMENTS_PKG.Log_control_info_proc
                    (
                          p_conversion_id            => ln_conversion_note_context_id
                        , p_batch_id                 => ln_batch_id
                        , p_num_bus_objs_processed   => lt_note_contxts.count
                    );

                FOR i IN lt_note_contxts.first .. lt_note_contxts.last
                LOOP
                    lc_note_context_return_status       := 'E';
                    log_debug_msg(CHR(10)||'Record-id:'||lt_note_contxts(i).record_id);
                    log_debug_msg('=====================');

                    --Creating a new note context
                    create_note_context
                        (
                            l_jtf_note_context_int         => lt_note_contxts(i)
                          , x_note_context_return_status   => lc_note_context_return_status
                        );

                    lt_note_ctxt_update(i) := lt_note_contxts(i).record_id;

                    IF lc_note_context_return_status = 'S' THEN
                        --Processing Successful
                        lt_note_ctxt_interface(i) := '7';
                        ln_note_context_rec_pro_succ := ln_note_context_rec_pro_succ+1;

                    ELSIF lc_note_context_return_status = 'V' THEN
                        --Validation Failed
                        lt_note_ctxt_interface(i) := '3';
                        ln_note_ctx_rec_validation := ln_note_ctx_rec_validation+1;
                        
                    ELSIF lc_note_context_return_status = 'D' THEN
                        --Duplicate Records
                        lt_note_ctxt_interface(i) := '3';
                        ln_note_ctx_rec_duplicated := ln_note_ctx_rec_duplicated+1;

                    ELSE
                        --Processing Failed
                        lt_note_ctxt_interface(i) := '6';
                        ln_note_context_rec_pro_fail := ln_note_context_rec_pro_fail+1;
                    END IF;

                END LOOP;

                --Bulk update of interface_status column
                IF lt_note_ctxt_update.last > 0 THEN
                  FORALL i IN 1 .. lt_note_ctxt_update.last
                      UPDATE xx_jtf_note_ctx_int
                      SET    interface_status  = lt_note_ctxt_interface(i)
                      WHERE  record_id = lt_note_ctxt_update(i);
                END IF;

                COMMIT;
                --No.of processed,failed,succeeded records - start
                lc_num_pro_rec_read := (ln_note_context_rec_pro_succ + ln_note_context_rec_pro_fail+ln_note_ctx_rec_duplicated+ln_note_ctx_rec_validation);
                log_debug_msg(CHR(10)||'-----------------------------------------------------------');
                log_debug_msg('Total no.of records read = '||lc_num_pro_rec_read);
                log_debug_msg('Total no.of records succeded = '||ln_note_context_rec_pro_succ);
                log_debug_msg('Total no.of records failed = '||ln_note_context_rec_pro_fail);
                log_debug_msg('Total no.of records duplicated = '||ln_note_ctx_rec_validation);
                log_debug_msg('Total no.of records duplicated = '||ln_note_ctx_rec_duplicated);

                log_debug_msg('-----------------------------------------------------------');

                fnd_file.put_line(fnd_file.output,'================ Create Note Contexts =================');
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');
                fnd_file.put_line(fnd_file.output,'Total no.of records read = '||lc_num_pro_rec_read);
                fnd_file.put_line(fnd_file.output,'Total no.of records succeded = '||ln_note_context_rec_pro_succ);
                fnd_file.put_line(fnd_file.output,'Total no.of records failed = '||ln_note_context_rec_pro_fail);
                fnd_file.put_line(fnd_file.output,'Total no.of records validation failed = '||ln_note_ctx_rec_validation);
                fnd_file.put_line(fnd_file.output,'Total no.of records duplicated = '||ln_note_ctx_rec_duplicated);
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');

                XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
                    (
                          p_conc_mst_req_id              => APPS.FND_GLOBAL.CONC_REQUEST_ID
                        , p_batch_id                     => ln_batch_id
                        , p_conversion_id                => ln_conversion_note_context_id
                        , p_num_bus_objs_failed_valid    => 0
                        , p_num_bus_objs_failed_process  => ln_note_context_rec_pro_fail
                        , p_num_bus_objs_succ_process    => ln_note_context_rec_pro_succ
                    );

                log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.END *********************'||CHR(10));
           END IF;

       END LOOP;

    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf    :='Others Exception in create_notes_main procedure '||SQLERRM;
        x_retcode   :='2';
    END;

    log_debug_msg(CHR(10)||'-----------------------       END        ----------------------');

END create_notes_main;

-- +===================================================================+
-- | Name        : create_notes                                        |
-- | Description : Procedure to create a new customer notes            |
-- |                                                                   |
-- | Parameters  : l_jtf_notes_int                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_note
    (
         l_jtf_notes_int            IN      xx_jtf_notes_int%ROWTYPE
        ,x_notes_return_status      OUT     VARCHAR
    )

AS

    lc_return_status                VARCHAR2(1);
    lc_msg_data                     VARCHAR2(2000);
    ln_api_version                  NUMBER := 1.0;
    lc_init_msg_list                VARCHAR2(1);
    ln_jtf_note_id                  NUMBER := NULL;
    ln_msg_count                    NUMBER ;
    
    ln_parent_note_id               NUMBER;
    ln_source_object_id             NUMBER;
    lc_source_object_code           VARCHAR2(250);
    lb_notes_create_flag            BOOLEAN := TRUE;
    ln_conversion_note_id           NUMBER := 1381.1;

    lc_procedure_name               VARCHAR2(250):='XX_JTF_NOTES_PKG.CREATE_NOTE';--
    lc_staging_table_name           VARCHAR2(250):='XX_JTF_NOTES_INT';
    lc_exception_log                VARCHAR2(2000);
    lc_oracle_error_msg             VARCHAR2(2000);
    lc_staging_column_name          VARCHAR2(32);
    lc_staging_column_value         VARCHAR2(500);
    l_msg_text                      VARCHAR2(4200);
    ln_orig_system                  VARCHAR2(30);
    
    l_note_type                     VARCHAR2(10) := 'NOTES';

BEGIN

    g_staging_table_name         := 'XX_JTF_NOTES_INT';
    g_procedure_name             := lc_procedure_name;
    g_batch_id                   := l_jtf_notes_int.batch_id;
    --------------------------------
    -- Data validations
    --------------------------------

    IF l_jtf_notes_int.source_object_code IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0026_SOU_OBJ_CODE_NULL');
        g_errbuf := FND_MESSAGE.GET;
        g_staging_column_name              := 'source_object_code';
        g_staging_column_value             := l_jtf_notes_int.source_object_code;
        log_debug_msg(g_procedure_name||' : '||g_errbuf);
        log_exception
            (
                p_procedure_name            => g_procedure_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_exception_log             => g_errbuf
               ,p_oracle_error_code         => 'XX_SFA_0026_SOU_OBJ_CODE_NULL'
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
               ,p_batch_id                  => TO_NUMBER(l_jtf_notes_int.batch_id)
            ); 
        lb_notes_create_flag := FALSE;

    END IF;
    ------------------

    IF l_jtf_notes_int.source_object_orig_system_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0027_SOU_OOSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        g_staging_column_name              := 'source_object_orig_system_ref';
        g_staging_column_value             := l_jtf_notes_int.source_object_orig_system_ref;
        log_debug_msg(g_procedure_name||' : '||g_errbuf);
        log_exception
            (
                p_procedure_name            => g_procedure_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_exception_log             => g_errbuf
               ,p_oracle_error_code         => 'XX_SFA_0027_SOU_OOSR_NULL'
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
               ,p_batch_id                  => l_jtf_notes_int.batch_id
            ); 
        lb_notes_create_flag := FALSE;
    END IF;


    ----------------------------------------------------
    -- Checking whether source_object_orig_system is a
    -- valid foreign key reference to HZ_ORIG_SYSTEMS_B
    ----------------------------------------------------
    IF l_jtf_notes_int.source_object_orig_system IS NOT NULL THEN

        BEGIN

        SELECT  orig_system
        INTO    ln_orig_system
        FROM    hz_orig_systems_b
        WHERE   orig_system = l_jtf_notes_int.source_object_orig_system;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0028_INV_SOU_OOS');
            FND_MESSAGE.SET_TOKEN('P_SOURCE_OS',l_jtf_notes_int.source_object_orig_system);
            g_errbuf := 'WHEN NO_DATA_FOUND : '||FND_MESSAGE.GET;
            g_staging_column_name              := 'source_object_orig_system';
            g_staging_column_value             := l_jtf_notes_int.source_object_orig_system;
            log_debug_msg(g_procedure_name||' : '||g_errbuf);
            log_exception
                    (
                        p_procedure_name            => g_procedure_name
                       ,p_staging_column_name       => g_staging_column_name
                       ,p_staging_column_value      => g_staging_column_value
                       ,p_exception_log             => g_errbuf
                       ,p_oracle_error_code         => 'XX_SFA_0028_INV_SOU_OOS'
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
                       ,p_batch_id                  => l_jtf_notes_int.batch_id
                   ); 
            lb_notes_create_flag := FALSE;
            
            WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0028_INV_SOU_OOS');
            FND_MESSAGE.SET_TOKEN('P_SOURCE_OS',l_jtf_notes_int.source_object_orig_system);
            g_errbuf := 'WHEN OTHERS : '||FND_MESSAGE.GET;
            g_staging_column_name              := 'source_object_orig_system';
            g_staging_column_value             := l_jtf_notes_int.source_object_orig_system;
            log_debug_msg(g_procedure_name||' : '||g_errbuf);
            log_exception
                    (
                        p_procedure_name            => g_procedure_name
                       ,p_staging_column_name       => g_staging_column_name
                       ,p_staging_column_value      => g_staging_column_value
                       ,p_exception_log             => g_errbuf
                       ,p_oracle_error_code         => 'XX_SFA_0028_INV_SOU_OOS'
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
                       ,p_batch_id                  => l_jtf_notes_int.batch_id
                   ); 
            lb_notes_create_flag := FALSE;
        END;

    END IF;


    ----------------------------------------------------
    -- Checking whether source_object_code is a
    -- valid foreign key reference to JTF_OBJECTS_B
    ----------------------------------------------------
    IF l_jtf_notes_int.source_object_code IS NOT NULL THEN

        BEGIN

        SELECT  object_code
        INTO    lc_source_object_code
        FROM    jtf_objects_b
        WHERE   object_code = l_jtf_notes_int.source_object_code;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN

            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0029_INV_SOC');
            FND_MESSAGE.SET_TOKEN('P_SOURCE_OC',l_jtf_notes_int.source_object_code);
            g_errbuf := 'WHEN NO_DATA_FOUND : '||FND_MESSAGE.GET;
            g_staging_column_name              := 'source_object_code';
            g_staging_column_value             := l_jtf_notes_int.source_object_code;
            log_debug_msg(g_procedure_name||' : '||g_errbuf);
            log_exception
                    (
                        p_procedure_name            => g_procedure_name
                       ,p_staging_column_name       => g_staging_column_name
                       ,p_staging_column_value      => g_staging_column_value
                       ,p_exception_log             => g_errbuf
                       ,p_oracle_error_code         => 'XX_SFA_0029_INV_SOC'
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
                       ,p_batch_id                  => l_jtf_notes_int.batch_id
                   ); 
                lb_notes_create_flag := FALSE;

            WHEN OTHERS THEN

            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0029_INV_SOC');
            FND_MESSAGE.SET_TOKEN('P_SOURCE_OC',l_jtf_notes_int.source_object_code);
            g_errbuf := 'WHEN OTHERS : '||FND_MESSAGE.GET;
            log_debug_msg(lc_procedure_name||' : '||g_errbuf);
            g_staging_column_name              := 'source_object_code';
            g_staging_column_value             := l_jtf_notes_int.source_object_code;
            log_debug_msg(g_procedure_name||' : '||g_errbuf);
            log_exception
                    (
                        p_procedure_name            => g_procedure_name
                       ,p_staging_column_name       => g_staging_column_name
                       ,p_staging_column_value      => g_staging_column_value
                       ,p_exception_log             => g_errbuf
                       ,p_oracle_error_code         => 'XX_SFA_0029_INV_SOC'
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
                       ,p_batch_id                  => l_jtf_notes_int.batch_id
                   );                       
                lb_notes_create_flag := FALSE;
        END;

    END IF;

    --------------------------------
    -- Getting source_object_id
    --------------------------------
    IF l_jtf_notes_int.source_object_code IS NOT NULL AND
       l_jtf_notes_int.source_object_orig_system_ref IS NOT NULL THEN

        Get_object_source_id
            (
                  p_source_object_code            => l_jtf_notes_int.source_object_code
                , p_source_object_orig_sys_ref    => l_jtf_notes_int.source_object_orig_system_ref
                , p_source_object_orig_sys        => l_jtf_notes_int.source_object_orig_system
                , x_object_source_id              => ln_source_object_id
            );

            log_debug_msg('x_object_source_id:'||ln_source_object_id);

            IF ln_source_object_id IS NULL THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0030_SOU_OBJID_NFOUND');
                FND_MESSAGE.SET_TOKEN('P_SOURCE_OC',l_jtf_notes_int.source_object_code);
                FND_MESSAGE.SET_TOKEN('P_SOURCE_OSR',l_jtf_notes_int.source_object_orig_system_ref);
                FND_MESSAGE.SET_TOKEN('P_SOURCE_OS',l_jtf_notes_int.source_object_orig_system);
                g_errbuf := FND_MESSAGE.GET;
                g_staging_column_name              := 'source_object_id';
                g_staging_column_value             := l_jtf_notes_int.source_object_code;
                log_debug_msg(g_procedure_name||' : '||g_errbuf);
                log_exception
                    (
                        p_procedure_name            => g_procedure_name
                       ,p_staging_column_name       => g_staging_column_name
                       ,p_staging_column_value      => g_staging_column_value
                       ,p_exception_log             => g_errbuf
                       ,p_oracle_error_code         => 'XX_SFA_0030_SOU_OBJID_NFOUND'
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
                       ,p_batch_id                  => l_jtf_notes_int.batch_id
                   );                       
            lb_notes_create_flag := FALSE;
            END IF;

    ELSE

        lb_notes_create_flag := FALSE;

    END IF;


    --------------------------------
    -- Retrieving parent_note_id
    --------------------------------
    IF l_jtf_notes_int.parent_note_orig_system_ref IS NOT NULL THEN

        Get_note_id
            (
                 p_note_orig_system_ref => l_jtf_notes_int.parent_note_orig_system_ref
               ,  p_note_type            => 'NOTES'
               , x_note_id              => ln_parent_note_id
            );
    END IF;

    ---------------------------
    -- Retrieving jtf_note_id
    ---------------------------

    IF l_jtf_notes_int.jtf_note_orig_system_ref IS NOT NULL THEN

        Get_note_id
            (
                 p_note_orig_system_ref => l_jtf_notes_int.jtf_note_orig_system_ref
               ,  p_note_type            => 'NOTES'
               , x_note_id              => ln_jtf_note_id
            );

    END IF;


    IF lb_notes_create_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||': Cannot create notes - Validation Failed');
        x_notes_return_status     := 'V';
        g_errbuf                           :=  'Error: Cannot create notes - Validation Failed';
	g_staging_column_name              := 'JTF_NOTES_PUB.CREATE_NOTE';
	g_staging_column_value             := 'JTF_NOTES_PUB.CREATE_NOTE';
	log_exception
	             (
	               p_procedure_name            => g_procedure_name
	               ,p_staging_column_name       => g_staging_column_name
	               ,p_staging_column_value      => g_staging_column_value
	               ,p_exception_log             => g_errbuf
	               ,p_oracle_error_code         => g_errbuf
	               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
	               ,p_batch_id                  => l_jtf_notes_int.batch_id
                     );                      
        RETURN;
    END IF;


    IF ln_jtf_note_id IS NOT NULL THEN

        log_debug_msg(lc_procedure_name||': Error: Duplicate note is found the note_id - '||ln_jtf_note_id);
        x_notes_return_status     := 'D';
                g_errbuf                           :=  'Error: Duplicate note is found the note_id';
		g_staging_column_name              := 'JTF_NOTES_PUB.CREATE_NOTE';
		g_staging_column_value             := 'JTF_NOTES_PUB.CREATE_NOTE';
		log_exception
		             (
		               p_procedure_name            => g_procedure_name
		               ,p_staging_column_name       => g_staging_column_name
		               ,p_staging_column_value      => g_staging_column_value
		               ,p_exception_log             => g_errbuf
		               ,p_oracle_error_code         => g_errbuf
		               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
		               ,p_batch_id                  => l_jtf_notes_int.batch_id
                     );          
        RETURN;

    ELSE

        ---------------------
        -- Create notes
        ---------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': create a new note');
        log_debug_msg('-------------------------------------');


        jtf_notes_pub.Create_note
        (
              p_parent_note_id           => ln_parent_note_id
            , p_api_version              => ln_api_version
            , p_init_msg_list            => FND_API.G_TRUE
            , p_source_object_id         => ln_source_object_id
            , p_source_object_code       => l_jtf_notes_int.source_object_code
            , x_return_status            => lc_return_status
            , x_msg_count                => ln_msg_count
            , x_msg_data                 => lc_msg_data
            , p_notes                    => l_jtf_notes_int.notes
            , p_notes_detail             => l_jtf_notes_int.notes_detail
            , p_note_status              => l_jtf_notes_int.notes_status
            , p_entered_by               => FND_GLOBAL.USER_ID
            , p_entered_date             => SYSDATE--l_jtf_notes_int.entered_date
            , x_jtf_note_id              => ln_jtf_note_id
            , p_last_update_date         => SYSDATE--l_jtf_notes_int.last_update_date
            , p_attribute1               => l_jtf_notes_int.attribute1
            , p_attribute2               => l_jtf_notes_int.attribute2
            , p_attribute3               => l_jtf_notes_int.attribute3
            , p_attribute4               => l_jtf_notes_int.attribute4
            , p_attribute5               => l_jtf_notes_int.attribute5
            , p_attribute6               => l_jtf_notes_int.attribute6
            , p_attribute7               => l_jtf_notes_int.attribute7
            , p_attribute8               => l_jtf_notes_int.attribute8
            , p_attribute9               => l_jtf_notes_int.attribute9
            , p_attribute10              => l_jtf_notes_int.attribute10
            , p_attribute11              => l_jtf_notes_int.attribute11
            , p_attribute12              => l_jtf_notes_int.attribute12
            , p_attribute13              => l_jtf_notes_int.attribute13
            , p_attribute14              => l_jtf_notes_int.attribute14
            , p_attribute15              => l_jtf_notes_int.attribute15
            , p_context                  => l_jtf_notes_int.context
            , p_note_type                => l_jtf_notes_int.note_type

        );

        x_notes_return_status := lc_return_status;

        log_debug_msg('After calling Create_note API');
        log_debug_msg('ln_jtf_note_id = '||ln_jtf_note_id);
        log_debug_msg('lc_return_status = '||lc_return_status);

        IF lc_return_status = 'S' THEN

            log_debug_msg('successfully created !!!');

            BEGIN

                UPDATE  jtf_notes_b
                SET     orig_system_reference = l_jtf_notes_int.jtf_note_orig_system_ref
                WHERE   jtf_note_id           = ln_jtf_note_id;

            EXCEPTION

                WHEN NO_DATA_FOUND THEN
                    l_msg_text := 'WHEN NO_DATA_FOUND : Error in updating orig_sys_reference col'||SQLERRM;
                    log_debug_msg(l_msg_text);
                    g_errbuf                           :=  l_msg_text;
                    g_staging_column_name              := 'JTF_NOTES_PUB.CREATE_NOTE';
                    g_staging_column_value             := 'JTF_NOTES_PUB.CREATE_NOTE';
                    log_debug_msg(g_procedure_name||' : '||g_errbuf);
                    log_exception
                    (
                        p_procedure_name            => g_procedure_name
                       ,p_staging_column_name       => g_staging_column_name
                       ,p_staging_column_value      => g_staging_column_value
                       ,p_exception_log             => g_errbuf
                       ,p_oracle_error_code         => SQLERRM
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR
                       ,p_batch_id                  => l_jtf_notes_int.batch_id
                   );                    

                WHEN OTHERS THEN
                    l_msg_text := 'WHEN OTHERS : Error in updating orig_sys_reference col'||SQLERRM;
                    log_debug_msg(l_msg_text);
                    g_errbuf                           :=  l_msg_text;
                    g_staging_column_name              := 'JTF_NOTES_PUB.CREATE_NOTE';
                    g_staging_column_value             := 'JTF_NOTES_PUB.CREATE_NOTE';
                    log_debug_msg(g_procedure_name||' : '||g_errbuf);
                    log_exception
                    (
                        p_procedure_name            => g_procedure_name
                       ,p_staging_column_name       => g_staging_column_name
                       ,p_staging_column_value      => g_staging_column_value
                       ,p_exception_log             => g_errbuf
                       ,p_oracle_error_code         => SQLERRM
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
                       ,p_batch_id                  => l_jtf_notes_int.batch_id
                   );                      
            END;

        ELSE
            log_debug_msg('not created !!!');
            IF ln_msg_count >= 1 THEN
                FOR I IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||I||' . '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                END LOOP;
            END IF;
            g_errbuf                           :=  l_msg_text;
            g_staging_column_name              := 'JTF_NOTES_PUB.CREATE_NOTE';
            g_staging_column_value             := 'JTF_NOTES_PUB.CREATE_NOTE';
            log_debug_msg(g_procedure_name||' : '||g_errbuf);
            log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => SQLERRM
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR
                   ,p_batch_id                  => l_jtf_notes_int.batch_id
                );             
        END IF;

    END IF;

END create_note;

-- +===================================================================+
-- | Name        : create_note_context                                 |
-- | Description : Procedure to create a new customer notes            |
-- |                                                                   |
-- | Parameters  : l_jtf_note_context_int                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Create_note_context
    (
         l_jtf_note_context_int          IN   XX_JTF_NOTE_CTX_INT%ROWTYPE
        ,x_note_context_return_status    OUT  VARCHAR
    )

AS

    lc_return_status                    VARCHAR2(1);
    lc_msg_data                         VARCHAR2(2000);
    ln_api_version                      NUMBER := 1.0;
    lc_init_msg_list                    VARCHAR2(1);
    ln_jtf_note_id                      NUMBER := NULL;
    ln_msg_count                        NUMBER;

    ln_source_object_code               VARCHAR2(250);
    ln_note_context_type_id             NUMBER;
    ln_jtf_note_context_id              NUMBER;
    lb_note_context_create_flag         BOOLEAN := TRUE;

    ln_conversion_note_context_id       NUMBER := 1381.2;

    lc_procedure_name                   VARCHAR2(250):='XX_JTF_NOTES_PKG.CREATE_NOTE_CONTEXT';
    lc_staging_table_name               VARCHAR2(250):='XX_JTF_NOTE_CTX_INT';
    lc_exception_log                    VARCHAR2(2000);
    lc_oracle_error_msg                 VARCHAR2(2000);
    lc_staging_column_name              VARCHAR2(32);
    lc_staging_column_value             VARCHAR2(500);
    l_msg_text                          VARCHAR2(4200);
    ln_orig_system                      VARCHAR2(30);
    lc_msg_data                         VARCHAR2(250);
    
BEGIN
    g_staging_table_name         := 'XX_JTF_NOTE_CTX_INT';
    g_procedure_name             := lc_procedure_name;
    g_batch_id                   := l_jtf_note_context_int.batch_id;

    --------------------------------
    -- Data validations
    --------------------------------
    IF l_jtf_note_context_int.jtf_note_orig_system_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0031_JTF_NOTE_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        g_staging_column_name              := 'jtf_note_orig_system_ref';
        g_staging_column_value             := l_jtf_note_context_int.jtf_note_orig_system_ref;
        log_debug_msg(g_procedure_name||' : '||g_errbuf);
        log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => 'XX_SFA_0031_JTF_NOTE_OSR_NULL'
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
                   ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
                ); 
        lb_note_context_create_flag := FALSE;
    END IF;


    IF l_jtf_note_context_int.note_context_type IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0032_NOTE_CT_TYPE_NULL');
        g_errbuf := FND_MESSAGE.GET;
        g_staging_column_name              := 'note_context_type';
        g_staging_column_value             := l_jtf_note_context_int.note_context_type;
        log_debug_msg(g_procedure_name||' : '||g_errbuf);
        log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => 'XX_SFA_0032_NOTE_CT_TYPE_NULL'
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR
                   ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
                ); 
        lb_note_context_create_flag := FALSE;
    END IF;

    IF l_jtf_note_context_int.jtf_note_ctx_orig_system_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0033_JTF_NT_CT_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        g_staging_column_name              := 'jtf_note_ctx_orig_system_ref';
        g_staging_column_value             := l_jtf_note_context_int.jtf_note_ctx_orig_system_ref;
        log_debug_msg(g_procedure_name||' : '||g_errbuf);
        log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => 'XX_SFA_0033_JTF_NT_CT_OSR_NULL'
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
                   ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
                ); 
        lb_note_context_create_flag := FALSE;
    END IF;


    ----------------------------------------------------
    -- Checking whether jtf_note_ctx_orig_system is a
    -- valid foreign key reference to HZ_ORIG_SYSTEMS_B
    ----------------------------------------------------
    IF l_jtf_note_context_int.jtf_note_ctx_orig_system IS NOT NULL THEN

        BEGIN

        SELECT  orig_system
        INTO    ln_orig_system
        FROM    hz_orig_systems_b
        WHERE   orig_system = l_jtf_note_context_int.jtf_note_ctx_orig_system;

        EXCEPTION

            WHEN NO_DATA_FOUND THEN

            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0034_INV_JTF_NT_CTX_OS');
            FND_MESSAGE.SET_TOKEN('P_NOTE_OS',l_jtf_note_context_int.jtf_note_ctx_orig_system);
            g_errbuf := 'WHEN NO_DATA_FOUND : '||FND_MESSAGE.GET;
            log_debug_msg(lc_procedure_name||' : '||g_errbuf);
            g_staging_column_name              := 'jtf_note_ctx_orig_system';
            g_staging_column_value             := l_jtf_note_context_int.jtf_note_ctx_orig_system;
            log_debug_msg(g_procedure_name||' : '||g_errbuf);
            log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => 'XX_SFA_0034_INV_JTF_NT_CTX_OS'
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR
                   ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
                ); 
            lb_note_context_create_flag := FALSE;

            WHEN OTHERS THEN

            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0034_INV_JTF_NT_CTX_OS');
            FND_MESSAGE.SET_TOKEN('P_NOTE_OS',l_jtf_note_context_int.jtf_note_ctx_orig_system);
            g_errbuf := 'WHEN OTHERS : '||FND_MESSAGE.GET;
            log_debug_msg(lc_procedure_name||' : '||g_errbuf);
            g_staging_column_name              := 'jtf_note_ctx_orig_system';
            g_staging_column_value             := l_jtf_note_context_int.jtf_note_ctx_orig_system;
            log_debug_msg(g_procedure_name||' : '||g_errbuf);
            log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => 'XX_SFA_0034_INV_JTF_NT_CTX_OS'
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR
                   ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
                );  
            lb_note_context_create_flag := FALSE;
        END;
    END IF;

    IF l_jtf_note_context_int.note_context_type IS NOT NULL THEN
        -- Check if note_context_type is a foreign key reference in JTF_OBJECTS_B
        BEGIN

        SELECT  object_code
        INTO    ln_source_object_code
        FROM    jtf_objects_b
        WHERE   object_code = l_jtf_note_context_int.note_context_type;

        EXCEPTION
        
            WHEN NO_DATA_FOUND THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0035_INV_NT_CT_TYPE');
                FND_MESSAGE.SET_TOKEN('P_NOTE_CT',l_jtf_note_context_int.note_context_type);
                g_errbuf := 'WHEN NO_DATA_FOUND : '||FND_MESSAGE.GET;
                g_staging_column_name              := 'note_context_type';
                g_staging_column_value             := l_jtf_note_context_int.note_context_type;
                log_debug_msg(g_procedure_name||' : '||g_errbuf);
                log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => 'XX_SFA_0035_INV_NT_CT_TYPE'
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR
                   ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
                );  
                lb_note_context_create_flag := FALSE;        
        
            WHEN OTHERS THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0035_INV_NT_CT_TYPE');
                FND_MESSAGE.SET_TOKEN('P_NOTE_CT',l_jtf_note_context_int.note_context_type);
                g_errbuf := 'WHEN OTHERS : '||FND_MESSAGE.GET;
                g_staging_column_name              := 'note_context_type';
                g_staging_column_value             := l_jtf_note_context_int.note_context_type;
                log_debug_msg(g_procedure_name||' : '||g_errbuf);
                log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => 'XX_SFA_0035_INV_NT_CT_TYPE'
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
                   ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
                );  
                lb_note_context_create_flag := FALSE;
        END;

    END IF;


    ---------------------------------
    -- Retrieving jtf_note_id
    ---------------------------------

    IF l_jtf_note_context_int.jtf_note_orig_system_ref IS NOT NULL THEN

        Get_note_id
            (
                 p_note_orig_system_ref => l_jtf_note_context_int.jtf_note_orig_system_ref
               , p_note_type            => null
               , x_note_id              => ln_jtf_note_id
            );

        log_debug_msg(lc_procedure_name||': x_note_id:'||ln_jtf_note_id);
        IF ln_jtf_note_id IS NULL THEN

            lb_note_context_create_flag := FALSE;
            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0036_JTF_NT_ID_NT_FOUND');
            FND_MESSAGE.SET_TOKEN('P_NOTE_OSR',l_jtf_note_context_int.jtf_note_orig_system_ref);
            g_errbuf := FND_MESSAGE.GET;
            g_staging_column_name               := 'jtf_note_orig_system_ref';
            g_staging_column_value              := l_jtf_note_context_int.jtf_note_orig_system_ref;
            log_debug_msg(lc_procedure_name||' : '||g_errbuf);
            log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => 'XX_SFA_0036_JTF_NT_ID_NT_FOUND'
                   ,p_msg_severity              => 'MINOR'  -- MAJOR, MEDIUM, MINOR
                   ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
                );   
        END IF;

    END IF;


    ----------------------------------------------
    -- Retrieving note_context_type_id
    ----------------------------------------------

    IF l_jtf_note_context_int.note_context_type IS NOT NULL AND
    l_jtf_note_context_int.jtf_note_ctx_orig_system_ref IS NOT NULL THEN

        Get_object_source_id
            (
                 p_source_object_code            => l_jtf_note_context_int.note_context_type
                ,p_source_object_orig_sys_ref    => l_jtf_note_context_int.jtf_note_ctx_orig_system_ref
                ,p_source_object_orig_sys        => l_jtf_note_context_int.jtf_note_ctx_orig_system
                ,x_object_source_id              => ln_note_context_type_id
            );

            log_debug_msg(lc_procedure_name||': x_object_source_id:'||ln_note_context_type_id);

            IF ln_note_context_type_id IS NULL THEN
                lb_note_context_create_flag := FALSE;

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0037_NT_CT_TP_ID_NFOUND');
                FND_MESSAGE.SET_TOKEN('P_NOTE_CTX_OSR',l_jtf_note_context_int.jtf_note_ctx_orig_system_ref);
                g_errbuf := FND_MESSAGE.GET;
                g_staging_column_name               := 'jtf_note_orig_system_ref';
                g_staging_column_value              := l_jtf_note_context_int.jtf_note_ctx_orig_system_ref;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf);
                log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => 'XX_SFA_0037_NT_CT_TP_ID_NFOUND'
                   ,p_msg_severity              => 'MINOR'  -- MAJOR, MEDIUM, MINOR 
                   ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
                );                       
            END IF;

    END IF;

    ------------------------------------------------
    -- Retrieving note_context_id
    ------------------------------------------------

    IF l_jtf_note_context_int.note_context_type IS NOT NULL AND
       ln_note_context_type_id IS NOT NULL AND
       ln_jtf_note_id IS NOT NULL THEN

        BEGIN
        
        g_procedure_name                := 'Create_note_context';    
        g_staging_column_name           := 'NOTE_CONTEXT_TYPE';
        g_staging_column_value          :=  l_jtf_note_context_int.note_context_type;

        SELECT  note_context_id
        INTO    ln_jtf_note_context_id
        FROM    jtf_note_contexts
        WHERE   jtf_note_id             = ln_jtf_note_id
        AND     note_context_type       = l_jtf_note_context_int.note_context_type
        AND     note_context_type_id    = ln_note_context_type_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                ln_jtf_note_context_id := NULL;
                g_errbuf   :='WHEN NO_DATA_FOUND Error'||SQLCODE ||', '||SQLERRM;
                log_debug_msg(g_errbuf);
                log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => SQLCODE
                   ,p_msg_severity              => 'MINOR'  -- MAJOR, MEDIUM, MINOR
                   ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
                );                  
            WHEN OTHERS THEN
                ln_jtf_note_context_id := NULL;
                g_errbuf   :='WHEN OTHERS Error'||SQLCODE ||', '||SQLERRM;
                log_debug_msg(g_errbuf);
                log_exception
                (
                    p_procedure_name            => g_procedure_name
                   ,p_staging_column_name       => g_staging_column_name
                   ,p_staging_column_value      => g_staging_column_value
                   ,p_exception_log             => g_errbuf
                   ,p_oracle_error_code         => SQLCODE
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
                   ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
                );                   
        END;

    END IF;

    log_debug_msg(lc_procedure_name||': ln_jtf_note_context_id:'||ln_jtf_note_context_id);

    IF lb_note_context_create_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||': Cannot create/update note context - Validation Failed');
        x_note_context_return_status := 'V';
         g_procedure_name                := 'Create_note_context';    
	 g_staging_column_name           := 'NOTE_CONTEXT_TYPE';
	 g_staging_column_value          :=  l_jtf_note_context_int.note_context_type;
	 g_errbuf                        := 'Error: Cannot create/update note context - Validation Failed';
	 log_debug_msg (g_errbuf);
	
	 log_exception
	       (
	        p_procedure_name            => g_procedure_name
	        ,p_staging_column_name       => g_staging_column_name
	        ,p_staging_column_value      => g_staging_column_value
	        ,p_exception_log             => g_errbuf
	        ,p_oracle_error_code         => SQLCODE
	        ,p_msg_severity              => 'MAJOR'  
	        ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
               );         
        RETURN;
    END IF;


    IF ln_jtf_note_context_id IS NOT NULL THEN

        log_debug_msg(CHR(10)||lc_procedure_name||': Duplicate note context is found for the note_context_id');
        x_note_context_return_status     := 'D';
        g_procedure_name                := 'Create_note_context';    
		 g_staging_column_name           := 'NOTE_CONTEXT_TYPE';
		 g_staging_column_value          :=  l_jtf_note_context_int.note_context_type;
		 g_errbuf                        := 'Error:Duplicate note context is found for the note_context_id.';
		 log_debug_msg (g_errbuf);
		
		 log_exception
		       (
		        p_procedure_name            => g_procedure_name
		        ,p_staging_column_name       => g_staging_column_name
		        ,p_staging_column_value      => g_staging_column_value
		        ,p_exception_log             => g_errbuf
		        ,p_oracle_error_code         => SQLCODE
		        ,p_msg_severity              => 'MAJOR'  
		        ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
               );         
        RETURN;

    ELSE

        -------------------------
        -- Create note context
        -------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': create a new note');
        log_debug_msg('-------------------------------------');


       jtf_notes_pub.Create_note_context
        (
             p_validation_level         => FND_API.G_VALID_LEVEL_FULL
           , x_return_status            => lc_return_status
           , p_jtf_note_id              => ln_jtf_note_id
           , p_last_update_date         => TO_DATE('1','j')
           , p_last_updated_by          => FND_GLOBAL.USER_ID
           , p_creation_date            => SYSDATE
           , p_created_by               => FND_GLOBAL.USER_ID
           , p_last_update_login        => FND_GLOBAL.LOGIN_ID
           , p_note_context_type_id     => ln_note_context_type_id
           , p_note_context_type        => l_jtf_note_context_int.note_context_type
           , x_note_context_id          => ln_jtf_note_context_id
        );

        x_note_context_return_status  := lc_return_status;

        log_debug_msg ('After calling Create_note_context API');
        log_debug_msg ('ln_jtf_note_context_id = '||ln_jtf_note_context_id);
        log_debug_msg ('lc_return_status = '||lc_return_status);

        IF lc_return_status = 'S' THEN
           
           log_debug_msg ('Note_context is successfully created !!!');
            
        ELSE
           g_procedure_name                := 'Create_note_context';    
           g_staging_column_name           := 'NOTE_CONTEXT_TYPE';
           g_staging_column_value          :=  l_jtf_note_context_int.note_context_type;
           g_errbuf                        := 'Error in creating Note Context.';
           log_debug_msg (g_errbuf);

           log_exception
               (
                   p_procedure_name            => g_procedure_name
                  ,p_staging_column_name       => g_staging_column_name
                  ,p_staging_column_value      => g_staging_column_value
                  ,p_exception_log             => g_errbuf
                  ,p_oracle_error_code         => SQLCODE
                  ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR 
                  ,p_batch_id                  =>  l_jtf_note_context_int.batch_id
               );         
        END IF;

    END IF;


END Create_note_context;

-- +===================================================================+
-- | Name        : Get_note_id                                         |
-- |                                                                   |
-- | Description : Procedure used to get note_id                       |
-- |                                                                   |
-- | Parameters  : p_note_orig_system_ref                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_note_id
    (
         p_note_orig_system_ref     IN  VARCHAR2
        ,p_note_type                IN VARCHAR2 default null
        ,x_note_id                  OUT NUMBER
    )
AS

BEGIN
    g_procedure_name                := 'Get_note_id';    
    g_staging_column_name           := 'NOTE_ORIG_SYSTEM_REF';
    g_staging_column_value          :=  p_note_orig_system_ref;
    
    SELECT  jtf_note_id
    INTO    x_note_id
    FROM    jtf_notes_b
    WHERE   orig_system_reference = p_note_orig_system_ref;


EXCEPTION
     WHEN NO_DATA_FOUND THEN
       IF p_note_type = 'NOTES' THEN
         x_note_id := NULL;
         NULL;
         ELSE
        x_note_id := NULL;
        g_errbuf  := 'NO_DATA_FOUND for jtf_note_id for orig_system_reference :'||p_note_orig_system_ref;
        log_debug_msg (g_errbuf);
 
        log_exception
            (
                p_procedure_name            => g_procedure_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_exception_log             => g_errbuf
               ,p_oracle_error_code         => SQLCODE
               ,p_msg_severity              => 'MINOR'  -- MAJOR, MEDIUM, MINOR  
               ,p_batch_id                  => g_batch_id
            );   
        END IF;
       
    WHEN OTHERS THEN
        x_note_id := NULL;
        g_errbuf  := 'WHEN OTHERS for jtf_note_id for orig_system_reference :'||p_note_orig_system_ref;
        log_debug_msg (g_errbuf);
 
        log_exception
            (
                p_procedure_name            => g_procedure_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_exception_log             => g_errbuf
               ,p_oracle_error_code         => SQLCODE
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR  
               ,p_batch_id                  => g_batch_id
            );

END  Get_note_id;

-- +===================================================================+
-- | Name        : Get_object_source_id                                |
-- |                                                                   |
-- | Description : Procedure used to get object_source_id              |
-- |                                                                   |
-- | Parameters  : p_source_object_code,p_source_object_orig_sys_ref   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_object_source_id
    (
         p_source_object_code               IN  VARCHAR2
        ,p_source_object_orig_sys_ref       IN  VARCHAR2
        ,p_source_object_orig_sys           IN  VARCHAR2
        ,x_object_source_id                 OUT NUMBER
    )
AS

lc_procedure_name   VARCHAR2(2000):= 'Get_object_source_id';

-- Cursor to fetch party_id
CURSOR  c_party_id
    (
        cp_source_object_orig_sys_ref   VARCHAR2
       ,cp_source_object_orig_sys       VARCHAR2
    )
IS
SELECT  owner_table_id
FROM    hz_orig_sys_references
WHERE   orig_system_reference = cp_source_object_orig_sys_ref
AND     orig_system           = cp_source_object_orig_sys
AND     owner_table_name      = 'HZ_PARTIES'
AND     status                = 'A';

-- Cursor to fetch party_site_id
CURSOR  c_party_site_id
    (
        cp_source_object_orig_sys_ref   VARCHAR2
       ,cp_source_object_orig_sys       VARCHAR2
    )
IS
SELECT  owner_table_id
FROM    hz_orig_sys_references
WHERE   orig_system_reference = cp_source_object_orig_sys_ref
AND     orig_system           = cp_source_object_orig_sys
AND     owner_table_name      = 'HZ_PARTY_SITES'
AND     status                = 'A';

-- Cursor to fetch lead_id
CURSOR  c_lead_id
    (
        cp_source_object_orig_sys_ref   VARCHAR2
    )
IS
SELECT  sales_lead_id
FROM    as_sales_leads
WHERE   orig_system_reference = cp_source_object_orig_sys_ref;

-- Cursor to fetch opportunity_id
CURSOR  c_opportunity_id
    (
        cp_source_object_orig_sys_ref   VARCHAR2
    )
IS
SELECT  lead_id
FROM    as_leads_all
WHERE   orig_system_reference = cp_source_object_orig_sys_ref;

-- Cursor to fetch task_id
CURSOR  c_task_id
    (
        cp_source_object_orig_sys_ref   VARCHAR2
    )
IS
SELECT  task_id
FROM    jtf_tasks_b
WHERE   orig_system_reference = p_source_object_orig_sys_ref;

BEGIN

        x_object_source_id := NULL;
        IF p_source_object_code = 'PARTY' THEN


            OPEN    c_party_id (p_source_object_orig_sys_ref,p_source_object_orig_sys);
            FETCH   c_party_id into  x_object_source_id;
            CLOSE   c_party_id;

            IF  x_object_source_id IS NULL THEN
                log_debug_msg(lc_procedure_name||': party_id not found, invalid source_object_orig_system_ref '||p_source_object_orig_sys_ref);
            END IF;

        ELSIF p_source_object_code = 'PARTY_SITE' THEN

            OPEN    c_party_site_id (p_source_object_orig_sys_ref,p_source_object_orig_sys);
            FETCH   c_party_site_id into  x_object_source_id;
            CLOSE   c_party_site_id;

            IF  x_object_source_id IS null THEN
                log_debug_msg(lc_procedure_name||': party_site_id not found, invalid source_object_orig_system_ref '||p_source_object_orig_sys_ref);
            END IF;


        ELSIF p_source_object_code = 'LEAD' THEN


            OPEN    c_lead_id (p_source_object_orig_sys_ref);
            FETCH   c_lead_id into  x_object_source_id;
            CLOSE   c_lead_id;

            IF  x_object_source_id IS NULL THEN
                log_debug_msg(lc_procedure_name||': sales_lead_id (LEAD) not found, invalid source_object_orig_system_ref '||p_source_object_orig_sys_ref);
            END IF;

        ELSIF p_source_object_code = 'OPPORTUNITY' THEN


            OPEN    c_opportunity_id (p_source_object_orig_sys_ref);
            FETCH   c_opportunity_id into  x_object_source_id;
            CLOSE   c_opportunity_id;

            IF  x_object_source_id IS null THEN
                log_debug_msg(lc_procedure_name||': lead_id (OPPORTUNITY) not found, invalid source_object_orig_system_ref '||p_source_object_orig_sys_ref);
            END IF;

        ELSIF p_source_object_code = 'TASK' THEN

            OPEN    c_task_id (p_source_object_orig_sys_ref);
            FETCH   c_task_id into  x_object_source_id;
            CLOSE   c_task_id;

            IF  x_object_source_id IS null THEN
                log_debug_msg(lc_procedure_name||': task_id (TASK) not found, invalid source_object_orig_system_ref '||p_source_object_orig_sys_ref);
            END IF;

        END IF;

END Get_object_source_id;


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
    --dbms_output.put_line(p_debug_msg);
    fnd_file.put_line(fnd_file.log,p_debug_msg);
    --END IF;
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
         p_procedure_name         IN VARCHAR2
        ,p_staging_column_name    IN VARCHAR2
        ,p_staging_column_value   IN VARCHAR2
        ,p_exception_log          IN VARCHAR2
        ,p_oracle_error_code      IN VARCHAR2
        ,p_msg_severity           IN VARCHAR2
        ,p_batch_id               IN NUMBER   -- Included Batch ID parameter
    )

AS
l_RETURN_CODE    VARCHAR2(1)  := 'E';
l_MSG_COUNT      NUMBER       := 1;
BEGIN

    XX_COM_ERROR_LOG_PUB.LOG_ERROR_CRM
        (
             P_RETURN_CODE             =>  l_RETURN_CODE
            ,P_MSG_COUNT               =>  l_MSG_COUNT
            ,P_APPLICATION_NAME        => 'XXCRM'        
            ,P_PROGRAM_TYPE            => 'I1381_NotesInterface'        
            ,P_PROGRAM_NAME            => 'XX_JTF_NOTES_PKG'
            ,P_PROGRAM_ID              =>  APPS.FND_GLOBAL.CONC_REQUEST_ID
            ,P_MODULE_NAME             => 'SFA'
            ,P_ERROR_LOCATION          =>  p_procedure_name
            ,P_ERROR_MESSAGE_COUNT     =>  1
            ,P_ERROR_MESSAGE_CODE      =>  p_oracle_error_code            
            ,P_ERROR_MESSAGE           =>  p_exception_log            
            ,P_ERROR_MESSAGE_SEVERITY  =>  p_msg_severity
            ,P_ERROR_STATUS            => 'ACTIVE'
            ,P_NOTIFY_FLAG             => 'N'
            ,P_OBJECT_TYPE             =>  p_staging_column_name
            ,P_OBJECT_ID               =>  p_staging_column_value
            ,P_ATTRIBUTE15             =>  p_batch_id         
        );

EXCEPTION
    WHEN OTHERS THEN
        log_debug_msg('LOG_EXCEPTION: Error in logging exception :'||SQLERRM);

END log_exception;

END XX_JTF_NOTES_PKG;
/

SHOW ERRORS;