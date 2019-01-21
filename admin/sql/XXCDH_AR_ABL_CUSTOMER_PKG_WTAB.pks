-- $Id:  $
-- $Rev:  $
-- $HeadURL:  $
-- $Author:  $
-- $Date:  $
SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XXCDH_AR_ABL_CUSTOMER_PKG_WTAB AUTHID CURRENT_USER 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify  Rel 1.1                         |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  PRINT_CUSTOMER_DETAILS                                        |
-- |                                                                                   |
-- | Description      : Reporting package for all AB Customers                         |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1.0 02-DEC-09   Nabarun Ghosh                Draft version                   |
-- +===================================================================================+
AS

 --CREATE INDEX XXCDH_ARABLCUST_JOBTITLE_N1 ON hz_org_contacts (UPPER(job_title))

 TYPE xxcdh_abl_cust_rec IS RECORD 
             (              
              party_id     NUMBER,
	                     account_name  VARCHAR2(250), 
	                     party_site_id NUMBER,
	                     address1  VARCHAR2(250),
	                     address2  VARCHAR2(250),
	                     city  VARCHAR2(250),
	                     state  VARCHAR2(250),
	                     province VARCHAR2(250),
	                     postal_code VARCHAR2(250),
	                     country VARCHAR2(250),
	                     country_code VARCHAR2(4),
	                     account_number VARCHAR2(150),
               standard_terms NUMBER
             );

  --Create table type as below , which are of above record type
  TYPE xxcdh_abl_cust_tab        IS TABLE OF XXCDH_AR_ABL_CUSTOMER_PKG_WTAB.xxcdh_abl_cust_rec;

  lt_abl_cust_rec                xxcdh_abl_cust_tab;
  lt_abl_cust_rec_init           xxcdh_abl_cust_tab;
  
 TYPE xxcdh_phone_rec IS RECORD 
             (
              party_id          NUMBER,
              job_title         VARCHAR2(150),
              phone_number      VARCHAR2(50)
             );

  --Create table type as below , which are of above record type
  TYPE xxcdh_phone_tab        IS TABLE OF XXCDH_AR_ABL_CUSTOMER_PKG_WTAB.xxcdh_phone_rec;
  lt_abl_phone_rec                xxcdh_phone_tab;
  lt_abl_phone_rec_init           xxcdh_phone_tab;
  
 TYPE xxcdh_abl_cust_stg_rec IS RECORD 
             (
              country_code      VARCHAR(4),
              account_number    VARCHAR2(150),
              account_name      VARCHAR2(250),
              address1          VARCHAR2(250),
              address2          VARCHAR2(250),
              city              VARCHAR2(250),
              state             VARCHAR2(250),
              Province          VARCHAR2(250),
              postal_code       VARCHAR2(250),
              country           VARCHAR2(250),
              party_id          NUMBER
             );

  --Create table type as below , which are of above record type
  TYPE xxcdh_abl_cust_stg_tab        IS TABLE OF XXCDH_AR_ABL_CUSTOMER_PKG_WTAB.xxcdh_abl_cust_stg_rec;

  lt_abl_cust_stg_rec                xxcdh_abl_cust_stg_tab;
  lt_abl_cust_stg_rec_init           xxcdh_abl_cust_stg_tab;
  
  PROCEDURE PRINT_CUSTOMER_DETAILS ( p_errbuf   OUT NOCOPY VARCHAR2
                                    ,p_retcode  OUT NOCOPY VARCHAR2               
                                   );
END XXCDH_AR_ABL_CUSTOMER_PKG_WTAB;
/
SHOW ERRORS;
