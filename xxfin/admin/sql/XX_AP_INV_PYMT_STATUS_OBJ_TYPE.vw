WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_INV_PYMT_STATUS_OBJ_TYPE.vw                         |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        11-JUL-2017    Havish Kasina         Initial Version           |
-- +==========================================================================+

prompt Create XX_AP_INV_PYMT_STATUS_REC_TYPE...
CREATE OR REPLACE TYPE "XX_AP_INV_PYMT_STATUS_REC_TYPE"  AS OBJECT (country       VARCHAR2(100),
                                                                    vendor_nbr    VARCHAR2(100),
																	document_nbr  VARCHAR2(100),
																	doc_date      DATE,
																	gross_amount  NUMBER,
																	adj_amt       NUMBER,
																	discount_amt  NUMBER,
																	net_amt       NUMBER,
																	due_date      DATE,
																	check_nbr     VARCHAR2(100),
																	check_amt     NUMBER,
																	check_date    DATE,
																	location      VARCHAR2(100),
																	po_number     VARCHAR2(100),
																	voucher       VARCHAR2(100)
																   );
/
show err


prompt Create XX_AP_INV_PYMT_STATUS_OBJ_TYPE...
CREATE OR REPLACE TYPE "XX_AP_INV_PYMT_STATUS_OBJ_TYPE" AS TABLE OF XX_AP_INV_PYMT_STATUS_REC_TYPE;
/
show err

