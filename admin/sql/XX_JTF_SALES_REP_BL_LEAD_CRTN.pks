SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_SALES_REP_BL_LEAD_CRTN package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_SALES_REP_BL_LEAD_CRTN
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_SALES_REP_BL_LEAD_CRTN                                 |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Lead Named Account Mass Assignment Master     | 
-- |                     Program' and 'OD: TM Lead Named Account Mass Assignment Child |
-- |                     Program' Lead ID From and Lead ID To as the Input parameter.  |
-- |                     This public procedure will create a lead record in the custom |
-- |                     assignments table                                             |
-- |                                                                                   |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Master_Main             This is a public procedure.                   |
-- |PROCEDURE    Child_Main              This is a public procedure.                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  12-Oct-07   Abhradip Ghosh               Initial draft version           |
-- |Draft 1b  12-Nov-07   Abhradip Ghosh               Incorporated the standards for  |
-- |                                                   EBS error logging               |
-- |Draft 1c  25-Feb-08   Abhradip Ghosh               Changed the program to          |
-- |                                                   multi-threading                 |
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
G_CHLD_PROG_EXECUTABLE          CONSTANT VARCHAR2(30)  := 'XXJTFBLSLREPLEADCRTNCHILD';
G_BATCH_SIZE                    CONSTANT NUMBER        := 50000;
G_LEVEL_ID                      CONSTANT NUMBER        := 10001;
G_LEVEL_VALUE                   CONSTANT NUMBER        := 0;
G_SLEEP                         CONSTANT PLS_INTEGER   := 60;

----------------------------
--Declaring Global Variables
----------------------------
gn_program_id      PLS_INTEGER  := FND_GLOBAL.CONC_REQUEST_ID;
gn_index_req_id    PLS_INTEGER  := 0;

-----------------------------------
--Declaring Global Record Variables
-----------------------------------
TYPE req_id_lead_id_rec_type IS RECORD
           (
            REQUEST_ID         NUMBER
            , FROM_LEAD_ID     NUMBER
            , TO_LEAD_ID       NUMBER
           );

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------
TYPE req_id_lead_id_tbl_type IS TABLE OF req_id_lead_id_rec_type INDEX BY BINARY_INTEGER;
gt_req_id_lead_id req_id_lead_id_tbl_type;

-- +===================================================================+
-- | Name  : master_main                                                |
-- |                                                                    |
-- | Description:       This is the public procedure which will get     |
-- |                    called from the concurrent program 'OD: TM Lead |
-- |                    Named Account Mass Assignment Master            |
-- |                    Program' with Lead ID From and Lead ID To       |
-- |                    as the Input parameters to launch a             |
-- |                    number of child processes for parallel          |
-- |                    execution depending upon the batch size         |
-- |                                                                    |
-- +====================================================================+

PROCEDURE master_main
            (
               x_errbuf       OUT NOCOPY VARCHAR2
             , x_retcode      OUT NOCOPY NUMBER
             , p_from_lead_id IN         NUMBER
             , p_to_lead_id   IN         NUMBER
            );
            
-- +===================================================================+
-- | Name  : child_main                                                |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: TM Lead|
-- |                    Named Account Mass Assignment Child            |
-- |                    Program' with Lead ID From and Lead ID To      |
-- |                    as the Input parameters to  create a           |
-- |                    lead record in the custom assignments          |
-- |                    table                                          |
-- |                                                                   |
-- +===================================================================+

PROCEDURE child_main
                (
                 x_errbuf               OUT NOCOPY VARCHAR2
                 , x_retcode            OUT NOCOPY NUMBER
                 , p_from_lead_id       IN  NUMBER
                 , p_to_lead_id         IN  NUMBER
                );

END XX_JTF_SALES_REP_BL_LEAD_CRTN;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
