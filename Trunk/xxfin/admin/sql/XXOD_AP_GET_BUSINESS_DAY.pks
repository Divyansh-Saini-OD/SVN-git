create or replace PACKAGE XXOD_AP_GET_BUSINESS_DAY
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                      Wipro/Office Depot                           |
-- +===================================================================+
-- | Name  : XXOD_AP_GET_BUSINESS_DAY                                  |
-- | Description: To get the business day                              |
-- |                                                                   |                
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author            Remarks                   |
-- |=======   ==========   =============     ==========================|
-- |1.0       18-OCT-2007  Ganesan JV        Initial Version	       |			
-- +===================================================================+|
FUNCTION ap_get_business_day (p_date DATE)
RETURN DATE;
END XXOD_AP_GET_BUSINESS_DAY;
/
