SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_GI_WAC_LOAD_CONV_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_GI_WAC_LOAD_CONV_PKG.pks                        |
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

--- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the OD: GI WAC       |
-- |                Conversion Master Program.This would submit child   |
-- |                programs based on batch_size                        |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_validate_only_flag                                |
-- |                p_reset_status_flag                                 |
-- |                p_max_wait_time                                     |
-- |                p_sleep                                             |
-- |                                                                    |
-- | Returns     :                                                      |
-- |                                                                    |
-- +====================================================================+

PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                      ,x_retcode            OUT NOCOPY VARCHAR2
                      ,p_validate_only_flag IN  VARCHAR2
                      ,p_reset_status_flag  IN  VARCHAR2
                      ,p_max_wait_time      IN  NUMBER
                      ,p_sleep              IN  NUMBER
                     );

-- +===================================================================+
-- | Name        :  child_main                                         |
-- | Description :  This procedure is invoked from the OD: GI WAC      |
-- |                Conversion Child Program based on input            |
-- |                parameters.                                        |
-- |                                                                   |
-- | Parameters  :  p_validate_only_flag                               |
-- |                p_reset_status_flag                                |
-- |                p_batch_id                                         |
-- |                p_max_wait_time                                    |
-- |                p_sleep                                            |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE child_main(
                     x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                     ,p_validate_only_flag IN  VARCHAR2
                     ,p_reset_status_flag  IN  VARCHAR2                   
                     ,p_batch_id           IN  NUMBER
                     ,p_max_wait_time      IN  NUMBER
                     ,p_sleep              IN  NUMBER
                    );

END XX_GI_WAC_LOAD_CONV_PKG;
/
SHOW ERRORS
EXIT;

