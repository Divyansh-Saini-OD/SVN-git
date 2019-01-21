create or replace
PACKAGE xx_cdh_indir_site_uses_pkg
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CDH_CLEANUP_INDIRECT_SITE_USES_PKG                    |
-- | Description : 1) To cleanup indirect sites by creating BILL TO site    |
-- |                  use if does not exists.                               |
-- |                                                                        |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      20-Aug-2010  Devi Viswanathan     Initial version              |
-- |2.0      30-Sep-2010  Devi Viswanathan     To add commit parameter.     |
-- |3.0      11-Jan-2013  Dheeraj V            QC 21670, Add Billing cycle  |
-- |                                           date as parameter            |
-- +========================================================================+

-- +========================================================================+
-- | Name        : main                                                     |
-- | Description : 1) To cleanup indirect sites by creating BILL TO site    |
-- |                  use if does not exists.                               |
-- |                                                                        |
-- +========================================================================+

  procedure main( x_errbuf   OUT NOCOPY  VARCHAR2
                , x_retcode  OUT NOCOPY  VARCHAR2
                , p_commit   IN          VARCHAR2
                , p_cycle_date IN        VARCHAR2);


END xx_cdh_indir_site_uses_pkg;
/
SHOW ERRORS;