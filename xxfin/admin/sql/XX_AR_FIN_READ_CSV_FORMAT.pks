create or replace PACKAGE XX_AR_FIN_READ_CSV_FORMAT
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_AR_FIN_READ_CSV_FORMAT                                                      	  |
  -- |                                                                                            |
  -- |  Description:  This package is used to process CSV comma separated file.                   |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-JUNE-2019  Thejaswini Rajula    Initial version                             |
  -- +============================================================================================+

FUNCTION read_next_element (p_data IN OUT VARCHAR2
                          , p_delimiter IN VARCHAR2
                          , p_encapsulator IN VARCHAR2)
      RETURN VARCHAR2;
END XX_AR_FIN_READ_CSV_FORMAT ;
/