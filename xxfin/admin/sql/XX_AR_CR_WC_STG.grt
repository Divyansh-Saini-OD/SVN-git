--+=====================================================================+
--|                   Office Depot - Project FIT                        |
--|          Capgemini/Office Depot/Consulting Organization             |
--+=====================================================================+
--|                                                                     |
--|Rice        : 106313                                                 |
--|File Name   : XX_AR_CR_WC_STG.grt                                    |
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
                  
PROMPT "Grant on table XX_AR_CR_WC_STG to APPS Schema..."
GRANT ALL ON XXFIN.XX_AR_CR_WC_STG TO APPS;
