
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CRM_ESP_PKG
AS
       
       
        -- +===================================================================+
        -- |                  Office Depot - Project Simplify                  |
        -- |                       WIPRO Technologies                          |
        -- +===================================================================+
        -- | Name       :  XX_CRM_ESP_PKG                                      |
        -- |                                                                   |
        -- | Description:  To do a logical grouping in ESP in order to stop    |
        -- |               predeccesor jobs to run.                            |
        -- |                                                                   |
        -- |Change Record:                                                     |
        -- |===============                                                    |
        -- |Version   Date        Author           Remarks                     |
        -- |=======   ==========  =============    ============================|
        -- |DRAFT 1.A 13-Jun-2008  Piyush           Initial draft version      |
        -- +===================================================================+

        -- +===================================================================+
        -- | Name             : Main_Proc                                      |
        -- | Description      : This procedure will error out the predecessor  |
        -- |                    jobs in ESP based on the profile option value. |
        -- |                                                                   |
        -- |                                                                   |
        -- | parameters :      x_errbuf                                        |
        -- |                   x_retcode                                       |
        -- |                   p_profile_option                                |
        -- +===================================================================+

PROCEDURE Main_Proc    ( x_errbuf              OUT NOCOPY VARCHAR2
                        ,x_retcode             OUT NOCOPY NUMBER
                        ,p_profile_option      Varchar2
                       ) ;
	

END XX_CRM_ESP_PKG;

/
SHOW ERRORS;