SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_gi_new_store_auto_pkg AUTHID CURRENT_USER
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_GI_NEW_STORE_AUTO_PKG                                         |
-- |                                                                                |
-- | Description:                                                                   |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 18-JUL-2007 Sarah Maria Justina     Initial draft version              |
-- |1.1      29-OCT-2007 Archibald Antony P      Change as per CR                   |
-- |1.2      31-MAR-2007 Ganesh B Nadakudhiti   Changed generate org code function  |
-- |								to generate org codes from custom   |
-- |								table.					|
-- +================================================================================+
--**************************
--Declaring Global variables
--**************************
   TYPE xx_inv_accounts_rec_type IS RECORD (
      material_account               NUMBER,
      material_overhead_account      NUMBER,
      matl_ovhd_absorption_acct      NUMBER,
      resource_account               NUMBER,
      purchase_price_var_account     NUMBER,
      ap_accrual_account             NUMBER,
      overhead_account               NUMBER,
      outside_processing_account     NUMBER,
      intransit_inv_account          NUMBER,
      interorg_receivables_account   NUMBER,
      interorg_price_var_account     NUMBER,
      interorg_payables_account      NUMBER,
      cost_of_sales_account          NUMBER,
      encumbrance_account            NUMBER,
      project_cost_account           NUMBER,
      interorg_transfer_cr_account   NUMBER,
      receiving_account_id           NUMBER,
      clearing_account_id            NUMBER,
      retroprice_adj_account_id      NUMBER,
      sales_account                  NUMBER,
      expense_account                NUMBER,
      avg_cost_var_account           NUMBER,
      invoice_price_var_account      NUMBER,
      material_acc_cd                VARCHAR2 (2000),
      material_overhead_ac_cd        VARCHAR2 (2000),
      matl_ovhd_abs_acc_cd           VARCHAR2 (2000),
      resource_acc_cd                VARCHAR2 (2000),
      pur_price_var_acc_cd           VARCHAR2 (2000),
      ap_accrual_acc_cd              VARCHAR2 (2000),
      overhead_acc_cd                VARCHAR2 (2000),
      outside_processing_acc_cd      VARCHAR2 (2000),
      intransit_inv_acc_cd           VARCHAR2 (2000),
      interorg_rec_acc_cd            VARCHAR2 (2000),
      interorg_price_var_acc_cd      VARCHAR2 (2000),
      interorg_payables_acc_cd       VARCHAR2 (2000),
      cost_of_sales_acc_cd           VARCHAR2 (2000),
      encumbrance_acc_cd             VARCHAR2 (2000),
      project_cost_acc_cd            VARCHAR2 (2000),
      interorg_trnfr_cr_acc_cd       VARCHAR2 (2000),
      receiving_acc_cd               VARCHAR2 (2000),
      clearing_acc_cd                VARCHAR2 (2000),
      retropr_adj_acc_cd             VARCHAR2 (2000),
      sales_acc_cd                   VARCHAR2 (2000),
      expense_acc_cd                 VARCHAR2 (2000),
      avg_cost_var_acc_cd            VARCHAR2 (2000),
      invoice_price_var_acc_cd       VARCHAR2 (2000)
   );

   TYPE xx_inv_sixaccts_rec_type IS RECORD (
      material_account                VARCHAR2 (2000),
      material_overhead_account        VARCHAR2 (2000),
      resource_account                VARCHAR2 (2000),
      overhead_account                VARCHAR2 (2000),
      outside_processing_account      VARCHAR2 (2000),
      expense_account                 VARCHAR2 (2000)
   );

   TYPE xx_conc_requests_rec_type IS RECORD (
      conc_request_id   NUMBER,
      group_code        VARCHAR2 (10)
   );

   TYPE xx_control_rec_type IS RECORD (
      control_id           NUMBER,
      location_number_sw   NUMBER,
      org_name             VARCHAR2 (300),
      error_message        VARCHAR2 (300)
   );

   TYPE xx_conc_requests_tbl_type IS TABLE OF xx_conc_requests_rec_type
      INDEX BY BINARY_INTEGER;

   TYPE xx_inv_accounts_tbl_type IS TABLE OF xx_inv_accounts_rec_type
      INDEX BY BINARY_INTEGER;

   TYPE xx_inv_sixaccts_tbl_type IS TABLE OF xx_inv_sixaccts_rec_type
      INDEX BY BINARY_INTEGER;

   TYPE xx_control_tbl_type IS TABLE OF xx_control_rec_type
      INDEX BY BINARY_INTEGER;

---------------------------------------------------------------------------------------------------------
--Declaring procedure which gets called from Conc Program: OD: GI Populate Copy Org Staging table Program
---------------------------------------------------------------------------------------------------------
   PROCEDURE update_stg_org_data (
      x_errbuf               OUT      VARCHAR2,
      x_retcode              OUT      VARCHAR2,
      p_debug_flag           IN       VARCHAR2,
      p_records_to_process   IN       VARCHAR2
   );

   PROCEDURE get_accounts (
      p_model_org_id        IN              NUMBER,
      p_location_number     IN              NUMBER,
      p_does_rcv_exist      IN              NUMBER,
      x_accounts_tbl_type   OUT NOCOPY      xx_inv_accounts_tbl_type,
      x_errbuf              OUT             VARCHAR2,
      x_retcode             OUT             VARCHAR2
   );

---------------------------------------------------------------------------------------------------
--Declaring procedure which gets called from Conc Program: OD: GI Copy Inventory Org Master Program
---------------------------------------------------------------------------------------------------
   PROCEDURE copy_stg_org_data (
      x_errbuf               OUT      VARCHAR2,
      x_retcode              OUT      VARCHAR2,
      p_debug_flag           IN       VARCHAR2,
      p_records_to_process   IN       VARCHAR2
   );

--------------------------------------------------------------------------------------------
--Declaring procedure which gets called from Workflow XXGISTORE
--------------------------------------------------------------------------------------------
   PROCEDURE get_location_details (
      p_incoming_doc   IN       VARCHAR2,
      display_type     IN       VARCHAR2,
      document         IN OUT   CLOB,
      document_type    IN OUT   VARCHAR2
   );

   PROCEDURE get_ccid_wrapper (
      p_inv_sixaccts_tbl_type IN OUT xx_inv_sixaccts_tbl_type,
      p_location_number IN NUMBER
      );

--------------------------------------------------------------------------------------------
-- Function to generate org code
--------------------------------------------------------------------------------------------
FUNCTION generate_org_code
RETURN VARCHAR2;
--------------------------------------------------------------------------------------------
-- Function to check if org code is in use
--------------------------------------------------------------------------------------------
FUNCTION check_org_code(p_org_code IN VARCHAR2)
RETURN NUMBER ;
--------------------------------------------------------------------------------------------
-- Procedure to update the org code as used in the org codes table
--------------------------------------------------------------------------------------------
PROCEDURE update_org_codes(p_org_code IN VARCHAR2);

END xx_gi_new_store_auto_pkg;
/

SHOW ERRORS
EXIT;
