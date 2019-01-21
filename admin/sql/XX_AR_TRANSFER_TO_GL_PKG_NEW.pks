SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_AR_TRANSFER_TO_GL_PKG_NEW
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_AR_TRANSFER_TO_GL_PKG.pks                       |
-- | Description :   						       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date         Author           Remarks                   |
-- |========   ===========  ===============  ==========================|
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
-- | Name        :  generate_group                                      |
-- | Description :  							|
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  			                                |
-- |                                                                    |
-- | Returns     :                                                      |
-- |                                                                    |
-- +====================================================================+

PROCEDURE generate_group(
                      x_errbuf              OUT NOCOPY VARCHAR2
                      ,x_retcode            OUT NOCOPY VARCHAR2
                      ,p_batch_size         IN         NUMBER
                      ,p_req_id             IN         NUMBER
                      ,p_check_interval     IN         NUMBER
      		          ,p_max_wait_time      IN         NUMBER
                      ,p_email_id           IN         VARCHAR2
                     );



END XX_AR_TRANSFER_TO_GL_PKG_NEW;
/
SHOW ERRORS

