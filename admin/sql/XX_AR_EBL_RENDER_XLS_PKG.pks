create or replace PACKAGE XX_AR_EBL_RENDER_XLS_PKG AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_AR_EBL_RENDER_XLS_PKG                                                             |
-- | Description : Package body for eBilling eXLS bill generation                                       |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       30-Apr-2010 Bushrod Thomas     Initial draft version.                                     |
-- |                                                                                                    |
-- |1.1       22-Jun-2015 Suresh Naragam     Done Changes to get the additional                         |
-- |                                         Columns data (Module 4B Relase 1) (Proc : XLS_FILE_HEADER) |
-- |1.2       20-Aug-2015 Suresh Naragam     Module 4B Release 2 Changes                                |
-- |                                         (Proc : GET_XL_TABS_INFO)                                  |
-- |1.3       27-MAY-2020 Divyansh           Added logic for JIRA NAIT-129167                           |
-- +====================================================================================================+
*/

g_fee_option VARCHAR2(20);--Added for 1.3
  -- Parent concurrent program; starts Java child threads
  PROCEDURE RENDER_XLS_P (
    Errbuf                  OUT NOCOPY VARCHAR2
   ,Retcode                 OUT NOCOPY VARCHAR2
   ,p_billing_dt            IN VARCHAR2
  );

  PROCEDURE XLS_FILES_TO_RENDER (
    p_thread_id             IN NUMBER
   ,p_thread_count          IN NUMBER
   ,x_cursor                OUT SYS_REFCURSOR
  );

  PROCEDURE SHOW_XLS_FILES_TO_RENDER (
    p_thread_id             IN NUMBER
   ,p_thread_count          IN NUMBER
  );

  PROCEDURE XLS_FILE_HEADER (
    p_file_id               IN NUMBER
   ,x_cell_total_due        OUT VARCHAR2
   ,x_description           OUT VARCHAR2
   ,x_cell_cons_bill_number OUT VARCHAR2
   ,x_cell_billing_period   OUT VARCHAR2
   ,x_cell_pay_terms        OUT VARCHAR2
   ,x_cell_due_date         OUT VARCHAR2
   ,x_billing_for           OUT VARCHAR2
   ,x_billing_id            OUT VARCHAR2
   ,x_aops_id               OUT VARCHAR2
   ,x_include_header        OUT VARCHAR2
   ,x_logo_hyperlink_url    OUT VARCHAR2
   ,x_logo_alt_text         OUT VARCHAR2
   ,x_logo_path             OUT VARCHAR2
   ,x_total_merchandise_label   OUT VARCHAR2
   ,x_total_merchandise_amt OUT VARCHAR2
   ,x_total_salestax_label  OUT VARCHAR2
   ,x_total_salestax_amt    OUT VARCHAR2
   ,x_total_misc_label      OUT VARCHAR2
   ,x_total_misc_amt        OUT VARCHAR2
   ,x_total_gift_card_label OUT VARCHAR2
   ,x_total_gift_card_amt   OUT VARCHAR2
   ,x_split_tabs_by         OUT VARCHAR2
   ,x_enable_xl_subtotal    OUT VARCHAR2
   ,x_fee_label             OUT VARCHAR2-- Added for 1.3
   ,x_fee_amount            OUT VARCHAR2-- Added for 1.3
  );


  PROCEDURE XLS_FILE_COLS (
    p_file_id               IN NUMBER
   ,x_cursor                OUT SYS_REFCURSOR
  );
  PROCEDURE SHOW_XLS_FILE_COLS (
    p_file_id               IN NUMBER
  );


  PROCEDURE XLS_FILE_SORT_COLS (
    p_file_id               IN NUMBER
   ,x_cursor                OUT SYS_REFCURSOR
  );
  PROCEDURE SHOW_XLS_FILE_SORT_COLS (
    p_file_id               IN NUMBER
  );


  PROCEDURE XLS_FILE_AGGS (
    p_file_id               IN NUMBER
   ,x_cursor                OUT SYS_REFCURSOR
  );

  PROCEDURE SHOW_XLS_FILE_AGGS (
    p_file_id               IN NUMBER
  );

  PROCEDURE GET_XL_TABS_INFO (
    p_file_id               IN NUMBER
   ,p_cust_doc_id           IN NUMBER
   ,x_cursor                OUT SYS_REFCURSOR
   ,x_maxtabs               OUT NUMBER
  );

END XX_AR_EBL_RENDER_XLS_PKG;
