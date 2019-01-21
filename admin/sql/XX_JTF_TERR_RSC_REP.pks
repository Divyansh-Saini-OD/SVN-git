SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_TERR_RSC_REP package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_TERR_RSC_REP
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_TERR_RSC_REP                                   |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM  Territories Resources Report' with   |
-- |                     Territory Name as the mandatory Input parameter.              |
-- |                     This public procedure will display the lowest-level child     |
-- |                     records in which the following conditions are met             |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Terr_without_rsc        This is the public procedure                  |
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

-- +===================================================================+
-- | Name  : terr_without_rsc                                          |
-- |                                                                   |
-- | Description:  This is the public procedure which will get called  |
-- |               from the concurrent program 'OD: TM Territories     |
-- |               without Resources Report' with Territory Name as the|
-- |               mandatory Input parameter.                          |
-- |               This public procedure will display the lowest-level |
-- |               child records in which the following conditions are |
-- |               met                                                 |
-- |               1. No resource is assigned to territory             |
-- |               2. End Dated resource on the territory (and no other|
-- |                  active resource is assigned to that territory)   |
-- |               3.There is a mismatch of the group and role for a   |
-- |                 resource between the rule-based territory and that|
-- |                 of in the Resource Manager.                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE terr_rsc
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_terr_id            IN  NUMBER
            );

END XX_JTF_TERR_RSC_REP;
/
SHOW ERRORS;
--EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
