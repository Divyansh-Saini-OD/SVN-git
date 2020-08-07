CREATE OR REPLACE PACKAGE APPS.XX_DBA_WFROLE_ASSIGN_PKG
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                            Providge                                      |
-- +==========================================================================+
-- | Name             :    XX_DBA_WFROLE_ASSIGN_PKG                           |
-- | Description      :    Package for assign roles                           |
-- | RICE             :    E3078                                              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      3-Nov-2013   Paddy Sanjeevi      Initial                        |
-- +==========================================================================+

    PROCEDURE assign_roles        ( p_errbuf   		IN OUT    VARCHAR2
                                   ,p_retcode  		IN OUT    NUMBER
                                   ,p_role_name 	IN 	  VARCHAR2
	                           ,p_email_list        IN 	  VARCHAR2
				   ,p_cc_mail		IN 	  VARCHAR2
                                  );

END XX_DBA_WFROLE_ASSIGN_PKG;
/
