SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_BL_SLREP_GDW_PST_CRTN package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_BL_SLREP_GDW_PST_CRTN
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_BL_SLREP_GDW_PST_CRTN                                  |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM GDW Party Site Named Account Mass Assignment  |
-- |                     Master Program'. This public procedure will launch a number   |
-- |                     of child processes for each of the batch_id's present in      |
-- |                     hz_imp_batch_summary table.                                   |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    master_main             This is the public procedure                  |
-- |PROCEDURE    child_main              This is the public procedure                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  09-Apr-08   Abhradip Ghosh               Initial draft version           |
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
G_CHLD_PROG_APPLICATION         CONSTANT  VARCHAR2(30)  := 'XXCRM';
G_CHLD_PROG_EXECUTABLE          CONSTANT  VARCHAR2(30)  := 'XXJTFBLSLREPGDWPSTCRTNCHILD'; 
G_BATCH_SIZE                    CONSTANT  NUMBER        := 50000;
G_LEVEL_ID                      CONSTANT  NUMBER        := 10001;
G_LEVEL_VALUE                   CONSTANT  NUMBER        := 0;
G_SLEEP                         CONSTANT  PLS_INTEGER   := 60;

----------------------------
--Declaring Global Variables
----------------------------
gn_program_id      PLS_INTEGER  := FND_GLOBAL.CONC_REQUEST_ID;
gn_index_req_id    PLS_INTEGER := 0;
gn_index           PLS_INTEGER := 0;

-----------------------------------
--Declaring Global Record Variables
-----------------------------------
TYPE req_id_batch_id_rec_type IS RECORD
           (
              REQUEST_ID        NUMBER
              , BATCH_ID        NUMBER
              , FROM_RECORD_ID  NUMBER
              , TO_RECORD_ID    NUMBER
           );
           
TYPE rsc_role_grp_terr_id_rec_type IS RECORD
       (
        rsc_role_group_id    VARCHAR2(2000)
        , named_acct_terr_id NUMBER
       );

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------
TYPE req_id_batch_id_tbl_type IS TABLE OF req_id_batch_id_rec_type INDEX BY BINARY_INTEGER;
gt_req_id_batch_id req_id_batch_id_tbl_type; 

TYPE rsc_role_grp_terr_id_tbl_type IS TABLE OF rsc_role_grp_terr_id_rec_type INDEX BY BINARY_INTEGER;
gt_rsc_role_grp_terr_id rsc_role_grp_terr_id_tbl_type;

-- +===================================================================+
-- | Name  : master_main                                               |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: TM GDW |
-- |                    Party Site Named Account Mass Assignment       |
-- |                    Master Program' to launch a                    |
-- |                    number of child processes for parallel         |
-- |                    execution for each of the batch_id's present in|
-- |                    hz_imp_batch_summary table.                    |
-- |                                                                   |
-- +===================================================================+

PROCEDURE master_main
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
            );

-- +===================================================================+
-- | Name  : child_main                                                |
-- |                                                                   |
-- | Description: This is the public procedure which will get          |
-- |              called from the concurrent program 'OD: TM GDW Party |
-- |              Site Named Account Mass Assignment Child Program'    |
-- |              with Batch ID as the Input parameters to  create a   |
-- |              party site record in the custom assignments table    |
-- |                                                                   |
-- +===================================================================+

PROCEDURE child_main
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_min_record_id      IN  NUMBER
             , p_max_record_id      IN  NUMBER
             , p_batch_id           IN  NUMBER
            );

END XX_JTF_BL_SLREP_GDW_PST_CRTN;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
