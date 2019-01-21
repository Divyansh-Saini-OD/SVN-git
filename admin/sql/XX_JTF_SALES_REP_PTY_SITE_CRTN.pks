SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_SALES_REP_PTY_SITE_CRTN package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_SALES_REP_PTY_SITE_CRTN 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_SALES_REP_PTY_SITE_CRTN                                |
-- |                                                                                   |
-- | Description      :  This custom package will get triggered when a sales-rep       |
-- |                     creates a party_site                                          |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                  Description                                     |
-- |=========    ===========           ================================================|
-- |PROCEDURE    Create_Party_Site     This is the public procedure.                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  25-Sep-07   Abhradip Ghosh               Initial draft version           |
-- |Draft 1b  12-Nov-07   Abhradip Ghosh               Incorporated the standards for  |
-- |                                                   EBS error logging               |
-- +===================================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------
G_APPLICATION_NAME               CONSTANT  VARCHAR2(10) := 'XXCRM';
G_PROGRAM_TYPE                   CONSTANT  VARCHAR2(50) := 'E1309_Autonamed_Account_Creation';
G_MODULE_NAME                    CONSTANT  VARCHAR2(80) := 'TM';
G_MEDIUM_ERROR_MSG_SEVERTY       CONSTANT  VARCHAR2(30) := 'MEDIUM';
G_MAJOR_ERROR_MESSAGE_SEVERITY   CONSTANT  VARCHAR2(30) := 'MAJOR';
G_ERROR_STATUS_FLAG              CONSTANT  VARCHAR2(10) := 'ACTIVE';

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
-- | Name  : Create_Party_Site                                         |
-- |                                                                   |
-- | Description:       This is the public procedure to create a party |
-- |                    site record in the custom assignments table    |
-- |                    when a sales-rep creates a party_site          |
-- |                                                                   |
-- +===================================================================+  

PROCEDURE create_party_site
            (
              p_party_site_id        IN NUMBER
            );
            
END XX_JTF_SALES_REP_PTY_SITE_CRTN; 
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
