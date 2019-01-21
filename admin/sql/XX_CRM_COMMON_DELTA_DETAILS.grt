--+=====================================================================+
--|                   Office Depot - Project FIT                        |
--|          Capgemini/Office Depot/Consulting Organization             |
--+=====================================================================+
--|                                                                     |
--|Rice        : 106313                                                 |
--|File Name   : XX_CRM_COMMON_DELTA_DETALIS.grt                        |
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
                
GRANT ALL ON XXCRM.XX_CRM_COMMON_DELTA_DETAILS TO APPS WITH GRANT OPTION;