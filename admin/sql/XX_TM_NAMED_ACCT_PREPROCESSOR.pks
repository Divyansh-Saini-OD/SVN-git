SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK


CREATE OR REPLACE PACKAGE XX_TM_NAMED_ACCT_PREPROCESSOR
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_TM_NAMED_ACCT_PREPROCESSOR                                 |
-- |                                                                                   |
-- | Description      :  This custom package will display the future assignments of the|
-- |                     unassigned Party Site.                                        |
-- |                     This program will be multithreaded.                           |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  11-Jun-2008 Nabarun Ghosh                Initial draft version           |
-- +===================================================================================+
AS
----------------------------
--Declaring Global Constants
----------------------------
G_APPLICATION_NAME              CONSTANT  VARCHAR2(10) := 'XXCRM';
G_PROGRAM_TYPE                  CONSTANT  VARCHAR2(50) := 'E1309D_Autonamed_Account_Creation';
G_MODULE_NAME                   CONSTANT  VARCHAR2(80) := 'TM';
G_MEDIUM_ERROR_MSG_SEVERTY      CONSTANT  VARCHAR2(30) := 'MEDIUM';
G_MAJOR_ERROR_MESSAGE_SEVERITY  CONSTANT  VARCHAR2(30) := 'MAJOR';
G_ERROR_STATUS_FLAG             CONSTANT  VARCHAR2(10) := 'ACTIVE';
--G_LIMIT                         CONSTANT  PLS_INTEGER  := NVL(fnd_profile.value ('XX_CDH_BULK_FETCH_LIMIT'),200);
G_LIMIT                         CONSTANT  PLS_INTEGER  := 100;
G_COMMIT                        CONSTANT  PLS_INTEGER  := 100;
G_CHLD_PROG_APPLICATION         CONSTANT VARCHAR2(30)  := 'XXCRM';
G_CHLD_PROG_EXECUTABLE          CONSTANT VARCHAR2(30)  := 'XXTMNAMEDACTPREPROCCHILD'; -- Name of the child program
G_BATCH_SIZE                    CONSTANT NUMBER        := 50000;
G_LEVEL_ID                      CONSTANT NUMBER        := 10001;
G_LEVEL_VALUE                   CONSTANT NUMBER        := 0;
G_SLEEP                         CONSTANT PLS_INTEGER   := 60;

----------------------------
--Declaring Global Variables
----------------------------
gn_program_id      PLS_INTEGER  := FND_GLOBAL.CONC_REQUEST_ID;
gn_index_req_id    PLS_INTEGER := 0;

TYPE grec_insert_preprocessor IS TABLE OF xxcrm.xx_tm_nmdactasgn_preprocessor%ROWTYPE INDEX BY PLS_INTEGER;
gt_insert_preprocessor        grec_insert_preprocessor;
gt_insert_index_rec_init      grec_insert_preprocessor;


TYPE grec_insert_index IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
gt_insert_index_rec         grec_insert_index;


-----------------------------------
--Declaring Global Record Variables
-----------------------------------
TYPE req_id_pty_site_id_rec_type IS RECORD
           (
                request_id          NUMBER
              , from_party_site_id  NUMBER
              , to_party_site_id    NUMBER
              , record_count        NUMBER
           );

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------
TYPE req_id_pty_site_id_tbl_type IS TABLE OF req_id_pty_site_id_rec_type INDEX BY BINARY_INTEGER;
gt_req_id_pty_site_id req_id_pty_site_id_tbl_type;

----------------------------------------------------
--Declaring pipelined functions and the record types
----------------------------------------------------
 TYPE lrec_pipelined_sites_t IS RECORD 
                  (  
                    party_site_id         NUMBER(20)
                  );
 
 TYPE lt_pipelined_sites          IS TABLE OF XX_TM_NAMED_ACCT_PREPROCESSOR.lrec_pipelined_sites_t; 
 TYPE lt_pipelined_incoming_sites IS TABLE OF XX_TM_NAMED_ACCT_PREPROCESSOR.lrec_pipelined_sites_t;     
 l_tab_pipelined_incoming         lt_pipelined_incoming_sites; 
 l_tab_pipelined_outgoing         xx_tm_named_acct_preprocessor.lrec_pipelined_sites_t;

 TYPE lrec_pipelin_siteloc_t IS RECORD
           (
             party_site_id   NUMBER(20)
            ,attribute13     VARCHAR2(250)
            ,country         VARCHAR2(100)
           );

 TYPE lt_pipelin_siteloc          IS TABLE OF XX_TM_NAMED_ACCT_PREPROCESSOR.lrec_pipelin_siteloc_t;  
 TYPE lt_pipelin_incoming_siteloc IS TABLE OF XX_TM_NAMED_ACCT_PREPROCESSOR.lrec_pipelin_siteloc_t;      
 l_tab_pipelin_in_siteloc         lt_pipelin_incoming_siteloc;  
 l_tab_pipelin_out_siteloc        xx_tm_named_acct_preprocessor.lrec_pipelin_siteloc_t;

 TYPE lrec_pipelin_sitecustype_t IS RECORD
           (
             attribute18    VARCHAR2(600)
            ,party_site_id  NUMBER(20)
            ,customer_type  VARCHAR2(600)
           );

 TYPE lt_pipelin_sitecustype          IS TABLE OF XX_TM_NAMED_ACCT_PREPROCESSOR.lrec_pipelin_sitecustype_t;  
 TYPE lt_pipelin_in_sitecustype       IS TABLE OF XX_TM_NAMED_ACCT_PREPROCESSOR.lrec_pipelin_sitecustype_t;      
 l_tab_pipelin_in_sitecustype         lt_pipelin_in_sitecustype;  
 l_tab_pipelin_out_sitecustype        xx_tm_named_acct_preprocessor.lrec_pipelin_sitecustype_t;
 
 FUNCTION Pipelined_Party_Sites (
                                  lcu_party_sites_in IN SYS_REFCURSOR
                                ) RETURN xx_tm_named_acct_preprocessor.lt_pipelined_sites
                                  PIPELINED
                                  PARALLEL_ENABLE (PARTITION lcu_party_sites_in BY ANY) ;
                                  
 FUNCTION Pipelined_Site_Loc_Dtls (
                                    lcu_party_siteloc_in IN SYS_REFCURSOR
                                  ) RETURN xx_tm_named_acct_preprocessor.lt_pipelin_siteloc
                                    PIPELINED
                                    PARALLEL_ENABLE (PARTITION lcu_party_siteloc_in BY ANY) ;

 FUNCTION Pipelined_Site_Cust_Type_Dtls (
                                          lcu_party_sitecustype_in IN SYS_REFCURSOR
                                        ) RETURN xx_tm_named_acct_preprocessor.lt_pipelin_sitecustype
                                          PIPELINED
                                          PARALLEL_ENABLE (PARTITION lcu_party_sitecustype_in BY ANY) ;

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
             , p_gdw_validate_YN    IN  VARCHAR2
            );

-- +===================================================================+
-- | Name  : child_main                                                |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: Party  |
-- |                    Site Named Account Mass Assignment Child       |
-- |                    Program' with Party Site ID From and Party Site|
-- |                    ID To as the Input parameters to  create a     |
-- |                    party site record in the custom assignments    |
-- |                    table                                          |
-- |                                                                   |
-- +===================================================================+

PROCEDURE child_main
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_from_party_site_id IN  NUMBER
             , p_to_party_site_id   IN  NUMBER
             , p_upd_profile_value  IN  VARCHAR2
             , p_gdw_validate_YN    IN  VARCHAR2
            );


END XX_TM_NAMED_ACCT_PREPROCESSOR;
/
SHOW ERRORS;

