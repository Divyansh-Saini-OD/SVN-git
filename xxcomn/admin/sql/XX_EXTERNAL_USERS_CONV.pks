create or replace PACKAGE XX_EXTERNAL_USERS_CONV
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_CONV                                                               |
-- | Description : Package body for E1328_BSD_iReceivables_interface                                    |
-- |               This package performs the following                                                  |
-- |               1. Setup the contact at a bill to level                                              |
-- |               2. Insert web user details into xx_external_users                                    |
-- |               3. Assign responsibilites and party id  when the webuser is created in fnd_user      |
-- |                                                                                                    |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       30-Jan-2008 Alok Sahay         Initial draft version.      			 	                        |
-- |1.1       11-Nov-2015 Manikant Kasu      Made code changes as part of BSD - iRec Webpassword Sync   |
-- |                                         enhancements                                               |
-- |1.2       20-Jul-2016 Vasu Raparla       Added two new procedures for defect #38393                 |
-- +====================================================================================================+
*/

   TYPE webcontact_user_rec_type IS RECORD (
         fnd_user_rowid            ROWID
       , user_id                   NUMBER(15)
       , user_name                 VARCHAR2(100)
       , description               VARCHAR2(240)
       , customer_id               NUMBER(15)
       , ext_user_rowid            ROWID
       , ext_user_id               NUMBER(10)
       , userid                    VARCHAR2(100)
       , password                  VARCHAR2(255)
       , person_first_name         VARCHAR2(150)
       , person_middle_name        VARCHAR2(60)
       , person_last_name          VARCHAR2(150)
       , email                     VARCHAR2(100)
       , party_id                  NUMBER(15)
       , status                    VARCHAR2(1)
       , orig_system               VARCHAR2(50)
       , contact_osr               VARCHAR2(50)
       , acct_site_osr             VARCHAR2(50)
       , webuser_osr               VARCHAR2(50)
       , access_code               NUMBER(3)
       , permission_flag           VARCHAR2(1)
       , site_key                  VARCHAR2(100)
       , end_date                  DATE
       , load_status               VARCHAR2(30)
       , user_locked               VARCHAR2(1)
       , created_by                NUMBER
       , creation_date             DATE
       , last_update_date          DATE
       , last_updated_by           NUMBER
       , last_update_login         NUMBER
   );

   TYPE BATCH_LIST_TYP   IS TABLE OF VARCHAR2(60) INDEX BY BINARY_INTEGER;

   PROCEDURE print_batch_id;

   FUNCTION gen_batch_id
            RETURN VARCHAR2;

   PROCEDURE web_contact_conv_master ( x_errbuf            OUT NOCOPY   VARCHAR2
                                     , x_retcode           OUT NOCOPY   VARCHAR2
                                     , p_load_status       IN           VARCHAR2 DEFAULT NULL
                                     , p_report_only       IN            VARCHAR2 DEFAULT 'Y'
                                     );

   PROCEDURE web_contact_conv_batch ( x_errbuf            OUT NOCOPY   VARCHAR2
                                    , x_retcode           OUT NOCOPY   VARCHAR2
                                    , p_orig_system       IN           VARCHAR2
                                    , p_batch_id          IN           VARCHAR2
                                    , p_load_status       IN           VARCHAR2 DEFAULT NULL
                                    );


   PROCEDURE process_new_user_access ( x_errbuf            OUT NOCOPY   VARCHAR2
                                     , x_retcode           OUT NOCOPY   VARCHAR2
                                     , p_force             IN           VARCHAR2  DEFAULT NULL
                                     , p_date              IN           VARCHAR2  DEFAULT NULL
                                     , p_load_status       IN           VARCHAR2  DEFAULT NULL
                                     );

   PROCEDURE generate_ldif_file ( x_errbuf            OUT NOCOPY    VARCHAR2
                                , x_retcode           OUT NOCOPY    VARCHAR2
                                , p_load_status       IN            VARCHAR2 DEFAULT NULL
                                );
                                
                                
   PROCEDURE update_external_table_status ( x_errbuf     OUT NOCOPY    VARCHAR2
                                          , x_retcode    OUT NOCOPY    VARCHAR2
                                          );

   PROCEDURE webuser_conv_wrapper         ( x_errbuf        OUT NOCOPY    VARCHAR2
                                          , x_retcode       OUT NOCOPY    VARCHAR2
                                          , p_load_status   IN            VARCHAR2
                                          , p_force         IN            VARCHAR2
                                          , p_date          IN            VARCHAR2
                                          , p_submit_ext    IN            VARCHAR2
                                          , p_submit_main   IN            VARCHAR2
                                          , p_submit_ldif   IN            VARCHAR2
                                          , p_submit_access IN            VARCHAR2
                                          );  
  
  PROCEDURE webuser_dip_monitor          ( x_errbuf       OUT NOCOPY    VARCHAR2
                                          , x_retcode      OUT NOCOPY    VARCHAR2
                                          , p_mail_server  IN            VARCHAR2
                                          , p_mail_from    IN            VARCHAR2
                                          , p_mail_to      IN            VARCHAR2
                                          , p_from_title   IN            VARCHAR2
                                          , p_subject      IN            VARCHAR2
                                          , p_page_flag    IN            VARCHAR2
                                          , p_wait_time    IN            NUMBER
                                          , p_retry_count  IN            NUMBER
                                          );   

PROCEDURE process_new_user_access_delta (
      x_errbuf            OUT NOCOPY    VARCHAR2
    , x_retcode           OUT NOCOPY    VARCHAR2
    , p_load_status       IN            VARCHAR2  DEFAULT NULL
    );   

    
PROCEDURE   purge_external_usr_stg        (  x_errbuf               OUT NOCOPY VARCHAR2
                                            ,x_retcode              OUT NOCOPY VARCHAR2
                                            ,p_age                  IN         NUMBER
                                                      );
 PROCEDURE  debug_external_user           (  x_errbuf            OUT NOCOPY   VARCHAR2
                                            , x_retcode           OUT NOCOPY   NUMBER
                                            , p_fnd_user          IN           VARCHAR2 DEFAULT NULL
                                            , p_report_only       IN           VARCHAR2 DEFAULT 'Y'
                                            , p_debug_flag        IN           VARCHAR2 DEFAULT 'N'
                                                      ); 
                                         
END XX_EXTERNAL_USERS_CONV;

/

SHOW ERRORS