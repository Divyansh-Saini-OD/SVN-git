create or replace 
PACKAGE XX_AP_OPINACCC_BURST
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_OPINACCC_BURST                                                    |
  -- |                                                                                            |
  -- |  Description:  Package created afterReport Trigger                                         |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         04/08/2019   Bhargavi Ankolekar Initial version                                |
  -- +============================================================================================+
  
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  afterReport                                                                      |
  -- |                                                                                            |
  -- |  Description:  Common Report for XML bursting                                              |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+


FUNCTION afterReport RETURN BOOLEAN;

P_CONC_REQUEST_ID  		NUMBER;

END XX_AP_OPINACCC_BURST;
/