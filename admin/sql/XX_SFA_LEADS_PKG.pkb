
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_SFA_LEADS_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_SFA_LEADS_PKG.pkb                                                      |
-- | Description : Package Body to perform TCA Entity Validations and to invoke the seeded   |
-- |               Import Sales Leads program with the required parameters.                  |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   15-Jun-2007       Ashok Kumar T J     Initial draft version                   |
-- |DRAFT 1b   05-Jul-2007       Ashok Kumar T J     Incorporated review comments.           |
-- |DRAFT 1c   24-Sep-2007       Ashok Kumar T J     Bugfixing, removed hiden params in the  |
-- |                                                 conc req submittion api. Added code to  |
-- |                                                 use fnd messages.                       |
-- |                                                                                         |
-- |DRAFT 1d   15-Nov-2007      Piyush Khandelwal    Modified to add new error handling part.|
-- |                                                 Changed the logic to fetch              |
-- |                                                 contact_party_id and rel_party_id.      |
-- |                                                                                         |
-- |DRAFT 1e   16-jan-2008      Piyush Khandelwal    Modified to add batch_id as a parameter.|
-- |DRAFT 1f   02-May-2008      Piyush Khandelwal    Modified to add wait condition.         |
-- +=========================================================================================+

 AS
  -- Global Variables
  G_REQUEST_ID NUMBER;
  G_ERRBUF     VARCHAR2(2000);

  ------------------------------------------
  -- Function to get the TCA Entity Id's  --
  ------------------------------------------

  FUNCTION GET_OWNER_TABLE_ID(P_ORIG_SYSTEM           IN VARCHAR2,
                              P_ORIG_SYSTEM_REFERENCE IN VARCHAR2,
                              P_OWNER_TABLE_NAME      IN VARCHAR2,
                              P_ERR_MSG               OUT VARCHAR2)
    RETURN NUMBER
  -- +===================================================================+
    -- | Name       : GET_OWNER_TABLE_ID                                   |
    -- | Description: Function to return the TCA Entity Id (owner_table_id)|
    -- |              from HZ_ORIG_SYS_REFERENCES table for a given set    |
    -- |              of input parameters.                                 |
    -- |                                                                   |
    -- | Parameters : p_orig_system                                        |
    -- |            : p_orig_system_reference                              |
    -- |            : p_owner_table_name                                   |
    -- |                                                                   |
    -- | Returns    : TCA Entity id                                        |
    -- |                                                                   |
    -- +===================================================================+

   IS
    LN_TCA_ENTITY_ID NUMBER := 0;

  BEGIN

    SELECT OWNER_TABLE_ID
      INTO LN_TCA_ENTITY_ID
      FROM HZ_ORIG_SYS_REFERENCES
     WHERE ORIG_SYSTEM = P_ORIG_SYSTEM
       AND ORIG_SYSTEM_REFERENCE = P_ORIG_SYSTEM_REFERENCE
       AND OWNER_TABLE_NAME = P_OWNER_TABLE_NAME
       AND STATUS = 'A'; -- Active flag

    RETURN LN_TCA_ENTITY_ID;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,
                             'No data found error while fetching from HZ_ORIG_SYS_REFERENCE for ' ||
                             'Owner Table Name: ' || P_OWNER_TABLE_NAME ||
                             ', Orig System: ' || P_ORIG_SYSTEM ||
                             ', Orig System Reference: ' ||
                             P_ORIG_SYSTEM_REFERENCE);

      RETURN LN_TCA_ENTITY_ID;

    WHEN TOO_MANY_ROWS THEN
      APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,
                             'Multiple records found while fetching from HZ_ORIG_SYS_REFERENCE for ' ||
                             'Owner Table Name: ' || P_OWNER_TABLE_NAME ||
                             ', Orig System: ' || P_ORIG_SYSTEM ||
                             ', Orig System Reference: ' ||
                             P_ORIG_SYSTEM_REFERENCE);

      RETURN LN_TCA_ENTITY_ID;
    WHEN OTHERS THEN
      APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,
                             'Unexpected error logging error message into error stack table. Error - ' ||
                             SQLERRM);
      RETURN LN_TCA_ENTITY_ID;
  END GET_OWNER_TABLE_ID;

  --------------------------------------------------------------------------------------------
  -- Procedure registered as Concurrent program to perform OSR Checks, update the interface --
  -- table(s) with the respective TCA Entity Id and to call the standard concurrent program --
  -- "Import Sales Leads" to import the leads in to oracle.                                 --
  --------------------------------------------------------------------------------------------

  PROCEDURE MAIN_PROC(X_ERRBUF  OUT NOCOPY VARCHAR2,
                      X_RETCODE OUT NOCOPY NUMBER,
                      P_BATCHID IN NUMBER)
  -- +===================================================================+
    -- | Name       : MAIN_PROC                                            |
    -- | Description: *** See above ***                                    |
    -- |                                                                   |
    -- | Parameters : No Input Parameters                                  |
    -- |                                                                   |
    -- | Returns    : Standard Out parameters of a concurrent program      |
    -- |                                                                   |
    -- +===================================================================+
   IS

    LC_VALID_FLAG       VARCHAR2(1) := 'T';
    LC_ERROR_MSG        VARCHAR2(2000);
    LC_FULL_ERR_MSG     VARCHAR2(2000);
    LN_BATCH_ID         NUMBER := NULL;
    L_SRC_SYS           APPS.AS_IMPORT_INTERFACE.SOURCE_SYSTEM%TYPE;
    LN_IMP_INT_ID       NUMBER := NULL;
    LN_PARTY_ID         NUMBER;
    LN_PARTY_SITE_ID    NUMBER;
    LN_CONTACT_PARTY_ID NUMBER;
    LN_REL_PARTY_ID     NUMBER;
    LN_CNT_PNT_ID       NUMBER;
    L_P_OS              VARCHAR2(30);
    L_P_OSR             VARCHAR2(240);
    L_PS_OS             VARCHAR2(30);
    L_PS_OSR            VARCHAR2(240);
    L_CNT_OS            VARCHAR2(30);
    L_CNT_OSR           VARCHAR2(240);
    L_CP_OS             VARCHAR2(30);
    L_CP_OSR            VARCHAR2(240);
    LC_DEBUG            VARCHAR2(10) := NULL;
    LC_PURGE            VARCHAR2(10) := NULL;
    LN_REQ_ID           NUMBER;

    LN_TOTAL_REC_CNT NUMBER := 0;
    LN_TOTAL_ERR_CNT NUMBER := 0;
    LN_BTCH_CNT      NUMBER := 0;
    LN_BTCH_ERR_CNT  NUMBER := 0;
    LB_WAIT  BOOLEAN;
    lv_phase              VARCHAR2(50);
    lv_status             VARCHAR2(50);
    lv_dev_phase          VARCHAR2(15);
    lv_dev_status         VARCHAR2(15);
    lv_message            VARCHAR2(4000);
    lv_error_exist        VARCHAR2(1);
    lv_warning            VARCHAR2(1);
    
    
   -- Cursor to fetch distinct batch_id and source_system to
    -- perform TCA Entity Validations.
    CURSOR LCU_GET_BATCHES(P_BATCH NUMBER) IS
      SELECT DISTINCT BATCH_ID, SOURCE_SYSTEM
        FROM AS_IMPORT_INTERFACE
       WHERE LOAD_STATUS IN ('STAGED', 'VALIDATION_ERROR')
         AND BATCH_ID = NVL(P_BATCH, BATCH_ID);

    -- Cursor to fetch Leads record from AS_IMPORT_INTERFACE
    CURSOR LCU_GET_LEADS(P_BATCH_ID NUMBER, P_SRC_SYS VARCHAR2) IS
      SELECT IMPORT_INTERFACE_ID
        FROM AS_IMPORT_INTERFACE
       WHERE BATCH_ID = P_BATCH_ID
         AND SOURCE_SYSTEM = P_SRC_SYS
         AND LOAD_STATUS IN ('STAGED', 'VALIDATION_ERROR');

    -- Cursor to fetch TCA Entity OSR's from the common staging table.
    CURSOR LCU_GET_OSR(P_IMP_INT_ID NUMBER) IS
      SELECT PARTY_ORIG_SYSTEM,
             PARTY_ORIG_SYSTEM_REFERENCE,
             PTY_SITE_ORIG_SYSTEM,
             PTY_SITE_ORIG_SYSTEM_REFERENCE,
             CONTACT_ORIG_SYSTEM,
             CONTACT_ORIG_SYSTEM_REFERENCE,
             CNT_PNT_ORIG_SYSTEM,
             CNT_PNT_ORIG_SYSTEM_REFERENCE
        FROM XX_AS_LEAD_IMP_OSR_STG
       WHERE IMPORT_INTERFACE_ID = P_IMP_INT_ID;

    -- Cursor to fetch Contact party id and Rel party id.
    CURSOR GET_CTC_REL_PRTY_ID(P_OS VARCHAR2, P_OSR VARCHAR2) IS

      SELECT HR.SUBJECT_ID, HOS.PARTY_ID
        FROM HZ_ORIG_SYS_REFERENCES HOS, HZ_RELATIONSHIPS HR
       WHERE HOS.ORIG_SYSTEM = P_OS
         AND HOS.ORIG_SYSTEM_REFERENCE = P_OSR
         AND HOS.OWNER_TABLE_NAME = 'HZ_ORG_CONTACTS'
         AND HOS.STATUS = 'A' -- Active flag
         AND HOS.PARTY_ID = HR.PARTY_ID
         AND HR.DIRECTIONAL_FLAG = 'F';
    -- Cursor to fetch distinct batch_id and source_system to
    -- submit the Lead import program after the OSR check.

    CURSOR LCU_GET_VALID_BATCHES(P_BTCH_ID NUMBER) IS
      SELECT DISTINCT BATCH_ID, SOURCE_SYSTEM
        FROM AS_IMPORT_INTERFACE
       WHERE LOAD_STATUS = 'NEW'
       AND BATCH_ID = NVL(P_BTCH_ID,BATCH_ID);

    -- PL/SQL to store the import_interface_id
    TYPE XX_IMP_INT_TBL_TYPE IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    LT_XX_IMP_INT_TBL XX_IMP_INT_TBL_TYPE;

    -- PL/SQL to store the custom staging table record status
    TYPE XX_OSR_STATUS_TBL_TYPE IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
    LT_XX_OSR_STATUS_TBL XX_OSR_STATUS_TBL_TYPE;

    -- PL/SQL to store the customer party id's
    TYPE XX_PARTY_ID_TBL_TYPE IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    LT_XX_PARTY_ID_TBL XX_PARTY_ID_TBL_TYPE;

    -- PL/SQL to store the customer party site id's
    TYPE XX_PTY_SITE_ID_TBL_TYPE IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    LT_XX_PTY_SITE_ID_TBL XX_PTY_SITE_ID_TBL_TYPE;

    -- PL/SQL to store the contact party id's
    TYPE XX_CNT_PTY_ID_TBL_TYPE IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    LT_XX_CNT_PTY_ID_TBL XX_CNT_PTY_ID_TBL_TYPE;

    -- PL/SQL to store the relationship party id's
    TYPE XX_REL_PTY_ID_TBL_TYPE IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    LT_XX_REL_PTY_ID_TBL XX_REL_PTY_ID_TBL_TYPE;

    -- PL/SQL to store the lead's record status
    TYPE XX_LOAD_STATUS_TBL_TYPE IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
    LT_XX_LOAD_STATUS_TBL XX_LOAD_STATUS_TBL_TYPE;

    -- PL/SQL to store the full error message
    TYPE XX_LD_ERR_MSG_TBL_TYPE IS TABLE OF AS_IMPORT_INTERFACE.LOAD_ERROR_MESSAGE%TYPE INDEX BY BINARY_INTEGER;
    LT_XX_LD_ERR_MSG_TBL XX_LD_ERR_MSG_TBL_TYPE;

  BEGIN

    -- Initialize the global variables.
    G_REQUEST_ID := APPS.FND_GLOBAL.CONC_REQUEST_ID;

    -- Initialize the Global PL/SQL error table.
    --XX_COM_CONV_ELEMENTS_PKG.bulk_table_initialize;

    -- Initializing the PL/SQL tables.
    LT_XX_IMP_INT_TBL.DELETE;
    LT_XX_PARTY_ID_TBL.DELETE;
    LT_XX_PTY_SITE_ID_TBL.DELETE;
    LT_XX_CNT_PTY_ID_TBL.DELETE;
    LT_XX_REL_PTY_ID_TBL.DELETE;
    LT_XX_LOAD_STATUS_TBL.DELETE;
    LT_XX_LD_ERR_MSG_TBL.DELETE;
    LT_XX_OSR_STATUS_TBL.DELETE;

    -- Update the Leads interface table with Batch ID 9999
    -- if the records are not already batched.
    IF P_BATCHID IS NULL THEN

      UPDATE AS_IMPORT_INTERFACE AII
         SET AII.BATCH_ID = 9999
       WHERE AII.BATCH_ID IS NULL
         AND AII.LOAD_STATUS = 'STAGED';

    END IF;

    APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                           ' ----------- Run Statistics -----------' ||
                           CHR(10));
    APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                           'Batch ID  Processed   Success   Errored ');
    APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                           '--------  ---------   -------   ------- ');

    FOR BATCH_REC IN LCU_GET_BATCHES(P_BATCHID) LOOP
      -- Re-initialize the local variables
      LN_BATCH_ID := NULL;
      L_SRC_SYS   := NULL;

      LN_BTCH_CNT     := 0;
      LN_BTCH_ERR_CNT := 0;

      LN_BATCH_ID := BATCH_REC.BATCH_ID;
      L_SRC_SYS   := BATCH_REC.SOURCE_SYSTEM;

      LT_XX_IMP_INT_TBL.DELETE;

      -- Bulk collect the interface records.
      OPEN LCU_GET_LEADS(LN_BATCH_ID, L_SRC_SYS);
      FETCH LCU_GET_LEADS BULK COLLECT
        INTO LT_XX_IMP_INT_TBL;
      CLOSE LCU_GET_LEADS;
      APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, LT_XX_IMP_INT_TBL.COUNT);

      IF LT_XX_IMP_INT_TBL.COUNT = 0 THEN
        FND_MESSAGE.SET_NAME('XXCRM', 'XX_SFA_0043_NOREC_TO_PROCESS');
        FND_MESSAGE.SET_TOKEN(TOKEN => 'P_BATCH_ID', VALUE => LN_BATCH_ID);
        FND_MESSAGE.SET_TOKEN(TOKEN => 'P_SRC_SYS', VALUE => L_SRC_SYS);
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, FND_MESSAGE.GET);
        G_ERRBUF := FND_MESSAGE.GET;
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, G_REQUEST_ID);

        XX_COM_ERROR_LOG_PUB.LOG_ERROR_CRM(P_APPLICATION_NAME       => G_APPLICATION_NAME,
                                           P_PROGRAM_TYPE           => G_PROGRAM_TYPE,
                                           P_PROGRAM_NAME           => G_PROGRAM_NAME,
                                           P_PROGRAM_ID             => G_REQUEST_ID,
                                           P_MODULE_NAME            => G_MODULE_NAME,
                                           P_ERROR_LOCATION         => 'XX_SFA_LEADS_PKG.main_proc',
                                           P_ERROR_MESSAGE_CODE     => 'XX_SFA_0043_NOREC_TO_PROCESS',
                                           P_ERROR_MESSAGE          => G_ERRBUF,
                                           P_ERROR_MESSAGE_SEVERITY => 'MEDIUM',
                                           P_ERROR_STATUS           => G_ERROR_STATUS_FLAG);

        -- RETURN;

      ELSIF LT_XX_IMP_INT_TBL.COUNT > 0 THEN
        --
        -- Process all the interface records for Valid OSR checks
        --
        FOR I IN LT_XX_IMP_INT_TBL.FIRST .. LT_XX_IMP_INT_TBL.LAST LOOP
          -- Re-initialize the local variable
          LC_VALID_FLAG       := 'T';
          LC_FULL_ERR_MSG     := NULL;
          LC_ERROR_MSG        := NULL;
          LN_IMP_INT_ID       := NULL;
          LN_PARTY_ID         := NULL;
          LN_PARTY_SITE_ID    := NULL;
          LN_CONTACT_PARTY_ID := NULL;
          LN_REL_PARTY_ID     := NULL;
          LN_CNT_PNT_ID       := NULL;
          L_P_OS              := NULL;
          L_P_OSR             := NULL;
          L_PS_OS             := NULL;
          L_PS_OSR            := NULL;
          L_CNT_OS            := NULL;
          L_CNT_OSR           := NULL;
          L_CP_OS             := NULL;
          L_CP_OSR            := NULL;

          LN_IMP_INT_ID := LT_XX_IMP_INT_TBL(I);
          LN_BTCH_CNT   := LN_BTCH_CNT + 1; -- Record count within a batch.

          -- Initialized the PL/SQL record
          LT_XX_PARTY_ID_TBL(I) := NULL;
          LT_XX_PTY_SITE_ID_TBL(I) := NULL;
          LT_XX_CNT_PTY_ID_TBL(I) := NULL;
          LT_XX_REL_PTY_ID_TBL(I) := NULL;
          LT_XX_LOAD_STATUS_TBL(I) := NULL;
          LT_XX_LD_ERR_MSG_TBL(I) := NULL;
          LT_XX_OSR_STATUS_TBL(I) := NULL;

          OPEN LCU_GET_OSR(LN_IMP_INT_ID);
          FETCH LCU_GET_OSR
            INTO L_P_OS, L_P_OSR, L_PS_OS, L_PS_OSR, L_CNT_OS, L_CNT_OSR, L_CP_OS, L_CP_OSR;
          IF LCU_GET_OSR%NOTFOUND THEN
            LC_VALID_FLAG := 'F';
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_SFA_0044_NO_DATA_FOUND');
            FND_MESSAGE.SET_TOKEN(TOKEN => 'P_IMP_INT_ID',
                                  VALUE => LN_IMP_INT_ID);
            G_ERRBUF        := FND_MESSAGE.GET;

            LC_FULL_ERR_MSG := G_ERRBUF;

            LN_BTCH_ERR_CNT := LN_BTCH_ERR_CNT + 1; -- Error count within a batch
            --
            -- As record not found in custom staging table, update only the interface
            -- table with error details.
            --
            LT_XX_LOAD_STATUS_TBL(I) := 'VALIDATION_ERROR';
            LT_XX_LD_ERR_MSG_TBL(I) := LC_FULL_ERR_MSG;
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                   'Record ID: ' || LN_IMP_INT_ID ||
                                   ' Error - ' || LC_FULL_ERR_MSG);

            /*Call API for inserting records in error table*/
            XX_COM_ERROR_LOG_PUB.LOG_ERROR_CRM(P_APPLICATION_NAME       => G_APPLICATION_NAME,
                                               P_PROGRAM_TYPE           => G_PROGRAM_TYPE,
                                               P_PROGRAM_NAME           => G_PROGRAM_NAME,
                                               P_PROGRAM_ID             => G_REQUEST_ID,
                                               P_MODULE_NAME            => G_MODULE_NAME,
                                               P_ERROR_LOCATION         => 'XX_SFA_LEADS_PKG.main_proc',
                                               P_ERROR_MESSAGE_CODE     => 'XX_SFA_0044_NO_DATA_FOUND',
                                               P_ERROR_MESSAGE          => G_ERRBUF,
                                               P_ERROR_MESSAGE_SEVERITY => 'MEDIUM',
                                               P_ERROR_STATUS           => G_ERROR_STATUS_FLAG);

          END IF;
          CLOSE LCU_GET_OSR;
          G_ERRBUF := NULL;
          -- If record found then do the OSR checks.
          IF LC_VALID_FLAG <> 'F' THEN

            --lc_error_msg := NULL;

            -- Identify the Oracle Party ID associated with the Party OSR.
            IF L_P_OS IS NOT NULL AND L_P_OSR IS NOT NULL THEN
              LN_PARTY_ID := GET_OWNER_TABLE_ID(P_ORIG_SYSTEM           => L_P_OS,
                                                P_ORIG_SYSTEM_REFERENCE => L_P_OSR,
                                                P_OWNER_TABLE_NAME      => 'HZ_PARTIES',
                                                P_ERR_MSG               => LC_ERROR_MSG);
            ELSE
              FND_MESSAGE.SET_NAME('XXCRM', 'XX_SFA_0038_PARTY_OSR_NULL');
              G_ERRBUF      := FND_MESSAGE.GET;
              LC_VALID_FLAG := 'F';

              LC_FULL_ERR_MSG := G_ERRBUF;

              /*Call API for inserting records in error table*/
              XX_COM_ERROR_LOG_PUB.LOG_ERROR_CRM(P_APPLICATION_NAME       => G_APPLICATION_NAME,
                                                 P_PROGRAM_TYPE           => G_PROGRAM_TYPE,
                                                 P_PROGRAM_NAME           => G_PROGRAM_NAME,
                                                 P_PROGRAM_ID             => G_REQUEST_ID,
                                                 P_MODULE_NAME            => G_MODULE_NAME,
                                                 P_ERROR_LOCATION         => 'XX_SFA_LEADS_PKG.main_proc',
                                                 P_ERROR_MESSAGE_CODE     => 'XX_SFA_0038_PARTY_OSR_NULL',
                                                 P_ERROR_MESSAGE          => G_ERRBUF,
                                                 P_ERROR_MESSAGE_SEVERITY => 'MEDIUM',
                                                 P_ERROR_STATUS           => G_ERROR_STATUS_FLAG);
            END IF;

            G_ERRBUF := NULL;
            -- Identify the Oracle Party Site ID associated with the Party Site OSR.
            IF L_PS_OS IS NOT NULL AND L_PS_OSR IS NOT NULL THEN
              LN_PARTY_SITE_ID := GET_OWNER_TABLE_ID(P_ORIG_SYSTEM           => L_PS_OS,
                                                     P_ORIG_SYSTEM_REFERENCE => L_PS_OSR,
                                                     P_OWNER_TABLE_NAME      => 'HZ_PARTY_SITES',
                                                     P_ERR_MSG               => LC_ERROR_MSG);
            ELSE
              FND_MESSAGE.SET_NAME('XXCRM',
                                   'XX_SFA_0039_PRTY_SITE_OSR_NULL');
              G_ERRBUF      := FND_MESSAGE.GET;
              LC_VALID_FLAG := 'F';

              LC_FULL_ERR_MSG := LC_FULL_ERR_MSG || ' >> ' || G_ERRBUF;

              /*Call API for inserting records in error table*/
              XX_COM_ERROR_LOG_PUB.LOG_ERROR_CRM(P_APPLICATION_NAME       => G_APPLICATION_NAME,
                                                 P_PROGRAM_TYPE           => G_PROGRAM_TYPE,
                                                 P_PROGRAM_NAME           => G_PROGRAM_NAME,
                                                 P_PROGRAM_ID             => G_REQUEST_ID,
                                                 P_MODULE_NAME            => G_MODULE_NAME,
                                                 P_ERROR_LOCATION         => 'XX_SFA_LEADS_PKG.main_proc',
                                                 P_ERROR_MESSAGE_CODE     => 'XX_SFA_0039_PRTY_SITE_OSR_NULL',
                                                 P_ERROR_MESSAGE          => G_ERRBUF,
                                                 P_ERROR_MESSAGE_SEVERITY => 'MEDIUM',
                                                 P_ERROR_STATUS           => G_ERROR_STATUS_FLAG);
            END IF;

            G_ERRBUF := NULL;

            -- Identify the Oracle Party Site ID associated with the Party Site OSR.
            IF L_CNT_OS IS NOT NULL AND L_CNT_OSR IS NOT NULL THEN

              -- Get the related party id and contact party id
              OPEN GET_CTC_REL_PRTY_ID(L_CNT_OS, L_CNT_OSR);
              FETCH GET_CTC_REL_PRTY_ID
                INTO LN_CONTACT_PARTY_ID, LN_REL_PARTY_ID;
              IF GET_CTC_REL_PRTY_ID%NOTFOUND THEN
                --lc_error_msg := 'Invalid OSR columns for Contact Points.';
                FND_MESSAGE.SET_NAME('XXCRM',
                                     'XX_SFA_0042_CNTPRTY_NOTFOUND');
                G_ERRBUF      := FND_MESSAGE.GET;
                LC_VALID_FLAG := 'F';

                LC_FULL_ERR_MSG := LC_FULL_ERR_MSG || ' >> ' || G_ERRBUF;
                XX_COM_ERROR_LOG_PUB.LOG_ERROR_CRM(P_APPLICATION_NAME       => G_APPLICATION_NAME,
                                                   P_PROGRAM_TYPE           => G_PROGRAM_TYPE,
                                                   P_PROGRAM_NAME           => G_PROGRAM_NAME,
                                                   P_PROGRAM_ID             => G_REQUEST_ID,
                                                   P_MODULE_NAME            => G_MODULE_NAME,
                                                   P_ERROR_LOCATION         => 'XX_SFA_LEADS_PKG.main_proc',
                                                   P_ERROR_MESSAGE_CODE     => 'XX_SFA_0042_CNTPRTY_NOTFOUND',
                                                   P_ERROR_MESSAGE          => G_ERRBUF,
                                                   P_ERROR_MESSAGE_SEVERITY => 'MEDIUM',
                                                   P_ERROR_STATUS           => G_ERROR_STATUS_FLAG);
              END IF;
              CLOSE GET_CTC_REL_PRTY_ID;
            ELSE
              FND_MESSAGE.SET_NAME('XXCRM',
                                   'XX_SFA_0041_CONT_PNT_OSR_NULL');
              G_ERRBUF      := FND_MESSAGE.GET;
              LC_VALID_FLAG := 'F';

              LC_FULL_ERR_MSG := LC_FULL_ERR_MSG || ' >> ' || G_ERRBUF;
              XX_COM_ERROR_LOG_PUB.LOG_ERROR_CRM(P_APPLICATION_NAME       => G_APPLICATION_NAME,
                                                 P_PROGRAM_TYPE           => G_PROGRAM_TYPE,
                                                 P_PROGRAM_NAME           => G_PROGRAM_NAME,
                                                 P_PROGRAM_ID             => G_REQUEST_ID,
                                                 P_MODULE_NAME            => G_MODULE_NAME,
                                                 P_ERROR_LOCATION         => 'XX_SFA_LEADS_PKG.main_proc',
                                                 P_ERROR_MESSAGE_CODE     => 'XX_SFA_0041_CONT_PNT_OSR_NULL',
                                                 P_ERROR_MESSAGE          => G_ERRBUF,
                                                 P_ERROR_MESSAGE_SEVERITY => 'MEDIUM',
                                                 P_ERROR_STATUS           => G_ERROR_STATUS_FLAG);
            END IF;

            -- load_status = STAGED -> Initial record status when data is loaded by the OWB.
            -- load_status = NEW    -> Records that passed the OSR checks and are new to load.
            -- load_status = VALIDATION_ERROR -> Records which did not pass the OSR checks.
            IF LC_VALID_FLAG = 'F' THEN
              LN_BTCH_ERR_CNT := LN_BTCH_ERR_CNT + 1; -- Error count within a batch
              LT_XX_LOAD_STATUS_TBL(I) := 'VALIDATION_ERROR';
              LT_XX_LD_ERR_MSG_TBL(I) := SUBSTR(LC_FULL_ERR_MSG, 1, 2000);
              LT_XX_OSR_STATUS_TBL(I) := 'VALIDATION_ERROR';
              APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                     'Record ID: ' || LN_IMP_INT_ID ||
                                     ' Error - ' || LC_FULL_ERR_MSG);
            ELSE
              -- Populate the PL/SQL tables
              LT_XX_PARTY_ID_TBL(I) := LN_PARTY_ID;
              LT_XX_PTY_SITE_ID_TBL(I) := LN_PARTY_SITE_ID;
              LT_XX_CNT_PTY_ID_TBL(I) := LN_CONTACT_PARTY_ID;
              LT_XX_REL_PTY_ID_TBL(I) := LN_REL_PARTY_ID;
              LT_XX_LOAD_STATUS_TBL(I) := 'NEW';
              LT_XX_OSR_STATUS_TBL(I) := 'VALID';
            END IF;

          END IF; -- IF lc_valid_flag <> 'F' THEN
        END LOOP; -- FOR i IN lt_xx_imp_int_tbl.FIRST .. lt_xx_imp_int_tbl.LAST

        -- Bulk update the interface and staging tables.
        FORALL I IN LT_XX_IMP_INT_TBL.FIRST .. LT_XX_IMP_INT_TBL.LAST
          UPDATE AS_IMPORT_INTERFACE
             SET PARTY_ID           = LT_XX_PARTY_ID_TBL(I),
                 PARTY_SITE_ID      = LT_XX_PTY_SITE_ID_TBL(I),
                 CONTACT_PARTY_ID   = LT_XX_CNT_PTY_ID_TBL(I),
                 REL_PARTY_ID       = LT_XX_REL_PTY_ID_TBL(I),
                 LOAD_STATUS        = LT_XX_LOAD_STATUS_TBL(I),
                 LOAD_ERROR_MESSAGE = LT_XX_LD_ERR_MSG_TBL(I),
                 LAST_UPDATE_DATE   = SYSDATE,
                 LAST_UPDATED_BY    = FND_GLOBAL.USER_ID,
                 LAST_UPDATE_LOGIN  = FND_GLOBAL.LOGIN_ID
           WHERE IMPORT_INTERFACE_ID = LT_XX_IMP_INT_TBL(I);

        FORALL I IN 1 .. LT_XX_OSR_STATUS_TBL.LAST
          UPDATE XX_AS_LEAD_IMP_OSR_STG
             SET STATUS = LT_XX_OSR_STATUS_TBL(I)
           WHERE IMPORT_INTERFACE_ID = LT_XX_IMP_INT_TBL(I);

        COMMIT;

        -- Re-initialize the PL/SQL tables.
        LT_XX_IMP_INT_TBL.DELETE;
        LT_XX_PARTY_ID_TBL.DELETE;
        LT_XX_PTY_SITE_ID_TBL.DELETE;
        LT_XX_CNT_PTY_ID_TBL.DELETE;
        LT_XX_REL_PTY_ID_TBL.DELETE;
        LT_XX_LOAD_STATUS_TBL.DELETE;
        LT_XX_LD_ERR_MSG_TBL.DELETE;
        LT_XX_OSR_STATUS_TBL.DELETE;

      END IF; -- IF lt_xx_imp_int_tbl.COUNT = 0 THEN

      APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                             LPAD(LN_BATCH_ID, 8, ' ') ||
                             LPAD(LN_BTCH_CNT, 11, ' ') ||
                             LPAD((LN_BTCH_CNT - LN_BTCH_ERR_CNT), 10, ' ') ||
                             LPAD(LN_BTCH_ERR_CNT, 10, ' '));

      LN_TOTAL_REC_CNT := LN_TOTAL_REC_CNT + LN_BTCH_CNT; -- Total Record count
      LN_TOTAL_ERR_CNT := LN_TOTAL_ERR_CNT + LN_BTCH_ERR_CNT; -- Total error count

    END LOOP; -- lcu_get_batches

    APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                           '--------  ---------   -------   ------- ');
    APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                           '          ' || LPAD(LN_TOTAL_REC_CNT, 9, ' ') ||
                           LPAD((LN_TOTAL_REC_CNT - LN_TOTAL_ERR_CNT),
                                10,
                                ' ') || LPAD(LN_TOTAL_ERR_CNT, 10, ' '));
    APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                           '--------  ---------   -------   ------- ');

    COMMIT;
    IF LN_TOTAL_REC_CNT = LN_TOTAL_ERR_CNT THEN
      IF LN_TOTAL_REC_CNT = 0 THEN
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Records Found To Process');
      END IF;
      
      IF LN_TOTAL_REC_CNT >0
      THEN X_RETCODE := 2;
       RETURN;
      END IF;
      
    ELSIF LN_TOTAL_REC_CNT <> LN_TOTAL_ERR_CNT AND LN_TOTAL_ERR_CNT <> 0 THEN
      X_RETCODE := 1;
    END IF;
    -- Fetching the profile values for debug and purge options.
    LC_DEBUG := FND_PROFILE.VALUE('XX_LEADS_IMPORT_DEBUG');
    LC_PURGE := FND_PROFILE.VALUE('XX_LEADS_IMPORT_PURGE_ERRORS');

    APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_debug ' || LC_DEBUG);
    APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_purge ' || LC_PURGE);

    --
    -- Submit the Standard import program to load the leads data into oracle.
    --
    FOR VLD_BATCH_REC IN LCU_GET_VALID_BATCHES(P_BATCHID) LOOP
      BEGIN
        --
        -- Call to Standard "Import Sales Leads" concurrent program to load the leads data into oracle.
        --
        LN_REQ_ID := 0;
        LN_REQ_ID := FND_REQUEST.SUBMIT_REQUEST(APPLICATION => 'AS',
                                                PROGRAM     => 'ASXSLIMP',
                                                DESCRIPTION => 'The program is spawned by request id - ' ||
                                                               G_REQUEST_ID,
                                                START_TIME  => NULL,
                                                SUB_REQUEST => FALSE,
                                                ARGUMENT1   => VLD_BATCH_REC.SOURCE_SYSTEM,
                                                ARGUMENT2   => LC_DEBUG,
                                                ARGUMENT3   => VLD_BATCH_REC.BATCH_ID,
                                                ARGUMENT4   => LC_PURGE
                                                --,argument5   => ''
                                                --,argument6   => ''
                                                --,argument7   => ''
                                                --,argument8   => ''
                                                --,argument9   => ''
                                                --,argument10  => ''
                                                );
        IF LN_REQ_ID > 0 THEN
          APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                 'Submitted Import Sales Leads Program with request id : ' ||
                                 LN_REQ_ID || ' For Batch Id: ' ||
                                 VLD_BATCH_REC.BATCH_ID);
          APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                                 'Submitted Import Sales Leads Program with request id : ' ||
                                 LN_REQ_ID || ' For Batch Id: ' ||
                                 VLD_BATCH_REC.BATCH_ID);
            COMMIT;
                      
        ELSE
          APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                 'Failed to submitted Import Sales Leads Program for Batch Id: ' ||
                                 VLD_BATCH_REC.BATCH_ID);
          APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                                 'Failed to submitted Import Sales Leads Program for Batch Id: ' ||
                                 VLD_BATCH_REC.BATCH_ID);



        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,
                                 'Unexpected error while calling the standard import program. Error - ' ||
                                 SQLCODE || ' : ' || SQLERRM);
          APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,
                                 'Unexpected error while calling the standard import program. Error - ' ||
                                 SQLCODE || ' : ' || SQLERRM);

          FND_MESSAGE.SET_NAME('XXCRM', 'XX_SFA_0058_CONC_PRG_ERR');
          FND_MESSAGE.SET_TOKEN('SQLERR', SQLERRM);
          G_ERRBUF  := FND_MESSAGE.GET;
          X_RETCODE := 1;

          XX_COM_ERROR_LOG_PUB.LOG_ERROR_CRM(P_APPLICATION_NAME       => G_APPLICATION_NAME,
                                             P_PROGRAM_TYPE           => G_PROGRAM_TYPE,
                                             P_PROGRAM_NAME           => G_PROGRAM_NAME,
                                             P_PROGRAM_ID             => LN_REQ_ID,
                                             P_MODULE_NAME            => G_MODULE_NAME,
                                             P_ERROR_LOCATION         => 'XX_SFA_LEADS_PKG.main_proc',
                                             P_ERROR_MESSAGE_CODE     => 'XX_SFA_0058_CONC_PRG_ERR',
                                             P_ERROR_MESSAGE          => G_ERRBUF,
                                             P_ERROR_MESSAGE_SEVERITY => 'MEDIUM',
                                             P_ERROR_STATUS           => G_ERROR_STATUS_FLAG);

      END;
    END LOOP; -- lcu_get_valid_batches
             lv_phase       := NULL;
             lv_status      := NULL;
             lv_dev_phase   := NULL;
             lv_dev_status  := NULL;
             lv_message     := NULL;
             lv_error_exist := NULL;
             lv_warning     := NULL;
             
             
     /*Added wait condition*/        
    IF P_BATCHID is not null then
         lb_wait := FND_CONCURRENT.wait_for_request
                       (   request_id      => LN_REQ_ID,
                           interval        => 10,
                           phase           => lv_phase,
                           status          => lv_status,
                           dev_phase       => lv_dev_phase,
                           dev_status      => lv_dev_status,
                           message         => lv_message
                       );
  END IF;
  EXCEPTION
    WHEN OTHERS THEN
      APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,
                             'Unexpected error in MAIN_PROC. Error - ' ||
                             SQLERRM);
      FND_MESSAGE.SET_NAME('XXCRM', 'XX_SFA_0059_MAIN_PRG_ERR');
      FND_MESSAGE.SET_TOKEN('SQLERR', SQLERRM);
      G_ERRBUF  := FND_MESSAGE.GET;
      X_RETCODE := 2;

      XX_COM_ERROR_LOG_PUB.LOG_ERROR_CRM(P_APPLICATION_NAME       => G_APPLICATION_NAME,
                                         P_PROGRAM_TYPE           => G_PROGRAM_TYPE,
                                         P_PROGRAM_NAME           => G_PROGRAM_NAME,
                                         P_PROGRAM_ID             => G_REQUEST_ID,
                                         P_MODULE_NAME            => G_MODULE_NAME,
                                         P_ERROR_LOCATION         => 'XX_SFA_LEADS_PKG.main_proc',
                                         P_ERROR_MESSAGE_CODE     => 'XX_SFA_0059_MAIN_PRG_ERR',
                                         P_ERROR_MESSAGE          => G_ERRBUF,
                                         P_ERROR_MESSAGE_SEVERITY => 'MEDIUM',
                                         P_ERROR_STATUS           => G_ERROR_STATUS_FLAG);

  END MAIN_PROC;

END XX_SFA_LEADS_PKG;

/
SHOW ERRORS;
