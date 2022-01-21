WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_CHECK_DETAILS_OBJ_TYPE.vw                                 |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        19-JAN-2018    Uday Jadhav         	Initial Version           |
-- +==========================================================================+

prompt Create XX_AP_CHECK_DETAILS_REC_TYPE...
create or replace TYPE XX_AP_CHECK_DETAILS_REC_TYPE AS OBJECT ( document_nbr   VARCHAR2(100),
																 document_date  DATE,
																 gross_amt      NUMBER,
																 adj_amt	    NUMBER,
																 disc_amt		NUMBER,
																 net_amt		NUMBER,
																 description	VARCHAR2(100)
																 );
/
show err 

prompt Create XX_AP_CHECK_DETAILS_OBJ_TYPE...
CREATE OR REPLACE TYPE "XX_AP_CHECK_DETAILS_OBJ_TYPE" AS TABLE OF XX_AP_CHECK_DETAILS_REC_TYPE;
/
show err