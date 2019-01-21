SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_cn_sales_rep_asgn_pkg

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_CN_SALES_REP_ASGN_PKG.pkb                               |
-- | Rice ID     : E1004E_CustomCollections_(SalesRep_Assignment)             |
-- | Description : Custom Package that contains all the utility functions and |
-- |               procedures required to do Sales Rep Assignments.           |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |Draft 1a 11-Oct-2007 Vidhya Valantina T     Initial draft version         |
-- |1.0      23-Oct-2007 Vidhya Valantina T     Baselined after review        |
-- |1.1      05-Nov-2007 Vidhya Valantina T     Changes due to addition of new|
-- |                                            column 'Party_Site_Id' in the |
-- |                                            Extract Tables.               |
-- |1.2      14-Nov-2007 Vidhya Valantina T     Error Output Format Changes   |
-- |                                                                          |
-- +==========================================================================+

AS

-- --------------------
-- Function Definitions
-- --------------------

    -- +===================================================================+
    -- | Name        : Ins_Sales_Reps                                      |
    -- | Description : Function to insert Records into XX_CN_SALES_REP_ASGN|
    -- |               Custom Table                                        |
    -- |                                                                   |
    -- | Parameters  : Sales_Rep_Asgn_Tbl    PL/SQL Table of Records       |
    -- |               Commit_Flag           Commit Flag                   |
    -- |                                                                   |
    -- | Returns     : Insert Status                                       |
    -- |                                                                   |
    -- +===================================================================+

    FUNCTION ins_sales_reps ( x_sales_rep_asgn_tbl  IN OUT sales_rep_asgn_tbl_type
                             ,p_commit_flag         IN     BOOLEAN  DEFAULT FALSE )
    RETURN BOOLEAN
    IS

        lb_ins_status        BOOLEAN;

        lc_message_data      VARCHAR2 (4000);

        ld_sysdate           DATE         := SYSDATE;

        ln_appln_id          NUMBER       := FND_PROFILE.Value('RESP_APPL_ID');
        ln_index             PLS_INTEGER;
        ln_login             NUMBER       := FND_GLOBAL.Login_Id;
        ln_message_code      NUMBER;
        ln_org_id            NUMBER       := FND_GLOBAL.Org_Id;
        ln_req_id            NUMBER       := FND_GLOBAL.Conc_Request_Id;
        ln_sales_rep_asgn_id NUMBER;
        ln_user_id           NUMBER       := FND_GLOBAL.User_Id;

        --
        -- Cursor to Get Primary Key Sequence
        --
        CURSOR lcu_sales_rep_asgn_id
        IS
        SELECT xx_cn_sales_rep_asgn_s.NEXTVAL sales_rep_asgn_id
        FROM   SYS.dual;

    BEGIN

        lb_ins_status   := TRUE;

        xx_cn_util_pkg.WRITE       ('<<Begin INS_SALES_REPS>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<Begin INS_SALES_REPS>>');
        xx_cn_util_pkg.display_log ('<<Begin INS_SALES_REPS>>');

        xx_cn_util_pkg.WRITE       ('INS_SALES_REPS: Bulk Insert into XX_CN_SALES_REP_ASGN Table ','LOG');
        xx_cn_util_pkg.DEBUG       ('INS_SALES_REPS: Bulk Insert into XX_CN_SALES_REP_ASGN Table ' );
        xx_cn_util_pkg.display_log ('INS_SALES_REPS: Bulk Insert into XX_CN_SALES_REP_ASGN Table ' );

        FOR ln_index IN x_sales_rep_asgn_tbl.FIRST .. x_sales_rep_asgn_tbl.LAST
        LOOP

            FOR sales_rep_asgn_id_rec IN lcu_sales_rep_asgn_id
            LOOP

                ln_sales_rep_asgn_id := sales_rep_asgn_id_rec.sales_rep_asgn_id;

            END LOOP;

            xx_cn_util_pkg.DEBUG       ('INS_SALES_REPS: Sales Rep Asgn Id : ' || ln_sales_rep_asgn_id );
            xx_cn_util_pkg.display_log ('INS_SALES_REPS: Sales Rep Asgn Id : ' || ln_sales_rep_asgn_id );

            x_sales_rep_asgn_tbl(ln_index).sales_rep_asgn_id      :=  ln_sales_rep_asgn_id;
            x_sales_rep_asgn_tbl(ln_index).org_id                 :=  ln_org_id;
            x_sales_rep_asgn_tbl(ln_index).obsolete_flag          :=  'N';
            x_sales_rep_asgn_tbl(ln_index).request_id             :=  ln_req_id;
            x_sales_rep_asgn_tbl(ln_index).program_application_id :=  ln_appln_id;
            x_sales_rep_asgn_tbl(ln_index).created_by             :=  ln_user_id;
            x_sales_rep_asgn_tbl(ln_index).creation_date          :=  ld_sysdate;
            x_sales_rep_asgn_tbl(ln_index).last_updated_by        :=  ln_user_id;
            x_sales_rep_asgn_tbl(ln_index).last_update_date       :=  ld_sysdate;
            x_sales_rep_asgn_tbl(ln_index).last_update_login      :=  ln_login;

            xx_cn_util_pkg.DEBUG       ('INS_SALES_REPS: Insert Record : ' || ln_sales_rep_asgn_id );
            xx_cn_util_pkg.display_log ('INS_SALES_REPS: Insert Record : ' || ln_sales_rep_asgn_id );

            INSERT INTO xx_cn_sales_rep_asgn VALUES x_sales_rep_asgn_tbl(ln_index);

        END LOOP;

        IF ( p_commit_flag ) THEN

            xx_cn_util_pkg.DEBUG       ('INS_SALES_REPS: Commit Inserted Records.' );
            xx_cn_util_pkg.display_log ('INS_SALES_REPS: Commit Inserted Records.' );

            COMMIT;

        END IF;

        xx_cn_util_pkg.DEBUG       ('INS_SALES_REPS: Bulk Inserted Records.' );
        xx_cn_util_pkg.display_log ('INS_SALES_REPS: Bulk Inserted Records.' );

        xx_cn_util_pkg.WRITE       ('<<End INS_SALES_REPS>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<End INS_SALES_REPS>>');
        xx_cn_util_pkg.display_log ('<<End INS_SALES_REPS>>');

        RETURN lb_ins_status;

    EXCEPTION

        WHEN OTHERS THEN

            lb_ins_status   := FALSE;

            ROLLBACK;

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0037_ERR_INS_SALES_REPS');
            FND_MESSAGE.Set_Token ('SQL_ERR', SQLERRM);
            lc_message_data       := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.INS_SALES_REPS'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.INS_SALES_REPS'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0037_ERR_INS_SALES_REPS' );

            xx_cn_util_pkg.DEBUG       ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Ins_Sales_Reps ' || lc_message_data);
            xx_cn_util_pkg.display_log ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Ins_Sales_Reps ' || lc_message_data);

            xx_cn_util_pkg.WRITE       ('<<End INS_SALES_REPS>>', 'LOG');
            xx_cn_util_pkg.DEBUG       ('<<End INS_SALES_REPS>>');
            xx_cn_util_pkg.display_log ('<<End INS_SALES_REPS>>');

            RETURN lb_ins_status;

    END ins_sales_reps;

    -- +===================================================================+
    -- | Name        : Upd_Sales_Reps                                      |
    -- | Description : Function to update Records in XX_CN_SALES_REP_ASGN  |
    -- |               Custom Table                                        |
    -- |                                                                   |
    -- | Parameters  : Sales_Rep_Asgn_Tbl    PL/SQL Table of Records       |
    -- |               Commit_Flag           Commit Flag                   |
    -- |                                                                   |
    -- | Returns     : Update Status                                       |
    -- |                                                                   |
    -- +===================================================================+

    FUNCTION upd_sales_reps ( x_sales_rep_asgn_tbl  IN OUT sales_rep_asgn_tbl_type
                             ,p_commit_flag         IN     BOOLEAN  DEFAULT FALSE )
    RETURN BOOLEAN
    IS

        lb_upd_status   BOOLEAN;

        lc_message_data VARCHAR2 (4000);

        ld_sysdate      DATE         := SYSDATE;

        ln_appln_id     NUMBER       := FND_PROFILE.Value('RESP_APPL_ID');
        ln_index        PLS_INTEGER;
        ln_login        NUMBER       := FND_GLOBAL.Login_Id;
        ln_message_code NUMBER;
        ln_req_id       NUMBER       := FND_GLOBAL.Conc_Request_Id;
        ln_user_id      NUMBER       := FND_GLOBAL.User_Id;

    BEGIN

        lb_upd_status   := TRUE;

        xx_cn_util_pkg.WRITE       ('<<Begin UPD_SALES_REPS>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<Begin UPD_SALES_REPS>>');
        xx_cn_util_pkg.display_log ('<<Begin UPD_SALES_REPS>>');

        xx_cn_util_pkg.WRITE       ('UPD_SALES_REPS: Bulk Update into XX_CN_SALES_REP_ASGN Table ','LOG');
        xx_cn_util_pkg.DEBUG       ('UPD_SALES_REPS: Bulk Update into XX_CN_SALES_REP_ASGN Table ' );
        xx_cn_util_pkg.display_log ('UPD_SALES_REPS: Bulk Update into XX_CN_SALES_REP_ASGN Table ' );

        FOR ln_index IN x_sales_rep_asgn_tbl.FIRST .. x_sales_rep_asgn_tbl.LAST
        LOOP

            x_sales_rep_asgn_tbl(ln_index).request_id             :=  ln_req_id;
            x_sales_rep_asgn_tbl(ln_index).program_application_id :=  ln_appln_id;
            x_sales_rep_asgn_tbl(ln_index).last_updated_by        :=  ln_user_id;
            x_sales_rep_asgn_tbl(ln_index).last_update_date       :=  ld_sysdate;
            x_sales_rep_asgn_tbl(ln_index).last_update_login      :=  ln_login;

            xx_cn_util_pkg.DEBUG       ('UPD_SALES_REPS: Update Record : ' || x_sales_rep_asgn_tbl(ln_index).sales_rep_asgn_id );
            xx_cn_util_pkg.display_log ('UPD_SALES_REPS: Update Record : ' || x_sales_rep_asgn_tbl(ln_index).sales_rep_asgn_id );

            UPDATE xx_cn_sales_rep_asgn      XCSRA
            SET    ROW = x_sales_rep_asgn_tbl(ln_index)
            WHERE  XCSRA.sales_rep_asgn_id = x_sales_rep_asgn_tbl(ln_index).sales_rep_asgn_id;

        END LOOP;

        IF ( p_commit_flag ) THEN

            xx_cn_util_pkg.DEBUG       ('UPD_SALES_REPS: Commit Updated Records.' );
            xx_cn_util_pkg.display_log ('UPD_SALES_REPS: Commit Updated Records.' );

            COMMIT;

        END IF;

        xx_cn_util_pkg.DEBUG       ('UPD_SALES_REPS: Bulk Updated Records.' );
        xx_cn_util_pkg.display_log ('UPD_SALES_REPS: Bulk Updated Records.' );

        xx_cn_util_pkg.WRITE       ('<<End UPD_SALES_REPS>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<End UPD_SALES_REPS>>');
        xx_cn_util_pkg.display_log ('<<End UPD_SALES_REPS>>');

        RETURN lb_upd_status;

    EXCEPTION

        WHEN OTHERS THEN

            lb_upd_status   := FALSE;

            ROLLBACK;

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0039_ERR_UPD_SALES_REPS');
            lc_message_data       := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.UPD_SALES_REPS'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.UPD_SALES_REPS'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0039_ERR_UPD_SALES_REPS' );

            xx_cn_util_pkg.DEBUG       ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Upd_Sales_Reps ' || lc_message_data);
            xx_cn_util_pkg.display_log ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Upd_Sales_Reps ' || lc_message_data);

            xx_cn_util_pkg.WRITE       ('<<End UPD_SALES_REPS>>', 'LOG');
            xx_cn_util_pkg.DEBUG       ('<<End UPD_SALES_REPS>>');
            xx_cn_util_pkg.display_log ('<<End UPD_SALES_REPS>>');

            RETURN lb_upd_status;

    END upd_sales_reps;

    -- +===================================================================+
    -- | Name        : Obs_Sales_Reps                                      |
    -- | Description : Function to obsolete Records in XX_CN_SALES_REP_ASGN|
    -- |               Custom Table                                        |
    -- |                                                                   |
    -- | Parameters  : Sales_Rep_Asgn_Tbl    PL/SQL Table of Records       |
    -- |               Commit_Flag           Commit Flag                   |
    -- |                                                                   |
    -- | Returns     : Obsolete Status                                     |
    -- |                                                                   |
    -- +===================================================================+

    FUNCTION obs_sales_reps ( x_sales_rep_asgn_tbl  IN OUT sales_rep_asgn_tbl_type
                             ,p_commit_flag         IN     BOOLEAN  DEFAULT FALSE )
    RETURN BOOLEAN
    IS

        lb_obs_status   BOOLEAN;

        lc_message_data VARCHAR2 (4000);

        ld_sysdate      DATE         := SYSDATE;

        ln_appln_id     NUMBER       := FND_PROFILE.Value('RESP_APPL_ID');
        ln_index        PLS_INTEGER;
        ln_login        NUMBER       := FND_GLOBAL.Login_Id;
        ln_message_code NUMBER;
        ln_req_id       NUMBER       := FND_GLOBAL.Conc_Request_Id;
        ln_user_id      NUMBER       := FND_GLOBAL.User_Id;

    BEGIN

        lb_obs_status   := TRUE;

        xx_cn_util_pkg.WRITE       ('<<Begin OBS_SALES_REPS>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<Begin OBS_SALES_REPS>>');
        xx_cn_util_pkg.display_log ('<<Begin OBS_SALES_REPS>>');

        xx_cn_util_pkg.WRITE       ('OBS_SALES_REPS: Obsolete Records in XX_CN_SALES_REP_ASGN Table ','LOG');
        xx_cn_util_pkg.DEBUG       ('OBS_SALES_REPS: Obsolete Records in XX_CN_SALES_REP_ASGN Table ' );
        xx_cn_util_pkg.display_log ('OBS_SALES_REPS: Obsolete Records in XX_CN_SALES_REP_ASGN Table ' );

        FOR ln_index IN x_sales_rep_asgn_tbl.FIRST .. x_sales_rep_asgn_tbl.LAST
        LOOP

            x_sales_rep_asgn_tbl(ln_index).obsolete_flag          :=  'Y';
            x_sales_rep_asgn_tbl(ln_index).request_id             :=  ln_req_id;
            x_sales_rep_asgn_tbl(ln_index).program_application_id :=  ln_appln_id;
            x_sales_rep_asgn_tbl(ln_index).last_updated_by        :=  ln_user_id;
            x_sales_rep_asgn_tbl(ln_index).last_update_date       :=  ld_sysdate;
            x_sales_rep_asgn_tbl(ln_index).last_update_login      :=  ln_login;

            xx_cn_util_pkg.DEBUG       ('OBS_SALES_REPS: Obsolete Record : ' || x_sales_rep_asgn_tbl(ln_index).sales_rep_asgn_id );
            xx_cn_util_pkg.display_log ('OBS_SALES_REPS: Obsolete Record : ' || x_sales_rep_asgn_tbl(ln_index).sales_rep_asgn_id );

            UPDATE xx_cn_sales_rep_asgn      XCSRA
            SET    ROW = x_sales_rep_asgn_tbl(ln_index)
            WHERE  XCSRA.sales_rep_asgn_id = x_sales_rep_asgn_tbl(ln_index).sales_rep_asgn_id;

        END LOOP;

        IF ( p_commit_flag ) THEN

            xx_cn_util_pkg.DEBUG       ('OBS_SALES_REPS: Commit Obsoleted Records.' );
            xx_cn_util_pkg.display_log ('OBS_SALES_REPS: Commit Obsoleted Records.' );

            COMMIT;

        END IF;

        xx_cn_util_pkg.DEBUG       ('OBS_SALES_REPS: Obsoleted Records.' );
        xx_cn_util_pkg.display_log ('OBS_SALES_REPS: Obsoleted Records.' );

        xx_cn_util_pkg.WRITE       ('<<End OBS_SALES_REPS>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<End OBS_SALES_REPS>>');
        xx_cn_util_pkg.display_log ('<<End OBS_SALES_REPS>>');

        RETURN lb_obs_status;

    EXCEPTION

        WHEN OTHERS THEN

            lb_obs_status   := FALSE;

            ROLLBACK;

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0038_ERR_OBS_SALES_REPS');
            lc_message_data       := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.OBS_SALES_REPS'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.OBS_SALES_REPS'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0038_ERR_OBS_SALES_REPS' );

            xx_cn_util_pkg.DEBUG       ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Obs_Sales_Reps ' || lc_message_data);
            xx_cn_util_pkg.display_log ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Obs_Sales_Reps ' || lc_message_data);

            xx_cn_util_pkg.WRITE       ('<<End OBS_SALES_REPS>>', 'LOG');
            xx_cn_util_pkg.DEBUG       ('<<End OBS_SALES_REPS>>');
            xx_cn_util_pkg.display_log ('<<End OBS_SALES_REPS>>');

            RETURN lb_obs_status;

    END obs_sales_reps;

    -- +===================================================================+
    -- | Name        : Ins_Sales_Rep_Rec                                   |
    -- | Description : Function to insert Records in XX_CN_SALES_REP_ASGN  |
    -- |               PL/SQL Table                                        |
    -- |                                                                   |
    -- | Parameters  : Sales_Rep_Asgn_Tbl    PL/SQL Table of Records       |
    -- |               Sales_Rep_Asgn_Rec    PL/SQL Record                 |
    -- |                                                                   |
    -- | Returns     : Insert Record Status                                |
    -- |                                                                   |
    -- +===================================================================+

    FUNCTION ins_sales_rep_rec( x_sales_rep_asgn_tbl  IN OUT sales_rep_asgn_tbl_type
                               ,p_sales_rep_asgn_rec  IN     gcu_sales_rep_details%ROWTYPE )
    RETURN BOOLEAN
    IS

        lb_ins_status   BOOLEAN;

        lc_message_data VARCHAR2 (4000);

        ln_index        NUMBER;
        ln_message_code NUMBER;
        ln_req_id       NUMBER       := FND_GLOBAL.Conc_Request_Id;

    BEGIN

        lb_ins_status   := TRUE;

        ln_index        := x_sales_rep_asgn_tbl.COUNT + 1;

        xx_cn_util_pkg.WRITE       ('<<Begin INS_SALES_REP_REC>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<Begin INS_SALES_REP_REC>>');
        xx_cn_util_pkg.display_log ('<<Begin INS_SALES_REP_REC>>');

        xx_cn_util_pkg.WRITE       ('INS_SALES_REP_REC: Add New Record in Custom PL/SQL Table.','LOG');
        xx_cn_util_pkg.DEBUG       ('INS_SALES_REP_REC: Add New Record in Custom PL/SQL Table.');
        xx_cn_util_pkg.display_log ('INS_SALES_REP_REC: Add New Record in Custom PL/SQL Table.');

        -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
        x_sales_rep_asgn_tbl(ln_index).party_site_id           :=  p_sales_rep_asgn_rec.party_site_id;
        x_sales_rep_asgn_tbl(ln_index).ship_to_address_id      :=  p_sales_rep_asgn_rec.ship_to_address_id;
        x_sales_rep_asgn_tbl(ln_index).rollup_date             :=  p_sales_rep_asgn_rec.rollup_date;
        x_sales_rep_asgn_tbl(ln_index).division                :=  p_sales_rep_asgn_rec.division;
        x_sales_rep_asgn_tbl(ln_index).named_acct_terr_id      :=  p_sales_rep_asgn_rec.named_acct_terr_id;
        x_sales_rep_asgn_tbl(ln_index).resource_id             :=  p_sales_rep_asgn_rec.resource_id;
        x_sales_rep_asgn_tbl(ln_index).resource_org_id         :=  p_sales_rep_asgn_rec.resource_org_id;
        x_sales_rep_asgn_tbl(ln_index).salesrep_division       :=  p_sales_rep_asgn_rec.salesrep_division;
        x_sales_rep_asgn_tbl(ln_index).resource_role_id        :=  p_sales_rep_asgn_rec.resource_role_id;
        x_sales_rep_asgn_tbl(ln_index).group_id                :=  p_sales_rep_asgn_rec.group_id;
        x_sales_rep_asgn_tbl(ln_index).salesrep_id             :=  p_sales_rep_asgn_rec.salesrep_id;
        x_sales_rep_asgn_tbl(ln_index).employee_number         :=  p_sales_rep_asgn_rec.employee_number;
        x_sales_rep_asgn_tbl(ln_index).revenue_type            :=  p_sales_rep_asgn_rec.role_code;
        x_sales_rep_asgn_tbl(ln_index).start_date_active       :=  p_sales_rep_asgn_rec.start_date_active;
        x_sales_rep_asgn_tbl(ln_index).end_date_active         :=  p_sales_rep_asgn_rec.end_date_active;
        x_sales_rep_asgn_tbl(ln_index).comments                :=  p_sales_rep_asgn_rec.comments;
        x_sales_rep_asgn_tbl(ln_index).batch_id                :=  p_sales_rep_asgn_rec.batch_id;
        x_sales_rep_asgn_tbl(ln_index).process_audit_id        :=  p_sales_rep_asgn_rec.process_audit_id;

        xx_cn_util_pkg.DEBUG       ('INS_SALES_REP_REC: Added Record : ' || ln_index || ' in Custom PL/SQL Table ' );
        xx_cn_util_pkg.display_log ('INS_SALES_REP_REC: Added Record : ' || ln_index || ' in Custom PL/SQL Table ' );

        xx_cn_util_pkg.WRITE       ('<<End INS_SALES_REP_REC>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<End INS_SALES_REP_REC>>');
        xx_cn_util_pkg.display_log ('<<End INS_SALES_REP_REC>>');

        RETURN lb_ins_status;

    EXCEPTION

        WHEN OTHERS THEN

            lb_ins_status   := FALSE;

            x_sales_rep_asgn_tbl.DELETE(x_sales_rep_asgn_tbl.COUNT + 1);

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
            FND_MESSAGE.Set_Token ('SQL_CODE', SQLCODE);
            FND_MESSAGE.Set_Token ('SQL_ERR', SQLERRM);
            lc_message_data       := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.INS_SALES_REP_REC'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.INS_SALES_REP_REC'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR' );

            xx_cn_util_pkg.DEBUG       ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Ins_Sales_Rep_Rec ' || lc_message_data);
            xx_cn_util_pkg.display_log ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Ins_Sales_Rep_Rec ' || lc_message_data);

            xx_cn_util_pkg.WRITE       ('<<End INS_SALES_REP_REC>>', 'LOG');
            xx_cn_util_pkg.DEBUG       ('<<End INS_SALES_REP_REC>>');
            xx_cn_util_pkg.display_log ('<<End INS_SALES_REP_REC>>');

            RETURN lb_ins_status;

    END ins_sales_rep_rec;

-- ---------------------
-- Procedure Definitions
-- ---------------------

    -- +===================================================================+
    -- | Name        : Report_Error                                        |
    -- | Description : Procedure to report errors in the Output File       |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE report_error
    IS

        lb_err_found  BOOLEAN := FALSE;

        ln_rev_index  PLS_INTEGER;
        ln_sr_index   PLS_INTEGER;
        ln_terr_index PLS_INTEGER;

    BEGIN

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out ('Error Report');
        xx_cn_util_pkg.display_out ('------------');

        IF ( gt_terr_api_error.COUNT > 0 ) THEN

            lb_err_found := TRUE;

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out ('Territory API failed to fetch Sales Rep Records for the following transactions');
            xx_cn_util_pkg.display_out (RPAD('-',78,'-'));
            xx_cn_util_pkg.display_out ('');

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out (   RPAD('  ',2)
                                        || RPAD('SHIP_TO_ADDRESS_ID',20)
                                        || CHR(9)
                                        || RPAD('PARTY_SITE_ID',15)
                                        || CHR(9)
                                        || RPAD('ROLLUP_DATE',15)
                                        || CHR(9)
                                        || RPAD('SRC_DOC_TYPE',15)
                                        || CHR(9)
                                        || RPAD('SRC_TRX_ID',15)
                                        || CHR(9)
                                        || RPAD('SRC_TRX_LINE_ID',15)
                                        || CHR(9)
                                        || RPAD('ERROR_MESSAGE',240));
            xx_cn_util_pkg.display_out (RPAD('-',339,'-'));
            xx_cn_util_pkg.display_out ('');

            FOR ln_terr_index IN gt_terr_api_error.FIRST .. gt_terr_api_error.LAST
            LOOP

                xx_cn_util_pkg.display_out (   RPAD('  ',2)
                                            || RPAD(NVL(TO_CHAR(gt_terr_api_error(ln_terr_index).ship_to_address_id),' '),20)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_terr_api_error(ln_terr_index).party_site_id),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_terr_api_error(ln_terr_index).rollup_date),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_terr_api_error(ln_terr_index).source_doc_type),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_terr_api_error(ln_terr_index).source_trx_id),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_terr_api_error(ln_terr_index).source_trx_line_id),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(SUBSTR(TO_CHAR(gt_terr_api_error(ln_terr_index).error_message),1,240),' '),240));

            END LOOP;

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out ('');

        END IF;

        IF ( gt_sales_rep_error.COUNT > 0 ) THEN

            lb_err_found := TRUE;

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out ('Unable to fetch Sales Rep Details Records for the following Sales Reps :');
            xx_cn_util_pkg.display_out ('(Possible Error due to Effectivity Dates, No Assignments, No Active Sales Compensation Role Types)');
            xx_cn_util_pkg.display_out (RPAD('-',98,'-'));
            xx_cn_util_pkg.display_out ('');

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out (   RPAD('  ',2)
                                        || RPAD('SHIP_TO_ADDRESS_ID',20)
                                        || CHR(9)
                                        || RPAD('PARTY_SITE_ID',15)
                                        || CHR(9)
                                        || RPAD('ROLLUP_DATE',15)
                                        || CHR(9)
                                        || RPAD('RESOURCE_ID',15)
                                        || CHR(9)
                                        || RPAD('NAM_TERR_ID',15));
            xx_cn_util_pkg.display_out (RPAD('-',84,'-'));
            xx_cn_util_pkg.display_out ('');

            FOR ln_sr_index IN gt_sales_rep_error.FIRST .. gt_sales_rep_error.LAST
            LOOP

                xx_cn_util_pkg.display_out (   RPAD('  ',2)
                                            || RPAD(NVL(TO_CHAR(gt_sales_rep_error(ln_sr_index).ship_to_address_id),' '),20)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_sales_rep_error(ln_sr_index).party_site_id),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_sales_rep_error(ln_sr_index).rollup_date),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_sales_rep_error(ln_sr_index).resource_id),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_sales_rep_error(ln_sr_index).nam_terr_id),' '),15));

            END LOOP;

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out ('');

        END IF;

        IF ( gt_rev_type_error.COUNT > 0 ) THEN

            lb_err_found := TRUE;

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out ('Following errors occured while setting Revenue Type for Sales Rep Records:');
            xx_cn_util_pkg.display_out (RPAD('-',74,'-'));
            xx_cn_util_pkg.display_out ('');

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out (   RPAD('  ',2)
                                        || RPAD('SHIP_TO_ADDRESS_ID',20)
                                        || CHR(9)
                                        || RPAD('PARTY_SITE_ID',15)
                                        || CHR(9)
                                        || RPAD('ROLLUP_DATE',15)
                                        || CHR(9)
                                        || RPAD('RESOURCE_ID',15)
                                        || CHR(9)
                                        || RPAD('ROLE_ID',15)
                                        || CHR(9)
                                        || RPAD('GROUP_ID',15)
                                        || CHR(9)
                                        || RPAD('SR_DIVISION',15)
                                        || CHR(9)
                                        || RPAD('ROLE_CODE',15)
                                        || CHR(9)
                                        || RPAD('REVENUE_TYPE',15)
                                        || CHR(9)
                                        || RPAD('COMMENTS',240));
            xx_cn_util_pkg.display_out (RPAD('-',384,'-'));
            xx_cn_util_pkg.display_out ('');

            FOR ln_rev_index IN gt_rev_type_error.FIRST .. gt_rev_type_error.LAST
            LOOP

                xx_cn_util_pkg.display_out (   RPAD('  ',2)
                                            || RPAD(NVL(TO_CHAR(gt_rev_type_error(ln_rev_index).ship_to_address_id),' '),20)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_rev_type_error(ln_rev_index).party_site_id),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_rev_type_error(ln_rev_index).rollup_date),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_rev_type_error(ln_rev_index).resource_id),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_rev_type_error(ln_rev_index).role_id),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_rev_type_error(ln_rev_index).group_id),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_rev_type_error(ln_rev_index).salesrep_division),' '),10)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_rev_type_error(ln_rev_index).role_code),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(TO_CHAR(gt_rev_type_error(ln_rev_index).revenue_type),' '),15)
                                            || CHR(9)
                                            || RPAD(NVL(SUBSTR(TO_CHAR(gt_rev_type_error(ln_rev_index).comments),1,240),' '),240));

            END LOOP;

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out ('');

        END IF;

        IF ( NOT lb_err_found ) THEN

            xx_cn_util_pkg.display_out ('');
            xx_cn_util_pkg.display_out ('No Errored Records....');

        END IF;

    END report_error;

    PROCEDURE add_terr_errors ( p_ship_to_address_id IN NUMBER
                               ,p_party_site_id      IN NUMBER
                               ,p_rollup_date        IN DATE
                               ,p_batch_id           IN NUMBER
                               ,p_comments           IN VARCHAR2 )
    IS

        ln_index        NUMBER;

        CURSOR lcu_terr_errors ( p_ship_to_address_id NUMBER
                                ,p_party_site_id      NUMBER
                                ,p_rollup_date        DATE
                                ,p_batch_id           NUMBER
                                ,p_comments           VARCHAR2 )
        IS
        SELECT p_ship_to_address_id              ship_to_address_id
              ,p_party_site_id                   party_site_id
              ,p_rollup_date                     rollup_date
              ,XCT.source_doc_type               source_doc_type
              ,XCT.source_trx_id                 source_trx_id
              ,XCT.source_trx_line_id            source_trx_line_id
              ,p_comments                        error_message
        FROM
              ( SELECT DISTINCT
                       XCOT.source_doc_type
                      ,XCOT.source_trx_id
                      ,XCOT.source_trx_line_id
                FROM   xx_cn_om_trx_v              XCOT
                WHERE  XCOT.summarized_flag      = 'N'
                AND    XCOT.salesrep_assign_flag = 'N'
                AND    XCOT.trnsfr_batch_id||''  = p_batch_id
                AND    XCOT.ship_to_address_id   = p_ship_to_address_id
                AND    XCOT.rollup_date          = p_rollup_date
                UNION  ALL
                SELECT DISTINCT
                       XCAT.source_doc_type
                      ,XCAT.source_trx_id
                      ,XCAT.source_trx_line_id
                FROM   xx_cn_ar_trx_v              XCAT
                WHERE  XCAT.summarized_flag      = 'N'
                AND    XCAT.salesrep_assign_flag = 'N'
                AND    XCAT.trnsfr_batch_id||''  = p_batch_id
                AND    XCAT.ship_to_address_id   = p_ship_to_address_id
                AND    XCAT.rollup_date          = p_rollup_date
                UNION  ALL
                SELECT DISTINCT
                       XCFT.source_doc_type
                      ,XCFT.source_trx_id
                      ,XCFT.source_trx_line_id
                FROM   xx_cn_fan_trx_v             XCFT
                WHERE  XCFT.summarized_flag      = 'N'
                AND    XCFT.salesrep_assign_flag = 'N'
                AND    XCFT.trnsfr_batch_id||''  = p_batch_id
                AND    XCFT.ship_to_address_id   = p_ship_to_address_id
                AND    XCFT.rollup_date          = p_rollup_date ) XCT;

    BEGIN

        ln_index := gt_terr_api_error.COUNT + 1;

        FOR terr_errors_rec IN lcu_terr_errors ( p_ship_to_address_id => p_ship_to_address_id
                                                ,p_party_site_id      => p_party_site_id
                                                ,p_rollup_date        => p_rollup_date
                                                ,p_batch_id           => p_batch_id
                                                ,p_comments           => p_comments )
        LOOP

            gt_terr_api_error(ln_index).ship_to_address_id  := terr_errors_rec.ship_to_address_id;
            gt_terr_api_error(ln_index).party_site_id       := terr_errors_rec.party_site_id;
            gt_terr_api_error(ln_index).rollup_date         := terr_errors_rec.rollup_date;
            gt_terr_api_error(ln_index).source_doc_type     := terr_errors_rec.source_doc_type;
            gt_terr_api_error(ln_index).source_trx_id       := terr_errors_rec.source_trx_id;
            gt_terr_api_error(ln_index).source_trx_line_id  := terr_errors_rec.source_trx_line_id;
            gt_terr_api_error(ln_index).error_message       := terr_errors_rec.error_message;

        END LOOP;

    END add_terr_errors;

    PROCEDURE add_sra_errors ( p_ship_to_address_id IN NUMBER
                              ,p_party_site_id      IN NUMBER
                              ,p_rollup_date        IN DATE
                              ,p_resource_id        IN NUMBER
                              ,p_nam_terr_id        IN NUMBER )
    IS

        ln_index        NUMBER;

    BEGIN

        ln_index := gt_sales_rep_error.COUNT + 1;

        gt_sales_rep_error(ln_index).ship_to_address_id  := p_ship_to_address_id;
        gt_sales_rep_error(ln_index).party_site_id       := p_party_site_id;
        gt_sales_rep_error(ln_index).rollup_date         := p_rollup_date;
        gt_sales_rep_error(ln_index).resource_id         := p_resource_id;
        gt_sales_rep_error(ln_index).nam_terr_id         := p_nam_terr_id;

    END add_sra_errors;

    PROCEDURE add_rev_errors ( p_ship_to_address_id IN NUMBER
                              ,p_party_site_id      IN NUMBER
                              ,p_rollup_date        IN DATE
                              ,p_resource_id        IN NUMBER
                              ,p_role_id            IN NUMBER
                              ,p_group_id           IN NUMBER
                              ,p_salesrep_division  IN VARCHAR2
                              ,p_role_code          IN VARCHAR2
                              ,p_revenue_type       IN VARCHAR2
                              ,p_comments           IN VARCHAR2 )
    IS

        ln_index        NUMBER;

    BEGIN

        ln_index := gt_rev_type_error.COUNT + 1;

        gt_rev_type_error(ln_index).ship_to_address_id  := p_ship_to_address_id;
        gt_rev_type_error(ln_index).party_site_id       := p_party_site_id;
        gt_rev_type_error(ln_index).rollup_date         := p_rollup_date;
        gt_rev_type_error(ln_index).resource_id         := p_resource_id;
        gt_rev_type_error(ln_index).role_id             := p_role_id;
        gt_rev_type_error(ln_index).group_id            := p_group_id;
        gt_rev_type_error(ln_index).salesrep_division   := p_salesrep_division;
        gt_rev_type_error(ln_index).role_code           := p_role_code;
        gt_rev_type_error(ln_index).revenue_type        := p_revenue_type;
        gt_rev_type_error(ln_index).comments            := p_comments;

    END add_rev_errors;

    -- +===================================================================+
    -- | Name        : Get_Resources                                       |
    -- | Description : Procedure to obtain Sales Rep Assignments from the  |
    -- |               Custom Territory API                                |
    -- |                                                                   |
    -- | Parameters  : Ship_To_Address_Id    Ship_To_Address_Id            |
    -- |               Party_Site_Id         Party Site Id                 |
    -- |               Rollup_Date           Rollup Date                   |
    -- |               Batch_Id              Batch Id                      |
    -- |               Process_Audit_Id      Process Audit Id              |
    -- |                                                                   |
    -- | Returns     : Sales_Rep_Asgn_Tbl    PL/SQL Table of Records       |
    -- |               Retcode               Return Code                   |
    -- |               Errbuf                Error Buffer                  |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE get_resources ( p_ship_to_address_id IN  NUMBER
                             ,p_party_site_id      IN  NUMBER -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
                             ,p_rollup_date        IN  DATE
                             ,p_batch_id           IN  NUMBER
                             ,p_process_audit_id   IN  NUMBER
                             ,x_sales_rep_asgn_tbl OUT sales_rep_asgn_tbl_type
                             ,x_retcode            OUT NUMBER
                             ,x_errbuf             OUT VARCHAR2 )
    IS

        EX_INS_REC          EXCEPTION;

        lb_rec_ins_sts      BOOLEAN;
        lb_sales_rep_fnd    BOOLEAN;

        lc_message_data     VARCHAR2(4000);
        lc_ret_sts          VARCHAR2(10);
        lc_sr_div           VARCHAR2(100);

        ln_index            PLS_INTEGER;
        ln_message_code     NUMBER;
        ln_req_id           NUMBER       := FND_GLOBAL.Conc_Request_Id;
        ln_resource_id      NUMBER;
        ln_terr_id          NUMBER;

        lt_nam_terr_lkp_tbl xx_tm_territory_util_pkg.Nam_Terr_Lookup_Out_Tbl_Type;

    BEGIN

        xx_cn_util_pkg.WRITE       ('<<Begin GET_RESOURCES>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<Begin GET_RESOURCES>>');
        xx_cn_util_pkg.display_log ('<<Begin GET_RESOURCES>>');

        xx_cn_util_pkg.WRITE       ('GET_RESOURCES: Invoke Territory API.','LOG');
        xx_cn_util_pkg.DEBUG       ('GET_RESOURCES: Invoke Territory API.');
        xx_cn_util_pkg.display_log ('GET_RESOURCES: Invoke Territory API.');

        xx_tm_territory_util_pkg.Nam_Terr_Lookup ( p_api_version_number            => 1.0
                                                  ,p_nam_terr_id                   => NULL
                                                  ,p_resource_id                   => NULL
                                                  ,p_res_role_id                   => NULL
                                                  ,p_res_group_id                  => NULL
                                                  ,p_entity_type                   => G_ENTITY_TYPE
                                                  ,p_entity_id                     => p_party_site_id    -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
                                                  ,p_as_of_date                    => p_rollup_date
                                                  ,x_nam_terr_lookup_out_tbl_type  => lt_nam_terr_lkp_tbl
                                                  ,x_return_status                 => lc_ret_sts
                                                  ,x_message_data                  => x_errbuf );

        IF ( lc_ret_sts = FND_API.G_Ret_Sts_Error ) THEN

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0052_TERR_API_FAILURE');
            FND_MESSAGE.Set_Token ('PARTY_SITE_ID', p_party_site_id);
            FND_MESSAGE.Set_Token ('ROLLUP_DATE', p_rollup_date);
            FND_MESSAGE.Set_Token ('ERRBUF', x_errbuf);
            lc_message_data       := FND_MESSAGE.Get;

            add_terr_errors ( p_ship_to_address_id => p_ship_to_address_id
                             ,p_party_site_id      => p_party_site_id
                             ,p_rollup_date        => p_rollup_date
                             ,p_batch_id           => p_batch_id
                             ,p_comments           => lc_message_data );

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.GET_RESOURCES'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.GET_RESOURCES'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0052_TERR_API_FAILURE' );

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Get_Resources ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Get_Resources ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( p_process_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.WRITE       ('<<End GET_RESOURCES>>', 'LOG');
            xx_cn_util_pkg.DEBUG       ('<<End GET_RESOURCES>>');
            xx_cn_util_pkg.display_log ('<<End GET_RESOURCES>>');

            x_retcode := 2;
            x_errbuf  := lc_message_data;

            RETURN;

        END IF;

        xx_cn_util_pkg.DEBUG       ('GET_RESOURCES: Named Terr Lkp Tbl Count : ' || lt_nam_terr_lkp_tbl.COUNT );
        xx_cn_util_pkg.display_log ('GET_RESOURCES: Named Terr Lkp Tbl Count : ' || lt_nam_terr_lkp_tbl.COUNT );

        IF ( lt_nam_terr_lkp_tbl.COUNT = 0 ) THEN

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0053_TERR_API_NO_SR');
            FND_MESSAGE.Set_Token ('PARTY_SITE_ID', p_party_site_id);
            FND_MESSAGE.Set_Token ('ROLLUP_DATE', p_rollup_date);
            lc_message_data       := FND_MESSAGE.Get;

            add_terr_errors ( p_ship_to_address_id => p_ship_to_address_id
                             ,p_party_site_id      => p_party_site_id
                             ,p_rollup_date        => p_rollup_date
                             ,p_batch_id           => p_batch_id
                             ,p_comments           => lc_message_data );

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.GET_RESOURCES'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.GET_RESOURCES'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0053_TERR_API_NO_SR' );

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Get_Resources ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Get_Resources ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( p_process_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.WRITE       ('<<End GET_RESOURCES>>', 'LOG');
            xx_cn_util_pkg.DEBUG       ('<<End GET_RESOURCES>>');
            xx_cn_util_pkg.display_log ('<<End GET_RESOURCES>>');

            x_retcode := 0;
            x_errbuf  := lc_message_data;

            RETURN;

        END IF;

        xx_cn_util_pkg.WRITE       ('GET_RESOURCES: Fetch Resource Details for Resources Obtained from Territory API.','LOG');
        xx_cn_util_pkg.display_log ('GET_RESOURCES: Fetch Resource Details for Resources Obtained from Territory API.');

        FOR ln_index IN 1 .. lt_nam_terr_lkp_tbl.COUNT
        LOOP

            ln_resource_id   := lt_nam_terr_lkp_tbl(ln_index).resource_id;
            ln_terr_id       := lt_nam_terr_lkp_tbl(ln_index).nam_terr_id;

            xx_cn_util_pkg.DEBUG       ('GET_RESOURCES: Fetch Resource Details for Resource : ' || ln_resource_id );
            xx_cn_util_pkg.display_log ('GET_RESOURCES: Fetch Resource Details for Resource : ' || ln_resource_id );

            lb_sales_rep_fnd := FALSE;

            FOR sales_rep_details_rec IN gcu_sales_rep_details (  p_ship_to_address_id  => p_ship_to_address_id
                                                                 ,p_party_site_id       => p_party_site_id      -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
                                                                 ,p_rollup_date         => p_rollup_date
                                                                 ,p_resource_id         => ln_resource_id
                                                                 ,p_named_acct_terr_id  => ln_terr_id
                                                                 ,p_batch_id            => p_batch_id
                                                                 ,p_process_audit_id    => p_process_audit_id )
            LOOP

                lb_sales_rep_fnd := TRUE;

                lc_sr_div := sales_rep_details_rec.salesrep_division;

                xx_cn_util_pkg.DEBUG       ('GET_RESOURCES: Resource : ' || ln_resource_id || ' is a ' || lc_sr_div || ' Sales Rep.');
                xx_cn_util_pkg.display_log ('GET_RESOURCES: Resource : ' || ln_resource_id || ' is a ' || lc_sr_div || ' Sales Rep.');

                IF ( UPPER(sales_rep_details_rec.salesrep_division) <> G_SR_DIV_BSD ) THEN


                    lb_rec_ins_sts := Ins_Sales_Rep_Rec( x_sales_rep_asgn_tbl  => x_sales_rep_asgn_tbl
                                                        ,p_sales_rep_asgn_rec  => sales_rep_details_rec );

                ELSIF ( UPPER(sales_rep_details_rec.salesrep_division) = G_SR_DIV_BSD ) THEN

                    lb_rec_ins_sts := Ins_Sales_Rep_Rec( x_sales_rep_asgn_tbl  => x_sales_rep_asgn_tbl
                                                        ,p_sales_rep_asgn_rec  => sales_rep_details_rec );

                    x_sales_rep_asgn_tbl(x_sales_rep_asgn_tbl.COUNT).division := G_SR_DIV_BSD;

                    IF ( lb_rec_ins_sts ) THEN

                        lb_rec_ins_sts := Ins_Sales_Rep_Rec( x_sales_rep_asgn_tbl  => x_sales_rep_asgn_tbl
                                                            ,p_sales_rep_asgn_rec  => sales_rep_details_rec );

                        x_sales_rep_asgn_tbl(x_sales_rep_asgn_tbl.COUNT).division := G_SR_DIV_FUR;

                        IF ( lb_rec_ins_sts ) THEN

                            lb_rec_ins_sts := Ins_Sales_Rep_Rec( x_sales_rep_asgn_tbl  => x_sales_rep_asgn_tbl
                                                                ,p_sales_rep_asgn_rec  => sales_rep_details_rec );

                            x_sales_rep_asgn_tbl(x_sales_rep_asgn_tbl.COUNT).division := G_SR_DIV_DPS;

                        ELSE

                            RAISE EX_INS_REC;

                        END IF;

                    ELSE

                        RAISE EX_INS_REC;

                    END IF;

                END IF;

                IF ( lb_rec_ins_sts )  THEN

                    EXIT;

                ELSE

                    RAISE EX_INS_REC;

                END IF;

                EXIT;

                xx_cn_util_pkg.DEBUG       ('GET_RESOURCES: Sales Rep Details Fetched for Resource : ' || ln_resource_id );
                xx_cn_util_pkg.display_log ('GET_RESOURCES: Sales Rep Details Fetched for Resource : ' || ln_resource_id );

            END LOOP;

            IF ( NOT lb_sales_rep_fnd ) THEN

                ln_message_code       := -1;
                FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0054_SR_SETUP_INCORRECT');
                FND_MESSAGE.Set_Token ('RESOURCE_ID', ln_resource_id);
                lc_message_data       := FND_MESSAGE.Get;

                add_sra_errors ( p_ship_to_address_id => p_ship_to_address_id
                                ,p_party_site_id      => p_party_site_id
                                ,p_rollup_date        => p_rollup_date
                                ,p_resource_id        => ln_resource_id
                                ,p_nam_terr_id        => ln_terr_id );

                xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.GET_RESOURCES'
                                         ,p_prog_type      => G_PROG_TYPE
                                         ,p_prog_id        => ln_req_id
                                         ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.GET_RESOURCES'
                                         ,p_message        => lc_message_data
                                         ,p_code           => ln_message_code
                                         ,p_err_code       => 'XX_OIC_0054_SR_SETUP_INCORRECT' );

                xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Get_Resources ' || lc_message_data);
                xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Get_Resources ' || lc_message_data);
                xx_cn_util_pkg.update_batch ( p_process_audit_id
                                             ,SQLCODE
                                             ,lc_message_data );

            END IF;

        END LOOP;

        x_retcode := 0;
        x_errbuf  := NULL;

        xx_cn_util_pkg.WRITE       ('<<End GET_RESOURCES>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<End GET_RESOURCES>>');
        xx_cn_util_pkg.display_log ('<<End GET_RESOURCES>>');

    EXCEPTION

        WHEN EX_INS_REC THEN

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0040_INS_REC');
            lc_message_data       := FND_MESSAGE.Get;

            add_sra_errors ( p_ship_to_address_id => p_ship_to_address_id
                            ,p_party_site_id      => p_party_site_id
                            ,p_rollup_date        => p_rollup_date
                            ,p_resource_id        => ln_resource_id
                            ,p_nam_terr_id        => ln_terr_id );

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.GET_RESOURCES'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.GET_RESOURCES'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0040_INS_REC' );

            x_retcode := 2;
            x_errbuf  := lc_message_data;

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Get_Resources ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Get_Resources ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( p_process_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.WRITE       ('<<End GET_RESOURCES>>', 'LOG');
            xx_cn_util_pkg.DEBUG       ('<<End GET_RESOURCES>>');
            xx_cn_util_pkg.display_log ('<<End GET_RESOURCES>>');

        WHEN OTHERS THEN

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
            FND_MESSAGE.Set_Token ('SQL_CODE', SQLCODE);
            FND_MESSAGE.Set_Token ('SQL_ERR', SQLERRM);
            lc_message_data       := FND_MESSAGE.Get;

            add_sra_errors ( p_ship_to_address_id => p_ship_to_address_id
                            ,p_party_site_id      => p_party_site_id
                            ,p_rollup_date        => p_rollup_date
                            ,p_resource_id        => ln_resource_id
                            ,p_nam_terr_id        => ln_terr_id );

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.GET_RESOURCES'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.GET_RESOURCES'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR' );

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Get_Resources ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Get_Resources ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( p_process_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.WRITE        ('<<End GET_RESOURCES>>', 'LOG');
            xx_cn_util_pkg.DEBUG        ('<<End GET_RESOURCES>>');
            xx_cn_util_pkg.display_log  ('<<End GET_RESOURCES>>');

            x_retcode := 2;
            x_errbuf  := 'Procedure: GET_RESOURCES: ' || lc_message_data;

    END get_resources;

    -- +===================================================================+
    -- | Name        : Set_Revenue_Type                                    |
    -- | Description : Procedure to update Revenue Type for the Sales Reps |
    -- |                                                                   |
    -- | Parameters  : Process_Audit_Id      Process Audit Id              |
    -- |               Sales_Rep_Asgn_Tbl    PL/SQL Table of Records       |
    -- |                                                                   |
    -- | Returns     : Retcode               Return Code                   |
    -- |               Errbuf                Error Buffer                  |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE set_revenue_type ( p_process_audit_id   IN  NUMBER
                                ,x_sales_rep_asgn_tbl IN OUT sales_rep_asgn_tbl_type
                                ,x_retcode            OUT    NUMBER
                                ,x_errbuf             OUT    VARCHAR2 )
    IS

        TYPE rol_rec_type IS RECORD ( role_code     VARCHAR2(30)
                                     ,role_count    NUMBER
                                     ,role_error    VARCHAR2(1) );

        TYPE rol_tbl_type IS TABLE OF rol_rec_type INDEX BY VARCHAR2(240);

        TYPE rev_rec_type IS RECORD ( sr_grp        VARCHAR2(40)
                                     ,sr_count      NUMBER
                                     ,sr_division   VARCHAR2(30)
                                     ,sr_role       rol_tbl_type
                                     ,sr_error      VARCHAR2(1) );

        TYPE rev_tbl_type IS TABLE OF rev_rec_type INDEX BY VARCHAR2(240);

        TYPE sales_rep_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

        lb_skip           BOOLEAN;


        lc_am_resource    VARCHAR2(5);
        lc_bdm_resource   VARCHAR2(5);
        lc_indx           VARCHAR2(240);
        lc_message_data   VARCHAR2 (4000);
        lc_rol_indx       VARCHAR2(240);
        lc_role           VARCHAR2(40);
        lc_sr_div         VARCHAR2(30);

        ln_grp_id         NUMBER;
        ln_idx            NUMBER;
        ln_index          PLS_INTEGER;
        ln_message_code   NUMBER;
        ln_req_id         NUMBER       := FND_GLOBAL.Conc_Request_Id;
        ln_salesrep_id    NUMBER;
        ln_cntr           NUMBER;

        lt_rol_tbl        rol_tbl_type;

        lt_rev_tbl        rev_tbl_type;

        lt_sales_rep      sales_rep_tbl_type;

    BEGIN

        xx_cn_util_pkg.WRITE       ('<<Begin SET_REVENUE_TYPE>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<Begin SET_REVENUE_TYPE>>');
        xx_cn_util_pkg.display_log ('<<Begin SET_REVENUE_TYPE>>');

        xx_cn_util_pkg.WRITE       ('SET_REVENUE_TYPE: Build the Revenue Type PL/SQL Table','LOG');
        xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: Build the Revenue Type PL/SQL Table');
        xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: Build the Revenue Type PL/SQL Table');

        ln_cntr        := 0;

        FOR ln_index IN x_sales_rep_asgn_tbl.FIRST .. x_sales_rep_asgn_tbl.LAST
        LOOP

            lb_skip        := FALSE;

            lc_role        := x_sales_rep_asgn_tbl(ln_index).revenue_type;
            lc_sr_div      := x_sales_rep_asgn_tbl(ln_index).salesrep_division;

            ln_grp_id      := x_sales_rep_asgn_tbl(ln_index).group_id;
            ln_salesrep_id := x_sales_rep_asgn_tbl(ln_index).salesrep_id;

            xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: ln_salesrep_id: '||ln_salesrep_id);
            xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: ln_salesrep_id: '||ln_salesrep_id);

            lc_indx      := ln_grp_id;
            lc_rol_indx  := NVL(lc_role,'NULL');

            lt_rol_tbl.DELETE;

            lt_rev_tbl(lc_indx).sr_grp := ln_grp_id;

            xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: After Initialization');
            xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: After Initialization');

            IF ( NVL(lt_rev_tbl(lc_indx).sr_error,'N') = 'Y' ) THEN

                lb_skip  := TRUE;

            ELSIF ( lt_rev_tbl(lc_indx).sr_error IS NULL ) THEN

                lt_rev_tbl(lc_indx).sr_error := 'N';

            END IF;

            FOR ln_idx IN 1..lt_sales_rep.COUNT
            LOOP

                xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: In Loop SalesRep: '||ln_idx);
                xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: In Loop SalesRep: '||ln_idx);

                IF ( ln_salesrep_id = lt_sales_rep(ln_idx) ) THEN

                    xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: Same SalesRep');
                    xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: Same SalesRep');

                    lb_skip := TRUE;
                    EXIT;

                END IF;

            END LOOP;

            IF ( NOT lb_skip ) THEN

                xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: Assigning lt_sales_rep(ln_salesrep_id): '||ln_salesrep_id);
                xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: Assigning lt_sales_rep(ln_salesrep_id): '||ln_salesrep_id);

                ln_cntr := ln_cntr + 1;
                lt_sales_rep(ln_cntr) := ln_salesrep_id;

                xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: Assigned lt_sales_rep(ln_salesrep_id): '||ln_salesrep_id);
                xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: Assigned lt_sales_rep(ln_salesrep_id): '||ln_salesrep_id);

                lt_rev_tbl(lc_indx).sr_count := NVL(lt_rev_tbl(lc_indx).sr_count,0) + 1;

                xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: lt_sales_rep(ln_cntr): '||lt_sales_rep(ln_cntr));
                xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: lt_sales_rep(ln_cntr): '||lt_sales_rep(ln_cntr));

                IF ( lt_rev_tbl(lc_indx).sr_count > 2 ) THEN

                    lt_rev_tbl(lc_indx).sr_division := lc_sr_div;
                    lt_rev_tbl(lc_indx).sr_role     := lt_rol_tbl;
                    lt_rev_tbl(lc_indx).sr_error    := 'Y';

                    lb_skip := TRUE;

                END IF;

            END IF;

            IF ( NOT lb_skip ) THEN

                IF ( NVL(lt_rev_tbl(lc_indx).sr_division,lc_sr_div ) = lc_sr_div ) THEN

                    lt_rev_tbl(lc_indx).sr_division := lc_sr_div;

                ELSE

                    lt_rev_tbl(lc_indx).sr_division := 'NULL';
                    lt_rev_tbl(lc_indx).sr_role     := lt_rol_tbl;
                    lt_rev_tbl(lc_indx).sr_error    := 'Y';

                    lb_skip := TRUE;

                END IF;

            END IF;

            IF ( NOT lb_skip ) THEN

                IF ( lt_rev_tbl(lc_indx).sr_role.COUNT > 0 ) THEN

                     lt_rol_tbl := lt_rev_tbl(lc_indx).sr_role;

                END IF;

                lt_rol_tbl(lc_rol_indx).role_code  := NVL(lc_role,'NULL');
                lt_rol_tbl(lc_rol_indx).role_count := NVL(lt_rol_tbl(lc_rol_indx).role_count,0) + 1;
                lt_rol_tbl(lc_rol_indx).role_error := 'N';

                IF ( lc_role IS NULL ) THEN

                    lt_rol_tbl(lc_rol_indx).role_error := 'Y';

                ELSIF ( UPPER(lc_role) = G_ROLE_HSE AND lt_rol_tbl(lc_rol_indx).role_count > 1 ) THEN

                    lt_rol_tbl(lc_rol_indx).role_error := 'Y';

                ELSIF (    ( UPPER(lc_role) = G_ROLE_AM OR UPPER(lc_role) = G_ROLE_BDM )
                       AND lt_rol_tbl(lc_rol_indx).role_count = 2
                       AND NVL(lt_rol_tbl(lc_rol_indx).role_code,' ' ) = lc_role ) THEN

                    lt_rol_tbl(lc_rol_indx).role_error := 'Y';

                END IF;

                lt_rev_tbl(lc_indx).sr_role := lt_rol_tbl;

            END IF;

        END LOOP;

        xx_cn_util_pkg.WRITE       ('SET_REVENUE_TYPE: Set the Revenue Type','LOG');
        xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: Set the Revenue Type');
        xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: Set the Revenue Type');

        xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: Revenue Type Table Count : ' || lt_rev_tbl.COUNT );
        xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: Revenue Type Table Count : ' || lt_rev_tbl.COUNT );

        FOR ln_index IN x_sales_rep_asgn_tbl.FIRST .. x_sales_rep_asgn_tbl.LAST
        LOOP

            lc_role   := x_sales_rep_asgn_tbl(ln_index).revenue_type;
            lc_sr_div := x_sales_rep_asgn_tbl(ln_index).salesrep_division;

            ln_grp_id := x_sales_rep_asgn_tbl(ln_index).group_id;

            lc_indx      := ln_grp_id;
            lc_rol_indx  := NVL(lc_role,'NULL');

            xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_error : ' || lt_rev_tbl(lc_indx).sr_error );
            xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_error : ' || lt_rev_tbl(lc_indx).sr_error );

            IF ( lt_rev_tbl(lc_indx).sr_error = 'Y' ) THEN

                xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_division : ' || lt_rev_tbl(lc_indx).sr_division );
                xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_division : ' || lt_rev_tbl(lc_indx).sr_division );

                xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_count : ' || lt_rev_tbl(lc_indx).sr_count );
                xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_count : ' || lt_rev_tbl(lc_indx).sr_count );

                IF ( lt_rev_tbl(lc_indx).sr_division = 'NULL' ) THEN

                    ln_message_code       := -1;
                    FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0041_SG_DIFF_DIVS');
                    FND_MESSAGE.Set_Token ('SALES_GRP', lc_indx);
                    lc_message_data       := FND_MESSAGE.Get;

                    xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                             ,p_prog_type      => G_PROG_TYPE
                                             ,p_prog_id        => ln_req_id
                                             ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                             ,p_message        => lc_message_data
                                             ,p_code           => ln_message_code
                                             ,p_err_code       => 'XX_OIC_0041_SG_DIFF_DIVS' );

                    x_sales_rep_asgn_tbl(ln_index).revenue_type := G_REVENUE;
                    x_sales_rep_asgn_tbl(ln_index).comments     := lc_message_data;

                    add_rev_errors ( p_ship_to_address_id => x_sales_rep_asgn_tbl(ln_index).ship_to_address_id
                                    ,p_party_site_id      => x_sales_rep_asgn_tbl(ln_index).party_site_id
                                    ,p_rollup_date        => x_sales_rep_asgn_tbl(ln_index).rollup_date
                                    ,p_resource_id        => x_sales_rep_asgn_tbl(ln_index).resource_id
                                    ,p_role_id            => x_sales_rep_asgn_tbl(ln_index).resource_role_id
                                    ,p_group_id           => x_sales_rep_asgn_tbl(ln_index).group_id
                                    ,p_salesrep_division  => x_sales_rep_asgn_tbl(ln_index).salesrep_division
                                    ,p_role_code          => lc_role
                                    ,p_revenue_type       => x_sales_rep_asgn_tbl(ln_index).revenue_type
                                    ,p_comments           => x_sales_rep_asgn_tbl(ln_index).comments );

                    xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
                    xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
                    xx_cn_util_pkg.update_batch ( p_process_audit_id
                                                 ,SQLCODE
                                                 ,lc_message_data );

                ELSIF ( lt_rev_tbl(lc_indx).sr_count > 2 ) THEN

                    ln_message_code       := -1;
                    FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0042_SG_MORE_SALES_REPS');
                    FND_MESSAGE.Set_Token ('SALES_GRP', lc_indx);
                    lc_message_data       := FND_MESSAGE.Get;

                    xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                             ,p_prog_type      => G_PROG_TYPE
                                             ,p_prog_id        => ln_req_id
                                             ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                             ,p_message        => lc_message_data
                                             ,p_code           => ln_message_code
                                             ,p_err_code       => 'XX_OIC_0042_SG_MORE_SALES_REPS' );

                    x_sales_rep_asgn_tbl(ln_index).revenue_type := G_NON_REVENUE;
                    x_sales_rep_asgn_tbl(ln_index).comments     := lc_message_data;

                    add_rev_errors ( p_ship_to_address_id => x_sales_rep_asgn_tbl(ln_index).ship_to_address_id
                                    ,p_party_site_id      => x_sales_rep_asgn_tbl(ln_index).party_site_id
                                    ,p_rollup_date        => x_sales_rep_asgn_tbl(ln_index).rollup_date
                                    ,p_resource_id        => x_sales_rep_asgn_tbl(ln_index).resource_id
                                    ,p_role_id            => x_sales_rep_asgn_tbl(ln_index).resource_role_id
                                    ,p_group_id           => x_sales_rep_asgn_tbl(ln_index).group_id
                                    ,p_salesrep_division  => x_sales_rep_asgn_tbl(ln_index).salesrep_division
                                    ,p_role_code          => lc_role
                                    ,p_revenue_type       => x_sales_rep_asgn_tbl(ln_index).revenue_type
                                    ,p_comments           => x_sales_rep_asgn_tbl(ln_index).comments );

                    xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
                    xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
                    xx_cn_util_pkg.update_batch ( p_process_audit_id
                                                 ,SQLCODE
                                                 ,lc_message_data );

                END IF;

            ELSE

                xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_error : ' || lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_error );
                xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_error : ' || lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_error );

                IF ( lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_error = 'Y' ) THEN

                    xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code : ' || lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code );
                    xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code : ' || lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code );

                    IF ( lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code = 'NULL' ) THEN

                        ln_message_code       := -1;
                        FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0043_SG_NO_ROLE_CODE');
                        FND_MESSAGE.Set_Token ('SALES_GRP', lc_indx);
                        lc_message_data       := FND_MESSAGE.Get;

                        xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                                 ,p_prog_type      => G_PROG_TYPE
                                                 ,p_prog_id        => ln_req_id
                                                 ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                                 ,p_message        => lc_message_data
                                                 ,p_code           => ln_message_code
                                                 ,p_err_code       => 'XX_OIC_0043_SG_NO_ROLE_CODE' );

                        x_sales_rep_asgn_tbl(ln_index).revenue_type := G_NON_REVENUE;
                        x_sales_rep_asgn_tbl(ln_index).comments     := lc_message_data;

                        add_rev_errors ( p_ship_to_address_id => x_sales_rep_asgn_tbl(ln_index).ship_to_address_id
                                        ,p_party_site_id      => x_sales_rep_asgn_tbl(ln_index).party_site_id
                                        ,p_rollup_date        => x_sales_rep_asgn_tbl(ln_index).rollup_date
                                        ,p_resource_id        => x_sales_rep_asgn_tbl(ln_index).resource_id
                                        ,p_role_id            => x_sales_rep_asgn_tbl(ln_index).resource_role_id
                                        ,p_group_id           => x_sales_rep_asgn_tbl(ln_index).group_id
                                        ,p_salesrep_division  => x_sales_rep_asgn_tbl(ln_index).salesrep_division
                                        ,p_role_code          => lc_role
                                        ,p_revenue_type       => x_sales_rep_asgn_tbl(ln_index).revenue_type
                                        ,p_comments           => x_sales_rep_asgn_tbl(ln_index).comments );

                        xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
                        xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
                        xx_cn_util_pkg.update_batch ( p_process_audit_id
                                                     ,SQLCODE
                                                     ,lc_message_data );

                    ELSIF (  UPPER(lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code) = G_ROLE_HSE ) THEN

                        ln_message_code       := -1;
                        FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0044_SG_INVALID_HSE');
                        FND_MESSAGE.Set_Token ('SALES_GRP', lc_indx);
                        lc_message_data       := FND_MESSAGE.Get;

                        xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                                 ,p_prog_type      => G_PROG_TYPE
                                                 ,p_prog_id        => ln_req_id
                                                 ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                                 ,p_message        => lc_message_data
                                                 ,p_code           => ln_message_code
                                                 ,p_err_code       => 'XX_OIC_0044_SG_INVALID_HSE' );

                        x_sales_rep_asgn_tbl(ln_index).revenue_type := G_NON_REVENUE;
                        x_sales_rep_asgn_tbl(ln_index).comments     := lc_message_data;

                        add_rev_errors ( p_ship_to_address_id => x_sales_rep_asgn_tbl(ln_index).ship_to_address_id
                                        ,p_party_site_id      => x_sales_rep_asgn_tbl(ln_index).party_site_id
                                        ,p_rollup_date        => x_sales_rep_asgn_tbl(ln_index).rollup_date
                                        ,p_resource_id        => x_sales_rep_asgn_tbl(ln_index).resource_id
                                        ,p_role_id            => x_sales_rep_asgn_tbl(ln_index).resource_role_id
                                        ,p_group_id           => x_sales_rep_asgn_tbl(ln_index).group_id
                                        ,p_salesrep_division  => x_sales_rep_asgn_tbl(ln_index).salesrep_division
                                        ,p_role_code          => lc_role
                                        ,p_revenue_type       => x_sales_rep_asgn_tbl(ln_index).revenue_type
                                        ,p_comments           => x_sales_rep_asgn_tbl(ln_index).comments );

                        xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
                        xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
                        xx_cn_util_pkg.update_batch ( p_process_audit_id
                                                     ,SQLCODE
                                                     ,lc_message_data );

                    ELSIF (   UPPER(lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code) = G_ROLE_AM
                           OR UPPER(lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code) = G_ROLE_BDM  ) THEN

                        ln_message_code       := -1;
                        FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0045_SG_INV_ROLE_CODES');
                        FND_MESSAGE.Set_Token ('SALES_GRP', lc_indx);
                        FND_MESSAGE.Set_Token ('ROLE_CODE', lc_rol_indx);
                        lc_message_data       := FND_MESSAGE.Get;

                        xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                                 ,p_prog_type      => G_PROG_TYPE
                                                 ,p_prog_id        => ln_req_id
                                                 ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                                 ,p_message        => lc_message_data
                                                 ,p_code           => ln_message_code
                                                 ,p_err_code       => 'XX_OIC_0045_SG_INV_ROLE_CODES' );

                        x_sales_rep_asgn_tbl(ln_index).revenue_type := G_REVENUE;
                        x_sales_rep_asgn_tbl(ln_index).comments     := lc_message_data;

                        add_rev_errors ( p_ship_to_address_id => x_sales_rep_asgn_tbl(ln_index).ship_to_address_id
                                        ,p_party_site_id      => x_sales_rep_asgn_tbl(ln_index).party_site_id
                                        ,p_rollup_date        => x_sales_rep_asgn_tbl(ln_index).rollup_date
                                        ,p_resource_id        => x_sales_rep_asgn_tbl(ln_index).resource_id
                                        ,p_role_id            => x_sales_rep_asgn_tbl(ln_index).resource_role_id
                                        ,p_group_id           => x_sales_rep_asgn_tbl(ln_index).group_id
                                        ,p_salesrep_division  => x_sales_rep_asgn_tbl(ln_index).salesrep_division
                                        ,p_role_code          => lc_role
                                        ,p_revenue_type       => x_sales_rep_asgn_tbl(ln_index).revenue_type
                                        ,p_comments           => x_sales_rep_asgn_tbl(ln_index).comments );

                        xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
                        xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
                        xx_cn_util_pkg.update_batch ( p_process_audit_id
                                                     ,SQLCODE
                                                     ,lc_message_data );

                    END IF;

                ELSE

                    xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code : ' || lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code );
                    xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code : ' || lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code );

                    BEGIN

                        lc_am_resource := lt_rev_tbl(lc_indx).sr_role(G_ROLE_AM).role_code;

                    EXCEPTION

                        WHEN OTHERS THEN

                            lc_am_resource := NULL;

                    END;

                    BEGIN

                        lc_bdm_resource := lt_rev_tbl(lc_indx).sr_role(G_ROLE_BDM).role_code;

                    EXCEPTION

                        WHEN OTHERS THEN

                            lc_bdm_resource := NULL;

                    END;

                    IF (    UPPER(lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code) <> G_ROLE_SALES_SUPPORT
                        AND UPPER(lc_am_resource) = G_ROLE_AM AND UPPER(lc_bdm_resource) = G_ROLE_BDM ) THEN

                        IF ( UPPER(lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code) = G_ROLE_AM ) THEN

                            x_sales_rep_asgn_tbl(ln_index).revenue_type := G_NON_REVENUE;

                        ELSIF ( UPPER(lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code) = G_ROLE_BDM ) THEN

                            x_sales_rep_asgn_tbl(ln_index).revenue_type := G_REVENUE;

                        END IF;

                    ELSIF ( UPPER(lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code) = G_ROLE_SALES_SUPPORT ) THEN

                        x_sales_rep_asgn_tbl(ln_index).revenue_type := G_NON_REVENUE;

                    ELSIF ( UPPER(lt_rev_tbl(lc_indx).sr_role(lc_rol_indx).role_code) <> G_ROLE_SALES_SUPPORT ) THEN

                        x_sales_rep_asgn_tbl(ln_index).revenue_type := G_REVENUE;

                    END IF;

                END IF;

            END IF;

        END LOOP;

        lt_rev_tbl.DELETE;

        xx_cn_util_pkg.DEBUG       ('SET_REVENUE_TYPE: Revenue Type Table Count : ' || lt_rev_tbl.COUNT );
        xx_cn_util_pkg.display_log ('SET_REVENUE_TYPE: Revenue Type Table Count : ' || lt_rev_tbl.COUNT );

        x_retcode := 0;
        x_errbuf  := NULL;

        xx_cn_util_pkg.WRITE       ('<<End SET_REVENUE_TYPE>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<End SET_REVENUE_TYPE>>');
        xx_cn_util_pkg.display_log ('<<End SET_REVENUE_TYPE>>');

    EXCEPTION

        WHEN OTHERS THEN

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
            FND_MESSAGE.Set_Token ('SQL_CODE', SQLCODE);
            FND_MESSAGE.Set_Token ('SQL_ERR', SQLERRM);
            lc_message_data       := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SET_REVENUE_TYPE'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR' );

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Set_Revenue_Type ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( p_process_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.WRITE           ('<<End SET_REVENUE_TYPE>>', 'LOG');
            xx_cn_util_pkg.DEBUG           ('<<End SET_REVENUE_TYPE>>');
            xx_cn_util_pkg.display_log     ('<<End SET_REVENUE_TYPE>>');

            x_retcode := 2;
            x_errbuf  := 'Procedure: SET_REVENUE_TYPE: ' || lc_message_data;

    END set_revenue_type;

    -- +===================================================================+
    -- | Name        : Insert_Salesreps                                    |
    -- | Description : Procedure to obtain Sales Rep Assignments from the  |
    -- |               Custom Territory API and insert into Custom Table   |
    -- |               XX_CN_SALES_REP_ASGN                                |
    -- |                                                                   |
    -- | Parameters  : Ship_To_Address_Id    Ship To Address Id            |
    -- |               Party_Site_Id         Party Site Id                 |
    -- |               Rollup_Date           Rollup Date                   |
    -- |               Batch_Id              Batch Id                      |
    -- |               Process_Audit_Id      Process Audit Id              |
    -- |                                                                   |
    -- | Returns     : No_of_Records         No of Sales Rep Records       |
    -- |               Retcode               Return Code                   |
    -- |               Errbuf                Error Buffer                  |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE insert_salesreps ( p_ship_to_address_id IN  NUMBER
                                ,p_party_site_id      IN  NUMBER -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
                                ,p_rollup_date        IN  DATE
                                ,p_batch_id           IN  NUMBER
                                ,p_process_audit_id   IN  NUMBER
                                ,x_no_of_records      OUT NUMBER
                                ,x_retcode            OUT NUMBER
                                ,x_errbuf             OUT VARCHAR2 )
    IS

        lb_ins_sts      BOOLEAN := TRUE;

        lc_message_data VARCHAR2 (4000);

        ln_message_code NUMBER;
        ln_req_id       NUMBER  := FND_GLOBAL.Conc_Request_Id;

    BEGIN

        xx_cn_util_pkg.WRITE       ('<<Begin INSERT_SALESREPS>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<Begin INSERT_SALESREPS>>');
        xx_cn_util_pkg.display_log ('<<Begin INSERT_SALESREPS>>');

        xx_cn_util_pkg.WRITE       ('INSERT_SALESREPS: Insert Sales Rep Assignments for Party Site Id ' || p_ship_to_address_id || ' and Rollup Date ' || p_rollup_date || '.','LOG');
        xx_cn_util_pkg.display_log ('INSERT_SALESREPS: Insert Sales Rep Assignments for Party Site Id ' || p_ship_to_address_id || ' and Rollup Date ' || p_rollup_date || '.');

        xx_cn_util_pkg.WRITE       ('INSERT_SALESREPS: Invoking Get_Resources Procedure.','LOG');
        xx_cn_util_pkg.display_log ('INSERT_SALESREPS: Invoking Get_Resources Procedure.');

        Get_Resources ( p_ship_to_address_id => p_ship_to_address_id
                       ,p_party_site_id      => p_party_site_id      -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
                       ,p_rollup_date        => p_rollup_date
                       ,p_batch_id           => p_batch_id
                       ,p_process_audit_id   => p_process_audit_id
                       ,x_sales_rep_asgn_tbl => gt_sales_rep_asgn
                       ,x_retcode            => x_retcode
                       ,x_errbuf             => x_errbuf );

        xx_cn_util_pkg.DEBUG       ('INSERT_SALESREPS: Sales Rep Asgn Table Count : ' || gt_sales_rep_asgn.COUNT );
        xx_cn_util_pkg.display_log ('INSERT_SALESREPS: Sales Rep Asgn Table Count : ' || gt_sales_rep_asgn.COUNT );

        IF ( x_retcode = 0 AND gt_sales_rep_asgn.COUNT > 0 ) THEN

            xx_cn_util_pkg.WRITE       ('INSERT_SALESREPS: Invoking Set_Revenue_Type Procedure.','LOG');
            xx_cn_util_pkg.display_log ('INSERT_SALESREPS: Invoking Set_Revenue_Type Procedure.');

            Set_Revenue_Type ( p_process_audit_id   => p_process_audit_id
                              ,x_sales_rep_asgn_tbl => gt_sales_rep_asgn
                              ,x_retcode            => x_retcode
                              ,x_errbuf             => x_errbuf );

            IF ( x_retcode = 0 ) THEN

                xx_cn_util_pkg.WRITE       ('INSERT_SALESREPS: Invoking Set_Revenue_Type Procedure.','LOG');
                xx_cn_util_pkg.display_log ('INSERT_SALESREPS: Invoking Set_Revenue_Type Procedure.');

                lb_ins_sts := Ins_Sales_Reps ( x_sales_rep_asgn_tbl  => gt_sales_rep_asgn );

                IF ( lb_ins_sts ) THEN

                    COMMIT;

                    x_no_of_records := gt_sales_rep_asgn.COUNT;

                    xx_cn_util_pkg.WRITE       ('INSERT_SALESREPS: Inserted Sales Reps into the Sales Rep Assignment Table.','LOG');
                    xx_cn_util_pkg.display_log ('INSERT_SALESREPS: Inserted Sales Reps into the Sales Rep Assignment Table.');

                ELSE

                    ln_message_code      := -1;
                    FND_MESSAGE.Set_Name ('XXCRM', 'XX_OIC_0037_ERR_INS_SALES_REPS');
                    lc_message_data      := FND_MESSAGE.Get;

                    xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.INSERT_SALESREPS'
                                             ,p_prog_type      => G_PROG_TYPE
                                             ,p_prog_id        => ln_req_id
                                             ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.INSERT_SALESREPS'
                                             ,p_message        => lc_message_data
                                             ,p_code           => ln_message_code
                                             ,p_err_code       => 'XX_OIC_0037_ERR_INS_SALES_REPS' );

                    x_retcode := 2;
                    x_errbuf  := lc_message_data;

                    xx_cn_util_pkg.DEBUG        ('INSERT_SALESREPS: Error while Bulk Inserting.');
                    xx_cn_util_pkg.display_log  ('INSERT_SALESREPS: Error while Bulk Inserting.');
                    xx_cn_util_pkg.update_batch ( p_process_audit_id
                                                 ,SQLCODE
                                                 ,x_errbuf );

                END IF;

            ELSE

                ln_message_code      := -1;
                FND_MESSAGE.Set_Name ('XXCRM', 'XX_OIC_0036_ERR_REVENUE_TYPE');
                lc_message_data      := FND_MESSAGE.Get;

                xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.INSERT_SALESREPS'
                                         ,p_prog_type      => G_PROG_TYPE
                                         ,p_prog_id        => ln_req_id
                                         ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.INSERT_SALESREPS'
                                         ,p_message        => lc_message_data
                                         ,p_code           => ln_message_code
                                         ,p_err_code       => 'XX_OIC_0036_ERR_REVENUE_TYPE' );

                x_retcode := 2;
                x_errbuf  := lc_message_data;

                xx_cn_util_pkg.DEBUG        ('INSERT_SALESREPS: Error while Setting Revenue Type.');
                xx_cn_util_pkg.display_log  ('INSERT_SALESREPS: Error while Setting Revenue Type.');
                xx_cn_util_pkg.update_batch ( p_process_audit_id
                                             ,SQLCODE
                                             ,x_errbuf );

            END IF;

        ELSIF ( x_retcode = 0 AND gt_sales_rep_asgn.COUNT = 0 ) THEN

            x_no_of_records := gt_sales_rep_asgn.COUNT;

            ln_message_code      := -1;
            FND_MESSAGE.Set_Name ('XXCRM', 'XX_OIC_0035_ERR_GET_RESOURCES');
            lc_message_data      := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.INSERT_SALESREPS'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.INSERT_SALESREPS'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0035_ERR_GET_RESOURCES' );

            x_retcode := 1;
            x_errbuf  := lc_message_data;

            xx_cn_util_pkg.DEBUG        ('INSERT_SALESREPS: No Sales Reps found.');
            xx_cn_util_pkg.display_log  ('INSERT_SALESREPS: No Sales Reps found.');
            xx_cn_util_pkg.update_batch ( p_process_audit_id
                                         ,SQLCODE
                                         ,x_errbuf );

        ELSIF ( x_retcode <> 0 ) THEN


            ln_message_code      := -1;
            FND_MESSAGE.Set_Name ('XXCRM', 'XX_OIC_0035_ERR_GET_RESOURCES');
            lc_message_data      := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.INSERT_SALESREPS'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.INSERT_SALESREPS'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0035_ERR_GET_RESOURCES' );

            x_retcode := 2;
            x_errbuf  := FND_MESSAGE.Get;

            xx_cn_util_pkg.DEBUG        ('INSERT_SALESREPS: Error while Obtaining Sales Reps.');
            xx_cn_util_pkg.display_log  ('INSERT_SALESREPS: Error while Obtaining Sales Reps.');
            xx_cn_util_pkg.update_batch ( p_process_audit_id
                                         ,SQLCODE
                                         ,x_errbuf );

        END IF;

        gt_sales_rep_asgn.DELETE;

        xx_cn_util_pkg.DEBUG       ('INSERT_SALESREPS: Sales Rep Asgn Table Count : ' || gt_sales_rep_asgn.COUNT );
        xx_cn_util_pkg.display_log ('INSERT_SALESREPS: Sales Rep Asgn Table Count : ' || gt_sales_rep_asgn.COUNT );

        xx_cn_util_pkg.WRITE       ('<<End INSERT_SALESREPS>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<End INSERT_SALESREPS>>');
        xx_cn_util_pkg.display_log ('<<End INSERT_SALESREPS>>');

    EXCEPTION

        WHEN OTHERS THEN

            ROLLBACK;

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
            FND_MESSAGE.Set_Token ('SQL_CODE', SQLCODE);
            FND_MESSAGE.Set_Token ('SQL_ERR', SQLERRM);
            lc_message_data       := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.INSERT_SALESREPS'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.INSERT_SALESREPS'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR' );

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Insert_Salesreps ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Insert_Salesreps ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( p_process_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.WRITE       ('<<End INSERT_SALESREPS>>', 'LOG');
            xx_cn_util_pkg.DEBUG       ('<<End INSERT_SALESREPS>>');
            xx_cn_util_pkg.display_log ('<<End INSERT_SALESREPS>>');

            x_retcode := 2;
            x_errbuf  := 'Procedure: INSERT_SALESREPS: ' || lc_message_data;

    END insert_salesreps;

    -- +===================================================================+
    -- | Name        : Sales_Rep_Asgn_Wrker                                |
    -- | Description : Sales Rep Assignment Worker Program                 |
    -- |                                                                   |
    -- | Parameters  : Batch_Id              Batch Id                      |
    -- |               Process_Audit_Id      Process Audit Id              |
    -- |                                                                   |
    -- | Returns     : Retcode               Return Code                   |
    -- |               Errbuf                Error Buffer                  |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE sales_rep_asgn_wrker  ( x_errbuf           OUT VARCHAR2
                                     ,x_retcode          OUT NUMBER
                                     ,p_batch_id         IN  NUMBER
                                     ,p_process_audit_id IN  NUMBER )
    IS

        lc_message_data        VARCHAR2 (4000);
        lc_desc                VARCHAR2 (240);

        ld_rollup_date         DATE;
        ld_sysdate             DATE := SYSDATE;

        ln_login               NUMBER := FND_GLOBAL.Login_Id;
        ln_message_code        NUMBER;
        ln_no_of_records       NUMBER;
        ln_party_site_id       NUMBER;
        ln_proc_audit_id       NUMBER;
        ln_req_id              NUMBER := FND_GLOBAL.Conc_Request_Id;
        ln_sales_reps_exist    NUMBER;
        ln_ship_to_address_id  NUMBER;
        ln_user_id             NUMBER := FND_GLOBAL.User_Id;

        --
        -- Begin of changes
        -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
        --
        -- Following Cursor is replaced
        --
        /*CURSOR lcu_shipto_rollupdate ( p_batch_id NUMBER )
        IS
        SELECT HCAS.party_site_id
              ,XCT.ship_to_address_id
              ,XCT.rollup_date
        FROM
              ( SELECT DISTINCT
                       XCOT.ship_to_address_id
                      ,XCOT.rollup_date
                FROM   xx_cn_om_trx_v              XCOT
                WHERE  XCOT.summarized_flag      = 'N'
                AND    XCOT.salesrep_assign_flag = 'N'
                AND    XCOT.trnsfr_batch_id||''  = p_batch_id
                UNION
                SELECT DISTINCT
                       XCAT.ship_to_address_id
                      ,XCAT.rollup_date
                FROM   xx_cn_ar_trx_v              XCAT
                WHERE  XCAT.summarized_flag      = 'N'
                AND    XCAT.salesrep_assign_flag = 'N'
                AND    XCAT.trnsfr_batch_id||''  = p_batch_id
                UNION
                SELECT DISTINCT
                       XCFT.ship_to_address_id
                      ,XCFT.rollup_date
                FROM   xx_cn_fan_trx_v             XCFT
                WHERE  XCFT.summarized_flag      = 'N'
                AND    XCFT.salesrep_assign_flag = 'N'
                AND    XCFT.trnsfr_batch_id||''  = p_batch_id ) XCT
              ,hz_cust_acct_sites_all                           HCAS
        WHERE XCT.ship_to_address_id                         = HCAS.cust_acct_site_id;*/
        --
        -- Changed Cursor to fetch Party Site Id from Extract Tables
        --
        CURSOR lcu_shipto_rollupdate ( p_batch_id NUMBER )
        IS
        SELECT XCT.ship_to_address_id
              ,XCT.party_site_id
              ,XCT.rollup_date
        FROM
              ( SELECT DISTINCT
                       XCOT.ship_to_address_id
                      ,XCOT.party_site_id
                      ,XCOT.rollup_date
                FROM   xx_cn_om_trx_v              XCOT
                WHERE  XCOT.summarized_flag      = 'N'
                AND    XCOT.salesrep_assign_flag = 'N'
                AND    XCOT.trnsfr_batch_id||''  = p_batch_id
                UNION
                SELECT DISTINCT
                       XCAT.ship_to_address_id
                      ,XCAT.party_site_id
                      ,XCAT.rollup_date
                FROM   xx_cn_ar_trx_v              XCAT
                WHERE  XCAT.summarized_flag      = 'N'
                AND    XCAT.salesrep_assign_flag = 'N'
                AND    XCAT.trnsfr_batch_id||''  = p_batch_id
                UNION
                SELECT DISTINCT
                       XCFT.ship_to_address_id
                      ,XCFT.party_site_id
                      ,XCFT.rollup_date
                FROM   xx_cn_fan_trx_v             XCFT
                WHERE  XCFT.summarized_flag      = 'N'
                AND    XCFT.salesrep_assign_flag = 'N'
                AND    XCFT.trnsfr_batch_id||''  = p_batch_id ) XCT;
        --
        -- End of changes
        -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
        --

        CURSOR lcu_sales_reps_exist ( p_ship_to_address_id  NUMBER
                                     ,p_rollup_date         DATE )
        IS
        SELECT COUNT(1)                   sales_reps_exist
        FROM   xx_cn_sales_rep_asgn       XCSRA
        WHERE  XCSRA.ship_to_address_id = p_ship_to_address_id
        AND    XCSRA.rollup_date        = p_rollup_date
        AND    XCSRA.obsolete_flag      = 'N';

    BEGIN

        lc_desc                    := 'Sales Rep Assignment Worker for Batch: '|| p_batch_id;

        -- ----------------------------------
        -- Process Audit
        -- Begin Batch - Sales_Rep_Asgn_Wrker
        -- ----------------------------------

        xx_cn_util_pkg.begin_batch ( p_parent_proc_audit_id => p_process_audit_id
                                    ,x_process_audit_id     => ln_proc_audit_id
                                    ,p_request_id           => ln_req_id
                                    ,p_process_type         => G_SALES_REP_ASGN_WRKER
                                    ,p_description          => lc_desc   );

        xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_WRKER: Begin Process Audit Batch : '|| ln_proc_audit_id);
        xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: Begin Process Audit Batch : '|| ln_proc_audit_id);

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (LPAD ('Office Depot', 44));
        xx_cn_util_pkg.display_out (LPAD (G_WRKER_PROG,56));
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (RPAD ('-', 76, '-'));

        xx_cn_util_pkg.WRITE       ('<<Begin SALES_REP_ASGN_WRKER>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<Begin SALES_REP_ASGN_WRKER>>');
        xx_cn_util_pkg.display_log ('<<Begin SALES_REP_ASGN_WRKER>>');

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out ('Program Start Date : '|| TO_CHAR(ld_sysdate,'MM/DD/RRRR HH24:MI:SS') );

        xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_WRKER: Batch Size: '|| gn_xfer_batch_size);
        xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: Batch Size: '|| gn_xfer_batch_size);

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (RPAD ('Batch Id ', 19)|| ': ' || p_batch_id );
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (RPAD ('Batch Size ', 19)|| ': ' || gn_xfer_batch_size );
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out ('Recommended Batch Size is 10000 per batch');
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (LPAD ('Start of Program', 46, '*') || LPAD ('*', 30, '*'));

        xx_cn_util_pkg.WRITE       ('SALES_REP_ASGN_WRKER: DISTINCT Party Site and Rollup Date Combination','LOG');
        xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_WRKER: DISTINCT Party Site and Rollup Date Combination');
        xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: DISTINCT Party Site and Rollup Date Combination');

        FOR shipto_rollupdate_rec IN lcu_shipto_rollupdate ( p_batch_id )
        LOOP

            ln_ship_to_address_id := shipto_rollupdate_rec.ship_to_address_id;
            ln_party_site_id      := shipto_rollupdate_rec.party_site_id;
            ld_rollup_date        := shipto_rollupdate_rec.rollup_date;

            xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_WRKER: Checking if Sales Reps exist for Party Site ID : ' || ln_party_site_id || ' and Rollup Date : ' || ld_rollup_date );
            xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: Checking if Sales Reps exist for Party Site ID : ' || ln_party_site_id || ' and Rollup Date : ' || ld_rollup_date );

            FOR sales_reps_exist_rec IN lcu_sales_reps_exist ( p_ship_to_address_id  => ln_party_site_id
                                                              ,p_rollup_date         => ld_rollup_date )
            LOOP

                ln_sales_reps_exist := sales_reps_exist_rec.sales_reps_exist;

            END LOOP;

            xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_WRKER: Sales Rep Record Count : ' || ln_sales_reps_exist );
            xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: Sales Rep Record Count : ' || ln_sales_reps_exist );

            IF ( ln_sales_reps_exist = 0 ) THEN

                xx_cn_util_pkg.WRITE       ('SALES_REP_ASGN_WRKER: Obtain Sales Reps ','LOG' );
                xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: Obtain Sales Reps ' );

                Insert_Salesreps ( p_ship_to_address_id => ln_ship_to_address_id
                                  ,p_party_site_id      => ln_party_site_id      -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 05-Nov-2007
                                  ,p_rollup_date        => ld_rollup_date
                                  ,p_batch_id           => p_batch_id
                                  ,p_process_audit_id   => ln_proc_audit_id
                                  ,x_no_of_records      => ln_no_of_records
                                  ,x_retcode            => x_retcode
                                  ,x_errbuf             => x_errbuf );

                IF ( x_retcode = 0 ) THEN

                    xx_cn_util_pkg.WRITE       ('SALES_REP_ASGN_WRKER: Marking the Transactions as Sales Rep Assigned', 'LOG');
                    xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: Marking the Transactions as Sales Rep Assigned');

                    BEGIN

                        UPDATE xx_cn_om_trx                XCOT
                        SET    XCOT.salesrep_assign_flag = 'Y'
                              ,XCOT.last_updated_by      = ln_user_id
                              ,XCOT.last_update_date     = ld_sysdate
                              ,XCOT.last_update_login    = ln_login
                        WHERE  XCOT.trnsfr_batch_id      = p_batch_id
                        AND    XCOT.ship_to_address_id   = ln_ship_to_address_id
                        AND    XCOT.rollup_date          = ld_rollup_date;

                        UPDATE xx_cn_ar_trx                XCAT
                        SET    XCAT.salesrep_assign_flag = 'Y'
                              ,XCAT.last_updated_by      = ln_user_id
                              ,XCAT.last_update_date     = ld_sysdate
                              ,XCAT.last_update_login    = ln_login
                        WHERE  XCAT.trnsfr_batch_id      = p_batch_id
                        AND    XCAT.ship_to_address_id   = ln_ship_to_address_id
                        AND    XCAT.rollup_date          = ld_rollup_date;

                        UPDATE xx_cn_fan_trx               XCFT
                        SET    XCFT.salesrep_assign_flag = 'Y'
                              ,XCFT.last_updated_by      = ln_user_id
                              ,XCFT.last_update_date     = ld_sysdate
                              ,XCFT.last_update_login    = ln_login
                        WHERE  XCFT.trnsfr_batch_id      = p_batch_id
                        AND    XCFT.ship_to_address_id   = ln_ship_to_address_id
                        AND    XCFT.rollup_date          = ld_rollup_date;

                        COMMIT;

                    EXCEPTION

                        WHEN OTHERS THEN

                            ln_message_code := -1;

                            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0034_ERR_UPD_BATCHES');
                            FND_MESSAGE.Set_Token ('SQL_ERR', SQLERRM);

                            x_retcode := 2;
                            x_errbuf  := FND_MESSAGE.Get;

                            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_WRKER'
                                                     ,p_prog_type      => G_PROG_TYPE
                                                     ,p_prog_id        => ln_req_id
                                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_WRKER'
                                                     ,p_message        => lc_message_data
                                                     ,p_code           => ln_message_code
                                                     ,p_err_code       => 'XX_OIC_0034_ERR_UPD_BATCHES' );

                            xx_cn_util_pkg.DEBUG        ('SALES_REP_ASGN_WRKER: Error while updating Extract Tables.');
                            xx_cn_util_pkg.display_log  ('SALES_REP_ASGN_WRKER: Error while updating Extract Tables.');
                            xx_cn_util_pkg.update_batch ( p_process_audit_id
                                                         ,SQLCODE
                                                         ,x_errbuf );
                            RAISE;

                    END;

                    xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_WRKER: Updated Sales Rep Assignment Flag for Batch Id ' || p_batch_id );
                    xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: Updated Sales Rep Assignment Flag for Batch Id ' || p_batch_id );

                ELSIF ( x_retcode = 1 ) THEN

                    x_retcode  := 1;
                    x_errbuf   := 'Procedure: SALES_REP_ASGN_WRKER: ' || x_errbuf;

                    xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_WRKER: No Sales Reps found for the Party Site and Rollup Date.');
                    xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: No Sales Reps found for the Party Site and Rollup Date.');

                ELSIF ( x_retcode = 2 ) THEN

                    x_retcode  := 2;
                    x_errbuf   := 'Procedure: SALES_REP_ASGN_WRKER: ' || x_errbuf;

                    xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_WRKER: Error while Inserting Sales Reps.');
                    xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: Error while Inserting Sales Reps.');

                END IF;

            END IF;

            xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_WRKER: Proceed with next combination');
            xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: Proceed with next combination');

        END LOOP;

        report_error;

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (LPAD ('End of Program', 45, '*') || LPAD ('*', 31, '*'));
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (RPAD ('-', 76, '-'));

        -- ------------------
        -- End Worker Program
        -- ------------------

        xx_cn_util_pkg.WRITE       ('<<End SALES_REP_ASGN_WRKER>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<End SALES_REP_ASGN_WRKER>>');
        xx_cn_util_pkg.display_log ('<<End SALES_REP_ASGN_WRKER>>');

        xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_WRKER: End Process Audit Batch : '|| ln_proc_audit_id);
        xx_cn_util_pkg.display_log ('SALES_REP_ASGN_WRKER: End Process Audit Batch : '|| ln_proc_audit_id);

        -- --------------------------------
        -- Process Audit
        -- End Batch - Sales_Rep_Asgn_Wrker
        -- --------------------------------

        xx_cn_util_pkg.end_batch ( ln_proc_audit_id );

    EXCEPTION

        WHEN OTHERS THEN

            ROLLBACK;

            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
            FND_MESSAGE.Set_Token ('SQL_CODE', SQLCODE);
            FND_MESSAGE.Set_Token ('SQL_ERR', SQLERRM);
            lc_message_data       := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_WRKER'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_WRKER'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR' );

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Sales_Rep_Asgn_Wrker ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Sales_Rep_Asgn_Wrker ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( ln_proc_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.WRITE        ('<<End SALES_REP_ASGN_WRKER>>', 'LOG');
            xx_cn_util_pkg.DEBUG        ('<<End SALES_REP_ASGN_WRKER>>');
            xx_cn_util_pkg.display_log  ('<<End SALES_REP_ASGN_WRKER>>');

            xx_cn_util_pkg.end_batch    ( ln_proc_audit_id );

            x_retcode  := 2;
            x_errbuf   := 'Procedure: SALES_REP_ASGN_WRKER: ' || lc_message_data;
            RAISE;

    END sales_rep_asgn_wrker;

    -- +===================================================================+
    -- | Name        : Sales_Rep_Asgn_Main                                 |
    -- | Description : Sales Rep Assignment Main Program                   |
    -- |                                                                   |
    -- | Returns     : Retcode               Return Code                   |
    -- |               Errbuf                Error Buffer                  |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE sales_rep_asgn_main ( x_errbuf   OUT VARCHAR2
                                   ,x_retcode  OUT NUMBER )
    IS

        EX_INVALID_SRA_BATCH_SIZE   EXCEPTION;

        lb_request_status           BOOLEAN;

        lc_desc                     VARCHAR2(240) := NULL;
        lc_dev_phase                VARCHAR2(100) := NULL;
        lc_dev_status               VARCHAR2(100) := NULL;
        lc_message                  VARCHAR2(240) := NULL;
        lc_message_data             VARCHAR2(4000);
        lc_phase                    VARCHAR2(100) := NULL;
        lc_status                   VARCHAR2(100) := NULL;

        ld_sysdate                  DATE := SYSDATE;

        ln_batch_id                 NUMBER;
        ln_cntr                     NUMBER;
        ln_conc_req_id              NUMBER;
        ln_conc_req_index           NUMBER;
        ln_last_batch_id            NUMBER;
        ln_login                    NUMBER       := FND_GLOBAL.Login_Id;
        ln_maxwait                  NUMBER := 0;
        ln_message_code             NUMBER;
        ln_proc_audit_id            NUMBER;
        ln_req_id                   NUMBER       := FND_GLOBAL.Conc_Request_Id;
        ln_sales_rep_count          NUMBER;
        ln_sr_cntr                  NUMBER;
        ln_sra_batch_id             NUMBER;
        ln_user_id                  NUMBER       := FND_GLOBAL.User_Id;

        lt_conc_req_tbl             conc_req_tbl_type;

        CURSOR lcu_sales_rep_count
        IS
        SELECT COUNT(1)  sales_rep_count
        FROM
              ( SELECT DISTINCT
                       XCOT.ship_to_address_id
                      ,XCOT.rollup_date
                FROM   xx_cn_om_trx_v              XCOT
                WHERE  XCOT.summarized_flag      = 'N'
                AND    XCOT.salesrep_assign_flag = 'N'
                UNION
                SELECT DISTINCT
                       XCAT.ship_to_address_id
                      ,XCAT.rollup_date
                FROM   xx_cn_ar_trx_v              XCAT
                WHERE  XCAT.summarized_flag      = 'N'
                AND    XCAT.salesrep_assign_flag = 'N'
                UNION
                SELECT DISTINCT
                       XCFT.ship_to_address_id
                      ,XCFT.rollup_date
                FROM   xx_cn_fan_trx_v             XCFT
                WHERE  XCFT.summarized_flag      = 'N'
                AND    XCFT.salesrep_assign_flag = 'N' ) XCT;

        CURSOR lcu_sales_rep_batches
        IS
        SELECT XCT.ship_to_address_id
              ,XCT.rollup_date
        FROM
              ( SELECT DISTINCT
                       XCOT.ship_to_address_id
                      ,XCOT.rollup_date
                FROM   xx_cn_om_trx_v              XCOT
                WHERE  XCOT.summarized_flag      = 'N'
                AND    XCOT.salesrep_assign_flag = 'N'
                UNION
                SELECT DISTINCT
                       XCAT.ship_to_address_id
                      ,XCAT.rollup_date
                FROM   xx_cn_ar_trx_v              XCAT
                WHERE  XCAT.summarized_flag      = 'N'
                AND    XCAT.salesrep_assign_flag = 'N'
                UNION
                SELECT DISTINCT
                       XCFT.ship_to_address_id
                      ,XCFT.rollup_date
                FROM   xx_cn_fan_trx_v             XCFT
                WHERE  XCFT.summarized_flag      = 'N'
                AND    XCFT.salesrep_assign_flag = 'N' ) XCT
        ORDER BY XCT.ship_to_address_id;

        --
        -- Cursor to Get Batch Sequence
        --

        CURSOR lcu_sra_batch_id
        IS
        SELECT xx_cn_sra_batch_s.NEXTVAL sra_batch_id
        FROM   SYS.dual;

    BEGIN

        lc_desc                    := 'Sales Rep Assignment Program as on Date : ' || ld_sysdate;

        -- ---------------------------------
        -- Process Audit
        -- Begin Batch - Sales_Rep_Asgn_Main
        -- ---------------------------------

        xx_cn_util_pkg.begin_batch ( p_parent_proc_audit_id => NULL
                                    ,x_process_audit_id     => ln_proc_audit_id
                                    ,p_request_id           => ln_req_id
                                    ,p_process_type         => G_SALES_REP_ASGN_MAIN
                                    ,p_description          => lc_desc   );

        xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_MAIN: Begin Process Audit Batch : '|| ln_proc_audit_id);
        xx_cn_util_pkg.display_log ('SALES_REP_ASGN_MAIN: Begin Process Audit Batch : '|| ln_proc_audit_id);

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (LPAD ('Office Depot', 44));
        xx_cn_util_pkg.display_out (LPAD (G_MAIN_PROG,55));
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (RPAD ('-', 76, '-'));

        xx_cn_util_pkg.WRITE       ('<<Begin SALES_REP_ASGN_MAIN>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<Begin SALES_REP_ASGN_MAIN>>');
        xx_cn_util_pkg.display_log ('<<Begin SALES_REP_ASGN_MAIN>>');

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out ('Program Start Date : '|| TO_CHAR(ld_sysdate,'MM/DD/RRRR HH24:MI:SS') );

        xx_cn_util_pkg.DEBUG        ('SALES_REP_ASGN_MAIN: Checking if Batch Size from XX_CN_SRA_BATCH_SIZE is valid');
        xx_cn_util_pkg.display_log  ('SALES_REP_ASGN_MAIN: Checking if Batch Size from XX_CN_SRA_BATCH_SIZE is valid');

        IF (gn_xfer_batch_size IS NULL OR gn_xfer_batch_size <= 0) THEN

            RAISE EX_INVALID_SRA_BATCH_SIZE;

        END IF;

        xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_MAIN: Batch Size: '|| gn_xfer_batch_size);
        xx_cn_util_pkg.display_log ('SALES_REP_ASGN_MAIN: Batch Size: '|| gn_xfer_batch_size);

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (RPAD ('Batch Size ', 19)|| ': ' || gn_xfer_batch_size );
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out ('Recommended Batch Size is 10000 per batch');
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (LPAD ('Start of Program', 46, '*') || LPAD ('*', 30, '*'));

        ln_cntr    := 0;
        ln_sr_cntr := 0;

        -- -------------------------------
        -- Initialize PL/SQL Table
        --
        -- To Store Concurrent Request IDs
        -- -------------------------------

        ln_conc_req_index := 0;

        lt_conc_req_tbl.DELETE;

        -- ----------------------
        -- Launch Worker Programs
        -- ----------------------

        xx_cn_util_pkg.WRITE       ('SALES_REP_ASGN_MAIN: Launch Sales Rep Assignment Workers','LOG');
        xx_cn_util_pkg.display_log ('SALES_REP_ASGN_MAIN: Launch Sales Rep Assignment Workers');

        FOR sales_rep_count_rec IN lcu_sales_rep_count
        LOOP

            ln_sales_rep_count := sales_rep_count_rec.sales_rep_count;

        END LOOP;

        FOR sales_rep_batches_rec IN lcu_sales_rep_batches
        LOOP

            ln_cntr    := ln_cntr + 1;
            ln_sr_cntr := ln_sr_cntr + 1;

            FOR sra_batch_id_rec IN lcu_sra_batch_id
            LOOP

                ln_sra_batch_id := sra_batch_id_rec.sra_batch_id;

            END LOOP;

            ln_batch_id := CEIL(ln_sra_batch_id/gn_xfer_batch_size);
            ln_last_batch_id := ln_sra_batch_id/gn_xfer_batch_size;

            UPDATE xx_cn_om_trx              XCOT
            SET    XCOT.trnsfr_batch_id    = ln_batch_id
                  ,XCOT.last_updated_by    = ln_user_id
                  ,XCOT.last_update_date   = ld_sysdate
                  ,XCOT.last_update_login  = ln_login
            WHERE  XCOT.ship_to_address_id = sales_rep_batches_rec.ship_to_address_id
            AND    XCOT.rollup_date        = sales_rep_batches_rec.rollup_date;

            UPDATE xx_cn_ar_trx              XCAT
            SET    XCAT.trnsfr_batch_id    = ln_batch_id
                  ,XCAT.last_updated_by    = ln_user_id
                  ,XCAT.last_update_date   = ld_sysdate
                  ,XCAT.last_update_login  = ln_login
            WHERE  XCAT.ship_to_address_id = sales_rep_batches_rec.ship_to_address_id
            AND    XCAT.rollup_date        = sales_rep_batches_rec.rollup_date;

            UPDATE xx_cn_fan_trx             XCFT
            SET    XCFT.trnsfr_batch_id    = ln_batch_id
                  ,XCFT.last_updated_by    = ln_user_id
                  ,XCFT.last_update_date   = ld_sysdate
                  ,XCFT.last_update_login  = ln_login
            WHERE  XCFT.ship_to_address_id = sales_rep_batches_rec.ship_to_address_id
            AND    XCFT.rollup_date        = sales_rep_batches_rec.rollup_date;

            IF ( ln_cntr = gn_xfer_batch_size OR ln_sr_cntr = ln_sales_rep_count OR ln_batch_id = ln_last_batch_id ) THEN

                xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_MAIN: Updated the Extract Tables for Batch Id : ' || ln_batch_id );
                xx_cn_util_pkg.display_log ('SALES_REP_ASGN_MAIN: Updated the Extract Tables for Batch Id : ' || ln_batch_id );

                ln_cntr := 0;

                COMMIT;

                ln_conc_req_id := FND_REQUEST.Submit_Request( application      => G_PROG_APPLICATION
                                                             ,program          => G_WRKER_PROG_EXECUTABLE
                                                             ,sub_request      => FALSE
                                                             ,argument1        => ln_batch_id
                                                             ,argument2        => ln_proc_audit_id );
                COMMIT;

                IF ( ln_conc_req_id = 0 ) THEN

                   ROLLBACK;

                   ln_message_code := -1;
                   FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
                   FND_MESSAGE.Set_Token ('PRG_NAME', G_WRKER_PROG_EXECUTABLE);
                   FND_MESSAGE.Set_Token ('SQL_CODE', SQLCODE);
                   FND_MESSAGE.Set_Token ('SQL_ERR', SQLERRM);
                   lc_message_data       := FND_MESSAGE.Get;

                   xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_MAIN'
                                            ,p_prog_type      => G_PROG_TYPE
                                            ,p_prog_id        => ln_req_id
                                            ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_MAIN'
                                            ,p_message        => lc_message_data
                                            ,p_code           => ln_message_code
                                            ,p_err_code       => 'XX_OIC_0012_CONC_PRG_FAILED' );

                   xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Sales_Rep_Asgn_Main ' || lc_message_data);
                   xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Sales_Rep_Asgn_Main ' || lc_message_data);
                   xx_cn_util_pkg.update_batch ( ln_proc_audit_id
                                                ,SQLCODE
                                                ,lc_message_data );

                   x_retcode := 1;
                   x_errbuf  := 'Procedure: SALES_REP_ASGN_MAIN: ' || lc_message_data;

                ELSE

                   ln_conc_req_index := ln_conc_req_index + 1;

                   lt_conc_req_tbl(ln_conc_req_index) := ln_conc_req_id;

                   xx_cn_util_pkg.display_out ('');
                   xx_cn_util_pkg.display_out ('Spawned Worker Program with Request Id : ' || ln_conc_req_id || ' for Batch Id : '|| ln_batch_id );

                   xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_MAIN: Sales Rep Assignment Worker Request Id : ' || ln_conc_req_id );
                   xx_cn_util_pkg.display_log ('SALES_REP_ASGN_MAIN: Sales Rep Assignment Worker Request Id : ' || ln_conc_req_id );

                END IF;

            END IF;

        END LOOP;

        xx_cn_util_pkg.WRITE       ('SALES_REP_ASGN_MAIN: Wait for Sales Rep Assignment Workers to complete','LOG');
        xx_cn_util_pkg.display_log ('SALES_REP_ASGN_MAIN: Wait for Sales Rep Assignment Workers to complete');

        IF ( ln_conc_req_index > 0 ) THEN

            FOR ln_index IN 1 .. ln_conc_req_index
            LOOP

                ln_conc_req_id     := lt_conc_req_tbl(ln_index);

                xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_MAIN: Request Id : ' || ln_conc_req_id );
                xx_cn_util_pkg.display_log ('SALES_REP_ASGN_MAIN: Request Id : ' || ln_conc_req_id );

                lb_request_status  := FND_CONCURRENT.Wait_For_Request ( request_id => ln_conc_req_id
                                                                       ,interval   => 10
                                                                       ,max_wait   => ln_maxwait  -- Wait indefinitely
                                                                       ,phase      => lc_phase
                                                                       ,status     => lc_status
                                                                       ,dev_phase  => lc_dev_phase
                                                                       ,dev_status => lc_dev_status
                                                                       ,message    => lc_message );

                xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_MAIN: After Wait_For_Request : ' || lc_dev_status );
                xx_cn_util_pkg.display_log ('SALES_REP_ASGN_MAIN: After Wait_For_Request : ' || lc_dev_status );

                IF (   lc_dev_status = 'ERROR' OR lc_dev_status = 'TERMINATED' OR lc_dev_status = 'CANCELLED' ) THEN

                    ln_message_code := -1;

                    xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_MAIN: Status is ERROR/TERMINATED/CANCELLED ' );
                    xx_cn_util_pkg.display_log ('SALES_REP_ASGN_MAIN: Status is ERROR/TERMINATED/CANCELLED ' );

                    xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_MAIN'
                                             ,p_prog_type      => G_PROG_TYPE
                                             ,p_prog_id        => ln_req_id
                                             ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_MAIN'
                                             ,p_message        => lc_message
                                             ,p_code           => ln_message_code
                                             ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR' );

                    xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Sales_Rep_Asgn_Main : ' || lc_message);
                    xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Sales_Rep_Asgn_Main : ' || lc_message);
                    xx_cn_util_pkg.update_batch ( ln_proc_audit_id
                                                 ,SQLCODE
                                                 ,lc_message );

                    x_retcode := 1;
                    x_errbuf  := 'Procedure: SALES_REP_ASGN_MAIN: ' || lc_message;

                END IF;

                xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_MAIN: Proceed to next Worker ' );
                xx_cn_util_pkg.display_log ('SALES_REP_ASGN_MAIN: Proceed to next Worker ' );

            END LOOP;

        END IF;

        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (LPAD ('End of Program', 45, '*') || LPAD ('*', 31, '*'));
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out ('Number of Workers Spawned : ' || ln_conc_req_index );
        xx_cn_util_pkg.display_out ('');
        xx_cn_util_pkg.display_out (RPAD ('-', 76, '-'));

        -- ----------------
        -- End Main Program
        -- ----------------

        xx_cn_util_pkg.WRITE       ('<<End SALES_REP_ASGN_MAIN>>', 'LOG');
        xx_cn_util_pkg.DEBUG       ('<<End SALES_REP_ASGN_MAIN>>');
        xx_cn_util_pkg.display_log ('<<End SALES_REP_ASGN_MAIN>>');

        xx_cn_util_pkg.DEBUG       ('SALES_REP_ASGN_MAIN: End Process Audit Batch : '|| ln_proc_audit_id);
        xx_cn_util_pkg.display_log ('SALES_REP_ASGN_MAIN: End Process Audit Batch : '|| ln_proc_audit_id);

        -- -------------------------------
        -- Process Audit
        -- End Batch - Sales_Rep_Asgn_Main
        -- -------------------------------

        xx_cn_util_pkg.end_batch ( ln_proc_audit_id );

    EXCEPTION

        WHEN EX_INVALID_SRA_BATCH_SIZE THEN

            ROLLBACK;
            ln_message_code      := -1;
            FND_MESSAGE.Set_Name ('XXCRM', 'XX_OIC_0033_INVALID_SRA_SIZE');
            lc_message_data      := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_MAIN'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_MAIN'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0033_INVALID_SRA_SIZE' );

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Sales_Rep_Asgn_Main ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Sales_Rep_Asgn_Main ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( ln_proc_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.WRITE        ('<<End SALES_REP_ASGN_MAIN>>', 'LOG');
            xx_cn_util_pkg.DEBUG        ('<<End SALES_REP_ASGN_MAIN>>');
            xx_cn_util_pkg.display_log  ('<<End SALES_REP_ASGN_MAIN>>');

            xx_cn_util_pkg.end_batch    ( ln_proc_audit_id );

            x_retcode := 2;
            x_errbuf  := 'Procedure: SALES_REP_ASGN_MAIN: ' || lc_message_data;

        WHEN OTHERS THEN

            ROLLBACK;
            ln_message_code       := -1;
            FND_MESSAGE.Set_Name  ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
            FND_MESSAGE.Set_Token ('SQL_CODE', SQLCODE);
            FND_MESSAGE.Set_Token ('SQL_ERR', SQLERRM);
            lc_message_data       := FND_MESSAGE.Get;

            xx_cn_util_pkg.log_error( p_prog_name      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_MAIN'
                                     ,p_prog_type      => G_PROG_TYPE
                                     ,p_prog_id        => ln_req_id
                                     ,p_exception      => 'XX_CN_SALES_REP_ASGN_PKG.SALES_REP_ASGN_MAIN'
                                     ,p_message        => lc_message_data
                                     ,p_code           => ln_message_code
                                     ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR' );

            xx_cn_util_pkg.DEBUG        ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Sales_Rep_Asgn_Main ' || lc_message_data);
            xx_cn_util_pkg.display_log  ('ERROR: XX_CN_SALES_REP_ASGN_PKG.Sales_Rep_Asgn_Main ' || lc_message_data);
            xx_cn_util_pkg.update_batch ( ln_proc_audit_id
                                         ,SQLCODE
                                         ,lc_message_data );

            xx_cn_util_pkg.WRITE        ('<<End SALES_REP_ASGN_MAIN>>', 'LOG');
            xx_cn_util_pkg.DEBUG        ('<<End SALES_REP_ASGN_MAIN>>');
            xx_cn_util_pkg.display_log  ('<<End SALES_REP_ASGN_MAIN>>');

            xx_cn_util_pkg.end_batch    ( ln_proc_audit_id );

            x_retcode := 2;
            x_errbuf  := 'Procedure: SALES_REP_ASGN_MAIN: ' || lc_message_data;

    END sales_rep_asgn_main;

END xx_cn_sales_rep_asgn_pkg;
/

SHOW ERRORS;
