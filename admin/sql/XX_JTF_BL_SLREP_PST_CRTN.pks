SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_BL_SLREP_PST_CRTN package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_BL_SLREP_PST_CRTN
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_BL_SLREP_PST_CRTN                                      |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: Party Site Named Account Mass Assignment Master  |
-- |                     Program' with Party Site ID From and Party Site ID To as the  |
-- |                     Input parameters. This public procedure will launch a number  |
-- |                     of child processes for parallel execution depending upon the  |
-- |                     batch size                                                    |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Create_Batch             This is the public procedure                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  04-Feb-08   Abhradip Ghosh               Initial draft version           |
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
G_LIMIT                         CONSTANT  PLS_INTEGER  := NVL(fnd_profile.value ('XX_CDH_BULK_FETCH_LIMIT'),200);
G_COMMIT                        CONSTANT  PLS_INTEGER  := 100;
G_CHLD_PROG_APPLICATION         CONSTANT VARCHAR2(30)  := 'XXCRM';
G_CHLD_PROG_EXECUTABLE          CONSTANT VARCHAR2(30)  := 'XXJTFBLSLREPPSTCRTNCHILD'; -- Name of the child program
G_BATCH_SIZE                    CONSTANT NUMBER        := 50000;
G_LEVEL_ID                      CONSTANT NUMBER        := 10001;
G_LEVEL_VALUE                   CONSTANT NUMBER        := 0;
G_SLEEP                         CONSTANT PLS_INTEGER   := 60;

----------------------------
--Declaring Global Variables
----------------------------
gn_program_id      PLS_INTEGER  := FND_GLOBAL.CONC_REQUEST_ID;
gn_index_req_id    PLS_INTEGER := 0;

-----------------------------------
--Declaring Global Record Variables
-----------------------------------
TYPE req_id_pty_site_id_rec_type IS RECORD
           (
              REQUEST_ID            NUMBER
              , FROM_PARTY_SITE_ID  NUMBER
              , TO_PARTY_SITE_ID    NUMBER
              , RECORD_COUNT        NUMBER
           );

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------
TYPE req_id_pty_site_id_tbl_type IS TABLE OF req_id_pty_site_id_rec_type INDEX BY BINARY_INTEGER;
gt_req_id_pty_site_id req_id_pty_site_id_tbl_type;


-- +===================================================================+
-- | Name  : master_main                                               |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: Party  |
-- |                    Site Named Account Mass Assignment Master      |
-- |                    Program' with Party Site ID From and Party Site|
-- |                    ID To as the Input parameters to launch a      |
-- |                    number of child processes for parallel         |
-- |                    execution depending upon the batch size        |
-- |                                                                   |
-- +===================================================================+

PROCEDURE master_main
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_from_party_site_id IN  NUMBER
             , p_to_party_site_id   IN  NUMBER
             , p_country            IN  VARCHAR2 DEFAULT 'US'            
            );


END XX_JTF_BL_SLREP_PST_CRTN;
/
SHOW ERRORS;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
