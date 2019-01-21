SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_cn_retro_asgn_pkg

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_CN_RETRO_ASGN_PKG.pkb                                   |
-- | Rice ID     : I1005_RetroAssignmentChanges                               |
-- | Description : Custom Package that contains all the utility functions and |
-- |               procedures required to do Retro Assignments                |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |Draft 1a 17-Oct-2007 Vidhya Valantina T     Initial draft version         |
-- |1.0      23-Oct-2007 Vidhya Valantina T     Baselined after review        |
-- |1.1      13-Nov-2007 Vidhya Valantina T     Changes due to Error Logging  |
-- |                                            Standards                     |
-- |                                                                          |
-- +==========================================================================+

AS

-- --------------------
-- Function Definitions
-- --------------------

    -- +===================================================================+
    -- | Name        : Ins_Site_Reqs                                       |
    -- | Description : Function to insert Records into XX_CN_SITE_REQUESTS |
    -- |               Custom Table                                        |
    -- |                                                                   |
    -- | Parameters  : Sales_Rep_Asgn_Tbl    PL/SQL Table of Records       |
    -- |               Commit_Flag           Commit Flag                   |
    -- |                                                                   |
    -- | Returns     : Insert Status                                       |
    -- |                                                                   |
    -- +===================================================================+

    FUNCTION ins_site_reqs ( p_site_requests_rec gcu_site_requests%ROWTYPE
                            ,p_commit_flag       IN BOOLEAN  DEFAULT FALSE )
    RETURN BOOLEAN
    IS

        lb_ins_status        BOOLEAN;

        lc_message_data      VARCHAR2 (4000);

        ld_sysdate           DATE         := SYSDATE;

        ln_appln_id          NUMBER       := FND_PROFILE.Value('RESP_APPL_ID');
        ln_login             NUMBER       := FND_GLOBAL.Login_Id;
        ln_message_code      NUMBER;
        ln_req_id            NUMBER       := FND_GLOBAL.Conc_Request_Id;
        ln_site_requests_id  NUMBER;
        ln_user_id           NUMBER       := FND_GLOBAL.User_Id;

        --
        -- Cursor to Get Primary Key Sequence
        --
        CURSOR lcu_site_requests_id
        IS
        SELECT xx_cn_site_requests_s.NEXTVAL site_requests_id
        FROM   SYS.dual;

    BEGIN

        lb_ins_status   := TRUE;

        xx_cn_util_pkg.WRITE       ('<<Begin INS_SITE_REQS>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<Begin INS_SITE_REQS>>');
        xx_cn_util_pkg.display_log ('<<Begin INS_SITE_REQS>>');

        xx_cn_util_pkg.WRITE       ('INS_SITE_REQS: Insert into XX_CN_SITE_REQUESTS Table ','LOG');
        xx_cn_util_pkg.DEBUG       ('INS_SITE_REQS: Insert into XX_CN_SITE_REQUESTS Table ' );
        xx_cn_util_pkg.display_log ('INS_SITE_REQS: Insert into XX_CN_SITE_REQUESTS Table ' );

        FOR site_requests_id_rec IN lcu_site_requests_id
        LOOP

            ln_site_requests_id := site_requests_id_rec.site_requests_id;

        END LOOP;

        xx_cn_util_pkg.DEBUG       ('INS_SITE_REQS: Site Requests Id : ' || ln_site_requests_id );
        xx_cn_util_pkg.display_log ('INS_SITE_REQS: Site Requests Id : ' || ln_site_requests_id );

        INSERT INTO xx_cn_site_requests ( site_req_id
                                         ,row_id
                                         ,party_site_id
                                         ,site_request_id
                                         ,effective_date
                                         ,processed_date
                                         ,request_id
                                         ,program_application_id
                                         ,created_by
                                         ,creation_date
                                         ,last_updated_by
                                         ,last_update_date
                                         ,last_update_login )
                                 VALUES ( ln_site_requests_id
                                         ,p_site_requests_rec.row_id
                                         ,p_site_requests_rec.party_site_id
                                         ,p_site_requests_rec.site_request_id
                                         ,p_site_requests_rec.effective_date
                                         ,ld_sysdate
                                         ,ln_req_id
                                         ,ln_appln_id
                                         ,ln_user_id
                                         ,ld_sysdate
                                         ,ln_user_id
                                         ,ld_sysdate
                                         ,ln_login );

        IF ( p_commit_flag ) THEN

            xx_cn_util_pkg.DEBUG       ('INS_SITE_REQS: Commit Inserted Records.' );
            xx_cn_util_pkg.display_log ('INS_SITE_REQS: Commit Inserted Records.' );

            COMMIT;

        END IF;

        xx_cn_util_pkg.DEBUG       ('INS_SITE_REQS: Inserted Record.' );
        xx_cn_util_pkg.display_log ('INS_SITE_REQS: Inserted Record.' );

        xx_cn_util_pkg.WRITE       ('<<End INS_SITE_REQS>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<End INS_SITE_REQS>>');
        xx_cn_util_pkg.display_log ('<<End INS_SITE_REQS>>');

        RETURN lb_ins_status;

    EXCEPTION

        WHEN OTHERS THEN

            lb_ins_status   := FALSE;

            ROLLBACK;

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0048_ERR_INS_SITE_REQS');
            FND_MESSAGE.Set_Token ('SQL_ERR', SQLERRM);
            lc_message_data       := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_RETRO_ASGN_PKG.INS_SITE_REQS'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_RETRO_ASGN_PKG.INS_SITE_REQS'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0048_ERR_INS_SITE_REQS' );

            xx_cn_util_pkg.DEBUG       ('ERROR: XX_CN_RETRO_ASGN_PKG.Ins_Site_Reqs ' || lc_message_data);
            xx_cn_util_pkg.display_log ('ERROR: XX_CN_RETRO_ASGN_PKG.Ins_Site_Reqs ' || lc_message_data);

            xx_cn_util_pkg.WRITE       ('<<End INS_SITE_REQS>>', 'LOG');
            xx_cn_util_pkg.DEBUG       ('<<End INS_SITE_REQS>>');
            xx_cn_util_pkg.display_log ('<<End INS_SITE_REQS>>');

            RETURN lb_ins_status;

    END ins_site_reqs;

-- ---------------------
-- Procedure Definitions
-- ---------------------

    -- +===================================================================+
    -- | Name        : Run_Retro_Asgn                                      |
    -- | Description : Retro Assignment Program                            |
    -- |                                                                   |
    -- | Parameters  : Start_Date            Start Date                    |
    -- |               End_Date              End Date                      |
    -- |                                                                   |
    -- | Returns     : Retcode               Return Code                   |
    -- |               Errbuf                Error Buffer                  |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE run_retro_asgn( x_errbuf           OUT VARCHAR2
                             ,x_retcode          OUT NUMBER
                             ,p_start_date       IN  VARCHAR2
                             ,p_end_date         IN  VARCHAR2 )
    IS

        EX_INVALID_START_DATE    EXCEPTION;
        EX_START_DATE_NOT_IN_QTR EXCEPTION;

        lb_ins_sts               BOOLEAN;
        lb_no_records            BOOLEAN;
        lb_obs_sts               BOOLEAN;

        lc_desc                  VARCHAR2(240) := NULL;
        lc_message_data          VARCHAR2(4000);

        ld_effective_date        DATE;
        ld_end_date              DATE;
        ld_quarter_start_date    DATE;
        ld_rollup_date           DATE;
        ld_start_date            DATE;
        ld_sysdate               DATE := SYSDATE;

        ln_cntr                  NUMBER;
        ln_message_code          NUMBER;
        ln_no_of_records         NUMBER;
        ln_party_site_id         NUMBER;
        ln_proc_audit_id         NUMBER;
        ln_req_id                NUMBER := FND_GLOBAL.Conc_Request_Id;
        ln_sales_reps_exist      NUMBER;
        ln_ship_to_address_id    NUMBER;
        ln_site_reqs             NUMBER;

        CURSOR lcu_quarter_date ( p_sysdate DATE )
        IS
        SELECT GPS.quarter_start_date
        FROM   gl_period_statuses     GPS
              ,cn_repositories        CR
        WHERE  GPS.application_id   = FND_PROFILE.Value('RESP_APPL_ID')
        AND    GPS.set_of_books_id  = CR.set_of_books_id
        AND    CR.org_id            = FND_PROFILE.Value('ORG_ID')
        AND    p_sysdate            BETWEEN GPS.start_date
                                    AND     GPS.end_date;

        CURSOR lcu_changed_sites ( p_start_date  DATE
                                  ,p_end_date    DATE )
        IS
        SELECT XSR.party_site_id         party_site_id
              ,min(XSR.effective_date)   effective_date
        FROM   xxtps_site_requests       XSR
        WHERE  XSR.request_status_code = 'COMPLETED'
        AND    XSR.effective_date      BETWEEN p_start_date
                                       AND     p_end_date
        AND    XSR.site_request_id     NOT IN ( SELECT XCSR.site_request_id
                                                FROM   xx_cn_site_requests   XCSR )
        GROUP BY XSR.party_site_id;

        CURSOR lcu_rollupdates( p_party_site_id NUMBER
                               ,p_eff_date      DATE
                               ,p_end_date      DATE )
        IS
        SELECT DISTINCT
               XCOT.ship_to_address_id   ship_to_address_id
              ,XCOT.rollup_date          rollup_date
        FROM   xx_cn_om_trx_v            XCOT
        WHERE  XCOT.summarized_flag      = 'N'
        AND    XCOT.salesrep_assign_flag = 'Y'
        AND    XCOT.party_site_id        = p_party_site_id
        AND    XCOT.rollup_date          BETWEEN p_eff_date
                                         AND     p_end_date
        UNION
        SELECT DISTINCT
               XCAT.ship_to_address_id   ship_to_address_id
              ,XCAT.rollup_date          rollup_date
        FROM   xx_cn_ar_trx_v            XCAT
        WHERE  XCAT.summarized_flag      = 'N'
        AND    XCAT.salesrep_assign_flag = 'Y'
        AND    XCAT.party_site_id        = p_party_site_id
        AND    XCAT.rollup_date          BETWEEN p_eff_date
                                         AND     p_end_date
        UNION
        SELECT DISTINCT
               XCFT.ship_to_address_id   ship_to_address_id
              ,XCFT.rollup_date          rollup_date
        FROM   xx_cn_fan_trx_v           XCFT
        WHERE  XCFT.summarized_flag      = 'N'
        AND    XCFT.salesrep_assign_flag = 'Y'
        AND    XCFT.party_site_id        = p_party_site_id
        AND    XCFT.rollup_date          BETWEEN p_eff_date
                                         AND     p_end_date;

        CURSOR lcu_sales_reps_exist ( p_party_site_id  NUMBER
                                     ,p_rollup_date    DATE )
        IS
        SELECT COUNT(1)                sales_reps_exist
        FROM   xx_cn_sales_rep_asgn    XCSRA
        WHERE  XCSRA.party_site_id   = p_party_site_id
        AND    XCSRA.rollup_date     = p_rollup_date
        AND    XCSRA.obsolete_flag   = 'N';

        CURSOR lcu_sales_reps ( p_party_site_id  NUMBER
                               ,p_rollup_date    DATE )
        IS
        SELECT *
        FROM   xx_cn_sales_rep_asgn    XCSRA
        WHERE  XCSRA.party_site_id   = p_party_site_id
        AND    XCSRA.rollup_date     = p_rollup_date
        AND    XCSRA.obsolete_flag   = 'N';

    BEGIN

        lc_desc        := 'Retro Assignment Program for Date Range Between ' || p_start_date || ' and ' || p_end_date;

        ld_start_date  := FND_DATE.Canonical_To_Date(p_start_date);
        ld_end_date    := FND_DATE.Canonical_To_Date(p_end_date);

        lb_no_records  := TRUE;

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (LPAD ('Office Depot', 44));
        xx_cn_util_pkg.display_out (LPAD (G_RETRO_PROG,55));
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (RPAD ('-', 76, '-'));

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out ('Program Run Date     : '|| TO_CHAR(ld_sysdate,'MM/DD/RRRR HH24:MI:SS') );

        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.display_log (LPAD ('Office Depot', 44));
        xx_cn_util_pkg.display_log (LPAD (G_RETRO_PROG,55));
        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.display_log (RPAD ('-', 76, '-'));

        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.display_log ('Program Run Date     : '|| TO_CHAR(ld_sysdate,'MM/DD/RRRR HH24:MI:SS') );

        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.WRITE       ('<<Begin RUN_RETRO_ASGN>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<Begin RUN_RETRO_ASGN>>');
        xx_cn_util_pkg.display_log ('<<Begin RUN_RETRO_ASGN>>');

        -- ---------------------------------
        -- Process Audit
        -- Begin Batch - Sales_Rep_Asgn_Main
        -- ---------------------------------

        xx_cn_util_pkg.begin_batch ( p_parent_proc_audit_id => NULL
                                    ,x_process_audit_id     => ln_proc_audit_id
                                    ,p_request_id           => ln_req_id
                                    ,p_process_type         => G_RETRO_ASGN
                                    ,p_description          => lc_desc   );

        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: Begin Process Audit Batch : '|| ln_proc_audit_id);
        xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Begin Process Audit Batch : '|| ln_proc_audit_id);

        xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: Checking if Start Date is valid');
        xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Checking if Start Date is valid');

        IF ( ld_start_date > ld_sysdate ) THEN

            RAISE EX_INVALID_START_DATE;

        ELSE

            FOR quarter_date_rec IN lcu_quarter_date ( p_sysdate => ld_sysdate )
            LOOP

                ld_quarter_start_date := quarter_date_rec.quarter_start_date;

            END LOOP;

            IF ( ld_start_date < ld_quarter_start_date ) THEN

                RAISE EX_START_DATE_NOT_IN_QTR;

            END IF;

        END IF;

        xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: Start Date is Valid ' || TO_CHAR(ld_start_date,'MM/DD/RRRR HH24:MI:SS'));
        xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Start Date is Valid ' || TO_CHAR(ld_start_date,'MM/DD/RRRR HH24:MI:SS'));

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out ('Date Range ( Start ) : '|| TO_CHAR(ld_start_date,'MM/DD/RRRR HH24:MI:SS') );

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out ('Date Range ( End )   : '|| TO_CHAR(ld_end_date,'MM/DD/RRRR HH24:MI:SS') );

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (LPAD ('Start of Program', 46, '*') || LPAD ('*', 30, '*'));

        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.display_log (LPAD ('Detailed Error and Debug Messages', 22, '*') || LPAD ('*', 22, '*'));

        xx_cn_util_pkg.WRITE       ('RUN_RETRO_ASGN: Run Retro Assignment ','LOG');
        xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Run Retro Assignment ');

        FOR changed_sites_rec IN  lcu_changed_sites ( p_start_date  => ld_start_date
                                                     ,p_end_date    => ld_end_date  )
        LOOP

            ln_party_site_id  := changed_sites_rec.party_site_id;
            ld_effective_date := changed_sites_rec.effective_date;

            lb_no_records  := FALSE;

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out (LPAD ('*', 40, '*'));

            xx_cn_util_pkg.display_log ('');
            xx_cn_util_pkg.display_log (LPAD ('*', 40, '*'));

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out ('Party Site Id   : '|| ln_party_site_id );

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out ('Effective Date  : '|| TO_CHAR(ld_effective_date,'MM/DD/RRRR HH24:MI:SS') );

            xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: Effective Date ' || TO_CHAR(ld_effective_date,'MM/DD/RRRR HH24:MI:SS') );
            xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Effective Date ' || TO_CHAR(ld_effective_date,'MM/DD/RRRR HH24:MI:SS') );

            FOR rollupdates_rec IN lcu_rollupdates( p_party_site_id => ln_party_site_id
                                                   ,p_eff_date      => ld_effective_date
                                                   ,p_end_date      => ld_end_date )
            LOOP

                ln_ship_to_address_id  := rollupdates_rec.ship_to_address_id;
                ld_rollup_date         := rollupdates_rec.rollup_date;

                xx_cn_util_pkg.display_out ('');
                xx_cn_util_pkg.display_out ('Rollup Date     : '|| TO_CHAR(ld_rollup_date,'MM/DD/RRRR HH24:MI:SS') );

                xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: Checking if Sales Reps exist for Party Site ID : ' || ln_party_site_id || ' and Rollup Date : ' || ld_rollup_date );
                xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Checking if Sales Reps exist for Party Site ID : ' || ln_party_site_id || ' and Rollup Date : ' || ld_rollup_date );

                FOR sales_reps_exist_rec IN lcu_sales_reps_exist ( p_party_site_id  => ln_party_site_id
                                                                  ,p_rollup_date    => ld_rollup_date )
                LOOP

                    ln_sales_reps_exist := sales_reps_exist_rec.sales_reps_exist;

                END LOOP;

                xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: Sales Rep Record Count : ' || ln_sales_reps_exist );
                xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Sales Rep Record Count : ' || ln_sales_reps_exist );

                IF ( ln_sales_reps_exist > 0 ) THEN

                    xx_cn_util_pkg.WRITE       ('RUN_RETRO_ASGN: Obsolete Sales Reps ','LOG' );
                    xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Obsolete Sales Reps ' );

                    ln_cntr := 0;

                    FOR sales_reps_rec IN lcu_sales_reps ( p_party_site_id  => ln_party_site_id
                                                          ,p_rollup_date    => ld_rollup_date )
                    LOOP

                        ln_cntr := ln_cntr + 1;

                        gt_sales_rep_asgn(ln_cntr) := sales_reps_rec;

                    END LOOP;

                    lb_obs_sts := xx_cn_sales_rep_asgn_pkg.Obs_Sales_Reps ( x_sales_rep_asgn_tbl  => gt_sales_rep_asgn );

                    IF ( lb_obs_sts ) THEN

                        COMMIT;

                        xx_cn_util_pkg.display_out ('');
                        xx_cn_util_pkg.display_out ('No of Sales Rep Records Obsoleted : '|| ln_cntr );

                        xx_cn_util_pkg.WRITE       ('RUN_RETRO_ASGN: Obsoleted Sales Reps.','LOG');
                        xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Obsoleted Sales Reps.');

                    ELSE

                        ln_message_code      := -1;
                        FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0038_ERR_OBS_SALES_REPS');
                        lc_message_data      := FND_MESSAGE.Get;

                        xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_RETRO_ASGN_PKG.RUN_RETRO_ASGN'
                                                 ,p_prog_type      => G_PROG_TYPE
                                                 ,p_prog_id        => ln_req_id
                                                 ,p_exception      => 'XX_CN_RETRO_ASGN_PKG.RUN_RETRO_ASGN'
                                                 ,p_message        => lc_message_data
                                                 ,p_code           => ln_message_code
                                                 ,p_err_code       => 'XX_OIC_0038_ERR_OBS_SALES_REPS' );

                        xx_cn_util_pkg.DEBUG        ('RUN_RETRO_ASGN: Error while Obsoleting.');
                        xx_cn_util_pkg.display_log  ('RUN_RETRO_ASGN: Error while Obsoleting.');
                        xx_cn_util_pkg.update_batch ( ln_proc_audit_id
                                                     ,SQLCODE
                                                     ,lc_message_data );
                        x_retcode  := 2;
                        x_errbuf   := 'Procedure: RUN_RETRO_ASGN: ' || lc_message_data;

                    END IF;

                END IF;

                xx_cn_util_pkg.WRITE       ('RUN_RETRO_ASGN: Obtain Sales Reps ','LOG' );
                xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Obtain Sales Reps ' );

                ln_no_of_records := 0;

                xx_cn_sales_rep_asgn_pkg.Insert_Salesreps ( p_ship_to_address_id => ln_ship_to_address_id
                                                           ,p_party_site_id      => ln_party_site_id
                                                           ,p_rollup_date        => ld_rollup_date
                                                           ,p_batch_id           => NULL
                                                           ,p_process_audit_id   => ln_proc_audit_id
                                                           ,x_no_of_records      => ln_no_of_records
                                                           ,x_retcode            => x_retcode
                                                           ,x_errbuf             => x_errbuf );

                IF ( x_retcode = 0 ) THEN

                    xx_cn_util_pkg.display_out ('');
                    xx_cn_util_pkg.display_out ('No of Sales Rep Records Inserted : '|| ln_no_of_records );

                    xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: Number of records inserted : ' || ln_no_of_records );
                    xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Number of records inserted : ' || ln_no_of_records );

                ELSIF ( x_retcode = 1 ) THEN

                    xx_cn_util_pkg.display_out ('');
                    xx_cn_util_pkg.display_out ('No of Sales Rep Records Inserted : '|| ln_no_of_records );

                    x_retcode  := 1;
                    x_errbuf   := 'Procedure: RUN_RETRO_ASGN: ' || x_errbuf;

                    xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: No Sales Reps found for the Party Site and Rollup Date.');
                    xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: No Sales Reps found for the Party Site and Rollup Date.');

                ELSIF ( x_retcode = 2 ) THEN

                    xx_cn_util_pkg.display_out ('');
                    xx_cn_util_pkg.display_out ('Error while Inserting Sales Reps.' );

                    x_retcode  := 2;
                    x_errbuf   := 'Procedure: RUN_RETRO_ASGN: ' || x_errbuf;

                    xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: Error while Inserting Sales Reps.');
                    xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Error while Inserting Sales Reps.');

                END IF;

            END LOOP;

            IF ( x_retcode = 0 AND ln_no_of_records > 0 ) THEN

                xx_cn_util_pkg.WRITE       ('RUN_RETRO_ASGN: Insert Processed Site Requests into XX_CN_SITE_REQUESTS ','LOG' );
                xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Insert Processed Site Requests into XX_CN_SITE_REQUESTS ' );

                FOR site_requests_rec IN gcu_site_requests ( p_party_site_id => ln_party_site_id )
                LOOP

                    ln_site_reqs := ln_site_reqs + 1;

                    lb_ins_sts := Ins_Site_Reqs ( p_site_requests_rec => site_requests_rec );

                END LOOP;

                IF ( lb_ins_sts ) THEN

                    COMMIT;

                    xx_cn_util_pkg.WRITE       ('RUN_RETRO_ASGN: Inserted Processed Site Requests.','LOG');
                    xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: Inserted Processed Site Requests.');

                ELSE

                    FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0048_ERR_INS_SITE_REQS');

                    x_retcode := 2;
                    x_errbuf  := FND_MESSAGE.Get;

                    xx_cn_util_pkg.DEBUG        ('RUN_RETRO_ASGN: Error while Inserting.');
                    xx_cn_util_pkg.display_log  ('RUN_RETRO_ASGN: Error while Inserting.');
                    xx_cn_util_pkg.update_batch ( ln_proc_audit_id
                                                 ,SQLCODE
                                                 ,x_errbuf );

                END IF;

            END IF;

        END LOOP;

        xx_cn_sales_rep_asgn_pkg.Report_Error;

        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.display_log (LPAD ('*', 77, '*'));

        IF ( lb_no_records ) THEN

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out ('No effective site requests to be processed.');

            xx_cn_util_pkg.display_log ('');
            xx_cn_util_pkg.display_log ('No effective site requests to be processed.');

        ELSE

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out ('No of Site Requests Processed : '|| ln_site_reqs );

        END IF;

        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.display_log (LPAD ('*', 77, '*'));

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (LPAD ('End of Program', 45, '*') || LPAD ('*', 31, '*'));
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (RPAD ('-', 76, '-'));

        -- ----------------
        -- End Main Program
        -- ----------------

        xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: End Process Audit Batch : '|| ln_proc_audit_id);
        xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: End Process Audit Batch : '|| ln_proc_audit_id);

        -- -------------------------------
        -- Process Audit
        -- End Batch - Sales_Rep_Asgn_Main
        -- -------------------------------

        xx_cn_util_pkg.end_batch ( ln_proc_audit_id );

        xx_cn_util_pkg.WRITE       ('<<End RUN_RETRO_ASGN>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<End RUN_RETRO_ASGN>>');
        xx_cn_util_pkg.display_log ('<<End RUN_RETRO_ASGN>>');

    EXCEPTION

        WHEN EX_INVALID_START_DATE THEN

            ROLLBACK;

            ln_message_code      := -1;
            FND_MESSAGE.Set_Name ('XXCRM', 'XX_OIC_0049_INVALID_START_DATE');
            lc_message_data      := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_RETRO_ASGN_PKG.RUN_RETRO_ASGN'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_RETRO_ASGN_PKG.RUN_RETRO_ASGN'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0048_INVALID_START_DATE' );

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_RETRO_ASGN_PKG.Run_Retro_Asgn ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_RETRO_ASGN_PKG.Run_Retro_Asgn ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( ln_proc_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: End Process Audit Batch : '|| ln_proc_audit_id);
            xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: End Process Audit Batch : '|| ln_proc_audit_id);

            xx_cn_util_pkg.WRITE        ('<<End RUN_RETRO_ASGN>>', 'LOG');
            xx_cn_util_pkg.DEBUG        ('<<End RUN_RETRO_ASGN>>');
            xx_cn_util_pkg.display_log  ('<<End RUN_RETRO_ASGN>>');

            xx_cn_util_pkg.end_batch    ( ln_proc_audit_id );

            x_retcode := 2;
            x_errbuf  := 'Procedure: RUN_RETRO_ASGN: ' || lc_message_data;

        WHEN EX_START_DATE_NOT_IN_QTR THEN

            ROLLBACK;

            ln_message_code      := -1;
            FND_MESSAGE.Set_Name ('XXCRM', 'XX_OIC_0047_DATE_NOT_IN_QTR');
            lc_message_data      := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_RETRO_ASGN_PKG.RUN_RETRO_ASGN'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_RETRO_ASGN_PKG.RUN_RETRO_ASGN'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0047_DATE_NOT_IN_QTR' );

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_RETRO_ASGN_PKG.Run_Retro_Asgn ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_RETRO_ASGN_PKG.Run_Retro_Asgn ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( ln_proc_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: End Process Audit Batch : '|| ln_proc_audit_id);
            xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: End Process Audit Batch : '|| ln_proc_audit_id);

            xx_cn_util_pkg.WRITE        ('<<End RUN_RETRO_ASGN>>', 'LOG');
            xx_cn_util_pkg.DEBUG        ('<<End RUN_RETRO_ASGN>>');
            xx_cn_util_pkg.display_log  ('<<End RUN_RETRO_ASGN>>');

            xx_cn_util_pkg.end_batch    ( ln_proc_audit_id );

            x_retcode := 2;
            x_errbuf  := 'Procedure: RUN_RETRO_ASGN: ' || lc_message_data;

        WHEN OTHERS THEN

            ROLLBACK;

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
            FND_MESSAGE.Set_Token ('SQL_CODE', SQLCODE);
            FND_MESSAGE.Set_Token ('SQL_ERR', SQLERRM);
            lc_message_data       := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_RETRO_ASGN_PKG.RUN_RETRO_ASGN'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_RETRO_ASGN_PKG.RUN_RETRO_ASGN'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR' );

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_RETRO_ASGN_PKG.Run_Retro_Asgn ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_RETRO_ASGN_PKG.Run_Retro_Asgn ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( ln_proc_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.DEBUG       ('RUN_RETRO_ASGN: End Process Audit Batch : '|| ln_proc_audit_id);
            xx_cn_util_pkg.display_log ('RUN_RETRO_ASGN: End Process Audit Batch : '|| ln_proc_audit_id);

            xx_cn_util_pkg.WRITE        ('<<End RUN_RETRO_ASGN>>', 'LOG');
            xx_cn_util_pkg.DEBUG        ('<<End RUN_RETRO_ASGN>>');
            xx_cn_util_pkg.display_log  ('<<End RUN_RETRO_ASGN>>');

            xx_cn_util_pkg.end_batch    ( ln_proc_audit_id );

            x_retcode := 2;
            x_errbuf  := 'Procedure: RUN_RETRO_ASGN: ' || lc_message_data;

    END run_retro_asgn;

END xx_cn_retro_asgn_pkg;
/

SHOW ERRORS;
