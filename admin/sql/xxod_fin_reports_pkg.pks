SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE xxod_fin_reports_pkg

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  IT Convergence/Wirpo?Office Depot                |
-- +===================================================================+
-- | Name             :  XXOD_FIN_REPORTS_PKG                          |
-- | Description      :  This Package is used by Financial Reports     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1.0 24-MAY-2007  M.Cahuas         Initial draft version      |
-- +===================================================================+
AS
   FUNCTION ar_ultimate_party_func (p_party_id NUMBER, p_hierarchy VARCHAR2)
      RETURN NUMBER;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    IT Convergence/Office Depot                    |
-- +===================================================================+
-- | Name             :  AR_ULTIMATE_PARTY_FUNC                        |
-- | Description      :  This Function will be used to get the global  |
-- |                    ultimate party corresponding FOR a given party |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 24-MAY-2007  M.Cahuas         Initial draft version       |
-- |DRAFT 2  31-MAY-2007  M.Cahuas         Change Connect by clause by |
-- |                                       loop sentence               |
-- +===================================================================+
FUNCTION ap_get_business_day (p_date DATE)
      RETURN DATE;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  AP_GET_BUSINESS_DAY                           |
-- | RICE ID          :  R0460                                         |
-- | Description      :  This Function will be used to get the         |
-- |                     business day for the settle date              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-JUL-2007  Malathi         Initial draft version        |
-- |                      karpagam				                          |
-- +===================================================================+
FUNCTION fa_deprn_reserve_book (
							    p_asset_id  IN NUMBER,
							    p_book_type_code IN VARCHAR2,
							    p_period_counter_low IN NUMBER,
							    p_period_counter_high IN NUMBER
							)
 RETURN NUMBER;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  DEPRN_RESERVE_BOOK                            |
-- | RICE ID          :  R0296													  |
-- | Description      :  This Function will be used to get the         |
-- |                     Depreciation Amount for an asset for          |
-- |                     that period                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 02-AUG-2007  Ganesan.JV      Initial draft version        |
-- |								       |														  |
-- +===================================================================+
FUNCTION  fa_cost_book (
                      p_asset_id IN NUMBER,
		      p_book_type_code IN VARCHAR2,
                      p_transaction_type_code IN VARCHAR2,
                      p_period_start_date IN DATE,
                      p_period_end_date IN DATE
                     )
 RETURN NUMBER;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  COST_BOOK                                     |
-- | RICE ID          :  R0296					       						  |
-- | Description      :  This Function will be used to get the         |
-- |                     Cost Amount for an asset for		              |
-- |                     that period for a given book                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 02-AUG-2007  Ganesan.JV      Initial draft version        |
-- |								         											  |
-- +===================================================================+
FUNCTION  get_cost_for_transaction (
                      p_asset_id IN NUMBER,
		      p_book_type_code IN VARCHAR2,
                      p_transaction_type_code IN VARCHAR2,
                      p_period_start_date IN DATE,
                      p_period_end_date IN DATE,
		      p_transaction_header_id IN NUMBER
                     )
 RETURN NUMBER;
 -- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  COST_BOOK                                     |
-- | RICE ID          :  R0296					       						  |
-- | Description      :  This Function will be used to get the         |
-- |                     transfer Cost Amount for an asset for		              |
-- |                     that period for a given book                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 02-AUG-2007  Ganesan.JV      Initial draft version        |
-- |								         											  |
-- +===================================================================+
FUNCTION fa_deprn_amount(
			p_asset_id  IN NUMBER,
			p_book_type_code IN VARCHAR2,
			p_period_counter_low IN NUMBER,
			p_period_counter_high IN NUMBER
			)
 RETURN NUMBER;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  FA_DEPRN_AMOUNTS                              |
-- | RICE ID          :  R0296					              				  |
-- | Description      :  This Procedure will be used to get the        |
-- |                     Depreciation Amount and accumulated           |
-- |                     depreciation for an asset for that period     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 20-Nov-2007  Ganesan.JV      Initial draft version        |
-- |								         											  |
-- +===================================================================+
PROCEDURE FA_DEPRN_AMOUNTS (
			     p_asset_id  IN NUMBER,
			     p_book_type_code IN VARCHAR2,
			     p_period_counter_low IN NUMBER,
			     p_period_counter_high IN NUMBER,
			     x_deprn_amount OUT NUMBER,
			     x_deprn_reserve OUT NUMBER
			    );

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  GET_DSM_NAME                              |
-- | RICE ID          :  R0435					              				  |
-- | Description      :  This function will get the DSM Name for the   |
-- |                     salesrep that is passed as parameter          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 04-MAR-2008  Senthil Kumar   Initial draft version        |
-- |								         											  |
-- +===================================================================+
FUNCTION   get_dsm_name(
                        p_salesrep_id IN NUMBER)
RETURN VARCHAR2;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  GET_RSD_FOR_DSM                               |
-- | RICE ID          :  R0435					              				  |
-- | Description      :  This function will get the RSD Name for the   |
-- |                     DSM GROUP                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 04-MAR-2008  Senthil Kumar   Initial draft version        |
-- |								         											  |
-- +===================================================================+
FUNCTION   get_rsd_for_dsm(
                        p_salesrep_id IN NUMBER)
RETURN VARCHAR2;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  GET_RSD_NAME                                  |
-- | RICE ID          :  R0435					              				  |
-- | Description      :  This function will get the RSD Name for the   |
-- |                     salesrep that is passed as parameter          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 04-MAR-2008  Senthil Kumar   Initial draft version        |
-- |								         											  |
-- +===================================================================+
FUNCTION   get_rsd_name(
                  p_salesrep_id IN NUMBER)
RETURN VARCHAR2;
END xxod_fin_reports_pkg;
/
SHOW ERROR
