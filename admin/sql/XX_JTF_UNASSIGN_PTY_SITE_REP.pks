SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_UNASSIGN_PTY_SITE_REP package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_UNASSIGN_PTY_SITE_REP
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_UNASSIGN_PTY_SITE_REP                                  |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Un-Assigned Party Sites Report' with          |
-- |                     Resource Name as the Input parameters.                        |
-- |                     This public procedure will display the party-sites that       |
-- |                     are assigned to the resource in the custom assignments table. |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Assign_pty_site         This is the public procedure                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  04-Mar-08   Abhradip Ghosh               Initial draft version           |
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

----------------------------
--Declaring Global Variables
----------------------------
gn_program_id    NUMBER;

-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

-- +==========================================================================+
-- | Name  : assign_pty_site                                                  |
-- |                                                                          |
-- | Description  :  This custom package will get called from the concurrent  |
-- |                 program 'OD: TM Un-Assigned Party Sites Report' with     |
-- |                 Resource Name as the Input parameters. This public       |
-- |                 procedure will display the party-sites that are          |
-- |                 assigned to the resource in the custom assignments table.|
-- +==========================================================================+

PROCEDURE assign_pty_site
            (
             x_errbuf            OUT NOCOPY VARCHAR2
             , x_retcode         OUT NOCOPY NUMBER
             , p_rsd_group_id IN NUMBER
             , p_mgr_resource_id IN  NUMBER
            );

END XX_JTF_UNASSIGN_PTY_SITE_REP;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
