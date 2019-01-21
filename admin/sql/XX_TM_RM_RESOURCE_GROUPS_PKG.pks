SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_TM_RM_RESOURCE_GROUPS_PKG package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_TM_RM_RESOURCE_GROUPS_PKG
 -- +===================================================================================== +
 -- |                  Office Depot - Project Simplify                                     |
 -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
 -- +===================================================================================== +
 -- |                                                                                      |
 -- | Name             : XX_TM_RM_RESOURCE_GROUPS_PKG                                     |
 -- | Description      : This custom package extracts the resource details                 |
 -- |                    from resource manager and prints to a log output file             |
 -- |                                                                                      |
 -- | This package contains the following sub programs:                                    |
 -- | =================================================                                    |
 -- |Type         Name                  Description                                        |
 -- |=========    ===========           ================================================   |
 -- |PROCEDURE    MAIN_PROC             This procedure will be used to extract and display |
 -- |                                   the  resource details                              |
 -- |                                           .                                          |
 -- |Change Record:                                                                        |
 -- |===============                                                                       |
 -- |Version   Date         Author           Remarks                                       |
 -- |=======   ==========   =============    ============================================= |
 -- |Draft 1a  21-Apr-2008  Gowri Nagarajan  Initial draft version                         |
 -- +===================================================================================== +
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

    -- +===================================================================== +
    -- | Name       : MAIN_PROC                                               |
    -- |                                                                      |
    -- | Description: This procedure will be used to extract the resource     |
    -- |              information                                             |
    -- |                                                                      |
    -- | Parameters : p_resource_id   IN  GROUP_ID                            |
    -- |              x_retcode  OUT Holds '0','1','2'                        |
    -- |              x_errbuf   OUT Holds the error message                  |
    -- +======================================================================+

PROCEDURE MAIN_PROC
            (
             x_errbuf            OUT NOCOPY VARCHAR2
             , x_retcode         OUT NOCOPY NUMBER
             ,p_sales_group_id in number
            );

END XX_TM_RM_RESOURCE_GROUPS_PKG;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
