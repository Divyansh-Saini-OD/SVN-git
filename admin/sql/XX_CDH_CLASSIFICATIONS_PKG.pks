SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_CLASSIFICATIONS_PKG

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_CLASSIFICATIONS_PKG.pks                     |
-- | Description :  Custom party classifications into industrial       |
-- |                classifications section in Oracle Customers Online |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  03-Apr-2007 Madhukar Salunke   Initial draft version     |
-- |Draft 1b  10-Apr-2007 Ambarish Mukherjee Reviewed and updated.     |
-- |Draft 1c  02-Jul-2007 Ashok Kumar T J    Modified file name as per |
-- |                                         new MD040.                |
-- +===================================================================+
IS

--+============================================================================================================+
--| PROCEDURE  : Load_party_classification                                                                     |
--| x_errbuf                 OUT   VARCHAR2   Standard Concurrent program Parameter                            |
--| x_retcode                OUT   NUMBER     Standard Concurrent program Parameter                            |
--| p_classification         IN    VARCHAR2   Identify the classification that needs to be used or create      |
--| p_classification_type    IN    VARCHAR2   This will identify the type of classification to create          |
--| p_delimiter              IN    VARCHAR2   This is freeform text to identify the delimiter to use           |
--| p_allow_mul_parent       IN    VARCHAR2   This is a parameter to be used when creating a new classification|
--| p_allow_parent_asgn      IN    VARCHAR2   This is a parameter to be used when creating a new classification|
--| p_allow_mul_class_asgn   IN    VARCHAR2   This is a parameter to be used when creating a new classification|
--+============================================================================================================+

PROCEDURE Load_party_classification  (
            x_errbuf                 OUT   VARCHAR2,
            x_retcode                OUT   NUMBER,
            p_classification         IN    VARCHAR2,
            p_classification_type    IN    VARCHAR2,
            p_delimiter              IN    VARCHAR2,
            p_allow_mul_parent       IN    VARCHAR2,
            p_allow_parent_asgn      IN    VARCHAR2,
            p_allow_mul_class_asgn   IN    VARCHAR2
            );

--+=========================================================================================================+
--| PROCEDURE  : fetch_parent_code                                                                          |
--| p_child_code            IN   VARCHAR2   To identify the parent class code                               |
--| p_classification        IN   VARCHAR2   Classification name                                             |
--| x_parent_code           OUT  VARCHAR2   Returns parent code                                             |
--| x_return_status         OUT  VARCHAR2   Returns return status                                           |
--| x_return_msg            OUT  VARCHAR2   Returns return message                                          |
--+=========================================================================================================+

PROCEDURE fetch_parent_code  (
            p_child_code            IN   VARCHAR2,
            p_classification        IN   VARCHAR2,
            x_parent_code           OUT  VARCHAR2,
            x_return_status         OUT  VARCHAR2,
            x_return_msg            OUT  VARCHAR2
            );

END xx_cdh_classifications_pkg;
/
SHOW ERRORS;
EXIT;

