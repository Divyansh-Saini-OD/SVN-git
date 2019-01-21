create or replace
PACKAGE xx_ce_cc_stmt_match_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                                                                                 |
-- +=================================================================================+
-- | Name       : xx_ce_cc_stmt_match_pkg.pks                                       |
-- | Description: E2079 OD: CE CreditCard AJB Statement Match                        |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |  1.0     2011-02-09   Joe Klein          New package copied from E1310 to       |
-- |                                          create separate package for the        |
-- |                                          match procedure.                       |
-- |                                          Include fix for defect 9249.           |
-- |                                                                                 |                                                                                     |
-- +=================================================================================+
-- | Name        : match_stmt_to_ajb_batches                                         |
-- | Description : This procedure will be used to match AJB 99x files to BAI bank    |
-- |               statements.                                                       |
-- |                                                                                 |
-- +=================================================================================+
   PROCEDURE match_stmt_to_ajb_batches (
      x_errbuf          OUT NOCOPY      VARCHAR2
    , x_retcode         OUT NOCOPY      NUMBER
    , p_provider_code   IN              VARCHAR2
    , p_from_date       IN              VARCHAR2
    , p_to_date         IN              VARCHAR2
   );
   
END xx_ce_cc_stmt_match_pkg;

/
