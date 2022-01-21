CREATE OR REPLACE PACKAGE XX_EXTERNAL_USERS_PKG
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_PKG                                                           |
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
-- |1.0       30-Jan-2008 Alok Sahay         Initial draft version.      			 	                    |
-- |                                                                                                    |
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

   PROCEDURE process_new_user_access ( x_errbuf            OUT    VARCHAR2
                                     , x_retcode           OUT    VARCHAR2
                                     , p_force             IN     VARCHAR2  DEFAULT NULL
                                     , p_date              IN     DATE      DEFAULT NULL
                                     );

   PROCEDURE process_new_ext_user ( x_errbuf            OUT    VARCHAR2
                                  , x_retcode           OUT    VARCHAR2
                                  );

END XX_EXTERNAL_USERS_PKG;

/

SHOW ERRORS