SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_BE_SLS_REP_PTY_ST_CRTN package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_BE_SLS_REP_PTY_ST_CRTN
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_BE_SLS_REP_PTY_ST_CRTN                                 |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the                  |
-- |                     business event oracle.apps.ar.hz.PartySite.create.            |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |FUNCTION     Create_Be_Party_Site    This is the function                          |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  20-Nov-07   Abhradip Ghosh               Initial draft version           |
-- +===================================================================================+
AS
----------------------------
--Declaring Global Constants
----------------------------
G_APPLICATION_NAME              CONSTANT  VARCHAR2(10) := 'XXCRM';
G_PROGRAM_TYPE                  CONSTANT  VARCHAR2(50) := 'E1309_Autonamed_Account_Creation';
G_MODULE_NAME                   CONSTANT  VARCHAR2(80) := 'TM';
G_MAJOR_ERROR_MESSAGE_SEVERITY  CONSTANT  VARCHAR2(30) := 'MAJOR';
G_ERROR_STATUS_FLAG             CONSTANT  VARCHAR2(10) := 'ACTIVE';

----------------------------
--Declaring Global Variables
----------------------------

-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

-- +===================================================================+
-- | Name  : create_be_party_site                                      |
-- |                                                                   |
-- | Description:  This is the function which gets called from the     |
-- |               business event oracle.apps.ar.hz.PartySite.create   |
-- |                                                                   |
-- +===================================================================+

FUNCTION create_be_party_site(
                              p_subscription_guid IN            RAW
                              , p_event           IN OUT NOCOPY WF_EVENT_T
                             )
RETURN VARCHAR2;

END XX_JTF_BE_SLS_REP_PTY_ST_CRTN;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
