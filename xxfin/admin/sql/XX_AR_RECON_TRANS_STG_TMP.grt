--+=====================================================================+
--|                   Office Depot - Project FIT                        |
--|          Capgemini/Office Depot/Consulting Organization             |
--+=====================================================================+
--|                                                                     |
--|Rice        : I2160                                                  |
--|File Name   : XX_AR_RECON_TRANS_STG_TMP.grt                          |
--|File Path   : $XXFIN_TOP/admin/sql                                   |
--|Schema      : xxfin                                                  |
--|                                                                     |
--|Version  Date         Author             Remarks                     |
--|=======  ===========  =================  ============================|
--|1.0      03-OCT-2011  R.Aldridge         Initial Creation.           |
--|                                                                     |
--+=====================================================================+

SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
                  
GRANT ALL ON XXFIN.XX_AR_RECON_TRANS_STG_TMP TO APPS WITH GRANT OPTION;
