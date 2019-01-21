SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_SETUP_UPDATE_PKG 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_SETUP_UPDATE_PKG.pks                        |
-- | Description :  Code to Update Profile and FinTranslation Setups   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  22-Jan-2009 Indra Varada       Initial draft version     |
-- +===================================================================+

AS

  PROCEDURE update_main
   (   x_errbuf                 OUT VARCHAR2,
       x_retcode                OUT VARCHAR2,
       p_profile_name           IN  VARCHAR2,
       p_profile_value          IN  VARCHAR2,
       p_profile_level          IN  VARCHAR2,
       p_profile_level_value    IN  VARCHAR2,
       p_translation_name       IN  VARCHAR2,
       p_source_values          IN  VARCHAR2,
       p_target_values          IN  VARCHAR2,
       p_commit                 IN  VARCHAR2
   );

END XX_CDH_SETUP_UPDATE_PKG;
/
SHOW ERRORS;
EXIT;