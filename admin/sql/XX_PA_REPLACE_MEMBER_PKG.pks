CREATE OR REPLACE PACKAGE XX_PA_REPLACE_MEMBER_PKG IS
/**********************************************************************************
 Program Name: XX_PA_IDEA_PROJECT_PKG
 Purpose:      To Create Projects from PLM to Oracle Projects.

 REVISIONS:
-- Version Date        Author                               Description
-- ------- ----------- ----------------------               ---------------------
-- 1.0     15-NOV-2007 Siva Boya, Clearpath.         Created base version.
--
**********************************************************************************/
PROCEDURE XXOD_REPLACE_MEMBER ( retcode        OUT VARCHAR2,
                             errbuf OUT VARCHAR2,
                             p_replace_name IN VARCHAR2 ,
                             p_replace_with IN VARCHAR2,
                             p_department IN VARCHAR2                                                        
                             );
END   XX_PA_REPLACE_MEMBER_PKG; 
/
EXIT;
