WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_CHK_INF_INQUIRY_OBJ_TYPE.vw                            |
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

prompt Create XX_CHK_INF_INQUIRY_REC_TYPE...
CREATE OR REPLACE TYPE "XX_CHK_INF_INQUIRY_REC_TYPE"  AS OBJECT (country       VARCHAR2(100),
                                                                 vendor_nbr    VARCHAR2(100),
																 check_nbr     VARCHAR2(100),
																 check_date    DATE,
																 status        VARCHAR2(100),
																 check_amt     NUMBER,
																 discount_amt  NUMBER,
																 invoice_num   VARCHAR2(100),
																 amount_paid   NUMBER,
																 vendor_name   VARCHAR2(100),
																 address_line1 VARCHAR2(100),
																 address_line2 VARCHAR2(100),
																 city          VARCHAR2(100),
                                                                 state         VARCHAR2(100),
 																 zip           VARCHAR2(100)
																);
/
show err


prompt Create XX_CHK_INF_INQUIRY_OBJ_TYPE...
CREATE OR REPLACE TYPE "XX_CHK_INF_INQUIRY_OBJ_TYPE" AS TABLE OF XX_CHK_INF_INQUIRY_REC_TYPE;
/
show err

