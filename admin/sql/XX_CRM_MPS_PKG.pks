create or replace
PACKAGE XX_CRM_MPS_PKG AS
-- +=============================================================================+
-- |                     Office Depot                                            |
-- +=============================================================================+
-- | Name             : XX_OD_MPS_PKG                           |
-- | Description      : This Package
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |Version    Date          Author            Remarks                           |
-- |=======    ==========    =============     ==================================|
-- |DRAFT 1A   10-OCT-2012   Suraj Charan      Initial draft version             |
-- |V1.0       03-Jun-2013   Suraj Charan      Defect: 23597 parameter location  |
-- |                                               change to serialno            |
-- |V2.0       15-Jul-2013   Suraj Charan      Location Update                   |
-- |v3.0       22-May-2014   Shubhashree R     Address2, PO Number update        |
-- +=============================================================================+
PROCEDURE UPDATE_CUSTOMER_CONTACTS(P_PARTY_ID   IN VARCHAR2
                                  , P_CONTACT     IN VARCHAR2
                                  , P_PHONE       IN VARCHAR2
                                  , P_ADDRESS1    IN VARCHAR2
                                  , P_ADDRESS2    IN VARCHAR2
                                  , P_CITY        IN VARCHAR2
                                  , P_STATE       IN VARCHAR2
                                  , P_ZIP         IN VARCHAR2
                                  , P_COSTCENTER  IN VARCHAR2
                                  , P_SERIALNO    IN VARCHAR2
                                  , P_LOCATION    IN VARCHAR2
                                  , P_PONUMBER    IN VARCHAR2
                                  , P_RESULT      out varchar2
                                  );

END XX_CRM_MPS_PKG;
/