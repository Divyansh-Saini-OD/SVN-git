SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification XX_AP_CC_1099_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_AP_CC_1099_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name :      1099 From CreditCard                                    |
-- | Description : To create one invoice and one credit memo for each    |
-- |              of the vendors that Office Depot pays through 3rd party|
-- |              credit card companies,inorder to report 1099 activity  |
-- |              on such vendors.                                       |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       27-MAR-2007  Anusha Ramanujam,     Initial version         |
-- |                       Wipro Technologies                            |
-- +=====================================================================+


    gn_request3_id               NUMBER;
    gn_request4_id               NUMBER;
    gc_concurrent_program_name   fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
    gc_inv_account               ap_lookup_codes.displayed_field%TYPE;


-- +==========================================================================+
-- | Name : PROCESS                                                           |
-- | Description : To validate the data in the staging table                  |
-- |            xx_ap_creditcard_1099_stg and then load them into the base    |
-- |            tables through the standard interface tables. It calls the    |
-- |            custom insert procedures to insert into the interface tables  |
-- |            and then submits the "Supplier Open Interface Import", the    |
-- |            "Supplier Sites Open Interface Import" and the "Payables Open |
-- |            Interface Import" programs to import the data into the        |
-- |            corresponding base tables.                                    |
-- |                                                                          |
-- | Parameters : x_error_buff, x_ret_code, p_file_name, p_batch_size,        |
-- |            p_user_id, p_login_id, p_reprocess_flag, p_vendor_site        |
-- |            p_description, p_lkp_code_sup_pay, p_type_1099,               |
-- |            p_lkp_type_ven, p_lkp_code_ven, p_lkp_type_pay,               |
-- |            p_lkp_code_site_pay, p_lkp_type_sou, p_lkp_code_sou           |
-- |                                                                          |
-- | Returns :    x_error_buff, x_ret_code                                    |
-- +==========================================================================+
    PROCEDURE PROCESS(
                     x_error_buff        OUT VARCHAR2
                    ,x_ret_code          OUT NUMBER
                    ,p_file_name         IN  VARCHAR2
                    ,p_batch_size        IN  NUMBER
                    ,p_user_id           IN  NUMBER
                    ,p_login_id          IN  NUMBER
                    ,p_reprocess_flag    IN  VARCHAR2
                    ,p_vendor_site       IN  VARCHAR2
                    ,p_description       IN  VARCHAR2
                    ,p_lkp_code_sup_pay  IN  VARCHAR2
                    ,p_type_1099         IN  VARCHAR2
                    ,p_lkp_type_ven      IN  VARCHAR2
                    ,p_lkp_code_ven      IN  VARCHAR2
                    ,p_lkp_type_pay      IN  VARCHAR2
                    ,p_lkp_code_site_pay IN  VARCHAR2
                    ,p_lkp_type_sou      IN  VARCHAR2
                    ,p_lkp_code_sou      IN  VARCHAR2
                    ,p_lkp_type_acc      IN  VARCHAR2
                    ,p_lkp_code_acc      IN  VARCHAR2
                    ,p_lkp_code_org      IN  VARCHAR2
                    );


-- +=======================================================================+
-- | Name : GET_REQUEST_ID                                                 |
-- | Description : To populate the request_id of the SQL Loader concurrent |
-- |               Program, 'OD: AP CC1099 Import Program' in the Staging  |
-- |               table                                                   |
-- |                                                                       |
-- | Returns : ln_req_id (request id of the loader program)                |
-- +=======================================================================+
    FUNCTION GET_REQUEST_ID RETURN NUMBER;

END XX_AP_CC_1099_PKG;
/
SHOW ERROR