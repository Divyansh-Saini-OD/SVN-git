--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        : XX_IEX_DIARY_NOTES_STG_TMP.grt                         |
--|RICE        : I2159                                                  |
--|Description : Assigning grants to custom schema                      |
--|                                                                     |
--|                                                                     |
--|Change Record:                                                       |
--|==============                                                       |
--|Version   Date            Author                      Remarks        |
--|=======   ===========     ====================        ===============|
--|1.00      28-MAR-2012     R.Aldridge                  Initial Version|
--+=====================================================================+

SET VERIFY OFF
WHENEVER SQLERROR CONTINUE

GRANT ALL ON  XXFIN.XX_IEX_DIARY_NOTES_STG_TMP TO APPS;
