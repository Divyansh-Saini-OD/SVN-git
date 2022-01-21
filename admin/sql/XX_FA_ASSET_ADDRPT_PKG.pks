SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package  XX_FA_ASSET_ADDRPT_PKG

Prompt Program Exits If The Creation Is Not Successful

WHENEVER SQLERROR CONTINUE
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             : XX_FA_ASSET_ADDRPT_PKG                          |
-- | Description      : This Program generates fixed asset data,related to   |
-- |                   additions and register for the report, into Table     |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    20-Mar-2015   Madhu Bolli       Initial code                  |
-- |    1.1    16-Apr-2015   Paddy Sanjeevi    Defect 1110                   |
-- +=========================================================================+

create or replace
PACKAGE  XX_FA_ASSET_ADDRPT_PKG AS

  --=================================================================
  -- Declaring Global variables
  --=================================================================
  p_period varchar2(25);
  p_book_type varchar2(50);
  p_location varchar2(25);

  --+============================================================================+
  --| Name          : process_asset_addition                                     |
  --| Description   : This function process fixed assets data and                |
  --|                     
  --|                                                                            |
  --| Parameters    :                                                            |
  --|                                                                            |
  --| Returns       : N/A                                                        |
  --|                                                                            |
  --+============================================================================+    

  FUNCTION process_asset_addition RETURN BOOLEAN;   

  PROCEDURE process_asset_register ( x_errbuf      	OUT NOCOPY VARCHAR2
                                    ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_period		IN  VARCHAR2
				    ,p_book_type	IN  VARCHAR2
				    ,p_company		IN  VARCHAR2
				    ,p_cost_ctr		IN  VARCHAR2
				    ,p_location		IN  VARCHAR2
				    ,p_lob		IN  VARCHAR2
				    ,p_cat_major	IN  VARCHAR2
	    		          );


END XX_FA_ASSET_ADDRPT_PKG;
/
SHOW ERRORS;