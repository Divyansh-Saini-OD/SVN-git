SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_JTF_NOTES_PKG
-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |                 Oracle NAIO Consulting Organization                   |
-- +=======================================================================+
-- | Name        : XX_JTF_NOTES_PKG                                        |
-- | Description :                                                         |
-- |                                                                       |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version     Date           Author               Remarks                |
-- |=======    ==========      ================     =======================|
-- |Draft 1a   19-Apr-2007     Prakash Sowriraj     Initial draft version  |
-- |                                                                       |
-- |Draft 1b   04-Apr-2008     Hema Chikkanna       Included Batch_ID      |
-- |                                                parameter in           |
-- |                                                log_exception          |
-- |Draft 1c   16-Jul-2008     Satyasrinivas        Changes for the error  |
-- |                                                message for notes.     |
-- +=======================================================================+

AS

----------------------------
--Declaring Global Variables
----------------------------

    g_errbuf                         VARCHAR2(2000);
    g_procedure_name                 VARCHAR2(250);
    g_staging_table_name             VARCHAR2(250);
    g_staging_column_name            VARCHAR2(32);
    g_staging_column_value           VARCHAR2(500);
    
-- +===================================================================+
-- | Name        : create_notes_main                                   |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: CDH Customer Conversion Notes'         |
-- | Parameters  : p_batch_id_from,p_batch_id_to                       |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_notes_main
    (
         x_errbuf           OUT NOCOPY  VARCHAR2
        ,x_retcode          OUT NOCOPY  VARCHAR2
        ,p_batch_id_from    IN          NUMBER
        ,p_batch_id_to      IN          NUMBER
    );

-- +===================================================================+
-- | Name        : create_notes                                        |
-- | Description : Procedure to create a new customer notes            |
-- |                                                                   |
-- | Parameters  : l_jtf_notes_int                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_note
    (
         l_jtf_notes_int            IN      XX_JTF_NOTES_INT%ROWTYPE
        ,x_notes_return_status      OUT     VARCHAR
    );


-- +===================================================================+
-- | Name        : create_note_context                                 |
-- | Description : Procedure to create a new customer notes            |
-- |                                                                   |
-- | Parameters  : l_jtf_note_context_int                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Create_note_context
    (
         l_jtf_note_context_int          IN   XX_JTF_NOTE_CTX_INT%ROWTYPE
        ,x_note_context_return_status    OUT  VARCHAR
    );


-- +===================================================================+
-- | Name        : Get_note_id                                         |
-- |                                                                   |
-- | Description : Procedure used to get note_id                       |
-- |                                                                   |
-- | Parameters  : p_note_orig_system_ref                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_note_id
    (
         p_note_orig_system_ref          IN   VARCHAR2
        ,p_note_type                     IN   VARCHAR2 default null
        ,x_note_id                       OUT  NUMBER
    );


-- +===================================================================+
-- | Name        : Get_object_source_id                                |
-- |                                                                   |
-- | Description : Procedure used to get object_source_id              |
-- |                                                                   |
-- | Parameters  : p_source_object_code,p_source_object_orig_system_ref|
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_object_source_id
    (
         p_source_object_code            IN  VARCHAR2
        ,p_source_object_orig_sys_ref    IN  VARCHAR2
        ,p_source_object_orig_sys        IN  VARCHAR2
        ,x_object_source_id              OUT NUMBER
    );

-- +===================================================================+
-- | Name        : log_debug_msg                                       |
-- |                                                                   |
-- | Description : Procedure used to store the count of records that   |
-- |               are processed/failed/succeeded                      |
-- | Parameters  : p_debug_msg                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE log_debug_msg
    (
        p_debug_msg  IN  VARCHAR2
    );

-- +===================================================================+
-- | Name        : log_exception                                       |
-- | Description : This procedure is used for logging exceptions into  |
-- |               conversion common elements tables.                  |
-- |                                                                   |
-- | Parameters  : p_conversion_id,p_record_control_id,p_procedure_name|
-- |               p_batch_id,p_exception_log,p_oracle_error_msg       |
-- +===================================================================+
PROCEDURE log_exception
    (
         p_procedure_name         IN VARCHAR2
        ,p_staging_column_name    IN VARCHAR2
        ,p_staging_column_value   IN VARCHAR2
        ,p_exception_log          IN VARCHAR2
        ,p_oracle_error_code      IN VARCHAR2
        ,p_msg_severity           IN VARCHAR2
        ,p_batch_id               IN NUMBER
    );
END XX_JTF_NOTES_PKG;
/
SHOW ERRORS;