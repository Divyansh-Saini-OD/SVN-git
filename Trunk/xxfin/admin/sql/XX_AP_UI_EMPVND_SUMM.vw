WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_UI_EMPVND_SUMM.vw                                   |
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

prompt Create XX_AP_UI_EMPVND_SUMM...

CREATE OR REPLACE TYPE XX_AP_UI_EMPVND_SUMM AS OBJECT 
(
    org_id 					NUMBER,	
	vendor_assistant 		VARCHAR2(100),
	employee_id				VARCHAR2(20),
	vendor_name				VARCHAR2(100),
    supplier				VARCHAR2(25),
	vendor_site_code	    VARCHAR2(15),
	disc					VARCHAR2(1),
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

prompt Create XX_AP_UI_EMPVND_SUMM_T...

CREATE OR REPLACE TYPE XX_AP_UI_EMPVND_SUMM_T AS TABLE OF XX_AP_UI_EMPVND_SUMM;
/
show err

