SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_CDH_TMP_CRD_LMT_PKG

WHENEVER SQLERROR CONTINUE
create or replace PACKAGE XX_CDH_TMP_CRD_LMT_PKG
IS
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- | Name        :  XX_CDH_TMP_CRD_LMT_PKG                                                               |
-- |                                                                                                     |
-- | Description :                                                                                       |
-- |                                                                                                     |
-- | Rice ID     : E3512                                                                                 |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- |=========    ===========  =============        ======================================================|
-- |  1.0        21-MAR-2016  Manikant Kasu        Program to update the credit limit to original amount |
-- |                                               after temp credit limit expires                       |
-- |  1.1        15-NOV-2016  Vasu Raparla         Modified for TempCreditUpload Tool process            |
-- +=====================================================================================================+

-- +====================================================================+
-- | Name       :  update_profile_amount                                |
-- |                                                                    |
-- | Description: Procedure to update the original credit limit once the|
-- |              temp credit expires                                   |
-- | Parameters : p_run_date                                            |
-- |              p_debug_flag                                          |
-- |                                                                    |
-- +====================================================================+

PROCEDURE update_profile_amount (    x_errbuf                   OUT NOCOPY   VARCHAR2
                                    ,x_retcode                  OUT NOCOPY   NUMBER
                                    ,p_run_date                 IN           VARCHAR2
                                    ,p_debug_flag               IN           VARCHAR2
                                 );

-- +====================================================================+
-- | Name       :  update_profile_amount_api                            |
-- |                                                                    |
-- | Description: Procedure to call the API to update the original      |
-- |              credit limit once the temp credit expires             |
-- | Parameters : p_cust_profile_amt_rec                                |
-- |              p_object_version_num                                  |
-- |                                                                    |
-- +====================================================================+

PROCEDURE update_profile_amount_api(  p_cust_profile_amt_rec  IN  hz_customer_profile_v2pub.cust_profile_amt_rec_type
                                     ,p_object_version_num    IN  NUMBER
);                                 

-- +====================================================================+
-- | Name       :  update_profile_amount                                |
-- |                                                                    |
-- | Description: Procedure to update customer profile credit limit amt |
-- |              from Temp Credit Limit OAF page                       |
-- | Parameters : p_prof_amt_id                                         |
-- |              p_cr_limit                                            |
-- |              p_orig_cr_limit                                       |
-- |              p_dml_typ                                             |
-- +====================================================================+

PROCEDURE update_profile_amount (    x_errmsg        OUT NOCOPY      VARCHAR2,
                                     x_retcode       OUT NOCOPY      NUMBER,
                                     p_prof_amt_id   IN              hz_cust_profile_amts.cust_acct_profile_amt_id%TYPE,
                                     p_cr_limit      IN              hz_cust_profile_amts.overall_credit_limit%TYPE,
                                     p_orig_cr_limit OUT NOCOPY      hz_cust_profile_amts.cust_acct_profile_amt_id%TYPE,
                                     p_dml_typ       IN              VARCHAR2
                                );
                                
-- +====================================================================+
-- | Name       : format_date                                           |
-- |                                                                    |
-- | Description: Procedure to format DATE input parameter              |
-- |                                                                    |
-- | Parameters : p_dml_typ                                             |
-- |              p_in_date                                             |
-- |              p_out_date                                            |
-- +====================================================================+

PROCEDURE format_date          (     p_dml_typ    IN  VARCHAR2,
                                     p_in_date    IN  VARCHAR2,
                                     p_out_date   OUT TIMESTAMP,
                                     x_errmsg     OUT NOCOPY  VARCHAR2,
                                     x_retcode    OUT NOCOPY NUMBER
                                );
  -- +===================================================================+
  -- | Name  : fetch_data                                                |
  -- | Description     : The fetch_data procedure will fetch data from   |
  -- |                   WEBADI to XX_CDH_TEMP_CREDIT_LIMIT_STG          |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- |                   p_debug_flag        IN -> Debug Flag            |
  -- |                   p_status            IN -> Record status         |
  -- +===================================================================+                                  
PROCEDURE fetch_data(p_customer_number        VARCHAR2,
                     p_temp_credit_limit      VARCHAR2,
                     p_start_date             DATE,
                     p_end_date               DATE,
                     p_currency               VARCHAR2);
  -- +===================================================================+
  -- | Name  : extract
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records insert into XX_CDH_CUST_ACCT_EXT_B      |
  -- |                                                                   |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- |                   p_debug_flag        IN -> Debug Flag            |
  -- |                   p_status            IN -> Record status         |
  -- +===================================================================+                     
PROCEDURE extract(
                  x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER);
END XX_CDH_TMP_CRD_LMT_PKG;
/
SHOW ERR