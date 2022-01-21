
 -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name      :  XX_CE_MKTPLC_PRE_STG_N1,XX_CE_MKTPLC_PRE_STG_N2,XX_CE_MKTPLC_PRE_STG_N3      |
  -- |  RICE ID   :                                                                               |                                                                         
  -- |  Change Record:   
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  ---|  1.0        28-JUN-18     Digamber S     Indexes on XX_CE_MARKETPLACE_PRE_STG
  -- +============================================================================================+


REM================================================================================================
REM                                 Start Of Script
REM================================================================================================
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

PROMPT
PROMPT Creating Indexes....
PROMPT


  drop INDEX XX_CE_MKTPLC_PRE_STG_N1  ;

  drop INDEX XX_CE_MKTPLC_PRE_STG_N2 ;

  drop INDEX XX_CE_MKTPLC_PRE_STG_N3 ;
  
WHENEVER SQLERROR CONTINUE;

show error

/

