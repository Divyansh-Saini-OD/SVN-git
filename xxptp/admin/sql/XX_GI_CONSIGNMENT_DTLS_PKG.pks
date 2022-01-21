SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_GI_CONSIGNMENT_DTLS_PKG AUTHID CURRENT_USER
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
-- +===========================================================================+
-- | Name        :   XX_GI_CONSIGNMENT_DTLS_PKG.pks                            |        
-- |                                                                           |
-- | Description :  Package Specification for E0356a_Consignment.              |
-- |                                                                           |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1a  11-Sep-2007  Chandan U H      Initial draft version              |
-- |1.0       12-Sep-2007  Chandan U H      Base Lined                         |
-- +===========================================================================+

AS
----------------------------
--Declaring Global Constants
----------------------------

----------------------------
--Declaring Global Variables
----------------------------

-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

----------------------------------------------------------------------------------------
--Declaring XX_GI_IS_CONSIGNED procedure which gets called 
----------------------------------------------------------------------------------------
PROCEDURE  XX_GI_IS_CONSIGNED  
                ( p_item_id               IN    NUMBER
                 ,p_organization_id       IN    NUMBER
                 ,x_consignment_flag      OUT   NOCOPY  VARCHAR2
                 ,x_vendor_id             OUT   NOCOPY  NUMBER
                 ,x_vendor_site_id        OUT   NOCOPY  NUMBER                 
                 ,x_return_status         OUT   NOCOPY  VARCHAR2
                 ,x_return_message        OUT   NOCOPY  VARCHAR2
                );

END  XX_GI_CONSIGNMENT_DTLS_PKG;
/
SHOW ERRORS
EXIT;