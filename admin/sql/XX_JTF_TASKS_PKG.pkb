SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_JTF_TASKS_PKG
-- +====================================================================================+
-- |                        Office Depot - Project Simplify                             |
-- |                      Oracle NAIO Consulting Organization                           |
-- +====================================================================================+
-- | Name        : XX_JTF_TASKS_PKG                                                     |
-- | Description : Package to create Tasks, Task References, Task Assignments,          |
-- |               Task Dependencies and Task Recurrences                               |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version     Date           Author               Remarks                             |
-- |=======    ==========      ================     ====================================|
-- |1.0        17-Sept-2007    Bibhubrata Jena                                          |
-- |1.1        04-Apr-2008     Hema Chikkanna       Included Batch ID in error logging  |
-- |                                                procedure                           | 
-- +====================================================================================+

AS

-- +===================================================================+
-- | Name        : create_tasks_main                                   |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: JTF Tasks Creation Program'            |
-- | Parameters  : p_batch_id_from,p_batch_id_to                       |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_tasks_main
    (
         x_errbuf           OUT NOCOPY  VARCHAR2
        ,x_retcode          OUT NOCOPY  VARCHAR2
        ,p_batch_id_from    IN          NUMBER
        ,p_batch_id_to      IN          NUMBER
    )
AS

---------------------------
-- Cursors for Create Tasks
---------------------------
--Cursor to fecth distinct batch_ids from XX_JTF_IMP_TASKS_INT table
CURSOR lcu_get_tasks_batch_id
    (
          p_batch_id_from  NUMBER
        , p_batch_id_to    NUMBER
    )
IS
SELECT   DISTINCT batch_id
FROM     xx_jtf_imp_tasks_int
WHERE    batch_id BETWEEN p_batch_id_from AND p_batch_id_to
AND      interface_status IN ('1','4','6')
ORDER BY batch_id ASC;

--Cursor to fecth tasks records from XX_JTF_IMP_TASKS_INT table
CURSOR lcu_get_task_recs
    (
         cp_batch_id        NUMBER
    )
IS
SELECT  *
FROM    xx_jtf_imp_tasks_int
WHERE   batch_id = cp_batch_id
AND     interface_status IN ('1','4','6');

-------------------------------------
-- Cursors for Create Task References
-------------------------------------
--Cursor to fecth distinct batch_ids from XX_JTF_IMP_TASK_REFS_INT table
CURSOR lcu_get_task_ref_batch_id
    (
          p_batch_id_from  NUMBER
        , p_batch_id_to    NUMBER
    )
IS
SELECT  DISTINCT batch_id
FROM    xx_jtf_imp_task_refs_int
WHERE   batch_id BETWEEN p_batch_id_from AND p_batch_id_to
AND     interface_status IN ('1','4','6')
ORDER BY batch_id ASC;

--Cursor to fecth task reference records from XX_JTF_IMP_TASK_REFS_INT table
CURSOR lcu_get_task_ref_recs
    (
         cp_batch_id        NUMBER
    )
IS
SELECT  *
FROM    xx_jtf_imp_task_refs_int
WHERE   batch_id = cp_batch_id
AND     interface_status IN ('1','4','6');

--------------------------------------
-- Cursors for Create Task Assignments
--------------------------------------
--Cursor to fecth distinct batch_ids from XX_JTF_IMP_TASK_ASSGN_INT table
CURSOR lcu_get_task_assign_batch_id
    (
          p_batch_id_from  NUMBER
        , p_batch_id_to    NUMBER
    )
IS
SELECT  DISTINCT batch_id
FROM    xx_jtf_imp_task_assgn_int
WHERE   batch_id BETWEEN p_batch_id_from AND p_batch_id_to
AND     interface_status IN ('1','4','6')
ORDER BY batch_id ASC;

--Cursor to fecth task assignment records from XX_JTF_IMP_TASK_ASSGN_INT table
CURSOR lcu_get_task_assign_recs
    (
         cp_batch_id        NUMBER
    )
IS
SELECT  *
FROM    xx_jtf_imp_task_assgn_int
WHERE   batch_id = cp_batch_id
AND     interface_status IN ('1','4','6');


---------------------------------------
-- Cursors for Create Task Dependencies
---------------------------------------
--Cursor to fecth distinct batch_ids from XX_JTF_IMP_TASKS_DEPEND_INT table
CURSOR lcu_get_task_dep_batch_id
    (
          p_batch_id_from  NUMBER
        , p_batch_id_to    NUMBER
    )
IS
SELECT  DISTINCT batch_id
FROM    xx_jtf_imp_tasks_depend_int
WHERE   batch_id BETWEEN p_batch_id_from AND p_batch_id_to
AND     interface_status IN ('1','4','6')
ORDER BY batch_id ASC;

--Cursor to fecth task dependency records from XX_JTF_IMP_TASKS_DEPEND_INT table
CURSOR lcu_get_task_dep_recs
    (
         cp_batch_id        NUMBER
    )
IS
SELECT  *
FROM    xx_jtf_imp_tasks_depend_int
WHERE   batch_id = cp_batch_id
AND     interface_status IN ('1','4','6');

---------------------------------------
-- Cursors for Create Task Recurrences
---------------------------------------
--Cursor to fecth distinct batch_ids from XX_JTF_IMP_TASK_RECUR_INT table
CURSOR lcu_get_task_recur_batch_id
    (
          p_batch_id_from  NUMBER
        , p_batch_id_to    NUMBER
    )
IS
SELECT  DISTINCT batch_id
FROM    xx_jtf_imp_task_recur_int
WHERE   batch_id BETWEEN p_batch_id_from AND p_batch_id_to
AND     interface_status IN ('1','4','6')
ORDER BY batch_id ASC;

--Cursor to fecth task recurrent records from XX_JTF_IMP_TASK_RECUR_INT table
CURSOR lcu_get_task_recur_recs
    (
         cp_batch_id        NUMBER
    )
IS
SELECT  *
FROM    xx_jtf_imp_task_recur_int
WHERE   batch_id = cp_batch_id
AND     interface_status IN ('1','4','6');

--------------------
-- Create Tasks
--------------------
ln_batch_id                      NUMBER;
ln_tasks_rec_pro_succ            NUMBER          := 0;
ln_tasks_rec_pro_fail            NUMBER          := 0;
ln_tasks_rec_duplicated          NUMBER          := 0;
TYPE task_interface_status_tbl_type      IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;
lt_task_interface_status         task_interface_status_tbl_type;
TYPE record_id_tbl_type          IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
lt_tasks_record_id_table         record_id_tbl_type;
TYPE task_tbl_type               IS TABLE OF xx_jtf_imp_tasks_int%ROWTYPE;
lt_tasks_table                   task_tbl_type;
ln_task_conversion_id            NUMBER          := 801.1;
lc_tasks_return_status           VARCHAR2(1)     := 'E';
lc_task_pro_rec_read             NUMBER          := 0;

-------------------------
-- Create Task References
-------------------------
ln_task_refs_rec_pro_succ        NUMBER          := 0;
ln_task_refs_rec_pro_fail        NUMBER          := 0;
ln_task_refs_rec_duplicated      NUMBER          := 0;
lt_task_refs_interface_status    task_interface_status_tbl_type;
lt_task_refs_record_id_table     record_id_tbl_type;
TYPE task_refs_tbl_type          IS TABLE OF xx_jtf_imp_task_refs_int%ROWTYPE;
lt_task_refs_table               task_refs_tbl_type;
ln_task_refs_conversion_id       NUMBER          := 801.2;
lc_task_refs_return_status       VARCHAR2(1)     := 'E';
lc_task_refs_pro_rec_read        NUMBER          := 0;

--------------------------
-- Create Task Assignments
--------------------------
ln_task_assgn_rec_pro_succ        NUMBER          := 0;
ln_task_assgn_rec_pro_fail        NUMBER          := 0;
ln_task_assgn_rec_duplicated      NUMBER          := 0;
lt_task_assgn_interface_status    task_interface_status_tbl_type;
lt_task_assgn_record_id_table     record_id_tbl_type;
TYPE task_assgn_tbl_type          IS TABLE OF xx_jtf_imp_task_assgn_int%ROWTYPE;
lt_task_assgn_table               task_assgn_tbl_type;
ln_task_assgn_conversion_id       NUMBER          := 801.3;
lc_task_assgn_return_status       VARCHAR2(1)     := 'E';
lc_task_assgn_pro_rec_read        NUMBER          := 0;

---------------------------
-- Create Task Dependencies
---------------------------
ln_task_depend_rec_pro_succ        NUMBER          := 0;
ln_task_depend_rec_pro_fail        NUMBER          := 0;
ln_task_depend_rec_duplicated      NUMBER          := 0;
lt_task_dpnd_interface_status    task_interface_status_tbl_type;
lt_task_depend_record_id_table     record_id_tbl_type;
TYPE task_depend_tbl_type          IS TABLE OF xx_jtf_imp_tasks_depend_int%ROWTYPE;
lt_task_depend_table               task_depend_tbl_type;
ln_task_depend_conversion_id       NUMBER          := 801.4;
lc_task_depend_return_status       VARCHAR2(1)     := 'E';
lc_task_depend_pro_rec_read        NUMBER          := 0;

---------------------------
-- Create Task Recurrences
---------------------------
ln_task_recur_rec_pro_succ        NUMBER          := 0;
ln_task_recur_rec_pro_fail        NUMBER          := 0;
ln_task_recur_rec_duplicated      NUMBER          := 0;
lt_task_recur_interface_status    task_interface_status_tbl_type;
lt_task_recur_record_id_table     record_id_tbl_type;
TYPE task_recur_tbl_type          IS TABLE OF xx_jtf_imp_task_recur_int%ROWTYPE;
lt_task_recur_table               task_recur_tbl_type;
ln_task_recur_conversion_id       NUMBER          := 801.5;
lc_task_recur_return_status       VARCHAR2(1)     := 'E';
lc_task_recur_pro_rec_read        NUMBER          := 0;

BEGIN

    --************************** Part:1 Create Tasks ****************************--
    log_debug_msg('==================   BEGIN  =======================');
    log_debug_msg('================ Create Tasks ====================='||CHR(10));

    BEGIN

        log_debug_msg('p_batch_id_from = '||p_batch_id_from);
        log_debug_msg('p_batch_id_to = '||p_batch_id_to);

        FOR idx IN lcu_get_tasks_batch_id
            (     p_batch_id_from  => p_batch_id_from
                , p_batch_id_to    => p_batch_id_to
            )
        LOOP

            ln_batch_id := idx.batch_id;

            ln_tasks_rec_pro_succ   := 0;
            ln_tasks_rec_pro_fail   := 0;
            ln_tasks_rec_duplicated := 0;

            lt_task_interface_status.DELETE;
            lt_tasks_record_id_table.DELETE;

            log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.BEGIN *********************'||CHR(10));

            OPEN lcu_get_task_recs
                (
                     cp_batch_id   => ln_batch_id
                );
            FETCH lcu_get_task_recs BULK COLLECT INTO lt_tasks_table;
            CLOSE lcu_get_task_recs;

            IF  lt_tasks_table.COUNT < 1 THEN
                log_debug_msg('No records found for the batch_id = '||ln_batch_id);
            ELSE

                log_debug_msg('Records found for the batch_id ('||ln_batch_id||')'||'= '||lt_tasks_table.COUNT||CHR(10));

                XX_COM_CONV_ELEMENTS_PKG.Log_control_info_proc
                    (
                          p_conversion_id            => ln_task_conversion_id
                        , p_batch_id                 => ln_batch_id
                        , p_num_bus_objs_processed   => 0
                    );

                FOR i IN lt_tasks_table.first .. lt_tasks_table.last
                LOOP
                    lc_tasks_return_status       := 'E';
                    log_debug_msg(CHR(10)||'Record-id:'||lt_tasks_table(i).record_id);
                    log_debug_msg('=====================');

                    --Creating tasks
                    create_task
                        (
                            l_jtf_tasks_int         => lt_tasks_table(i)
                          , x_tasks_return_status   => lc_tasks_return_status
                        );

                    lt_tasks_record_id_table(i) := lt_tasks_table(i).record_id;

                    IF lc_tasks_return_status = 'S' THEN
                        --Processing Successful
                        lt_task_interface_status(i) := '7';
                        ln_tasks_rec_pro_succ := ln_tasks_rec_pro_succ+1;

                    ELSIF lc_tasks_return_status = 'V' THEN
                        -- Validation Falied
                        lt_task_interface_status(i) := '6';
                        ln_tasks_rec_duplicated := ln_tasks_rec_duplicated+1;
                    ELSE
                        --Processing Failed
                        lt_task_interface_status(i) := '6';
                        ln_tasks_rec_pro_fail := ln_tasks_rec_pro_fail+1;
                    END IF;

                END LOOP;
                COMMIT;

                --Bulk update of interface_status column
                IF lt_tasks_record_id_table.last > 0 THEN
                  FORALL i IN 1 .. lt_tasks_record_id_table.last
                      UPDATE xx_jtf_imp_tasks_int
                      SET    interface_status  = lt_task_interface_status(i)
                      WHERE  record_id = lt_tasks_record_id_table(i);
                END IF;

                COMMIT;
                --No.of processed,failed,succeeded records - start
                lc_task_pro_rec_read := (ln_tasks_rec_pro_succ + ln_tasks_rec_pro_fail+ln_tasks_rec_duplicated);
                log_debug_msg(CHR(10)||'-----------------------------------------------------------');
                log_debug_msg('Total no.of records read = '||lc_task_pro_rec_read);
                log_debug_msg('Total no.of records succeeded = '||ln_tasks_rec_pro_succ);
                log_debug_msg('Total no.of records process failed = '||ln_tasks_rec_pro_fail);
                log_debug_msg('Total no.of records validation failed = '||ln_tasks_rec_duplicated);
                log_debug_msg('-----------------------------------------------------------');

                fnd_file.put_line(fnd_file.output,'================ Create Tasks =================');
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');
                fnd_file.put_line(fnd_file.output,'Total no.of records read = '||lc_task_pro_rec_read);
                fnd_file.put_line(fnd_file.output,'Total no.of records succeeded = '||ln_tasks_rec_pro_succ);
                fnd_file.put_line(fnd_file.output,'Total no.of records process failed = '||ln_tasks_rec_pro_fail);
                fnd_file.put_line(fnd_file.output,'Total no.of records validation failed = '||ln_tasks_rec_duplicated);
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');

                XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
                    (
                          p_conc_mst_req_id              => APPS.FND_GLOBAL.CONC_REQUEST_ID
                        , p_batch_id                     => ln_batch_id
                        , p_conversion_id                => ln_task_conversion_id
                        , p_num_bus_objs_failed_valid    => 0
                        , p_num_bus_objs_failed_process  => ln_tasks_rec_pro_fail
                        , p_num_bus_objs_succ_process    => ln_tasks_rec_pro_succ
                    );
                log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.END *********************'||CHR(10));

            END IF;

        END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf    :='Other Exceptions in create_tasks_main procedure '||SQLERRM;
        x_retcode   :='2';
    END;
    log_debug_msg(CHR(10)||'-----------------------       END        ----------------------');

    --************************** Part:2 Create Task References ****************************--
    log_debug_msg('==================   BEGIN  =======================');
    log_debug_msg('============ Create Task References ==============='||CHR(10));

    BEGIN

        log_debug_msg('p_batch_id_from = '||p_batch_id_from);
        log_debug_msg('p_batch_id_to = '||p_batch_id_to);

        FOR idx IN lcu_get_task_ref_batch_id
            (     p_batch_id_from  => p_batch_id_from
                , p_batch_id_to    => p_batch_id_to
            )
        LOOP

            ln_batch_id := idx.batch_id;

            ln_task_refs_rec_pro_succ   := 0;
            ln_task_refs_rec_pro_fail   := 0;
            ln_task_refs_rec_duplicated := 0;

            lt_task_refs_interface_status.DELETE;
            lt_task_refs_record_id_table.DELETE;


            log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.BEGIN *********************'||CHR(10));

            OPEN lcu_get_task_ref_recs
                (
                     cp_batch_id   => ln_batch_id
                );
            FETCH lcu_get_task_ref_recs BULK COLLECT INTO lt_task_refs_table;
            CLOSE lcu_get_task_ref_recs;

            IF  lt_task_refs_table.COUNT < 1 THEN
                log_debug_msg('No records found for the batch_id = '||ln_batch_id);
            ELSE

                log_debug_msg('Records found for the batch_id ('||ln_batch_id||')'||'= '||lt_task_refs_table.COUNT||CHR(10));

                XX_COM_CONV_ELEMENTS_PKG.Log_control_info_proc
                    (
                          p_conversion_id            => ln_task_refs_conversion_id
                        , p_batch_id                 => ln_batch_id
                        , p_num_bus_objs_processed   => 0
                    );

                FOR i IN lt_task_refs_table.first .. lt_task_refs_table.last
                LOOP
                    lc_task_refs_return_status       := 'E';
                    log_debug_msg(CHR(10)||'Record-id:'||lt_task_refs_table(i).record_id);
                    log_debug_msg('=====================');

                    --Creating task references
                    create_task_references
                        (
                            l_jtf_task_refs_int         => lt_task_refs_table(i)
                          , x_task_refs_return_status   => lc_task_refs_return_status
                        );

                    lt_task_refs_record_id_table(i) := lt_task_refs_table(i).record_id;

                    IF lc_task_refs_return_status = 'S' THEN
                        -- Processing Successful
                        lt_task_refs_interface_status(i) := '7';
                        ln_task_refs_rec_pro_succ := ln_task_refs_rec_pro_succ+1;

                    ELSIF lc_task_refs_return_status = 'V' THEN
                        -- Validation Falied
                        lt_task_refs_interface_status(i) := '6';
                        ln_task_refs_rec_duplicated := ln_task_refs_rec_duplicated+1;
                    ELSE
                        -- Processing Failed
                        lt_task_refs_interface_status(i) := '6';
                        ln_task_refs_rec_pro_fail := ln_task_refs_rec_pro_fail+1;
                    END IF;

                END LOOP;
                COMMIT;

                --Bulk update of interface_status column
                IF lt_task_refs_record_id_table.last > 0 THEN
                  FORALL i IN 1 .. lt_task_refs_record_id_table.last
                      UPDATE xx_jtf_imp_task_refs_int
                      SET    interface_status  = lt_task_refs_interface_status(i)
                      WHERE  record_id = lt_task_refs_record_id_table(i);
                END IF;

                COMMIT;
                --No.of processed,failed,succeeded records - start
                lc_task_refs_pro_rec_read := (ln_task_refs_rec_pro_succ + ln_task_refs_rec_pro_fail+ln_task_refs_rec_duplicated);
                log_debug_msg(CHR(10)||'-----------------------------------------------------------');
                log_debug_msg('Total no.of records read = '||lc_task_refs_pro_rec_read);
                log_debug_msg('Total no.of records succeeded = '||ln_task_refs_rec_pro_succ);
                log_debug_msg('Total no.of records process failed = '||ln_task_refs_rec_pro_fail);
                log_debug_msg('Total no.of records validation failed = '||ln_task_refs_rec_duplicated);
                log_debug_msg('-----------------------------------------------------------');

                fnd_file.put_line(fnd_file.output,'================ Create Task References =================');
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');
                fnd_file.put_line(fnd_file.output,'Total no.of records read = '||lc_task_refs_pro_rec_read);
                fnd_file.put_line(fnd_file.output,'Total no.of records succeeded = '||ln_task_refs_rec_pro_succ);
                fnd_file.put_line(fnd_file.output,'Total no.of records process failed = '||ln_task_refs_rec_pro_fail);
                fnd_file.put_line(fnd_file.output,'Total no.of records validation failed = '||ln_task_refs_rec_duplicated);
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');

                XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
                    (
                          p_conc_mst_req_id              => APPS.FND_GLOBAL.CONC_REQUEST_ID
                        , p_batch_id                     => ln_batch_id
                        , p_conversion_id                => ln_task_refs_conversion_id
                        , p_num_bus_objs_failed_valid    => 0
                        , p_num_bus_objs_failed_process  => ln_task_refs_rec_pro_fail
                        , p_num_bus_objs_succ_process    => ln_task_refs_rec_pro_succ
                    );
                log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.END *********************'||CHR(10));

            END IF;

        END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf    :='Other Exceptions in create_tasks_main procedure '||SQLERRM;
        x_retcode   :='2';
    END;
    log_debug_msg(CHR(10)||'-----------------------       END        ----------------------');

    --************************** Part:3 Create Task Assignments ****************************--
    log_debug_msg('==================   BEGIN  =======================');
    log_debug_msg('============ Create Task Assignments ==============='||CHR(10));

    BEGIN

        log_debug_msg('p_batch_id_from = '||p_batch_id_from);
        log_debug_msg('p_batch_id_to = '||p_batch_id_to);

        FOR idx IN lcu_get_task_assign_batch_id
            (     p_batch_id_from  => p_batch_id_from
                , p_batch_id_to    => p_batch_id_to
            )
        LOOP

            ln_batch_id := idx.batch_id;

            ln_task_assgn_rec_pro_succ   := 0;
            ln_task_assgn_rec_pro_fail   := 0;
            ln_task_assgn_rec_duplicated := 0;

            lt_task_assgn_interface_status.DELETE;
            lt_task_assgn_record_id_table.DELETE;


            log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.BEGIN *********************'||CHR(10));

            OPEN lcu_get_task_assign_recs
                (
                     cp_batch_id   => ln_batch_id
                );
            FETCH lcu_get_task_assign_recs BULK COLLECT INTO lt_task_assgn_table;
            CLOSE lcu_get_task_assign_recs;

            IF  lt_task_assgn_table.COUNT < 1 THEN
                log_debug_msg('No records found for the batch_id = '||ln_batch_id);
            ELSE

                log_debug_msg('Records found for the batch_id ('||ln_batch_id||')'||'= '||lt_task_assgn_table.COUNT||CHR(10));

                XX_COM_CONV_ELEMENTS_PKG.Log_control_info_proc
                    (
                          p_conversion_id            => ln_task_assgn_conversion_id
                        , p_batch_id                 => ln_batch_id
                        , p_num_bus_objs_processed   => 0
                    );

                FOR i IN lt_task_assgn_table.first .. lt_task_assgn_table.last
                LOOP
                    lc_task_assgn_return_status       := 'E';
                    log_debug_msg(CHR(10)||'Record-id:'||lt_task_assgn_table(i).record_id);
                    log_debug_msg('=====================');

                    --Creating task assignments
                    create_task_assignment
                        (
                            l_jtf_task_assgn_int         => lt_task_assgn_table(i)
                          , x_task_assgn_ret_status      => lc_task_assgn_return_status
                        );

                    lt_task_assgn_record_id_table(i) := lt_task_assgn_table(i).record_id;

                    IF lc_task_assgn_return_status = 'S' THEN
                        --Processing Successful
                        lt_task_assgn_interface_status(i) := '7';
                        ln_task_assgn_rec_pro_succ := ln_task_assgn_rec_pro_succ+1;

                    ELSIF lc_task_assgn_return_status = 'V' THEN
                        -- Validation Falied
                        lt_task_assgn_interface_status(i) := '6';
                        ln_task_assgn_rec_duplicated := ln_task_assgn_rec_duplicated+1;
                    ELSE
                        --Processing Failed
                        lt_task_assgn_interface_status(i) := '6';
                        ln_task_assgn_rec_pro_fail := ln_task_assgn_rec_pro_fail+1;
                    END IF;

                END LOOP;
                COMMIT;

                --Bulk update of interface_status column
                IF lt_task_assgn_record_id_table.last > 0 THEN
                  FORALL i IN 1 .. lt_task_assgn_record_id_table.last
                      UPDATE xx_jtf_imp_task_assgn_int
                      SET    interface_status  = lt_task_assgn_interface_status(i)
                      WHERE  record_id = lt_task_assgn_record_id_table(i);
                END IF;

                COMMIT;
                --No.of processed,failed,succeeded records - start
                lc_task_assgn_pro_rec_read := (ln_task_assgn_rec_pro_succ + ln_task_assgn_rec_pro_fail+ln_task_assgn_rec_duplicated);
                log_debug_msg(CHR(10)||'-----------------------------------------------------------');
                log_debug_msg('Total no.of records read = '||lc_task_assgn_pro_rec_read);
                log_debug_msg('Total no.of records succeeded = '||ln_task_assgn_rec_pro_succ);
                log_debug_msg('Total no.of records process failed = '||ln_task_assgn_rec_pro_fail);
                log_debug_msg('Total no.of records validation failed= '||ln_task_assgn_rec_duplicated);
                log_debug_msg('-----------------------------------------------------------');

                fnd_file.put_line(fnd_file.output,'================ Create Task References =================');
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');
                fnd_file.put_line(fnd_file.output,'Total no.of records read = '||lc_task_assgn_pro_rec_read);
                fnd_file.put_line(fnd_file.output,'Total no.of records succeeded = '||ln_task_assgn_rec_pro_succ);
                fnd_file.put_line(fnd_file.output,'Total no.of records process failed = '||ln_task_assgn_rec_pro_fail);
                fnd_file.put_line(fnd_file.output,'Total no.of records validation failed = '||ln_task_assgn_rec_duplicated);
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');

                XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
                    (
                          p_conc_mst_req_id              => APPS.FND_GLOBAL.CONC_REQUEST_ID
                        , p_batch_id                     => ln_batch_id
                        , p_conversion_id                => ln_task_assgn_conversion_id
                        , p_num_bus_objs_failed_valid    => 0
                        , p_num_bus_objs_failed_process  => ln_task_assgn_rec_pro_fail
                        , p_num_bus_objs_succ_process    => ln_task_assgn_rec_pro_succ
                    );
                log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.END *********************'||CHR(10));

            END IF;

        END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf    :='Other Exceptions in create_tasks_main procedure '||SQLERRM;
        x_retcode   :='2';
    END;
    log_debug_msg(CHR(10)||'-----------------------       END        ----------------------');


    --************************** Part:4 Create Task Dependencies ****************************--
    log_debug_msg('====================  BEGIN  =======================');
    log_debug_msg('============ Create Task Dependencies ==============='||CHR(10));

    BEGIN

        log_debug_msg('p_batch_id_from = '||p_batch_id_from);
        log_debug_msg('p_batch_id_to = '||p_batch_id_to);

        FOR idx IN lcu_get_task_dep_batch_id
            (     p_batch_id_from  => p_batch_id_from
                , p_batch_id_to    => p_batch_id_to
            )
        LOOP

            ln_batch_id := idx.batch_id;

            ln_task_depend_rec_pro_succ   := 0;
            ln_task_depend_rec_pro_fail   := 0;
            ln_task_depend_rec_duplicated := 0;

            lt_task_dpnd_interface_status.DELETE;
            lt_task_depend_record_id_table.DELETE;


            log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.BEGIN *********************'||CHR(10));

            OPEN lcu_get_task_dep_recs
                (
                     cp_batch_id   => ln_batch_id
                );
            FETCH lcu_get_task_dep_recs BULK COLLECT INTO lt_task_depend_table;
            CLOSE lcu_get_task_dep_recs;

            IF  lt_task_depend_table.COUNT < 1 THEN
                log_debug_msg('No records found for the batch_id = '||ln_batch_id);
            ELSE

                log_debug_msg('Records found for the batch_id ('||ln_batch_id||')'||'= '||lt_task_depend_table.COUNT||CHR(10));

                XX_COM_CONV_ELEMENTS_PKG.Log_control_info_proc
                    (
                          p_conversion_id            => ln_task_depend_conversion_id
                        , p_batch_id                 => ln_batch_id
                        , p_num_bus_objs_processed   => 0
                    );

                FOR i IN lt_task_depend_table.first .. lt_task_depend_table.last
                LOOP
                    lc_task_depend_return_status       := 'E';
                    log_debug_msg(CHR(10)||'Record-id:'||lt_task_depend_table(i).record_id);
                    log_debug_msg('=====================');

                    --Creating task dependencies
                    create_task_dependency
                        (
                            l_jtf_tasks_depend_int         => lt_task_depend_table(i)
                          , x_task_depend_ret_status       => lc_task_depend_return_status
                        );

                    lt_task_depend_record_id_table(i) := lt_task_depend_table(i).record_id;

                    IF lc_task_depend_return_status = 'S' THEN
                        --Processing Successful
                        lt_task_dpnd_interface_status(i) := '7';
                        ln_task_depend_rec_pro_succ := ln_task_depend_rec_pro_succ+1;

                    ELSIF lc_task_depend_return_status = 'V' THEN
                        -- Validation Falied
                        lt_task_dpnd_interface_status(i) := '6';
                        ln_task_depend_rec_duplicated := ln_task_depend_rec_duplicated+1;
                    ELSE
                        --Processing Failed
                        lt_task_dpnd_interface_status(i) := '6';
                        ln_task_depend_rec_pro_fail := ln_task_depend_rec_pro_fail+1;
                    END IF;

                END LOOP;
                COMMIT;

                --Bulk update of interface_status column
                IF lt_task_depend_record_id_table.last > 0 THEN
                  FORALL i IN 1 .. lt_task_depend_record_id_table.last
                      UPDATE xx_jtf_imp_tasks_depend_int
                      SET    interface_status  = lt_task_dpnd_interface_status(i)
                      WHERE  record_id = lt_task_depend_record_id_table(i);
                END IF;

                COMMIT;
                --No.of processed,failed,succeeded records - start
                lc_task_depend_pro_rec_read := (ln_task_depend_rec_pro_succ + ln_task_depend_rec_pro_fail+ln_task_depend_rec_duplicated);
                log_debug_msg(CHR(10)||'-----------------------------------------------------------');
                log_debug_msg('Total no.of records read = '||lc_task_depend_pro_rec_read);
                log_debug_msg('Total no.of records succeeded = '||ln_task_depend_rec_pro_succ);
                log_debug_msg('Total no.of records process failed = '||ln_task_depend_rec_pro_fail);
                log_debug_msg('Total no.of records validation failed = '||ln_task_depend_rec_duplicated);
                log_debug_msg('-----------------------------------------------------------');

                fnd_file.put_line(fnd_file.output,'================ Create Task References =================');
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');
                fnd_file.put_line(fnd_file.output,'Total no.of records read = '||lc_task_depend_pro_rec_read);
                fnd_file.put_line(fnd_file.output,'Total no.of records succeeded = '||ln_task_depend_rec_pro_succ);
                fnd_file.put_line(fnd_file.output,'Total no.of records process failed = '||ln_task_depend_rec_pro_fail);
                fnd_file.put_line(fnd_file.output,'Total no.of records validation failed = '||ln_task_depend_rec_duplicated);
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');

                XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
                    (
                          p_conc_mst_req_id              => APPS.FND_GLOBAL.CONC_REQUEST_ID
                        , p_batch_id                     => ln_batch_id
                        , p_conversion_id                => ln_task_depend_conversion_id
                        , p_num_bus_objs_failed_valid    => 0
                        , p_num_bus_objs_failed_process  => ln_task_depend_rec_pro_fail
                        , p_num_bus_objs_succ_process    => ln_task_depend_rec_pro_succ
                    );
                log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.END *********************'||CHR(10));

            END IF;

        END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf    :='Other Exceptions in create_tasks_main procedure '||SQLERRM;
        x_retcode   :='2';
    END;
    log_debug_msg(CHR(10)||'-----------------------       END        ----------------------');


    --************************** Part:5 Create Task Recurrences ****************************--
    log_debug_msg('=======================  BEGIN  =======================');
    log_debug_msg('=============== Create Task Recurrences ==============='||CHR(10));

    BEGIN

        log_debug_msg('p_batch_id_from = '||p_batch_id_from);
        log_debug_msg('p_batch_id_to = '||p_batch_id_to);

        FOR idx IN lcu_get_task_recur_batch_id
            (     p_batch_id_from  => p_batch_id_from
                , p_batch_id_to    => p_batch_id_to
            )
        LOOP

            ln_batch_id := idx.batch_id;

            ln_task_recur_rec_pro_succ   := 0;
            ln_task_recur_rec_pro_fail   := 0;
            ln_task_recur_rec_duplicated := 0;

            lt_task_recur_interface_status.DELETE;
            lt_task_recur_record_id_table.DELETE;


            log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.BEGIN *********************'||CHR(10));

            OPEN lcu_get_task_recur_recs
                (
                     cp_batch_id   => ln_batch_id
                );
            FETCH lcu_get_task_recur_recs BULK COLLECT INTO lt_task_recur_table;
            CLOSE lcu_get_task_recur_recs;

            IF  lt_task_recur_table.COUNT < 1 THEN
                log_debug_msg('No records found for the batch_id = '||ln_batch_id);
            ELSE

                log_debug_msg('Records found for the batch_id ('||ln_batch_id||')'||'= '||lt_task_recur_table.COUNT||CHR(10));

                XX_COM_CONV_ELEMENTS_PKG.Log_control_info_proc
                    (
                          p_conversion_id            => ln_task_recur_conversion_id
                        , p_batch_id                 => ln_batch_id
                        , p_num_bus_objs_processed   => 0
                    );

                FOR i IN lt_task_recur_table.first .. lt_task_recur_table.last
                LOOP
                    lc_task_recur_return_status       := 'E';
                    log_debug_msg(CHR(10)||'Record-id:'||lt_task_recur_table(i).record_id);
                    log_debug_msg('=====================');

                    --Creating task recurrences
                    create_task_recurrence
                        (
                            l_jtf_tasks_recur_int         => lt_task_recur_table(i)
                          , x_tasks_recur_return_status   => lc_task_recur_return_status
                        );

                    lt_task_recur_record_id_table(i) := lt_task_recur_table(i).record_id;

                    IF lc_task_recur_return_status = 'S' THEN
                        --Processing Successful
                        lt_task_recur_interface_status(i) := '7';
                        ln_task_recur_rec_pro_succ := ln_task_recur_rec_pro_succ+1;

                    ELSIF lc_task_recur_return_status = 'V' THEN
                        -- Validation Falied
                        lt_task_recur_interface_status(i) := '6';
                        ln_task_recur_rec_duplicated := ln_task_recur_rec_duplicated+1;
                    ELSE
                        --Processing Failed
                        lt_task_recur_interface_status(i) := '6';
                        ln_task_recur_rec_pro_fail := ln_task_recur_rec_pro_fail+1;
                    END IF;

                END LOOP;
                COMMIT;

                --Bulk update of interface_status column
                IF lt_task_recur_record_id_table.last > 0 THEN
                  FORALL i IN 1 .. lt_task_recur_record_id_table.last
                      UPDATE xx_jtf_imp_task_recur_int
                      SET    interface_status  = lt_task_recur_interface_status(i)
                      WHERE  record_id = lt_task_recur_record_id_table(i);
                END IF;

                COMMIT;
                --No.of processed,failed,succeeded records - start
                lc_task_recur_pro_rec_read := (ln_task_recur_rec_pro_succ + ln_task_recur_rec_pro_fail+ln_task_recur_rec_duplicated);
                log_debug_msg(CHR(10)||'-----------------------------------------------------------');
                log_debug_msg('Total no.of records read = '||lc_task_recur_pro_rec_read);
                log_debug_msg('Total no.of records succeeded = '||ln_task_recur_rec_pro_succ);
                log_debug_msg('Total no.of records process failed = '||ln_task_recur_rec_pro_fail);
                log_debug_msg('Total no.of records validation failed = '||ln_task_recur_rec_duplicated);
                log_debug_msg('-----------------------------------------------------------');

                fnd_file.put_line(fnd_file.output,'================ Create Task Recurrences =================');
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');
                fnd_file.put_line(fnd_file.output,'Total no.of records read = '||lc_task_recur_pro_rec_read);
                fnd_file.put_line(fnd_file.output,'Total no.of records succeeded = '||ln_task_recur_rec_pro_succ);
                fnd_file.put_line(fnd_file.output,'Total no.of records process failed = '||ln_task_recur_rec_pro_fail);
                fnd_file.put_line(fnd_file.output,'Total no.of records validation failed = '||ln_task_recur_rec_duplicated);
                fnd_file.put_line(fnd_file.output,'-----------------------------------------------------------');

                XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
                    (
                          p_conc_mst_req_id              => APPS.FND_GLOBAL.CONC_REQUEST_ID
                        , p_batch_id                     => ln_batch_id
                        , p_conversion_id                => ln_task_recur_conversion_id
                        , p_num_bus_objs_failed_valid    => 0
                        , p_num_bus_objs_failed_process  => ln_task_recur_rec_pro_fail
                        , p_num_bus_objs_succ_process    => ln_task_recur_rec_pro_succ
                    );
                log_debug_msg(CHR(10)||'********************* Batch_id = '||ln_batch_id||'.END *********************'||CHR(10));

            END IF;

        END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf    :='Other Exceptions in create_tasks_main procedure '||SQLERRM;
        x_retcode   :='2';
    END;
    log_debug_msg(CHR(10)||'-----------------------       END        ----------------------');

END create_tasks_main;

-- +===================================================================+
-- | Name        : create_task                                         |
-- | Description : Procedure to create and update tasks                |
-- |                                                                   |
-- | Parameters  : l_jtf_tasks_int                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_task
    (
         l_jtf_tasks_int            IN      XX_JTF_IMP_TASKS_INT%ROWTYPE
        ,x_tasks_return_status      OUT     VARCHAR2
    )
AS
    ---------------------------------
    -- Data validations
    ---------------------------------
    lc_staging_column_name           VARCHAR2(32);
    lc_staging_column_value          VARCHAR2(500);
    lc_exception_log                 VARCHAR2(2000);
    lc_oracle_error_msg              VARCHAR2(2000);
    ln_task_conversion_id            NUMBER          := 801.1;
    lc_procedure_name                VARCHAR2(250)   := 'XX_JTF_TASKS_PKG.CREATE_TASK';
    lc_staging_table_name            VARCHAR2(250)   := 'XX_JTF_IMP_TASKS_INT';
    lb_tasks_create_flag             BOOLEAN         := TRUE;

    ln_orig_system                   VARCHAR2(30);
    lc_source_object_code            VARCHAR2(250);

    ln_source_object_id              NUMBER;

    ln_parent_task_id                jtf_tasks_b.task_id%TYPE;
    ln_task_id                       jtf_tasks_b.task_id%TYPE;
    ln_task_type_id                  jtf_task_types_tl.task_type_id%TYPE;
    ln_task_priority_id              jtf_task_priorities_tl.task_priority_id%TYPE;
    ln_task_status_id                jtf_task_statuses_tl.task_status_id%TYPE;

    ---------------------------------
    -- Create_task
    ---------------------------------
    ln_api_version                   NUMBER := 1.0;
    ln_owner_id                      jtf_rs_resource_extns.resource_id%TYPE;
    ln_user_id                       jtf_rs_resource_extns.user_id%TYPE;
    ln_customer_id                   hz_parties.party_id%TYPE;
    ln_address_id                    hz_party_sites.party_site_id%TYPE;
    ln_account_id                    hz_cust_accounts.cust_account_id%TYPE;
    ln_timezone_id                   hz_timezones_vl.timezone_id%TYPE;
    ln_owner_type_code               jtf_objects_b.object_code%TYPE;

    lc_ret_sts                       VARCHAR2(1);
    lc_msg_cnt                       NUMBER;
    lc_msg_dat                       VARCHAR2(2000);
    lc_tsk_id                        NUMBER;
    ---------------------------------
    -- Update_task
    ---------------------------------
    lc_object_version_num            NUMBER;

BEGIN
    g_conv_id                    := ln_task_conversion_id;
    g_record_control_id          := l_jtf_tasks_int.record_id;
    g_source_system_code         := l_jtf_tasks_int.source_object_orig_system;
    g_orig_sys_ref               := l_jtf_tasks_int.source_object_orig_system_ref;
    g_staging_table_name         := 'XX_JTF_IMP_TASKS_INT';
    g_batch_id                   := l_jtf_tasks_int.batch_id;
    --------------------------------
    -- Data validations
    --------------------------------

    IF  l_jtf_tasks_int.source_object_code IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0001_S_OBJ_CODE_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'source_object_code';
        lc_staging_column_value             := l_jtf_tasks_int.source_object_code;
        log_exception
            (
                p_conversion_id             => ln_task_conversion_id
               ,p_record_control_id         => l_jtf_tasks_int.record_id
               ,p_source_system_code        => l_jtf_tasks_int.source_object_orig_system
               ,p_source_system_ref         => l_jtf_tasks_int.source_object_orig_system_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_tasks_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0001_S_OBJ_CODE_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_tasks_create_flag := FALSE;

    END IF;

    ------------------

    IF l_jtf_tasks_int.source_object_orig_system_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0002_S_OBJ_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);

        lc_staging_column_name              := 'source_object_orig_system_ref';
        lc_staging_column_value             := l_jtf_tasks_int.source_object_orig_system_ref;
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        log_exception
            (
                p_conversion_id             => ln_task_conversion_id
               ,p_record_control_id         => l_jtf_tasks_int.record_id
               ,p_source_system_code        => l_jtf_tasks_int.source_object_orig_system
               ,p_source_system_ref         => l_jtf_tasks_int.source_object_orig_system_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_tasks_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0002_S_OBJ_OSR_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_tasks_create_flag := FALSE;

    END IF;

    ----------------------------------------------------
    -- Checking whether source_object_orig_system is a
    -- valid foreign key reference to HZ_ORIG_SYSTEMS_B
    ----------------------------------------------------
    IF l_jtf_tasks_int.source_object_orig_system IS NOT NULL THEN

        BEGIN

        SELECT  orig_system
        INTO    ln_orig_system
        FROM    hz_orig_systems_b
        WHERE   orig_system = l_jtf_tasks_int.source_object_orig_system;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN

            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0003_INV_S_OOS');
            FND_MESSAGE.SET_TOKEN('P_SOURCE_OS',l_jtf_tasks_int.source_object_orig_system);
            g_errbuf := FND_MESSAGE.GET;
            log_debug_msg(lc_procedure_name||' : '||g_errbuf||':WHEN NO_DATA_FOUND');
            lc_exception_log                    := g_errbuf;
            lc_oracle_error_msg                 := g_errbuf;
            lc_staging_column_name              := 'source_object_orig_system';
            lc_staging_column_value             := l_jtf_tasks_int.source_object_orig_system;
            log_exception
                (
                    p_conversion_id             => ln_task_conversion_id
                   ,p_record_control_id         => l_jtf_tasks_int.record_id
                   ,p_source_system_code        => l_jtf_tasks_int.source_object_orig_system
                   ,p_source_system_ref         => l_jtf_tasks_int.source_object_orig_system_ref
                   ,p_procedure_name            => lc_procedure_name
                   ,p_staging_table_name        => lc_staging_table_name
                   ,p_staging_column_name       => lc_staging_column_name
                   ,p_staging_column_value      => lc_staging_column_value
                   ,p_batch_id                  => l_jtf_tasks_int.batch_id
                   ,p_exception_log             => lc_exception_log
                   ,p_oracle_error_code         => 'XX_SFA_0003_INV_S_OOS'
                   ,p_oracle_error_msg          => lc_oracle_error_msg
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                      
                );
            lb_tasks_create_flag := FALSE;

            WHEN OTHERS THEN

            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0003_INV_S_OOS');
            FND_MESSAGE.SET_TOKEN('P_SOURCE_OS',l_jtf_tasks_int.source_object_orig_system);
            g_errbuf := FND_MESSAGE.GET;
            log_debug_msg(lc_procedure_name||' : '||g_errbuf||':WHEN OTHERS');
            lc_exception_log                    := g_errbuf;
            lc_oracle_error_msg                 := g_errbuf;
            lc_staging_column_name              := 'source_object_orig_system';
            lc_staging_column_value             := l_jtf_tasks_int.source_object_orig_system;
            log_exception
                (
                    p_conversion_id             => ln_task_conversion_id
                   ,p_record_control_id         => l_jtf_tasks_int.record_id
                   ,p_source_system_code        => l_jtf_tasks_int.source_object_orig_system
                   ,p_source_system_ref         => l_jtf_tasks_int.source_object_orig_system_ref
                   ,p_procedure_name            => lc_procedure_name
                   ,p_staging_table_name        => lc_staging_table_name
                   ,p_staging_column_name       => lc_staging_column_name
                   ,p_staging_column_value      => lc_staging_column_value
                   ,p_batch_id                  => l_jtf_tasks_int.batch_id
                   ,p_exception_log             => lc_exception_log
                   ,p_oracle_error_code         => 'XX_SFA_0003_INV_S_OOS'
                   ,p_oracle_error_msg          => lc_oracle_error_msg
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                      
                );
            lb_tasks_create_flag := FALSE;
        END;

    END IF;

    ----------------------------------------------------
    -- Checking whether source_object_code is a
    -- valid foreign key reference to JTF_OBJECTS_B
    ----------------------------------------------------
    IF l_jtf_tasks_int.source_object_code IS NOT NULL THEN

        BEGIN

        SELECT  object_code
        INTO    lc_source_object_code
        FROM    jtf_objects_b
        WHERE   object_code = l_jtf_tasks_int.source_object_code;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0004_INV_S_OBJ_CODE');
            FND_MESSAGE.SET_TOKEN('P_SOURCE_OC',l_jtf_tasks_int.source_object_code);
            g_errbuf := FND_MESSAGE.GET;
            log_debug_msg(lc_procedure_name||' : '||g_errbuf||':WHEN NO_DATA_FOUND');
            lc_exception_log                    := g_errbuf;
            lc_oracle_error_msg                 := g_errbuf;
            lc_staging_column_name              := 'source_object_code';
            lc_staging_column_value             := l_jtf_tasks_int.source_object_code;
            log_exception
                (
                    p_conversion_id             => ln_task_conversion_id
                   ,p_record_control_id         => l_jtf_tasks_int.record_id
                   ,p_source_system_code        => l_jtf_tasks_int.source_object_orig_system
                   ,p_source_system_ref         => l_jtf_tasks_int.source_object_orig_system_ref
                   ,p_procedure_name            => lc_procedure_name
                   ,p_staging_table_name        => lc_staging_table_name
                   ,p_staging_column_name       => lc_staging_column_name
                   ,p_staging_column_value      => lc_staging_column_value
                   ,p_batch_id                  => l_jtf_tasks_int.batch_id
                   ,p_exception_log             => lc_exception_log
                   ,p_oracle_error_code         => 'XX_SFA_0004_INV_S_OBJ_CODE'
                   ,p_oracle_error_msg          => lc_oracle_error_msg
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                      
                );
            lb_tasks_create_flag := FALSE;

            WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0004_INV_S_OBJ_CODE');
            FND_MESSAGE.SET_TOKEN('P_SOURCE_OC',l_jtf_tasks_int.source_object_code);
            g_errbuf := FND_MESSAGE.GET;
            log_debug_msg(lc_procedure_name||' : '||g_errbuf||':WHEN OTHERS');
            lc_exception_log                    := g_errbuf;
            lc_oracle_error_msg                 := g_errbuf;
            lc_staging_column_name              := 'source_object_code';
            lc_staging_column_value             := l_jtf_tasks_int.source_object_code;
            log_exception
                (
                    p_conversion_id             => ln_task_conversion_id
                   ,p_record_control_id         => l_jtf_tasks_int.record_id
                   ,p_source_system_code        => l_jtf_tasks_int.source_object_orig_system
                   ,p_source_system_ref         => l_jtf_tasks_int.source_object_orig_system_ref
                   ,p_procedure_name            => lc_procedure_name
                   ,p_staging_table_name        => lc_staging_table_name
                   ,p_staging_column_name       => lc_staging_column_name
                   ,p_staging_column_value      => lc_staging_column_value
                   ,p_batch_id                  => l_jtf_tasks_int.batch_id
                   ,p_exception_log             => lc_exception_log
                   ,p_oracle_error_code         => 'XX_SFA_0004_INV_S_OBJ_CODE'
                   ,p_oracle_error_msg          => lc_oracle_error_msg
                   ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                      
                );
            lb_tasks_create_flag := FALSE;
        END;

    END IF;

    --------------------------------
    -- Getting source_object_id
    --------------------------------
    IF l_jtf_tasks_int.source_object_code IS NOT NULL AND
       l_jtf_tasks_int.source_object_orig_system_ref IS NOT NULL THEN

          Get_object_source_id
            (
                  p_source_object_code            => l_jtf_tasks_int.source_object_code
                , p_source_object_orig_sys_ref    => l_jtf_tasks_int.source_object_orig_system_ref
                , p_source_object_orig_sys        => l_jtf_tasks_int.source_object_orig_system
                , x_object_source_id              => ln_source_object_id
            );

            log_debug_msg('x_object_source_id:'||ln_source_object_id);

            IF ln_source_object_id IS NULL THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0005_S_OBJ_ID_NULL');
                g_errbuf := FND_MESSAGE.GET;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf);
                lc_exception_log                    := g_errbuf;
                lc_oracle_error_msg                 := g_errbuf;
                lc_staging_column_name              := 'source_object_id';
                lc_staging_column_value             := l_jtf_tasks_int.source_object_code;
                log_exception
                    (
                        p_conversion_id             => ln_task_conversion_id
                       ,p_record_control_id         => l_jtf_tasks_int.record_id
                       ,p_source_system_code        => l_jtf_tasks_int.source_object_orig_system
                       ,p_source_system_ref         => l_jtf_tasks_int.source_object_orig_system_ref
                       ,p_procedure_name            => lc_procedure_name
                       ,p_staging_table_name        => lc_staging_table_name
                       ,p_staging_column_name       => lc_staging_column_name
                       ,p_staging_column_value      => lc_staging_column_value
                       ,p_batch_id                  => l_jtf_tasks_int.batch_id
                       ,p_exception_log             => lc_exception_log
                       ,p_oracle_error_code         => 'XX_SFA_0005_S_OBJ_ID_NULL'
                       ,p_oracle_error_msg          => lc_oracle_error_msg
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                          
                    );
                lb_tasks_create_flag := FALSE;

            ELSIF ln_source_object_id IS NOT NULL THEN

                -----------------------------------------------------
            -- Retrieving customer_id, address_id and account_id
                -----------------------------------------------------
                Get_customer_id
                    (
                        p_source_object_code        => l_jtf_tasks_int.source_object_code
                       ,p_object_source_id          => ln_source_object_id
                       ,x_customer_id               => ln_customer_id
                       ,x_address_id                => ln_address_id
                       ,x_account_id                => ln_account_id
                    );

            END IF;

    ELSE

        lb_tasks_create_flag := FALSE;

    END IF;

    --------------------------------
    -- Retrieving parent_task_id
    --------------------------------
    IF l_jtf_tasks_int.parent_task_orig_system_ref IS NOT NULL THEN

        Get_task_id
            (
                 p_task_orig_system_ref => l_jtf_tasks_int.parent_task_orig_system_ref
                ,x_task_id              => ln_parent_task_id
            );
    END IF;

    ---------------------------
    -- Retrieving task_type_id
    ---------------------------
    IF l_jtf_tasks_int.task_type_name IS NOT NULL THEN

        Get_task_type_id
            (
                 p_task_type_name              => l_jtf_tasks_int.task_type_name
                ,x_task_type_id                => ln_task_type_id
            );
    END IF;

    ----------------------------
    -- Retrieving task_status_id
    ----------------------------
    IF l_jtf_tasks_int.task_status_name IS NOT NULL THEN

        Get_task_status_id
            (
                 p_task_status_name            => l_jtf_tasks_int.task_status_name
                ,x_task_status_id              => ln_task_status_id
            );
    END IF;

    ------------------------------
    -- Retrieving task_priority_id
    ------------------------------
    IF l_jtf_tasks_int.task_priority_name IS NOT NULL THEN

        Get_task_priority_id
            (
                 p_task_priority_name          => l_jtf_tasks_int.task_priority_name
                ,x_task_priority_id            => ln_task_priority_id
            );
    END IF;

    ------------------------------
    -- Retrieving timezone_id
    ------------------------------
    IF l_jtf_tasks_int.timezone_name IS NOT NULL THEN

        Get_timezone_id
            (
                 p_timezone_name               => l_jtf_tasks_int.timezone_name
                ,x_timezone_id                 => ln_timezone_id
            );
    END IF;

    ---------------------------
    -- Retrieving owner_id
    ---------------------------
    IF l_jtf_tasks_int.owner_original_system_ref IS NOT NULL THEN

        Get_resource_id
            (
                 p_resource_orig_system_ref    => l_jtf_tasks_int.owner_original_system_ref
                ,x_resource_id                 => ln_owner_id
                ,x_user_id                     => ln_user_id
                ,x_own_type_code               => ln_owner_type_code
            );

    END IF;
    
        

    IF lb_tasks_create_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||': Cannot create tasks - Validation Failed');
        x_tasks_return_status     := 'V';
        RETURN;
    END IF;

    ---------------------------
    -- Retrieving task_id
    ---------------------------
    IF l_jtf_tasks_int.task_original_system_ref IS NOT NULL THEN

        Get_task_id
            (
                 p_task_orig_system_ref => l_jtf_tasks_int.task_original_system_ref
                ,x_task_id              => ln_task_id
            );
    END IF;
    IF ln_task_id IS NULL THEN
        ---------------------
        -- Create tasks
        ---------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': create a new task');
        log_debug_msg('-----------------------------------------------');
 
       log_debug_msg('owner type code:' ||ln_owner_type_code);
       
        jtf_tasks_pub.create_task
        (
              p_api_version                    => ln_api_version
             ,p_init_msg_list                  => fnd_api.g_true
             ,p_commit                         => fnd_api.g_false
             --,p_task_id                      =>
             ,p_task_name                      => l_jtf_tasks_int.task_name
             ,p_task_type_name                 => l_jtf_tasks_int.task_type_name
             ,p_task_type_id                   => ln_task_type_id
             ,p_description                    => l_jtf_tasks_int.description
             ,p_task_status_name               => l_jtf_tasks_int.task_status_name
             ,p_task_status_id                 => ln_task_status_id
             ,p_task_priority_name             => l_jtf_tasks_int.task_priority_name
             ,p_task_priority_id               => ln_task_priority_id
             --p_owner_type_name               =>
             ,p_owner_type_code                => ln_owner_type_code
             ,p_owner_id                       => ln_owner_id
             --,p_owner_territory_id           =>
             --,p_assigned_by_name             =>
             ,p_assigned_by_id                 => ln_user_id
             --,p_customer_number              =>
             ,p_customer_id                    => ln_customer_id
             --,p_cust_account_number          =>
             ,p_cust_account_id                => ln_account_id
             ,p_address_id                     => ln_address_id
             --,p_address_number               =>
             ,p_planned_start_date             => l_jtf_tasks_int.planned_start_date
             ,p_planned_end_date               => l_jtf_tasks_int.planned_end_date
             ,p_scheduled_start_date           => l_jtf_tasks_int.scheduled_start_date
             ,p_scheduled_end_date             => l_jtf_tasks_int.scheduled_end_date
             ,p_actual_start_date              => l_jtf_tasks_int.actual_start_date
             ,p_actual_end_date                => l_jtf_tasks_int.actual_end_date
             ,p_timezone_id                    => ln_timezone_id
             ,p_timezone_name                  => l_jtf_tasks_int.timezone_name
             ,p_source_object_type_code        => l_jtf_tasks_int.source_object_code
             ,p_source_object_id               => ln_source_object_id
             --,p_source_object_name           =>
             ,p_duration                       => l_jtf_tasks_int.duration
             ,p_duration_uom                   => l_jtf_tasks_int.duration_uom
             ,p_planned_effort                 => l_jtf_tasks_int.planned_effort
             ,p_planned_effort_uom             => l_jtf_tasks_int.planned_effort_uom
             ,p_actual_effort                  => l_jtf_tasks_int.actual_effort
             ,p_actual_effort_uom              => l_jtf_tasks_int.actual_effort_uom
             ,p_percentage_complete            => l_jtf_tasks_int.percentage_complete
             ,p_reason_code                    => l_jtf_tasks_int.reason_code
             ,p_private_flag                   => l_jtf_tasks_int.private_flag
             ,p_publish_flag                   => l_jtf_tasks_int.publish_flag
             ,p_restrict_closure_flag          => l_jtf_tasks_int.restrict_closure_flag
             ,p_multi_booked_flag              => l_jtf_tasks_int.multi_booked_flag
             ,p_milestone_flag                 => l_jtf_tasks_int.milestone_flag
             ,p_holiday_flag                   => l_jtf_tasks_int.holiday_flag
             ,p_billable_flag                  => l_jtf_tasks_int.holiday_flag
             ,p_bound_mode_code                => l_jtf_tasks_int.bound_mode_code
             ,p_soft_bound_flag                => l_jtf_tasks_int.soft_bound_flag
             ,p_workflow_process_id            => l_jtf_tasks_int.workflow_process_id
             ,p_notification_flag              => l_jtf_tasks_int.notification_flag
             ,p_notification_period            => l_jtf_tasks_int.notification_period
             ,p_notification_period_uom        => l_jtf_tasks_int.notification_period_uom
             --,p_parent_task_number           =>
             ,p_parent_task_id                 => ln_parent_task_id
             ,p_alarm_start                    => l_jtf_tasks_int.alarm_start
             ,p_alarm_start_uom                => l_jtf_tasks_int.alarm_start_uom
             ,p_alarm_on                       => l_jtf_tasks_int.alarm_on
             ,p_alarm_count                    => l_jtf_tasks_int.alarm_count
             ,p_alarm_interval                 => l_jtf_tasks_int.alarm_interval
             ,p_alarm_interval_uom             => l_jtf_tasks_int.alarm_interval_uom
             ,p_palm_flag                      => l_jtf_tasks_int.palm_flag
             ,p_wince_flag                     => l_jtf_tasks_int.wince_flag
             ,p_laptop_flag                    => l_jtf_tasks_int.laptop_flag
             ,p_device1_flag                   => l_jtf_tasks_int.device1_flag
             ,p_device2_flag                   => l_jtf_tasks_int.device2_flag
             ,p_device3_flag                   => l_jtf_tasks_int.device3_flag
             ,p_costs                          => l_jtf_tasks_int.costs
             ,p_currency_code                  => l_jtf_tasks_int.currency_code
             ,p_escalation_level               => l_jtf_tasks_int.escalation_level
             ,x_return_status                  => lc_ret_sts
             ,x_msg_count                      => lc_msg_cnt
             ,x_msg_data                       => lc_msg_dat
             ,x_task_id                        => lc_tsk_id
             ,p_attribute1                     => l_jtf_tasks_int.attribute1
             ,p_attribute2                     => l_jtf_tasks_int.attribute2
             ,p_attribute3                     => l_jtf_tasks_int.attribute3
             ,p_attribute4                     => l_jtf_tasks_int.attribute4
             ,p_attribute5                     => l_jtf_tasks_int.attribute5
             ,p_attribute6                     => l_jtf_tasks_int.attribute6
             ,p_attribute7                     => l_jtf_tasks_int.attribute7
             ,p_attribute8                     => l_jtf_tasks_int.attribute8
             ,p_attribute9                     => l_jtf_tasks_int.attribute9
             ,p_attribute10                    => l_jtf_tasks_int.attribute10
             ,p_attribute11                    => l_jtf_tasks_int.attribute11
             ,p_attribute12                    => l_jtf_tasks_int.attribute12
             ,p_attribute13                    => l_jtf_tasks_int.attribute13
             ,p_attribute14                    => l_jtf_tasks_int.attribute14
             ,p_attribute15                    => l_jtf_tasks_int.task_original_system_ref
             ,p_attribute_category             => l_jtf_tasks_int.attribute_category
             ,p_date_selected                  => l_jtf_tasks_int.date_selected
             ,p_category_id                    => l_jtf_tasks_int.category_id
             ,p_show_on_calendar               => l_jtf_tasks_int.show_on_calendar
             ,p_owner_status_id                => l_jtf_tasks_int.owner_status_id
             ,p_template_id                    => l_jtf_tasks_int.template_id
             ,p_template_group_id              => l_jtf_tasks_int.template_group_id
             ,p_enable_workflow                => l_jtf_tasks_int.enable_workflow
             ,p_abort_workflow                 => l_jtf_tasks_int.abort_workflow
             ,p_task_split_flag                => l_jtf_tasks_int.task_split_flag
             ,p_reference_flag                 => l_jtf_tasks_int.reference_flag
             ,p_child_position                 => l_jtf_tasks_int.child_position
             ,p_child_sequence_num             => l_jtf_tasks_int.child_sequence_num
        );


        x_tasks_return_status := lc_ret_sts;

        log_debug_msg('After calling Create_task API');
        log_debug_msg('lc_tsk_id = '||lc_tsk_id);
        log_debug_msg('lc_ret_sts = '||lc_ret_sts);

        IF lc_ret_sts = 'S' THEN

            log_debug_msg('successfully created !!!');

        ELSE
            log_debug_msg('not created !!!');
            IF lc_msg_cnt >= 1 THEN
                FOR i IN 1..lc_msg_cnt
                LOOP
                    log_debug_msg(CHR(10)||i||' . '|| FND_MSG_PUB.Get(i, FND_API.G_FALSE));
                    lc_msg_dat := lc_msg_dat||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                END LOOP;
            END IF;
            log_exception
            (
                p_conversion_id             => ln_task_conversion_id
               ,p_record_control_id         => l_jtf_tasks_int.record_id
               ,p_source_system_code        => l_jtf_tasks_int.source_object_orig_system
               ,p_source_system_ref         => l_jtf_tasks_int.source_object_orig_system_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASKS_PUB.CREATE_TASK'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_tasks_int.batch_id
               ,p_exception_log             => lc_msg_dat
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_dat
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;


    ELSIF ln_task_id IS NOT NULL THEN

        -----------------------------------
        -- Retrieving object_version_number
        -----------------------------------
        Get_task_obj_ver_num
            (
                p_task_id      => ln_task_id
               ,x_obj_ver_num  => lc_object_version_num
            );

        ---------------------
        -- Update tasks
        ---------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': update an existing task');
        log_debug_msg('-----------------------------------------------');

        jtf_tasks_pub.update_task
            (
                p_api_version                    => ln_api_version
               ,p_init_msg_list                  => fnd_api.g_true
               ,p_commit                         => fnd_api.g_false
               ,p_object_version_number          => lc_object_version_num
               ,p_task_id                        => ln_task_id
               ,p_task_name                      => nvl(l_jtf_tasks_int.task_name,fnd_api.g_miss_char)
               ,p_task_type_name                 => nvl(l_jtf_tasks_int.task_type_name,fnd_api.g_miss_char)
               ,p_task_type_id                   => ln_task_type_id
               ,p_description                    => nvl(l_jtf_tasks_int.description,fnd_api.g_miss_char)
               ,p_task_status_name               => nvl(l_jtf_tasks_int.task_status_name,fnd_api.g_miss_char)
               ,p_task_status_id                 => ln_task_status_id
               ,p_task_priority_name             => nvl(l_jtf_tasks_int.task_priority_name,fnd_api.g_miss_char)
               ,p_task_priority_id               => ln_task_priority_id
               --p_owner_type_name               =>
               ,p_owner_type_code                => ln_owner_type_code
               ,p_owner_id                       => ln_owner_id
               --,p_owner_territory_id           =>
               --,p_assigned_by_name             =>
               ,p_assigned_by_id                 => ln_user_id
               --,p_customer_number              =>
               ,p_customer_id                    => ln_customer_id
               --,p_cust_account_number          =>
               ,p_cust_account_id                => ln_account_id
               ,p_address_id                     => ln_address_id
               --,p_address_number               =>
               ,p_planned_start_date             => nvl(l_jtf_tasks_int.planned_start_date,fnd_api.g_miss_date)
               ,p_planned_end_date               => nvl(l_jtf_tasks_int.planned_end_date,fnd_api.g_miss_date)
               ,p_scheduled_start_date           => nvl(l_jtf_tasks_int.scheduled_start_date,fnd_api.g_miss_date)
               ,p_scheduled_end_date             => nvl(l_jtf_tasks_int.scheduled_end_date,fnd_api.g_miss_date)
               ,p_actual_start_date              => nvl(l_jtf_tasks_int.actual_start_date,fnd_api.g_miss_date)
               ,p_actual_end_date                => nvl(l_jtf_tasks_int.actual_end_date,fnd_api.g_miss_date)
               ,p_timezone_id                    => ln_timezone_id
               ,p_timezone_name                  => nvl(l_jtf_tasks_int.timezone_name,fnd_api.g_miss_char)
               ,p_source_object_type_code        => nvl(l_jtf_tasks_int.source_object_code,fnd_api.g_miss_char)
               ,p_source_object_id               => ln_source_object_id
               --,p_source_object_name           =>
               ,p_duration                       => nvl(l_jtf_tasks_int.duration,fnd_api.g_miss_num)
               ,p_duration_uom                   => nvl(l_jtf_tasks_int.duration_uom,fnd_api.g_miss_char)
               ,p_planned_effort                 => nvl(l_jtf_tasks_int.planned_effort,fnd_api.g_miss_num)
               ,p_planned_effort_uom             => nvl(l_jtf_tasks_int.planned_effort_uom,fnd_api.g_miss_char)
               ,p_actual_effort                  => nvl(l_jtf_tasks_int.actual_effort,fnd_api.g_miss_num)
               ,p_actual_effort_uom              => nvl(l_jtf_tasks_int.actual_effort_uom ,fnd_api.g_miss_char)
               ,p_percentage_complete            => nvl(l_jtf_tasks_int.percentage_complete,fnd_api.g_miss_num)
               ,p_reason_code                    => nvl(l_jtf_tasks_int.reason_code,fnd_api.g_miss_char)
               ,p_private_flag                   => nvl(l_jtf_tasks_int.private_flag,fnd_api.g_miss_char)
               ,p_publish_flag                   => nvl(l_jtf_tasks_int.publish_flag,fnd_api.g_miss_char)
               ,p_restrict_closure_flag          => nvl(l_jtf_tasks_int.restrict_closure_flag,fnd_api.g_miss_char)
               ,p_multi_booked_flag              => nvl(l_jtf_tasks_int.multi_booked_flag,fnd_api.g_miss_char)
               ,p_milestone_flag                 => nvl(l_jtf_tasks_int.milestone_flag,fnd_api.g_miss_char)
               ,p_holiday_flag                   => nvl(l_jtf_tasks_int.holiday_flag,fnd_api.g_miss_char)
               ,p_billable_flag                  => nvl(l_jtf_tasks_int.holiday_flag,fnd_api.g_miss_char)
               ,p_bound_mode_code                => nvl(l_jtf_tasks_int.bound_mode_code,fnd_api.g_miss_char)
               ,p_soft_bound_flag                => nvl(l_jtf_tasks_int.soft_bound_flag,fnd_api.g_miss_char)
               ,p_workflow_process_id            => nvl(l_jtf_tasks_int.workflow_process_id,fnd_api.g_miss_num)
               ,p_notification_flag              => nvl(l_jtf_tasks_int.notification_flag,fnd_api.g_miss_char)
               ,p_notification_period            => nvl(l_jtf_tasks_int.notification_period,fnd_api.g_miss_num)
               ,p_notification_period_uom        => nvl(l_jtf_tasks_int.notification_period_uom,fnd_api.g_miss_char)
               ,p_alarm_start                    => nvl(l_jtf_tasks_int.alarm_start,fnd_api.g_miss_num)
               ,p_alarm_start_uom                => nvl(l_jtf_tasks_int.alarm_start_uom,fnd_api.g_miss_char)
               ,p_alarm_on                       => nvl(l_jtf_tasks_int.alarm_on,fnd_api.g_miss_char)
               ,p_alarm_count                    => nvl(l_jtf_tasks_int.alarm_count,fnd_api.g_miss_num)
               ,p_alarm_fired_count              => fnd_api.g_miss_num                                  -- item not present in the create API
               ,p_alarm_interval                 => nvl(l_jtf_tasks_int.alarm_interval,fnd_api.g_miss_num)
               ,p_alarm_interval_uom             => nvl(l_jtf_tasks_int.alarm_interval_uom,fnd_api.g_miss_char)
               ,p_palm_flag                      => nvl(l_jtf_tasks_int.palm_flag,fnd_api.g_miss_char)
               ,p_wince_flag                     => nvl(l_jtf_tasks_int.wince_flag,fnd_api.g_miss_char)
               ,p_laptop_flag                    => nvl(l_jtf_tasks_int.laptop_flag,fnd_api.g_miss_char)
               ,p_device1_flag                   => nvl(l_jtf_tasks_int.device1_flag,fnd_api.g_miss_char)
               ,p_device2_flag                   => nvl(l_jtf_tasks_int.device2_flag,fnd_api.g_miss_char)
               ,p_device3_flag                   => nvl(l_jtf_tasks_int.device3_flag,fnd_api.g_miss_char)
               ,p_costs                          => nvl(l_jtf_tasks_int.costs ,fnd_api.g_miss_num)
               ,p_currency_code                  => nvl(l_jtf_tasks_int.currency_code,fnd_api.g_miss_char)
               ,p_escalation_level               => nvl(l_jtf_tasks_int.escalation_level,fnd_api.g_miss_char)
               ,x_return_status                  => lc_ret_sts
               ,x_msg_count                      => lc_msg_cnt
               ,x_msg_data                       => lc_msg_dat
               ,p_attribute1                     => nvl(l_jtf_tasks_int.attribute1,fnd_api.g_miss_char)
               ,p_attribute2                     => nvl(l_jtf_tasks_int.attribute2,fnd_api.g_miss_char)
               ,p_attribute3                     => nvl(l_jtf_tasks_int.attribute3,fnd_api.g_miss_char)
               ,p_attribute4                     => nvl(l_jtf_tasks_int.attribute4,fnd_api.g_miss_char)
               ,p_attribute5                     => nvl(l_jtf_tasks_int.attribute5,fnd_api.g_miss_char)
               ,p_attribute6                     => nvl(l_jtf_tasks_int.attribute6,fnd_api.g_miss_char)
               ,p_attribute7                     => nvl(l_jtf_tasks_int.attribute7,fnd_api.g_miss_char)
               ,p_attribute8                     => nvl(l_jtf_tasks_int.attribute8,fnd_api.g_miss_char)
               ,p_attribute9                     => nvl(l_jtf_tasks_int.attribute9,fnd_api.g_miss_char)
               ,p_attribute10                    => nvl(l_jtf_tasks_int.attribute10,fnd_api.g_miss_char)
               ,p_attribute11                    => nvl(l_jtf_tasks_int.attribute11,fnd_api.g_miss_char)
               ,p_attribute12                    => nvl(l_jtf_tasks_int.attribute12,fnd_api.g_miss_char)
               ,p_attribute13                    => nvl(l_jtf_tasks_int.attribute13,fnd_api.g_miss_char)
               ,p_attribute14                    => nvl(l_jtf_tasks_int.attribute14,fnd_api.g_miss_char)
               ,p_attribute15                    => l_jtf_tasks_int.task_original_system_ref
               ,p_attribute_category             => nvl(l_jtf_tasks_int.attribute_category,fnd_api.g_miss_char)
               ,p_date_selected                  => nvl(l_jtf_tasks_int.date_selected,fnd_api.g_miss_char)
               ,p_category_id                    => nvl(l_jtf_tasks_int.category_id,fnd_api.g_miss_num)
               ,p_show_on_calendar               => nvl(l_jtf_tasks_int.show_on_calendar,fnd_api.g_miss_char)
               ,p_owner_status_id                => nvl(l_jtf_tasks_int.owner_status_id,fnd_api.g_miss_num)
               ,p_parent_task_id                 => ln_parent_task_id
               --,p_parent_task_number           =>
               ,p_enable_workflow                => l_jtf_tasks_int.enable_workflow
               ,p_abort_workflow                 => l_jtf_tasks_int.abort_workflow
               ,p_task_split_flag                => l_jtf_tasks_int.task_split_flag
               ,p_child_position                 => nvl(l_jtf_tasks_int.child_position,fnd_api.g_miss_char)
               ,p_child_sequence_num             => nvl(l_jtf_tasks_int.child_sequence_num,fnd_api.g_miss_num)
            );

        x_tasks_return_status := lc_ret_sts;

        log_debug_msg('After calling Create_task API');
        log_debug_msg('lc_tsk_id = '||lc_tsk_id);
        log_debug_msg('lc_ret_sts = '||lc_ret_sts);

        IF lc_ret_sts = 'S' THEN

            log_debug_msg('successfully created !!!');

        ELSE
            log_debug_msg('not created !!!');
            IF lc_msg_cnt >= 1 THEN
                FOR i IN 1..lc_msg_cnt
                LOOP
                    log_debug_msg(CHR(10)||i||' . '|| FND_MSG_PUB.Get(i, FND_API.G_FALSE));
                    lc_msg_dat := FND_MSG_PUB.Get(i, FND_API.G_FALSE)||lc_msg_dat;
                END LOOP;
            END IF;
            log_exception
            (
                p_conversion_id             => ln_task_conversion_id
               ,p_record_control_id         => l_jtf_tasks_int.record_id
               ,p_source_system_code        => l_jtf_tasks_int.source_object_orig_system
               ,p_source_system_ref         => l_jtf_tasks_int.source_object_orig_system_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASKS_PUB.UPDATE_TASK'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_tasks_int.batch_id
               ,p_exception_log             => lc_msg_dat --XX_CDH_CONV_MASTER_PKG.trim_input_msg(lc_msg_dat)
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_dat
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;

    END IF;

END create_task;

-- +===================================================================+
-- | Name        : create_task_references                              |
-- | Description : Procedure to create, update and delete              |
-- |               a task reference                                    |
-- | Parameters  : l_jtf_tasks_int                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_task_references
    (
        l_jtf_task_refs_int         IN          XX_JTF_IMP_TASK_REFS_INT%ROWTYPE
       ,x_task_refs_return_status   OUT NOCOPY  VARCHAR2
    )

AS
    lc_staging_column_name           VARCHAR2(32);
    lc_staging_column_value          VARCHAR2(500);
    lc_exception_log                 VARCHAR2(2000);
    lc_oracle_error_msg              VARCHAR2(2000);
    ln_task_refs_conv_id             NUMBER          := 801.2;
    lc_procedure_name                VARCHAR2(250)   := 'XX_JTF_TASKS_PKG.CREATE_TASK_REFERENCES';
    lc_staging_table_name            VARCHAR2(250)   := 'XX_JTF_IMP_TASK_REFS_INT';
    lb_task_refs_create_flag         BOOLEAN         := TRUE;
    ln_object_type_code              jtf_objects_b.object_code%TYPE;

    ---------------------------------
    -- Create_task_references
    ---------------------------------
    ln_api_version                   NUMBER := 1.0;
    ln_jtf_task_id                   jtf_tasks_b.task_id%TYPE;
    lc_object_name                   VARCHAR2(2000);
    ln_object_id                     NUMBER;
    ln_task_ref_id                   jtf_task_references_b.task_reference_id%TYPE;
    ln_obj_ver_num                   jtf_task_references_b.object_version_number%TYPE;

    lc_return_status                 VARCHAR2(1);
    lc_msg_data                      VARCHAR2(2000);
    ln_msg_count                     NUMBER;
    ln_task_reference_id             jtf_task_references_b.task_reference_id%TYPE;

BEGIN
    g_conv_id                    := ln_task_refs_conv_id;
    g_record_control_id          := l_jtf_task_refs_int.record_id;
    g_source_system_code         := l_jtf_task_refs_int.task_ref_orig_system;
    g_orig_sys_ref               := l_jtf_task_refs_int.task_ref_orig_system_ref;
    g_staging_table_name         := 'XX_JTF_IMP_TASK_REFS_INT';
    g_batch_id                   := l_jtf_task_refs_int.batch_id;
    --------------------------------
    -- Data validations
    --------------------------------

    --------------------------------------
    -- Validating task_orig_system_ref
    --------------------------------------
    IF  l_jtf_task_refs_int.task_orig_system_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0006_TASK_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'task_orig_system_ref';
        lc_staging_column_value             := l_jtf_task_refs_int.task_orig_system_ref;
        log_exception
            (
                p_conversion_id             => ln_task_refs_conv_id
               ,p_record_control_id         => l_jtf_task_refs_int.record_id
               ,p_source_system_code        => l_jtf_task_refs_int.task_ref_orig_system
               ,p_source_system_ref         => l_jtf_task_refs_int.task_ref_orig_system_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_task_refs_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0006_TASK_OSR_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_task_refs_create_flag := FALSE;

    END IF;

    --------------------------------------
    -- Validating task_ref_orig_system_ref
    --------------------------------------
    IF  l_jtf_task_refs_int.task_ref_orig_system_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0007_TASK_REF_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'task_ref_orig_system_ref';
        lc_staging_column_value             := l_jtf_task_refs_int.task_ref_orig_system_ref;
        log_exception
            (
                p_conversion_id             => ln_task_refs_conv_id
               ,p_record_control_id         => l_jtf_task_refs_int.record_id
               ,p_source_system_code        => l_jtf_task_refs_int.task_ref_orig_system
               ,p_source_system_ref         => l_jtf_task_refs_int.task_ref_orig_system_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_task_refs_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0007_TASK_REF_OSR_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_task_refs_create_flag := FALSE;
    END IF;

    --------------------------------------
    -- Validating object_type_code
    --------------------------------------
    IF  l_jtf_task_refs_int.object_type_code IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0008_TASK_REF_OTC_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'task_ref_orig_system_ref';
        lc_staging_column_value             := l_jtf_task_refs_int.task_ref_orig_system_ref;
        lc_staging_column_name              := 'object_type_code';
        lc_staging_column_value             := l_jtf_task_refs_int.object_type_code;

        log_exception
            (
                p_conversion_id             => ln_task_refs_conv_id
               ,p_record_control_id         => l_jtf_task_refs_int.record_id
               ,p_source_system_code        => l_jtf_task_refs_int.task_ref_orig_system
               ,p_source_system_ref         => l_jtf_task_refs_int.task_ref_orig_system_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_task_refs_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0008_TASK_REF_OTC_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_task_refs_create_flag := FALSE;

    ELSIF  l_jtf_task_refs_int.object_type_code IS NOT NULL THEN

        BEGIN
            SELECT object_code
            INTO   ln_object_type_code
            FROM   jtf_objects_vl
            WHERE  object_code = l_jtf_task_refs_int.object_type_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0009_INV_OBJ_TYPE_CODE');
                FND_MESSAGE.SET_TOKEN('P_OBJ_TC',l_jtf_task_refs_int.object_type_code);
                g_errbuf := FND_MESSAGE.GET;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf||': WHEN NO_DATA_FOUND');
                lc_exception_log                    := g_errbuf||': WHEN NO_DATA_FOUND';
                lc_oracle_error_msg                 := g_errbuf||': WHEN NO_DATA_FOUND';
                lc_staging_column_name              := 'object_type_code';
                lc_staging_column_value             := l_jtf_task_refs_int.object_type_code;
                log_exception
                    (
                        p_conversion_id             => ln_task_refs_conv_id
                       ,p_record_control_id         => l_jtf_task_refs_int.record_id
                       ,p_source_system_code        => l_jtf_task_refs_int.task_ref_orig_system
                       ,p_source_system_ref         => l_jtf_task_refs_int.task_ref_orig_system_ref
                       ,p_procedure_name            => lc_procedure_name
                       ,p_staging_table_name        => lc_staging_table_name
                       ,p_staging_column_name       => lc_staging_column_name
                       ,p_staging_column_value      => lc_staging_column_value
                       ,p_batch_id                  => l_jtf_task_refs_int.batch_id
                       ,p_exception_log             => lc_exception_log
                       ,p_oracle_error_code         => 'XX_SFA_0009_INV_OBJ_TYPE_CODE'
                       ,p_oracle_error_msg          => lc_oracle_error_msg
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                          
                    );
            lb_task_refs_create_flag := FALSE;

            WHEN OTHERS THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0009_INV_OBJ_TYPE_CODE');
                FND_MESSAGE.SET_TOKEN('P_OBJ_TC',l_jtf_task_refs_int.object_type_code);
                g_errbuf := FND_MESSAGE.GET;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf||': WHEN OTHERS');
                lc_exception_log                    := g_errbuf||': WHEN OTHERS';
                lc_oracle_error_msg                 := g_errbuf||': WHEN OTHERS';
                lc_staging_column_name              := 'object_type_code';
                lc_staging_column_value             := l_jtf_task_refs_int.object_type_code;
                log_exception
                    (
                        p_conversion_id             => ln_task_refs_conv_id
                       ,p_record_control_id         => l_jtf_task_refs_int.record_id
                       ,p_source_system_code        => l_jtf_task_refs_int.task_ref_orig_system
                       ,p_source_system_ref         => l_jtf_task_refs_int.task_ref_orig_system_ref
                       ,p_procedure_name            => lc_procedure_name
                       ,p_staging_table_name        => lc_staging_table_name
                       ,p_staging_column_name       => lc_staging_column_name
                       ,p_staging_column_value      => lc_staging_column_value
                       ,p_batch_id                  => l_jtf_task_refs_int.batch_id
                       ,p_exception_log             => lc_exception_log
                       ,p_oracle_error_code         => 'XX_SFA_0009_INV_OBJ_TYPE_CODE'
                       ,p_oracle_error_msg          => lc_oracle_error_msg
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                          
                    );
            lb_task_refs_create_flag := FALSE;

        END;

    END IF;

    ---------------------------
    -- Retrieving task_id
    ---------------------------
    IF l_jtf_task_refs_int.task_orig_system_ref IS NOT NULL THEN

        Get_task_id
            (
                 p_task_orig_system_ref => l_jtf_task_refs_int.task_orig_system_ref
                ,x_task_id              => ln_jtf_task_id
            );

            IF ln_jtf_task_id IS NULL THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0010_INV_TASK_OSR');
                FND_MESSAGE.SET_TOKEN('P_TASK_OSR',l_jtf_task_refs_int.task_orig_system_ref);
                g_errbuf := FND_MESSAGE.GET;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf);
                lc_exception_log                    := g_errbuf;
                lc_oracle_error_msg                 := g_errbuf;
                lc_staging_column_name              := 'task_orig_system_ref';
                lc_staging_column_value             := l_jtf_task_refs_int.task_orig_system_ref;
                log_exception
                    (
                        p_conversion_id             => ln_task_refs_conv_id
                       ,p_record_control_id         => l_jtf_task_refs_int.record_id
                       ,p_source_system_code        => l_jtf_task_refs_int.task_ref_orig_system
                       ,p_source_system_ref         => l_jtf_task_refs_int.task_ref_orig_system_ref
                       ,p_procedure_name            => lc_procedure_name
                       ,p_staging_table_name        => lc_staging_table_name
                       ,p_staging_column_name       => lc_staging_column_name
                       ,p_staging_column_value      => lc_staging_column_value
                       ,p_batch_id                  => l_jtf_task_refs_int.batch_id
                       ,p_exception_log             => lc_exception_log
                       ,p_oracle_error_code         => 'XX_SFA_0010_INV_TASK_OSR'
                       ,p_oracle_error_msg          => lc_oracle_error_msg
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                          
                    );
                lb_task_refs_create_flag := FALSE;
            END IF;
    END IF;
    ---------------------------
    -- Retrieving ln_object_id
    ---------------------------

    IF l_jtf_task_refs_int.object_type_code IS NOT NULL AND
       l_jtf_task_refs_int.object_orig_system_ref IS NOT NULL THEN
          Get_object_id
            (
                  p_object_type_code         => l_jtf_task_refs_int.object_type_code
                 ,p_object_orig_system_ref   => l_jtf_task_refs_int.object_orig_system_ref
                 ,x_object_name              => lc_object_name
                 ,x_object_id                => ln_object_id
            );
            IF ln_object_id IS NULL THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0011_INV_OOSR');
                FND_MESSAGE.SET_TOKEN('P_OBJ_OSR',l_jtf_task_refs_int.object_orig_system_ref);
                FND_MESSAGE.SET_TOKEN('P_OBJ_TC',l_jtf_task_refs_int.object_type_code);
                g_errbuf := FND_MESSAGE.GET;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf);
                lc_exception_log                    := g_errbuf;
                lc_oracle_error_msg                 := g_errbuf;
                lc_staging_column_name              := 'object_orig_system_ref';
                lc_staging_column_value             := l_jtf_task_refs_int.object_orig_system_ref;
                log_exception
                    (
                        p_conversion_id             => ln_task_refs_conv_id
                       ,p_record_control_id         => l_jtf_task_refs_int.record_id
                       ,p_source_system_code        => l_jtf_task_refs_int.task_ref_orig_system
                       ,p_source_system_ref         => l_jtf_task_refs_int.task_ref_orig_system_ref
                       ,p_procedure_name            => lc_procedure_name
                       ,p_staging_table_name        => lc_staging_table_name
                       ,p_staging_column_name       => lc_staging_column_name
                       ,p_staging_column_value      => lc_staging_column_value
                       ,p_batch_id                  => l_jtf_task_refs_int.batch_id
                       ,p_exception_log             => lc_exception_log
                       ,p_oracle_error_code         => 'XX_SFA_0011_INV_OOSR'
                       ,p_oracle_error_msg          => lc_oracle_error_msg
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                          
                    );
                lb_task_refs_create_flag := FALSE;
            END IF;
    ELSE
        lb_task_refs_create_flag := FALSE;
    END IF;

    IF lb_task_refs_create_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||': Cannot create task references - Validation Failed||');
        x_task_refs_return_status     := 'V';
        RETURN;
    END IF;

    -------------------------------
    -- Retrieving task_reference_id
    -------------------------------
    IF  l_jtf_task_refs_int.task_ref_orig_system_ref IS NOT NULL THEN

        Get_task_reference_id
            (
                 p_task_ref_orig_sys_ref     => l_jtf_task_refs_int.task_ref_orig_system_ref
                ,x_task_ref_id               => ln_task_ref_id
                ,x_obj_ver_num               => ln_obj_ver_num
            );
    END IF;
    IF ln_task_ref_id IS NULL AND
       l_jtf_task_refs_int.insert_update_flag = 'I' THEN

        --------------------------------
        -- Create task reference
        --------------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': create a new task reference');
        log_debug_msg('-------------------------------------');

        jtf_task_references_pub.create_references
            (
                 p_api_version                 => ln_api_version
                ,p_init_msg_list               => fnd_api.g_true
                ,p_commit                      => fnd_api.g_false
                ,p_task_id                     => ln_jtf_task_id
                --,p_task_number               =>
                ,p_object_type_code            => l_jtf_task_refs_int.object_type_code
                ,p_object_name                 => lc_object_name
                ,p_object_id                   => ln_object_id
                ,p_object_details              => l_jtf_task_refs_int.object_details
                ,p_reference_code              => l_jtf_task_refs_int.reference_code
                ,p_usage                       => l_jtf_task_refs_int.usage
                ,x_return_status               => lc_return_status
                ,x_msg_data                    => lc_msg_data
                ,x_msg_count                   => ln_msg_count
                ,x_task_reference_id           => ln_task_reference_id
                ,p_attribute1                  => l_jtf_task_refs_int.attribute1
                ,p_attribute2                  => l_jtf_task_refs_int.attribute2
                ,p_attribute3                  => l_jtf_task_refs_int.attribute3
                ,p_attribute4                  => l_jtf_task_refs_int.attribute4
                ,p_attribute5                  => l_jtf_task_refs_int.attribute5
                ,p_attribute6                  => l_jtf_task_refs_int.attribute6
                ,p_attribute7                  => l_jtf_task_refs_int.attribute7
                ,p_attribute8                  => l_jtf_task_refs_int.attribute8
                ,p_attribute9                  => l_jtf_task_refs_int.attribute9
                ,p_attribute10                 => l_jtf_task_refs_int.attribute10
                ,p_attribute11                 => l_jtf_task_refs_int.attribute11
                ,p_attribute12                 => l_jtf_task_refs_int.attribute12
                ,p_attribute13                 => l_jtf_task_refs_int.attribute13
                ,p_attribute14                 => l_jtf_task_refs_int.attribute14
                ,p_attribute15                 => l_jtf_task_refs_int.task_ref_orig_system_ref
                ,p_attribute_category          => l_jtf_task_refs_int.attribute_category
            );

        x_task_refs_return_status   := lc_return_status;

        IF lc_return_status = 'S' THEN

            log_debug_msg('task reference successfully created !!!');

        ELSE
            log_debug_msg('task reference not created !!!');
            IF ln_msg_count >= 1 THEN
                FOR I IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||i||' . '||FND_MSG_PUB.Get(i, FND_API.G_FALSE));
                    lc_msg_data := lc_msg_data||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                END LOOP;
            END IF;

            log_exception
            (
                p_conversion_id             => ln_task_refs_conv_id
               ,p_record_control_id         => l_jtf_task_refs_int.record_id
               ,p_source_system_code        => l_jtf_task_refs_int.task_ref_orig_system
               ,p_source_system_ref         => l_jtf_task_refs_int.task_ref_orig_system_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASK_REFERENCES_PUB.CREATE_REFERENCES'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_task_refs_int.batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_data
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;

    ELSIF ln_task_ref_id IS NOT NULL AND
          l_jtf_task_refs_int.insert_update_flag = 'U' THEN

        jtf_task_references_pub.update_references
            (
                 p_api_version                 => ln_api_version
                ,p_init_msg_list               => fnd_api.g_true
                ,p_commit                      => fnd_api.g_false
                ,p_object_version_number       => ln_obj_ver_num
                ,p_task_reference_id           => ln_task_ref_id
                ,p_object_type_code            => nvl(l_jtf_task_refs_int.object_type_code,fnd_api.g_miss_char)
                ,p_object_name                 => lc_object_name
                ,p_object_id                   => ln_object_id
                ,p_object_details              => nvl(l_jtf_task_refs_int.object_details,fnd_api.g_miss_char)
                ,p_reference_code              => nvl(l_jtf_task_refs_int.reference_code,fnd_api.g_miss_char)
                ,p_usage                       => nvl(l_jtf_task_refs_int.usage,fnd_api.g_miss_char)
                ,x_return_status               => lc_return_status
                ,x_msg_data                    => lc_msg_data
                ,x_msg_count                   => ln_msg_count
                ,p_attribute1                  => nvl(l_jtf_task_refs_int.attribute1,fnd_api.g_miss_char)
                ,p_attribute2                  => nvl(l_jtf_task_refs_int.attribute2,fnd_api.g_miss_char)
                ,p_attribute3                  => nvl(l_jtf_task_refs_int.attribute3,fnd_api.g_miss_char)
                ,p_attribute4                  => nvl(l_jtf_task_refs_int.attribute4,fnd_api.g_miss_char)
                ,p_attribute5                  => nvl(l_jtf_task_refs_int.attribute5,fnd_api.g_miss_char)
                ,p_attribute6                  => nvl(l_jtf_task_refs_int.attribute6,fnd_api.g_miss_char)
                ,p_attribute7                  => nvl(l_jtf_task_refs_int.attribute7,fnd_api.g_miss_char)
                ,p_attribute8                  => nvl(l_jtf_task_refs_int.attribute8,fnd_api.g_miss_char)
                ,p_attribute9                  => nvl(l_jtf_task_refs_int.attribute9,fnd_api.g_miss_char)
                ,p_attribute10                 => nvl(l_jtf_task_refs_int.attribute10,fnd_api.g_miss_char)
                ,p_attribute11                 => nvl(l_jtf_task_refs_int.attribute11,fnd_api.g_miss_char)
                ,p_attribute12                 => nvl(l_jtf_task_refs_int.attribute12,fnd_api.g_miss_char)
                ,p_attribute13                 => nvl(l_jtf_task_refs_int.attribute13,fnd_api.g_miss_char)
                ,p_attribute14                 => nvl(l_jtf_task_refs_int.attribute14,fnd_api.g_miss_char)
                ,p_attribute15                 => l_jtf_task_refs_int.task_ref_orig_system_ref
                ,p_attribute_category          => nvl(l_jtf_task_refs_int.attribute_category, fnd_api.g_miss_char)
            );

        x_task_refs_return_status   := lc_return_status;

        IF lc_return_status = 'S' THEN

            log_debug_msg('task reference successfully created !!!');

        ELSE
            log_debug_msg('task reference not created !!!');
            IF ln_msg_count >= 1 THEN
                FOR i IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||i||' . '|| FND_MSG_PUB.Get(i, FND_API.G_FALSE));
                    lc_msg_data := lc_msg_data||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                END LOOP;
            END IF;
            log_exception
            (
                p_conversion_id             => ln_task_refs_conv_id
               ,p_record_control_id         => l_jtf_task_refs_int.record_id
               ,p_source_system_code        => l_jtf_task_refs_int.task_ref_orig_system
               ,p_source_system_ref         => l_jtf_task_refs_int.task_ref_orig_system_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASK_REFERENCES_PUB.UPDATE_REFERENCES'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_task_refs_int.batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_data
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;

    ELSIF ln_task_ref_id IS NOT NULL AND
          l_jtf_task_refs_int.insert_update_flag = 'D' THEN

        jtf_task_references_pub.delete_references
            (
                 p_api_version                 => ln_api_version
                ,p_init_msg_list               => fnd_api.g_true
                ,p_commit                      => fnd_api.g_false
                ,p_object_version_number       => ln_obj_ver_num
                ,p_task_reference_id           => ln_task_ref_id
                ,x_return_status               => lc_return_status
                ,x_msg_data                    => lc_msg_data
                ,x_msg_count                   => ln_msg_count
            );

        x_task_refs_return_status   := lc_return_status;

        IF lc_return_status = 'S' THEN

            log_debug_msg('task reference successfully created !!!');

        ELSE
            log_debug_msg('task reference not created !!!');
            IF ln_msg_count >= 1 THEN
                FOR i IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||i||' . '|| FND_MSG_PUB.Get(i, FND_API.G_FALSE));
                    lc_msg_data := lc_msg_data||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                END LOOP;
            END IF;
            log_exception
            (
                p_conversion_id             => ln_task_refs_conv_id
               ,p_record_control_id         => l_jtf_task_refs_int.record_id
               ,p_source_system_code        => l_jtf_task_refs_int.task_ref_orig_system
               ,p_source_system_ref         => l_jtf_task_refs_int.task_ref_orig_system_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASK_REFERENCES_PUB.DELETE_REFERENCES'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_task_refs_int.batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_data
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );

        END IF;
    END IF;
END create_task_references;

-- +===================================================================+
-- | Name        : create_task_assignment                              |
-- | Description : Procedure to create, update and delete              |
-- |               a task assignment                                   |
-- | Parameters  : l_jtf_task_assgn_int                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_task_assignment
    (
        l_jtf_task_assgn_int        IN          XX_JTF_IMP_TASK_ASSGN_INT%ROWTYPE
       ,x_task_assgn_ret_status     OUT NOCOPY  VARCHAR2
    )
AS

    lc_staging_column_name           VARCHAR2(32);
    lc_staging_column_value          VARCHAR2(500);
    lc_exception_log                 VARCHAR2(2000);
    lc_oracle_error_msg              VARCHAR2(2000);
    ln_task_assign_conv_id           NUMBER          := 801.3;
    lc_procedure_name                VARCHAR2(250)   := 'XX_JTF_TASKS_PKG.CREATE_TASK_ASSIGNMENT';
    lc_staging_table_name            VARCHAR2(250)   := 'XX_JTF_IMP_TASK_ASSGN_INT';
    lb_task_assgn_create_flag        BOOLEAN         := TRUE;
    ---------------------------------
    -- Create_task_assignment
    ---------------------------------
    ln_api_version                   NUMBER := 1.0;
    ln_jtf_task_id                   jtf_tasks_b.task_id%TYPE;
    ln_assgn_status_id               jtf_task_statuses_b.task_status_id%TYPE;
    ln_resource_id                   jtf_rs_resource_extns.resource_id%TYPE;
    ln_user_id                       jtf_rs_resource_extns.user_id%TYPE;
    ln_task_assign_id                jtf_task_all_assignments.task_assignment_id%TYPE;
    ln_obj_ver_num                   jtf_task_all_assignments.object_version_number%TYPE;
    ln_owner_type_code               jtf_objects_b.object_code%TYPE;

    lc_return_status                 VARCHAR2(1);
    lc_msg_data                      VARCHAR2(2000);
    ln_msg_count                     NUMBER;
    ln_task_assignment_id            jtf_task_all_assignments.task_assignment_id%TYPE;

BEGIN
    g_conv_id                    := ln_task_assign_conv_id;
    g_record_control_id          := l_jtf_task_assgn_int.record_id;
    g_source_system_code         := l_jtf_task_assgn_int.task_assign_orig_sys;
    g_orig_sys_ref               := l_jtf_task_assgn_int.task_assign_orig_sys_ref;
    g_staging_table_name         := 'XX_JTF_IMP_TASK_ASSGN_INT';
    g_batch_id                   := l_jtf_task_assgn_int.batch_id;
    --------------------------------
    -- Data validations
    --------------------------------

    --------------------------------------
    -- Validating task_orig_system_ref
    --------------------------------------
    IF  l_jtf_task_assgn_int.task_orig_system_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0012_TASK_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'task_orig_system_ref';
        lc_staging_column_value             := l_jtf_task_assgn_int.task_orig_system_ref;

        log_exception
            (
                p_conversion_id             => ln_task_assign_conv_id
               ,p_record_control_id         => l_jtf_task_assgn_int.record_id
               ,p_source_system_code        => l_jtf_task_assgn_int.task_assign_orig_sys
               ,p_source_system_ref         => l_jtf_task_assgn_int.task_assign_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_task_assgn_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0012_TASK_OSR_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_task_assgn_create_flag := FALSE;

    END IF;

    --------------------------------------
    -- Validating task_assign_orig_sys_ref
    --------------------------------------
    IF  l_jtf_task_assgn_int.task_assign_orig_sys_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0013_TASK_ASS_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'task_assign_orig_sys_ref';
        lc_staging_column_value             := l_jtf_task_assgn_int.task_assign_orig_sys_ref;
        log_exception
            (
                p_conversion_id             => ln_task_assign_conv_id
               ,p_record_control_id         => l_jtf_task_assgn_int.record_id
               ,p_source_system_code        => l_jtf_task_assgn_int.task_assign_orig_sys
               ,p_source_system_ref         => l_jtf_task_assgn_int.task_assign_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_task_assgn_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0013_TASK_ASS_OSR_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_task_assgn_create_flag := FALSE;

    END IF;

    --------------------------------------
    -- Validating task_assign_orig_sys_ref
    --------------------------------------
    IF  l_jtf_task_assgn_int.resource_orig_system_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0014_RES_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'resource_orig_system_ref';
        lc_staging_column_value             := l_jtf_task_assgn_int.resource_orig_system_ref;
        log_exception
            (
                p_conversion_id             => ln_task_assign_conv_id
               ,p_record_control_id         => l_jtf_task_assgn_int.record_id
               ,p_source_system_code        => l_jtf_task_assgn_int.task_assign_orig_sys
               ,p_source_system_ref         => l_jtf_task_assgn_int.task_assign_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_task_assgn_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0014_RES_OSR_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_task_assgn_create_flag := FALSE;

    END IF;

    ---------------------------
    -- Retrieving task_id
    ---------------------------
    IF l_jtf_task_assgn_int.task_orig_system_ref IS NOT NULL THEN

        Get_task_id
            (
                 p_task_orig_system_ref => l_jtf_task_assgn_int.task_orig_system_ref
                ,x_task_id              => ln_jtf_task_id
            );

            IF ln_jtf_task_id IS NULL THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0015_INV_TASK_OSR');
                FND_MESSAGE.SET_TOKEN('P_TASK_OSR',l_jtf_task_assgn_int.task_orig_system_ref);
                g_errbuf := FND_MESSAGE.GET;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf);
                lc_exception_log                    := g_errbuf;
                lc_oracle_error_msg                 := g_errbuf;
                lc_staging_column_name              := 'task_orig_system_ref';
                lc_staging_column_value             := l_jtf_task_assgn_int.task_orig_system_ref;
                log_exception
                    (
                        p_conversion_id             => ln_task_assign_conv_id
                       ,p_record_control_id         => l_jtf_task_assgn_int.record_id
                       ,p_source_system_code        => l_jtf_task_assgn_int.task_assign_orig_sys
                       ,p_source_system_ref         => l_jtf_task_assgn_int.task_assign_orig_sys_ref
                       ,p_procedure_name            => lc_procedure_name
                       ,p_staging_table_name        => lc_staging_table_name
                       ,p_staging_column_name       => lc_staging_column_name
                       ,p_staging_column_value      => lc_staging_column_value
                       ,p_batch_id                  => l_jtf_task_assgn_int.batch_id
                       ,p_exception_log             => lc_exception_log
                       ,p_oracle_error_code         => 'XX_SFA_0015_INV_TASK_OSR'
                       ,p_oracle_error_msg          => lc_oracle_error_msg
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                          
                    );
                lb_task_assgn_create_flag := FALSE;
            END IF;
    END IF;

    ----------------------------------
    -- Retrieving assignment_status_id
    ----------------------------------
    IF l_jtf_task_assgn_int.assignment_status_name IS NOT NULL THEN

        Get_assign_status_id
            (
                 p_assign_status_name            => l_jtf_task_assgn_int.assignment_status_name
                ,x_assign_status_id              => ln_assgn_status_id
            );

            IF ln_assgn_status_id IS NULL THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0016_INV_ASS_STA_NM');
                FND_MESSAGE.SET_TOKEN('P_ASSGN_STNM',l_jtf_task_assgn_int.assignment_status_name);
                g_errbuf := FND_MESSAGE.GET;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf);
                lc_exception_log                    := g_errbuf;
                lc_oracle_error_msg                 := g_errbuf;
                lc_staging_column_name              := 'assignment_status_name';
                lc_staging_column_value             := l_jtf_task_assgn_int.assignment_status_name;
                log_exception
                    (
                        p_conversion_id             => ln_task_assign_conv_id
                       ,p_record_control_id         => l_jtf_task_assgn_int.record_id
                       ,p_source_system_code        => l_jtf_task_assgn_int.task_assign_orig_sys
                       ,p_source_system_ref         => l_jtf_task_assgn_int.task_assign_orig_sys_ref
                       ,p_procedure_name            => lc_procedure_name
                       ,p_staging_table_name        => lc_staging_table_name
                       ,p_staging_column_name       => lc_staging_column_name
                       ,p_staging_column_value      => lc_staging_column_value
                       ,p_batch_id                  => l_jtf_task_assgn_int.batch_id
                       ,p_exception_log             => lc_exception_log
                       ,p_oracle_error_code         => 'XX_SFA_0016_INV_ASS_STA_NM'
                       ,p_oracle_error_msg          => lc_oracle_error_msg
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                          
                    );
                lb_task_assgn_create_flag := FALSE;
            END IF;
    END IF;

    ---------------------------
    -- Retrieving resource_id
    ---------------------------
    IF l_jtf_task_assgn_int.resource_orig_system_ref IS NOT NULL THEN

        Get_resource_id
            (
                 p_resource_orig_system_ref    => l_jtf_task_assgn_int.resource_orig_system_ref
                ,x_resource_id                 => ln_resource_id
                ,x_user_id                     => ln_user_id
                ,x_own_type_code               => ln_owner_type_code
            );

            IF ln_resource_id IS NULL THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0017_INV_RES_OSR');
                FND_MESSAGE.SET_TOKEN('P_RESOURCE_OSR',l_jtf_task_assgn_int.resource_orig_system_ref);
                g_errbuf := FND_MESSAGE.GET;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf);
                lc_exception_log                    := g_errbuf;
                lc_oracle_error_msg                 := g_errbuf;
                lc_staging_column_name              := 'resource_orig_system_ref';
                lc_staging_column_value             := l_jtf_task_assgn_int.resource_orig_system_ref;
                log_exception
                    (
                        p_conversion_id             => ln_task_assign_conv_id
                       ,p_record_control_id         => l_jtf_task_assgn_int.record_id
                       ,p_source_system_code        => l_jtf_task_assgn_int.task_assign_orig_sys
                       ,p_source_system_ref         => l_jtf_task_assgn_int.task_assign_orig_sys_ref
                       ,p_procedure_name            => lc_procedure_name
                       ,p_staging_table_name        => lc_staging_table_name
                       ,p_staging_column_name       => lc_staging_column_name
                       ,p_staging_column_value      => lc_staging_column_value
                       ,p_batch_id                  => l_jtf_task_assgn_int.batch_id
                       ,p_exception_log             => lc_exception_log
                       ,p_oracle_error_code         => 'XX_SFA_0017_INV_RES_OSR'
                       ,p_oracle_error_msg          => lc_oracle_error_msg
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                          
                    );
                lb_task_assgn_create_flag := FALSE;
            END IF;

    END IF;

    IF lb_task_assgn_create_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||': Cannot create task assignments - Validation Failed');
        x_task_assgn_ret_status     := 'V';
        RETURN;
    END IF;

    --------------------------------
    -- Retrieving task_assignment_id
    --------------------------------
    IF l_jtf_task_assgn_int.task_assign_orig_sys_ref IS NOT NULL THEN

        Get_task_assignment_id
            (
                 p_task_assign_orig_sys_ref   => l_jtf_task_assgn_int.task_assign_orig_sys_ref
                ,x_task_assign_id             => ln_task_assign_id
                ,x_obj_ver_num                => ln_obj_ver_num
            );
    END IF;
    IF ln_task_assign_id IS NULL AND
       l_jtf_task_assgn_int.insert_update_flag = 'I' THEN

        --------------------------------
        -- Create task assignment
        --------------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': create a new task assignment');
        log_debug_msg('-------------------------------------');

        jtf_task_assignments_pub.create_task_assignment
            (
                 p_api_version                 => ln_api_version
                ,p_init_msg_list               => fnd_api.g_true
                ,p_commit                      => fnd_api.g_false
                --,p_task_assignment_id        =>
                ,p_task_id                     => ln_jtf_task_id
                --,p_task_number               =>
                --,p_task_name                 =>
                ,p_resource_type_code          => ln_owner_type_code
                ,p_resource_id                 => ln_resource_id
                --,p_resource_name             =>
                ,p_actual_effort               => l_jtf_task_assgn_int.actual_effort
                ,p_actual_effort_uom           => l_jtf_task_assgn_int.actual_effort_uom
                ,p_schedule_flag               => l_jtf_task_assgn_int.schedule_flag
                ,p_alarm_type_code             => l_jtf_task_assgn_int.alarm_type_code
                ,p_alarm_contact               => l_jtf_task_assgn_int.alarm_contact
                ,p_sched_travel_distance       => l_jtf_task_assgn_int.sched_travel_distance
                ,p_sched_travel_duration       => l_jtf_task_assgn_int.sched_travel_duration
                ,p_sched_travel_duration_uom   => l_jtf_task_assgn_int.sched_travel_duration_uom
                ,p_actual_travel_distance      => l_jtf_task_assgn_int.actual_travel_distance
                ,p_actual_travel_duration      => l_jtf_task_assgn_int.actual_travel_duration
                ,p_actual_travel_duration_uom  => l_jtf_task_assgn_int.actual_travel_duration_uom
                ,p_actual_start_date           => l_jtf_task_assgn_int.actual_start_date
                ,p_actual_end_date             => l_jtf_task_assgn_int.actual_end_date
                ,p_palm_flag                   => l_jtf_task_assgn_int.palm_flag
                ,p_wince_flag                  => l_jtf_task_assgn_int.wince_flag
                ,p_laptop_flag                 => l_jtf_task_assgn_int.laptop_flag
                ,p_device1_flag                => l_jtf_task_assgn_int.device1_flag
                ,p_device2_flag                => l_jtf_task_assgn_int.device2_flag
                ,p_device3_flag                => l_jtf_task_assgn_int.device3_flag
                ,p_resource_territory_id       => l_jtf_task_assgn_int.resource_territory_id
                ,p_assignment_status_id        => ln_assgn_status_id
                ,p_shift_construct_id          => l_jtf_task_assgn_int.shift_construct_id
                ,x_return_status               => lc_return_status
                ,x_msg_count                   => ln_msg_count
                ,x_msg_data                    => lc_msg_data
                ,x_task_assignment_id          => ln_task_assignment_id
                ,p_attribute1                  => l_jtf_task_assgn_int.attribute1
                ,p_attribute2                  => l_jtf_task_assgn_int.attribute2
                ,p_attribute3                  => l_jtf_task_assgn_int.attribute3
                ,p_attribute4                  => l_jtf_task_assgn_int.attribute4
                ,p_attribute5                  => l_jtf_task_assgn_int.attribute5
                ,p_attribute6                  => l_jtf_task_assgn_int.attribute6
                ,p_attribute7                  => l_jtf_task_assgn_int.attribute7
                ,p_attribute8                  => l_jtf_task_assgn_int.attribute8
                ,p_attribute9                  => l_jtf_task_assgn_int.attribute9
                ,p_attribute10                 => l_jtf_task_assgn_int.attribute10
                ,p_attribute11                 => l_jtf_task_assgn_int.attribute11
                ,p_attribute12                 => l_jtf_task_assgn_int.attribute12
                ,p_attribute13                 => l_jtf_task_assgn_int.attribute13
                ,p_attribute14                 => l_jtf_task_assgn_int.attribute14
                ,p_attribute15                 => l_jtf_task_assgn_int.task_assign_orig_sys_ref
                ,p_attribute_category          => l_jtf_task_assgn_int.attribute_category
                ,p_show_on_calendar            => l_jtf_task_assgn_int.show_on_calendar
                ,p_category_id                 => l_jtf_task_assgn_int.category_id
                ,p_enable_workflow             => l_jtf_task_assgn_int.enable_workflow
                ,p_abort_workflow              => l_jtf_task_assgn_int.abort_workflow
                ,p_object_capacity_id          => l_jtf_task_assgn_int.object_capacity_id
                ,p_free_busy_type              => l_jtf_task_assgn_int.free_busy_type
            );

        x_task_assgn_ret_status   := lc_return_status;

        IF lc_return_status = 'S' THEN

            log_debug_msg('task assignment successfully created !!!');

        ELSE
            log_debug_msg('task assignment not created !!!');
            IF ln_msg_count >= 1 THEN
                FOR I IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||I||' . '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                    lc_msg_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE)||lc_msg_data;
                END LOOP;
            END IF;
            log_exception
            (
                p_conversion_id             => ln_task_assign_conv_id
               ,p_record_control_id         => l_jtf_task_assgn_int.record_id
               ,p_source_system_code        => l_jtf_task_assgn_int.task_assign_orig_sys
               ,p_source_system_ref         => l_jtf_task_assgn_int.task_assign_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASK_ASSIGNMENTS_PUB.CREATE_TASK_ASSIGNMENT'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_task_assgn_int.batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_data
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;

    ELSIF ln_task_assign_id IS NOT NULL AND
       l_jtf_task_assgn_int.insert_update_flag = 'U' THEN

        --------------------------------
        -- Update task assignment
        --------------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': update a task assignment');
        log_debug_msg('-------------------------------------');

        jtf_task_assignments_pub.update_task_assignment
            (
                 p_api_version                 => ln_api_version
                ,p_object_version_number       => ln_obj_ver_num
                ,p_init_msg_list               => fnd_api.g_true
                ,p_commit                      => fnd_api.g_false
                ,p_task_assignment_id          => ln_task_assign_id
                ,p_task_id                     => ln_jtf_task_id
                --,p_task_number               =>
                --,p_task_name                 =>
                ,p_resource_type_code          => ln_owner_type_code
                ,p_resource_id                 => ln_resource_id
                --,p_resource_name             =>
                ,p_actual_effort               => l_jtf_task_assgn_int.actual_effort
                ,p_actual_effort_uom           => l_jtf_task_assgn_int.actual_effort_uom
                ,p_schedule_flag               => l_jtf_task_assgn_int.schedule_flag
                ,p_alarm_type_code             => l_jtf_task_assgn_int.alarm_type_code
                ,p_alarm_contact               => l_jtf_task_assgn_int.alarm_contact
                ,p_sched_travel_distance       => l_jtf_task_assgn_int.sched_travel_distance
                ,p_sched_travel_duration       => l_jtf_task_assgn_int.sched_travel_duration
                ,p_sched_travel_duration_uom   => l_jtf_task_assgn_int.sched_travel_duration_uom
                ,p_actual_travel_distance      => l_jtf_task_assgn_int.actual_travel_distance
                ,p_actual_travel_duration      => l_jtf_task_assgn_int.actual_travel_duration
                ,p_actual_travel_duration_uom  => l_jtf_task_assgn_int.actual_travel_duration_uom
                ,p_actual_start_date           => l_jtf_task_assgn_int.actual_start_date
                ,p_actual_end_date             => l_jtf_task_assgn_int.actual_end_date
                ,p_palm_flag                   => l_jtf_task_assgn_int.palm_flag
                ,p_wince_flag                  => l_jtf_task_assgn_int.wince_flag
                ,p_laptop_flag                 => l_jtf_task_assgn_int.laptop_flag
                ,p_device1_flag                => l_jtf_task_assgn_int.device1_flag
                ,p_device2_flag                => l_jtf_task_assgn_int.device2_flag
                ,p_device3_flag                => l_jtf_task_assgn_int.device3_flag
                ,p_resource_territory_id       => l_jtf_task_assgn_int.resource_territory_id
                ,p_assignment_status_id        => ln_assgn_status_id
                ,p_shift_construct_id          => l_jtf_task_assgn_int.shift_construct_id
                ,x_return_status               => lc_return_status
                ,x_msg_count                   => ln_msg_count
                ,x_msg_data                    => lc_msg_data
                ,p_attribute1                  => l_jtf_task_assgn_int.attribute1
                ,p_attribute2                  => l_jtf_task_assgn_int.attribute2
                ,p_attribute3                  => l_jtf_task_assgn_int.attribute3
                ,p_attribute4                  => l_jtf_task_assgn_int.attribute4
                ,p_attribute5                  => l_jtf_task_assgn_int.attribute5
                ,p_attribute6                  => l_jtf_task_assgn_int.attribute6
                ,p_attribute7                  => l_jtf_task_assgn_int.attribute7
                ,p_attribute8                  => l_jtf_task_assgn_int.attribute8
                ,p_attribute9                  => l_jtf_task_assgn_int.attribute9
                ,p_attribute10                 => l_jtf_task_assgn_int.attribute10
                ,p_attribute11                 => l_jtf_task_assgn_int.attribute11
                ,p_attribute12                 => l_jtf_task_assgn_int.attribute12
                ,p_attribute13                 => l_jtf_task_assgn_int.attribute13
                ,p_attribute14                 => l_jtf_task_assgn_int.attribute14
                ,p_attribute15                 => l_jtf_task_assgn_int.task_assign_orig_sys_ref
                ,p_attribute_category          => l_jtf_task_assgn_int.attribute_category
                ,p_show_on_calendar            => l_jtf_task_assgn_int.show_on_calendar
                ,p_category_id                 => l_jtf_task_assgn_int.category_id
                ,p_enable_workflow             => l_jtf_task_assgn_int.enable_workflow
                ,p_abort_workflow              => l_jtf_task_assgn_int.abort_workflow
                ,p_object_capacity_id          => l_jtf_task_assgn_int.object_capacity_id
            );

        x_task_assgn_ret_status   := lc_return_status;

        IF lc_return_status = 'S' THEN

            log_debug_msg('task assignment successfully updated !!!');

        ELSE
            log_debug_msg('task assignment not updated !!!');
            IF ln_msg_count >= 1 THEN
                FOR I IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||I||' . '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                    lc_msg_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE)||lc_msg_data;
                END LOOP;
            END IF;
            log_exception
            (
                p_conversion_id             => ln_task_assign_conv_id
               ,p_record_control_id         => l_jtf_task_assgn_int.record_id
               ,p_source_system_code        => l_jtf_task_assgn_int.task_assign_orig_sys
               ,p_source_system_ref         => l_jtf_task_assgn_int.task_assign_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASK_ASSIGNMENTS_PUB.UPDATE_TASK_ASSIGNMENT'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_task_assgn_int.batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_data
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;


    ELSIF ln_task_assign_id IS NOT NULL AND
       l_jtf_task_assgn_int.insert_update_flag = 'D' THEN

        --------------------------------
        -- Delete task assignment
        --------------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': delete a task assignment');
        log_debug_msg('-------------------------------------');

        jtf_task_assignments_pub.delete_task_assignment
            (
                p_api_version                 => ln_api_version
               ,p_object_version_number       => ln_obj_ver_num
               ,p_init_msg_list               => fnd_api.g_true
               ,p_commit                      => fnd_api.g_false
               ,p_task_assignment_id          => ln_task_assign_id
               ,x_return_status               => lc_return_status
               ,x_msg_count                   => ln_msg_count
               ,x_msg_data                    => lc_msg_data
               ,p_enable_workflow             => l_jtf_task_assgn_int.enable_workflow
               ,p_abort_workflow              => l_jtf_task_assgn_int.abort_workflow
            );

        x_task_assgn_ret_status   := lc_return_status;

        IF lc_return_status = 'S' THEN

            log_debug_msg('task assignment successfully deleted !!!');

        ELSE
            log_debug_msg('task assignment not deleted !!!');
            IF ln_msg_count >= 1 THEN
                FOR i IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||i||' . '|| FND_MSG_PUB.Get(i, FND_API.G_FALSE));
                    lc_msg_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE)||lc_msg_data;
                END LOOP;
            END IF;
            log_exception
            (
                p_conversion_id             => ln_task_assign_conv_id
               ,p_record_control_id         => l_jtf_task_assgn_int.record_id
               ,p_source_system_code        => l_jtf_task_assgn_int.task_assign_orig_sys
               ,p_source_system_ref         => l_jtf_task_assgn_int.task_assign_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASK_ASSIGNMENTS_PUB.DELETE_TASK_ASSIGNMENT'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_task_assgn_int.batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_data
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;

    END IF;

END create_task_assignment;


-- +===================================================================+
-- | Name        : create_task_dependency                              |
-- | Description : Procedure to create, update and delete              |
-- |               a task dependency                                   |
-- | Parameters  : l_jtf_tasks_depend_int                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_task_dependency
    (
        l_jtf_tasks_depend_int      IN          XX_JTF_IMP_TASKS_DEPEND_INT%ROWTYPE
       ,x_task_depend_ret_status    OUT NOCOPY  VARCHAR2
    )
AS

    lc_staging_column_name           VARCHAR2(32);
    lc_staging_column_value          VARCHAR2(500);
    lc_exception_log                 VARCHAR2(2000);
    lc_oracle_error_msg              VARCHAR2(2000);
    ln_task_dpnd_conv_id             NUMBER          := 801.4;
    lc_procedure_name                VARCHAR2(250)   := 'XX_JTF_TASKS_PKG.CREATE_TASK_DEPENDENCY';
    lc_staging_table_name            VARCHAR2(250)   := 'XX_JTF_IMP_TASKS_DEPEND_INT';
    lb_task_dpnd_create_flag         BOOLEAN         := TRUE;
    ---------------------------------
    -- Create_task_dependency
    ---------------------------------
    ln_api_version                   NUMBER := 1.0;
    ln_jtf_task_id                   jtf_tasks_b.task_id%TYPE;
    ln_jtf_dpnd_task_id              jtf_tasks_b.task_id%TYPE;

    ln_task_dpnd_id                  jtf_task_depends.dependency_id%TYPE;
    ln_obj_ver_num                   jtf_task_depends.object_version_number%TYPE;

    lc_return_status                 VARCHAR2(1);
    lc_msg_data                      VARCHAR2(2000);
    ln_msg_count                     NUMBER;
    ln_task_dependency_id            jtf_task_depends.dependency_id%TYPE;

BEGIN

    g_conv_id                    := ln_task_dpnd_conv_id;
    g_record_control_id          := l_jtf_tasks_depend_int.record_id;
    g_source_system_code         := l_jtf_tasks_depend_int.task_depend_orig_sys;
    g_orig_sys_ref               := l_jtf_tasks_depend_int.task_depend_orig_sys_ref;
    g_staging_table_name         :='XX_JTF_IMP_TASKS_DEPEND_INT';
    g_batch_id                   := l_jtf_tasks_depend_int.batch_id;

    --------------------------------
    -- Data validations
    --------------------------------

    --------------------------------------
    -- Validating task_depend_orig_sys_ref
    --------------------------------------
    IF  l_jtf_tasks_depend_int.task_depend_orig_sys_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0018_TASK_DEP_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'task_depend_orig_sys_ref';
        lc_staging_column_value             := l_jtf_tasks_depend_int.task_depend_orig_sys_ref;
        log_exception
            (
                p_conversion_id             => ln_task_dpnd_conv_id
               ,p_record_control_id         => l_jtf_tasks_depend_int.record_id
               ,p_source_system_code        => l_jtf_tasks_depend_int.task_depend_orig_sys
               ,p_source_system_ref         => l_jtf_tasks_depend_int.task_depend_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_tasks_depend_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0018_TASK_DEP_OSR_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_task_dpnd_create_flag := FALSE;

    END IF;

    --------------------------------------
    -- Validating task_orig_system_ref
    --------------------------------------
    IF  l_jtf_tasks_depend_int.task_orig_system_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0019_TASK_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'task_orig_system_ref';
        lc_staging_column_value             := l_jtf_tasks_depend_int.task_orig_system_ref;
        log_exception
            (
                p_conversion_id             => ln_task_dpnd_conv_id
               ,p_record_control_id         => l_jtf_tasks_depend_int.record_id
               ,p_source_system_code        => l_jtf_tasks_depend_int.task_depend_orig_sys
               ,p_source_system_ref         => l_jtf_tasks_depend_int.task_depend_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_tasks_depend_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0019_TASK_OSR_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_task_dpnd_create_flag := FALSE;

    END IF;

    --------------------------------------
    -- Validating dep_task_orig_sys_ref
    --------------------------------------
    IF  l_jtf_tasks_depend_int.dep_task_orig_sys_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0020_DEP_TASK_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'dep_task_orig_sys_ref';
        lc_staging_column_value             := l_jtf_tasks_depend_int.dep_task_orig_sys_ref;
        log_exception
            (
                p_conversion_id             => ln_task_dpnd_conv_id
               ,p_record_control_id         => l_jtf_tasks_depend_int.record_id
               ,p_source_system_code        => l_jtf_tasks_depend_int.task_depend_orig_sys
               ,p_source_system_ref         => l_jtf_tasks_depend_int.task_depend_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_tasks_depend_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0020_DEP_TASK_OSR_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_task_dpnd_create_flag := FALSE;

    END IF;

    ---------------------------
    -- Retrieving task_id
    ---------------------------
    IF l_jtf_tasks_depend_int.task_orig_system_ref IS NOT NULL THEN

        Get_task_id
            (
                 p_task_orig_system_ref => l_jtf_tasks_depend_int.task_orig_system_ref
                ,x_task_id              => ln_jtf_task_id
            );

            IF ln_jtf_task_id IS NULL THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0021_INV_TASK_OSR');
                FND_MESSAGE.SET_TOKEN('P_TASK_OSR',l_jtf_tasks_depend_int.task_orig_system_ref);
                g_errbuf := FND_MESSAGE.GET;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf);
                lc_exception_log                    := g_errbuf;
                lc_oracle_error_msg                 := g_errbuf;
                lc_staging_column_name              := 'task_orig_system_ref';
                lc_staging_column_value             := l_jtf_tasks_depend_int.dep_task_orig_sys_ref;
                log_exception
                    (
                        p_conversion_id             => ln_task_dpnd_conv_id
                       ,p_record_control_id         => l_jtf_tasks_depend_int.record_id
                       ,p_source_system_code        => l_jtf_tasks_depend_int.task_depend_orig_sys
                       ,p_source_system_ref         => l_jtf_tasks_depend_int.task_depend_orig_sys_ref
                       ,p_procedure_name            => lc_procedure_name
                       ,p_staging_table_name        => lc_staging_table_name
                       ,p_staging_column_name       => lc_staging_column_name
                       ,p_staging_column_value      => lc_staging_column_value
                       ,p_batch_id                  => l_jtf_tasks_depend_int.batch_id
                       ,p_exception_log             => lc_exception_log
                       ,p_oracle_error_code         => 'XX_SFA_0021_INV_TASK_OSR'
                       ,p_oracle_error_msg          => lc_oracle_error_msg
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                          
                    );
                lb_task_dpnd_create_flag := FALSE;

            END IF;
    END IF;

    -------------------------------
    -- Retrieving dependent_task_id
    -------------------------------
    IF l_jtf_tasks_depend_int.dep_task_orig_sys_ref IS NOT NULL THEN

        Get_task_id
            (
                 p_task_orig_system_ref => l_jtf_tasks_depend_int.dep_task_orig_sys_ref
                ,x_task_id              => ln_jtf_dpnd_task_id
            );

            IF ln_jtf_dpnd_task_id IS NULL THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0022_INV_DEP_TASK_OSR');
                FND_MESSAGE.SET_TOKEN('P_DEPTASK_OSR',l_jtf_tasks_depend_int.dep_task_orig_sys_ref);
                g_errbuf := FND_MESSAGE.GET;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf);
                lc_exception_log                    := g_errbuf;
                lc_oracle_error_msg                 := g_errbuf;
                lc_staging_column_name              := 'dep_task_orig_sys_ref';
                lc_staging_column_value             := l_jtf_tasks_depend_int.dep_task_orig_sys_ref;
                log_exception
                    (
                        p_conversion_id             => ln_task_dpnd_conv_id
                       ,p_record_control_id         => l_jtf_tasks_depend_int.record_id
                       ,p_source_system_code        => l_jtf_tasks_depend_int.task_depend_orig_sys
                       ,p_source_system_ref         => l_jtf_tasks_depend_int.task_depend_orig_sys_ref
                       ,p_procedure_name            => lc_procedure_name
                       ,p_staging_table_name        => lc_staging_table_name
                       ,p_staging_column_name       => lc_staging_column_name
                       ,p_staging_column_value      => lc_staging_column_value
                       ,p_batch_id                  => l_jtf_tasks_depend_int.batch_id
                       ,p_exception_log             => lc_exception_log
                       ,p_oracle_error_code         => 'XX_SFA_0022_INV_DEP_TASK_OSR'
                       ,p_oracle_error_msg          => lc_oracle_error_msg
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                          
                    );
                lb_task_dpnd_create_flag := FALSE;

            END IF;
    END IF;

    IF lb_task_dpnd_create_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||': Cannot create task dependency - Validation Failed');
        x_task_depend_ret_status     := 'V';
        RETURN;
    END IF;

    --------------------------------
    -- Retrieving task_dependency_id
    --------------------------------
    IF l_jtf_tasks_depend_int.task_depend_orig_sys_ref IS NOT NULL THEN

        Get_task_dependency_id
            (
                 p_task_dpnd_orig_sys_ref     => l_jtf_tasks_depend_int.task_depend_orig_sys_ref
                ,x_task_dpnd_id               => ln_task_dpnd_id
                ,x_obj_ver_num                => ln_obj_ver_num
            );

    END IF;

    IF ln_task_dpnd_id IS NULL AND
       l_jtf_tasks_depend_int.insert_update_flag = 'I' THEN

        --------------------------------
        -- Create task dependency
        --------------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': create a task dependency');
        log_debug_msg('-------------------------------------');

        jtf_task_dependency_pub.create_task_dependency
            (
                 p_api_version                 => ln_api_version
                ,p_init_msg_list               => fnd_api.g_true
                ,p_commit                      => fnd_api.g_false
                ,p_validation_level            => fnd_api.g_valid_level_full
                ,p_task_id                     => ln_jtf_task_id
                --,p_task_number               =>
                ,p_dependent_on_task_id        => ln_jtf_dpnd_task_id
                --,p_dependent_on_task_number  =>
                ,p_dependency_type_code        => l_jtf_tasks_depend_int.dependency_type_code
                ,p_template_flag               => l_jtf_tasks_depend_int.template_flag
                ,p_adjustment_time             => l_jtf_tasks_depend_int.adjustment_time
                ,p_adjustment_time_uom         => l_jtf_tasks_depend_int.adjustment_time_uom
                ,p_validated_flag              => l_jtf_tasks_depend_int.validated_flag
                ,x_dependency_id               => ln_task_dependency_id
                ,x_return_status               => lc_return_status
                ,x_msg_count                   => ln_msg_count
                ,x_msg_data                    => lc_msg_data
                ,p_attribute1                  => l_jtf_tasks_depend_int.attribute1
                ,p_attribute2                  => l_jtf_tasks_depend_int.attribute2
                ,p_attribute3                  => l_jtf_tasks_depend_int.attribute3
                ,p_attribute4                  => l_jtf_tasks_depend_int.attribute4
                ,p_attribute5                  => l_jtf_tasks_depend_int.attribute5
                ,p_attribute6                  => l_jtf_tasks_depend_int.attribute6
                ,p_attribute7                  => l_jtf_tasks_depend_int.attribute7
                ,p_attribute8                  => l_jtf_tasks_depend_int.attribute8
                ,p_attribute9                  => l_jtf_tasks_depend_int.attribute9
                ,p_attribute10                 => l_jtf_tasks_depend_int.attribute10
                ,p_attribute11                 => l_jtf_tasks_depend_int.attribute11
                ,p_attribute12                 => l_jtf_tasks_depend_int.attribute12
                ,p_attribute13                 => l_jtf_tasks_depend_int.attribute13
                ,p_attribute14                 => l_jtf_tasks_depend_int.attribute14
                ,p_attribute15                 => l_jtf_tasks_depend_int.task_depend_orig_sys_ref
                ,p_attribute_category          => l_jtf_tasks_depend_int.attribute_category
            );

        x_task_depend_ret_status   := lc_return_status;

        IF lc_return_status = 'S' THEN

            log_debug_msg('task dependency successfully created !!!');

        ELSE
            log_debug_msg('task dependency not created !!!');
            IF ln_msg_count >= 1 THEN
                FOR I IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||I||' . '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                    lc_msg_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE)||lc_msg_data;
                END LOOP;
            END IF;

            log_exception
            (
                p_conversion_id             => ln_task_dpnd_conv_id
               ,p_record_control_id         => l_jtf_tasks_depend_int.record_id
               ,p_source_system_code        => l_jtf_tasks_depend_int.task_depend_orig_sys
               ,p_source_system_ref         => l_jtf_tasks_depend_int.task_depend_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASK_DEPENDENCY_PUB.CREATE_TASK_DEPENDENCY'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_tasks_depend_int.batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_data
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;

    ELSIF ln_task_dpnd_id IS NOT NULL AND
       l_jtf_tasks_depend_int.insert_update_flag = 'U' THEN

        --------------------------------
        -- Update task dependency
        --------------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': update a task dependency');
        log_debug_msg('-------------------------------------');

        jtf_task_dependency_pub.update_task_dependency
            (
                 p_api_version                 => ln_api_version
                ,p_init_msg_list               => fnd_api.g_true
                ,p_commit                      => fnd_api.g_false
                ,p_object_version_number       => ln_obj_ver_num
                ,p_dependency_id               => ln_task_dpnd_id
                ,p_task_id                     => ln_jtf_task_id
                --,p_task_number               =>
                ,p_dependent_on_task_id        => ln_jtf_dpnd_task_id
                --,p_dependent_on_task_number  =>
                ,p_dependency_type_code        => l_jtf_tasks_depend_int.dependency_type_code
                ,p_adjustment_time             => l_jtf_tasks_depend_int.adjustment_time
                ,p_adjustment_time_uom         => l_jtf_tasks_depend_int.adjustment_time_uom
                ,p_validated_flag              => l_jtf_tasks_depend_int.validated_flag
                ,x_return_status               => lc_return_status
                ,x_msg_count                   => ln_msg_count
                ,x_msg_data                    => lc_msg_data
                ,p_attribute1                  => l_jtf_tasks_depend_int.attribute1
                ,p_attribute2                  => l_jtf_tasks_depend_int.attribute2
                ,p_attribute3                  => l_jtf_tasks_depend_int.attribute3
                ,p_attribute4                  => l_jtf_tasks_depend_int.attribute4
                ,p_attribute5                  => l_jtf_tasks_depend_int.attribute5
                ,p_attribute6                  => l_jtf_tasks_depend_int.attribute6
                ,p_attribute7                  => l_jtf_tasks_depend_int.attribute7
                ,p_attribute8                  => l_jtf_tasks_depend_int.attribute8
                ,p_attribute9                  => l_jtf_tasks_depend_int.attribute9
                ,p_attribute10                 => l_jtf_tasks_depend_int.attribute10
                ,p_attribute11                 => l_jtf_tasks_depend_int.attribute11
                ,p_attribute12                 => l_jtf_tasks_depend_int.attribute12
                ,p_attribute13                 => l_jtf_tasks_depend_int.attribute13
                ,p_attribute14                 => l_jtf_tasks_depend_int.attribute14
                ,p_attribute15                 => l_jtf_tasks_depend_int.task_depend_orig_sys_ref
                ,p_attribute_category          => l_jtf_tasks_depend_int.attribute_category
            );
        x_task_depend_ret_status   := lc_return_status;

        IF lc_return_status = 'S' THEN

            log_debug_msg('task dependency successfully updated !!!');

        ELSE
            log_debug_msg('task dependency not updated !!!');
            IF ln_msg_count >= 1 THEN
                FOR I IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||I||' . '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                    lc_msg_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE)||lc_msg_data;
                END LOOP;
            END IF;

            log_exception
            (
                p_conversion_id             => ln_task_dpnd_conv_id
               ,p_record_control_id         => l_jtf_tasks_depend_int.record_id
               ,p_source_system_code        => l_jtf_tasks_depend_int.task_depend_orig_sys
               ,p_source_system_ref         => l_jtf_tasks_depend_int.task_depend_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASK_DEPENDENCY_PUB.UPDATE_TASK_DEPENDENCY'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_tasks_depend_int.batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_data
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;

    ELSIF ln_task_dpnd_id IS NOT NULL AND
       l_jtf_tasks_depend_int.insert_update_flag = 'D' THEN

        --------------------------------
        -- Delete task dependency
        --------------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': delete a task dependency');
        log_debug_msg('-------------------------------------');

        jtf_task_dependency_pub.delete_task_dependency
            (
                p_api_version                 => ln_api_version
               ,p_init_msg_list               => fnd_api.g_true
               ,p_commit                      => fnd_api.g_false
               ,p_object_version_number       => ln_obj_ver_num
               ,p_dependency_id               => ln_task_dpnd_id
               ,x_return_status               => lc_return_status
               ,x_msg_count                   => ln_msg_count
               ,x_msg_data                    => lc_msg_data
            );

        x_task_depend_ret_status   := lc_return_status;

        IF lc_return_status = 'S' THEN

            log_debug_msg('task dependency successfully deleted !!!');

        ELSE
            log_debug_msg('task dependency not deleted !!!');
            IF ln_msg_count >= 1 THEN
                FOR I IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||I||' . '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                    lc_msg_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE)||lc_msg_data;
                END LOOP;
            END IF;

            log_exception
            (
                p_conversion_id             => ln_task_dpnd_conv_id
               ,p_record_control_id         => l_jtf_tasks_depend_int.record_id
               ,p_source_system_code        => l_jtf_tasks_depend_int.task_depend_orig_sys
               ,p_source_system_ref         => l_jtf_tasks_depend_int.task_depend_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASK_DEPENDENCY_PUB.DELETE_TASK_DEPENDENCY'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_tasks_depend_int.batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_data
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;

    END IF;

END create_task_dependency;

-- +===================================================================+
-- | Name        : create_task_recurrence                              |
-- | Description : Procedure to create and update a task recurrence    |
-- |                                                                   |
-- | Parameters  : l_jtf_tasks_recur_int                               |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_task_recurrence
    (
        l_jtf_tasks_recur_int       IN          XX_JTF_IMP_TASK_RECUR_INT%ROWTYPE
       ,x_tasks_recur_return_status OUT NOCOPY  VARCHAR2
    )
AS

    lc_staging_column_name           VARCHAR2(32);
    lc_staging_column_value          VARCHAR2(500);
    lc_exception_log                 VARCHAR2(2000);
    lc_oracle_error_msg              VARCHAR2(2000);
    ln_task_recur_conv_id            NUMBER          := 801.5;
    lc_procedure_name                VARCHAR2(250)   := 'XX_JTF_TASKS_PKG.CREATE_TASK_RECURRENCE';
    lc_staging_table_name            VARCHAR2(250)   := 'XX_JTF_IMP_TASK_RECUR_INT';
    lb_task_recur_create_flag        BOOLEAN         := TRUE;
    ---------------------------------
    -- Create_task_recurrence
    ---------------------------------
    ln_api_version                   NUMBER := 1.0;
    ln_jtf_task_id                   jtf_tasks_b.task_id%TYPE;

    ln_task_recur_id                 jtf_task_recur_rules.recurrence_rule_id%TYPE;
    ln_obj_ver_num                   jtf_task_recur_rules.object_version_number%TYPE;

    lc_return_status                 VARCHAR2(1);
    lc_msg_data                      VARCHAR2(2000);
    ln_msg_count                     NUMBER;
    ln_task_recurrence_id            jtf_task_recur_rules.recurrence_rule_id%TYPE;
    lr_task_rec                      jtf_task_recurrences_pub.task_details_rec;
    ln_reccur_generated              NUMBER;


BEGIN
    g_conv_id                    := ln_task_recur_conv_id;
    g_record_control_id          := l_jtf_tasks_recur_int.record_id;
    g_source_system_code         := l_jtf_tasks_recur_int.task_recurr_orig_sys;
    g_orig_sys_ref               := l_jtf_tasks_recur_int.task_recurr_orig_sys_ref;
    g_staging_table_name         := 'XX_JTF_IMP_TASK_RECUR_INT';
    g_batch_id                   := l_jtf_tasks_recur_int.batch_id;
    --------------------------------
    -- Data validations
    --------------------------------

    --------------------------------------
    -- Validating task_recurr_orig_sys_ref
    --------------------------------------
    IF  l_jtf_tasks_recur_int.task_recurr_orig_sys_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0023_TASK_REC_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'task_recurr_orig_sys_ref';
        lc_staging_column_value             := l_jtf_tasks_recur_int.task_recurr_orig_sys_ref;
        log_exception
            (
                p_conversion_id             => ln_task_recur_conv_id
               ,p_record_control_id         => l_jtf_tasks_recur_int.record_id
               ,p_source_system_code        => l_jtf_tasks_recur_int.task_recurr_orig_sys
               ,p_source_system_ref         => l_jtf_tasks_recur_int.task_recurr_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_tasks_recur_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0023_TASK_REC_OSR_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        lb_task_recur_create_flag := FALSE;

    END IF;

    --------------------------------------
    -- Validating task_orig_system_ref
    --------------------------------------
    IF  l_jtf_tasks_recur_int.task_orig_system_ref IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0024_TASK_OSR_NULL');
        g_errbuf := FND_MESSAGE.GET;
        log_debug_msg(lc_procedure_name||' : '||g_errbuf);
        lc_exception_log                    := g_errbuf;
        lc_oracle_error_msg                 := g_errbuf;
        lc_staging_column_name              := 'task_orig_system_ref';
        lc_staging_column_value             := l_jtf_tasks_recur_int.task_orig_system_ref;
        log_exception
            (
                p_conversion_id             => ln_task_recur_conv_id
               ,p_record_control_id         => l_jtf_tasks_recur_int.record_id
               ,p_source_system_code        => l_jtf_tasks_recur_int.task_recurr_orig_sys
               ,p_source_system_ref         => l_jtf_tasks_recur_int.task_recurr_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => lc_staging_column_name
               ,p_staging_column_value      => lc_staging_column_value
               ,p_batch_id                  => l_jtf_tasks_recur_int.batch_id
               ,p_exception_log             => lc_exception_log
               ,p_oracle_error_code         => 'XX_SFA_0024_TASK_OSR_NULL'
               ,p_oracle_error_msg          => lc_oracle_error_msg
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR   
            );
        lb_task_recur_create_flag := FALSE;

    END IF;


    ---------------------------
    -- Retrieving task_id
    ---------------------------
    IF l_jtf_tasks_recur_int.task_orig_system_ref IS NOT NULL THEN

        Get_task_id
            (
                 p_task_orig_system_ref => l_jtf_tasks_recur_int.task_orig_system_ref
                ,x_task_id              => ln_jtf_task_id
            );

            IF ln_jtf_task_id IS NULL THEN

                FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_0025_INV_TASK_OSR');
                FND_MESSAGE.SET_TOKEN('P_TASK_OSR',l_jtf_tasks_recur_int.task_orig_system_ref);
                g_errbuf := FND_MESSAGE.GET;
                log_debug_msg(lc_procedure_name||' : '||g_errbuf);
                lc_exception_log                    := g_errbuf;
                lc_oracle_error_msg                 := g_errbuf;
                lc_staging_column_name              := 'task_orig_system_ref';
                lc_staging_column_value             := l_jtf_tasks_recur_int.task_orig_system_ref;
                log_exception
                    (
                        p_conversion_id             => ln_task_recur_conv_id
                       ,p_record_control_id         => l_jtf_tasks_recur_int.record_id
                       ,p_source_system_code        => l_jtf_tasks_recur_int.task_recurr_orig_sys
                       ,p_source_system_ref         => l_jtf_tasks_recur_int.task_recurr_orig_sys_ref
                       ,p_procedure_name            => lc_procedure_name
                       ,p_staging_table_name        => lc_staging_table_name
                       ,p_staging_column_name       => lc_staging_column_name
                       ,p_staging_column_value      => lc_staging_column_value
                       ,p_batch_id                  => l_jtf_tasks_recur_int.batch_id
                       ,p_exception_log             => lc_exception_log
                       ,p_oracle_error_code         => 'XX_SFA_0025_INV_TASK_OSR'
                       ,p_oracle_error_msg          => lc_oracle_error_msg
                       ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                          
                    );
                lb_task_recur_create_flag := FALSE;

            END IF;
    END IF;


    IF lb_task_recur_create_flag = FALSE THEN
        log_debug_msg(lc_procedure_name||': Cannot create task dependency - Validation Failed');
        x_tasks_recur_return_status     := 'V';
        RETURN;
    END IF;

    --------------------------------
    -- Retrieving recurrence_rule_id
    --------------------------------
    IF l_jtf_tasks_recur_int.task_recurr_orig_sys_ref IS NOT NULL THEN

        Get_task_recurrence_id
            (
                 p_task_recur_orig_sys_ref     => l_jtf_tasks_recur_int.task_recurr_orig_sys_ref
                ,x_task_recur_id               => ln_task_recur_id
                ,x_obj_ver_num                 => ln_obj_ver_num
            );

    END IF;
    IF ln_task_recur_id IS NULL AND
       l_jtf_tasks_recur_int.insert_update_flag = 'I' THEN

        --------------------------------
        -- Create task recurrence
        --------------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': create a task recurrence');
        log_debug_msg('-------------------------------------');

        jtf_task_recurrences_pub.create_task_recurrence
            (
                 p_api_version                 => ln_api_version
                ,p_init_msg_list               => fnd_api.g_true
                ,p_commit                      => fnd_api.g_false
                ,p_task_id                     => ln_jtf_task_id
                --,p_task_number               =>
                ,p_occurs_which                => l_jtf_tasks_recur_int.occurs_which
                ,p_template_flag               => l_jtf_tasks_recur_int.template_flag
                ,p_day_of_week                 => l_jtf_tasks_recur_int.day_of_week
                ,p_date_of_month               => l_jtf_tasks_recur_int.date_of_month
                ,p_occurs_month                => l_jtf_tasks_recur_int.occurs_month
                ,p_occurs_uom                  => l_jtf_tasks_recur_int.occurs_uom
                ,p_occurs_every                => l_jtf_tasks_recur_int.occurs_every
                ,p_occurs_number               => l_jtf_tasks_recur_int.occurs_number
                ,p_start_date_active           => l_jtf_tasks_recur_int.start_date_active
                ,p_end_date_active             => l_jtf_tasks_recur_int.end_date_active
                ,x_return_status               => lc_return_status
                ,x_msg_count                   => ln_msg_count
                ,x_msg_data                    => lc_msg_data
                ,x_recurrence_rule_id          => ln_task_recurrence_id
                ,x_task_rec                    => lr_task_rec
                ,x_reccurences_generated       => ln_reccur_generated
                ,p_attribute1                  => l_jtf_tasks_recur_int.attribute1
                ,p_attribute2                  => l_jtf_tasks_recur_int.attribute2
                ,p_attribute3                  => l_jtf_tasks_recur_int.attribute3
                ,p_attribute4                  => l_jtf_tasks_recur_int.attribute4
                ,p_attribute5                  => l_jtf_tasks_recur_int.attribute5
                ,p_attribute6                  => l_jtf_tasks_recur_int.attribute6
                ,p_attribute7                  => l_jtf_tasks_recur_int.attribute7
                ,p_attribute8                  => l_jtf_tasks_recur_int.attribute8
                ,p_attribute9                  => l_jtf_tasks_recur_int.attribute9
                ,p_attribute10                 => l_jtf_tasks_recur_int.attribute10
                ,p_attribute11                 => l_jtf_tasks_recur_int.attribute11
                ,p_attribute12                 => l_jtf_tasks_recur_int.attribute12
                ,p_attribute13                 => l_jtf_tasks_recur_int.attribute13
                ,p_attribute14                 => l_jtf_tasks_recur_int.attribute14
                ,p_attribute15                 => l_jtf_tasks_recur_int.task_recurr_orig_sys_ref
                ,p_attribute_category          => l_jtf_tasks_recur_int.attribute_category
                ,p_sunday                      => l_jtf_tasks_recur_int.sunday
                ,p_monday                      => l_jtf_tasks_recur_int.monday
                ,p_tuesday                     => l_jtf_tasks_recur_int.tuesday
                ,p_wednesday                   => l_jtf_tasks_recur_int.wednesday
                ,p_thursday                    => l_jtf_tasks_recur_int.thursday
                ,p_friday                      => l_jtf_tasks_recur_int.friday
                ,p_saturday                    => l_jtf_tasks_recur_int.saturday
            );

        x_tasks_recur_return_status   := lc_return_status;

        IF lc_return_status = 'S' THEN

            log_debug_msg('task recurrence successfully created !!!');

        ELSE
            log_debug_msg('task recurrence not created !!!');
            IF ln_msg_count >= 1 THEN
                FOR I IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||I||' . '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                    lc_msg_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE)||lc_msg_data;
                END LOOP;
            END IF;

            log_exception
            (
                p_conversion_id             => ln_task_recur_conv_id
               ,p_record_control_id         => l_jtf_tasks_recur_int.record_id
               ,p_source_system_code        => l_jtf_tasks_recur_int.task_recurr_orig_sys
               ,p_source_system_ref         => l_jtf_tasks_recur_int.task_recurr_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASK_RECURRENCES_PUB.CREATE_TASK_RECURRENCE'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_tasks_recur_int.batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_data
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;

    ELSIF ln_task_recur_id IS NOT NULL AND
          l_jtf_tasks_recur_int.insert_update_flag = 'U' THEN

        --------------------------------
        -- Update task recurrence
        --------------------------------

        log_debug_msg(CHR(10)||lc_procedure_name||': update a task recurrence');
        log_debug_msg('-------------------------------------');

        jtf_task_recurrences_pub.update_task_recurrence
            (
                 p_api_version                 => ln_api_version
                ,p_init_msg_list               => fnd_api.g_true
                ,p_commit                      => fnd_api.g_false
                ,p_task_id                     => ln_jtf_task_id
                ,p_recurrence_rule_id          => ln_task_recur_id
                ,p_occurs_which                => l_jtf_tasks_recur_int.occurs_which
                ,p_day_of_week                 => l_jtf_tasks_recur_int.day_of_week
                ,p_date_of_month               => l_jtf_tasks_recur_int.date_of_month
                ,p_occurs_month                => l_jtf_tasks_recur_int.occurs_month
                ,p_occurs_uom                  => l_jtf_tasks_recur_int.occurs_uom
                ,p_occurs_every                => l_jtf_tasks_recur_int.occurs_every
                ,p_occurs_number               => l_jtf_tasks_recur_int.occurs_number
                ,p_start_date_active           => l_jtf_tasks_recur_int.start_date_active
                ,p_end_date_active             => l_jtf_tasks_recur_int.end_date_active
                ,p_template_flag               => l_jtf_tasks_recur_int.template_flag
                ,p_attribute1                  => l_jtf_tasks_recur_int.attribute1
                ,p_attribute2                  => l_jtf_tasks_recur_int.attribute2
                ,p_attribute3                  => l_jtf_tasks_recur_int.attribute3
                ,p_attribute4                  => l_jtf_tasks_recur_int.attribute4
                ,p_attribute5                  => l_jtf_tasks_recur_int.attribute5
                ,p_attribute6                  => l_jtf_tasks_recur_int.attribute6
                ,p_attribute7                  => l_jtf_tasks_recur_int.attribute7
                ,p_attribute8                  => l_jtf_tasks_recur_int.attribute8
                ,p_attribute9                  => l_jtf_tasks_recur_int.attribute9
                ,p_attribute10                 => l_jtf_tasks_recur_int.attribute10
                ,p_attribute11                 => l_jtf_tasks_recur_int.attribute11
                ,p_attribute12                 => l_jtf_tasks_recur_int.attribute12
                ,p_attribute13                 => l_jtf_tasks_recur_int.attribute13
                ,p_attribute14                 => l_jtf_tasks_recur_int.attribute14
                ,p_attribute15                 => l_jtf_tasks_recur_int.task_recurr_orig_sys_ref
                ,p_attribute_category          => l_jtf_tasks_recur_int.attribute_category
                ,p_sunday                      => l_jtf_tasks_recur_int.sunday
                ,p_monday                      => l_jtf_tasks_recur_int.monday
                ,p_tuesday                     => l_jtf_tasks_recur_int.tuesday
                ,p_wednesday                   => l_jtf_tasks_recur_int.wednesday
                ,p_thursday                    => l_jtf_tasks_recur_int.thursday
                ,p_friday                      => l_jtf_tasks_recur_int.friday
                ,p_saturday                    => l_jtf_tasks_recur_int.saturday
                ,x_new_recurrence_rule_id      => ln_task_recurrence_id
                ,x_return_status               => lc_return_status
                ,x_msg_count                   => ln_msg_count
                ,x_msg_data                    => lc_msg_data
            );

        x_tasks_recur_return_status   := lc_return_status;

        IF lc_return_status = 'S' THEN

            log_debug_msg('task recurrence successfully updated !!!');

        ELSE
            log_debug_msg('task recurrence not updated !!!');
            IF ln_msg_count >= 1 THEN
                FOR I IN 1..ln_msg_count
                LOOP
                    log_debug_msg(CHR(10)||I||' . '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                    lc_msg_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE)||lc_msg_data;
                END LOOP;
            END IF;

            log_exception
            (
                p_conversion_id             => ln_task_recur_conv_id
               ,p_record_control_id         => l_jtf_tasks_recur_int.record_id
               ,p_source_system_code        => l_jtf_tasks_recur_int.task_recurr_orig_sys
               ,p_source_system_ref         => l_jtf_tasks_recur_int.task_recurr_orig_sys_ref
               ,p_procedure_name            => lc_procedure_name
               ,p_staging_table_name        => lc_staging_table_name
               ,p_staging_column_name       => 'JTF_TASK_RECURRENCES_PUB.UPDATE_TASK_RECURRENCE'
               ,p_staging_column_value      => 'RECORD_ID'
               ,p_batch_id                  => l_jtf_tasks_recur_int.batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => lc_msg_data
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END IF;

    END IF;

END create_task_recurrence;

-- +===================================================================+
-- | Name        : Get_task_recurrence_id                              |
-- |                                                                   |
-- | Description : Procedure used to get task_recurrence_id            |
-- |                                                                   |
-- | Parameters  : p_task_recur_orig_sys_ref                           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_recurrence_id
    (
         p_task_recur_orig_sys_ref    IN          VARCHAR2
        ,x_task_recur_id              OUT NOCOPY  NUMBER
        ,x_obj_ver_num                OUT NOCOPY  NUMBER
    )
AS

lc_msg_data        VARCHAR2(250)      :='Unexpeted Error';

BEGIN

    g_procedure_name              := 'Get_task_recurrence_id';
    g_staging_column_value        :=  p_task_recur_orig_sys_ref;
    g_staging_column_name         := 'TASK_RECURR_ORIG_SYS_REF';

    SELECT  recurrence_rule_id
           ,object_version_number
    INTO    x_task_recur_id
           ,x_obj_ver_num
    FROM    jtf_task_recur_rules
    WHERE   attribute15 = p_task_recur_orig_sys_ref;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_task_recur_id  := NULL;
        x_obj_ver_num    := NULL;
    WHEN OTHERS THEN
        x_task_recur_id  := NULL;
        x_obj_ver_num    := NULL;
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
END Get_task_recurrence_id;

-- +===================================================================+
-- | Name        : Get_task_dependency_id                              |
-- |                                                                   |
-- | Description : Procedure used to get task_dependency_id            |
-- |                                                                   |
-- | Parameters  : p_task_dpnd_orig_sys_ref                            |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_dependency_id
    (
         p_task_dpnd_orig_sys_ref     IN          VARCHAR2
        ,x_task_dpnd_id               OUT NOCOPY  NUMBER
        ,x_obj_ver_num                OUT NOCOPY  NUMBER
    )
AS

lc_msg_data        VARCHAR2(250)      := 'Unexpeted Error';

BEGIN

    g_procedure_name              := 'Get_task_dependency_id';
    g_staging_column_name         := 'TASK_DPND_ORIG_SYS_REF';
    g_staging_column_value        :=  p_task_dpnd_orig_sys_ref;

    SELECT  dependency_id
           ,object_version_number
    INTO    x_task_dpnd_id
           ,x_obj_ver_num
    FROM    jtf_task_depends
    WHERE   attribute15 = p_task_dpnd_orig_sys_ref;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_task_dpnd_id   := NULL;
        x_obj_ver_num    := NULL;
    WHEN OTHERS THEN
        x_task_dpnd_id   := NULL;
        x_obj_ver_num    := NULL;
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR   
            );
END  Get_task_dependency_id;

-- +===================================================================+
-- | Name        : Get_task_assignment_id                              |
-- |                                                                   |
-- | Description : Procedure used to get task_id                       |
-- |                                                                   |
-- | Parameters  : p_task_assign_orig_sys_ref                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_assignment_id
    (
         p_task_assign_orig_sys_ref   IN          VARCHAR2
        ,x_task_assign_id             OUT NOCOPY  NUMBER
        ,x_obj_ver_num                OUT NOCOPY  NUMBER
    )
AS

lc_msg_data        VARCHAR2(250)      := 'Unexpeted Error';

BEGIN

    g_procedure_name              := 'Get_task_assignment_id';
    g_staging_column_name         := 'TASK_ASSIGN_ORIG_SYS_REF';
    g_staging_column_value        :=  p_task_assign_orig_sys_ref;

    SELECT  task_assignment_id
           ,object_version_number
    INTO    x_task_assign_id
           ,x_obj_ver_num
    FROM    jtf_task_all_assignments
    WHERE   attribute15 = p_task_assign_orig_sys_ref;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_task_assign_id := NULL;
        x_obj_ver_num    := NULL;
    WHEN OTHERS THEN
        x_task_assign_id := NULL;
        x_obj_ver_num    := NULL;
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
END  Get_task_assignment_id;


-- +===================================================================+
-- | Name        : Get_assign_status_id                                |
-- |                                                                   |
-- | Description : Procedure used to retrieve the assignment_status_id |
-- |               from the task_status_name                           |
-- | Parameters  : p_assign_status_name                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_assign_status_id
    (
         p_assign_status_name       IN          VARCHAR2
        ,x_assign_status_id         OUT NOCOPY  NUMBER
    )
AS

lc_msg_data        VARCHAR2(250);

BEGIN

    g_procedure_name              := 'Get_assign_status_id';
    g_staging_column_name         := 'ASSIGNMENT_STATUS_NAME';
    g_staging_column_value        :=  p_assign_status_name;

    SELECT  task_status_id
    INTO    x_assign_status_id
    FROM    jtf_task_statuses_vl
    WHERE   name = p_assign_status_name
    AND     assignment_status_flag = 'Y';

EXCEPTION

    WHEN NO_DATA_FOUND THEN
        x_assign_status_id := NULL;
        lc_msg_data        := 'No status present with the Status Name : '||p_assign_status_name;
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
    WHEN OTHERS THEN
        x_assign_status_id := NULL;
        lc_msg_data        := 'Unexpected Error';
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
END  Get_assign_status_id;

-- +===================================================================+
-- | Name        : Get_task_reference_id                               |
-- |                                                                   |
-- | Description : Procedure used to get task_id                       |
-- |                                                                   |
-- | Parameters  : p_task_ref_orig_sys_ref                             |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_reference_id
    (
         p_task_ref_orig_sys_ref     IN          VARCHAR2
        ,x_task_ref_id               OUT NOCOPY  NUMBER
        ,x_obj_ver_num               OUT NOCOPY  NUMBER
    )
AS

lc_msg_data        VARCHAR2(250):= 'Unexpected Error';

BEGIN

    g_procedure_name              := 'Get_task_reference_id';
    g_staging_column_name         := 'TASK_REF_ORIG_SYS_REF';
    g_staging_column_value        :=  p_task_ref_orig_sys_ref;

    SELECT  task_reference_id
           ,object_version_number
    INTO    x_task_ref_id
           ,x_obj_ver_num
    FROM    jtf_task_references_b
    WHERE   attribute15 = p_task_ref_orig_sys_ref;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_task_ref_id := NULL;
        x_obj_ver_num := NULL;
    WHEN OTHERS THEN
        x_task_ref_id := NULL;
        x_obj_ver_num := NULL;
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
END  Get_task_reference_id;

-- +===================================================================+
-- | Name        : Get_object_id                                       |
-- | Description : Procedure used to get object_id for task reference  |
-- |                                                                   |
-- | Parameters  : p_object_type_code, p_object_orig_system_ref        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_object_id
    (
         p_object_type_code         IN          VARCHAR2
        ,p_object_orig_system_ref   IN          VARCHAR2
        ,x_object_name              OUT NOCOPY  VARCHAR2
        ,x_object_id                OUT NOCOPY  NUMBER
    )
AS

    ln_select_id                     jtf_objects_vl.select_id%TYPE;
    ln_select_name                   jtf_objects_vl.select_name%TYPE;
    ln_from_table                    jtf_objects_vl.from_table%TYPE;
    ln_where_clause                  jtf_objects_vl.where_clause%TYPE;
    sql_stmt                         VARCHAR2(2000);
    lc_procedure_name                VARCHAR2(2000):= 'Get_object_id';

    lc_msg_data        VARCHAR2(250) := 'Unexpected Error';

BEGIN

    g_procedure_name              := 'Get_object_id';
    g_staging_column_name         := 'OBJECT_TYPE_CODE';
    g_staging_column_value        :=  p_object_type_code;

    BEGIN
        SELECT  select_id
           ,select_name
               ,from_table
               ,where_clause
          INTO  ln_select_id
               ,ln_select_name
               ,ln_from_table
               ,ln_where_clause
           FROM jtf_objects_vl
          WHERE object_code = p_object_type_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            x_object_name := NULL;
            x_object_id   := NULL;
            lc_msg_data   := 'Improper object_type_code : '||p_object_type_code;
            log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        WHEN OTHERS THEN
            x_object_name := NULL;
            x_object_id   := NULL;
            lc_msg_data   := 'Unexpected Error'||SQLCODE ||', '||SQLERRM;
            log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
    END;

    SELECT DECODE (ln_where_clause, NULL, '  ', ln_where_clause || ' AND ')
    INTO ln_where_clause
    FROM dual;

    sql_stmt := ' SELECT ' ||
                ln_select_name ||
                ' , ' ||
                ln_select_id ||
                ' FROM ' ||
                ln_from_table ||
                '  WHERE ' ||
                ln_where_clause ||
                'ORIG_SYSTEM_REFERENCE' ||
                ' = ' ||
                ''''||
                p_object_orig_system_ref||
                '''';
    BEGIN
        EXECUTE IMMEDIATE sql_stmt INTO x_object_name, x_object_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            x_object_name := NULL;
            x_object_id   := NULL;
            lc_msg_data   := 'NO_DATA_FOUND in EXECUTE IMMEDIATE :'||SQLCODE ||', '||SQLERRM;
            log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        WHEN OTHERS THEN
            x_object_name := NULL;
            x_object_id   := NULL;
            lc_msg_data   := 'UNEXPECTED ERROR in EXECUTE IMMEDIATE :'||SQLCODE ||', '||SQLERRM;
            log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
    END;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_object_name := NULL;
        x_object_id   := NULL;
        lc_msg_data   :='WHEN NO_DATA_FOUND';
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
    WHEN OTHERS THEN
        x_object_name := NULL;
        x_object_id   := NULL;
        lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
END Get_object_id;

-- +===================================================================+
-- | Name        : Get_task_id                                         |
-- |                                                                   |
-- | Description : Procedure used to get task_id                       |
-- |                                                                   |
-- | Parameters  : p_task_orig_system_ref                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_id
    (
         p_task_orig_system_ref     IN          VARCHAR2
        ,x_task_id                  OUT NOCOPY  NUMBER
    )
AS

    lc_msg_data        VARCHAR2(250) := 'Unexpected Error';

BEGIN

    g_procedure_name              := 'Get_task_id';
    g_staging_column_name         := 'TASK_ORIG_SYSTEM_REF';
    g_staging_column_value        :=  p_task_orig_system_ref;

    SELECT  task_id
    INTO    x_task_id
    FROM    jtf_tasks_b
    WHERE   attribute15 = p_task_orig_system_ref;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_task_id := NULL;
    WHEN OTHERS THEN
        x_task_id := NULL;
        lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
END  Get_task_id;

-- +===================================================================+
-- | Name        : Get_task_type_id                                    |
-- |                                                                   |
-- | Description : Procedure used to retrieve the task_type_id from the|
-- |               task_type_name                                      |
-- | Parameters  : p_task_type_name                                    |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_type_id
    (
         p_task_type_name           IN          VARCHAR2
        ,x_task_type_id             OUT NOCOPY  NUMBER
    )
AS

    lc_msg_data        VARCHAR2(250);

BEGIN

    g_procedure_name              := 'Get_task_type_id';
    g_staging_column_name         := 'TASK_TYPE_NAME';
    g_staging_column_value        :=  p_task_type_name;

    SELECT  task_type_id
    INTO    x_task_type_id
    FROM    jtf_task_types_tl
    WHERE   name = p_task_type_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_task_type_id := NULL;
        lc_msg_data   :='Task Type Name : '||p_task_type_name||' not defined.';
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
    WHEN OTHERS THEN
        x_task_type_id := NULL;
        lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
END  Get_task_type_id;

-- +===================================================================+
-- | Name        : Get_task_status_id                                  |
-- |                                                                   |
-- | Description : Procedure used to retrieve the task_status_id from  |
-- |               the task_status_name                                |
-- | Parameters  : p_task_status_name                                  |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_status_id
    (
         p_task_status_name         IN          VARCHAR2
        ,x_task_status_id           OUT NOCOPY  NUMBER
    )
AS
    lc_msg_data        VARCHAR2(250);

BEGIN

    g_procedure_name              := 'Get_task_status_id';
    g_staging_column_name         := 'TASK_STATUS_NAME';
    g_staging_column_value        :=  p_task_status_name;

    SELECT  task_status_id
    INTO    x_task_status_id
    FROM    jtf_task_statuses_vl
    WHERE   name = p_task_status_name
    AND     task_status_flag = 'Y';

EXCEPTION

    WHEN NO_DATA_FOUND THEN
        x_task_status_id := NULL;
        lc_msg_data   :='Task Status Name : '||p_task_status_name||' not defined.';
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
    WHEN OTHERS THEN
        x_task_status_id := NULL;
        lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
END  Get_task_status_id;

-- +===================================================================+
-- | Name        : Get_task_priority_id                                |
-- |                                                                   |
-- | Description : Procedure used to retrieve the task_priority_id from|
-- |               the task_priority_name                              |
-- | Parameters  : p_task_priority_name                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_priority_id
    (
         p_task_priority_name         IN          VARCHAR2
        ,x_task_priority_id           OUT NOCOPY  NUMBER
    )
AS
    lc_msg_data        VARCHAR2(250);

BEGIN

    g_procedure_name              := 'Get_task_priority_id';
    g_staging_column_name         := 'TASK_PRIORITY_NAME';
    g_staging_column_value        :=  p_task_priority_name;

    SELECT  task_priority_id
    INTO    x_task_priority_id
    FROM    jtf_task_priorities_tl
    WHERE   name = p_task_priority_name;

EXCEPTION

    WHEN NO_DATA_FOUND THEN
        x_task_priority_id := NULL;
        lc_msg_data   :='Task Priority Name : '||p_task_priority_name||' not defined.';
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
    WHEN OTHERS THEN
        x_task_priority_id := NULL;
        lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
END  Get_task_priority_id;

-- +===================================================================+
-- | Name        : Get_customer_id                                     |
-- | Description : Procedure used to get customer_id                   |
-- |                                                                   |
-- | Parameters  : p_source_object_code,p_object_source_id             |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_customer_id
    (
         p_source_object_code            IN          VARCHAR2
        ,p_object_source_id              IN          NUMBER
        ,x_customer_id                   OUT NOCOPY  NUMBER
        ,x_address_id                    OUT NOCOPY  NUMBER
        ,x_account_id                    OUT NOCOPY  NUMBER
    )
AS
    lc_procedure_name   VARCHAR2(2000):= 'Get_customer_id';
    lc_msg_data         VARCHAR2(250);

BEGIN

    g_procedure_name              := 'Get_customer_id';
    g_staging_column_name         := 'SOURCE_OBJECT_CODE';
    g_staging_column_value        :=  p_source_object_code;

    x_customer_id := NULL;
    x_address_id  := NULL;
    x_account_id  := NULL;

    IF p_source_object_code = 'PARTY' THEN
        BEGIN
            SELECT  hps.party_id
                   ,hps.party_site_id
                   ,hca.cust_account_id
            INTO    x_customer_id
                   ,x_address_id
                   ,x_account_id
            FROM    hz_party_sites hps
                   ,hz_cust_accounts hca
            WHERE   hps.party_id = p_object_source_id
            AND     hps.party_id = hca.party_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
        WHEN TOO_MANY_ROWS THEN
            NULL;
        WHEN OTHERS THEN
            lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
            log_debug_msg(lc_procedure_name||lc_msg_data);
            log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END;

    ELSIF p_source_object_code = 'OD_PARTY_SITE' THEN
        BEGIN
            SELECT  hps.party_id
                   ,hps.party_site_id
                   ,hca.cust_account_id
            INTO    x_customer_id
                   ,x_address_id
                   ,x_account_id
            FROM    hz_party_sites hps
                   ,hz_cust_accounts hca
            WHERE   hps.party_site_id = p_object_source_id
            AND     hps.party_id      = hca.party_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
        WHEN TOO_MANY_ROWS THEN
            NULL;
        WHEN OTHERS THEN
            lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
            log_debug_msg(lc_procedure_name||lc_msg_data);
            log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END;

    ELSIF p_source_object_code = 'LEAD' THEN
        BEGIN
            SELECT  asl.customer_id
                   ,asl.address_id
                   ,hca.cust_account_id
            INTO    x_customer_id
                   ,x_address_id
                   ,x_account_id
            FROM    as_sales_leads asl
                   ,hz_cust_accounts hca
            WHERE   asl.sales_lead_id = p_object_source_id
            AND     asl.customer_id   = hca.party_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
        WHEN TOO_MANY_ROWS THEN
            NULL;
        WHEN OTHERS THEN
            lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
            log_debug_msg(lc_procedure_name||lc_msg_data);
            log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END;

    ELSIF p_source_object_code = 'OPPORTUNITY' THEN
        BEGIN
            SELECT  ala.customer_id
                   ,ala.address_id
                   ,hca.cust_account_id
            INTO    x_customer_id
                   ,x_address_id
                   ,x_account_id
            FROM    as_leads_all  ala
                   ,hz_cust_accounts hca
            WHERE   ala.lead_id       = p_object_source_id
            AND     ala.customer_id   = hca.party_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
        WHEN TOO_MANY_ROWS THEN
            NULL;
        WHEN OTHERS THEN
            lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
            log_debug_msg(lc_procedure_name||lc_msg_data);
            log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                  
            );
        END;
    END IF;
END Get_customer_id;

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
         p_source_object_code               IN          VARCHAR2
        ,p_source_object_orig_sys_ref       IN          VARCHAR2
        ,p_source_object_orig_sys           IN          VARCHAR2
        ,x_object_source_id                 OUT NOCOPY  NUMBER
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

---- Cursor to fetch task_id
--CURSOR  c_task_id
--    (
--        cp_source_object_orig_sys_ref   VARCHAR2
--    )
--IS
--SELECT  task_id
--FROM    jtf_tasks_b
--WHERE   orig_system_reference = p_source_object_orig_sys_ref;

BEGIN

        x_object_source_id := NULL;
        IF p_source_object_code = 'PARTY' THEN


            OPEN    c_party_id (p_source_object_orig_sys_ref,p_source_object_orig_sys);
            FETCH   c_party_id into  x_object_source_id;
            CLOSE   c_party_id;

            IF  x_object_source_id IS NULL THEN
                log_debug_msg(lc_procedure_name||': party_id not found, invalid source_object_orig_system_ref '||p_source_object_orig_sys_ref);
            END IF;

        ELSIF p_source_object_code = 'OD_PARTY_SITE' THEN

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

--        ELSIF p_source_object_code = 'TASK' THEN
--
--            OPEN    c_task_id (p_source_object_orig_sys_ref);
--            FETCH   c_task_id into  x_object_source_id;
--            CLOSE   c_task_id;
--
--            IF  x_object_source_id IS null THEN
--                log_debug_msg(lc_procedure_name||': task_id (TASK) not found, invalid source_object_orig_system_ref '||p_source_object_orig_sys_ref);
--            END IF;

        END IF;

END Get_object_source_id;

-- +===================================================================+
-- | Name        : Get_timezone_id                                     |
-- |                                                                   |
-- | Description : Procedure used to retrieve the timezone_id from     |
-- |               timezone_name                                       |
-- | Parameters  : p_timezone_name                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_timezone_id
    (
          p_timezone_name                IN          VARCHAR2
         ,x_timezone_id                  OUT NOCOPY  NUMBER
    )
AS

    lc_msg_data         VARCHAR2(250);

BEGIN

    g_procedure_name              := 'Get_timezone_id';
    g_staging_column_name         := 'TIMEZONE_NAME';
    g_staging_column_value        :=  p_timezone_name;

    SELECT timezone_id
    INTO x_timezone_id
    FROM hz_timezones_vl
    WHERE name = p_timezone_name;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_timezone_id := NULL;
            lc_msg_data   :='Timezone Name : '||p_timezone_name||' not defined.';
            log_debug_msg(g_procedure_name||lc_msg_data);
            log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR   
            );
    WHEN OTHERS THEN
        x_timezone_id := NULL;
            lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
            log_debug_msg(g_procedure_name||lc_msg_data);
            log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                 
            );
END Get_timezone_id;


-- +===================================================================+
-- | Name        : Get_resource_id                                     |
-- |                                                                   |
-- | Description : Procedure used to retrieve the resource_id of the   |
-- |               Owner/Assignee of a Task                            |
-- | Parameters  : p_resource_orig_system_ref                          |
-- |                                                                   |
-- +===================================================================+

PROCEDURE Get_resource_id
     (
          p_resource_orig_system_ref        IN          VARCHAR2
         ,x_resource_id                     OUT NOCOPY  NUMBER
         ,x_user_id                             OUT NOCOPY  NUMBER
         ,x_own_type_code                   OUT NOCOPY VARCHAR2
     )
AS

    lc_msg_data         VARCHAR2(250);

BEGIN

    g_procedure_name              := 'Get_resource_id';
    g_staging_column_name         := 'RESOURCE_ORIG_SYSTEM_REF';
    g_staging_column_value        :=  p_resource_orig_system_ref;

    SELECT jrre.resource_id
          ,jrre.user_id
          ,(SELECT object_code
            FROM jtf_objects_b jbb
            WHERE jbb.object_code = 'RS_'||jrre.category)
    INTO   x_resource_id
          ,x_user_id
          ,x_own_type_code
    FROM   jtf_rs_roles_b jrrb
          ,jtf_rs_role_relations jrrr
          ,jtf_rs_resource_extns jrre
    WHERE jrrb.role_id = jrrr.role_id
    AND   jrre.resource_id = jrrr.role_resource_id
    and   trunc(sysdate) between jrrr.start_date_active and nvl( jrrr.end_date_active,trunc(sysdate))
    and   nvl( jrrr.delete_flag,'N') ='N'
    AND   jrrr.attribute15 = p_resource_orig_system_ref;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_resource_id := NULL;
        lc_msg_data   :='No resource present with resource_orig_system_ref : '||p_resource_orig_system_ref;
        log_debug_msg(g_procedure_name||lc_msg_data);
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                 
            );
    WHEN OTHERS THEN
        x_resource_id := NULL;
        lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
        log_debug_msg(g_procedure_name||lc_msg_data);
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR  
            );
            
END Get_resource_id;




-- +===================================================================+
-- | Name        : Get_task_obj_ver_num                                |
-- | Description : Procedure used to get the object_version_number for |
-- |               task                                                |
-- |                                                                   |
-- | Parameters  : p_task_id                                           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_obj_ver_num
    (
        p_task_id               IN          VARCHAR2
       ,x_obj_ver_num           OUT NOCOPY  NUMBER
    )

AS
    lc_msg_data         VARCHAR2(250);

BEGIN

    g_procedure_name              := 'Get_task_obj_ver_num';
    g_staging_column_name         := 'TASK_ID';
    g_staging_column_value        :=  p_task_id;

    x_obj_ver_num := NULL;

    SELECT  object_version_number
    INTO    x_obj_ver_num
    FROM    jtf_tasks_b
    WHERE   task_id = p_task_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_obj_ver_num := NULL;
        lc_msg_data   :='No task present with TASK_ID : '||p_task_id;
        log_debug_msg(g_procedure_name||lc_msg_data);
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR  
            );
    WHEN OTHERS THEN
        x_obj_ver_num := NULL;
        lc_msg_data   :='Unexpected Error'||SQLCODE ||', '||SQLERRM;
        log_debug_msg(g_procedure_name||lc_msg_data);
        log_exception
            (
                p_conversion_id             => g_conv_id
               ,p_record_control_id         => g_record_control_id
               ,p_source_system_code        => g_source_system_code
               ,p_source_system_ref         => g_orig_sys_ref
               ,p_procedure_name            => g_procedure_name
               ,p_staging_table_name        => g_staging_table_name
               ,p_staging_column_name       => g_staging_column_name
               ,p_staging_column_value      => g_staging_column_value
               ,p_batch_id                  => g_batch_id
               ,p_exception_log             => lc_msg_data
               ,p_oracle_error_code         => SQLCODE
               ,p_oracle_error_msg          => SQLERRM
               ,p_msg_severity              => 'MAJOR'  -- MAJOR, MEDIUM, MINOR                 
            );
END Get_task_obj_ver_num;

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

    fnd_file.put_line(fnd_file.log,p_debug_msg);

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
        ,p_msg_severity           IN VARCHAR2
    )
AS
lc_package_name  VARCHAR2(32) := 'XX_JTF_TASKS_PKG';
l_return_code    VARCHAR2(1)  := 'E';
l_msg_count      NUMBER       := 1;
BEGIN
        
    XX_COM_ERROR_LOG_PUB.LOG_ERROR_CRM
        (
             P_RETURN_CODE             =>  l_RETURN_CODE
            ,P_MSG_COUNT               =>  l_MSG_COUNT
            ,P_APPLICATION_NAME        => 'XXCRM'        
            ,P_PROGRAM_TYPE            => 'I0801_Load_CDH_Tasks_To_CV'        
            ,P_PROGRAM_NAME            => 'XX_JTF_TASKS_PKG'
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
            ,P_ATTRIBUTE15             =>  p_batch_id -- Inluded Batch id --Apr 04 2008
        );
        
EXCEPTION
    WHEN OTHERS THEN
        log_debug_msg('LOG_EXCEPTION: Error in logging exception :'||SQLERRM);
END log_exception;
END XX_JTF_TASKS_PKG;
/
SHOW ERRORS;