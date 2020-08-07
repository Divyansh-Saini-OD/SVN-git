WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_UI_EMPVNDREC_TYPE.vw                                |
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

prompt Create XX_AP_UI_EMPVNDREC_TYPE...
CREATE OR REPLACE TYPE XX_AP_UI_EMPVNDREC_TYPE  AS OBJECT (
					invoice_id 				NUMBER,
					terms_id 				NUMBER,
					vendor_id 				NUMBER,
					vendor_site_id 			NUMBER,
					org_id 					NUMBER,
					hold_type 				VARCHAR2(10),
					inv_amount 				NUMBER,
					line_total 				NUMBER,
					inv_count 				NUMBER,
					vendor_name 			VARCHAR2(100),
					segment1  				VARCHAR2(25),
					vendor_site_code 		VARCHAR2(15),
					attribute6 				VARCHAR2(25)
				);
/
show err


prompt Create XX_AP_UI_EMPVNDREC_TYPE_T...

CREATE OR REPLACE TYPE XX_AP_UI_EMPVNDREC_TYPE_T AS TABLE OF XX_AP_UI_EMPVNDREC_TYPE;
/
show err
