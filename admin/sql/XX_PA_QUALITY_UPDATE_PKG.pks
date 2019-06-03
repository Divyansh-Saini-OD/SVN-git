CREATE OR REPLACE PACKAGE XX_PA_QUALITY_UPDATE_PKG IS
/**********************************************************************************
 Program Name: XX_PA_IDEA_PROJECT_PKG
 Purpose:      To Create Projects from PLM to Oracle Projects.

 REVISIONS:
-- Version Date        Author                               Description
-- ------- ----------- ----------------------               ---------------------
-- 1.0     11-Oct-2007 Siva Boya, Clearpath.         Created base version.
--
**********************************************************************************/
PROCEDURE XXOD_QUALITY_PROJECT_ATTR (retcode        OUT VARCHAR2                             
                               ,errbuf         OUT VARCHAR2
                             );
END   XX_PA_QUALITY_UPDATE_PKG; 
/
EXIT;
