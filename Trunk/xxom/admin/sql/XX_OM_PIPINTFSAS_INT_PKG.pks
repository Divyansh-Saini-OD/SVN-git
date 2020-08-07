SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_pipintfsas_int_pkg AUTHID CURRENT_USER

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_PIPINTFSAS_INT_PKG                                    |
-- | Rice ID     : I1267_PIPInterfacetoSAS                                     |
-- | Description : Custom Package to contain the Concurrent Program procedure  |
-- |               that is to be scheduled every month to purge the data from  |
-- |               the custom table XX_OM_PIP_LISTS once the campaign expires  |
-- |               determined by Expiration Date column on the custom table    |
-- |               XX_OM_PIP_CAMPAIGN_RULES_ALL                                |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 03-Apr-2007  Vidhya Valantina T     Initial draft version         |
-- |1.0      05-Apr-2007  Vidhya Valantina T     Baselined after testing       |
-- |1.1      11-May-2007  Vidhya Valantina T     Changes as per updated MD050. |
-- |                                             Added two parameters to the   |
-- |                                             concurrent program for purging|
-- |1.2      13-Jun-2007  Vidhya Valantina T     Changed made as per the new   |
-- |                                             Naming Conventions and coding |
-- |                                             standards. Also incorporated  |
-- |                                             code review comments          |
-- |1.3      21-Jun-2007  Vidhya Valantina T     Changes made as per the new   |
-- |                                             code review comments          |
-- |                                                                           |
-- +===========================================================================+

AS                                      -- Package Block

-- ----------------------------------
-- Global Variable Declarations
-- ----------------------------------

    ge_exception xx_om_report_exception_t := xx_om_report_exception_t(
                                                                      'OTHERS'
                                                                     ,'OTC'
                                                                     ,'Pick Release'
                                                                     ,'PIP Interface to SAS'
                                                                     ,null
                                                                     ,null
                                                                     ,'CAMPAIGN_ID'
                                                                     ,null
                                                                    );

-- -----------------------------------
-- Function and Procedure Declarations
-- -----------------------------------

    -- +===================================================================+
    -- | Name  : Write_Exception                                           |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :       Error_Code                                     |
    -- |                    Error_Description                              |
    -- |                    Entity_Reference                               |
    -- |                    Entity_Reference_Id                            |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Write_Exception (
                                p_error_code        IN  VARCHAR2
                               ,p_error_description IN  VARCHAR2
                              );

    -- +===================================================================+
    -- | Name  : Purge_Expired_Campaigns                                   |
    -- | Description : This procedure is to purge the records from custom  |
    -- |               table XX_OM_PIP_LISTS based on the expiration date  |
    -- |               of the campaigns defined in the custom table,       |
    -- |               XX_OM_PIP_CAMPAIGN_RULES_ALL. This procedure is to  |
    -- |               be scheduled to run as a Concurrent Program once    |
    -- |               every month.                                        |
    -- |                                                                   |
    -- | Parameters :       Campaign_Code                                  |
    -- |                    Delete_Active_Campaigns                        |
    -- |                                                                   |
    -- | Returns    :       Errbuf                                         |
    -- |                    Retcode                                        |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Purge_Expired_Campaigns (
                                        x_errbuf                    OUT NOCOPY VARCHAR2
                                       ,x_retcode                   OUT NOCOPY NUMBER
                                       ,p_campaign_code             IN  VARCHAR2 DEFAULT 'ALL'
                                       ,p_dummy_parameter           IN  VARCHAR2
                                       ,p_delete_active_campaigns   IN  VARCHAR2 DEFAULT 'N'
                                      );

END xx_om_pipintfsas_int_pkg;           -- End Package Block
/

SHOW ERRORS;
