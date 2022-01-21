CREATE or REPLACE PACKAGE XX_PO_PUNCHOUT_CLOSE_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_PO_PUNCHOUT_CLOSE_PKG                                                            |
  -- |                                                                                            |
  -- |  Description:  This package is used to close the Punch out PO's, for which the line        |
  -- | status as "Closed For Receiving"                                                           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         08-NOV-2017  Nagendra C    Initial version                                 |
  -- +============================================================================================+
 PROCEDURE main(errbuf        OUT  VARCHAR2,
                retcode       OUT  VARCHAR2,
                pi_no_of_days IN   NUMBER
                );
 
 g_conc_req_id PLS_INTEGER  :=  fnd_global.conc_request_id;  
 g_org_id      PLS_INTEGER  :=  fnd_global.org_id;  
                
END XX_PO_PUNCHOUT_CLOSE_PKG;
/