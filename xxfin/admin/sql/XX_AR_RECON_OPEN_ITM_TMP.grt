--+=====================================================================+
--|                   Office Depot - Project FIT                        |
--|          Capgemini/Office Depot/Consulting Organization             |
--+=====================================================================+
--|                                                                     |
--|Rice        : I2160                                                  |
--|File Name   : XX_AR_RECON_OPEN_ITM_TMP.grt                           |
--|File Path   : $XXFIN_TOP/admin/sql                                   |
--|Schema      : XXFIN                                                  |
--|                                                                     |
--|Version    Date           Author                       Remarks       |
--|=======   ======        ====================          =========      |
--| 1.0      28-MAR-12     R.Aldridge                                   |
--|                                                                     |
--+=====================================================================+

SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
                  
GRANT ALL ON XXFIN.XX_AR_RECON_OPEN_ITM_TMP TO APPS WITH GRANT OPTION;
