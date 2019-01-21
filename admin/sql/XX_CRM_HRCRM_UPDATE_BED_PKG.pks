SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT 'Creating XX_CRM_HRCRM_UPDATE_BED_PKG package body'
PROMPT

CREATE OR REPLACE PACKAGE XX_CRM_HRCRM_UPDATE_BED_PKG
  -- +====================================================================================+
  -- |                  Office Depot - Project Simplify                                   |
  -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                        |
  -- +====================================================================================+
  -- |                                                                                    |
  -- | Name             :  XX_CRM_HRCRM_UPDATE_BED_PKG                                    |
  -- | Description      :  This custom package is needed to update the attribute14 to null|
  -- |                     that was populated by the HRCRM program                        |
  -- |                                                                                    |
  -- | Change Record:                                                                     |
  -- |===============                                                                     |
  -- |Version   Date        Author           Remarks                                      |
  -- |=======   ==========  =============    =============================================|
  -- |Draft 1a  10-Jun-08   Gowri Nagarajan  Initial draft version                        |
  -- +====================================================================================+
IS
  
   -- +===================================================================+
   -- | Name  : MAIN                                                      |
   -- |                                                                   |
   -- | Description:       This is the public procedure.The concurrent    |
   -- |                    program OD:CRM HRCRM Update BED Program        |   
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE MAIN
                 (x_errbuf       OUT VARCHAR2
                 ,x_retcode      OUT NUMBER
                 ,p_person_id    IN  NUMBER                 
                 );
   

END XX_CRM_HRCRM_UPDATE_BED_PKG;
/

SHOW ERRORS

EXIT
	