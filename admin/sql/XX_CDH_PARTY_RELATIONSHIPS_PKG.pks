SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_PARTY_RELATIONSHIPS_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                         Oracle Consulting                                               |
-- +=========================================================================================+
-- | Name        : XX_CDH_PARTY_RELATIONSHIPS_PKG                                            |
-- | Description : Custom package for party-relationships not handled by bulk import         |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        30-Jul-2007     Rajeev Kamath        Initial version                          |
-- |                                                                                         |
-- +=========================================================================================+

AS
-- +===================================================================+
-- | Name        : party_relationship_main                             |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE party_relationship_main
    (
         x_errbuf       OUT     VARCHAR2
        ,x_retcode      OUT     VARCHAR2
        ,p_batch_id     IN      NUMBER
        ,p_process_yn   IN      VARCHAR2
    );
    
-- +===================================================================+
-- | Name        : party_relationship_worker                           |
-- |                                                                   |
-- | Description : The procedure to be invoked from the                |
-- |               concurrent program for threads in a batch           |
-- |                                                                   |
-- | Parameters  : p_batch_id                                          |
-- |               p_worker_id                                         |
-- +===================================================================+
PROCEDURE party_relationship_worker
    (
         x_errbuf       OUT     VARCHAR2
        ,x_retcode      OUT     VARCHAR2
        ,p_batch_id     IN      NUMBER
        ,p_worker_id    IN      NUMBER
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
        p_debug_msg     IN      VARCHAR2
    );
                    
-- +===================================================================+
-- | Name        : log_exception                                       |
-- | Description : This procedure is used for logging exceptions into  |
-- |                conversion common elements tables.                 |
-- |                                                                   |
-- | Parameters :  p_conversion_id,p_record_control_id,p_procedure_name|
-- |               p_batch_id,p_exception_log,p_oracle_error_msg       |
-- +===================================================================+
PROCEDURE log_exception
    (
         p_record_control_id        IN  NUMBER
        ,p_source_system_code       IN  VARCHAR2
        ,p_source_system_ref        IN  VARCHAR2
        ,p_procedure_name           IN  VARCHAR2
        ,p_staging_table_name       IN  VARCHAR2
        ,p_staging_column_name      IN  VARCHAR2
        ,p_staging_column_value     IN  VARCHAR2
        ,p_batch_id                 IN  NUMBER
        ,p_exception_log            IN  VARCHAR2
        ,p_oracle_error_code        IN  VARCHAR2
        ,p_oracle_error_msg         IN  VARCHAR2
    );


END XX_CDH_PARTY_RELATIONSHIPS_PKG;
/
SHOW ERRORS;