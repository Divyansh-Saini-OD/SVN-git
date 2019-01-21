SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE xxod_trans_comp_pkg
AS
PROCEDURE populate_asset_details(p_book_type_code VARCHAR2
								 ,p_transaction_type_code  VARCHAR2
								 ,p_company_low    VARCHAR2
								 ,p_company_high   VARCHAR2
								 ,p_category_low     VARCHAR2
								 ,p_category_high    VARCHAR2
                         ,p_period_from            VARCHAR2
                         ,p_period_to              VARCHAR2
								 ,p_layout_type         VARCHAR2
								 );
-- +============================================================================+ 
-- |                  Office Depot - Project Simplify                           | 
-- |                  Wirpo / Office Depot                                      | 
-- +============================================================================+ 
-- | Name             :  POPULATE_ASSET_DETAILS			                          | 
-- | Description      :  This Procedure is used to Populate the Asset           | 
-- |                     Details in xxod_fa_cost_comp_temp                      | 
-- |                                                                            | 
-- |Change Record:                                                              | 
-- |===============                                                             | 
-- |Version   Date        Author           Remarks                              | 
-- |=======   ==========  =============    =====================================| 
-- |DRAFT 1.0 26-AUG-2007  Senthil Kumar    Initial draft version               | 
-- |          15-Nov-2007  Ganesan          Fix for Defect 2315                 | 
-- |                                        To improve the performance          | 
-- |                                        , modified the package              | 
-- |                                        to use Bulk Collect,Query based on  | 
-- |                                        Transaction Type code               | 
-- | 		     13-dec-2007  Ganesan          Added the parameter p_layout_type   | 
-- |                                        to insert the data based on the     | 
-- |							                    layout type                         | 
-- |         24-JAN-2007   Ganesan         Changed the Parameters for the Period| 
-- |                                       Informations are taken inside the    | 
-- |                                       Package.Since the Period Informations| 
-- |                                       changes with respect to the Book     | 
-- +============================================================================+ 

END xxod_trans_comp_pkg;
/
SHOW ERROR
