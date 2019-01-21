
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_ESP_SCHEDULE_JOBS_PKG
AS
       
       
        -- +===================================================================+
        -- |                  Office Depot - Project Simplify                  |
        -- |                       Oracle                                      |
        -- +===================================================================+
        -- | Name       :  XX_ESP_SCHEDULE_JOBS_PKG                            |
        -- |                                                                   |
        -- | Description:To print report for all the scheduled ESP jobs run for|
        -- |             the current date                		                   |
        -- |                                                                   |
        -- |Change Record:                                                     |
        -- |===============                                                    |
        -- |Version   Date        Author           Remarks                     |
        -- |=======   ==========  =============    ============================|
        -- |DRAFT 1.A 23-Jun-2008  Piyush           Initial draft version      |
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
                        ,p_user_name           Varchar2
                       ) ;
	

END XX_ESP_SCHEDULE_JOBS_PKG;


/
SHOW ERRORS;
