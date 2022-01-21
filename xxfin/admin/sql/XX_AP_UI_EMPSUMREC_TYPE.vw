WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_UI_EMPSUMREC_TYPE.vw                                |
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

prompt Create XX_AP_UI_EMPSUMREC_TYPE...
CREATE OR REPLACE TYPE XX_AP_UI_EMPSUMREC_TYPE  AS OBJECT (
						invoice_id 			NUMBER,
						terms_id 			NUMBER,
						vendor_id 			NUMBER,
						vendor_site_id 		NUMBER,
						org_id 				NUMBER,
						HOLD_TYPE 			VARCHAR2(10),
						inv_amount 			NUMBER,
						line_total 			NUMBER,
						inv_count 			NUMBER,
						attribute6 			VARCHAR2(25)
					);
/					
show err


prompt Create XX_AP_UI_EMPSUMREC_TYPE_T...
CREATE OR REPLACE TYPE XX_AP_UI_EMPSUMREC_TYPE_T AS TABLE OF XX_AP_UI_EMPSUMREC_TYPE;
/
show err
