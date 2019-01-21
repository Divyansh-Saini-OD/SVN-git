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

CREATE OR REPLACE PACKAGE XXCDH_AR_ABL_CUSTOMER_PRF_PKG AUTHID CURRENT_USER 
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify  Rel 1.2                           |
-- +=====================================================================================+
-- |                                                                                     |
-- | Name             :  PRINT_CUSTOMER_DETAILS                                          |
-- |                                                                                     |
-- | Description      : Reporting package for all AB Customers                           |
-- |                                                                                     |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date        Author                       Remarks                           |
-- |=======   ==========  ====================         ==================================|
-- |Draft 1.0 02-DEC-09   Nabarun Ghosh                Draft version                     |
-- |V1.0      22-Feb-10   nabarun Ghosh                Incorporated the below performan	 |
-- |                                                   -ce advices from performance team:|
-- |                                                   Added the hint LEADING on the 02  |
-- |                                                   Functions.			 |
-- |                                                   Removed Parallel from the cursor	 |
-- |                                                   lcu_abl_cust.			 |
-- |						       Moved up the hz_customer_profile  |
-- |						       and ra_terms as inline view	 |
-- |											 |
-- |											 |
-- +=====================================================================================+
AS


 TYPE xxcdh_abl_cust_rec IS RECORD 
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
  TYPE xxcdh_abl_cust_tab        IS TABLE OF XXCDH_AR_ABL_CUSTOMER_PRF_PKG.xxcdh_abl_cust_rec;

  lt_abl_cust_rec                xxcdh_abl_cust_tab;
  lt_abl_cust_rec_init           xxcdh_abl_cust_tab;
  
  TYPE ltab_phone_number IS TABLE OF VARCHAR2(40) INDEX BY VARCHAR2(5);
  lt_phone_number        ltab_phone_number;
  lt_phone_ot            ltab_phone_number; 
  lt_phone_ap            ltab_phone_number; 

 TYPE xxcdh_subq_rec IS RECORD 
             (
               party_id          hz_parties.party_id%TYPE
              ,party_name        hz_parties.party_name%TYPE
              ,account_number    hz_cust_accounts.account_number%TYPE
              ,party_site_id     hz_party_sites.party_site_id%TYPE
              ,address1          hz_locations.address1%TYPE
              ,address2          hz_locations.address2%TYPE
              ,city              hz_locations.city%TYPE
              ,state             hz_locations.state%TYPE
              ,province          hz_locations.province%TYPE 
              ,postal_code       hz_locations.postal_code%TYPE
              ,country           fnd_territories_tl.territory_short_name%TYPE
              ,country_code      hz_locations.country%TYPE 
              ,cust_account_id   hz_cust_accounts.cust_account_id%TYPE 
             );
  
  TYPE lt_subq_func      IS TABLE OF XXCDH_AR_ABL_CUSTOMER_PRF_PKG.xxcdh_subq_rec; 
  TYPE lt_subq_func_in   IS TABLE OF XXCDH_AR_ABL_CUSTOMER_PRF_PKG.xxcdh_subq_rec;     
 
  l_tab_subq_func_inc       lt_subq_func_in; 
  lrec_subq_func_out        XXCDH_AR_ABL_CUSTOMER_PRF_PKG.xxcdh_subq_rec;
 

  FUNCTION Get_abl_cust_Details 
  RETURN XXCDH_AR_ABL_CUSTOMER_PRF_PKG.lt_subq_func
  PIPELINED ; 

  
  PROCEDURE PRINT_CUSTOMER_DETAILS ( p_errbuf   OUT NOCOPY VARCHAR2
                                    ,p_retcode  OUT NOCOPY VARCHAR2               
                                   );
END XXCDH_AR_ABL_CUSTOMER_PRF_PKG;
/
SHOW ERRORS;













