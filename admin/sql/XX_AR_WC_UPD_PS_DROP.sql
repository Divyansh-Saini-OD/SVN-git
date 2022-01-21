--+=====================================================================+
--|                   Office Depot - Project FIT                        |
--|          Capgemini/Office Depot/Consulting Organization             |
--+=====================================================================+
--|                                                                     |
--|Rice        : 106313                                                 |
--|File Name   : XX_AR_WC_UPD_PS_DROP.sql                                    |
--|File Path   : $XXFIN_TOP/admin/sql                                   |
--|Schema      : XXFIN                                                  |
--|                                                                     |
--|Version    Date           Author                       Remarks       |
--|=======   ======        ====================          =========      |
--| 1.0      15-DEC-11    Purushothaman.Narmatha                        |
--|                                                                     |
--+=====================================================================+

SET VERIFY OFF
WHENEVER SQLERROR CONTINUE

PROMPT "Droping Table XX_AR_WC_UPD_PS..."
DROP TABLE XXFIN.XX_AR_WC_UPD_PS CASCADE CONSTRAINTS;
