CREATE OR REPLACE PACKAGE XX_PA_FINPLAN_PKG IS
/**********************************************************************************
 Program Name: XXX_PA_FINPLAN_PKG
 Purpose:      To Create Revenue Forecast.

 REVISIONS:
-- Version Date        Author                               Description
-- ------- ----------- ----------------------               ---------------------
-- 1.0     27-SEP-2007 Siva Boya, Clearpath.         Created base version.
--
**********************************************************************************/
PROCEDURE XXOD_CREATE_FINPLAN (
                                retcode        OUT VARCHAR2                             
                               ,errbuf         OUT VARCHAR2
                               ,p_project_number IN pa_projects_all.segment1%TYPE);
END   XX_PA_FINPLAN_PKG; 
/
EXIT;
