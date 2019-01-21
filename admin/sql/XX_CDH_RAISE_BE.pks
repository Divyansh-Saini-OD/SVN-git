SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace
PACKAGE XX_CDH_RAISE_BE 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_RAISE_BE.pkb                                |
-- | Description :  Custom Code To Raise Business Events               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  13-Nov-2008 Indra Varada       Initial draft version     |
-- +===================================================================+
AS

  PROCEDURE event_main
   (
    x_errbuf                OUT   VARCHAR2
   ,x_retcode               OUT   VARCHAR2
   ,p_event_name            IN    VARCHAR2 
   ,p_arg_name              IN    VARCHAR2
   ,p_arg_value             IN    VARCHAR2
   );
END XX_CDH_RAISE_BE;
/
SHOW ERRORS;
EXIT;