WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_UI_EMP_SUMM.vw                                      |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        18-OCT-2017    Paddy Sanjeevi        Initial Version           |
-- +==========================================================================+

prompt Create XX_AP_UI_EMP_SUMM...
CREATE OR REPLACE TYPE XX_AP_UI_EMP_SUMM  AS OBJECT (
					vendor_assistant 		VARCHAR2(100),
					employee_id				VARCHAR2(20),
					total_inv_count			NUMBER,
					total_inv_amount		NUMBER,
					total_line_amount		NUMBER,
					total_moot_count		NUMBER,
					total_moot_inv_amount	NUMBER,
					total_moot_line_amount	NUMBER,
					total_nrf_count			NUMBER,
					total_nrf_amount		NUMBER
					);
/
show err


prompt Create XX_AP_UI_EMP_SUMM_T...
CREATE OR REPLACE TYPE XX_AP_UI_EMP_SUMM_T AS TABLE OF XX_AP_UI_EMP_SUMM;
/
show err
