create or replace PACKAGE xx_ap_dcn_pkg
IS

-- +=============================================================================================+
-- |  Office Depot - Project Simplify                                                            |
-- |                                                                                             |
-- +=============================================================================================+
-- |  Name:  XX_AP_DCN_PKG                                                                       |
-- |  Description:  This package is used to process DCN data from the vendor ACS                 |
-- |                                                                                             |
-- |  Change Record:                                                                             |
-- +=============================================================================================+
-- | Version     Date         Author            Remarks                                          |
-- | =========   ===========  =============     ===============================================  |
-- | 1.0         03/10/2007   Anamitra Banerjee Initial version                                  |
-- | 2.0         12/16/2009   Joe Klein         Added process_dcn_records procedure to replace   |
-- |                                            sql plus script XXAPDCNINT.sql.  See that script |
-- |                                            for all defects previous to this procedure that  |
-- |                                            are included in this new procedure.              |
-- +=============================================================================================+



-- +=============================================================================================+
-- |  Name: process_dcn_records                                                                  |
-- |  Description: This procedure will process the inbound DCN records and create the outbound   |
-- |               file to be sent to the vendor.                                                |
-- |                                                                                             |
-- |  Parameters:   None                                                                         |
-- |                                                                                             |
-- +=============================================================================================+
  PROCEDURE process_dcn_records
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2);
   
-- +=============================================================================================+
-- |  Name: get_pay_site                                                                         |
-- |  Description: This function will get the correct vendor pay site for an invoice.            |
-- |                                                                                             |
-- |  Parameters:                                                                                |
-- |    v_global_vendor_id      IN  -- global vendor id                                          |
-- |    v_vendor_site_id        OUT -- vendor site id for pay site                               |
-- |                                                                                             |
-- +==============================================================================================+   
  FUNCTION get_pay_site(v_global_vendor_id  VARCHAR2,v_sysdate  DATE DEFAULT SYSDATE) RETURN NUMBER;

END xx_ap_dcn_pkg;
/