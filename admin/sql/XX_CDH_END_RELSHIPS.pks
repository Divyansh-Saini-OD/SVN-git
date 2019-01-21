CREATE OR REPLACE
PACKAGE XX_CDH_END_RELSHIPS 
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_CDH_END_RELSHIPS                                                       |
-- | Description : Package to End Date OD_CUST_HIER Relationships                            |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        07-Jul-2009     Indra Varada        Initial version                           |
-- +=========================================================================================+
AS

  PROCEDURE end_relships
  (
     x_errbuf       OUT     VARCHAR2
    ,x_retcode      OUT     VARCHAR2
    ,p_summ_id      IN      NUMBER
    ,p_rel_code     IN      VARCHAR2
    ,p_commit       IN      VARCHAR2
  );

END XX_CDH_END_RELSHIPS;
/
SHOW ERRORS;
