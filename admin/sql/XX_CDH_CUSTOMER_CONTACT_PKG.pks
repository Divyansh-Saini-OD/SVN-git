SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_CUSTOMER_CONTACT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XXCDHCREATECONTACTS.pls                            |
-- | Description :  CDH Customer Conversion Create Contact Pkg Spec    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  10-Apr-2007 Ambarish Mukherjee Initial draft version     |
-- |Draft 1b  30-Apr-2007 Ambarish Mukherjee Commented out custom code |
-- |                                         to create contacts        |
-- |Draft 1c  09-May-2007 Ambarish Mukherjee Modified to handle updates|
-- |Draft 1d  04-Jun-2007 Ambarish Mukherjee Modified to include limit |
-- |                                         clause in bulk fetch      |
-- +===================================================================+
AS

PROCEDURE create_contact_main
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_process_yn        IN  VARCHAR2
      );      
      
PROCEDURE create_contact
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_process_yn        IN  VARCHAR2
      );
      
PROCEDURE create_contact_worker
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_worker_id         IN  NUMBER
      );      
      
PROCEDURE create_role_responsibility
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_process_yn        IN  VARCHAR2
      );
      
PROCEDURE create_role_resp_worker
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_worker_id         IN  NUMBER
      );      

PROCEDURE create_contact_points
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_process_yn        IN  VARCHAR2
      );

PROCEDURE create_contact_point_worker
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_worker_id         IN  NUMBER
      ) ;     
      
PROCEDURE log_exception
      (  p_record_control_id      IN NUMBER
        ,p_source_system_code     IN VARCHAR2
        ,p_procedure_name         IN VARCHAR2
        ,p_staging_table_name     IN VARCHAR2
        ,p_staging_column_name    IN VARCHAR2
        ,p_staging_column_value   IN VARCHAR2
        ,p_source_system_ref      IN VARCHAR2
        ,p_batch_id               IN NUMBER
        ,p_exception_log          IN VARCHAR2
        ,p_oracle_error_code      IN VARCHAR2
        ,p_oracle_error_msg       IN VARCHAR2
      ); 
      
PROCEDURE log_debug_msg
      (
         p_debug_msg              IN VARCHAR2
      );
      
PROCEDURE create_collector_contact
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_orig_system       IN  VARCHAR2         
      );   
      
PROCEDURE create_default_contact
      (  p_api_version            IN  NUMBER := 1.0,
         p_init_msg_list          IN  VARCHAR2,
         p_commit                 IN  VARCHAR2,
         p_validation_level       IN  NUMBER,
         x_return_status          OUT NOCOPY VARCHAR2,
         x_msg_count              OUT NOCOPY NUMBER,
         x_msg_data               OUT NOCOPY VARCHAR2,
         p_org_party_id           IN  NUMBER,
         p_person_party_id        IN  NUMBER,
         p_phone_contact_point_id IN  NUMBER,
         p_email_contact_point_id IN  NUMBER,
         p_type                   IN  VARCHAR2,
         p_location_id            IN  NUMBER,
         x_relationship_id        OUT NOCOPY NUMBER,
         x_party_id               OUT NOCOPY NUMBER
      );
      
      
END XX_CDH_CUSTOMER_CONTACT_PKG;
/
SHOW ERRORS;