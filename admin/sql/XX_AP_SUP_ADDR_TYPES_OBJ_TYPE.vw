WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_SUP_ADDR_TYPES_OBJ_TYPE.vw                          |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        10-MAR-2018    Sunil Kalal           Initial Version           |
-- +==========================================================================+

prompt Create XX_AP_SUP_ADDR_TYPES_REC_TYPE..
create or replace TYPE "XX_AP_SUP_ADDR_TYPES_REC_TYPE"      AS OBJECT (ADDRESS_TYPE NUMBER,
ADDRESS_TYPE_DESC VARCHAR2(150),
DASHBOARD_IND VARCHAR2(1),
VENDOR_EXTRANET_IND VARCHAR2(1),
    ENABLE_FLAG  varchar2(1));
/
show err


prompt Create  XX_AP_SUP_ADDR_TYPES_OBJ_TYPE...
CREATE OR REPLACE TYPE "XX_AP_SUP_ADDR_TYPES_OBJ_TYPE" AS TABLE OF XX_AP_SUP_ADDR_TYPES_REC_TYPE;
/
show err


