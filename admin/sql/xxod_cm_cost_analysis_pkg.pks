create or replace PACKAGE XXOD_CM_COST_ANALYSIS_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Wirpo / Office Depot              |
-- +===================================================================+
-- | Name             :  XXOD_CM_COST_ANALYSIS_PKG.pkb
-- | Description      :  This Package is used by CM Cost Analysis Report |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1.0 26-AUG-2007  Senthil Kumar    Initial draft version       |
-- |DRAFT 1.1 28-FEB-2008  Manovinayak       Changed for 12694           |
-- +===================================================================+
PROCEDURE XXOD_CM_COST_ANALYSIS_PROC(
                                          x_err_buff              OUT VARCHAR2
                                         ,x_ret_code              OUT NUMBER
				                 ,P_PROVIDER_TYPE		IN  VARCHAR2
				                 ,P_CARD_TYPE	            IN VARCHAR2
                                         ,P_DATE                  IN VARCHAR2
                                       );
-- +=====================================================================+
-- | Name :  XXOD_CM_COST_ANALYSIS_PROC                               |
-- | Description : The procedure will submit the : OD: CM Cost Analysis
 --                Report                                                |
-- | Parameters : P_PROVIDER_TYPE,P_CARD_TYPE,P_DATE
-- |               
-- | Returns :  x_err_buff,x_ret_code                                    |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  28-FEB-09    Manovinayak Velayutham        Initial version  |
-- |                                                                     |
-- +=====================================================================+
FUNCTION  get_amount(
                     --p_provider_type VARCHAR2,
                      p_card_type    VARCHAR2
                     ,p_year         VARCHAR2
                     ,p_month        VARCHAR2
                     ,p_card_typ_meaning VARCHAR2 --Added for the defect#15278
                    )
RETURN NUMBER;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Wirpo / Office Depot              |
-- +===================================================================+
-- | Name             :  Get_Amount
-- | Description      :  This function is used to fetch the amount from ajb table |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1.0 26-AUG-2007  Senthil Kumar    Initial draft version       |
-- |DRAFT 1.1 28-FEB-2008  Manovinayak       Changed for 12694           |
-- |1.1       19-MAY-09    Manovinayak     Changes for the             |
-- |                       Ayyappan         defect#15278               |
-- +===================================================================+


FUNCTION  get_deductions_amount(
                                p_provider_type VARCHAR2
                                ,p_card_type    VARCHAR2
                                ,p_year         VARCHAR2
                                ,p_period_name  VARCHAR2
                                ,p_reason_code  VARCHAR2)
RETURN NUMBER;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Wirpo / Office Depot              |
-- +===================================================================+
-- | Name             :  Get_deductions_Amount
-- | Description      :  This function is used to fetch the amount from gl_balances table |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1.0 13-FEB-2008 Senthil Kumar    Initial draft version       |
-- |DRAFT 1.1 28-FEB-2009 Manovinayak       Changed for defect 12694    |
-- +===================================================================+


PROCEDURE populate_cost_analysis(
                                 p_provider_type VARCHAR2 --Added the parameter on 13-Feb-2008 by Senthil as per the CR
				        ,p_card_type    VARCHAR2
				        ,p_date         DATE
                                ,p_card_typ_meaning VARCHAR2 --Added for the defect#15278
				 );
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Wirpo / Office Depot                             |
-- +===================================================================+
-- | Name             :  Populate_Cost_Analysis
-- | Description      :  This procedure is used to populate the Cost Analysis information |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1.0 26-AUG-2007  Senthil Kumar    Initial draft version      |
-- |DRAFT 1.1 28-FEB-2009 Manovinayak       Changed for defect 12694    |
-- |1.1       19-MAY-09    Manovinayak     Changes for the             |
-- |                       Ayyappan         defect#15278               |
-- +===================================================================+

END XXOD_CM_COST_ANALYSIS_PKG ;
/
SHO ERR;
