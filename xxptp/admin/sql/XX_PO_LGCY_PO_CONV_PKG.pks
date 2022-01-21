CREATE OR REPLACE PACKAGE XX_PO_LGCY_PO_CONV_PKG AUTHID CURRENT_USER 
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  :       XX_PO_LGCY_PO_CONV_PKG.pks                                  |
-- | Description:  This package spec is used in conversion Purchase Orders     |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date           Author                        Remarks             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1A  09-MAY-2007  Seemant Gour          Initial draft version         |
-- |Draft 1B  18-JUN-2007  Ritu Shukla                                         |
-- |Draft 1C  28-JUN-2007  Ritu Shukla           TL Review Comments            |
-- |Draft 1D  17-JUL-2007  Ritu Shukla           Included Debug_flag,record id |
-- |                                             linking                       |
-- |1.0       24-SEP-2007  Remya Sasi            Baselined.                    |
-- +===========================================================================+
AS

---------------------------
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

--------------------------------------------------------------------------------------------------------
--Declaring master_main procedure which gets called from OD: PO Purchase Order Conversion Master Program
--------------------------------------------------------------------------------------------------------
PROCEDURE master_main (
                        x_errbuf              OUT NOCOPY VARCHAR2
                       ,x_retcode             OUT NOCOPY VARCHAR2
                       ,p_validate_only_flag  IN         VARCHAR2
                       ,p_reset_status_flag   IN         VARCHAR2
                       ,p_batch_size          IN         NUMBER
                       ,p_max_thread          IN         NUMBER     
                       ,p_debug_flag          IN         VARCHAR2            
                      );
                     
-------------------------------------------------------------------------------------------------------
--Declaring master_main procedure which gets called from OD: PO Purchase Order Conversion Child Program
-------------------------------------------------------------------------------------------------------                  
PROCEDURE child_main(
                      x_errbuf             OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                     ,p_validate_only_flag IN         VARCHAR2
                     ,p_reset_status_flag  IN         VARCHAR2
                     ,p_batch_id           IN         NUMBER
                     ,p_debug_flag         IN         VARCHAR2                   
                    );               

END  XX_PO_LGCY_PO_CONV_PKG;
/
