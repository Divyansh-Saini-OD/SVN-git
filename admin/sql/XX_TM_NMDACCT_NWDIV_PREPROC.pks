SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_TM_NMDACCT_NWDIV_PREPROC package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_TM_NMDACCT_NWDIV_PREPROC 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_TM_NMDACCT_NWDIV_PREPROC                                   |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM New Division Named Account Assignment         |
-- |                     Preprocessor Master Program' to create                        |
-- |                     a new division for the party sites                            |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Master_Main             This is the public procedure.                 |
-- |PROCEDURE    Child_Main              This is the public procedure.                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  11-Jun-08   Abhradip Ghosh               Initial draft version           |
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
G_CHLD_PROG_APPLICATION         CONSTANT VARCHAR2(30)  := 'XXCRM';
G_CHLD_PROG_EXECUTABLE          CONSTANT VARCHAR2(30)  := 'XXTMNMDACCTPREPROCCHILD'; -- Name of the child program
G_BATCH_SIZE                    CONSTANT NUMBER        := 50000;
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
-- |                    called from the concurrent program 'OD:        |
-- |                    New Division Named Account Assignment Master   |
-- |                    Program' to create a new division for          |
-- |                    the party sites                                |
-- |                                                                   |
-- +===================================================================+  
PROCEDURE master_main
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_division           IN  VARCHAR2
            );
            
-- +===================================================================+
-- | Name  : child_main                                                |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD:        |
-- |                    New Division Named Account Assignment Child    |
-- |                    Program' to create a new division for          |
-- |                    the party sites                                |
-- |                                                                   |
-- +===================================================================+  

PROCEDURE child_main
                    (
                     x_errbuf               OUT NOCOPY VARCHAR2
                     , x_retcode            OUT NOCOPY NUMBER
                     , p_division           IN  VARCHAR2
                     , p_party_site_id_from IN NUMBER
                     , p_party_site_id_to   IN NUMBER
                    );
            
END XX_TM_NMDACCT_NWDIV_PREPROC;     
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
