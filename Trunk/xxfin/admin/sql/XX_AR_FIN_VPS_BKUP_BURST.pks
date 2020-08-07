SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE XX_AR_FIN_VPS_BKUP_BURST 
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_AR_FIN_VPS_BKUP_BURST                                                      	  |
  -- |                                                                                            |
  -- |  Description:  This package is used to burst backup email.        	                      |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         21-JUNE-2017  Thejaswini Rajula    Initial version                             |
  -- +============================================================================================+

FUNCTION Bkup_Burst 
  RETURN BOOLEAN;
  
  p_program_id VARCHAR2(250);
  p_vendor_num VARCHAR2(250);

END XX_AR_FIN_VPS_BKUP_BURST ;
/
SHOW ERRORS;