SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package spec xx_cdh_ebl_conv_paper_epdf

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE  xx_cdh_ebl_conv_paper_epdf
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CDH_EBL_CONV_PAPER_EPDF                               |
-- | Description : 1) To import account details and into BSD table          |
-- |                                                                        |
-- |                                                                        |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      22-NOV-2010  Devi Viswanathan      Initial version             |
-- +========================================================================+

-- +========================================================================+
-- | Name        : LOAD_ACCOUNT_DTLS                                        |
-- | Description : To import account details and into BSD table             |
-- |                                                                        |
-- | Returns     : VARCHAR2                                                 |
-- +========================================================================+


  FUNCTION load_account_dtls( p_cust_account_id   VARCHAR2
                            , p_account_number    VARCHAR2
                            , p_customer_name     VARCHAR2
                            , p_aops_number       VARCHAR2
                            , p_zip_code          VARCHAR2
                            )
  RETURN VARCHAR2;


-- +========================================================================+
-- | Name        : VALIDATE_ACCOUNT_LOGIN                                   |
-- | Description : To validate login details and return print documents of  |
-- |               the customer.                                            |
-- |                                                                        |
-- +========================================================================+

  PROCEDURE validate_account_login( p_aops_account_number   IN   VARCHAR2
                                  , p_account_name          IN   VARCHAR2
                                  , p_zip_code              IN   NUMBER
                                  , p_contact_first_name    IN   VARCHAR2
                                  , p_contact_last_name     IN   VARCHAR2
                                  , p_contact_phone_area    IN   VARCHAR2
                                  , p_contact_phone         IN   VARCHAR2
                                  , p_contact_phone_ext     IN   VARCHAR2
                                  , p_contact_email         IN   VARCHAR2
                                  , p_validate              IN   VARCHAR2
                                  , x_status                OUT  VARCHAR2
                                  , x_message               OUT  VARCHAR2
                                  );
                                  

-- +===========================================================================+
-- | Name        : CREATE_EBILL_CONTACT                                        |
-- | Description :                                                             |
-- | This program will create contact for the coverted ePDF document with      |
-- | contact points for eMail and phone.                                       |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author               Remarks                          |
-- |======== =========== ============= ========================================|
-- |DRAFT 1  24-DEC-2010 Naga kalyan          Initial draft version            |
-- |                                                                           |
-- |===========================================================================|

  PROCEDURE create_ebill_contact( p_cust_account_id       IN  HZ_CUST_ACCOUNTS.cust_account_id%TYPE
                                , p_contact_first_name    IN  VARCHAR2
                                , p_contact_last_name     IN  VARCHAR2
                                , p_contact_phone_area    IN  VARCHAR2
                                , p_contact_phone         IN  VARCHAR2
                                , p_contact_phone_ext     IN  VARCHAR2
                                , p_contact_email         IN  VARCHAR2
                                , x_org_contact_id        OUT NUMBER);                                  


-- +========================================================================+
-- | Name        : INSERT_CONTACT_DETAILS                                   |
-- | Description : To to insert contact details into the                    |
-- |               xx_cdh_ebl_conv_contact_dtl table.                       |
-- |                                                                        |
-- +========================================================================+
   PROCEDURE insert_conv_doc_details ( x_errbuff            OUT NOCOPY  VARCHAR2
                                     , x_retcode            OUT NOCOPY  VARCHAR2
                                     , p_cust_account_id    IN  NUMBER
                                     , p_contact_first_name IN  VARCHAR2
                                     , p_contact_last_name  IN  VARCHAR2
                                     , p_contact_phone_area IN  VARCHAR2
                                     , p_contact_phone      IN  VARCHAR2
                                     , p_contact_phone_ext  IN  VARCHAR2
                                     , p_contact_email      IN  VARCHAR2
                                     , p_validate           IN  VARCHAR2);


-- +===========================================================================+
-- | Name        : CONVERT_PAPER_TO_EPDF                                       |
-- | Description :                                                             |
-- | This program will convert all the PAPER document into ePDF documents and  |
-- | will validate the data to chaneg the status to COMPLETE                   |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author               Remarks                          |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 08-DEC-2010 Parameswaran S N     Initial draft version            |
-- |                                                                           |
-- |===========================================================================|
    PROCEDURE convert_paper_to_epdf( p_batch_id          IN  NUMBER
                                   , p_validate          IN  VARCHAR2
                                   , x_status            OUT VARCHAR2
                                   , x_message           OUT VARCHAR2
                                   );
                                   
                                   
-- +===========================================================================+
-- | Name        : CONVERT_PAPER_TO_EPDF                                       |
-- | Description :                                                             |
-- | This program is for generating a report to will all the documents which   |
-- | have failed during conversion from PRINT to ePDF.                         |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |DRAFT 1A 15-FEB-2011 Devi Viswanathan Initial draft version                |
-- |                                                                           |
-- |===========================================================================|                                   
  PROCEDURE convert_error_report( x_errbuff     OUT NOCOPY  VARCHAR2
                                , x_retcode     OUT NOCOPY  VARCHAR2
                                , p_start_date  IN  VARCHAR2
                                );
                                                                   

END xx_cdh_ebl_conv_paper_epdf;
/
SHOW ERR
