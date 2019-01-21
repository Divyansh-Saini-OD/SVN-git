--+========================================================================================+
--|      Office Depot - Project FIT                                                        |
--|   Capgemini/Office Depot/Consulting Organization                                       |
--+========================================================================================+
--|Name        :XX_IEX_DIARY_NOTES_STG_DROP.sql                                            |
--|RICE        :                                                                           |
--|Description : Drop the Staged Tables for diary Notes                                    |
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

DROP TABLE XXFIN.XX_IEX_DIARY_NOTES_STG;
