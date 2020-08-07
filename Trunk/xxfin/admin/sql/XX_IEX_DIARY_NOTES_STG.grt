--+========================================================================================+
--|      Office Depot - Project FIT                                                        |
--|   Capgemini/Office Depot/Consulting Organization                                       |
--+========================================================================================+
--|Name        :XX_IEX_DIARY_NOTES_STG.grt                                                 |
--|RICE        :                                                                           |
--|Description : Assigning grants to custom schema                                         |
--|                                                                                        |
--|                                                                                        |
--|Change Record:                                                                          |
--|==============                                                                          |
--|Version   Date            Author                      Remarks                           |
--|=======   ===========     ====================        ===============                   |
--|1.00      18-OCT-2011     Gangi Reddy M               Initial Version                   |
--+========================================================================================+

SET VERIFY OFF
WHENEVER SQLERROR CONTINUE

GRANT ALL ON  XXFIN.XX_IEX_DIARY_NOTES_STG TO APPS;
