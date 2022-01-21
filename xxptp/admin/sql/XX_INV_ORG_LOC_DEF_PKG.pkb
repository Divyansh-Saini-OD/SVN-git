SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_INV_ORG_LOC_DEF_PKG

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_INV_ORG_LOC_DEF_PKG.pkb                                           |
-- | Description      : Package Body for I1308_OrgCreationProcess                            |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |Draft 1a   21-Jun-2007      Remya Sasi       Initial draft version                       |
-- |Draft 1b   03-Jul-2007      Jayshree         Reviewed and updated                        |
-- |Draft 1c   04-Jul-2007      Remya Sasi       Incorporated changes for logging errors     |
-- |Draft 1d   31-Jul-2007      Paddy Sanjeevi   Incorporated changes for not to populate    |
-- |                                             payment terms for closed stores             |
-- |1.0        28-Aug-2007      Paddy Sanjeevi   Modified to use one batchid for inserting   |
-- |                                             cdh views for conversion                    |
-- |1.1        07-Feb-2008      Paddy Sanjeevi   Modified to populate org_id in CDV views    |
-- |1.2        31-Mar-2008      Paddy Sanjeevi   Modified to activate batch_id for CHD       |
-- |1.3        14-Apr-2008      GB Nadakudhiti   Modified to update addr info in Hr_locations|
-- |1.4        14-May-2008      GB Nadakudhiti   Updating the HR organization units attr if  |
--                                                               there is an update          |
-- |1.5        04-Jan-2010      Paddy Sanjeevi   Modified to update hr_locations with        |
--                                               inventory org is null for expense org       |
-- |1.6	       05-JUL-2012	ORACLE AMS Team	 Modified code to update default X-DOCK	WH   |
-- |						 value for warehouses (CS) as 		     |
-- |						 per business request as per defect# 18117   |

-- |1.7        19-Oct-2015   Madhu Bolli          Remove schema for 12.2 retrofit            |
-- +=========================================================================================+

AS

    -- ----------------------------------------
    -- Global constants used for error handling
    -- ----------------------------------------
    G_PROG_NAME              CONSTANT VARCHAR2(50)  := 'XX_INV_ORG_LOC_DEF_PKG.PROCESS_MAIN';
    G_MODULE_NAME            CONSTANT VARCHAR2(50)  := 'INV';
    G_PROG_TYPE              CONSTANT VARCHAR2(50)  := 'CUSTOM API';
    G_NOTIFY                 CONSTANT VARCHAR2(1)   := 'Y';
    G_MAJOR                  CONSTANT VARCHAR2(15)  := 'MAJOR';
    G_MINOR                  CONSTANT VARCHAR2(15)  := 'MINOR';


  -- +========================================================================+
  -- | Name        :  LOG_ERROR                                               |
  -- |                                                                        |
  -- | Description :  This wrapper procedure calls the custom common error api|
  -- |                 with relevant parameters.                              |
  -- |                                                                        |
  -- | Parameters  :                                                          |
  -- |                p_exception IN VARCHAR2                                 |
  -- |                p_message   IN VARCHAR2                                 |
  -- |                p_code      IN NUMBER                                   |
  -- |                                                                        |
  -- +========================================================================+
    PROCEDURE LOG_ERROR (p_exception IN VARCHAR2
                         ,p_message   IN VARCHAR2
                         ,p_code      IN NUMBER
                         )
    IS

    -- ---------
    -- Constants
    -- ---------
    lc_severity VARCHAR2(15) := NULL;

    BEGIN

        IF p_code = -1 THEN
            lc_severity := G_MAJOR;
        ELSIF p_code = 1 THEN
            lc_severity := G_MINOR;
        END IF;

        XX_COM_ERROR_LOG_PUB.LOG_ERROR
                           (
                            p_program_type            => G_PROG_TYPE     --IN VARCHAR2  DEFAULT NULL
                           ,p_program_name            => G_PROG_NAME     --IN VARCHAR2  DEFAULT NULL
                           ,p_module_name             => G_MODULE_NAME   --IN VARCHAR2  DEFAULT NULL
                           ,p_error_location          => p_exception      --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message_code      => p_code           --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message           => p_message        --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message_severity  => lc_severity      --IN VARCHAR2  DEFAULT NULL
                           ,p_notify_flag             => G_NOTIFY        --IN VARHCAR2  DEFAULT NULL
                           );

    END LOG_ERROR;

  -- +=========================================================================+
  -- |                                                                         |
  -- |                                                                         |
  -- |PROCEDURE   : Process_Main                                               |
  -- |                                                                         |
  -- |DESCRIPTION : This procedure will pick data from Custom Staging          |
  -- |              Table xx_inv_org_loc_def_stg and insert or update          |
  -- |              corresponding data into the Custom RMS attributes table    |
  -- |              ,the CDH Staging Tables and HR_LOCATIONS table with        |
  -- |              appropriate values for the inventory organization records  |
  -- |              being processed.                                           |
  -- |                                                                         |
  -- |                                                                         |
  -- |                                                                         |
  -- |PARAMETERS  :                                                            |
  -- |                                                                         |
  -- |    NAME          Mode    TYPE        DESCRIPTION                        |
  -- |---------------  ------  ---------- -------------------------            |
  -- |                                                                         |
  -- | x_message_data   OUT     VARCHAR2   Returns Error Message               |
  -- | x_message_code   OUT     NUMBER     Returns Error Code                  |
  -- | p_action_type    IN      VARCHAR2   To determine if Conversion/Interface|
  -- | p_bpel_inst_id   IN      VARCHAR2   BPEL Instance ID for Interface      |
  -- +=========================================================================+


    PROCEDURE Process_Main(
                            x_message_data  OUT VARCHAR2
                           ,x_message_code  OUT NUMBER
                           ,p_action_type   IN  VARCHAR2
                           ,p_bpel_inst_id  IN  NUMBER DEFAULT NULL
                           )
    IS
    -- ===============================================
    -- Cursor to pick records to be processed from the
    -- Staging Table
    -- ===============================================
    CURSOR  lcu_rec_process (p_bpel_instance_id  IN  NUMBER
                            ,p_axn_type          IN  VARCHAR2
                            ,p_proc_flag         IN  NUMBER)
    IS
    SELECT  *
    FROM    xx_inv_org_loc_def_stg
    WHERE   action_type         = p_axn_type
    AND     process_flag        = p_proc_flag
    UNION
    SELECT  *
    FROM    xx_inv_org_loc_def_stg
    WHERE   bpel_instance_id     = p_bpel_instance_id;
    -- ==============================================
    -- Cursor to pick latest existing record in RMS
    -- Attribute table for a given organization
    -- ==============================================
    CURSOR  lcu_rec_attrib (p_org_name  IN  VARCHAR2
                            ,p_loc_num  IN  NUMBER)
    IS
    SELECT  combination_id
    FROM    xx_inv_org_loc_rms_attribute
    WHERE   name_sw             = p_org_name
    AND     location_number_sw  = p_loc_num
    ORDER BY last_update_date desc;
    -- ==============================================
    -- Cursor to get structure id for given org_type
    -- ==============================================
    CURSOR  lcu_str_id  (p_org_type   IN  VARCHAR2)
    IS
    SELECT  id_flex_num
    FROM    fnd_id_flex_structures
    WHERE   id_flex_structure_code = DECODE(p_org_type
                                    ,'STORE','RMS Org Location Attribute'
                                    ,'WH','RMS WH Org Attribute');
    -- ======================================
    -- Cursor to get existing record from
    -- HR_LOCATIONS for a given organization
    -- ======================================
    CURSOR  lcu_rec_hr_loc  (p_name IN  VARCHAR2,p_country IN VARCHAR2)
    IS
    SELECT  location_id
           ,object_version_number
    FROM    hr_locations
    WHERE   substr(location_code,1,6) = p_name
    AND     country=p_country;

    -- =============================
    -- Local Variable Declaration
    -- =============================
    ln_bpel_instance_id         NUMBER;
    ln_proc_flag                NUMBER;
    ln_rms_comb_id              NUMBER;
    ln_structure_id             NUMBER;

    ln_obj_ver_num              NUMBER;
    ln_tot_count                NUMBER;
    ln_proc_count               NUMBER;
    ln_error_count              NUMBER;
    ln_location_id              NUMBER;
    ln_process_flag             NUMBER;
    lc_error_loc                VARCHAR2(500);
    lc_error_flag               VARCHAR2(3);
    lc_axn_type                 VARCHAR2(3);
    ex_incorrect_action         EXCEPTION;
    ex_no_location              EXCEPTION;
    ex_process_error            EXCEPTION;
    g_batch_id                    NUMBER;
    l_message                     VARCHAR2(500);
    lc_api_ret_status           VARCHAR2(20);
    ln_api_msg_count            NUMBER;
    lc_api_msg_data             VARCHAR2(500);
    v_order_cutoff_time           VARCHAR2(10) ;
    v_region2                     VARCHAR2(120);
    v_region1                     VARCHAR2(120);
    v_org_count                   NUMBER   :=0 ;
    v_ins_flag            VARCHAR2(1):='N';
    v_cnt            NUMBER;
   BEGIN
        ----------------------------
        -- Validating Action Type --
        ----------------------------
        FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Validating Action Type : '||p_action_type);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------');
        IF p_action_type = 'I' and p_bpel_inst_id IS NOT NULL THEN
            -- Assigning values incase of Interface
            FND_FILE.PUT_LINE(FND_FILE.LOG,'..Assigning values incase of Interface');
            ln_bpel_instance_id := p_bpel_inst_id;
            lc_axn_type         := NULL;
            ln_proc_flag        := NULL;
        ELSIF p_action_type = 'C' THEN
            -- Assigning values incase of Conversion
            FND_FILE.PUT_LINE(FND_FILE.LOG,'..Assigning values incase of Conversion');
            ln_bpel_instance_id := NULL;
            lc_axn_type         := p_action_type;
            ln_proc_flag        := 1;
        ELSE
            RAISE ex_incorrect_action;
        END IF;
        -------------------------------------------------
        -- Processing Valid Records from Staging Table --
        -------------------------------------------------
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'-- Processing Valid Records from Staging Table --');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------');
        ln_tot_count    := 0;
        ln_proc_count   := 0;
        ln_error_count  := 0;
        FOR lcr_rec_process IN lcu_rec_process(
                         p_bpel_instance_id  => ln_bpel_instance_id
                        ,p_axn_type          => lc_axn_type
                        ,p_proc_flag         => ln_proc_flag)
        LOOP
            BEGIN
                ln_tot_count            := ln_tot_count + 1 ;
                lc_error_flag           := 'S'            ;
--        v_cnt            :=0;
        v_ins_flag        :='N';
                ln_rms_comb_id          := NULL           ;
                lc_error_loc            := NULL           ;

                    v_order_cutoff_time := NULL           ;
                    v_org_count         := 0              ;
                ------------------------------------------------------
                -- Populating RMS Attributes and CDH Staging Tables --
                ------------------------------------------------------
                FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  In loop for Control ID :'||lcr_rec_process.control_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  ------------------------------------------------------');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  -- Processing RMS Attributes and CDH Staging Tables --');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  ------------------------------------------------------');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..Getting Structure ID based on org type');
                -- Getting Structure ID based on org type --
                OPEN lcu_str_id(lcr_rec_process.org_type);
                FETCH lcu_str_id INTO ln_structure_id;
                IF lcu_str_id%NOTFOUND THEN
                    ln_structure_id := NULL;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  - Structure ID does not exist');
                END IF;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  - Structure ID :'||ln_structure_id);
                CLOSE lcu_str_id;
                -- Derive the time portion for Order cutoff Date
                BEGIN
                  IF lcr_rec_process.od_ord_cutoff_tm_sw IS NOT NULL THEN
                    v_order_cutoff_time := TO_CHAR(lcr_rec_process.od_ord_cutoff_tm_sw,'HH24:MI');
                  END IF;
                 EXCEPTION
                  WHEN OTHERS THEN
                    v_order_cutoff_time := NULL;
                 END;
                    -- Order Cutoff date derivation complete.
                --
                    IF lcr_rec_process.country_id_sw IS NOT NULL THEN
                  --
                  SELECT COUNT(1)
                                INTO v_org_count
                                FROM hr_locations
                       WHERE SUBSTR(location_code,1,6) = LPAD(lcr_rec_process.location_number_sw,6,0)
                     AND country = lcr_rec_process.country_id_sw  ;
                  --
                  IF v_org_count >1 THEN
                    -- Raise Exception
                            lc_error_flag := 'E';
                    lc_error_loc := 'More than 1 Loc/country Combination exist';
                    RAISE ex_process_error;
                    --
                  END IF;
                  --
                    ELSE
                  -- Raise Exception
                      lc_error_flag := 'E';
                  lc_error_loc := 'Country Id is NULL';
                  RAISE ex_process_error;
                  --
                END IF;
                --
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..Checking if record exist in RMS Attribute table');
                -- Checking if record exist in RMS table
                OPEN lcu_rec_attrib(p_org_name  => lcr_rec_process.org_name_sw
                                    ,p_loc_num   => lcr_rec_process.location_number_sw
                                    );
                FETCH lcu_rec_attrib INTO ln_rms_comb_id;
                IF lcu_rec_attrib%NOTFOUND THEN
                    ln_rms_comb_id := NULL;
            v_ins_flag:='Y';
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  - RMS attribute record does not exist');
                END IF;
                CLOSE lcu_rec_attrib;
                IF ln_rms_comb_id IS NOT NULL THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  - RMS attribute exists with Combination ID :'||ln_rms_comb_id);
                    -- When Record Exists in RMS attribute Table --
                    BEGIN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..Updating Latest Existing Record in RMS Attribute Table ');
                        ------------------------------------------------------------
                        -- Updating Latest Existing Record in RMS Attribute Table --
                        ------------------------------------------------------------
                        UPDATE  xx_inv_org_loc_rms_attribute
                        SET     structure_id                =   ln_structure_id
                               ,enabled_flag                =   'Y'
                               ,summary_flag                =   'N'
                               ,od_type_sw                  =   lcr_rec_process.od_type_cd_sw
                               ,last_update_date            =   SYSDATE
                               ,last_updated_by             =   FND_GLOBAL.user_id
                               ,country_id_sw               =   lcr_rec_process.country_id_sw
                               ,orig_currency_code          =   lcr_rec_process.orig_currency_code_sw
                               ,mgr_name_sw                 =   lcr_rec_process.mgr_name_sw
                               ,fax_number_sw               =   lcr_rec_process.fax_number_sw
                               ,phone_number_sw             =   lcr_rec_process.phone_number_sw
                               ,email_sw                    =   lcr_rec_process.email_sw
                               ,od_cross_street_dir_1_sw    =   lcr_rec_process.od_cross_street_dir_1_sw
                               ,od_cross_street_dir_2_sw    =   lcr_rec_process.od_cross_street_dir_2_sw
                               ,time_zone_sw                =   lcr_rec_process.time_zone_sw
                               ,od_city_limits_flg_s        =   lcr_rec_process.od_city_limits_flg_s
                               ,store_class_s               =   lcr_rec_process.store_class_s
                               ,format_s                    =   lcr_rec_process.format_s
                               ,district_sw                 =   lcr_rec_process.district_sw
                               ,od_division_id_sw           =   lcr_rec_process.od_division_id_sw
                               ,od_sub_type_cd_sw           =   lcr_rec_process.od_sub_type_cd_sw
                               ,open_date_sw                =   lcr_rec_process.open_date_sw
                               ,close_date_sw               =   lcr_rec_process.close_date_sw
                               ,default_wh_sw               =   NVL(lcr_rec_process.default_wh_sw,lcr_rec_process.od_defaultcrossdock_sw)   -- As Per Ver 1.6
                               ,od_default_wh_csc_s         =   lcr_rec_process.od_default_wh_csc_s
                               ,od_mkt_open_date_s          =   lcr_rec_process.od_mkt_open_date_s
                               ,start_order_days_s          =   lcr_rec_process.start_order_days_s
                               ,stop_order_days_s           =   lcr_rec_process.stop_order_days_s
                               ,od_closing_store_ind_s      =   lcr_rec_process.od_closing_store_ind_s
                               ,od_model_tax_loc_sw         =   lcr_rec_process.od_model_tax_loc_sw
                               ,od_loc_brand_cd_sw          =   lcr_rec_process.od_loc_brand_cd_sw
                               ,od_geo_cd_sw                =   lcr_rec_process.od_geo_cd_sw
                               ,od_bts_flight_id_sw         =   lcr_rec_process.od_bts_flight_id_sw
                               ,od_ad_mkt_id_sw             =   lcr_rec_process.od_ad_mkt_id_sw
                               ,channel_id_sw               =   lcr_rec_process.channel_id_sw
                               ,transaction_no_generated_s  =   lcr_rec_process.transaction_no_generated_s
                               ,od_remerch_ind_s            =   lcr_rec_process.od_remerch_ind_s
                               ,od_sister_store1_sw         =   lcr_rec_process.od_sister_store1_sw
                               ,od_sister_store2_sw         =   lcr_rec_process.od_sister_store2_sw
                               ,od_sister_store3_sw         =   lcr_rec_process.od_sister_store3_sw
                               ,od_cross_dock_lead_time_sw  =   lcr_rec_process.od_cross_dock_lead_time_sw
                               ,od_ord_cutoff_tm_sw         =   lcr_rec_process.od_ord_cutoff_tm_sw
                               ,od_delivery_cd_sw           =   lcr_rec_process.od_delivery_cd_sw
                               ,od_routing_cd_sw            =   lcr_rec_process.od_routing_cd_sw
                               ,od_reloc_id_sw              =   lcr_rec_process.od_reloc_id_sw
                               ,total_square_feet_s         =   lcr_rec_process.total_square_feet_s
                               ,break_pack_ind_w            =   lcr_rec_process.break_pack_ind_w
                               ,delivery_policy_w           =   lcr_rec_process.delivery_policy_w
                               ,od_expanded_mix_flg_w       =   lcr_rec_process.od_expanded_mix_flg_w
                               ,od_default_import_wh_w      =   lcr_rec_process.od_default_import_wh_w
                               ,od_external_wms_system_w    =   lcr_rec_process.od_external_wms_system_w
                               ,protected_ind_w             =   lcr_rec_process.protected_ind_w
                               ,forecast_wh_ind_w           =   lcr_rec_process.forecast_wh_ind_w
                               ,repl_ind_w                  =   lcr_rec_process.repl_ind_w
                               ,repl_srs_ord_w              =   lcr_rec_process.repl_srs_ord_w
                               ,restricted_ind_w            =   lcr_rec_process.restricted_ind_w
                               ,pickup_delivery_cutoff_sw   =   lcr_rec_process.pickup_delivery_cutoff_sw
                               ,sameday_delivery_sw         =   lcr_rec_process.sameday_delivery_sw
                               ,furniture_cutoff_sw         =   lcr_rec_process.furniture_cutoff_sw
                               ,od_whse_org_cd_sw           =   lcr_rec_process.od_whse_org_cd_sw
                               ,org_type                    =   lcr_rec_process.org_type
                                         ,segment2                              =   v_order_cutoff_time
                        WHERE   combination_id              =   ln_rms_comb_id;
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..Updating rms_attribute_flag/update in Inv Org Staging Table');

                        -- Updating Flag in Inv Org Staging Table
                        UPDATE  xx_inv_org_loc_def_stg
                        SET     rms_attribute_updated_flag  = 'Y'
                               ,process_action              = 'UPDATE'
                               ,update_date                 = SYSDATE
                               ,updated_by                  = FND_GLOBAL.user_id
                        WHERE   control_id                  = lcr_rec_process.control_id;
                        
                        UPDATE  xx_inv_org_loc_rms_attribute                    -- As Per Ver 1.6
                        SET     default_wh_sw               =   NVL(lcr_rec_process.default_wh_sw,lcr_rec_process.od_defaultcrossdock_sw)
                        WHERE   location_number_sw=lcr_rec_process.location_number_sw;
                        
                        
                        --
                        -- Updating the org descriptive flexfield segments
                        --
                         UPDATE hr_all_organization_units
                            SET attribute2 = lcr_rec_process.district_sw
                               ,attribute3 = lcr_rec_process.open_date_sw
                               ,attribute4 = lcr_rec_process.close_date_sw
                               ,attribute5 = lcr_rec_process.country_id_sw
                               ,last_updated_by = FND_GLOBAL.user_id
                               ,last_update_date = SYSDATE
                          WHERE name = LPAD (lcr_rec_process.location_number_sw, 6, 0)||':'||lcr_rec_process.org_name_sw ;
                        --
                    EXCEPTION
                    WHEN OTHERS THEN
                        lc_error_flag := 'E';
                        lc_error_loc := 'updating RMS Attribute Table';
                        RAISE ex_process_error;
                    END;
                ELSE
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  - When Record Does not exist in RMS attribute Table');
                    -- When Record Does not exist in RMS attribute Table
                    -- Getting New Combination Id
                    SELECT  xx_inv_org_loc_rms_attribute_s.NEXTVAL
                    INTO    ln_rms_comb_id
                    FROM    SYS.DUAL;
                    BEGIN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..Inserting a new record into the RMS Attribute table');
                        ---------------------------------------------------------
                        -- Inserting a new record into the RMS Attribute table --
                        ---------------------------------------------------------
                        INSERT INTO xx_inv_org_loc_rms_attribute
                                   (combination_id
                                   ,structure_id
                                   ,enabled_flag
                                   ,summary_flag
                                   ,name_sw
                                   ,od_type_sw
                                   ,location_number_sw
                                   ,last_update_date
                                   ,last_updated_by
                                   ,country_id_sw
                                   ,orig_currency_code
                                   ,mgr_name_sw
                                   ,fax_number_sw
                                   ,phone_number_sw
                                   ,email_sw
                                   ,od_cross_street_dir_1_sw
                                   ,od_cross_street_dir_2_sw
                                   ,time_zone_sw
                                   ,od_city_limits_flg_s
                                   ,store_class_s
                                   ,format_s
                                   ,district_sw
                                   ,od_division_id_sw
                                   ,od_sub_type_cd_sw
                                   ,open_date_sw
                                   ,close_date_sw
                                   ,default_wh_sw
                                   ,od_default_wh_csc_s
                                   ,od_mkt_open_date_s
                                   ,start_order_days_s
                                   ,stop_order_days_s
                                   ,od_closing_store_ind_s
                                   ,od_model_tax_loc_sw
                                   ,od_loc_brand_cd_sw
                                   ,od_geo_cd_sw
                                   ,od_bts_flight_id_sw
                                   ,od_ad_mkt_id_sw
                                   ,channel_id_sw
                                   ,transaction_no_generated_s
                                   ,od_remerch_ind_s
                                   ,od_sister_store1_sw
                                   ,od_sister_store2_sw
                                   ,od_sister_store3_sw
                                   ,od_cross_dock_lead_time_sw
                                   ,od_ord_cutoff_tm_sw
                                   ,od_delivery_cd_sw
                                   ,od_routing_cd_sw
                                   ,od_reloc_id_sw
                                   ,total_square_feet_s
                                   ,break_pack_ind_w
                                   ,delivery_policy_w
                                   ,od_expanded_mix_flg_w
                                   ,od_default_import_wh_w
                                   ,od_external_wms_system_w
                                   ,protected_ind_w
                                   ,forecast_wh_ind_w
                                   ,repl_ind_w
                                   ,repl_srs_ord_w
                                   ,restricted_ind_w
                                   ,pickup_delivery_cutoff_sw
                                   ,sameday_delivery_sw
                                   ,furniture_cutoff_sw
                                   ,od_whse_org_cd_sw
                                   ,org_type
                                             ,segment2
                                    )
                            VALUES( ln_rms_comb_id
                                   ,ln_structure_id
                                   ,'Y'
                                   ,'N'
                                   ,lcr_rec_process.org_name_sw
                                   ,lcr_rec_process.od_type_cd_sw
                                   ,lcr_rec_process.location_number_sw
                                   ,SYSDATE
                                   ,FND_GLOBAL.user_id
                                   ,lcr_rec_process.country_id_sw
                                   ,lcr_rec_process.orig_currency_code_sw
                                   ,lcr_rec_process.mgr_name_sw
                                   ,lcr_rec_process.fax_number_sw
                                   ,lcr_rec_process.phone_number_sw
                                   ,lcr_rec_process.email_sw
                                   ,lcr_rec_process.od_cross_street_dir_1_sw
                                   ,lcr_rec_process.od_cross_street_dir_2_sw
                                   ,lcr_rec_process.time_zone_sw
                                   ,lcr_rec_process.od_city_limits_flg_s
                                   ,lcr_rec_process.store_class_s
                                   ,lcr_rec_process.format_s
                                   ,lcr_rec_process.district_sw
                                   ,lcr_rec_process.od_division_id_sw
                                   ,lcr_rec_process.od_sub_type_cd_sw
                                   ,lcr_rec_process.open_date_sw
                                   ,lcr_rec_process.close_date_sw
                                   ,NVL(lcr_rec_process.default_wh_sw,lcr_rec_process.od_defaultcrossdock_sw)  ---- As Per Ver 1.6
                                   ,lcr_rec_process.od_default_wh_csc_s
                                   ,lcr_rec_process.od_mkt_open_date_s
                                   ,lcr_rec_process.start_order_days_s
                                   ,lcr_rec_process.stop_order_days_s
                                   ,lcr_rec_process.od_closing_store_ind_s
                                   ,lcr_rec_process.od_model_tax_loc_sw
                                   ,lcr_rec_process.od_loc_brand_cd_sw
                                   ,lcr_rec_process.od_geo_cd_sw
                                   ,lcr_rec_process.od_bts_flight_id_sw
                                   ,lcr_rec_process.od_ad_mkt_id_sw
                                   ,lcr_rec_process.channel_id_sw
                                   ,lcr_rec_process.transaction_no_generated_s
                                   ,lcr_rec_process.od_remerch_ind_s
                                   ,lcr_rec_process.od_sister_store1_sw
                                   ,lcr_rec_process.od_sister_store2_sw
                                   ,lcr_rec_process.od_sister_store3_sw
                                   ,lcr_rec_process.od_cross_dock_lead_time_sw
                                   ,lcr_rec_process.od_ord_cutoff_tm_sw
                                   ,lcr_rec_process.od_delivery_cd_sw
                                   ,lcr_rec_process.od_routing_cd_sw
                                   ,lcr_rec_process.od_reloc_id_sw
                                   ,lcr_rec_process.total_square_feet_s
                                   ,lcr_rec_process.break_pack_ind_w
                                   ,lcr_rec_process.delivery_policy_w
                                   ,lcr_rec_process.od_expanded_mix_flg_w
                                   ,lcr_rec_process.od_default_import_wh_w
                                   ,lcr_rec_process.od_external_wms_system_w
                                   ,lcr_rec_process.protected_ind_w
                                   ,lcr_rec_process.forecast_wh_ind_w
                                   ,lcr_rec_process.repl_ind_w
                                   ,lcr_rec_process.repl_srs_ord_w
                                   ,lcr_rec_process.restricted_ind_w
                                   ,lcr_rec_process.pickup_delivery_cutoff_sw
                                   ,lcr_rec_process.sameday_delivery_sw
                                   ,lcr_rec_process.furniture_cutoff_sw
                                   ,lcr_rec_process.od_whse_org_cd_sw
                                   ,lcr_rec_process.org_type
                                             ,v_order_cutoff_time
                                    );
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..Updating rms_attribute_flag/Create in Inv Org Staging Table ');
                        -- Updating Flag in Inv Org Staging Table
                        UPDATE  xx_inv_org_loc_def_stg
                        SET     rms_attribute_created_flag  = 'Y'
                               ,process_action              = 'CREATE'
                               ,update_date                 = SYSDATE
                               ,updated_by                  = FND_GLOBAL.user_id
                        WHERE   control_id                  = lcr_rec_process.control_id;
                    EXCEPTION
                    WHEN OTHERS THEN
                        lc_error_flag := 'E';
                        lc_error_loc  := 'creating a new record in RMS Attribute Table';
                        RAISE ex_process_error;
                    END;

                END IF;
                -- ------------------------- --
                --   Updating HR_LOCATIONS   --
                -- ------------------------- --
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  -- ------------------------- -- ');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  --   Updating HR_LOCATIONS   -- ');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'  -- ------------------------- -- ');
                v_region2:= NULL;
                    v_region1:= NULL;
                BEGIN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..Checking if record exists in HR_LOCATIONS');
                    -- Checking if record exists in HR_LOCATIONS

                  OPEN lcu_rec_hr_loc (LPAD(lcr_rec_process.location_number_sw, 6,0),lcr_rec_process.country_id_sw);
                  FETCH lcu_rec_hr_loc INTO ln_location_id, ln_obj_ver_num;
                  IF lcu_rec_hr_loc%NOTFOUND THEN
                     lc_error_flag  := 'E';
                     RAISE ex_no_location;
                  END IF;
                  CLOSE lcu_rec_hr_loc;
                  --
                      IF lcr_rec_process.country_id_sw ='US' THEN
                   v_region2 := lcr_rec_process.state_sw  ;
                         v_region1 := lcr_rec_process.county_sw ;
                  ELSE
                   v_region2 := NULL                       ;
                   v_region1 := lcr_rec_process.state_sw ;
                  END IF;
                  --
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'  - When record exists in HR_LOCATIONS');
                  -- If record exists in HR_LOCATIONS
                  -- Updating HR_LOCATIONS using Standard API
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'..Updating HR_LOCATIONS using Standard API for'||to_char(ln_location_id));

                  FND_FILE.PUT_LINE(FND_FILE.LOG,' INS FLAG '||v_ins_flag);


          IF v_ins_flag='Y' THEN

                  SELECT COUNT(1)
               INTO v_cnt
               FROM hr_all_organization_units b,
                hr_locations_all a
              WHERE SUBSTR(a.location_code,1,6)=TO_CHAR(LPAD(lcr_rec_process.location_number_sw, 6,0))
            AND SUBSTR(a.location_code,1,6)=LPAD(b.attribute1,6,0)
            AND b.organization_id=a.inventory_organization_id
            AND SUBSTR(b.name,1,6)=SUBSTR(a.location_code,1,6);

                  FND_FILE.PUT_LINE(FND_FILE.LOG,' V_cnt '||to_char(v_cnt));

              IF v_cnt=0 THEN
             BEGIN

                    HR_LOCATION_API.update_location
                            (
                             p_effective_date       => SYSDATE
                            ,p_location_id          => ln_location_id
                            ,p_object_version_number=> ln_obj_ver_num
                            ,p_address_line_1       => lcr_rec_process.add1_sw
                            ,p_address_line_2       => lcr_rec_process.add2_sw
                            ,p_town_or_city         => lcr_rec_process.city_sw
                ,p_inventory_organization_id => NULL
                            ,p_region_1             => v_region1 --lcr_rec_process.county_sw
                            ,p_region_2             => v_region2 --lcr_rec_process.state_sw
                            ,p_postal_code          => lcr_rec_process.pcode_sw
                            ,p_loc_information15    => lcr_rec_process.mgr_name_sw
                            ,p_telephone_number_2   => lcr_rec_process.fax_number_sw
                            ,p_telephone_number_1   => lcr_rec_process.phone_number_sw
                            ,p_loc_information16    => lcr_rec_process.email_sw
                            ,p_loc_information17    => lcr_rec_process.od_cross_street_dir_1_sw||' '||lcr_rec_process.od_cross_street_dir_2_sw
                            ,p_loc_information14    => lcr_rec_process.od_city_limits_flg_s
                            );
                     EXCEPTION
                       WHEN others THEN
                         LOG_ERROR(p_exception => 'EX_PROCESS_ERROR'
                              ,p_message   => sqlerrm
                              ,p_code      => -1
                              );
             END;
               END IF;
          END IF;

                  BEGIN
 
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'--'||lcr_rec_process.add2_sw);

                    HR_LOCATION_API.update_location
                            (
                             p_effective_date       => SYSDATE
                            ,p_location_id          => ln_location_id
                            ,p_object_version_number=> ln_obj_ver_num
                            ,p_address_line_1       => lcr_rec_process.add1_sw
                            ,p_address_line_2       => lcr_rec_process.add2_sw
                            ,p_town_or_city         => lcr_rec_process.city_sw
                            ,p_region_1             => v_region1 --lcr_rec_process.county_sw
                            ,p_region_2             => v_region2 --lcr_rec_process.state_sw
                            ,p_postal_code          => lcr_rec_process.pcode_sw
                            ,p_loc_information15    => lcr_rec_process.mgr_name_sw
                            ,p_telephone_number_2   => lcr_rec_process.fax_number_sw
                            ,p_telephone_number_1   => lcr_rec_process.phone_number_sw
                            ,p_loc_information16    => lcr_rec_process.email_sw
                            ,p_loc_information17    => lcr_rec_process.od_cross_street_dir_1_sw||' '||lcr_rec_process.od_cross_street_dir_2_sw
                            ,p_loc_information14    => lcr_rec_process.od_city_limits_flg_s
                            );
                 EXCEPTION
                   WHEN others THEN
                     LOG_ERROR(p_exception => 'EX_PROCESS_ERROR'
                              ,p_message   => sqlerrm
                              ,p_code      => -1
                              );
                              
                    --
                    ROLLBACK;
                    x_message_code := -1;
                    FND_MESSAGE.SET_NAME('XXPTP','XX_INV_63083_PROC_ERR');
                    FND_MESSAGE.SET_TOKEN('LOC',lc_error_loc);
                    FND_MESSAGE.SET_TOKEN('NAME',LPAD(lcr_rec_process.location_number_sw,6,0                             )||':'||lcr_rec_process.org_name_sw);
                    FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
                    x_message_data := FND_MESSAGE.GET;
                    IF lc_axn_type = 'C' THEN -- Incase of Conversion
                       ln_process_flag := 6; -- Processing Failed
                    ELSE
                       ln_process_flag := NULL;
                    END IF;
                    UPDATE  xx_inv_org_loc_def_stg
                    SET     process_flag    = ln_process_flag
                           ,update_date     = SYSDATE
                           ,updated_by      = FND_GLOBAL.user_id
                           ,error_code      = x_message_code
                           ,error_message   = x_message_data
                    WHERE   control_id      = lcr_rec_process.control_id;
                    --          
                 END;
               EXCEPTION
                WHEN ex_no_location THEN
                    CLOSE lcu_rec_hr_loc;
                    ROLLBACK;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..ROLLBACK');
                    x_message_code := -1;
                    FND_MESSAGE.SET_NAME('XXPTP','XX_INV_63084_NO_HR_LOC');
                    FND_MESSAGE.SET_TOKEN('NAME',LPAD(lcr_rec_process.location_number_sw,6,0                             )||':'||lcr_rec_process.org_name_sw);
                    x_message_data := FND_MESSAGE.GET;
                    IF lc_axn_type = 'C' THEN -- Incase of Conversion
                        ln_process_flag := 6; -- Processing Failed
                    ELSE
                        ln_process_flag := NULL;
                    END IF;
                    UPDATE  xx_inv_org_loc_def_stg
                    SET     process_flag    = ln_process_flag
                           ,update_date     = SYSDATE
                           ,updated_by      = FND_GLOBAL.user_id
                           ,error_code      = x_message_code
                           ,error_message   = x_message_data
                    WHERE   control_id      = lcr_rec_process.control_id;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..'||x_message_data);
                    LOG_ERROR(p_exception => 'EX_NO_LOCATION'       --IN VARCHAR2
                            ,p_message   => x_message_data           --IN VARCHAR2
                            ,p_code      => x_message_code           --IN NUMBER
                            );
                WHEN OTHERS THEN
                    lc_error_flag  := 'E';
                    lc_error_loc   := 'updating HR_LOCATIONS';
                    RAISE ex_process_error;
                END;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  --  ');
        EXCEPTION
        WHEN ex_process_error THEN
            ROLLBACK;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..ROLLBACK');
            x_message_code := -1;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_63083_PROC_ERR');
            FND_MESSAGE.SET_TOKEN('LOC',lc_error_loc);
            FND_MESSAGE.SET_TOKEN('NAME',LPAD(lcr_rec_process.location_number_sw,6,0 )||':'||lcr_rec_process.org_name_sw);
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
            x_message_data := FND_MESSAGE.GET;
            IF lc_axn_type = 'C' THEN -- Incase of Conversion
                ln_process_flag := 6; -- Processing Failed
            ELSE
                ln_process_flag := NULL;
            END IF;
            UPDATE  xx_inv_org_loc_def_stg
            SET     process_flag    = ln_process_flag
                   ,update_date     = SYSDATE
                   ,updated_by      = FND_GLOBAL.user_id
                   ,error_code      = x_message_code
                   ,error_message   = x_message_data
            WHERE   control_id      = lcr_rec_process.control_id;
            LOG_ERROR(p_exception => 'EX_PROCESS_ERROR'       --IN VARCHAR2
                     ,p_message   => x_message_data           --IN VARCHAR2
                     ,p_code      => x_message_code           --IN NUMBER
                    );
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..'||x_message_data);
        WHEN OTHERS THEN
            ROLLBACK;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..ROLLBACK');
            x_message_code := -1;
            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_63085_OTHER_ERR');
            FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
            FND_MESSAGE.SET_TOKEN('NAME',LPAD(lcr_rec_process.location_number_sw,6,0 )||':'||lcr_rec_process.org_name_sw);
            x_message_data := FND_MESSAGE.GET;
            IF lc_axn_type = 'C' THEN -- Incase of Conversion
                ln_process_flag := 6; -- Processing Failed
            ELSE
                ln_process_flag := NULL;
            END IF;
            UPDATE  xx_inv_org_loc_def_stg
            SET     process_flag    = ln_process_flag
                   ,update_date     = SYSDATE
                   ,updated_by      = FND_GLOBAL.user_id
                   ,error_code      = x_message_code
                   ,error_message   = x_message_data
            WHERE   control_id      = lcr_rec_process.control_id;
            LOG_ERROR(p_exception => 'OTHERS'     --IN VARCHAR2
                     ,p_message   => x_message_data           --IN VARCHAR2
                     ,p_code      => x_message_code           --IN NUMBER
            );
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..'||x_message_data);
        END;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  --  ');
        IF lc_error_flag = 'S'THEN
            x_message_code := 0;
            x_message_data := NULL;
            ln_proc_count := ln_proc_count + 1;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  ..Processing Successfull');
            IF lc_axn_type = 'C' THEN -- Incase of Conversion
                ln_process_flag := 7; -- Processing Successfull
            ELSE
                ln_process_flag := NULL;
            END IF;
            UPDATE  xx_inv_org_loc_def_stg
            SET     process_flag    = ln_process_flag
                   ,update_date     = SYSDATE
                   ,updated_by      = FND_GLOBAL.user_id
                   ,error_code      = x_message_code
                   ,error_message   = x_message_data
            WHERE   control_id      = lcr_rec_process.control_id;
        ELSE
            ln_error_count := ln_error_count + 1;
        END IF;
        COMMIT;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  - Committed');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  - Finished processing record of control id : '||lcr_rec_process.control_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'  ');
        END LOOP;
        IF lc_axn_type = 'C' THEN
            IF ln_tot_count = 0 THEN -- Records were not picked up Or Some errors occurred
                x_message_code := 1;        -- ,WARNING status.
            ELSIF (ln_tot_count = ln_proc_count + ln_error_count) THEN 
            -- Processed records + Errored reocords = total records picked up.
                x_message_code := 0;        -- ,NORMAL status.
            ELSE
                x_message_code := 2;        -- Error status.
            END IF;
        END IF;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'            OrgCreationProcess Summary               ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no of Inventory Organization Records picked up :'||ln_tot_count);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Of Inventory Organization Records Processed       :'||ln_proc_count);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Of Inventory Organization Records Errored         :'||ln_error_count);
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------- ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'-- End of Processing -- ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----------------------- ');
    EXCEPTION
    WHEN ex_incorrect_action THEN
        x_message_code := 1;
        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_63082_INVALID_ACTION');
        FND_MESSAGE.SET_TOKEN('ACTION',p_action_type);
        x_message_data := FND_MESSAGE.GET;
        LOG_ERROR(p_exception => 'EX_INCORRECT_ACTION'     --IN VARCHAR2
                  ,p_message   => x_message_data           --IN VARCHAR2
                  ,p_code      => x_message_code           --IN NUMBER
                  );
        FND_FILE.PUT_LINE(FND_FILE.LOG,x_message_data);
    WHEN OTHERS THEN
        IF p_action_type = 'C' THEN
            x_message_code := 2;
        ELSE
            x_message_code := -1;
        END IF;
        FND_MESSAGE.SET_NAME('XXPTP','XX_INV_63081_UNEXP_ERR');
        FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
        x_message_data := FND_MESSAGE.GET;
        LOG_ERROR(p_exception => 'OTHERS'     --IN VARCHAR2
                  ,p_message   => x_message_data           --IN VARCHAR2
                  ,p_code      => x_message_code           --IN NUMBER
                  );
        FND_FILE.PUT_LINE(FND_FILE.LOG,x_message_data);
    END Process_Main;

END XX_INV_ORG_LOC_DEF_PKG ;
/


SHOW ERRORS;

EXIT ;

