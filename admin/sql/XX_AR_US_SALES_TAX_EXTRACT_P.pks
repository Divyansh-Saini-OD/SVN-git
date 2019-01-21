SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE XX_AR_US_SALES_TAX_EXTRACT_P AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        XX_AR_US_SALES_TAX_EXTRACT_P                          |
-- | Description : Procedure to extract the tax summary information    |
-- |               based on the company and gl date and write it to    |
-- |               to a flat file                                      |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |Draft 1   10-JUL-08     Ranjith            Initial version         |
-- |Version 1.1 14-MAY-09   Ranjith            Perf fix POC            | 
--                                                                     |
-- +===================================================================+
-- +===================================================================+
-- | Name : TAX_EXTRACT                                                |
-- | Description : Program to submit detail or summary mode based on   |
-- |               the mode                                            |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: AR US Sales Tax Extracts - Write to file            |
-- |                                                                   |
-- | Parameters :     x_error_buff                                     |
-- |                  x_ret_code                                       |
-- |                  p_company                                        |
-- |                  p_gl_date_from                                   |
-- |                  p_gl_date_to                                     |
-- |                  p_detail_level                                   |
-- |                  p_posted_status                                  |
-- |                  p_trx_id_from                                    |
-- |                  p_trx_id_to                                      |
-- |                  p_file_name                                      |
-- | Returns :                                                         |
-- |        return code , error msg                                    |
-- +===================================================================+

   PROCEDURE TAX_EXTRACT (x_error_buff            OUT  NOCOPY    VARCHAR2
                         ,x_ret_code              OUT  NOCOPY    NUMBER
                         ,p_company                              VARCHAR2
                         ,p_gl_date_from                         VARCHAR2
                         ,p_gl_date_to                           VARCHAR2
                         ,p_detail_level                         VARCHAR2
                         ,p_posted_status                        VARCHAR2
                         ,p_trx_id_from                          NUMBER       --added for performance per defect 10082
                         ,p_trx_id_to                            NUMBER       --added for performance per defect 10082
                         ,p_file_name                            VARCHAR2 
                         ,p_trx_date_from                        VARCHAR2 
                         ,p_trx_date_to                          VARCHAR2 
                         );
-- +===================================================================+
-- | Name : TAX_EXTRACT_DETAIL                                         |
-- | Description : Procedure to extract the tax DETAIL information     |
-- |               and write to a file. Extracts tax information        |
-- |               at the transaction level.                           |
-- |                                                                   |
-- | Parameters :  p_company                                            |
-- |               p_gl_date_from                                       |
-- |               p_gl_date_to                                         |
-- |               p_posted_status                                      |
-- |               p_trx_id_from                                        | 
-- |               p_trx_id_to                                          | 
-- |               p_file_name                                          |
-- |  Returns :           NONE                                          |
-- +===================================================================+
  PROCEDURE TAX_EXTRACT_DETAIL     ( p_company                  VARCHAR2
                                     ,p_gl_date_from             DATE
                                     ,p_gl_date_to               DATE
                                     ,p_posted_status            VARCHAR2
                                     ,p_trx_id_from              NUMBER     --added for performance per defect 10082
                                     ,p_trx_id_to                NUMBER     --added for performance per defect 10082
                                     ,p_file_name                VARCHAR2
                                     ,p_trx_date_from          date
                                     ,p_trx_date_to             date 
                                     ,p_adj_date_low             DATE
                                     ,p_adj_date_high            DATE 
                                      );

-- +===================================================================+
-- | Name : TAX_EXTRACT_SUMMARY                                        |
-- | Description : Proedure to extract the tax summary information     |
-- |               snd write to  flat file. The Tax information        |
-- |               is grouped based on the various display fields.     |
-- |                                                                   |
-- | Parameters :  p_company                                           |
-- |               p_gl_date_from                                      |
-- |               p_gl_date_to                                        |
-- |               p_posted_status                                     |
-- |               p_file_name                                         |
-- | Returns :                                                         |
-- |              NONE                                                 |
-- +===================================================================+
PROCEDURE TAX_EXTRACT_SUMMARY(p_company                 VARCHAR2
                             ,p_gl_date_from             DATE
                             ,p_gl_date_to               DATE
                             ,p_posted_status            VARCHAR2
                             ,p_file_name                VARCHAR2
                             ,p_trx_date_from          date
                             ,p_trx_date_to             date 
                             ,p_adj_date_low             DATE 
                             ,p_adj_date_high            DATE 
                             );

-- +===================================================================+
-- | Name : SUBMIT_REQUEST                                             |
-- | Description : Procedure to Submit the main tax extraction prog    |
-- |               and then submit the file copy program on sucessful  |
-- |               program completion or the error mailer on error     |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: AR US Sales Tax Extracts Program                    |
-- | Parameters :       x_error_buff                                   |
-- |                    x_ret_code                                     |
-- |                    p_company                                      |
-- |                    p_gl_date_from                                 |
-- |                    p_gl_date_to                                   |
-- |                    p_detail_level                                 |
-- |                    p_posted_status                                |
-- |                    p_limit_size                                   |
-- | Returns : Returns Code                                            |
-- |           Error Message                                           |
-- +===================================================================+

PROCEDURE SUBMIT_REQUEST (x_error_buff      OUT  NOCOPY    VARCHAR2
                         ,x_ret_code        OUT  NOCOPY    NUMBER
                         ,p_company                        VARCHAR2
                         ,p_gl_date_from                   VARCHAR2
                         ,p_gl_date_to                     VARCHAR2
                         ,p_detail_level                   VARCHAR2
                         ,p_posted_status                  VARCHAR2
                         ,p_limit_size                     NUMBER
                         ,p_trx_date_from                  VARCHAR2
                         ,p_trx_date_to                    VARCHAR2
                          );


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :     GET_SHIP_FROM_LOCATION                                 |
-- | Description : Function to extract ship from location              |
-- |               in pipe seperated values                            |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |Draft 1   10-JUL-08     Ranjith            Initial version         |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :  p_customer_trx_id                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |              Concatenated ship from location                      |
-- +===================================================================+

FUNCTION GET_SHIP_FROM_LOCATION  (p_ship_from_org_id	 NUMBER
                                  ,p_exclude_loc          VARCHAR2
                                   )
                                   RETURN VARCHAR2;

END XX_AR_US_SALES_TAX_EXTRACT_P;
/
SHOW ERROR
