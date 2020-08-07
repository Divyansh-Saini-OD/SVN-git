SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE XX_GI_SHIPNET_CREATION_PKG AUTHID CURRENT_USER
--Version 1.0
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_SHIPNET_CREATION_PKG                                   |
-- |Purpose      : This package contains procedures that pre-builds/dynamically  |
-- |                creates shipping networks between EBS organizations to       |
-- |                facilitate inventory transfer.                               |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- |                                                                             |
-- |MTL_PARAMETERS              : S                                              |
-- |HR_ORGAINZATION_UNTIS       : S                                              |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |Draft1A  13-Aug-2007   Arun Andavar     Initial version                      |
-- |1.0      18-Aug-2007   Vikas Raina      Reviewed and updated                 |
-- +=============================================================================+
IS
   -----------------
   -- Default values
   -----------------
   ---------------------
   -- FOB -- Starts here
   ---------------------
   G_FOB_RECEIPT_ID                CONSTANT NUMBER        := 2;
   G_FOB_SHIP_ID                   CONSTANT NUMBER        := 1;
   -------------------
   -- FOB -- Ends here
   -------------------
   ---------------------------------------------------
   -- Inter-org transfer charge percent -- Starts here
   ---------------------------------------------------
   G_INTERORG_NONE_ID              CONSTANT NUMBER        := 1;
   G_INTERORG_REQ_VALUE_ID         CONSTANT NUMBER        := 2;
   G_INTERORG_REQ_PERCENTAGE_ID    CONSTANT NUMBER        := 3;
   G_INTERORG_PRE_PERCENTAGE_ID    CONSTANT NUMBER        := 4;
   -------------------------------------------------
   -- Inter-org transfer charge percent -- Ends here
   -------------------------------------------------
   -------------------------------
   -- Transfer type -- Starts here
   -------------------------------
   G_INTRANSIT_ID                  CONSTANT NUMBER        := 2;
   G_DIRECT_ID                     CONSTANT NUMBER        := 1;
   -----------------------------
   -- Transfer type -- Ends here
   -----------------------------
   --------------------------------
   --Receipt routing -- Starts here
   --------------------------------
   G_RECEIPT_ROUTING_STND_ID       CONSTANT NUMBER        := 1;
   G_RECEIPT_ROUTING_INSPEC_ID     CONSTANT NUMBER        := 2;
   G_RECEIPT_ROUTING_DIRECT_ID     CONSTANT NUMBER        := 3;
   ------------------------------
   --Receipt routing -- Ends here
   ------------------------------
   --------------------------------------
   --Internal ordered flag -- Starts here
   --------------------------------------
   G_INTERNAL_ORDER_REQUIRED_YES   CONSTANT NUMBER        := 1;
   G_INTERNAL_ORDER_REQUIRED_NO    CONSTANT NUMBER        := 2;
   ------------------------------------
   --Internal ordered flag -- Ends here
   ------------------------------------
   ---------------------------------------
   --Element visibility flag - Starts here
   ---------------------------------------
   G_ELEMENT_VISIBIL_ENABLED_NO    CONSTANT VARCHAR2(1)   := 'N';
   G_ELEMENT_VISIBIL_ENABLED_YES   CONSTANT VARCHAR2(1)   := 'Y';
   --------------------------------------
   --Element visibility flag -- Ends here
   --------------------------------------
   ---------------------------------------
   --Manual Receipt Expense -- Starts here
   ---------------------------------------
   G_MANUAL_RECEIPT_EXPENSE_NO        CONSTANT VARCHAR2(1)   := 'N';
   G_MANUAL_RECEIPT_EXPENSE_YES       CONSTANT VARCHAR2(1)   := 'Y';
   -------------------------------------
   --Manual Receipt Expense -- Ends here
   -------------------------------------
   G_NO                            CONSTANT VARCHAR2(1)   := 'N';
   -- -------------------------
   -- Global PL/SQL record type
   -- -------------------------
   ----------------------------------------------------------
   -- Used to hold shipping network between two organizations
   ----------------------------------------------------------
   
   TYPE g_shipnet_rec_type IS RECORD
     (
      source_org_type                hr_all_organization_units.type%TYPE
     ,target_org_type                hr_all_organization_units.type%TYPE
     ,source_org_number              hr_all_organization_units.attribute1%TYPE
     ,target_org_number              hr_all_organization_units.attribute1%TYPE
     ,source_country                 hr_locations_all.country%TYPE
     ,target_country                 hr_locations_all.country%TYPE
     ,source_sub_type                xx_inv_org_loc_rms_attribute.od_sub_type_cd_sw%TYPE
     ,target_sub_type                xx_inv_org_loc_rms_attribute.od_sub_type_cd_sw%TYPE
     ,source_org_id                  hr_all_organization_units.organization_id%TYPE
     ,target_org_id                  hr_all_organization_units.organization_id%TYPE
     ,source_inv_org                 hr_all_organization_units.name%TYPE
     ,target_inv_org                 hr_all_organization_units.name%TYPE
     ,cr_rule_type                   fnd_flex_values.attribute7%TYPE
     ,cr_applicable_rule             fnd_flex_values_vl.description%TYPE
     ,rs_rule_type                   fnd_flex_values.attribute7%TYPE
     ,rs_applicable_rule             fnd_flex_values_vl.description%TYPE
     ,code_reference                 fnd_flex_values.attribute6%TYPE
     ,source_default_xdoc            xx_inv_org_loc_rms_attribute.default_wh_sw%TYPE
     ,source_default_csc             xx_inv_org_loc_rms_attribute.od_default_wh_csc_s%TYPE
     ,target_default_xdoc            xx_inv_org_loc_rms_attribute.default_wh_sw%TYPE
     ,target_default_csc             xx_inv_org_loc_rms_attribute.od_default_wh_csc_s%TYPE
     ,shipnet_create                 VARCHAR2(1)
     ,shipnet_exists                 VARCHAR2(1)
     ,message                        VARCHAR2(500)     
     -- For java API -Starts here
     ,error_code                     NUMBER(2)
     ,error_message                  VARCHAR2(500)
     ,source_org_code                mtl_parameters.organization_code%TYPE
     ,target_org_code                mtl_parameters.organization_code%TYPE
     ,intransit_type                 mtl_interorg_parameters.intransit_type%TYPE
     ,fob_point                      mtl_interorg_parameters.fob_point%TYPE
     ,interorg_transfer_code         mtl_interorg_parameters.matl_interorg_transfer_code%TYPE
     ,receipt_routing_id             mtl_interorg_parameters.routing_header_id%TYPE
     ,internal_order_required_flag   mtl_interorg_parameters.internal_order_required_flag%TYPE
     ,intransit_inv_account          VARCHAR2(500)
     ,intransit_inv_account_id       mtl_interorg_parameters.intransit_inv_account%TYPE
     ,interorg_transfer_cr_account   VARCHAR2(500)
     ,interorg_transfer_cr_accnt_id  mtl_interorg_parameters.interorg_transfer_cr_account%TYPE
     ,interorg_receivables_account   VARCHAR2(500)
     ,interorg_receivables_accnt_id  mtl_interorg_parameters.interorg_receivables_account%TYPE
     ,interorg_payables_account      VARCHAR2(500)
     ,interorg_payables_account_id  mtl_interorg_parameters.interorg_payables_account%TYPE
     ,interorg_price_var_account_id mtl_interorg_parameters.interorg_price_var_account%TYPE
     ,interorg_price_var_account    VARCHAR2(500)
     ,elemental_visibility_enabled   mtl_interorg_parameters.elemental_visibility_enabled%TYPE
     ,manual_receipt_expense         mtl_interorg_parameters.manual_receipt_expense%TYPE
     -- For java API -Ends here
      )
      ;

   TYPE shipnet_tbl_type IS TABLE OF g_shipnet_rec_type
   INDEX BY BINARY_INTEGER;

   PROCEDURE PRE_BUILD(p_report_only_mode     IN  VARCHAR2
                      ,p_source_org_type      IN  VARCHAR2
                      ,p_from_organization_id IN  NUMBER
                      ,p_shipnet_tbl          OUT shipnet_tbl_type
                      ,x_error_code           OUT NUMBER
                      ,x_error_message        OUT VARCHAR2
                      );

   PROCEDURE DYNAMIC_BUILD(p_from_organization_id         IN  NUMBER
                          ,p_to_organization_id           IN  NUMBER
                          ,p_transfer_type                IN  NUMBER   DEFAULT G_INTRANSIT_ID
                          ,p_fob_point                    IN  NUMBER   DEFAULT G_FOB_RECEIPT_ID
                          ,p_interorg_transfer_code       IN  NUMBER   DEFAULT G_INTERORG_NONE_ID
                          ,p_receipt_routing_id           IN  NUMBER   DEFAULT G_RECEIPT_ROUTING_DIRECT_ID
                          ,p_internal_order_required_flag IN  NUMBER   DEFAULT G_INTERNAL_ORDER_REQUIRED_NO
                          ,p_intransit_inv_account        IN  NUMBER   DEFAULT NULL
                          ,p_interorg_transfer_cr_account IN  NUMBER   DEFAULT NULL
                          ,p_interorg_receivables_account IN  NUMBER   DEFAULT NULL
                          ,p_interorg_payables_account    IN  NUMBER   DEFAULT NULL
                          ,p_interorg_price_var_account   IN  NUMBER   DEFAULT NULL
                          ,p_elemental_visibility_enabled IN  VARCHAR2 DEFAULT G_NO
                          ,p_manual_receipt_expense       IN  VARCHAR2 DEFAULT G_NO
                          ,x_status                       OUT VARCHAR2
                          ,x_error_code                   OUT NUMBER
                          ,x_error_message                OUT VARCHAR2
                          );


END XX_GI_SHIPNET_CREATION_PKG;
/
EXIT