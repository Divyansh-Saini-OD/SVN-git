CREATE OR REPLACE PACKAGE XX_CDH_WEBCONTACTS_CONV
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_RESP_PKG                                                           |
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
      cust_acct_site_id                 HZ_CUST_ACCT_SITES_ALL.cust_acct_site_id%TYPE      ,
      orig_system                       HZ_ORIG_SYS_REFERENCES.orig_system%TYPE            ,
      orig_system_reference             HZ_ORIG_SYS_REFERENCES.orig_system_reference%TYPE  ,
      webcontacts_bill_to_site_id       XX_CDH_AS_EXT_WEBCTS_V.webcontacts_bill_to_site_id%TYPE                   ,
      webcontacts_bill_to_osr           XX_CDH_AS_EXT_WEBCTS_V.webcontacts_bill_to_osr%TYPE                       ,
      webcontacts_contact_party_id      XX_CDH_AS_EXT_WEBCTS_V.webcontacts_contact_party_id%TYPE                  ,
      webcontacts_contact_party_osr     XX_CDH_AS_EXT_WEBCTS_V.webcontacts_contact_party_osr%TYPE
   );

   PROCEDURE update_ext_attributes ( x_errbuf            OUT NOCOPY VARCHAR2
                                   , x_retcode           OUT NOCOPY VARCHAR2
                                   );

END XX_CDH_WEBCONTACTS_CONV;

/

SHOW ERRORS