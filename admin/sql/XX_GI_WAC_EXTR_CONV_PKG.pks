SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_GI_WAC_EXTR_CONV_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_GI_WAC_EXTR_CONV_PKG.pks                        |
-- | Description :  Weighted Average Costs Package Specification       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date         Author           Remarks                   |
-- |========   ===========  ===============  ==========================|
-- |DRAFT 1a   17-Jul-2007  Abhradip Ghosh   Initial draft version     |
-- |DRAFT 1.0  03-Aug-2007  Parvez Siddiqui  TL Review                 |
-- +===================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------

----------------------------
--Declaring Global Variables
----------------------------

-----------------------------------
--Declaring Global Record Variables 
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

-- +====================================================================+
-- | Name        :  load_main                                           |
-- |                                                                    |
-- | Description :  This procedure is invoked from the OD: GI WAC       |
-- |                Extract Conversion Concurrent Program.This will     |
-- |                update the wac_process_flag of                      |
-- |                XX_GI_MTL_TRANS_INTF_STG and will also launch       |
-- |                OD: GI WAC Conversion Master Program.               |
-- |                                                                    |
-- | Parameters  :  p_validate_only_flag                                |
-- |                p_reset_status_flag                                 |
-- |                p_max_wait_time                                     |
-- |                p_sleep                                             |
-- |                                                                    |
-- | Returns     :                                                      |
-- |                                                                    |
-- +====================================================================+

PROCEDURE load_main( 
                    x_errbuf              OUT NOCOPY VARCHAR2
                    ,x_retcode            OUT NOCOPY VARCHAR2
                    ,p_validate_only_flag IN VARCHAR2
                    ,p_reset_status_flag  IN VARCHAR2
                    ,p_max_wait_time      IN NUMBER
                    ,p_sleep              IN NUMBER
                   );

END XX_GI_WAC_EXTR_CONV_PKG;
/
SHOW ERRORS
EXIT;

