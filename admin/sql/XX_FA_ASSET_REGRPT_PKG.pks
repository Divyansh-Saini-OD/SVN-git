SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package  XX_FA_ASSET_REGRPT_PKG

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
-- +=========================================================================+

create or replace
PACKAGE  XX_FA_ASSET_REGRPT_PKG AS

  --+============================================================================+
  --| Name          : xx_fa_get_compl_period                                     |
  --| Description   : This function returns asset completion FA period           |
  --|                                                                            |
  --|                                                                            |
  --| Parameters    :                                                            |
  --|                                                                            |
  --| Returns       : N/A                                                        |
  --|                                                                            |
  --+============================================================================+ 

  FUNCTION xx_fa_get_compl_period(p_psdate DATE,p_month NUMBER,p_asset_id NUMBER,p_book VARCHAR2)
  RETURN VARCHAR2;


  --+============================================================================+
  --| Name          : process_asset_register                                     |
  --| Description   : This procedure generates asset register data               |
  --|                                                                            |
  --|                                                                            |
  --| Parameters    :                                                            |
  --|                                                                            |
  --| Returns       : N/A                                                        |
  --|                                                                            |
  --+============================================================================+    

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

END XX_FA_ASSET_REGRPT_PKG;
/
SHOW ERRORS;