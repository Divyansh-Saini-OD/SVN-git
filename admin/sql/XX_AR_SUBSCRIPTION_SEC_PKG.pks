create or replace PACKAGE XX_AR_SUBSCRIPTION_SEC_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_AR_SUBSCRIPTION_SEC_PKG                                                         |
  -- |                                                                                            |
  -- |  Description:  This package is to process subscription billing                             |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         25-JAN-2018  Sreedhar Mohan   Initial version                                  |
  -- +============================================================================================+

  procedure get_clear_token (
                       x_errbuf      OUT NOCOPY      VARCHAR2
				     , x_retcode     OUT NOCOPY      NUMBER
				     , p_label       IN              VARCHAR2
				     , p_hash_value  IN              VARCHAR2
  );
                                 
END XX_AR_SUBSCRIPTION_SEC_PKG;
/

