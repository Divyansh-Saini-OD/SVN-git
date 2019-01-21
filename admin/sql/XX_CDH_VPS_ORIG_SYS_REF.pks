create or replace PACKAGE      XX_CDH_VPS_ORIG_SYS_REF
AUTHID CURRENT_USER AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_CDH_VPS_ORIG_SYS_REF                                                     	      |
  -- |                                                                                            |
  -- |  Description:  This package is used to update orig system reference.        	              |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         01-OCT-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+

 PROCEDURE update_origsystem_adhoc (
      p_errbuf_out              OUT      VARCHAR2
     ,p_retcod_out              OUT      VARCHAR2
     ,p_vendor_number           IN       VARCHAR2
     ,p_account_number          IN       VARCHAR2
   );

END XX_CDH_VPS_ORIG_SYS_REF;
/