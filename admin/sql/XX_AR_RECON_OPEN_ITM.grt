--+=====================================================================+
--|                   Office Depot - Project FIT                        |
--|          Capgemini/Office Depot/Consulting Organization             |
--+=====================================================================+
--|                                                                     |
--|Rice        : 106313                                                 |
--|File Name   : XX_AR_RECON_OPEN_ITM.grt                               |
--|File Path   : $XXFIN_TOP/admin/sql                                   |
--|Schema      : XXFIN                                                  |
--|                                                                     |
--|Version    Date           Author                       Remarks       |
--|=======   ======        ====================          =========      |
--| 1.0    06-Sep-2011     Balakrishna Bolikonda       Initial version  |
--|                                                                     |
--+=====================================================================+

SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
                  
GRANT ALL ON XXFIN.XX_AR_RECON_OPEN_ITM TO APPS WITH GRANT OPTION;
