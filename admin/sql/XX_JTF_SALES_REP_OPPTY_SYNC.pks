SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_SALES_REP_OPPTY_SYNC package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_SALES_REP_OPPTY_SYNC 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_SALES_REP_OPPTY_SYNC                                   |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: Synchronize Opportunity Named Account' to update |
-- |                     the opportunities in the custom assignments entity table      |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Update_Oppty            This is the public procedure.                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  16-Oct-07   Abhradip Ghosh               Initial draft version           |
-- |Draft 1b  08-Nov-07   Abhradip Ghosh               Modified code according to the  |
-- |                                                   new logic of comparing          |
-- |                                                   named_acct_terr_ids             |
-- |Draft 1c  12-Nov-07   Abhradip Ghosh               Incorporated the standards for  |
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
-- | Name  : update_oppty                                              |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD:        |
-- |                    Synchronize Opportunity Named Account' to      |
-- |                    update the opportunities in the custom         |
-- |                    assignments entity table                       |
-- |                                                                   |
-- +===================================================================+  

PROCEDURE update_oppty
            (
             x_errbuf      OUT NOCOPY VARCHAR2
             , x_retcode   OUT NOCOPY NUMBER
            );
            
END XX_JTF_SALES_REP_OPPTY_SYNC;     
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
