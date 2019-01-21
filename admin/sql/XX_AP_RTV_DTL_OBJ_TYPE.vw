WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_RTV_DTL_OBJ_TYPE.vw                                 |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        10-OCT-2017    Havish Kasina         Initial Version           |
-- +==========================================================================+

prompt Create XX_AP_RTV_DTL_REC_TYPE...
create or replace TYPE "XX_AP_RTV_DTL_REC_TYPE"  AS OBJECT (country           VARCHAR2(100),
                                                            vendor_num        VARCHAR2(100),
							                                document_num      VARCHAR2(100),
							                                document_date     DATE,
							                                freight_bill_num  VARCHAR2(300),
							                                location	      VARCHAR2(100),
							                                freight_carrier   VARCHAR2(100));
/
show err


prompt Create XX_AP_RTV_DTL_OBJ_TYPE...
CREATE OR REPLACE TYPE "XX_AP_RTV_DTL_OBJ_TYPE" AS TABLE OF XX_AP_RTV_DTL_REC_TYPE;
/
show err