create or replace
PACKAGE XXCRMEXCELFORMAT AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XXCRMEXCELFORMAT Package Specification                                             |
-- |  Description:     OD: TDS Vendor Subscription Report                                       |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         14-MAR-2013  POOJA MEHRA        Initial version                                |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name: XXCRMEXCELFORMAT.XX_CS_VND_SUBS_RPT                                                 |
-- |  Description: This pkg.procedure will extract the report in excel format                   |
-- |  for concurrent program OD: TDS Vendor Subscription Report (Excel)                         |
-- =============================================================================================|

PROCEDURE XX_CS_VND_SUBS_RPT( x_err_buff      OUT VARCHAR2
                             ,x_ret_code      OUT NUMBER
                             ,start_date	  IN  VARCHAR2
                             ,end_date		  IN  VARCHAR2
                            );
                                      

END XXCRMEXCELFORMAT ;
/