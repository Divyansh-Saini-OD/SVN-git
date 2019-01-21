
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CRM_ESP_PKG
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
AS
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
                        ,p_profile_option      VARCHAR2
                       ) IS

     
                       
                       
    ln_profile       Varchar2(4) := FND_PROFILE.VALUE(p_profile_option); 
    
    
   Begin
    
    IF ln_profile = 'Yes'
    THEN x_retcode := 2;
    END IF;
                      

END Main_Proc;


END XX_CRM_ESP_PKG;

/
SHOW ERRORS;
