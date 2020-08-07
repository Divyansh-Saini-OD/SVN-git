SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification xx_ce_accrual_pkg
PROMPT Program exits if the creation is not successful

create or replace
PACKAGE xx_ce_accrual_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- +=================================================================================+
-- | Name       : XX_CE_ACCRUAL_PKG.pks                                              |
-- | Description: Cash Management AJB Creditcard Reconciliation E1310-Extension      |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |                                                                                 |
-- |1.0      11-APR-2011   Jagadeesh S        Created the package for E2078          |
-- |1.1      11-Nov-2012   Ray Strauss        defect 21156 as-of-date                |
-- |1.2      16-JUL-2013   Darshini           Modified for R12 Upgrade Retrofit      |
---+=================================================================================+
   PROCEDURE accrual_process (
      x_errbuf               OUT NOCOPY      VARCHAR2,
      x_retcode              OUT NOCOPY      NUMBER,
      p_provider_code        IN              VARCHAR2,
      p_ajb_card_type        IN              VARCHAR2,
      p_fee_classification   IN              VARCHAR2,
	  --Commented and added by Darshini for R12 Upgrade Retrofit
      --p_to_date              IN              DATE,
	  p_to_date              IN              VARCHAR2,
      p_as_of_date           IN              VARCHAR2
   );
   PROCEDURE purge (
      x_errbuf               OUT NOCOPY      VARCHAR2,
      x_retcode              OUT NOCOPY      NUMBER
   );

END xx_ce_accrual_pkg;
/
show errors;
exit;