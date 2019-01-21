SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT 'Creating XX_CRM_HRCRM_CLEANSE_PKG package body'
PROMPT

CREATE OR REPLACE PACKAGE XX_CRM_HRCRM_CLEANSE_PKG
  -- +====================================================================================+
  -- |                  Office Depot - Project Simplify                                   |
  -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                        |
  -- +====================================================================================+
  -- |                                                                                    |
  -- | Name             :  XX_CRM_HRCRM_CLEANSE_PKG                                       |
  -- | Description      :  This custom package is needed to delete the Oracle CRM         |
  -- |                     resource roles,group membership,group member roles,group roles |
  -- |                     and parent child relations                                     |
  -- |                                                                                    |
  -- |                                                                                    |
  -- | Change Record:                                                                     |
  -- |===============                                                                     |
  -- |Version   Date        Author           Remarks                                      |
  -- |=======   ==========  =============    =============================================|
  -- |Draft 1a  26-May-08   Gowri Nagarajan  Initial draft version                        |
  -- +====================================================================================+
IS
  
   -- +===================================================================+
   -- | Name  : MAIN                                                      |
   -- |                                                                   |
   -- | Description:       This is the public procedure.The concurrent    |
   -- |                    program OD: CRM HRCRM Cleanse Program          |
   -- |                    will call this public procedure which inturn   |
   -- |                    will call the respective APIS                  |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE MAIN
                 (x_errbuf       OUT VARCHAR2
                 ,x_retcode      OUT NUMBER
                 ,p_person_id    IN  NUMBER                 
                 );
   

END XX_CRM_HRCRM_CLEANSE_PKG;
/

SHOW ERRORS

EXIT
	