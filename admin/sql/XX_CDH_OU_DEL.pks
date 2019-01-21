create or replace
PACKAGE XX_CDH_OU_DEL
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_OU_DEL.pks                                  |
-- | Description :  Code to remove site use OSR ref for OU Corrections |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  02-Nov-2009 Indra Varada       Initial draft version     |
-- +===================================================================+
PROCEDURE fix_site_use_ou
(   x_errbuf            OUT VARCHAR2
   ,x_retcode           OUT VARCHAR2
   ,p_commit            IN  VARCHAR2
   ,p_osr      		IN  VARCHAR2
   ,p_entity_type       IN  VARCHAR2
);
END XX_CDH_OU_DEL;
/
SHOW ERRORS;
EXIT;
