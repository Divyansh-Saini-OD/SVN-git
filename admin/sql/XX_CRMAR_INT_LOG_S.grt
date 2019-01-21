--+=====================================================================+
--|                   Office Depot - Project FIT                        |
--|          Capgemini/Office Depot/Consulting Organization             |
--+=====================================================================+
--|                                                                     |
--|Rice        : 106313                                                 |
--|File Name   : XX_CRMAR_INT_LOG_S.grt                                 |
--|File Path   : $XXCRM_TOP/admin/sql                                   |
--|Schema      : XXCRM                                                  |
--|                                                                     |
--|Version    Date           Author                       Remarks       |
--|=======   ======        ====================          =========      |
--| 1.0    06-Sep-2011     Balakrishna Bolikonda       Initial version  |
--|                                                                     |
--+=====================================================================+

SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
                
GRANT ALL ON XXCRM.XX_CRMAR_INT_LOG_S TO APPS WITH GRANT OPTION;
