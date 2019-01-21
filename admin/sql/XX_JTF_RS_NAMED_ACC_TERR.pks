SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_RS_NAMED_ACC_TERR package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_RS_NAMED_ACC_TERR 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_RS_NAMED_ACC_TERR                                      |
-- |                                                                                   |
-- | Description      :  This custom package will be used to insert record in the three|
-- |                     custom assignment tables XX_TM_NAM_TERR_DEFN,                 |
-- |                     XX_TM_NAM_TERR_RSC_DTLS and  XX_TM_NAM_TERR_ENTITY_DTLS.      |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                  Description                                     |
-- |=========    ===========           ================================================|
-- |PROCEDURE    Insert_Row            This is the public procedure.                   |
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
G_APPLICATION_NAME              CONSTANT  VARCHAR2(10) := 'XXCRM';
G_PROGRAM_TYPE                  CONSTANT  VARCHAR2(50) := 'E1309_Autonamed_Account_Creation';
G_MODULE_NAME                   CONSTANT  VARCHAR2(80) := 'TM';
G_MEDIUM_ERROR_MSG_SEVERTY      CONSTANT  VARCHAR2(30) := 'MEDIUM';
G_MAJOR_ERROR_MESSAGE_SEVERITY  CONSTANT  VARCHAR2(30) := 'MAJOR';
G_ERROR_STATUS_FLAG             CONSTANT  VARCHAR2(10) := 'ACTIVE';

----------------------------
--Declaring Global Variables
----------------------------
gn_program_id  PLS_INTEGER := FND_GLOBAL.CONC_REQUEST_ID;

-----------------------------------
--Declaring Global Record Variables 
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

-- +===================================================================+
-- | Name  : Insert_Row                                                |
-- |                                                                   |
-- | Description:       This is the public procedure will be used to   |
-- |                    insert record in the three custom assignment   |
-- |                    tables XX_TM_NAM_TERR_DEFN,                    |
-- |                    XX_TM_NAM_TERR_RSC_DTLS and                    |
-- |                    XX_TM_NAM_TERR_ENTITY_DTLS                     |
-- |                                                                   |
-- +===================================================================+  

PROCEDURE insert_row
            (
             p_api_version            IN NUMBER
             , p_start_date_active    IN DATE     DEFAULT SYSDATE
             , p_end_date_active      IN DATE     DEFAULT NULL
             , p_named_acct_terr_id   IN NUMBER   DEFAULT NULL
             , p_named_acct_terr_name IN VARCHAR2 DEFAULT NULL
             , p_named_acct_terr_desc IN VARCHAR2 DEFAULT NULL
             , p_full_access_flag     IN VARCHAR2 DEFAULT NULL
             , p_source_terr_id       IN NUMBER   DEFAULT NULL
             , p_resource_id          IN NUMBER   DEFAULT NULL
             , p_role_id              IN NUMBER   DEFAULT NULL
             , p_group_id             IN NUMBER   DEFAULT NULL
             , p_entity_type          IN VARCHAR2 DEFAULT NULL
             , p_entity_id            IN NUMBER   DEFAULT NULL
             , x_return_status        OUT NOCOPY  VARCHAR2
             , x_msg_count            OUT NOCOPY  NUMBER
             , x_message_data         OUT NOCOPY  VARCHAR2
            );
            
-- +===================================================================+
-- | Name  : Update_Row                                                |
-- |                                                                   |
-- | Description:       This is the public procedure will be used to   |
-- |                    update record in the custom assignment table   |
-- |                    XX_TM_NAM_TERR_ENTITY_DTLS                     |
-- |                                                                   |
-- +===================================================================+ 

PROCEDURE update_row
            (
             p_api_version            IN NUMBER
             , p_start_date_active    IN DATE     DEFAULT SYSDATE
             , p_end_date_active      IN DATE     DEFAULT NULL
             , p_named_acct_terr_id   IN NUMBER   
             , p_entity_type          IN VARCHAR2 
             , p_entity_id            IN NUMBER   DEFAULT NULL
             , x_return_status        OUT NOCOPY  VARCHAR2
             , x_msg_count            OUT NOCOPY  NUMBER
             , x_message_data         OUT NOCOPY  VARCHAR2
            );

END XX_JTF_RS_NAMED_ACC_TERR;     
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
