SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_UPD_PROFILE_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_UPD_PROFILE_PKG
AS

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +=======================================================================++
-- | Name        : XX_UPD_PROFILE_PKG                                       |
-- | Description : To update fnd_profile values based on the                |
-- |               requirement.                                             |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      17-MAY-2010  Anitha Devarajulu     Initial version             |
-- |1.1      19-MAY-2010  Anitha Devarajulu     Modified package to take    |
-- |                                            Resp Name as IN parameters  |
-- +========================================================================+

-- +===================================================================+
-- | Name        : UPDATE_PROFILE_VALUE                                |
-- | Description : To update the profile values                        |
-- | Returns     : x_error_buf, x_ret_code                             |
-- +===================================================================+

   PROCEDURE UPDATE_PROFILE_VALUE (
                                    x_error_buf          OUT VARCHAR2
                                   ,x_ret_code           OUT NUMBER
                                   ,p_name               IN  VARCHAR2
                                   ,p_value              IN  VARCHAR2 DEFAULT NULL
                                   ,p_level_name         IN  VARCHAR2
                                   ,p_flag               IN  VARCHAR2 DEFAULT NULL
                                   ,p_level_value        IN  VARCHAR2 DEFAULT NULL
                                   ,p_level_value_app_id IN  VARCHAR2 DEFAULT NULL
                                   ,p_level_value2       IN  VARCHAR2 DEFAULT NULL
                                   ,p_resp_name          IN  VARCHAR2
                                   );

END XX_UPD_PROFILE_PKG;
/
SHOW ERR