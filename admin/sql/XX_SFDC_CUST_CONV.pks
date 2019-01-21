SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +============================================================================================+
-- |                  Office Depot - Project Simplify                                           |
-- +============================================================================================+
-- | Name        : XX_SFDC_CUST_CONV.pks                                                        |
-- | Description : SFDC Conversion                                                              |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        26-Aug-2011     Indra Varada        Initial version                              |
-- |1.1       18-May-2016   Shubashree R     Removed the schema reference for GSCC compliance QC#37898|
-- +============================================================================================+
CREATE OR REPLACE 
PACKAGE XX_SFDC_CUST_CONV AS

date_format      VARCHAR2(50) := 'MM/dd/yyyy HH24:mm:ss';


  PROCEDURE create_gp (
   x_errbuf                 OUT NOCOPY VARCHAR2,
   x_retcode                OUT NOCOPY VARCHAR2,
   p_conv_type              VARCHAR2 DEFAULT 'FULL'
  );

  PROCEDURE create_cust_hier(
   x_errbuf                 OUT NOCOPY VARCHAR2,
   x_retcode                OUT NOCOPY VARCHAR2,
   p_conv_type              VARCHAR2 DEFAULT 'FULL'
  );

  FUNCTION trf_country (
    p_country       VARCHAR2
  )RETURN VARCHAR2;

  FUNCTION trf_phone (
    p_country_code       VARCHAR2,
    p_area_code          VARCHAR2,
    p_phone_num          VARCHAR2,
    p_raw_phone          VARCHAR2,
    p_extension          VARCHAR2,
    p_type               VARCHAR2
  )RETURN VARCHAR2;

  FUNCTION trf_null(
  trval VARCHAR2
  )RETURN VARCHAR2;

   PROCEDURE set_delta_times(
   x_errbuf                 OUT NOCOPY VARCHAR2,
   x_retcode                OUT NOCOPY VARCHAR2
  );

 


	FUNCTION fnc_created_by (p_created_by VARCHAR2)
	RETURN VARCHAR2;

END XX_SFDC_CUST_CONV;
/

SHOW ERRORS;