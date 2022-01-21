CREATE OR REPLACE
PACKAGE xx_gi_comn_utils_pkg
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  xx_gi_comn_utils_pkg                                     |
-- | Description      : This package contains library of common        |
-- |                    procedures and functions used                  |
-- |                    Various Custom Office Depot Procedures         |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- +===================================================================+
  -- Global variables
  pvg_exception_handled    VARCHAR2(1)   := 'N';
  pvg_sql_point            NUMBER;
  pvg_debug_option         CHAR (1);
  pvg_run_date             DATE   := SYSDATE;
  pvg_request_id           NUMBER := Fnd_Global.conc_request_id ;
  pvg_resp_id              NUMBER := Fnd_Global.resp_id ;
  pvg_user_id              NUMBER := Fnd_Global.user_id;
  pvg_login_id             NUMBER := Fnd_Global.login_id;
  pvg_org_id               NUMBER := Fnd_Profile.value('ORG_ID');
  pvg_sob_id               NUMBER := Fnd_Profile.value('GL_SET_OF_BKS_ID');
  pvg_application_id       NUMBER;
  --
  -- Records and Table used by function wrap text to store wrapped lines
  TYPE r_lines IS RECORD (
    text  VARCHAR2 (200)
  );
  --
  TYPE t_type_wrapped_lines IS TABLE OF r_lines
    INDEX BY BINARY_INTEGER;
  --
  --  Writes program log to request log
  PROCEDURE write_log (p_text_in IN VARCHAR2);
 --
  -- Writes program output to request out
  PROCEDURE write_out (p_text_in IN VARCHAR2);
  --
  -- Writes additional program output to request log
  PROCEDURE write_debug (p_msg_in IN VARCHAR2);
  -- This Function is used for Debugging and Logging
  PROCEDURE write_line (p_char_in VARCHAR2, p_len_in NUMBER) ;

  FUNCTION sqlpoint RETURN VARCHAR2;
  --  This procedure is used for logging Error raised by When Others
  --  Exception of calling object
  PROCEDURE log_exception (p_object_name_in IN VARCHAR2);
  --
 -- To get oracle EBS Inventory Transaction Type ID
  PROCEDURE get_gi_trx_type_id (p_legacy_trx  IN VARCHAR2
                               ,p_legacy_trx_type IN VARCHAR2
                               ,p_trx_action  IN VARCHAR2
                               ,x_trx_type_id OUT NUMBER
                               ,x_return_status OUT NOCOPY VARCHAR2
                               ,x_error_message OUT NOCOPY VARCHAR2
                         );
  --
 -- To get oracle EBS Inventory Reason ID
  PROCEDURE get_gi_reason_id (p_legacy_trx_type  IN VARCHAR2
                             ,x_reason_id OUT NUMBER
                             ,x_return_status OUT NOCOPY VARCHAR2
                             ,x_error_message OUT NOCOPY VARCHAR2
                          );
  --
  -- To get oracle EBS Inventory Code Combination ID for Miscellaneous Transactions
  PROCEDURE get_gi_adj_ccid (p_legacy_trx_type  IN VARCHAR2
                            ,p_org_id  IN NUMBER
                            ,x_adj_ccid OUT NUMBER
                            ,x_return_status OUT NOCOPY VARCHAR2
                            ,x_error_message OUT NOCOPY VARCHAR2
                          );
--
  FUNCTION get_ebs_organization_id (p_legacy_loc_id  IN NUMBER
                                 )
  RETURN NUMBER;
--
  FUNCTION get_legacy_loc_id (p_ebs_org_id  IN NUMBER
                                    )
  RETURN NUMBER;
--
  FUNCTION get_inventory_item_id (p_sku  IN VARCHAR2,
                                  p_org_id IN NUMBER
                                    )
  RETURN NUMBER;
--
END xx_gi_comn_utils_pkg;
