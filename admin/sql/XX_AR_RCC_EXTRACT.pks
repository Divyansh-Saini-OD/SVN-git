SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR  EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE apps.XX_AR_RCC_EXTRACT AUTHID CURRENT_USER
AS
-- +=========================================================================+
-- |                           Oracle - GSD                                  |
-- |                             Bangalore                                   |
-- +=========================================================================+
-- | Name  : XX_AR_RCC_EXTRACT                                               |
-- | Rice ID: I-3090                                                         |
-- | Description      : This Program will extract all the RCC transactions   |
-- |                    into an XML file for RACE                            |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== ================= ===================================|
-- |DRAFT1A 30-JUN-2014 Darshini G        Initial draft version              |
-- +=========================================================================+
   g_debug_flag  BOOLEAN;
-- +===================================================================+
-- | Name  : xx_rcc_ab_trx_extract                                     |
-- | Description     : The xx_rcc_ab_trx_extract procedure is the main |
-- |                   procedure that will extract the RCC Transactions|
-- |                   and write them into the output file             |
-- |                                                                   |
-- | Parameters      : p_trx_date          IN -> Transaction Date      |
-- |                   p_account_number    IN -> Account Number        |
-- |                   x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- +===================================================================+
PROCEDURE xx_rcc_ab_trx_extract(
                                x_retcode          OUT NOCOPY     NUMBER
                                ,x_errbuf          OUT NOCOPY     VARCHAR2
                                ,p_trx_date        IN             VARCHAR2
                                ,p_account_number  IN             VARCHAR2
                                ,p_debug_flag      IN             VARCHAR2
                                ,p_status          IN             VARCHAR2
                                );
PROCEDURE xx_rcc_trx_purge(
                              x_retcode          OUT NOCOPY     NUMBER
                              ,x_errbuf          OUT NOCOPY     VARCHAR2
                              ,p_purge_days      IN             NUMBER
                              );

END XX_AR_RCC_EXTRACT;
/
SHOW ERROR