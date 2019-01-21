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

CREATE OR REPLACE PACKAGE XXCDH_AR_ABL_CUST_PKG_NOTAB AUTHID CURRENT_USER 
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
-- |Draft 1.0 20-Feb-10   Nabarun Ghosh                Draft version                     |
-- |V1.0      22-Feb-10   nabarun Ghosh                Incorporated the below performan	 |
-- |                                                   -ce advices from performance team:|
-- |                                                   Added the hint LEADING on the 02  |
-- |                                                   Functions.			 |
-- |                                                   No changes to the modified query  |
-- |                                                   of the main cursor lcu_abl_cust.  |
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
  TYPE xxcdh_abl_cust_tab        IS TABLE OF XXCDH_AR_ABL_CUST_PKG_NOTAB.xxcdh_abl_cust_rec;

  lt_abl_cust_rec                xxcdh_abl_cust_tab;
  lt_abl_cust_rec_init           xxcdh_abl_cust_tab;
  
  TYPE ltab_phone_number IS TABLE OF VARCHAR2(40) INDEX BY VARCHAR2(5);
  lt_phone_number        ltab_phone_number;
  lt_phone_ot            ltab_phone_number; 
  lt_phone_ap            ltab_phone_number; 
  
  
  PROCEDURE PRINT_CUSTOMER_DETAILS ( p_errbuf   OUT NOCOPY VARCHAR2
                                    ,p_retcode  OUT NOCOPY VARCHAR2               
                                   );
END XXCDH_AR_ABL_CUST_PKG_NOTAB;
/
SHOW ERRORS;
