SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_BULK_SALES_REP_PST_CRTN package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_BULK_SALES_REP_PST_CRTN
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_BULK_SALES_REP_PST_CRTN                                |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: Party Site Named Account Mass Assignment' with   |
-- |                     Party Site ID From and Party Site ID To as the Input          |  
-- |                     parameters. This public procedure will create a party site    |
-- |                     record in the custom assignments table                        |                     |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Create_Bulk_Party_Site  This is the public procedure.                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  09-Oct-07   Abhradip Ghosh               Initial draft version           |
-- |Draft 1b  12-Nov-07   Abhradip Ghosh               Incorporated the standards for  |
-- |                                                   EBS error logging               |
-- +===================================================================================+

AS

----------------------------
--Declaring Global Constants
----------------------------
G_APPLICATION_NAME              CONSTANT  VARCHAR2(10) := 'XXCRM';
G_PROGRAM_TYPE                  CONSTANT  VARCHAR2(50) := 'E1309_Autonamed_Account_Creation';
G_MODULE_NAME                   CONSTANT  VARCHAR2(80) := 'TM';
G_MEDIUM_ERROR_MSG_SEVERTY      CONSTANT  VARCHAR2(30) := 'MEDIUM';
G_MAJOR_ERROR_MESSAGE_SEVERITY  CONSTANT  VARCHAR2(30) := 'MAJOR';
G_ERROR_STATUS_FLAG             CONSTANT  VARCHAR2(10) := 'ACTIVE';
G_LIMIT                         CONSTANT  PLS_INTEGER  := 10000;
G_COMMIT                        CONSTANT  PLS_INTEGER  := 1000;
----------------------------
--Declaring Global Variables
----------------------------
gn_program_id   PLS_INTEGER  := FND_GLOBAL.CONC_REQUEST_ID;

-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

-- +===================================================================+
-- | Name  : create_bulk_party_site                                    |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: Party  | 
-- |                    Site Named Account Mass Assignment' with       |
-- |                    Party Site ID From and Party Site ID To as the |
-- |                    Input parameters to  create a party site       |
-- |                    record in the custom assignments table         |
-- |                                                                   |
-- +===================================================================+

PROCEDURE create_bulk_party_site
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_from_party_site_id IN  NUMBER
             , p_to_party_site_id   IN  NUMBER
            );

END XX_JTF_BULK_SALES_REP_PST_CRTN;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
