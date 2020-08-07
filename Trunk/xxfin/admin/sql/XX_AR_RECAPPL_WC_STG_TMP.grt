--+=====================================================================+
--|                   Office Depot - Project FIT                        |
--|          Capgemini/Office Depot/Consulting Organization             |
--+=====================================================================+
--|                                                                     |
--|Rice        : I2158                                                  |
--|File Name   : XX_AR_RECAPPL_WC_STG_TMP.grt                           |
--|File Path   : $XXFIN_TOP/admin/sql                                   |
--|Schema      : XXFIN                                                  |
--|                                                                     |
--|Version    Date        Author                Remarks                 |
--|=======   ===========  ====================  ========================|
--| 1.0      28-MAR-2012  R.Aldridge            Initial                 |
--|                                                                     |
--+=====================================================================+

SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
                  
PROMPT "Grant on table XX_AR_RECAPPL_WC_STG_TMP to APPS Schema..."
GRANT ALL ON XXFIN.XX_AR_RECAPPL_WC_STG_TMP TO APPS;
