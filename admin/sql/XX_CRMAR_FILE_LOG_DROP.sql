--+=====================================================================+
--|                   Office Depot - Project FIT                        |
--|          Capgemini/Office Depot/Consulting Organization             |
--+=====================================================================+
--|                                                                     |
--|Rice        : 106313                                                 |
--|File Name   : XX_CRM_FILE_LOG_DROP.sql                               |
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

DROP TABLE XXCRM.XX_CRMAR_FILE_LOG;
