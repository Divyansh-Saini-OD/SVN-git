create or replace PACKAGE BODY      xx_ar_arcs_sl_extract_pkg
-- +============================================================================================+
-- |                      Office Depot - Project Simplify                                       |
-- +============================================================================================+
-- |  Name              :  XX_AR_ARCS_SL_EXTRACT_PKG                                            |
-- |  Description       :  R7043 Package to extract AR Subledger Accounting Information         |
-- |  Change Record     :                                                                       |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         012918       Dinesh Nagapuri  Initial version                                  |
-- | 2.0         05/24/2018   Havish Kasina    Modified the enabled Flag from 'y' to 'Y'        |
-- | 3.0         05/24/2018   Havish Kasina    Added Hints to the subledger_extract_cur cursor  |
-- | 4.0         01/24/2019   BIAS             INSTANCE_NAME is replaced with DB_NAME for OCI   |
-- |                                           Migration                                        |
-- +============================================================================================+
AS
    gc_debug       VARCHAR2(2)                                 := 'N';
    gn_request_id  fnd_concurrent_requests.request_id%TYPE;
    gn_user_id     fnd_concurrent_requests.requested_by%TYPE;
    gn_login_id    NUMBER;

    /*********************************************************************
    * Procedure used to log based on gb_debug value or if p_force is TRUE.
    * Will log to dbms_output if request id is not set,
    * else will log to concurrent program log file.  Will prepend
    * time stamp to each message logged.  This is useful for determining
    * elapse times.
    *********************************************************************/
    PROCEDURE print_debug_msg(
        p_message  IN  VARCHAR2,
        p_force    IN  BOOLEAN DEFAULT FALSE)
    IS
        lc_message  VARCHAR2(4000) := NULL;
    BEGIN
        IF (   gc_debug = 'Y'
            OR p_force)
        THEN
            lc_message := p_message;
            fnd_file.put_line(fnd_file.LOG,
                              lc_message);

            IF (   fnd_global.conc_request_id = 0
                OR fnd_global.conc_request_id = -1)
            THEN
                DBMS_OUTPUT.put_line(lc_message);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END print_debug_msg;

    /*********************************************************************
    * Procedure used to out the text to the concurrent program.
    * Will log to dbms_output if request id is not set,
    * else will log to concurrent program output file.
    *********************************************************************/
    PROCEDURE print_out_msg(
        p_message  IN  VARCHAR2)
    IS
        lc_message  VARCHAR2(4000) := NULL;
    BEGIN
        lc_message := p_message;
        fnd_file.put_line(fnd_file.output,
                          lc_message);

        IF (   fnd_global.conc_request_id = 0
            OR fnd_global.conc_request_id = -1)
        THEN
            DBMS_OUTPUT.put_line(lc_message);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END print_out_msg;

-- +======================================================================+
-- | Name        :  subledger_arcs_extract                                |
-- | Description :  This procedure will be called from the concurrent prog|
-- |                "OD : AR ARCS Subledger Extract" to extract AR        |
-- |                Subledger Accounting Information                      |
-- |                                                                      |
-- | Parameters  :  Period Name, Debug Flag                               |
-- |                                                                      |
-- | Returns     :  x_errbuf, x_retcode                                   |
-- |                                                                      |
-- +======================================================================+
    PROCEDURE subledger_arcs_extract(
        p_errbuf       OUT     VARCHAR2,
        p_retcode      OUT     VARCHAR2,
        p_period_name  IN      VARCHAR2,
        p_debug        IN      VARCHAR2)
    AS
        CURSOR subledger_extract_cur(
            p_period_name  VARCHAR2,
            p_start_date   DATE,
            p_end_date     DATE)
        IS
            SELECT  /*+ full(gllookups.lv) full(gp) full(gb) full(gld) full(gcc) full(glcd) full(xll) */
			         gcc.segment1 company,
                     gcc.segment2 cost_center,
                     gcc.segment3 ACCOUNT,
                     gcc.segment4 LOCATION,
                     gcc.segment5 intercompany,
                     gcc.segment6 line_of_business,
                     gcc.segment7 future,
                       NVL(gb.begin_balance_dr,
                           0)
                     - NVL(gb.begin_balance_cr,
                           0) ytd_beginning_bal,
                     SUM(NVL(xll.accounted_dr,
                             0) ) ptd_net_dr,
                     SUM(NVL(xll.accounted_cr,
                             0) ) ptd_net_cr,
                       NVL(gb.begin_balance_dr,
                           0)
                     - NVL(gb.begin_balance_cr,
                           0)
                     + SUM(NVL(xll.accounted_dr,
                               0) )
                     - SUM(NVL(xll.accounted_cr,
                               0) ) ytd_balance,
                     xll.currency_code,
                     xll.ledger_id,
                     gb.period_name,
                     gcc.code_combination_id,
                     gb.actual_flag balance_type,
                     (SELECT REPLACE(fvv.description,
                                     ',',
                                     '_')
                      FROM   fnd_flex_value_sets fvs, fnd_flex_values_vl fvv
                      WHERE  flex_value_set_name = 'OD_GL_GLOBAL_ACCOUNT'
                      AND    fvs.flex_value_set_id = fvv.flex_value_set_id
                      AND    fvv.flex_value = gcc.segment3) account_description
            FROM     xla_ae_lines xll,
                     gl_code_combinations gcc,
                     gl_ledgers gld,
                     gl_balances gb,
                     gl_ledger_config_details glcd,
                     gl_lookups gllookups
            WHERE    1 = 1
            AND      xll.code_combination_id = gcc.code_combination_id
            AND      xll.application_id = 222
            AND      xll.ledger_id = gld.ledger_id
            AND      gcc.segment3 IN(
                         SELECT vals.target_value1
                         FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
                         WHERE  defn.translate_id = vals.translate_id
                         AND    defn.translation_name = 'ARCS_AR_EXRACT_ACCOUNTS'
                         AND    SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,
                                                                                 SYSDATE
                                                                               + 1)
                         AND    SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active,
                                                                                 SYSDATE
                                                                               + 1)
                         AND    vals.enabled_flag = 'Y'
                         AND    defn.enabled_flag = 'Y')
            AND      xll.currency_code = gld.currency_code
            AND      xll.accounting_date >= p_start_date
            AND      xll.accounting_date <= p_end_date
            AND      gcc.code_combination_id = gb.code_combination_id
            AND      gb.actual_flag = 'A'
            AND      gb.period_name = p_period_name
            AND      gb.template_id IS NULL
            AND      gb.ledger_id = gld.ledger_id
            AND      gld.currency_code = gb.currency_code
            AND      gld.configuration_id = glcd.configuration_id
            AND      glcd.object_type_code = 'PRIMARY'
            AND      glcd.setup_step_code = 'NONE'
            AND      gllookups.lookup_type = 'GL_ASF_LEDGER_CATEGORY'
            AND      gllookups.lookup_code = gld.ledger_category_code
            AND      gcc.account_type IN('A', 'L', 'O')
            AND      EXISTS(
                         SELECT /*+ full(fvs) full(fvv.t) full(fvv.b) */ 1
                         FROM   fnd_flex_value_sets fvs, fnd_flex_values_vl fvv
                         WHERE  flex_value_set_name = 'OD_GL_GLOBAL_COMPANY'
                         AND    fvs.flex_value_set_id = fvv.flex_value_set_id
                         AND    fvv.flex_value = gcc.segment1
                         AND    fvv.enabled_flag = 'Y'
                         AND    NVL(fvv.start_date_active,
                                    SYSDATE) <= SYSDATE
                         AND    NVL(fvv.end_date_active,
                                    SYSDATE) >= SYSDATE)
            GROUP BY gcc.segment1,
                     gcc.segment2,
                     gcc.segment3,
                     gcc.segment4,
                     gcc.segment5,
                     gcc.segment6,
                     gcc.segment7,
                     gcc.segment8,
                       NVL(gb.begin_balance_dr,
                           0)
                     - NVL(gb.begin_balance_cr,
                           0),
                     xll.ledger_id,
                     xll.currency_code,
                     gb.period_name,
                     gcc.code_combination_id,
                     gb.actual_flag,
                     gld.NAME,
                     gllookups.meaning,
                     glcd.object_name
            UNION ALL
            SELECT   gcc.segment1 company,
                     gcc.segment2 cost_center,
                     gcc.segment3 ACCOUNT,
                     gcc.segment4 LOCATION,
                     gcc.segment5 intercompany,
                     gcc.segment6 line_of_business,
                     gcc.segment7 future,
                       NVL(gb.begin_balance_dr,
                           0)
                     - NVL(gb.begin_balance_cr,
                           0) ytd_beginning_bal,
                     0 ptd_net_dr,
                     0 ptd_net_cr,
                       NVL(gb.begin_balance_dr,
                           0)
                     - NVL(gb.begin_balance_cr,
                           0) ytd_balance,
                     gld.currency_code,
                     gld.ledger_id,
                     gb.period_name,
                     gcc.code_combination_id,
                     gb.actual_flag balance_type,
                     (SELECT fvv.description
                      FROM   fnd_flex_value_sets fvs, fnd_flex_values_vl fvv
                      WHERE  flex_value_set_name = 'OD_GL_GLOBAL_ACCOUNT'
                      AND    fvs.flex_value_set_id = fvv.flex_value_set_id
                      AND    fvv.flex_value = gcc.segment3) account_description
            FROM     gl_code_combinations gcc,
                     gl_ledgers gld,
                     gl_balances gb,
                     gl_ledger_config_details glcd,
                     gl_lookups gllookups,
                     gl_periods gp
            WHERE    1 = 1
            AND      gcc.code_combination_id = gb.code_combination_id
            AND      gld.configuration_id = glcd.configuration_id
            AND      gllookups.lookup_code = gld.ledger_category_code
            AND      glcd.object_type_code = 'PRIMARY'
            AND      glcd.setup_step_code = 'NONE'
            AND      gllookups.lookup_type = 'GL_ASF_LEDGER_CATEGORY'
            AND      gb.actual_flag = 'A'
            AND      gb.template_id IS NULL
            AND      gb.period_name = p_period_name
            AND      gb.period_name = gp.period_name
            AND      gb.ledger_id = gld.ledger_id
            AND      gld.currency_code = gb.currency_code
            AND        NVL(gb.begin_balance_dr,
                           0)
                     - NVL(gb.begin_balance_cr,
                           0) <> 0
            AND      gcc.segment3 IN(
                         SELECT vals.target_value1
                         FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
                         WHERE  defn.translate_id = vals.translate_id
                         AND    defn.translation_name = 'ARCS_AR_EXRACT_ACCOUNTS'
                         AND    SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,
                                                                                 SYSDATE
                                                                               + 1)
                         AND    SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active,
                                                                                 SYSDATE
                                                                               + 1)
                         AND    vals.enabled_flag = 'Y'
                         AND    defn.enabled_flag = 'Y')
            AND      NOT EXISTS(
                         SELECT 1
                         FROM   xla_ae_lines xll
                         WHERE  1 = 1
                         AND    gcc.code_combination_id = xll.code_combination_id
                         AND    xll.accounting_date >= p_start_date
                         AND    xll.accounting_date <= p_end_date
                         AND    xll.application_id = 222)
            AND      gcc.account_type IN('A', 'L', 'O')
            AND      EXISTS(
                         SELECT 1
                         FROM   fnd_flex_value_sets fvs, fnd_flex_values_vl fvv
                         WHERE  flex_value_set_name = 'OD_GL_GLOBAL_COMPANY'
                         AND    fvs.flex_value_set_id = fvv.flex_value_set_id
                         AND    fvv.flex_value = gcc.segment1
                         AND    fvv.enabled_flag = 'Y'
                         AND    NVL(fvv.start_date_active,
                                    SYSDATE) <= SYSDATE
                         AND    NVL(fvv.end_date_active,
                                    SYSDATE) >= SYSDATE)
            GROUP BY gcc.segment1,
                     gcc.segment2,
                     gcc.segment3,
                     gcc.segment4,
                     gcc.segment5,
                     gcc.segment6,
                     gcc.segment7,
                     gcc.segment8,
                     gcc.description,
                       NVL(gb.begin_balance_dr,
                           0)
                     - NVL(gb.begin_balance_cr,
                           0),
                     gld.ledger_id,
                     gld.currency_code,
                     gb.period_name,
                     gcc.code_combination_id,
                     gb.actual_flag;

        TYPE subledger_extract_tab_type IS TABLE OF subledger_extract_cur%ROWTYPE;

        CURSOR get_dir_path
        IS
            SELECT directory_path
            FROM   dba_directories
            WHERE  directory_name = 'XXFIN_OUTBOUND';

        l_subledger_extract_tab       subledger_extract_tab_type;
        lf_arcs_file                  UTL_FILE.file_type;
        lc_arcs_file_header           VARCHAR2(32000);
        lc_arcs_file_content          VARCHAR2(32000);
        ln_chunk_size                 BINARY_INTEGER             := 32767;
        lc_arcs_file_name             VARCHAR2(250)              := 'ARCS_AR_';
        lc_dest_file_name             VARCHAR2(200);
        ln_conc_file_copy_request_id  NUMBER;
        lc_dirpath                    VARCHAR2(500);
        lc_file_name_instance         VARCHAR2(250);
        lc_instance_name              VARCHAR2(30);
        lb_complete                   BOOLEAN;
        lc_phase                      VARCHAR2(100);
        lc_status                     VARCHAR2(100);
        lc_dev_phase                  VARCHAR2(100);
        lc_dev_status                 VARCHAR2(100);
        lc_message                    VARCHAR2(100);
        lc_delimeter                  VARCHAR2(1)                := ',';
        p_start_date                  DATE;
        p_end_date                    DATE;
        lc_error_msg                  VARCHAR2(2000)             := NULL;
        data_exception                EXCEPTION;
        lc_file_handle                UTL_FILE.file_type;
    BEGIN
        xla_security_pkg.set_security_context(602);
        gc_debug := p_debug;
        gn_request_id := fnd_global.conc_request_id;
        gn_user_id := fnd_global.user_id;
        gn_login_id := fnd_global.login_id;
		print_debug_msg('Begin - subledger_arcs_extract',
                        TRUE);
        print_out_msg(   'Processing Arcs Subledger Extract for Period End :'
                      || p_period_name);
        print_out_msg(   'Concurrent Request is : '
                      || gn_request_id);

        IF p_period_name IS NULL
        THEN
            print_debug_msg('Period Name is Mandatory',
                            TRUE);
            lc_error_msg := 'Period Name is Mandatory';
            RAISE data_exception;
        END IF;

        --get file dir path
        OPEN get_dir_path;

        FETCH get_dir_path
        INTO  lc_dirpath;

        CLOSE get_dir_path;

        SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV',
                                        'DB_NAME') ),
                      1,
                      8)
        INTO   lc_instance_name
        FROM   DUAL;

        lc_arcs_file_name :=    lc_arcs_file_name
                             || p_period_name
                             || '.txt';
        print_out_msg(   'Extracting Data into file :'
                      || lc_arcs_file_name);
        print_debug_msg(   'Extracting Data into file :'
                        || lc_arcs_file_name,
                        TRUE);

        SELECT NAME
        INTO   lc_file_name_instance
        FROM   v$database;

        BEGIN
            SELECT TO_DATE(TO_CHAR(start_date,
                                   'mm/dd/yyyy'),
                           'mm/dd/yyyy') period_start_date,
                   TO_DATE(TO_CHAR(end_date,
                                   'mm/dd/yyyy'),
                           'mm/dd/yyyy') period_end_date
            INTO   p_start_date,
                   p_end_date
            FROM   gl_periods
            WHERE  1 = 1
            AND    period_name = p_period_name;
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_error_msg :=
                    (   'Exception Raised while getting start date and end date for Period '
                     || p_period_name
                     || SUBSTR(SQLERRM,
                               1,
                               3800)
                     || SQLCODE);
                print_debug_msg(lc_error_msg,
                                TRUE);
        END;

        OPEN subledger_extract_cur(p_period_name,
                                   p_start_date,
                                   p_end_date);

        FETCH subledger_extract_cur
        BULK COLLECT INTO l_subledger_extract_tab;

        CLOSE subledger_extract_cur;

        print_debug_msg(   'Subledger Extract Count :'
                        || l_subledger_extract_tab.COUNT,
                        TRUE);
        print_out_msg(   'Subledger Extract Count :'
                      || l_subledger_extract_tab.COUNT);

        IF l_subledger_extract_tab.COUNT > 0
        THEN
            BEGIN
                lf_arcs_file := UTL_FILE.fopen('XXFIN_OUTBOUND',
                                               lc_arcs_file_name,
                                               'w',
                                               ln_chunk_size);
                lc_arcs_file_header :=
                       'COMPANY'
                    || lc_delimeter
                    || 'COST_CENTER'
                    || lc_delimeter
                    || 'ACCOUNT'
                    || lc_delimeter
                    || 'LOCATION'
                    || lc_delimeter
                    || 'INTERCOMPANY'
                    || lc_delimeter
                    || 'LOB'
                    || lc_delimeter
                    || 'Future'
                    || lc_delimeter
                    || 'YTD_BEGINNING_BAL'
                    || lc_delimeter
                    || 'PTD_NET_DR'
                    || lc_delimeter
                    || 'PTD_NET_CR'
                    || lc_delimeter
                    || 'YTD_Balance'
                    || lc_delimeter
                    || 'CURRENCY_CODE'
                    || lc_delimeter
                    || 'LEDGER_ID'
                    || lc_delimeter
                    || 'PERIOD_NAME'
                    || lc_delimeter
                    || 'CODE_COMBINATION_ID'
                    || lc_delimeter
                    || 'BALANCE_TYPE'
                    || lc_delimeter
                    || 'Account Description';
                UTL_FILE.put_line(lf_arcs_file,
                                  lc_arcs_file_header);

                FOR i IN 1 .. l_subledger_extract_tab.COUNT
                LOOP
                    lc_arcs_file_content :=
                           l_subledger_extract_tab(i).company
                        || lc_delimeter
                        || l_subledger_extract_tab(i).cost_center
                        || lc_delimeter
                        || l_subledger_extract_tab(i).ACCOUNT
                        || lc_delimeter
                        || l_subledger_extract_tab(i).LOCATION
                        || lc_delimeter
                        || l_subledger_extract_tab(i).intercompany
                        || lc_delimeter
                        || l_subledger_extract_tab(i).line_of_business
                        || lc_delimeter
                        || l_subledger_extract_tab(i).future
                        || lc_delimeter
                        || l_subledger_extract_tab(i).ytd_beginning_bal
                        || lc_delimeter
                        || l_subledger_extract_tab(i).ptd_net_dr
                        || lc_delimeter
                        || l_subledger_extract_tab(i).ptd_net_cr
                        || lc_delimeter
                        || l_subledger_extract_tab(i).ytd_balance
                        || lc_delimeter
                        || l_subledger_extract_tab(i).currency_code
                        || lc_delimeter
                        || l_subledger_extract_tab(i).ledger_id
                        || lc_delimeter
                        || l_subledger_extract_tab(i).period_name
                        || lc_delimeter
                        || l_subledger_extract_tab(i).code_combination_id
                        || lc_delimeter
                        || l_subledger_extract_tab(i).balance_type
                        || lc_delimeter
                        || l_subledger_extract_tab(i).account_description;
                    UTL_FILE.put_line(lf_arcs_file,
                                      lc_arcs_file_content);
                END LOOP;

                UTL_FILE.fclose(lf_arcs_file);
                print_out_msg(   'Matched Invoice File Created: '
                              || lc_arcs_file_name);
                print_debug_msg(   'Matched Invoice File Created: '
                                || lc_arcs_file_name);
                -- copy to matched invoice file to xxfin_data/ARCS dir
                lc_dest_file_name :=    '/app/ebs/ct'
                                     || lc_instance_name
                                     || '/xxfin/ftp/out/ARCS/'
                                     || lc_arcs_file_name;
                ln_conc_file_copy_request_id :=
                    fnd_request.submit_request('XXFIN',
                                               'XXCOMFILCOPY',
                                               '',
                                               '',
                                               FALSE,
                                                  lc_dirpath
                                               || '/'
                                               || lc_arcs_file_name,   --Source File Name
                                               lc_dest_file_name,   --Dest File Name
                                               '',
                                               '',
                                               'Y'   --Deleting the Source File
                                                  );

                IF ln_conc_file_copy_request_id > 0
                THEN
                    COMMIT;
                    -- wait for request to finish
                    lb_complete :=
                        fnd_concurrent.wait_for_request(request_id =>      ln_conc_file_copy_request_id,
                                                        INTERVAL =>        10,
                                                        max_wait =>        0,
                                                        phase =>           lc_phase,
                                                        status =>          lc_status,
                                                        dev_phase =>       lc_dev_phase,
                                                        dev_status =>      lc_dev_status,
                                                        MESSAGE =>         lc_message);
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         SQLCODE
                                      || SQLERRM);
            END;
        END IF;

        print_debug_msg('End - subledger_arcs_extract',
                        TRUE);
    EXCEPTION
        WHEN data_exception
        THEN
            p_retcode := 2;
            p_errbuf := lc_error_msg;
        WHEN UTL_FILE.access_denied
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' access_denied :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.delete_failed
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' delete_failed :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.file_open
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' file_open :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.internal_error
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' internal_error :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_filehandle
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' invalid_filehandle :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_filename
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' invalid_filename :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_maxlinesize
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' invalid_maxlinesize :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_mode
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' invalid_mode :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_offset
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' invalid_offset :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_operation
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' invalid_operation :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_path
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' invalid_path :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.read_error
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' read_error :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.rename_failed
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' rename_failed :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.write_error
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' write_error :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN OTHERS
        THEN
            lc_error_msg :=
                (   'GL Balances Outbound Report Generation Errored :- '
                 || ' OTHERS :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(   'End - populate_gl_out_file - '
                            || lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_arcs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
    END subledger_arcs_extract;
END xx_ar_arcs_sl_extract_pkg;
/
SHOW ERRORS;