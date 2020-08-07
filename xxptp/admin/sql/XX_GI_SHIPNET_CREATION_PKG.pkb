SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_GI_SHIPNET_CREATION_PKG
--Version 1.3
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_SHIPNET_CREATION_PKG                                    |
-- |Purpose      : This package contains procedures that pre-builds/dynamically  |
-- |                creates shipping networks between EBS organizations to       |
-- |                facilitate inventory transfer.                               |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- |                                                                             |
-- |MTL_INTERORG_PARAMETERS      : S,I                                           |
-- |MTL_PARAMETERS               : S                                             |
-- |XX_INV_ORG_LOC_RMS_ATTRIBUTE : S                                             |
-- |HR_ORGAINZATION_UNTIS        : S,U                                           |
-- |XX_COM_ERROR_LOG             : I                                             |
-- |FND_ID_FLEX_STRUCTURES       : S                                             |
-- |FND_APPLICATION              : S                                             |
-- |FND_FLEX_VALUE_SETS          : S                                             |
-- |FND_FLEX_VALUES_VL           : S                                             |
-- |GL_CODE_COMBINATIONS         : S,I                                           |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |Draft1A  13-Aug-2007   Arun Andavar     Original Code                        |
-- |Draft1B  29-Aug-2007   Arun Andavar     1)CR-NONTRADE will not be restricted.|
-- |                                        2)CR-Payables and Receivables account|
-- |                                        derivation logic is modified.        |
-- |                                        3)Modification-As all the orgs use   |
-- |                                          average costing inter-org purchase |
-- |                                          price variance account will not be |
-- |                                          derived by this program.           |
-- |Draft1C  10-Sep-2007   Arun Andavar     1)CR-Create code combination if does |
-- |                                           not exists in the EBS             |
-- | 1.0     18-Sep-2007   Vikas Raina      Reviewed and updated                 |
-- | 1.1     27-Sep-2007   Arun Andavar     1)Bug fix: For NON-TRADE networks    |
-- |                                          the intransit type should be direct|
-- | 1.2     02-Oct-2007   Arun Andavar     1)CR: Attribute6 updation is not done|
-- |                                          as discussed with Onsite team      |
-- | 1.3     04-Oct-2007   Arun Andavar     1)Bug fix: Count mismatch fixed      |
-- +=============================================================================+
IS
   -- ----------------------------------------
   -- Global constants used for error handling
   -- ----------------------------------------
   G_PROG_NAME                     CONSTANT VARCHAR2(50)  := 'XX_GI_SHIPNET_CREATION_PKG';
   G_MODULE_NAME                   CONSTANT VARCHAR2(50)  := 'INV';
   G_PROG_TYPE                     CONSTANT VARCHAR2(50)  := 'CUSTOM API';
   G_NOTIFY                        CONSTANT VARCHAR2(1)   := 'Y';
   G_MAJOR                         CONSTANT VARCHAR2(15)  := 'MAJOR';
   G_MINOR                         CONSTANT VARCHAR2(15)  := 'MINOR';
   G_989                           CONSTANT VARCHAR2(5)   := '-989';
   G_989_N                         CONSTANT PLS_INTEGER   := -989;
   ------------------
   -- Other constants
   ------------------
   G_PROCESS_TYPE_ONDEMAND         CONSTANT VARCHAR2(10)  := 'ON-DEMAND';
   G_PROCESS_TYPE_PREBUILD         CONSTANT VARCHAR2(10)  := 'PRE-BUILD';
   G_YES                           CONSTANT VARCHAR2(1)   := 'Y';
   G_VALIDATION_VALUSET            CONSTANT VARCHAR2(30)  := 'XX_GI_SHIPNET_VALIDATION';
   G_CREATION_RULE_TYPE            CONSTANT VARCHAR2(10)  := 'CREATION';
   G_RESTRICTION_RULE_TYPE         CONSTANT VARCHAR2(15)  := 'RESTRICTION';
   G_NON_TRADE                     CONSTANT VARCHAR2(10)  := 'NONTRADE';
   G_DROP_SHIP                     CONSTANT VARCHAR2(5)   := 'DS';
   G_TEMPLATE                      CONSTANT VARCHAR2(10)  := 'TMPL';
   G_ITEM_MASTER                   CONSTANT VARCHAR2(5)   := 'MAS';
   G_VALIDATION_ORG                CONSTANT VARCHAR2(10)  := 'VAL';
   G_SUBTYPE_NT                    CONSTANT VARCHAR2(2)   := 'NT';
   G_HIERARCHY_NODE                CONSTANT VARCHAR2(5)   := 'HNODE';
   G_GL_SHORT_NAME                 CONSTANT VARCHAR2(5)   := 'SQLGL';
   G_ACCNT_FLEX_CODE               CONSTANT VARCHAR2(5)   := 'GL#';
   G_ACNT_FLEX_STRUCT_CODE         CONSTANT VARCHAR2(25)  := 'OD_GLOBAL_COA';
   G_APPL_PTP_SHORT_NAME           CONSTANT VARCHAR2(6)   := 'XXPTP';
   ----------------------------------
   -- To be used in exception message
   ----------------------------------
   G_CREATION_RULE_STRING          CONSTANT VARCHAR2(15)  := 'Creation rule';
   G_INTERNAL_FLAG                 CONSTANT VARCHAR2(28)  := 'Internal order required flag';
   G_MANUAL_FLAG                   CONSTANT VARCHAR2(27)  := 'Manual receipt expense flag';
   G_ELEMENT_FLAG                  CONSTANT VARCHAR2(27)  := 'Element visibility flag';
   G_TRANS_FLAG                    CONSTANT VARCHAR2(27)  := 'Inter-org transfer code';
   G_ROUTING_FLAG                  CONSTANT VARCHAR2(27)  := 'Receipt routing';
   G_TRANS_TYPE                    CONSTANT VARCHAR2(27)  := 'Transfer Type';
   -----------------
   -- Message tokens
   -----------------
   G_T1                            CONSTANT VARCHAR2(5)   := 'PROC';
   G_T2                            CONSTANT VARCHAR2(5)   := 'ERR';
   G_T3                            CONSTANT VARCHAR2(5)   := 'ORG';
   G_T4                            CONSTANT VARCHAR2(6)   := 'TO_ORG';
   G_T5                            CONSTANT VARCHAR2(5)   := 'OBJ';
   ----------------
   -- Message names
   ----------------
   G_62501                         CONSTANT VARCHAR2(30)  := 'XX_INV_62501_ERR_DEFALT_ACCNT';
   G_62502                         CONSTANT VARCHAR2(30)  := 'XX_INV_62502_UNEXPECTED_ERR';
   G_62503                         CONSTANT VARCHAR2(30)  := 'XX_INV_62503_COUNTRY_NULL';
   G_62504                         CONSTANT VARCHAR2(30)  := 'XX_INV_62504_ACCNT_STRUCT_CODE';
   G_62505                         CONSTANT VARCHAR2(30)  := 'XX_INV_62505_TARGET_ORG_ERR';
   G_62506                         CONSTANT VARCHAR2(30)  := 'XX_INV_62506_TARGET_INFO_ERR';
   G_62507                         CONSTANT VARCHAR2(30)  := 'XX_INV_62507_NO_TO_NET_ACRS_OU';
   G_62508                         CONSTANT VARCHAR2(30)  := 'XX_INV_62508_NO_TO_DYNAMIC_NET';
   G_62509                         CONSTANT VARCHAR2(30)  := 'XX_INV_62509_NO_PREBUILD_NET';
   G_62510                         CONSTANT VARCHAR2(30)  := 'XX_INV_62510_NO_TO_NETWORK';
   G_62511                         CONSTANT VARCHAR2(30)  := 'XX_INV_62511_SUBTYPE_REQUIRED';
   G_62512                         CONSTANT VARCHAR2(30)  := 'XX_INV_62512_ORGTYPE_REQUIRED';
   G_62513                         CONSTANT VARCHAR2(30)  := 'XX_INV_62513_RESTRICTED_NET';
   G_62514                         CONSTANT VARCHAR2(30)  := 'XX_INV_62514_INVALID_ACCOUNT';
   G_62515                         CONSTANT VARCHAR2(30)  := 'XX_INV_62515_NONTRADE_OUT_MSG';
   G_62516                         CONSTANT VARCHAR2(30)  := 'XX_INV_62516_NO_VALID_RECORDS';
   G_62517                         CONSTANT VARCHAR2(30)  := 'XX_INV_62517_NO_DEFAULT_ACCNTS';
   G_62518                         CONSTANT VARCHAR2(30)  := 'XX_INV_62518_SHIPNET_HNDLR_ERR';
   G_62519                         CONSTANT VARCHAR2(30)  := 'XX_INV_62519_INVALID_DATA';
   G_62520                         CONSTANT VARCHAR2(30)  := 'XX_INV_62520_FROM_TO_SAME';
   G_62521                         CONSTANT VARCHAR2(30)  := 'XX_INV_62521_SOURCE_ORG_NULL';

   -- ------------------------------
   -- Global user defined exceptions
   -- ------------------------------
   EX_NULL_COUNTRY                 EXCEPTION;
   EX_ERR_DERIVING_ACCOUNTS        EXCEPTION;
   EX_ERR_ACNT_FLEX_STRUCT_ID      EXCEPTION;
   EX_SOURCE_ORG_NULL              EXCEPTION;
   -- -----------------------
   -- Global scalar variables
   -- -----------------------
   --------------------
   -- Parameters passed
   --------------------
   --For prebuild
   gc_param_source_org_type        hr_organization_units.type%TYPE                       := NULL;
   gc_param_from_org_name          hr_organization_units.name%TYPE                       := NULL;
   gc_param_report_mode            VARCHAR2(1)                                           := NULL;
   --For dynamic
   gn_param_from_id                hr_organization_units.organization_id%TYPE            := NULL;
   gn_param_to_id                  hr_organization_units.organization_id%TYPE            := NULL;
   -----------------
   -- For validation
   -----------------
   gn_ccid                         gl_code_combinations.code_combination_id%TYPE         := NULL;
   gn_ccid1                        gl_code_combinations.code_combination_id%TYPE         := NULL;
   gn_code_combination             VARCHAR2(500)                                         := NULL;
   gc_shipnet_exists               VARCHAR2(1)                                           := NULL;
   gc_bi_directional               VARCHAR2(1)                                           := NULL;
   gc_creation_allowed             VARCHAR2(1)                                           := NULL;
   gc_across_countries             VARCHAR2(1)                                           := NULL;
   gc_same_country                 VARCHAR2(1)                                           := NULL;
   gc_source_country               hr_locations_all.country%TYPE                         := NULL;
   gc_target_country               hr_locations_all.country%TYPE                         := NULL;
   gc_default_xdoc                 xx_inv_org_loc_rms_attribute.default_wh_sw%TYPE       := NULL;
   gc_default_csc                  xx_inv_org_loc_rms_attribute.od_default_wh_csc_s%TYPE := NULL;
   gc_non_trade_nw_processing      VARCHAR2(1)                                           := NULL;
   gc_process_type                 VARCHAR2(10)                                          := NULL;
   gn_accnt_flex_struct_id         fnd_id_flex_structures.id_flex_num%TYPE               := NULL;
   gc_delimiter                    VARCHAR2(1)                                           := NULL;
   gc_purch_price_var_flag         VARCHAR2(1)                                           := NULL;
   gc_invalid_creation_rule_flag   VARCHAR2(1)                                           := NULL;


   ------------------------------
   -- Shipnet account information
   ------------------------------
   gn_intransit_inv_account        gl_code_combinations.code_combination_id%TYPE         := NULL;
   gn_inter_transfer_cr_account    gl_code_combinations.code_combination_id%TYPE         := NULL;
   gn_src_inter_receiv_account     gl_code_combinations.code_combination_id%TYPE         := NULL;
   gn_src1_inter_receiv_account    gl_code_combinations.code_combination_id%TYPE         := NULL;
   gn_trgt_inter_receiv_account    gl_code_combinations.code_combination_id%TYPE         := NULL;
   gn_src_inter_pay_account        gl_code_combinations.code_combination_id%TYPE         := NULL;
   gn_trgt_inter_pay_account       gl_code_combinations.code_combination_id%TYPE         := NULL;
   gn_trgt1_inter_pay_account      gl_code_combinations.code_combination_id%TYPE         := NULL;
   gn_interorg_price_var_account   gl_code_combinations.code_combination_id%TYPE         := NULL;
   -----------------------------------
   -- Shipnet basic source information
   -----------------------------------
   gc_source_org_code              mtl_parameters.organization_code%TYPE                 := NULL;
   gc_source_org_num               hr_organization_units.attribute1%TYPE                 := NULL;
   gc_source_org_type              hr_organization_units.type%TYPE                       := NULL;
   gc_source_sub_type              xx_inv_org_loc_rms_attribute.od_sub_type_cd_sw%TYPE   := NULL;
   gn_source_org_id                mtl_parameters.organization_id%TYPE                   := NULL;
   -----------------------------------
   -- Shipnet basic target information
   -----------------------------------
   gc_target_org_num               hr_organization_units.attribute1%TYPE                 := NULL;
   gc_target_org_code              mtl_parameters.organization_code%TYPE                 := NULL;
   gc_target_org_type              hr_organization_units.type%TYPE                       := NULL;
   gn_target_org_id                mtl_parameters.organization_id%TYPE                   := NULL;
   gc_target_sub_type              xx_inv_org_loc_rms_attribute.od_sub_type_cd_sw%TYPE   := NULL;

   ------------------------------------------------------
   -- Used as index for temporary and main shipnet tables
   ------------------------------------------------------
   gn_temp_indx                    PLS_INTEGER                                           := NULL;
   gn_main_indx                    PLS_INTEGER                                           := NULL;
   --------------------------
   -- Used for error handling
   --------------------------
   gc_error_event                  VARCHAR2(50)                                          := NULL;
   gc_message_data                 VARCHAR2(5000)                                        := NULL;
   gc_is_log_validation_err        VARCHAR2(1)                                           := NULL;
   gn_message_code                 PLS_INTEGER                                           := 0;
   gn_total_non_trade_orgs         PLS_INTEGER                                           := 0;
   gn_total_nontrade_net_invalid   PLS_INTEGER                                           := 0;
   gn_total_nontrade_net_valid     PLS_INTEGER                                           := 0;
   gn_totl_excpt_nontrade_invalid  PLS_INTEGER                                           := 0;
   gn_totl_excpt_nontrade_valid    PLS_INTEGER                                           := 0;
   gn_total_org_excpt_nontrade     PLS_INTEGER                                           := 0;
   gn_total_nontrade_net           PLS_INTEGER                                           := 0;
   gc_non_trade                    VARCHAR2(1)                                           := NULL;


   -----------------------------------------------------------------
   -- Used to hold all non-duplicated and possible shipping networks
   --  information that may or may not be created.
   -----------------------------------------------------------------
   gt_main_shipnet_tbl shipnet_tbl_type;
   -------------------------------------------
   -- Used to hold possible shipping networks
   --  information for the given inventory org
   --  that may or may not be created.
   -------------------------------------------
   gt_temp_shipnet_tbl shipnet_tbl_type;

   ----------------------------------------------------------------------------
   -- Cursor to get the default CSC and XDOC for the given source inventory org
   ----------------------------------------------------------------------------
   CURSOR gcu_default_csc_xdoc(p_org_num IN VARCHAR2
                              )
   IS
   SELECT XIOLRA.default_wh_sw       default_xdoc
         ,XIOLRA.od_default_wh_csc_s default_csc
         ,UPPER(XIOLRA.od_sub_type_cd_sw)   src_sub_type
   FROM   xx_inv_org_loc_rms_attribute XIOLRA
   WHERE  XIOLRA.location_number_sw = p_org_num
   ;
   -- +========================================================================+
   -- | Name        :  LOG_ERROR                                               |
   -- |                                                                        |
   -- | Description :  This wrapper procedure calls the custom common error api|
   -- |                 with relevant parameters.                              |
   -- |                                                                        |
   -- | Parameters  :                                                          |
   -- |                p_exception IN VARCHAR2                                 |
   -- |                p_message   IN VARCHAR2                                 |
   -- |                p_code      IN PLS_INTEGER                              |
   -- |                                                                        |
   -- +========================================================================+
   PROCEDURE LOG_ERROR(p_exception IN VARCHAR2
                      ,p_message   IN VARCHAR2
                      ,p_code      IN PLS_INTEGER
                      )
   IS
      -------------------------
      -- Local scalar variables
      -------------------------
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
                           ,p_error_location          => p_exception     --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message_code      => p_code          --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message           => p_message       --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message_severity  => lc_severity     --IN VARCHAR2  DEFAULT NULL
                           ,p_notify_flag             => G_NOTIFY        --IN VARHCAR2  DEFAULT NULL
                           );

   END LOG_ERROR;
-- +====================================================================+
-- | Name        :  get_fnd_message                                     |
-- | Description :  This function get the message after                 |
-- |                 substituting the tokens.                           |
-- | Parameters  :  p_name IN VARCHAR2                                  |
-- |                p_1    IN VARCHAR2 DEFAULT NULL                     |
-- |                p_v1   IN VARCHAR2 DEFAULT NULL                     |
-- |                p_2    IN VARCHAR2 DEFAULT NULL                     |
-- |                p_v2   IN VARCHAR2 DEFAULT NULL                     |
-- |                p_3    IN VARCHAR2 DEFAULT NULL                     |
-- |                p_v3   IN VARCHAR2 DEFAULT NULL                     |
-- +====================================================================+
FUNCTION get_fnd_message(
                         p_name IN VARCHAR2
                        ,p_1    IN VARCHAR2 DEFAULT NULL
                        ,p_v1   IN VARCHAR2 DEFAULT NULL
                        ,p_2    IN VARCHAR2 DEFAULT NULL
                        ,p_v2   IN VARCHAR2 DEFAULT NULL
                        ,p_3    IN VARCHAR2 DEFAULT NULL
                        ,p_v3   IN VARCHAR2 DEFAULT NULL
                        )
RETURN VARCHAR2
IS
BEGIN
   FND_MESSAGE.SET_NAME(G_APPL_PTP_SHORT_NAME,p_name);
   IF p_1 IS NOT NULL THEN
     FND_MESSAGE.SET_TOKEN(p_1,p_v1);
   END IF;
   IF p_2 IS NOT NULL THEN
      FND_MESSAGE.SET_TOKEN(p_2,p_v2);
   END IF;
   IF p_3 IS NOT NULL THEN
      FND_MESSAGE.SET_TOKEN(p_3,p_v3);
   END IF;
   RETURN FND_MESSAGE.GET;
END;
-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the out file  |
-- |                                                                    |
-- | Parameters  :  Output Message                                      |
-- +====================================================================+
PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END;

-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the log file  |
-- |                                                                    |
-- | Parameters  :  Output Message                                      |
-- +====================================================================+
PROCEDURE display_log(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
END;


-- +========================================================================+
-- | Name        :  DERIVE_DEFAULT_ACCOUNTS                                 |
-- |                                                                        |
-- | Description :  This procedure derives the default account information  |
-- |                 for the given shipping network                         |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE DERIVE_DEFAULT_ACCOUNTS(p_src_org_id    IN mtl_parameters.organization_id%TYPE
                                 ,p_tgt_org_id    IN mtl_parameters.organization_id%TYPE
                                 ,p_fob_point     IN mtl_interorg_parameters.fob_point%TYPE
                                 ,p_transfer_type IN mtl_interorg_parameters.intransit_type%TYPE
                                 )
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm                            VARCHAR2(25)                                  := 'DERIVE_DEFAULT_ACCOUNTS';
   -------------------------
   -- Local scalar variables
   -------------------------
   ln_src_intransit_inv_accnt       gl_code_combinations.code_combination_id%TYPE := NULL;
   ln_src_inter_receiv_accnt        gl_code_combinations.code_combination_id%TYPE := NULL;
   ln_src_inter_price_var_accnt     gl_code_combinations.code_combination_id%TYPE := NULL;
   ln_src_inter_transfer_cr_accnt   gl_code_combinations.code_combination_id%TYPE := NULL;
   ln_src_inter_payables_accnt      gl_code_combinations.code_combination_id%TYPE := NULL;
   ln_src_primary_cost_method       mtl_parameters.primary_cost_method%TYPE       := NULL;

   ln_trgt_intransit_inv_accnt      gl_code_combinations.code_combination_id%TYPE := NULL;
   ln_trgt_inter_receiv_accnt       gl_code_combinations.code_combination_id%TYPE := NULL;
   ln_trgt_inter_price_var_accnt    gl_code_combinations.code_combination_id%TYPE := NULL;
   ln_trgt_inter_transf_cr_accnt    gl_code_combinations.code_combination_id%TYPE := NULL;
   ln_trgt_inter_payables_accnt     gl_code_combinations.code_combination_id%TYPE := NULL;
   ln_trgt_primary_cost_method      mtl_parameters.primary_cost_method%TYPE       := NULL;
   ---------------------------------------------------------
   -- Cursor to derive default accounts for the given org id
   ---------------------------------------------------------
   CURSOR lcu_accounts(p_org_id IN mtl_parameters.organization_id%TYPE)
   IS
   SELECT  MP.intransit_inv_account
          ,MP.interorg_receivables_account
          ,MP.interorg_price_var_account
          ,MP.interorg_transfer_cr_account
          ,MP.interorg_payables_account
          ,MP.primary_cost_method
   FROM    mtl_parameters MP
   WHERE   MP.organization_id = p_org_id
   ;
BEGIN

      gc_message_data := NULL;
      gc_purch_price_var_flag := NULL;
      ------------------------------------------------------------------------------
      -- Get the account information from mtl_parameters for the given source org id
      ------------------------------------------------------------------------------
      OPEN lcu_accounts(p_src_org_id);
      FETCH lcu_accounts INTO ln_src_intransit_inv_accnt
                             ,ln_src_inter_receiv_accnt
                             ,ln_src_inter_price_var_accnt
                             ,ln_src_inter_transfer_cr_accnt
                             ,ln_src_inter_payables_accnt
                             ,ln_src_primary_cost_method;
         IF lcu_accounts%NOTFOUND THEN

            gc_message_data := get_fnd_message
                               (p_name => G_62501,p_1 => G_T3,p_v1 => gt_temp_shipnet_tbl(gn_temp_indx).source_inv_org);
         END IF;
      CLOSE lcu_accounts;
      -------------------------------------------------------------------------------
      -- Get the account information from mtl_parameters for the given targtet org id
      -------------------------------------------------------------------------------
      OPEN lcu_accounts(p_tgt_org_id);
      FETCH lcu_accounts INTO ln_trgt_intransit_inv_accnt
                             ,ln_trgt_inter_receiv_accnt
                             ,ln_trgt_inter_price_var_accnt
                             ,ln_trgt_inter_transf_cr_accnt
                             ,ln_trgt_inter_payables_accnt
                             ,ln_trgt_primary_cost_method;
         IF lcu_accounts%NOTFOUND THEN
            gc_message_data := get_fnd_message
                               (p_name => G_62501,p_1 => G_T3,p_v1 => gt_temp_shipnet_tbl(gn_temp_indx).target_inv_org);
         END IF;

      CLOSE lcu_accounts;

      IF gc_message_data IS NULL THEN
         -------------------------------------------------------------------------------
         -- If the To organizations primary cost method is "standard" only then populate
         --  interorg purchase price variance account details.
         -------------------------------------------------------------------------------
         IF ln_trgt_primary_cost_method = 1 THEN

            gc_purch_price_var_flag       := 'Y';

            IF gn_interorg_price_var_account IS NULL THEN

               gn_interorg_price_var_account := ln_trgt_inter_price_var_accnt;

               IF gn_interorg_price_var_account IS NULL THEN

                  gc_message_data := get_fnd_message(p_name => G_62517,p_1 => G_T5,p_v1 => 'Target Orgs Inter-org purchase price variance');

               END IF;

            END IF;

         ELSE

            gc_purch_price_var_flag := 'N';

         END IF;
         -------------------------------------------------------------------------------
         -- Derive intransit account only if it not null and the transfer type is direct
         -------------------------------------------------------------------------------
         IF  gn_intransit_inv_account IS NULL AND p_transfer_type <> G_DIRECT_ID THEN

            IF p_fob_point = 2 THEN

               IF ln_src_intransit_inv_accnt IS NOT NULL THEN

                  gn_intransit_inv_account      := ln_src_intransit_inv_accnt;

               ELSE

                  gc_message_data := get_fnd_message(p_name => G_62517,p_1 => G_T5,p_v1 => 'Source Orgs Intransit');

               END IF;

            ELSIF p_fob_point = 1 THEN

               IF ln_trgt_intransit_inv_accnt IS NOT NULL THEN

                  gn_intransit_inv_account      := ln_trgt_intransit_inv_accnt;

               ELSE

                  gc_message_data := get_fnd_message(p_name => G_62517,p_1 => G_T5,p_v1 => 'Target Orgs Intransit');

               END IF;

            END IF;

         END IF;

         gn_trgt_inter_receiv_account  := ln_trgt_inter_receiv_accnt;

         IF ln_trgt_inter_receiv_accnt IS NOT NULL THEN
         
            gn_trgt_inter_receiv_account  := ln_trgt_inter_receiv_accnt;
         
         ELSE        

            gc_message_data := get_fnd_message(p_name => G_62517,p_1 => G_T5,p_v1 => 'Target Orgs Inter-org receivables');

         END IF;
         -------------------------------------------------------------------------------------------
         -- If user has passed receivables account information then do not derive it from source org
         -------------------------------------------------------------------------------------------

         IF gn_src1_inter_receiv_account IS NULL THEN

            IF ln_src_inter_receiv_accnt IS NOT NULL THEN

               gn_src_inter_receiv_account   := ln_src_inter_receiv_accnt;--default

            ELSE

               gc_message_data := get_fnd_message(p_name => G_62517,p_1 => G_T5,p_v1 => 'Source Orgs Inter-org receivables');

            END IF;

         ELSE

            gn_src_inter_receiv_account   := gn_src1_inter_receiv_account;

         END IF;

         -----------------------------------------------------
         -- Derive transfer credit account only if it not null
         -----------------------------------------------------

         IF gn_inter_transfer_cr_account IS NULL THEN

            gn_inter_transfer_cr_account  := ln_src_inter_transfer_cr_accnt;

            IF ln_src_inter_transfer_cr_accnt IS NOT NULL THEN

               gn_inter_transfer_cr_account   := ln_src_inter_transfer_cr_accnt;--default

            ELSE

               gc_message_data := get_fnd_message(p_name => G_62517,p_1 => G_T5,p_v1 => 'Source Orgs Inter-org transfer credit');
 
            END IF;

         END IF;
         

         gn_src_inter_pay_account      := ln_src_inter_payables_accnt;

         IF ln_src_inter_payables_accnt IS NOT NULL THEN

            gn_src_inter_pay_account      := ln_src_inter_payables_accnt;

         ELSE

            gc_message_data := get_fnd_message(p_name => G_62517,p_1 => G_T5,p_v1 => 'Source Orgs Inter-org payables');

         END IF;
         ----------------------------------------------------------------------------------------
         -- If user has passed payables account information then do not derive it from target org
         ----------------------------------------------------------------------------------------
         IF gn_trgt1_inter_pay_account IS NULL THEN

            IF ln_trgt_inter_payables_accnt IS NOT NULL THEN

               gn_trgt_inter_pay_account     := ln_trgt_inter_payables_accnt;--default

            ELSE

               gc_message_data := get_fnd_message(p_name => G_62517,p_1 => G_T5,p_v1 => 'Target Orgs Inter-org payables');

            END IF;

         ELSE

            gn_trgt_inter_pay_account      := gn_trgt1_inter_pay_account;

         END IF;

      END IF;
EXCEPTION
   WHEN OTHERS THEN
      IF lcu_accounts%ISOPEN THEN
         CLOSE lcu_accounts;
      END IF;
      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);
      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );

END DERIVE_DEFAULT_ACCOUNTS;

-- +========================================================================+
-- | Name        :  GET_CODE_COMBINATION                                    |
-- |                                                                        |
-- | Description :  This procedure derives the code combination for the     |
-- |                 given code combination id                              |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE GET_CODE_COMBINATION(p_account_name IN VARCHAR2)
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm         VARCHAR2(20)                       := 'GET_CODE_COMBINATION';
   -------------------------
   -- Local scalar variables
   -------------------------
   lc_segment1 gl_code_combinations.segment1%TYPE   := NULL;
   lc_segment2 gl_code_combinations.segment2%TYPE   := NULL;
   lc_segment3 gl_code_combinations.segment3%TYPE   := NULL;
   lc_segment4 gl_code_combinations.segment4%TYPE   := NULL;
   lc_segment5 gl_code_combinations.segment5%TYPE   := NULL;
   lc_segment6 gl_code_combinations.segment6%TYPE   := NULL;
   lc_segment7 gl_code_combinations.segment7%TYPE   := NULL;

   lc_def_seg1 gl_code_combinations.segment1%TYPE   := NULL;
   lc_def_seg2 gl_code_combinations.segment2%TYPE   := NULL;
   lc_def_seg3 gl_code_combinations.segment3%TYPE   := NULL;
   lc_def_seg4 gl_code_combinations.segment4%TYPE   := NULL;
   lc_def_seg5 gl_code_combinations.segment5%TYPE   := NULL;
   lc_def_seg6 gl_code_combinations.segment6%TYPE   := NULL;
   lc_def_seg7 gl_code_combinations.segment7%TYPE   := NULL;

   lc_other_seg1 gl_code_combinations.segment1%TYPE := NULL;
   lc_other_seg5 gl_code_combinations.segment2%TYPE := NULL;
   lc_count      PLS_INTEGER                        := 0;
   lc_type       VARCHAR2(10)                       := NULL;
   -----------------------------------------------------------------------------
   -- Cursor to fetch the code combinations for the given code combination id(s)
   -----------------------------------------------------------------------------
   CURSOR lcu_get_cc
   IS
   SELECT  GCC.segment1
          ,GCC.segment2
          ,GCC.segment3
          ,GCC.segment4
          ,GCC.segment5
          ,GCC.segment6
          ,GCC.segment7
          ,DECODE(GCC.code_combination_id,gn_ccid,'DEFAULT',NVL(gn_ccid1,G_989_N),'OTHER') TYPE
   FROM   gl_code_combinations GCC
   WHERE  GCC.code_combination_id IN (gn_ccid,NVL(gn_ccid1,G_989_N))
   ;
   ----------------------------------------------------------------------
   --Cursor to validate the code combination after modifying the segment5
   ----------------------------------------------------------------------
   CURSOR lcu_validate_cc
   IS
   SELECT GCC.code_combination_id
   FROM   gl_code_combinations GCC
   WHERE  GCC.segment1 = lc_def_seg1
   AND    GCC.segment2 = lc_def_seg2
   AND    GCC.segment3 = lc_def_seg3
   AND    GCC.segment4 = lc_def_seg4
   AND    GCC.segment5 = lc_other_seg1
   AND    GCC.segment6 = lc_def_seg6
   AND    GCC.segment7 = lc_def_seg7
   ;

BEGIN
   gn_code_combination := NULL;
   lc_count            := 0;
   lc_type             := NULL;
   ------------------------------------------------------------------------------
   -- This cursor would fetch two rows only for receivables and payables accounts.
   -- One would be the source org account and other would be for target account
   -- In case of receivables the default account would be from source org and for
   -- Payables the default account would be from target org.
   ------------------------------------------------------------------------------
   OPEN lcu_get_cc;
   LOOP
   FETCH lcu_get_cc INTO lc_segment1
                        ,lc_segment2
                        ,lc_segment3
                        ,lc_segment4
                        ,lc_segment5
                        ,lc_segment6
                        ,lc_segment7
                        ,lc_type;
   EXIT WHEN lcu_get_cc%NOTFOUND;

   lc_count := lc_count + 1;

   IF gn_ccid1 IS NOT NULL THEN

      IF lc_type = 'DEFAULT' THEN
         lc_def_seg1 := lc_segment1;
         lc_def_seg2 := lc_segment2;
         lc_def_seg3 := lc_segment3;
         lc_def_seg4 := lc_segment4;
         lc_def_seg5 := lc_segment5;
         lc_def_seg6 := lc_segment6;
         lc_def_seg7 := lc_segment7;
      ELSE
         -- Get the segment1(Company) from non-default account for
         -- comparing the segment1 of default and non-default account
         lc_other_seg1 := lc_segment1;
         lc_other_seg5 := lc_segment5;
      END IF;

   END IF;

   END LOOP;
   CLOSE lcu_get_cc;


   IF lc_count > 0 THEN

      IF gn_ccid1 IS NOT NULL THEN

         IF lc_def_seg1 <> lc_other_seg1 THEN
            ---------------------------------------------------------------------------------------------
            -- If segment1(Company) of both the source and target orgs differ
            -- then segment5(Intercompany) of the account which is going to be populated for this network
            -- is replaced with segment1 of the other account
            ---------------------------------------------------------------------------------------------
            gn_ccid             := NULL;

            gn_code_combination := lc_def_seg1  ||gc_delimiter||
                                   lc_def_seg2  ||gc_delimiter||
                                   lc_def_seg3  ||gc_delimiter||
                                   lc_def_seg4  ||gc_delimiter||
                                   lc_other_seg1||gc_delimiter||
                                   lc_def_seg6  ||gc_delimiter||
                                   lc_def_seg7;

            OPEN lcu_validate_cc;
            FETCH lcu_validate_cc INTO gn_ccid;

               IF lcu_validate_cc%NOTFOUND THEN
                  -----------------------------------------------------------------------------------------
                  -- After replacing the segment5(Intercompany) if the new code combination formed does not
                  --  exists in Oracle EBS then it has to be created assuming that dynamic insert is on
                  -----------------------------------------------------------------------------------------

                  gn_ccid := FND_FLEX_EXT.GET_CCID(application_short_name => G_GL_SHORT_NAME                      -- IN  VARCHAR2
                                                  ,key_flex_code          => G_ACCNT_FLEX_CODE                    --  IN  VARCHAR2
                                                  ,structure_number       => gn_accnt_flex_struct_id              --  IN  NUMBER
                                                  ,validation_date        => FND_DATE.DATE_TO_CANONICAL(SYSDATE)  --  IN  VARCHAR2
                                                  ,concatenated_segments  => gn_code_combination                  --  IN  VARCHAR2
                                                  );
                  IF NVL(gn_ccid,0) = 0 THEN
                    --------------------------------------------------------------------------------------
                    -- If dynamic insert is not ON (or) if the code combination is not a valid combination
                    -- then get the error message.
                    --------------------------------------------------------------------------------------

                    gc_message_data := FND_FLEX_EXT.GET_MESSAGE;
                    gn_ccid         := NULL;

                  END IF;

               END IF;

            CLOSE lcu_validate_cc;

            IF gn_ccid IS NULL THEN

               gc_message_data := p_account_name||','||gc_message_data;

            END IF;

         ELSE
            gn_code_combination := lc_def_seg1  ||gc_delimiter||
                                   lc_def_seg2  ||gc_delimiter||
                                   lc_def_seg3  ||gc_delimiter||
                                   lc_def_seg4  ||gc_delimiter||
                                   lc_def_seg5  ||gc_delimiter||
                                   lc_def_seg6  ||gc_delimiter||
                                   lc_def_seg7;
         END IF;
      ELSE
         gn_code_combination := lc_segment1||gc_delimiter||
                                lc_segment2||gc_delimiter||
                                lc_segment3||gc_delimiter||
                                lc_segment4||gc_delimiter||
                                lc_segment5||gc_delimiter||
                                lc_segment6||gc_delimiter||
                                lc_segment7;

      END IF;
   ELSE
      gc_message_data := p_account_name||','||gc_message_data;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      IF lcu_get_cc%ISOPEN THEN
         CLOSE lcu_get_cc;
      END IF;
      IF lcu_validate_cc%ISOPEN THEN
         CLOSE lcu_validate_cc;
      END IF;
      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);

      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );
END GET_CODE_COMBINATION;
-- +=================================================================================+
-- | Name        :  GET_SRC_AND_TRGT_COUNTRIES                                       |
-- |                                                                                 |
-- | Description :  This procedure derives the source and target countries of the    |
-- |                 given source and target org ids.                                |
-- |                                                                                 |
-- | Parameters  :  p_source_org_id IN hr_all_organization_units.organization_id%TYPE|                                                      |
-- |                p_target_org_id IN hr_all_organization_units.organization_id%TYPE|
-- |                                                                                 |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE GET_SRC_AND_TRGT_COUNTRIES(p_source_org_id IN hr_all_organization_units.organization_id%TYPE
                                    ,p_target_org_id IN hr_all_organization_units.organization_id%TYPE
                                    )
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm VARCHAR2(26) := 'GET_SRC_AND_TRGT_COUNTRIES';
   -------------------------------------------------
   -- Cursor to get the source and target countries
   -------------------------------------------------
   CURSOR lcu_get_countries
   IS
   SELECT  HLA_SRC.country
          ,HLA_TRGT.country
   FROM    hr_locations_all HLA_SRC
          ,hr_locations_all HLA_TRGT
   WHERE   HLA_SRC.location_id = (SELECT HAOU.location_id
                                  FROM   hr_all_organization_units HAOU
                                  WHERE  HAOU.organization_id = p_source_org_id
                                 )
   AND     HLA_TRGT.location_id = (SELECT  HAOU.location_id
                                   FROM   hr_all_organization_units HAOU
                                   WHERE  HAOU.organization_id = p_target_org_id
                                  )
   ;
BEGIN
      --------------------------------------
      -- Get the source and target countries
      --------------------------------------

      OPEN lcu_get_countries;

      FETCH lcu_get_countries INTO gc_source_country,gc_target_country;

      CLOSE lcu_get_countries;

      IF gc_source_country IS NULL AND gc_target_country IS NULL THEN

         gc_message_data := get_fnd_message
                            (p_name => G_62502,p_1 => G_T3,p_v1 => gt_temp_shipnet_tbl(gn_temp_indx).source_inv_org
                                                            ||','||gt_temp_shipnet_tbl(gn_temp_indx).target_inv_org
                            );
         RAISE EX_NULL_COUNTRY;

      ELSIF gc_source_country IS NULL THEN

         gc_message_data := get_fnd_message
                            (p_name => G_62502,p_1 => G_T3,p_v1 => gt_temp_shipnet_tbl(gn_temp_indx).source_inv_org);

         RAISE EX_NULL_COUNTRY;

      ELSIF gc_target_country IS NULL THEN

         gc_message_data := get_fnd_message
                            (p_name => G_62502,p_1 => G_T3,p_v1 => gt_temp_shipnet_tbl(gn_temp_indx).target_inv_org);

         RAISE EX_NULL_COUNTRY;
      ELSE

         gt_temp_shipnet_tbl(gn_temp_indx).source_country := gc_source_country;
         gt_temp_shipnet_tbl(gn_temp_indx).target_country := gc_target_country;

      END IF;

EXCEPTION
   WHEN EX_NULL_COUNTRY THEN

      RAISE EX_NULL_COUNTRY;

   WHEN OTHERS THEN
      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);

      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );
END GET_SRC_AND_TRGT_COUNTRIES;

-- +========================================================================+
-- | Name        :  POPULATE_ACCOUNT_INFORMATION                            |
-- |                                                                        |
-- | Description :  This procedure populates the relevant account           |
-- |                 information for the given shipping network.            |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE POPULATE_ACCOUNT_INFORMATION
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm VARCHAR2(28) := 'POPULATE_ACCOUNT_INFORMATION';

BEGIN

   --------------------------------------------------------------------
   -- Deriving the code combinations for the given code combination ids
   --------------------------------------------------------------------

   gc_message_data := NULL;
   gn_ccid         := NULL;
   gn_ccid1        := NULL;

   IF gn_intransit_inv_account IS NOT NULL THEN

      gn_ccid := gn_intransit_inv_account;

      gt_temp_shipnet_tbl(gn_temp_indx).intransit_inv_account_id := gn_ccid;

      GET_CODE_COMBINATION('Intransit');

      gt_temp_shipnet_tbl(gn_temp_indx).intransit_inv_account := gn_code_combination;

   END IF;

   gn_ccid  := NULL;
   gn_ccid1 := NULL;

   gn_ccid := gn_inter_transfer_cr_account;

   gt_temp_shipnet_tbl(gn_temp_indx).interorg_transfer_cr_accnt_id := gn_ccid;

   GET_CODE_COMBINATION('Inter-org transfer credit');

   gt_temp_shipnet_tbl(gn_temp_indx).interorg_transfer_cr_account := gn_code_combination;

   gn_ccid  := NULL;
   gn_ccid1 := NULL;

   IF gn_src1_inter_receiv_account IS NULL THEN

      gn_ccid  := gn_src_inter_receiv_account;
      gn_ccid1 := gn_trgt_inter_receiv_account;

   ELSE

      gn_ccid := gn_src1_inter_receiv_account;
      gn_ccid1 := NULL;

   END IF;

   GET_CODE_COMBINATION('Inter-org receivables');

   gt_temp_shipnet_tbl(gn_temp_indx).interorg_receivables_accnt_id := gn_ccid;

   gt_temp_shipnet_tbl(gn_temp_indx).interorg_receivables_account := gn_code_combination;

   gn_ccid  := NULL;
   gn_ccid1 := NULL;

   IF gn_trgt1_inter_pay_account IS NULL THEN

      gn_ccid  := gn_trgt_inter_pay_account;
      gn_ccid1 := gn_src_inter_pay_account;
   ELSE
      gn_ccid  := gn_trgt1_inter_pay_account;
      gn_ccid1 := NULL;
   END IF;

   GET_CODE_COMBINATION('Inter-org payables');

   gt_temp_shipnet_tbl(gn_temp_indx).interorg_payables_account_id := gn_ccid;

   gt_temp_shipnet_tbl(gn_temp_indx).interorg_payables_account := gn_code_combination;

   gn_ccid  := NULL;
   gn_ccid1 := NULL;

   IF gc_purch_price_var_flag = 'Y' THEN

      gn_ccid := gn_interorg_price_var_account;

      GET_CODE_COMBINATION('Inter-org purchase price variance');

      gt_temp_shipnet_tbl(gn_temp_indx).interorg_price_var_account := gn_code_combination;
      gt_temp_shipnet_tbl(gn_temp_indx).interorg_price_var_account_id := gn_ccid;

   ELSE

      gt_temp_shipnet_tbl(gn_temp_indx).interorg_price_var_account := NULL;

   END IF;


   IF gc_process_type = G_PROCESS_TYPE_PREBUILD THEN
      -----------------------------------------------------------------------------
      -- For pre-build for every network before calling derive_default_accounts
      --  these variable should be null so as to derive the default values for that
      --  source and target orgs.
      -----------------------------------------------------------------------------
      gn_intransit_inv_account     := NULL;
      gn_src_inter_receiv_account  := NULL;
      gn_inter_transfer_cr_account := NULL;
      gn_src_inter_pay_account     := NULL;
      gn_interorg_price_var_account:= NULL;
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);
      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );
END POPULATE_ACCOUNT_INFORMATION;

-- +========================================================================+
-- | Name        :  GET_ACCNT_FLEX_STRUCTURE_ID                             |
-- |                                                                        |
-- | Description :  This procedure derives the structure id,delimiter       |
-- |                 for accounting flex field.                             |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE GET_ACCNT_FLEX_STRUCTURE_ID
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm VARCHAR2(27) := 'GET_ACCNT_FLEX_STRUCTURE_ID';
   --------------------------------------------------------------
   -- Cursor to get the structure id for the given structure code
   --------------------------------------------------------------
   CURSOR lcu_get_acnt_flex_struct_id
   IS
   SELECT FIFS.id_flex_num
         ,FIFS.concatenated_segment_delimiter
   FROM   fnd_id_flex_structures FIFS
         ,fnd_application FA
   WHERE  FIFS.application_id         = FA.application_id
   AND    FIFS.id_flex_code           = G_ACCNT_FLEX_CODE
   AND    FA.application_short_name   = G_GL_SHORT_NAME
   AND    FIFS.id_flex_structure_code = G_ACNT_FLEX_STRUCT_CODE
   ;
BEGIN
   gc_message_data := NULL;

   OPEN lcu_get_acnt_flex_struct_id;
   FETCH lcu_get_acnt_flex_struct_id INTO gn_accnt_flex_struct_id,gc_delimiter;

      IF lcu_get_acnt_flex_struct_id%NOTFOUND THEN

         gn_accnt_flex_struct_id := NULL;
         gc_message_data         := get_fnd_message(p_name => G_62504);

      END IF;
   CLOSE lcu_get_acnt_flex_struct_id;


EXCEPTION
   WHEN OTHERS THEN
      IF lcu_get_acnt_flex_struct_id%ISOPEN THEN
         CLOSE lcu_get_acnt_flex_struct_id;
      END IF;
      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);
      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );


END GET_ACCNT_FLEX_STRUCTURE_ID;

-- +========================================================================+
-- | Name        :  CHECK_SHIPNET_EXISTS                                    |
-- |                                                                        |
-- | Description :  This procedure checks if the given shipping network     |
-- |                 is already defined in the Oracle EBS.                  |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE CHECK_SHIPNET_EXISTS
IS
BEGIN
   SELECT G_YES
   INTO   gc_shipnet_exists
   FROM   mtl_interorg_parameters MIP
   WHERE  MIP.from_organization_id = gn_source_org_id
   AND    MIP.to_organization_id   = gn_target_org_id
   ;
EXCEPTION
   WHEN NO_DATA_FOUND THEN

      gc_shipnet_exists := G_NO;

END CHECK_SHIPNET_EXISTS;

-- +========================================================================+
-- | Name        :  FORM_REVERSE_NETWORK                                    |
-- |                                                                        |
-- | Description :  This procedure forms a new network that would be the    |
-- |                 reverse of the network that is just formed.            |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE FORM_REVERSE_NETWORK
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm VARCHAR2(20) := 'FORM_REVERSE_NETWORK';
BEGIN
   gn_temp_indx := gn_temp_indx + 1;
   -------------------------
   -- Source org information
   -------------------------
   gt_temp_shipnet_tbl(gn_temp_indx).source_inv_org      := gt_temp_shipnet_tbl(gn_temp_indx - 1).target_inv_org;
   gt_temp_shipnet_tbl(gn_temp_indx).source_org_type     := gt_temp_shipnet_tbl(gn_temp_indx - 1).target_org_type;
   gt_temp_shipnet_tbl(gn_temp_indx).source_org_number   := gt_temp_shipnet_tbl(gn_temp_indx - 1).target_org_number;
   gt_temp_shipnet_tbl(gn_temp_indx).source_org_id       := gt_temp_shipnet_tbl(gn_temp_indx - 1).target_org_id;
   gt_temp_shipnet_tbl(gn_temp_indx).source_org_code     := gt_temp_shipnet_tbl(gn_temp_indx - 1).target_org_code;
   gt_temp_shipnet_tbl(gn_temp_indx).source_country      := gt_temp_shipnet_tbl(gn_temp_indx - 1).target_country;
   gt_temp_shipnet_tbl(gn_temp_indx).source_sub_type     := gt_temp_shipnet_tbl(gn_temp_indx - 1).target_sub_type;
   gt_temp_shipnet_tbl(gn_temp_indx).source_default_xdoc := gt_temp_shipnet_tbl(gn_temp_indx - 1).target_default_xdoc;
   gt_temp_shipnet_tbl(gn_temp_indx).source_default_csc  := gt_temp_shipnet_tbl(gn_temp_indx - 1).target_default_csc;
   --------------------------------------
   -- Relationship information and others
   --------------------------------------
   IF gc_process_type = G_PROCESS_TYPE_PREBUILD THEN

      gt_temp_shipnet_tbl(gn_temp_indx).intransit_type               := gt_temp_shipnet_tbl(gn_temp_indx - 1).intransit_type;
      gt_temp_shipnet_tbl(gn_temp_indx).fob_point                    := gt_temp_shipnet_tbl(gn_temp_indx - 1).fob_point;
      gt_temp_shipnet_tbl(gn_temp_indx).interorg_transfer_code       := gt_temp_shipnet_tbl(gn_temp_indx - 1).interorg_transfer_code;
      gt_temp_shipnet_tbl(gn_temp_indx).receipt_routing_id           := gt_temp_shipnet_tbl(gn_temp_indx - 1).receipt_routing_id;
      gt_temp_shipnet_tbl(gn_temp_indx).internal_order_required_flag := gt_temp_shipnet_tbl(gn_temp_indx - 1).internal_order_required_flag;
      gt_temp_shipnet_tbl(gn_temp_indx).elemental_visibility_enabled := gt_temp_shipnet_tbl(gn_temp_indx - 1).elemental_visibility_enabled;
      gt_temp_shipnet_tbl(gn_temp_indx).manual_receipt_expense       := gt_temp_shipnet_tbl(gn_temp_indx - 1).manual_receipt_expense;

   ELSIF gc_process_type = G_PROCESS_TYPE_ONDEMAND THEN
      ----------------------------------------------------------------------------------------------------
      -- For dynamic process these information should be the default values and not the user passed values
      ----------------------------------------------------------------------------------------------------
      gt_temp_shipnet_tbl(gn_temp_indx).intransit_type               := G_INTRANSIT_ID;
      gt_temp_shipnet_tbl(gn_temp_indx).fob_point                    := G_FOB_RECEIPT_ID;
      gt_temp_shipnet_tbl(gn_temp_indx).interorg_transfer_code       := G_INTERORG_NONE_ID;
      gt_temp_shipnet_tbl(gn_temp_indx).receipt_routing_id           := G_RECEIPT_ROUTING_DIRECT_ID;
      gt_temp_shipnet_tbl(gn_temp_indx).internal_order_required_flag := G_INTERNAL_ORDER_REQUIRED_NO;
      gt_temp_shipnet_tbl(gn_temp_indx).elemental_visibility_enabled := G_ELEMENT_VISIBIL_ENABLED_NO;
      gt_temp_shipnet_tbl(gn_temp_indx).manual_receipt_expense       := G_MANUAL_RECEIPT_EXPENSE_NO;

   END IF;

   -------------------------
   -- Target org information
   -------------------------
   gt_temp_shipnet_tbl(gn_temp_indx).target_inv_org      := gt_temp_shipnet_tbl(gn_temp_indx - 1).source_inv_org;
   gt_temp_shipnet_tbl(gn_temp_indx).target_org_type     := gt_temp_shipnet_tbl(gn_temp_indx - 1).source_org_type;
   gt_temp_shipnet_tbl(gn_temp_indx).target_org_number   := gt_temp_shipnet_tbl(gn_temp_indx - 1).source_org_number;
   gt_temp_shipnet_tbl(gn_temp_indx).target_org_id       := gt_temp_shipnet_tbl(gn_temp_indx - 1).source_org_id;
   gt_temp_shipnet_tbl(gn_temp_indx).target_org_code     := gt_temp_shipnet_tbl(gn_temp_indx - 1).source_org_code;
   gt_temp_shipnet_tbl(gn_temp_indx).target_country      := gt_temp_shipnet_tbl(gn_temp_indx - 1).source_country;
   gt_temp_shipnet_tbl(gn_temp_indx).target_sub_type     := gt_temp_shipnet_tbl(gn_temp_indx - 1).source_sub_type;
   gt_temp_shipnet_tbl(gn_temp_indx).target_default_xdoc := gt_temp_shipnet_tbl(gn_temp_indx - 1).source_default_xdoc;
   gt_temp_shipnet_tbl(gn_temp_indx).target_default_csc  := gt_temp_shipnet_tbl(gn_temp_indx - 1).source_default_csc;
EXCEPTION
   WHEN OTHERS THEN
      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);
      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );

END FORM_REVERSE_NETWORK;

-- +========================================================================+
-- | Name        :  SET_SHIPNET_CREATE_FLAG                                 |
-- |                                                                        |
-- | Description :  This procedure updates the shipnet_create flag of the   |
-- |                 network combination formed now.                        |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE SET_SHIPNET_CREATE_FLAG
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm VARCHAR2(23) := 'SET_SHIPNET_CREATE_FLAG';
BEGIN

   IF (gc_creation_allowed = G_NO) OR (gc_across_countries = G_NO AND gc_same_country = G_NO) THEN

      gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create     := G_NO;
      gt_temp_shipnet_tbl(gn_temp_indx).message            := gc_message_data;
      gc_creation_allowed                                  := G_YES;

   ELSE
     gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create     := G_YES;

   END IF;

   gc_message_data := NULL;

EXCEPTION
   WHEN OTHERS THEN

      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);
      display_log(gc_message_data);

      gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create     := G_NO;
      gt_temp_shipnet_tbl(gn_temp_indx).message            := gc_message_data;

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );

      gc_message_data := NULL;

END SET_SHIPNET_CREATE_FLAG;
-- +========================================================================+
-- | Name        :  POPULATE_TARGET_ORG_INFO                                |
-- |                                                                        |
-- | Description :  This procedure populates the target org information     |
-- |                 in the temp shipnet table.                             |
-- |                                                                        |
-- | Parameters  :  p_ebs_org_number IN VARCHAR2                            |
-- |                                                                        |
-- +========================================================================+
PROCEDURE POPULATE_TARGET_ORG_INFO(p_ebs_org_number IN VARCHAR2)
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm VARCHAR2(24) := 'POPULATE_TARGET_ORG_INFO';
   ---------------------------------------------
   -- Cursor to get target org basic information
   ---------------------------------------------
   CURSOR lcu_get_target_info
   IS
   SELECT HAOU.name                   ebs_inv_org
         ,UPPER(HAOU.type)                   ebs_inv_org_type
         ,HAOU.attribute1             rms_org
         ,HAOU.organization_id        ebs_org_id
         ,MP.organization_code        ebs_org_code
   FROM   hr_all_organization_units   HAOU
         ,mtl_parameters MP
   WHERE  HAOU.organization_id = MP.organization_id
   AND    HAOU.attribute1      = p_ebs_org_number
   ;
   ------------------------------------------------
   -- Cursor to derive default XDOC,CSC and subtype
   ------------------------------------------------
   CURSOR lcu_default_csc_xdoc
   IS
   SELECT XIOLRA.default_wh_sw       default_xdoc
         ,XIOLRA.od_default_wh_csc_s default_csc
         ,XIOLRA.od_sub_type_cd_sw   src_sub_type
   FROM   xx_inv_org_loc_rms_attribute XIOLRA
   WHERE  XIOLRA.location_number_sw = p_ebs_org_number
   ;
BEGIN

   gc_message_data := NULL;

   OPEN lcu_get_target_info;
   FETCH lcu_get_target_info INTO  gt_temp_shipnet_tbl(gn_temp_indx).target_inv_org
                                  ,gt_temp_shipnet_tbl(gn_temp_indx).target_org_type
                                  ,gt_temp_shipnet_tbl(gn_temp_indx).target_org_number
                                  ,gt_temp_shipnet_tbl(gn_temp_indx).target_org_id
                                  ,gt_temp_shipnet_tbl(gn_temp_indx).target_org_code
                                  ;

   IF lcu_get_target_info%NOTFOUND THEN

      gc_message_data := get_fnd_message
                          (p_name => G_62505,p_1 => G_T3,p_v1 => p_ebs_org_number);

   ELSE

      OPEN lcu_default_csc_xdoc;
      FETCH lcu_default_csc_xdoc INTO gt_temp_shipnet_tbl(gn_temp_indx).target_default_xdoc
                                     ,gt_temp_shipnet_tbl(gn_temp_indx).target_default_csc
                                     ,gt_temp_shipnet_tbl(gn_temp_indx).target_sub_type;
      IF lcu_get_target_info%NOTFOUND THEN
         gc_message_data := get_fnd_message
                             (p_name => G_62506,p_1 => G_T3,p_v1 => gt_temp_shipnet_tbl(gn_temp_indx).target_inv_org);

      ELSE

         gc_target_org_code := gt_temp_shipnet_tbl(gn_temp_indx).target_org_code;

      END IF;

      CLOSE lcu_default_csc_xdoc;


   END IF;

   CLOSE lcu_get_target_info;
EXCEPTION
   WHEN OTHERS THEN
      IF lcu_get_target_info%ISOPEN THEN
         CLOSE lcu_get_target_info;
      END IF;
      IF lcu_default_csc_xdoc%ISOPEN THEN
         CLOSE lcu_default_csc_xdoc;
      END IF;
      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);
      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );
END POPULATE_TARGET_ORG_INFO;

-- +========================================================================+
-- | Name        :  FORM_DEFAULT_NETWORKS                                   |
-- |                                                                        |
-- | Description :  This procedure forms the network between the source org |
-- |                 and its default XDOC and CSC. This is called from      |
-- |                 pre-build.                                             |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE FORM_DEFAULT_NETWORKS
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm           VARCHAR2(21) := 'FORM_DEFAULT_NETWORKS';
   -------------------------
   -- Local scalar variables
   -------------------------
   lc_dummy_xdoc   xx_inv_org_loc_rms_attribute.default_wh_sw%TYPE;
   lc_dummy_csc    xx_inv_org_loc_rms_attribute.od_default_wh_csc_s%TYPE;
BEGIN

   BEGIN
      IF gc_default_xdoc IS NOT NULL THEN

         IF gc_across_countries = G_NO THEN

            gc_same_country     := G_NO;

         END IF;
         ------------------------------------------------------------------------------------------
         -- Now make Org picked from HR_ALL_ORGANIZATION_UNITS as source and default XDOC as target
         ------------------------------------------------------------------------------------------
         --------------------------------------------------------
         -- Deriving subtype ,default xdoc and csc of target XDOC
         --------------------------------------------------------
         POPULATE_TARGET_ORG_INFO(p_ebs_org_number => gc_default_xdoc --IN VARCHAR2
                                 );

         IF gc_message_data IS NULL THEN

            GET_SRC_AND_TRGT_COUNTRIES(p_source_org_id => gt_temp_shipnet_tbl(gn_temp_indx).source_org_id -- IN hr_all_organization_units.organization_id%TYPE
                                      ,p_target_org_id => gt_temp_shipnet_tbl(gn_temp_indx).target_org_id -- IN hr_all_organization_units.organization_id%TYPE
                                      );

            IF gc_message_data IS NULL THEN

               IF gc_across_countries = G_NO THEN

                  IF gc_source_country = gc_target_country THEN

                     gc_same_country := G_YES;
                  ELSE
                     gc_message_data := get_fnd_message(p_name => G_62507);
                  END IF;

               END IF;

               SET_SHIPNET_CREATE_FLAG;

               IF gc_bi_directional = G_YES AND gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create = G_YES THEN
                  ------------------------------------------------------------------------------------------
                  -- Now make default XDOC as source and Org picked from HR_ALL_ORGANIZATION_UNITS as target
                  ------------------------------------------------------------------------------------------
                  FORM_REVERSE_NETWORK;

                  SET_SHIPNET_CREATE_FLAG;

               END IF;
            ELSE
               gc_creation_allowed := G_NO;

               SET_SHIPNET_CREATE_FLAG;

            END IF;--GET_SRC_AND_TRGT_COUNTRIES gc_message_data IS NULL
         ELSE

            gc_creation_allowed := G_NO;

            SET_SHIPNET_CREATE_FLAG;

         END IF;--POPULATE_TARGET_ORG_INFO gc_message_data IS NULL

      END IF;--gc_default_xdoc IS NOT NULL
   EXCEPTION
      WHEN EX_NULL_COUNTRY THEN

         gc_creation_allowed := G_NO;

         SET_SHIPNET_CREATE_FLAG;
   END;

   BEGIN
      IF gc_default_csc IS NOT NULL THEN

         IF gc_default_xdoc IS NULL THEN

            -----------------------------------------------------------------------------------------
            -- Now make Org picked from HR_ALL_ORGANIZATION_UNITS as source and default CSC as target
            -----------------------------------------------------------------------------------------
            -------------------------------------------------------
            -- Deriving subtype, default xdoc and csc of target CSC
            -------------------------------------------------------
            POPULATE_TARGET_ORG_INFO(p_ebs_org_number => gc_default_csc --IN VARCHAR2
                                    );

            IF gc_message_data IS NULL THEN

               GET_SRC_AND_TRGT_COUNTRIES(p_source_org_id => gt_temp_shipnet_tbl(gn_temp_indx).source_org_id -- IN hr_all_organization_units.organization_id%TYPE
                                         ,p_target_org_id => gt_temp_shipnet_tbl(gn_temp_indx).target_org_id -- IN hr_all_organization_units.organization_id%TYPE
                                         );
               IF gc_message_data IS NULL THEN

                  IF gc_across_countries = G_NO THEN

                     IF gc_source_country = gc_target_country THEN

                        gc_same_country := G_YES;

                     ELSE
                        gc_message_data := get_fnd_message(p_name => G_62507);
                     END IF;

                  END IF;

                  SET_SHIPNET_CREATE_FLAG;

                  IF gc_bi_directional = G_YES AND gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create = G_YES THEN

                     -----------------------------------------------------------------------------------------
                     -- Now make default CSC as source and Org picked from HR_ALL_ORGANIZATION_UNITS as target
                     -----------------------------------------------------------------------------------------
                     FORM_REVERSE_NETWORK;

                     SET_SHIPNET_CREATE_FLAG;
                  END IF;
               ELSE
                  gc_creation_allowed := G_NO;

                  SET_SHIPNET_CREATE_FLAG;
               END IF;--GET_SRC_AND_TRGT_COUNTRIES gc_message_data IS NULL
            ELSE

               gc_creation_allowed := G_NO;

               SET_SHIPNET_CREATE_FLAG;

            END IF;--POPULATE_TARGET_ORG_INFO gc_message_data IS NULL
         ELSE

            gn_temp_indx := gn_temp_indx + 1;
            ---------------------------------------------------------------------------------
            -- Now make Org picked from HR_ALL_ORGANIZATION_UNITS as source and CSC as target
            ---------------------------------------------------------------------------------
            gt_temp_shipnet_tbl(gn_temp_indx).source_inv_org               := gt_temp_shipnet_tbl(0).source_inv_org;
            gt_temp_shipnet_tbl(gn_temp_indx).source_org_type              := gt_temp_shipnet_tbl(0).source_org_type;
            gt_temp_shipnet_tbl(gn_temp_indx).source_org_number            := gt_temp_shipnet_tbl(0).source_org_number;
            gt_temp_shipnet_tbl(gn_temp_indx).source_org_id                := gt_temp_shipnet_tbl(0).source_org_id;
            gt_temp_shipnet_tbl(gn_temp_indx).source_org_code              := gt_temp_shipnet_tbl(0).source_org_code;
            gt_temp_shipnet_tbl(gn_temp_indx).intransit_type               := gt_temp_shipnet_tbl(0).intransit_type;
            gt_temp_shipnet_tbl(gn_temp_indx).fob_point                    := gt_temp_shipnet_tbl(0).fob_point;
            gt_temp_shipnet_tbl(gn_temp_indx).interorg_transfer_code       := gt_temp_shipnet_tbl(0).interorg_transfer_code;
            gt_temp_shipnet_tbl(gn_temp_indx).receipt_routing_id           := gt_temp_shipnet_tbl(0).receipt_routing_id;
            gt_temp_shipnet_tbl(gn_temp_indx).internal_order_required_flag := gt_temp_shipnet_tbl(0).internal_order_required_flag;
            gt_temp_shipnet_tbl(gn_temp_indx).elemental_visibility_enabled := gt_temp_shipnet_tbl(0).elemental_visibility_enabled;
            gt_temp_shipnet_tbl(gn_temp_indx).manual_receipt_expense       := gt_temp_shipnet_tbl(0).manual_receipt_expense;
            gt_temp_shipnet_tbl(gn_temp_indx).source_sub_type              := gt_temp_shipnet_tbl(0).source_sub_type;
            gt_temp_shipnet_tbl(gn_temp_indx).source_default_csc           := gt_temp_shipnet_tbl(0).source_default_csc;
            gt_temp_shipnet_tbl(gn_temp_indx).source_default_xdoc          := gt_temp_shipnet_tbl(0).source_default_xdoc;

            POPULATE_TARGET_ORG_INFO(p_ebs_org_number => gc_default_csc --IN VARCHAR2
                                    );
            IF gc_message_data IS NULL THEN

               GET_SRC_AND_TRGT_COUNTRIES(p_source_org_id => gt_temp_shipnet_tbl(gn_temp_indx).source_org_id -- IN hr_all_organization_units.organization_id%TYPE
                                         ,p_target_org_id => gt_temp_shipnet_tbl(gn_temp_indx).target_org_id -- IN hr_all_organization_units.organization_id%TYPE
                                         );
               IF gc_message_data IS NULL THEN

                  IF gc_across_countries = G_NO THEN

                     IF gc_source_country = gc_target_country THEN

                        gc_same_country := G_YES;

                     ELSE
                        gc_message_data := get_fnd_message(p_name => G_62507);
                     END IF;

                  END IF;

                  -------------------------------------------------------
                  -- Deriving subtype, default xdoc and csc of target CSC
                  -------------------------------------------------------
                  SET_SHIPNET_CREATE_FLAG;

                  IF gc_bi_directional = G_YES AND gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create = G_YES THEN
                     -----------------------------------------------------------------------------------------
                     -- Now make default CSC as source and Org picked from HR_ALL_ORGANIZATION_UNITS as target
                     -----------------------------------------------------------------------------------------
                     FORM_REVERSE_NETWORK;

                     SET_SHIPNET_CREATE_FLAG;

                  END IF;
               ELSE
                  gc_creation_allowed := G_NO;

                  SET_SHIPNET_CREATE_FLAG;
               END IF;--GET_SRC_AND_TRGT_COUNTRIES gc_message_data IS NULL
            ELSE
               gc_creation_allowed := G_NO;

               SET_SHIPNET_CREATE_FLAG;
            END IF;--POPULATE_TARGET_ORG_INFO gc_message_data IS NULL

         END IF;--gc_default_xdoc IS NULL
      END IF;--gc_default_csc IS NOT NULL
   EXCEPTION
      WHEN EX_NULL_COUNTRY THEN

         gc_creation_allowed := G_NO;

         SET_SHIPNET_CREATE_FLAG;
   END;
EXCEPTION
   WHEN OTHERS THEN

      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);
      gc_creation_allowed := G_NO;

      SET_SHIPNET_CREATE_FLAG;

      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );
END FORM_DEFAULT_NETWORKS;

-- +========================================================================+
-- | Name        :  CREATION_RULE_VALIDATION                                |
-- |                                                                        |
-- | Description :  This procedure validates the source organization against|
-- |                 its creation rule.                                     |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE CREATION_RULE_VALIDATION
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm                        VARCHAR2(24)  := 'CREATION_RULE_VALIDATION';
   -------------------------
   -- Local scalar variables
   -------------------------
   lc_creation_rule_desc        fnd_flex_values_vl.description%TYPE := NULL;
   lc_creation_rule             fnd_flex_values_vl.attribute2%TYPE  := NULL;
   -----------------------------------------------------
   -- Cursor to the creation rule for the given Org type
   -----------------------------------------------------
   CURSOR lcu_creation_rule
   IS
   SELECT FFV.description     creation_desc
         ,FFV.attribute2      creation_rule
   FROM   fnd_flex_value_sets FFVS
         ,fnd_flex_values_vl  FFV
   WHERE  FFVS.flex_value_set_id   = FFV.flex_value_set_id
   AND    FFVS.flex_value_set_name = G_VALIDATION_VALUSET
   AND    FFV.enabled_flag         = G_YES
   AND    FFV.attribute1           = gc_source_org_type
   AND    UPPER(FFV.attribute7)    = G_CREATION_RULE_TYPE
   ;

BEGIN
   ---------------------------------------
   -- Creation rule validation starts here
   ---------------------------------------
   lc_creation_rule_desc := NULL;
   lc_creation_rule      := NULL;
   gc_message_data       := NULL;

   OPEN  lcu_creation_rule;
   FETCH lcu_creation_rule INTO lc_creation_rule_desc
                               ,lc_creation_rule;
   CLOSE lcu_creation_rule;

   IF lc_creation_rule IS NOT NULL AND LENGTH(lc_creation_rule) = 4 AND (INSTR(lc_creation_rule,G_YES) <> 0 OR INSTR(lc_creation_rule,G_NO) <> 0 )THEN

      gt_temp_shipnet_tbl(gn_temp_indx).cr_applicable_rule := lc_creation_rule;
      gt_temp_shipnet_tbl(gn_temp_indx).cr_rule_type       := lc_creation_rule_desc;
      gc_creation_allowed                                  := SUBSTR(lc_creation_rule,1,1);

      IF gc_creation_allowed = G_YES THEN
         --------------------------------------------------------------------------
         -- Creation of shipping network is allowed for this inventory organization
         --------------------------------------------------------------------------
         -----------------------------------------------
         -- Check if bi-directional networks are allowed
         -----------------------------------------------
         IF SUBSTR(lc_creation_rule,4,1) = G_YES THEN

            gc_bi_directional := G_YES;
         ELSE

            gc_bi_directional := G_NO;
         END IF;

         --------------------------------------------------------
         -- Check if shipping network is allowed across countries
         --------------------------------------------------------
         IF SUBSTR(lc_creation_rule,3,1) = G_YES THEN

            gc_across_countries := G_YES;
         ELSE

            gc_across_countries := G_NO;
         END IF;
         ----------------------------------------------------------------------
         -- Check if the process is Dynamic and dynamic networks can be created
         ----------------------------------------------------------------------

         IF gc_process_type = G_PROCESS_TYPE_ONDEMAND THEN

            IF SUBSTR(lc_creation_rule,2,1) = G_YES THEN
               ------------------------
               -- For On-Demand process
               ------------------------
               GET_SRC_AND_TRGT_COUNTRIES(p_source_org_id => gt_temp_shipnet_tbl(gn_temp_indx).source_org_id -- IN hr_all_organization_units.organization_id%TYPE
                                         ,p_target_org_id => gt_temp_shipnet_tbl(gn_temp_indx).target_org_id -- IN hr_all_organization_units.organization_id%TYPE
                                         );


               IF gc_across_countries = G_YES THEN
                  ----------------------------------------------------------------
                  -- Create network between From and To org given as the parameter
                  ----------------------------------------------------------------
                  SET_SHIPNET_CREATE_FLAG;

                  IF gc_bi_directional = G_YES THEN

                     ---------------------------------------------------
                     -- Now make To org as source and From org as target
                     ---------------------------------------------------
                     FORM_REVERSE_NETWORK;

                     SET_SHIPNET_CREATE_FLAG;

                  END IF;

               ELSIF gc_across_countries = G_NO THEN

                  gc_same_country     := G_NO;
                  gc_across_countries := G_NO;
                  --------------------------------------------------------------
                  -- Since shipping network is not allowed across countries,
                  --  ensure that the from and the to org given as the parameter
                  --  are within the same country.
                  --------------------------------------------------------------
                  IF gc_source_country = gc_target_country THEN
                     gc_same_country := G_YES;

                  END IF;

                  -------------------------------------------------------------
                  -- Create network between from and to org given as parameter
                  --  But make sure that the shipnet_create flag is set to "N
                  --  if source and target org is in different country.
                  -------------------------------------------------------------
                  IF gc_same_country = G_YES THEN
                     ----------------------------------------------------------------
                     -- Create network between From and To org given as the parameter
                     ----------------------------------------------------------------
                     SET_SHIPNET_CREATE_FLAG;
                     IF gc_bi_directional = G_YES THEN

                     ---------------------------------------------------
                     -- Now make To org as source and From org as target
                     ---------------------------------------------------
                     FORM_REVERSE_NETWORK;

                     SET_SHIPNET_CREATE_FLAG;

                     END IF;
                  ELSE
                     ------------------------------------------------------------
                     -- No network between From and To org given as the parameter
                     ------------------------------------------------------------
                     gc_message_data := get_fnd_message(p_name => G_62507);
                     SET_SHIPNET_CREATE_FLAG;

                  END IF;

               END IF;--gc_across_countries = G_YES
            ELSE
               gc_creation_allowed := G_NO;

               gc_message_data := get_fnd_message(p_name => G_62508,p_1=> G_T3,p_v1=> gc_source_org_type);

               SET_SHIPNET_CREATE_FLAG;
            END IF;--SUBSTR(lc_creation_rule,2,1) = G_YES
            ------------------------
            -- END On-Demand process
            ------------------------
         ELSIF gc_process_type = G_PROCESS_TYPE_PREBUILD THEN
               ------------------------
               -- For Pre-Build process
               ------------------------
               OPEN gcu_default_csc_xdoc(gc_source_org_num);
               FETCH gcu_default_csc_xdoc INTO gc_default_xdoc,gc_default_csc,gc_source_sub_type;
                  IF gcu_default_csc_xdoc%NOTFOUND THEN
                     gc_default_xdoc    := NULL;
                     gc_default_csc     := NULL;
                     gc_source_sub_type := NULL;
                  END IF;
               CLOSE gcu_default_csc_xdoc;


               IF (gc_default_xdoc IS NOT NULL) OR (gc_default_csc IS NOT NULL) THEN
                  ------------------------------------------------------------
                  -- Assigning subtype, default xdoc and csc of the source org
                  ------------------------------------------------------------
                  gt_temp_shipnet_tbl(gn_temp_indx).source_sub_type    := gc_source_sub_type;
                  gt_temp_shipnet_tbl(gn_temp_indx).source_default_csc := gc_default_csc;
                  gt_temp_shipnet_tbl(gn_temp_indx).source_default_xdoc:= gc_default_xdoc;

                  FORM_DEFAULT_NETWORKS;

               ELSE
                  -------------------------------------------------------
                  -- No pre-build network for this inventory organization
                  -------------------------------------------------------
                  gc_creation_allowed := G_NO;

                  gc_message_data := get_fnd_message(p_name => G_62509);

                  SET_SHIPNET_CREATE_FLAG;
               END IF;
               ------------------------
               -- END Pre-Build process
               ------------------------
         END IF;--gc_process_type = G_PROCESS_TYPE_ONDEMAND
      ELSE
         ------------------------------------------------------------------------------
         -- Creation of shipping network is not allowed for this inventory organization
         ------------------------------------------------------------------------------
         gc_message_data := get_fnd_message(p_name => G_62510,p_1=> G_T3,p_v1=> gc_source_org_type);

         SET_SHIPNET_CREATE_FLAG;

      END IF;--gc_creation_allowed = G_YES
   ELSE
      -------------------------------------------------------------------------------
      -- If creation rule is not defined for Drop ship then dont consider it as error
      -- it will be restricted by restriction rule any way.
      -------------------------------------------------------------------------------
      IF gc_source_org_type IN (G_DROP_SHIP) THEN

         SET_SHIPNET_CREATE_FLAG;

      ELSE

         gc_creation_allowed := G_NO;

         gc_message_data := get_fnd_message(p_name => G_62519,p_1=> G_T5,p_v1=> G_CREATION_RULE_STRING);

         gc_invalid_creation_rule_flag := 'Y';

         SET_SHIPNET_CREATE_FLAG;

      END IF;
   END IF;

   gc_message_data := NULL;

EXCEPTION
   WHEN OTHERS THEN
      IF gcu_default_csc_xdoc%ISOPEN THEN
         CLOSE gcu_default_csc_xdoc;
      END IF;
      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);
      gc_creation_allowed := G_NO;

      SET_SHIPNET_CREATE_FLAG;

      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );

END CREATION_RULE_VALIDATION;

-- +========================================================================+
-- | Name        :  RESTRICTION_RULE_VALIDATION                             |
-- |                                                                        |
-- | Description :  This procedure verifies whether the given shipping      |
-- |                 network is to be restricted or not.                    |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE RESTRICTION_RULE_VALIDATION
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm                          VARCHAR2(27)  := 'RESTRICTION_RULE_VALIDATION';
   -------------------------
   -- Local scalar variables
   -------------------------
   lc_restriction_rule            VARCHAR2(100) := NULL;
   lc_restriction_entity fnd_flex_values_vl.attribute3%TYPE := NULL;
   lc_err_msg                     VARCHAR2(100) := NULL;
   ------------------------------------------------------------------
   -- Cursor to fetch all the restriction rules defined in the system
   ------------------------------------------------------------------
   CURSOR lcu_restriction_rule
   IS
   SELECT FFV.description     restriction_desc
         ,FFV.attribute3      restriction_entity
         ,FFV.attribute4      source_entity
         ,FFV.attribute5      target_entity
         ,FFV.attribute6      code_reference
   FROM   fnd_flex_value_sets FFVS
         ,fnd_flex_values_vl  FFV
   WHERE  FFVS.flex_value_set_id   = FFV.flex_value_set_id
   AND    FFVS.flex_value_set_name = G_VALIDATION_VALUSET
   AND    FFV.enabled_flag         = G_YES
   AND    UPPER(FFV.attribute7)    = G_RESTRICTION_RULE_TYPE
   ORDER BY FFV.attribute6 asc
   ;
BEGIN
   gc_message_data := NULL;

   FOR temp_indx IN gt_temp_shipnet_tbl.FIRST..gt_temp_shipnet_tbl.LAST
   LOOP
      BEGIN
         ------------------------------------------------------
         -- Initializing global temporary index so that correct
         --  record is accessed across the procedures.
         ------------------------------------------------------
         gn_temp_indx := temp_indx;

         IF gt_temp_shipnet_tbl(temp_indx).shipnet_create = G_YES THEN

            -------------------------------------------------------------------
            -- Restriction rule validation starts here for the records that are
            --  through the creation rule validation.
            -------------------------------------------------------------------

            lc_restriction_rule   := NULL;
            lc_restriction_entity := NULL;
            lc_err_msg            := NULL;

            FOR lr_rule IN lcu_restriction_rule
            LOOP
               BEGIN

                  lc_restriction_entity := lr_rule.restriction_entity;

                  IF lr_rule.code_reference = 1 THEN
                     ----------------------------
                     -- Restriction by subtype NT
                     ----------------------------
                     IF gt_temp_shipnet_tbl(temp_indx).source_sub_type IS NOT NULL
                     AND gt_temp_shipnet_tbl(temp_indx).target_sub_type IS NOT NULL
                     AND gt_temp_shipnet_tbl(temp_indx).source_org_type <> G_DROP_SHIP
                     AND gt_temp_shipnet_tbl(temp_indx).target_org_type <> G_DROP_SHIP THEN

                        IF (gt_temp_shipnet_tbl(temp_indx).source_sub_type = lr_rule.source_entity OR gt_temp_shipnet_tbl(temp_indx).target_sub_type = lr_rule.target_entity)
                        THEN--Source or Target org type is NT

                           IF gt_temp_shipnet_tbl(temp_indx).source_sub_type = gt_temp_shipnet_tbl(temp_indx).target_sub_type THEN

                              ------------------------------------------------------
                              --When both Source and Target subtypes are NT
                              -- Check if the target is source's default XDOC or CSC
                              -- and
                              -- Check if the source is target's default XDOC or CSC
                              --   then allow network.
                              ------------------------------------------------------
                              IF (NOT(NVL(gt_temp_shipnet_tbl(temp_indx).source_default_xdoc,G_989) = gt_temp_shipnet_tbl(temp_indx).target_org_number
                                  OR
                                  NVL(gt_temp_shipnet_tbl(temp_indx).source_default_csc,G_989) = gt_temp_shipnet_tbl(temp_indx).target_org_number
                                    )
                                 )
                                 OR
                                 (
                                 NOT(NVL(gt_temp_shipnet_tbl(temp_indx).target_default_xdoc,G_989) = gt_temp_shipnet_tbl(temp_indx).source_org_number
                                  OR
                                  NVL(gt_temp_shipnet_tbl(temp_indx).target_default_csc,G_989) = gt_temp_shipnet_tbl(temp_indx).source_org_number
                                   )
                                 )
                             THEN

                                 lc_restriction_rule            := lr_rule.restriction_desc;
                                 EXIT;

                              END IF;
                           ELSIF gt_temp_shipnet_tbl(temp_indx).source_sub_type = G_SUBTYPE_NT THEN
                              ------------------------------------------------------
                              --When Source subtype is NT
                              -- Check if the target is source's default XDOC or CSC
                              --   then allow network from source to target
                              ------------------------------------------------------

                              IF (gt_temp_shipnet_tbl(temp_indx).source_sub_type = lr_rule.source_entity OR gt_temp_shipnet_tbl(temp_indx).target_sub_type = lr_rule.target_entity)
                              THEN

                                 IF NOT(NVL(gt_temp_shipnet_tbl(temp_indx).source_default_xdoc,G_989) = gt_temp_shipnet_tbl(temp_indx).target_org_number
                                     OR
                                     NVL(gt_temp_shipnet_tbl(temp_indx).source_default_csc,G_989) = gt_temp_shipnet_tbl(temp_indx).target_org_number
                                    ) THEN

                                    lc_restriction_rule            := lr_rule.restriction_desc;
                                    EXIT;

                                 END IF;

                              END IF;

                           ELSIF gt_temp_shipnet_tbl(temp_indx).target_sub_type = G_SUBTYPE_NT THEN
                              ------------------------------------------------------
                              --When Target subtype is NT
                              -- Check if the Source is target's default XDOC or CSC
                              --   then allow network from source to target
                              ------------------------------------------------------

                              IF (gt_temp_shipnet_tbl(temp_indx).source_sub_type = lr_rule.source_entity OR gt_temp_shipnet_tbl(temp_indx).target_sub_type = lr_rule.target_entity)
                              THEN

                                 IF NOT(NVL(gt_temp_shipnet_tbl(temp_indx).target_default_xdoc,G_989) = gt_temp_shipnet_tbl(temp_indx).source_org_number
                                     OR
                                     NVL(gt_temp_shipnet_tbl(temp_indx).target_default_csc,G_989) = gt_temp_shipnet_tbl(temp_indx).source_org_number
                                    ) THEN

                                    lc_restriction_rule            := lr_rule.restriction_desc;
                                    EXIT;

                                 END IF;

                              END IF;

                           END IF;--gt_temp_shipnet_tbl(temp_indx).source_sub_type = gt_temp_shipnet_tbl(temp_indx).target_sub_type

                        END IF;--Source or Target org type is NT

                     ELSIF gt_temp_shipnet_tbl(temp_indx).source_org_type <> G_DROP_SHIP AND gt_temp_shipnet_tbl(temp_indx).target_org_type <> G_DROP_SHIP THEN

                        lc_restriction_rule            := lr_rule.restriction_desc;

                        lc_err_msg := get_fnd_message(p_name => G_62511);

                        EXIT;

                     END IF;


                  ELSIF lr_rule.code_reference = 2 THEN
                     ----------------------------
                     -- Restriction by subtype PF
                     ----------------------------
                     IF gt_temp_shipnet_tbl(temp_indx).source_sub_type IS NOT NULL
                     AND gt_temp_shipnet_tbl(temp_indx).target_sub_type IS NOT NULL
                     AND gt_temp_shipnet_tbl(temp_indx).source_org_type <> G_DROP_SHIP
                     AND gt_temp_shipnet_tbl(temp_indx).target_org_type <> G_DROP_SHIP THEN

                        IF (gt_temp_shipnet_tbl(temp_indx).source_sub_type = lr_rule.source_entity OR gt_temp_shipnet_tbl(temp_indx).target_sub_type = lr_rule.target_entity)
                        THEN

                           lc_restriction_rule            := lr_rule.restriction_desc;
                           EXIT;

                        END IF;
                     ELSIF gt_temp_shipnet_tbl(temp_indx).source_org_type <> G_DROP_SHIP AND gt_temp_shipnet_tbl(temp_indx).target_org_type <> G_DROP_SHIP THEN

                        lc_restriction_rule := lr_rule.restriction_desc;
                        lc_err_msg          := get_fnd_message(p_name => G_62511);
                        EXIT;

                     END IF;

                  ELSIF lr_rule.code_reference = 3 THEN
                     ------------------------------------
                     -- Restriction by Org-type Drop ship
                     ------------------------------------
                     IF gt_temp_shipnet_tbl(temp_indx).source_org_type IS NOT NULL AND gt_temp_shipnet_tbl(temp_indx).target_org_type IS NOT NULL THEN

                        IF (gt_temp_shipnet_tbl(temp_indx).source_org_type = lr_rule.source_entity OR gt_temp_shipnet_tbl(temp_indx).target_org_type = lr_rule.target_entity)
                        THEN

                           lc_restriction_rule            := lr_rule.restriction_desc;
                           EXIT;

                        END IF;

                     ELSE

                        lc_restriction_rule            := lr_rule.restriction_desc;
                        lc_err_msg := get_fnd_message(p_name => G_62512);
                        EXIT;

                     END IF;

                  ELSIF lr_rule.code_reference = 4 THEN
                     ---------------------------------
                     -- Restriction by Countries CA-US
                     ---------------------------------

                     IF gt_temp_shipnet_tbl(temp_indx).source_country = lr_rule.source_entity AND gt_temp_shipnet_tbl(temp_indx).target_country = lr_rule.target_entity
                     THEN
                        lc_restriction_rule            := lr_rule.restriction_desc;
                        EXIT;
                     END IF;

                  END IF;--lr_rule.code_reference = 1
               EXCEPTION
                  WHEN OTHERS THEN
                     gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create := G_NO;
                     gt_temp_shipnet_tbl(gn_temp_indx).message        := SQLERRM;
               END;
            END LOOP;

            IF lc_restriction_rule IS NOT NULL OR lc_err_msg IS NOT NULL THEN
               ----------------------------------------------------------------------------------------
               -- If any restriction is found then validation for the given shipping network is stopped
               --  and then error information is logged in main shipnet table for reporting purpose.
               ----------------------------------------------------------------------------------------
               IF lc_err_msg IS NULL THEN

                  gc_message_data := get_fnd_message(p_name => G_62513);

               ELSE

                  gc_message_data := lc_err_msg;

               END IF;

               gc_creation_allowed := G_NO;

               SET_SHIPNET_CREATE_FLAG;

               gt_temp_shipnet_tbl(temp_indx).rs_applicable_rule := lc_restriction_rule;
               gt_temp_shipnet_tbl(temp_indx).rs_rule_type       := lc_restriction_entity;

            ELSE
               IF gc_process_type = G_PROCESS_TYPE_ONDEMAND THEN

                  IF  gn_param_to_id   = gt_temp_shipnet_tbl(temp_indx).source_org_id
                  AND gn_param_from_id = gt_temp_shipnet_tbl(temp_indx).target_org_id THEN
                     -----------------------------------------------------------------------
                     -- For dynamic reverse network accounts will be derived by the
                     --  derive_default_accounts procedure. Hence initialize all the account
                     --  to null to indicate that user has not passed any values and its the
                     --  responsibility of this program to derive it.
                     -----------------------------------------------------------------------
                     gn_intransit_inv_account        := NULL;
                     gn_interorg_price_var_account   := NULL;
                     gn_inter_transfer_cr_account    := NULL;
                     gn_trgt1_inter_pay_account      := NULL;
                     gn_src1_inter_receiv_account    := NULL;
                  END IF;
               END IF;
               ----------------------------------------------------------------------------------------
               -- If a shipping network is through all the validations
               --  then derive and populate the default account information
               ----------------------------------------------------------------------------------------
               DERIVE_DEFAULT_ACCOUNTS(p_src_org_id    => gt_temp_shipnet_tbl(temp_indx).source_org_id --IN mtl_parameters.organization_id%TYPE
                                      ,p_tgt_org_id    => gt_temp_shipnet_tbl(temp_indx).target_org_id --IN mtl_parameters.organization_id%TYPE
                                      ,p_fob_point     => gt_temp_shipnet_tbl(temp_indx).fob_point
                                      ,p_transfer_type => gt_temp_shipnet_tbl(temp_indx).intransit_type
                                      );

               IF gc_message_data IS NULL THEN

                  POPULATE_ACCOUNT_INFORMATION;

                  IF gc_message_data IS NOT NULL THEN

                     gc_message_data := get_fnd_message
                                        (p_name => G_62514,p_1 => G_T5,p_v1 => SUBSTR(gc_message_data,1,LENGTH(gc_message_data)-1));

                     gc_creation_allowed := G_NO;

                     SET_SHIPNET_CREATE_FLAG;

                  END IF;

               ELSE

                  gc_creation_allowed := G_NO;

                  SET_SHIPNET_CREATE_FLAG;
               END IF;


            END IF;

         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create := G_NO;
            gt_temp_shipnet_tbl(gn_temp_indx).message        := SQLERRM;
      END;

   END LOOP;
   gc_message_data := NULL;
EXCEPTION
   WHEN OTHERS THEN
      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);

      gc_creation_allowed := G_NO;

      SET_SHIPNET_CREATE_FLAG;

      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );
END RESTRICTION_RULE_VALIDATION;
-- +========================================================================+
-- | Name        :  PRINT                                                   |
-- |                                                                        |
-- | Description :  This procedure is just a collection of all the output   |
-- |                 statements that would be required for this package.    |
-- |                 You have to pass the relevant type to get your work    |
-- |                 done.                                                  |
-- |                                                                        |
-- | Parameters  :  p_type IN VARCHAR2                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE PRINT(p_type IN VARCHAR2)
IS
BEGIN
   IF p_type = 'PARAMETER INFO' THEN

      IF gc_param_report_mode = 'Y' THEN

         display_out(RPAD('=',11,'='));
         display_out(RPAD('Parameters: ',11,' '));
         display_out(RPAD('=',11,'='));
         display_out('');
         display_out(RPAD('1. Report only mode ',21,' ')||'= '||gc_param_report_mode);
         display_out(RPAD('2. Source org type ',21,' ')||'= '||gc_param_source_org_type);
         display_out(RPAD('3. From Organization ',21,' ')||'= '||gc_param_from_org_name);
         display_out('');
         display_out(' Information about shipping network that would be created:');
         display_out(RPAD('=',58,'='));

      END IF;

   ELSIF p_type = 'STATISTICS' THEN
         display_out('--------------------------------');
         display_out('Summary from Validation Process:');         
         display_out('--------------------------------');
      IF NVL(gc_param_source_org_type,G_989) <> G_NON_TRADE THEN
         display_out('');
         display_out('Total Number of shipping networks formed(except NON-TRADE)                   : '||gn_total_org_excpt_nontrade);
         display_out('Total Number of shipping networks that would be created(except NON-TRADE)    : '||gn_totl_excpt_nontrade_valid);
         display_out('Total Number of shipping networks that would not be created(except NON-TRADE): '||gn_totl_excpt_nontrade_invalid);
      END IF;

      IF gc_non_trade = 'Y' THEN

         display_out('');
         display_out('Total number of NON-TRADE orgs read                                   : '||gn_total_non_trade_orgs);
         display_out('Total number of NON-TRADE shipping networks formed                    : '||gn_total_nontrade_net);
         display_out('Total number of NON-TRADE shipping networks that would be created     : '||gn_total_nontrade_net_valid);
         display_out('Total number of NON-TRADE shipping networks that would not be created : '||gn_total_nontrade_net_invalid);

      END IF;

   ELSIF p_type = 'SHIPNET_HEADER' THEN
      display_out('');
      display_out(RPAD('=',300,'='));
      display_out(RPAD('From Org',42,' ')||'   '||RPAD('To Org',42,' ')||'   '||RPAD('Create',6,' ')||'   '||RPAD('Creation Rule Type',55,' ')||'   '||RPAD('Rule',4,' ')||'   '||RPAD('Restriction Rule Type',21,' ')||'   '||RPAD('Rule',40,' ')||'   Message');
      display_out(RPAD(' ',90,' ')                                                 ||'(Y/N)?');
      display_out(RPAD('=',300,'='));

   ELSIF p_type = 'NON-TRADE HEADER' THEN

      display_out(RPAD('=',300,'='));
      display_out(get_fnd_message(p_name => G_62515,p_1 => G_T3,p_v1 => gt_main_shipnet_tbl(gn_temp_indx).source_inv_org));
      display_out(RPAD('=',300,'='));

   ELSIF p_type = 'SHIPNET INFO' THEN

      display_out(RPAD(NVL(gt_main_shipnet_tbl(gn_temp_indx).source_inv_org,'NA'),42,' ')||'   '||RPAD(NVL(gt_main_shipnet_tbl(gn_temp_indx).target_inv_org,'NA'),42,' ')
                 ||'   '||RPAD(LPAD(NVL(gt_main_shipnet_tbl(gn_temp_indx).shipnet_create,'NA'),2,' '),6,' ')||'   '||RPAD(NVL(gt_main_shipnet_tbl(gn_temp_indx).cr_rule_type,'NA'),55,' ')
                 ||'   '||RPAD(NVL(gt_main_shipnet_tbl(gn_temp_indx).cr_applicable_rule,'NA'),4,' ')||'   '||RPAD(NVL(gt_main_shipnet_tbl(gn_temp_indx).rs_rule_type,'NA'),21,' ')
                 ||'   '||RPAD(NVL(gt_main_shipnet_tbl(gn_temp_indx).rs_applicable_rule,'NA'),40,' ')||'   '||NVL(gt_main_shipnet_tbl(gn_temp_indx).message,'NA')
                 );
   ELSIF p_type = 'NO RECORDS' THEN
      display_out('');
      display_out(get_fnd_message(p_name => G_62516));

   END IF;--p_type = 'PARAMETER INFO'
END PRINT;

-- +========================================================================+
-- | Name        :  RENDER_REPORT                                           |
-- |                                                                        |
-- | Description :  This procedure is called from BUILD_REPORT either to    |
-- |                 get statistics information or to print the shipnet     |
-- |                 information.                                           |
-- |                                                                        |
-- | Parameters  :  p_just_statistics IN VARCHAR2                           |
-- |                                                                        |
-- +========================================================================+
PROCEDURE RENDER_REPORT(p_just_statistics IN VARCHAR2)
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm                         VARCHAR2(13)                    := 'RENDER_REPORT';
   -------------------------
   -- Local scalar variables
   -------------------------
   lc_non_trade_org              hr_organization_units.name%type := null;
BEGIN
      lc_non_trade_org := G_989;

      FOR main_indx IN gt_main_shipnet_tbl.FIRST..gt_main_shipnet_tbl.LAST
      LOOP
         gn_temp_indx := main_indx;

         IF gt_main_shipnet_tbl(main_indx).source_org_type = G_NON_TRADE  THEN

            IF lc_non_trade_org <> gt_main_shipnet_tbl(main_indx).source_inv_org THEN

               lc_non_trade_org := gt_main_shipnet_tbl(main_indx).source_inv_org;
               gc_non_trade := 'Y';
               gn_total_non_trade_orgs := gn_total_non_trade_orgs + 1;

               IF p_just_statistics = G_NO THEN

                  PRINT('NON-TRADE HEADER');

               END IF;

            END IF;

            gn_total_nontrade_net := gn_total_nontrade_net + 1;

            IF gt_main_shipnet_tbl(main_indx).shipnet_create = G_YES THEN

               gn_total_nontrade_net_valid := gn_total_nontrade_net_valid + 1;

            ELSIF gt_main_shipnet_tbl(main_indx).shipnet_create = G_NO THEN

               gn_total_nontrade_net_invalid := gn_total_nontrade_net_invalid + 1;
            END IF;

         ELSE

            gn_total_org_excpt_nontrade := gn_total_org_excpt_nontrade + 1;

            IF gt_main_shipnet_tbl(main_indx).shipnet_create = G_YES THEN

               gn_totl_excpt_nontrade_valid := gn_totl_excpt_nontrade_valid + 1;

            ELSIF gt_main_shipnet_tbl(main_indx).shipnet_create = G_NO THEN

               gn_totl_excpt_nontrade_invalid := gn_totl_excpt_nontrade_invalid + 1;
            END IF;
         END IF;

         IF p_just_statistics = G_NO THEN

            PRINT('SHIPNET INFO');
         END IF;
         --------------------------------------------------------------------------------------
         -- Log the validation error
         -- Ensure that validation errors are not logged already by the render_report procedure
         -- by checking the flag gc_is_log_validation_err
         --------------------------------------------------------------------------------------
         IF  gt_main_shipnet_tbl(main_indx).shipnet_create = G_NO
         AND gc_is_log_validation_err = G_NO
         AND gc_param_report_mode = G_NO
         THEN

            LOG_ERROR(p_exception => 'VALIDATION_ERROR'                     --IN VARCHAR2
                     ,p_message   => gt_main_shipnet_tbl(main_indx).message --IN VARCHAR2
                     ,p_code      => 1                                      --IN PLS_INTEGER
                     );

         END IF;


      END LOOP;
      gc_is_log_validation_err := G_YES;

END RENDER_REPORT;

-- +========================================================================+
-- | Name        :  BUILD_REPORT                                            |
-- |                                                                        |
-- | Description :  This procedure prints the shipping networks that would  |
-- |                 be created and rejected with appropriate reason.       |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE BUILD_REPORT(p_report_only_mode IN VARCHAR2)
IS
   lc_nm VARCHAR2(12) := 'BUILD_REPORT';
BEGIN

   gc_non_trade := 'N';
   -----------------------------------------------------
   -- Print the parameter information in the output file
   -----------------------------------------------------
   PRINT('PARAMETER INFO');
   -------------------------------------------------
   -- Initialize global variables used to statistics
   -------------------------------------------------
   gn_total_non_trade_orgs         := 0;
   gn_total_nontrade_net_invalid   := 0;
   gn_total_nontrade_net_valid     := 0;
   gn_totl_excpt_nontrade_invalid  := 0;
   gn_totl_excpt_nontrade_valid    := 0;
   gn_total_nontrade_net           := 0;

   IF gt_main_shipnet_tbl.COUNT > 0 THEN

      RENDER_REPORT(p_just_statistics => G_YES);

      IF p_report_only_mode = G_NO THEN

         PRINT('STATISTICS');

      ELSE

         PRINT('STATISTICS');
         ----------------
         -- Report Header
         ----------------
         PRINT('SHIPNET_HEADER');


         RENDER_REPORT(p_just_statistics => G_NO);
      END IF;
   ELSE
      PRINT('NO RECORDS');
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);
      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );
END BUILD_REPORT;

-- +========================================================================+
-- | Name        :  FROM_TEMP_TO_MAIN_TABLE                                 |
-- |                                                                        |
-- | Description :  This procedure loops through the temporary shipnet table|
-- |                 that has the current org type shipping networks and    |
-- |                 cross checks with the main table/database for its      |
-- |                 existence.                                             |
-- |                                                                        |
-- | Parameters  :  NA                                                      |
-- |                                                                        |
-- +========================================================================+
PROCEDURE FROM_TEMP_TO_MAIN_TABLE
IS
   lc_nm                VARCHAR2(23) := 'FROM_TEMP_TO_MAIN_TABLE';
   -------------------------------------------------------------------
   -- To check if the shipnet already exists in the main PL/SQL table.
   -------------------------------------------------------------------
   lc_duplicate_shipnet VARCHAR2(5) := NULL;
BEGIN
   ------------------------------------------------------------------------
   -- Appending temporary shipnet table records into the main shipnet table
   ------------------------------------------------------------------------
   FOR temp_indx IN gt_temp_shipnet_tbl.FIRST..gt_temp_shipnet_tbl.LAST
   LOOP
      BEGIN
         gn_source_org_id     := gt_temp_shipnet_tbl(temp_indx).source_org_id;
         gn_target_org_id     := gt_temp_shipnet_tbl(temp_indx).target_org_id;
         lc_duplicate_shipnet := G_NO;

         IF gc_non_trade_nw_processing = 'N' THEN

            ---------------------------------------------------------------
            -- Check if the shipnet already exists in the main PL/SQL table
            ---------------------------------------------------------------
            IF gt_main_shipnet_tbl.COUNT > 0 THEN

               FOR main_indx IN gt_main_shipnet_tbl.FIRST..gt_main_shipnet_tbl.LAST
               LOOP
                  BEGIN
                     IF     NVL(gt_main_shipnet_tbl(main_indx).source_org_id,G_989_N) = NVL(gn_source_org_id,G_989_N)
                        AND NVL(gt_main_shipnet_tbl(main_indx).target_org_id,G_989_N) = NVL(gn_target_org_id,G_989_N)
                     THEN

                        lc_duplicate_shipnet := G_YES;

                        EXIT;

                    END IF;
                 EXCEPTION
                    WHEN OTHERS THEN
                        gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create := G_NO;
                        gt_temp_shipnet_tbl(gn_temp_indx).message        := SQLERRM;
                  END;

               END LOOP;
            END IF;

         END IF;


         IF lc_duplicate_shipnet = G_NO THEN
            ------------------------------------------------------
            -- Check if this shipping network exists in Oracle EBS
            ------------------------------------------------------
            CHECK_SHIPNET_EXISTS;

            ---------------------------------------------------
            -- If shipping network does not exists in EBS then
            --  append the temp shipnet table record to the
            --  main shipnet table.
            ---------------------------------------------------

            IF gc_shipnet_exists = G_NO THEN

               gt_main_shipnet_tbl(gn_main_indx)                := gt_temp_shipnet_tbl(temp_indx);
               gt_main_shipnet_tbl(gn_main_indx).shipnet_exists := gc_shipnet_exists;

               gn_main_indx := gn_main_indx + 1;

            END IF;


         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create := G_NO;
            gt_temp_shipnet_tbl(gn_temp_indx).message        := SQLERRM;
      END;
   END LOOP;

   gc_message_data := NULL;

EXCEPTION
   WHEN OTHERS THEN
      gc_message_data := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);
      display_log(gc_message_data);

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => gc_message_data --IN VARCHAR2
               ,p_code      => -1              --IN PLS_INTEGER
               );
END FROM_TEMP_TO_MAIN_TABLE;

-- +========================================================================+
-- | Name        :  PRE_BUILD                                               |
-- |                                                                        |
-- | Description :  This procedure picks up the unprocessed inventory orgs  |
-- |                 from HR_ALL_ORGANIZATION_UNITS and builds the shipping |
-- |                 networks between its default XDOC and CSC only if its  |
-- |                 through all the creation and restriction rules.        |
-- |                 This program will be called by the pre-build java      |
-- |                 concurrent program which gets the p_shipnet_tbl that   |
-- |                 contains the shipping network information gathered by  |
-- |                 this program.                                          |
-- |                                                                        |
-- | Parameters  :  p_report_only_mode     IN  VARCHAR2                     |
-- |                p_source_org_type      IN  VARCHAR2                     |
-- |                p_from_organization_id IN  NUMBER                       |
-- |                p_shipnet_tbl          OUT shipnet_tbl_type             |
-- |                x_error_code           OUT NUMBER                       |
-- |                x_error_message        OUT VARCHAR2                     |
-- |                                                                        |
-- +========================================================================+
PROCEDURE PRE_BUILD(p_report_only_mode     IN  VARCHAR2
                   ,p_source_org_type      IN  VARCHAR2
                   ,p_from_organization_id IN  NUMBER
                   ,p_shipnet_tbl          OUT shipnet_tbl_type
                   ,x_error_code           OUT NUMBER
                   ,x_error_message        OUT VARCHAR2
                   )
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm                           VARCHAR2(9)                                 := 'PRE_BUILD';
   -------------------------
   -- Local scalar variables
   -------------------------
   ---------------------------
   -- Shipnet flag information
   ---------------------------
   ln_internal_order_req_flag      PLS_INTEGER                                 := NULL;
   lc_elem_visibility_enabled      VARCHAR2(1)                                 := NULL;
   lc_manual_receipt_expense       VARCHAR2(1)                                 := NULL;
   -----------------------------------
   -- Shipnet relationship information
   -----------------------------------
   ln_transfer_type                mtl_interorg_parameters.intransit_type%TYPE := NULL;
   ln_fob_point                    PLS_INTEGER                                 := NULL;
   ln_interorg_transfer_code       PLS_INTEGER                                 := NULL;
   ln_receipt_routing_id           PLS_INTEGER                                 := NULL;


   ----------------------------------------------------------------------------------
   -- Cursor to fetch all unprocessed inventory orgs from HR_ORGANIZATION_UNITS TABLE
   ----------------------------------------------------------------------------------
   CURSOR lcu_inv_org_to_process(p_from_org_id IN PLS_INTEGER
                                ,p_source_org_type IN VARCHAR2
                                )
   IS
   SELECT HAOU.name                   ebs_inv_org
         ,UPPER(HAOU.type)            ebs_inv_org_type
         ,HAOU.attribute1             rms_org
         ,HAOU.organization_id        ebs_org_id
         ,MP.organization_code        ebs_org_code
   FROM   hr_all_organization_units   HAOU
         ,mtl_parameters MP
   WHERE  HAOU.organization_id        = NVL(p_from_org_id,HAOU.organization_id)
   AND    HAOU.organization_id        = MP.organization_id
   AND    UPPER(HAOU.type)            = NVL(p_source_org_type,UPPER(HAOU.type))
   AND    UPPER(HAOU.type)           <> G_NON_TRADE
   ;
   --------------------------------------------------
   -- Cursor to fetch all the NON-TRADE organizations
   --------------------------------------------------
   CURSOR lcu_from_non_trade_orgs
   IS
   SELECT HAOU.name                   ebs_inv_org
         ,UPPER(HAOU.type)            ebs_inv_org_type
         ,HAOU.organization_id        ebs_org_id
         ,MP.organization_code        ebs_org_code
   FROM   hr_all_organization_units   HAOU
         ,mtl_parameters MP
   WHERE  HAOU.organization_id = MP.organization_id
   AND    UPPER(HAOU.type)     = G_NON_TRADE
   AND    HAOU.organization_id = NVL(p_from_organization_id,HAOU.organization_id)
   ;
   -----------------------------------------------------
   -- Cursor to fetch all inventory organizations except
   --   Drop ship, Template, Item Master, Validation
   --   and Hierarchy Node Orgs to create network from
   --   all NON-TRADE organziations
   -----------------------------------------------------
   CURSOR lcu_to_orgs(p_from_org_id IN mtl_parameters.organization_id%TYPE)
   IS
   SELECT HAOU.name                   ebs_inv_org
         ,UPPER(HAOU.type)            ebs_inv_org_type
         ,HAOU.organization_id        ebs_org_id
         ,MP.organization_code        ebs_org_code
   FROM   hr_all_organization_units   HAOU
         ,mtl_parameters MP
   WHERE  HAOU.organization_id        = MP.organization_id
   AND    HAOU.organization_id       <> p_from_org_id
   AND    UPPER(HAOU.type) NOT IN (G_DROP_SHIP
                                  ,G_TEMPLATE
                                  ,G_ITEM_MASTER
                                  ,G_VALIDATION_ORG
                                  ,G_HIERARCHY_NODE
                                  )
   ;

BEGIN
   --------------------------------------------------------
   -- Initialize the global variables with parameter values
   -- Used in BUILD_REPORT procedure.
   --------------------------------------------------------
   gc_param_source_org_type        := p_source_org_type;
   gc_param_report_mode            := p_report_only_mode;
   gc_invalid_creation_rule_flag   := 'N';
   ----------------------------------------------------------------------
   -- To print the from organization name in the output capture then name
   --  only if from org parameter is not null
   ----------------------------------------------------------------------
   BEGIN
      IF p_from_organization_id IS NOT NULL THEN

         SELECT HAOU.name
         INTO   gc_param_from_org_name
         FROM   hr_all_organization_units HAOU
         WHERE  HAOU.organization_id = p_from_organization_id
         ;

      END IF;
   END;
   ------------------------------------------------------
   -- Initialize the global variables with default values
   ------------------------------------------------------
   gc_process_type                 := G_PROCESS_TYPE_PREBUILD;
   ln_transfer_type                := G_INTRANSIT_ID;
   ln_fob_point                    := G_FOB_RECEIPT_ID;
   ln_interorg_transfer_code       := G_INTERORG_NONE_ID;
   ln_receipt_routing_id           := G_RECEIPT_ROUTING_DIRECT_ID;
   ln_internal_order_req_flag      := G_INTERNAL_ORDER_REQUIRED_NO;
   lc_elem_visibility_enabled      := G_ELEMENT_VISIBIL_ENABLED_NO;
   lc_manual_receipt_expense       := G_MANUAL_RECEIPT_EXPENSE_NO;
   -----------------------------------------------------------------------
   -- In pre-build accounts will be derived by the derive_default_accounts
   --  procedure. Hence initialize all the account to null to indicate that
   --  user has not passed any values and its the responsibility of this
   --  program to derive it.
   -----------------------------------------------------------------------
   gn_intransit_inv_account        := NULL;
   gn_interorg_price_var_account   := NULL;
   gn_inter_transfer_cr_account    := NULL;
   gn_trgt1_inter_pay_account      := NULL;
   gn_src1_inter_receiv_account    := NULL;
   -----------------------
   --Other initializations
   -----------------------
   gc_message_data := NULL;
   gc_is_log_validation_err := G_NO;
   -----------------------------------------
   -- Get accounting flex field structure id
   --  which will be used in deriving
   --  delimiter, ccid.
   -----------------------------------------
   GET_ACCNT_FLEX_STRUCTURE_ID;

   IF gc_message_data IS NOT NULL THEN

      RAISE EX_ERR_ACNT_FLEX_STRUCT_ID;

   END IF;
   -----------------------------------------------------------
   -- Initialize the global variables with their initial value
   -----------------------------------------------------------
   gn_main_indx                    := 0;
   --------------------------------------------------------------------------
   -- This flag is used in FROM_TEMP_TO_MAIN_TABLE procedure to differentiate
   --  the NON-TRADE processing and other PRE-BUILD processing.
   --------------------------------------------------------------------------
   gc_non_trade_nw_processing      := 'N';

   -----------------------------------------------
   -- Pre-Building of shipping network starts here
   -----------------------------------------------
   FOR lcu_inv_org IN lcu_inv_org_to_process(p_from_org_id     => p_from_organization_id  --IN PLS_INTEGER
                                            ,p_source_org_type => p_source_org_type       -- IN VARCHAR2
                                            )
   LOOP
      BEGIN
         ----------------------------------------------------------------
         -- For every inventory org do the following business validations
         ----------------------------------------------------------------
         -------------------------------------
         -- Initializing the temp PL/SQL table
         -------------------------------------
         gt_temp_shipnet_tbl.delete;
         gn_temp_indx       := 0;
         gc_source_org_type := lcu_inv_org.ebs_inv_org_type;
         gc_source_org_code := lcu_inv_org.ebs_org_code;
         gc_source_org_num  := lcu_inv_org.rms_org;
         -------------------------------------------------
         -- If Source org type is null then raise an error
         -------------------------------------------------
         IF gc_source_org_type IS NULL THEN
            RAISE EX_SOURCE_ORG_NULL;
         END IF;
         ----------------------------------------------------------------------
         -- Initialize the source org information in the temporary PL/SQL table
         ----------------------------------------------------------------------
         gt_temp_shipnet_tbl(gn_temp_indx).source_org_type              := gc_source_org_type;
         gt_temp_shipnet_tbl(gn_temp_indx).source_inv_org               := lcu_inv_org.ebs_inv_org;
         gt_temp_shipnet_tbl(gn_temp_indx).source_org_id                := lcu_inv_org.ebs_org_id;
         gt_temp_shipnet_tbl(gn_temp_indx).source_org_number            := gc_source_org_num;
         gt_temp_shipnet_tbl(gn_temp_indx).source_org_code              := gc_source_org_code;

         gt_temp_shipnet_tbl(gn_temp_indx).intransit_type               := ln_transfer_type;
         gt_temp_shipnet_tbl(gn_temp_indx).fob_point                    := ln_fob_point;
         gt_temp_shipnet_tbl(gn_temp_indx).interorg_transfer_code       := ln_interorg_transfer_code;
         gt_temp_shipnet_tbl(gn_temp_indx).receipt_routing_id           := ln_receipt_routing_id;
         gt_temp_shipnet_tbl(gn_temp_indx).internal_order_required_flag := ln_internal_order_req_flag;
         gt_temp_shipnet_tbl(gn_temp_indx).elemental_visibility_enabled := lc_elem_visibility_enabled;
         gt_temp_shipnet_tbl(gn_temp_indx).manual_receipt_expense       := lc_manual_receipt_expense;

         ------------------------------------
         -- Call creation rule validation API
         ------------------------------------
         CREATION_RULE_VALIDATION;

         ---------------------------------------
         -- Call restriction rule validation API
         ---------------------------------------
         RESTRICTION_RULE_VALIDATION;


         FROM_TEMP_TO_MAIN_TABLE;
      EXCEPTION
         WHEN EX_SOURCE_ORG_NULL THEN
            gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create := G_NO;
            gt_temp_shipnet_tbl(gn_temp_indx).message        := get_fnd_message(p_name => G_62521);
         WHEN OTHERS THEN
            gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create := G_NO;
            gt_temp_shipnet_tbl(gn_temp_indx).message        := SQLERRM;
      END;

   END LOOP
   ;
   ---------------------------------------------------------------
   -- Forming uni-directional networks from NONTRADE organizations
   --  to all other inventory organizations except
   --   Drop ship, Template, Item Master, Validation
   --   and Hierarchy Node Orgs
   ---------------------------------------------------------------
   gc_non_trade_nw_processing := 'Y';

   IF NVL(p_source_org_type,G_NON_TRADE) = G_NON_TRADE THEN

      FOR lr_from_org IN lcu_from_non_trade_orgs
      LOOP
         BEGIN
            -------------------------------------
            -- Initializing the temp PL/SQL table
            -------------------------------------
            gt_temp_shipnet_tbl.delete;
            gn_temp_indx       := 0;

            FOR lr_to_org IN lcu_to_orgs(lr_from_org.ebs_org_id)
            LOOP
               BEGIN
                  gt_temp_shipnet_tbl(gn_temp_indx).source_org_type              := lr_from_org.ebs_inv_org_type;
                  gt_temp_shipnet_tbl(gn_temp_indx).source_inv_org               := lr_from_org.ebs_inv_org;
                  gt_temp_shipnet_tbl(gn_temp_indx).source_org_id                := lr_from_org.ebs_org_id;
                  gt_temp_shipnet_tbl(gn_temp_indx).source_org_code              := lr_from_org.ebs_org_code;

                  -- Modified intranist type from intransit to direct - Bug fix -START 1.1
                  -- for direct intransit type fob, routing id is not necessary
                  gt_temp_shipnet_tbl(gn_temp_indx).intransit_type               := G_DIRECT_ID;
                  gt_temp_shipnet_tbl(gn_temp_indx).fob_point                    := NULL;
                  gt_temp_shipnet_tbl(gn_temp_indx).receipt_routing_id           := NULL;
                  -- Modified intranist type from intransit to direct - Bug fix -END 1.1
                  gt_temp_shipnet_tbl(gn_temp_indx).interorg_transfer_code       := ln_interorg_transfer_code;
                  gt_temp_shipnet_tbl(gn_temp_indx).internal_order_required_flag := ln_internal_order_req_flag;
                  gt_temp_shipnet_tbl(gn_temp_indx).elemental_visibility_enabled := lc_elem_visibility_enabled;
                  gt_temp_shipnet_tbl(gn_temp_indx).manual_receipt_expense       := lc_manual_receipt_expense;

                  gt_temp_shipnet_tbl(gn_temp_indx).target_org_type              := lr_to_org.ebs_inv_org_type;
                  gt_temp_shipnet_tbl(gn_temp_indx).target_inv_org               := lr_to_org.ebs_inv_org;
                  gt_temp_shipnet_tbl(gn_temp_indx).target_org_id                := lr_to_org.ebs_org_id;
                  gt_temp_shipnet_tbl(gn_temp_indx).target_org_code              := lr_to_org.ebs_org_code;

                  DERIVE_DEFAULT_ACCOUNTS(p_src_org_id    => gt_temp_shipnet_tbl(gn_temp_indx).source_org_id --IN mtl_parameters.organization_id%TYPE
                                         ,p_tgt_org_id    => gt_temp_shipnet_tbl(gn_temp_indx).target_org_id --IN mtl_parameters.organization_id%TYPE
                                         ,p_fob_point     => gt_temp_shipnet_tbl(gn_temp_indx).fob_point
                                         ,p_transfer_type => gt_temp_shipnet_tbl(gn_temp_indx).intransit_type
                                         );

                  IF gc_message_data IS NULL THEN

                     POPULATE_ACCOUNT_INFORMATION;

                     IF gc_message_data IS NULL THEN

                        gc_creation_allowed := G_YES;

                        SET_SHIPNET_CREATE_FLAG;

                     ELSE
                        gc_message_data := get_fnd_message
                                           (p_name => G_62514,p_1 => G_T5,p_v1 => SUBSTR(gc_message_data,1,LENGTH(gc_message_data)-1));

                        gc_creation_allowed := G_NO;

                        SET_SHIPNET_CREATE_FLAG;

                     END IF;

                  ELSE

                     gc_creation_allowed := G_NO;

                     SET_SHIPNET_CREATE_FLAG;
                  END IF;

                  gn_temp_indx := gn_temp_indx + 1;
               EXCEPTION
                  WHEN OTHERS THEN
                     gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create := G_NO;
                     gt_temp_shipnet_tbl(gn_temp_indx).message        := SQLERRM;
               END;

            END LOOP;

            FROM_TEMP_TO_MAIN_TABLE;
         EXCEPTION
            WHEN OTHERS THEN
               gt_temp_shipnet_tbl(gn_temp_indx).shipnet_create := G_NO;
               gt_temp_shipnet_tbl(gn_temp_indx).message        := SQLERRM;
         END;

      END LOOP;
   END IF;

   ----------------------------------------------------------------------------
   -- If user asks for report mode then print the shipnet information in output
   --  (Includes shipnet that would get created and also those not get created
   --    with respective reson.)
   ----------------------------------------------------------------------------
   BUILD_REPORT(p_report_only_mode => p_report_only_mode);

   p_shipnet_tbl := gt_main_shipnet_tbl;

   --------------------------------------------------------------------
   -- If creation rule is invalid for source org types except drop ship
   --  then give a warning code to the java concurrent program
   --------------------------------------------------------------------

   IF (gn_total_non_trade_orgs + gn_total_org_excpt_nontrade) > 0 THEN

      IF (gn_total_nontrade_net_valid + gn_totl_excpt_nontrade_valid) > 0 THEN

         IF gc_invalid_creation_rule_flag = 'Y' THEN

            p_shipnet_tbl(0).error_code := 1;
            p_shipnet_tbl(0).error_message := get_fnd_message(p_name => G_62519,p_1=> G_T5,p_v1=> G_CREATION_RULE_STRING);

         END IF;
      END IF;

   ELSE
      p_shipnet_tbl(0).error_code := 1;
      p_shipnet_tbl(0).error_message := get_fnd_message(p_name => G_62516);
   END IF;

EXCEPTION
   WHEN EX_ERR_ACNT_FLEX_STRUCT_ID THEN
         x_error_code := -1;

         x_error_message := gc_message_data;

         display_log(x_error_message);

         LOG_ERROR(p_exception => 'EX_ERR_ACNT_FLEX_STRUCT_ID' --IN VARCHAR2
                  ,p_message   => x_error_message              --IN VARCHAR2
                  ,p_code      => x_error_code                 --IN PLS_INTEGER
                  );
         p_shipnet_tbl(0).error_code := -1;
         p_shipnet_tbl(0).error_message := gc_message_data;

   WHEN OTHERS THEN
      x_error_code    := -1;
      x_error_message := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);

      display_log(x_error_message);

      ROLLBACK;

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => x_error_message --IN VARCHAR2
               ,p_code      => x_error_code    --IN PLS_INTEGER
               );
      p_shipnet_tbl(0).error_code := -1;
      p_shipnet_tbl(0).error_message := x_error_message;

END PRE_BUILD;

-- +=================================================================================================================================+
-- | Name        :  DYNAMIC_BUILD                                                                                                    |
-- |                                                                                                                                 |
-- | Description :  This API validates the given source and destination organizations against its creation and restriction rules and |
-- |                 creates the shipping networks that are through all the validation.                                              |
-- |---------------------------------------------------------------------------------------------------------------------------------|
-- | Parameters                       Type                Valid Values                Default                                        |
-- |---------------------------------------------------------------------------------------------------------------------------------|
-- | p_from_organization_id           IN  NUMBER   |Vaild inventory organization    | NA                                             |
-- |                                               |                                |                                                |
-- | p_to_organization_id             IN  NUMBER   |Vaild inventory organization    | NA                                             |
-- |                                               |                                |                                                |
-- | p_transfer_type                  IN  NUMBER   |1(Direct),2(Intransit)          | 2                                              |
-- |                                               |                                |                                                |
-- | p_fob_point                      IN  NUMBER   |1(Shipment),2(Receipt)          | 2                                              |
-- |                                               |                                |                                                |
-- | p_interorg_transfer_code         IN  NUMBER   |1(None),2(Requested value)      | 1                                              |
-- |                                               | ,3(Requested %),4(Predefined %)|                                                |
-- |                                               |                                |                                                |
-- | p_receipt_routing_id             IN  NUMBER   |1(Standard),2(Inspection)       | 3                                              |
-- |                                               | ,3(Direct)                     |                                                |
-- |                                               |                                |                                                |
-- | p_internal_order_required_flag   IN  NUMBER   |1(Yes),2(No)                    | 2                                              |
-- |                                               |                                |                                                |
-- | p_intransit_inv_account          IN  NUMBER   |Valid code combination id       | From p_from_organization_id                    |
-- |                                               |                                |  (mtl_parameters.intransit_inv_account)        |
-- |                                               |                                |                                                |
-- | p_interorg_transfer_cr_account   IN  NUMBER   |Valid code combination id       | From p_from_organization_id                    |
-- |                                               |                                |  (mtl_parameters.interorg_transfer_cr_account) |
-- |                                               |                                |                                                |
-- | p_interorg_receivables_account   IN  NUMBER   |Valid code combination id       | From p_from_organization_id                    |
-- |                                               |                                |  (mtl_parameters.interorg_receivables_account) |
-- |                                               |                                |                                                |
-- | p_interorg_payables_account      IN  NUMBER   |Valid code combination id       | From p_to_organization_id                      |
-- |                                               |                                |  (mtl_parameters.interorg_payables_account)    |
-- |                                               |                                |                                                |
-- | p_interorg_price_var_account     IN  NUMBER   |Valid code combination id       | From p_to_organization_id                      |
-- |                                               |                                |  (mtl_parameters.interorg_price_var_account)   |
-- |                                               |                                |                                                |
-- | p_elemental_visibility_enabled   IN  VARCHAR2 |Y(Yes),N(No)                    | N                                              |
-- |                                               |                                |                                                |
-- | p_manual_receipt_expense         IN  VARCHAR2 |Y(Yes),N(No)                    | N                                              |
-- |---------------------------------------------------------------------------------------------------------------------------------|
-- | x_status                         OUT VARCHAR2 |S-Success, E-Error                                                               |
-- | x_error_code                     OUT NUMBER   |NULL-Success, -1-Error                                                           |
-- | x_error_message                  OUT VARCHAR2 |Relevant error message                                                           |
-- +=================================================================================================================================+
PROCEDURE DYNAMIC_BUILD(p_from_organization_id           IN  NUMBER
                       ,p_to_organization_id             IN  NUMBER
                       ,p_transfer_type                  IN  NUMBER   DEFAULT G_INTRANSIT_ID
                       ,p_fob_point                      IN  NUMBER   DEFAULT G_FOB_RECEIPT_ID
                       ,p_interorg_transfer_code         IN  NUMBER   DEFAULT G_INTERORG_NONE_ID
                       ,p_receipt_routing_id             IN  NUMBER   DEFAULT G_RECEIPT_ROUTING_DIRECT_ID
                       ,p_internal_order_required_flag   IN  NUMBER   DEFAULT G_INTERNAL_ORDER_REQUIRED_NO
                       ,p_intransit_inv_account          IN  NUMBER   DEFAULT NULL
                       ,p_interorg_transfer_cr_account   IN  NUMBER   DEFAULT NULL
                       ,p_interorg_receivables_account   IN  NUMBER   DEFAULT NULL
                       ,p_interorg_payables_account      IN  NUMBER   DEFAULT NULL
                       ,p_interorg_price_var_account     IN  NUMBER   DEFAULT NULL
                       ,p_elemental_visibility_enabled   IN  VARCHAR2 DEFAULT G_NO
                       ,p_manual_receipt_expense         IN  VARCHAR2 DEFAULT G_NO
                       ,x_status                         OUT VARCHAR2
                       ,x_error_code                     OUT NUMBER
                       ,x_error_message                  OUT VARCHAR2
                       )
IS
   ------------------
   -- Local constants
   ------------------
   lc_nm                           VARCHAR2(13) := 'DYNAMIC_BUILD';
   --------------------------
   -- User defined exceptions
   --------------------------
   EX_INVALID_RECEIPT_EXPENS_FLAG  EXCEPTION;
   EX_INVALID_VISIBILITY_FLAG      EXCEPTION;
   EX_INVALID_INTERORG_TRANS_CODE  EXCEPTION;
   EX_INVALID_RECEIPT_ROUTING      EXCEPTION;
   EX_FROM_TO_ARE_SAME             EXCEPTION;
   EX_INVALID_TRANSFER_TYPE        EXCEPTION;
   EX_INVALID_FOB_POINT            EXCEPTION;
   EX_INVALID_INTERNAL_ORDR_FLAG   EXCEPTION;
   -------------------------
   -- Local scalar variables
   -------------------------
   ---------------------------
   -- Shipnet flag information
   ---------------------------
   ln_internal_order_req_flag      PLS_INTEGER                                 := NULL;
   lc_elem_visibility_enabled      VARCHAR2(1)                                 := NULL;
   lc_manual_receipt_expense       VARCHAR2(1)                                 := NULL;
   -----------------------------------
   -- Shipnet relationship information
   -----------------------------------
   ln_transfer_type                mtl_interorg_parameters.intransit_type%TYPE := NULL;
   ln_fob_point                    PLS_INTEGER                                 := NULL;
   ln_interorg_transfer_code       PLS_INTEGER                                 := NULL;
   ln_receipt_routing_id           PLS_INTEGER                                 := NULL;
   ------------------------------------------------------------------
   -- To check if the shipnet already exists in the main PL/SQL table.
   ------------------------------------------------------------------
   lc_duplicate_shipnet             VARCHAR2(5)                                := NULL;
   --------------------------
   -- Used for error handling
   --------------------------
   -- Out/In Out parameters
   --------------------------
   lc_err_msg                       VARCHAR2(500)                              := NULL;
   lc_rowid                         VARCHAR2(100)                              := NULL;

   ---------------------------------------------------------
   -- Cursor to fetch the organizations passed as parameters
   ---------------------------------------------------------
   CURSOR lcu_inv_org_to_process(p_from_org_id IN PLS_INTEGER
                                ,p_to_org_id   IN PLS_INTEGER
                                )
   IS
   SELECT HAOU.name                   ebs_inv_org
         ,UPPER(HAOU.type)            ebs_inv_org_type
         ,HAOU.attribute1             rms_org
         ,HAOU.organization_id        ebs_org_id
         ,DECODE(HAOU.organization_id ,p_from_org_id,'FROM',p_to_org_id,'TO') from_or_to
         ,MP.organization_code        ebs_org_code
   FROM   hr_all_organization_units   HAOU
         ,mtl_parameters MP
   WHERE  HAOU.organization_id IN (p_from_org_id,p_to_org_id)
   AND    HAOU.organization_id = MP.organization_id
   ;

BEGIN
   ---------------------------------------------------
   -- Dynamic creation of shipping network starts here
   ---------------------------------------------------
   --------------------------------
   -- Initializing global variables
   --------------------------------
   gc_process_type               := G_PROCESS_TYPE_ONDEMAND;
   gn_param_from_id              := p_from_organization_id;
   gn_param_to_id                := p_to_organization_id;

   gn_main_indx                  := 0;

   gc_non_trade_nw_processing    := 'N';
   -------------------------------------------------------------------
   -- Initialize the shipnet information that are passed as parameters
   -------------------------------------------------------------------
   ----------------------
   -- Account information
   ----------------------
   gn_intransit_inv_account      := p_intransit_inv_account;
   gn_inter_transfer_cr_account  := p_interorg_transfer_cr_account;
   gn_src1_inter_receiv_account  := p_interorg_receivables_account;
   gn_trgt1_inter_pay_account    := p_interorg_payables_account;
   gn_interorg_price_var_account := p_interorg_price_var_account;
   --------------------------------------
   -- relationship information and others
   --------------------------------------
   lc_elem_visibility_enabled    := NVL(p_elemental_visibility_enabled,G_NO);
   lc_manual_receipt_expense     := NVL(p_manual_receipt_expense,G_NO);
   ln_transfer_type              := NVL(p_transfer_type,G_INTRANSIT_ID);
   ln_fob_point                  := NVL(p_fob_point,G_FOB_RECEIPT_ID);
   ln_interorg_transfer_code     := NVL(p_interorg_transfer_code,G_INTERORG_NONE_ID);
   ln_receipt_routing_id         := NVL(p_receipt_routing_id,G_RECEIPT_ROUTING_DIRECT_ID);
   ln_internal_order_req_flag    := NVL(p_internal_order_required_flag,G_INTERNAL_ORDER_REQUIRED_NO);
   gc_invalid_creation_rule_flag := 'N';
   -----------------------
   --Other initializations
   -----------------------
   gc_message_data := NULL;

   ------------------------------
   -- Initializing OUT parameters
   ------------------------------
   x_status := 'S';
   -----------------------------------------
   -- Get accounting flex field structure id
   --  which will be used in deriving
   --  delimiter, ccid.
   -----------------------------------------
   GET_ACCNT_FLEX_STRUCTURE_ID;

   IF gc_message_data IS NOT NULL THEN

      RAISE EX_ERR_ACNT_FLEX_STRUCT_ID;

   END IF;

   ---------------------------
   -- Transfer type validation
   ---------------------------
   IF p_from_organization_id = p_to_organization_id THEN

      RAISE EX_FROM_TO_ARE_SAME;

   END IF;

   IF ln_transfer_type IN (G_INTRANSIT_ID,G_DIRECT_ID) THEN

      IF ln_transfer_type = G_INTRANSIT_ID THEN
         -----------------------
         -- FOB Point validation
         -----------------------
         IF ln_fob_point NOT IN (G_FOB_RECEIPT_ID,G_FOB_SHIP_ID) THEN

            RAISE EX_INVALID_FOB_POINT;
         END IF;

         -----------------------------
         -- Receipt Routing validation
         -----------------------------
         IF ln_receipt_routing_id NOT IN (G_RECEIPT_ROUTING_DIRECT_ID,G_RECEIPT_ROUTING_STND_ID,G_RECEIPT_ROUTING_INSPEC_ID)  THEN

            RAISE EX_INVALID_RECEIPT_ROUTING;

         END IF;

      ELSE
         ln_fob_point          := NULL;
         ln_receipt_routing_id := NULL;
      END IF;

   ELSE
      RAISE EX_INVALID_TRANSFER_TYPE;
   END IF;
   -------------------------------------
   -- Inter-org transfer code validation
   -------------------------------------
   IF ln_interorg_transfer_code NOT IN (G_INTERORG_NONE_ID,G_INTERORG_REQ_VALUE_ID,G_INTERORG_REQ_PERCENTAGE_ID,G_INTERORG_PRE_PERCENTAGE_ID) THEN

      RAISE EX_INVALID_INTERORG_TRANS_CODE;

   END IF;
   -------------------------------------
   -- Element visibility flag validation
   -------------------------------------
   IF lc_elem_visibility_enabled NOT IN (G_YES,G_NO) THEN

      RAISE EX_INVALID_VISIBILITY_FLAG;

   END IF;
   -----------------------------------------
   -- Manual receipt expense flag validation
   -----------------------------------------
   IF lc_manual_receipt_expense NOT IN (G_YES,G_NO) THEN

      RAISE EX_INVALID_RECEIPT_EXPENS_FLAG;

   END IF;
   ------------------------------------------
   -- Internal order required flag validation
   ------------------------------------------
   IF ln_internal_order_req_flag NOT IN (G_INTERNAL_ORDER_REQUIRED_NO,G_INTERNAL_ORDER_REQUIRED_YES) THEN

      RAISE EX_INVALID_INTERNAL_ORDR_FLAG;

   END IF;

   gt_temp_shipnet_tbl.delete;

   FOR lcu_inv_org IN lcu_inv_org_to_process(p_from_org_id    => p_from_organization_id   --IN PLS_INTEGER
                                            ,p_to_org_id      => p_to_organization_id     --IN PLS_INTEGER
                                            )
   LOOP

      -------------------------------------
      -- Initializing the temp PL/SQL table
      -------------------------------------
      gn_temp_indx := 0;
      ------------------------------------------------------------------------------------------
      -- Initialize the source org information and target org info in the temporary PL/SQL table
      ------------------------------------------------------------------------------------------
      IF lcu_inv_org.from_or_to = 'FROM' THEN

         gc_source_org_type                                             := lcu_inv_org.ebs_inv_org_type;

         IF gc_source_org_type IS NULL THEN

            RAISE EX_SOURCE_ORG_NULL;

         END IF;

         gc_source_org_num                                              := lcu_inv_org.rms_org;
         gc_source_org_code                                             := lcu_inv_org.ebs_org_code;
         gt_temp_shipnet_tbl(gn_temp_indx).source_org_number            := gc_source_org_num;
         gt_temp_shipnet_tbl(gn_temp_indx).source_org_type              := gc_source_org_type;
         gt_temp_shipnet_tbl(gn_temp_indx).source_inv_org               := lcu_inv_org.ebs_inv_org;
         gt_temp_shipnet_tbl(gn_temp_indx).source_org_id                := lcu_inv_org.ebs_org_id;
         gt_temp_shipnet_tbl(gn_temp_indx).source_org_code              := gc_source_org_code;
         gt_temp_shipnet_tbl(gn_temp_indx).intransit_type               := ln_transfer_type;
         gt_temp_shipnet_tbl(gn_temp_indx).fob_point                    := ln_fob_point;
         gt_temp_shipnet_tbl(gn_temp_indx).interorg_transfer_code       := ln_interorg_transfer_code;
         gt_temp_shipnet_tbl(gn_temp_indx).receipt_routing_id           := ln_receipt_routing_id;
         gt_temp_shipnet_tbl(gn_temp_indx).internal_order_required_flag := ln_internal_order_req_flag;
         gt_temp_shipnet_tbl(gn_temp_indx).elemental_visibility_enabled := lc_elem_visibility_enabled;
         gt_temp_shipnet_tbl(gn_temp_indx).manual_receipt_expense       := lc_manual_receipt_expense;

         OPEN gcu_default_csc_xdoc(gc_source_org_num);
         FETCH gcu_default_csc_xdoc INTO gt_temp_shipnet_tbl(gn_temp_indx).source_default_xdoc
                                        ,gt_temp_shipnet_tbl(gn_temp_indx).source_default_csc
                                        ,gc_source_sub_type;
         CLOSE gcu_default_csc_xdoc;

         gt_temp_shipnet_tbl(gn_temp_indx).source_sub_type              := gc_source_sub_type;

      ELSIF lcu_inv_org.from_or_to = 'TO' THEN
         gc_target_org_type                                  := lcu_inv_org.ebs_inv_org_type;
         gc_target_org_num                                   := lcu_inv_org.rms_org;
         gc_target_org_code                                  := lcu_inv_org.ebs_org_code;
         gt_temp_shipnet_tbl(gn_temp_indx).target_org_type   := gc_target_org_type;
         gt_temp_shipnet_tbl(gn_temp_indx).target_inv_org    := lcu_inv_org.ebs_inv_org;
         gt_temp_shipnet_tbl(gn_temp_indx).target_org_id     := lcu_inv_org.ebs_org_id;
         gt_temp_shipnet_tbl(gn_temp_indx).target_org_number := gc_target_org_num;
         gt_temp_shipnet_tbl(gn_temp_indx).target_org_code   := gc_target_org_code;

         OPEN gcu_default_csc_xdoc(gc_target_org_num);
         FETCH gcu_default_csc_xdoc INTO gt_temp_shipnet_tbl(gn_temp_indx).target_default_xdoc
                                        ,gt_temp_shipnet_tbl(gn_temp_indx).target_default_csc
                                        ,gc_target_sub_type;
         CLOSE gcu_default_csc_xdoc;

         gt_temp_shipnet_tbl(gn_temp_indx).target_sub_type   := gc_target_sub_type;

      END IF;

   END LOOP;

   IF gt_temp_shipnet_tbl.COUNT > 0 AND gt_temp_shipnet_tbl(gn_temp_indx).source_org_id IS NOT NULL
      AND gt_temp_shipnet_tbl(gn_temp_indx).target_org_id IS NOT NULL
   THEN
      ------------------------------------
      -- Call creation rule validation API
      ------------------------------------
      CREATION_RULE_VALIDATION;
      ---------------------------------------
      -- Call restriction rule validation API
      ---------------------------------------
      RESTRICTION_RULE_VALIDATION;

      FROM_TEMP_TO_MAIN_TABLE;

      IF gt_main_shipnet_tbl.COUNT > 0 THEN
         FOR main_indx IN gt_main_shipnet_tbl.FIRST..gt_main_shipnet_tbl.LAST
         LOOP
            --------------------------------------------------------------------------------------
            -- Call custom table handler if the shipnet_create flag is Y for the given combination
            --------------------------------------------------------------------------------------
            IF gt_main_shipnet_tbl(main_indx).shipnet_create = G_YES THEN
               lc_err_msg := NULL;
               lc_rowid   := NULL;

               XX_MTL_INTERORG_PARAMETERS_PKG.INSERT_ROW(
                                                         X_Rowid                         => lc_rowid                                                     --  IN OUT NOCOPY VARCHAR2
                                                        ,X_Err_msg                       => lc_err_msg                                                   --  OUT VARCHAR2
                                                        ,X_From_organization_id          => gt_main_shipnet_tbl(main_indx).source_org_id                 --  NUMBER
                                                        ,X_To_organization_id            => gt_main_shipnet_tbl(main_indx).target_org_id                 --  NUMBER
                                                        ,X_Last_update_date              => SYSDATE                                                      --  DATE
                                                        ,X_Last_updated_by               => FND_GLOBAL.user_id                                           --  NUMBER
                                                        ,X_Creation_date                 => SYSDATE                                                      --  DATE
                                                        ,X_Created_by                    => FND_GLOBAL.user_id                                           --  NUMBER
                                                        ,X_Last_update_login             => FND_GLOBAL.login_id                                          --  NUMBER
                                                        ,X_Intransit_type                => gt_main_shipnet_tbl(main_indx).intransit_type                --  NUMBER
                                                        ,X_Distance_uom_code             => NULL                                                         --  VARCHAR
                                                        ,X_To_organization_distance      => NULL                                                         --  NUMBER
                                                        ,X_Fob_point                     => gt_main_shipnet_tbl(main_indx).fob_point                     --  NUMBER
                                                        ,X_Matl_interorg_transfer_code   => gt_main_shipnet_tbl(main_indx).interorg_transfer_code        --  NUMBER
                                                        ,X_Routing_header_id             => gt_main_shipnet_tbl(main_indx).receipt_routing_id            --  NUMBER
                                                        ,X_Internal_order_required_flag  => gt_main_shipnet_tbl(main_indx).internal_order_required_flag  --  NUMBER
                                                        ,X_Intransit_inv_account         => gt_main_shipnet_tbl(main_indx).intransit_inv_account_id      --  NUMBER
                                                        ,X_Interorg_trnsfr_chrge_percnt  => NULL                                                         --  NUMBER
                                                        ,X_Interorg_transfer_cr_account  => gt_main_shipnet_tbl(main_indx).interorg_transfer_cr_accnt_id --   NUMBER
                                                        ,X_Interorg_receivables_account  => gt_main_shipnet_tbl(main_indx).interorg_receivables_accnt_id --   NUMBER
                                                        ,X_Interorg_payables_account     => gt_main_shipnet_tbl(main_indx).interorg_payables_account_id  --   NUMBER
                                                        ,X_Interorg_price_var_account    => gt_main_shipnet_tbl(main_indx).interorg_price_var_account_id --   NUMBER
                                                        ,X_Attribute_category            => NULL                                                         --   VARCHAR
                                                        ,X_Attribute1                    => NULL                                                         --   VARCHAR
                                                        ,X_Attribute2                    => NULL                                                         --   VARCHAR
                                                        ,X_Attribute3                    => NULL                                                         --   VARCHAR
                                                        ,X_Attribute4                    => NULL                                                         --   VARCHAR
                                                        ,X_Attribute5                    => NULL                                                         --   VARCHAR
                                                        ,X_Attribute6                    => NULL                                                         --   VARCHAR
                                                        ,X_Attribute7                    => NULL                                                         --   VARCHAR
                                                        ,X_Attribute8                    => NULL                                                         --   VARCHAR
                                                        ,X_Attribute9                    => NULL                                                         --   VARCHAR
                                                        ,X_Attribute10                   => NULL                                                         --   VARCHAR
                                                        ,X_Attribute11                   => NULL                                                         --   VARCHAR
                                                        ,X_Attribute12                   => NULL                                                         --   VARCHAR
                                                        ,X_Attribute13                   => NULL                                                         --   VARCHAR
                                                        ,X_Attribute14                   => NULL                                                         --   VARCHAR
                                                        ,X_Attribute15                   => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute_category     => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute1             => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute2             => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute3             => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute4             => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute5             => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute6             => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute7             => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute8             => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute9             => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute10            => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute11            => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute12            => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute13            => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute14            => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute15            => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute16            => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute17            => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute18            => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute19            => NULL                                                         --   VARCHAR
                                                        ,X_Global_attribute20            => NULL                                                         --  VARCHAR
                                                        ,X_Elemental_visibility_enabled  => gt_main_shipnet_tbl(main_indx).elemental_visibility_enabled  --  VARCHAR
                                                        ,X_Manual_receipt_expense        => gt_main_shipnet_tbl(main_indx).manual_receipt_expense        --  VARCHAR
                                                        ,X_Profit_in_inv_account         => NULL                                                         -- NUMBER
                                                        );
               IF lc_err_msg IS NOT NULL THEN

                  IF gt_main_shipnet_tbl(main_indx).source_org_id = p_from_organization_id AND gt_main_shipnet_tbl(main_indx).target_org_id = p_to_organization_id THEN
                     x_error_message := get_fnd_message
                                        (p_name => G_62518,p_1 => G_T3,p_v1 => gt_main_shipnet_tbl(main_indx).source_inv_org
                                                          ,p_2 => G_T4,p_v2 => gt_main_shipnet_tbl(main_indx).target_inv_org
                                                          ,p_3 => G_T2,p_v3 => lc_err_msg
                                        );
                     x_status        := 'E';
                     x_error_code := -1;

                  END IF;
               END IF;
            ELSIF gt_main_shipnet_tbl(main_indx).shipnet_create = G_NO THEN

               IF gt_main_shipnet_tbl(main_indx).source_org_id = p_from_organization_id AND gt_main_shipnet_tbl(main_indx).target_org_id = p_to_organization_id THEN

                  x_error_message := get_fnd_message
                                     (p_name => G_62518,p_1 => G_T3,p_v1 => gt_main_shipnet_tbl(main_indx).source_inv_org
                                                       ,p_2 => G_T4,p_v2 => gt_main_shipnet_tbl(main_indx).target_inv_org
                                                       ,p_3 => G_T2,p_v3 => gt_main_shipnet_tbl(main_indx).message
                                     );
                  x_status        := 'E';
                  x_error_code := -1;
                  -- Log the validation error
                  LOG_ERROR(p_exception => 'VALIDATION_ERROR'                     --IN VARCHAR2
                           ,p_message   => gt_main_shipnet_tbl(main_indx).message --IN VARCHAR2
                           ,p_code      => x_error_code                           --IN PLS_INTEGER
                           );
               ELSE
                  -- Log the validation error
                  LOG_ERROR(p_exception => 'VALIDATION_ERROR'                     --IN VARCHAR2
                           ,p_message   => gt_main_shipnet_tbl(main_indx).message --IN VARCHAR2
                           ,p_code      => 1                                      --IN PLS_INTEGER
                           );
               END IF;

            END IF;
         END LOOP;
      END IF;
   ELSE
      x_error_message := get_fnd_message(p_name => G_62516);
      x_error_code    := -1;
      x_status := 'E';
   END IF;

   --------------------------------------------------------------------
   -- If creation rule is invalid for source org types except drop ship
   --  then give a warning code to the java concurrent program
   --------------------------------------------------------------------
   IF gc_invalid_creation_rule_flag = 'Y' AND x_status = 'S' THEN
      x_error_code := -1;
      x_status := 'E';
   END IF;

   COMMIT;
EXCEPTION
   WHEN EX_SOURCE_ORG_NULL THEN
      x_error_code := -1;
      x_error_message := get_fnd_message(p_name => G_62521);
      x_status := 'E';
   WHEN EX_ERR_ACNT_FLEX_STRUCT_ID THEN
      x_error_code := -1;
      x_error_message := gc_message_data;
      x_status := 'E';
   WHEN EX_INVALID_INTERNAL_ORDR_FLAG THEN
      x_error_code := -1;
      x_error_message := get_fnd_message(p_name => G_62519,p_1 => G_T5,p_v1 => G_INTERNAL_FLAG);
      x_status := 'E';
   WHEN EX_INVALID_RECEIPT_EXPENS_FLAG THEN
      x_error_code := -1;
      x_error_message := get_fnd_message(p_name => G_62519,p_1 => G_T5,p_v1 => G_MANUAL_FLAG);
      x_status := 'E';
   WHEN EX_INVALID_VISIBILITY_FLAG THEN
      x_error_code := -1;
      x_error_message := get_fnd_message(p_name => G_62519,p_1 => G_T5,p_v1 => G_ELEMENT_FLAG);
      x_status := 'E';
   WHEN EX_INVALID_INTERORG_TRANS_CODE THEN
      x_error_code := -1;
      x_error_message := get_fnd_message(p_name => G_62519,p_1 => G_T5,p_v1 => G_TRANS_FLAG);
      x_status := 'E';
   WHEN EX_INVALID_RECEIPT_ROUTING THEN
      x_error_code := -1;
      x_error_message := get_fnd_message(p_name => G_62519,p_1 => G_T5,p_v1 => G_ROUTING_FLAG);
      x_status := 'E';
   WHEN EX_FROM_TO_ARE_SAME THEN
      x_error_code := -1;
      x_error_message := get_fnd_message(p_name => G_62520);
      x_status := 'E';
   WHEN EX_INVALID_TRANSFER_TYPE THEN
      x_error_code := -1;
      x_error_message := get_fnd_message(p_name => G_62519,p_1 => G_T5,p_v1 => G_TRANS_TYPE);
      x_status := 'E';
   WHEN OTHERS THEN
      IF gcu_default_csc_xdoc%ISOPEN THEN
         CLOSE gcu_default_csc_xdoc;
      END IF;
      x_error_code    := -1;
      x_error_message := get_fnd_message
                          (p_name => G_62502,p_1 => G_T1,p_v1 => lc_nm,p_2 => G_T2,p_v2 => SQLERRM);

      x_status := 'E';
      ROLLBACK;

      LOG_ERROR(p_exception => 'OTHERS'        --IN VARCHAR2
               ,p_message   => x_error_message --IN VARCHAR2
               ,p_code      => x_error_code    --IN PLS_INTEGER
               );
END DYNAMIC_BUILD;

END XX_GI_SHIPNET_CREATION_PKG;
/
SHOW ERRORS;
EXIT;