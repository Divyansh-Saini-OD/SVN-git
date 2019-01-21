SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_CDH_GEN_EXP_SEGMENT
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_GEN_EXP_SEGMENT                                     |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Generates Exposure Analysis Segment based on Collector Code| 
-- |               and Category Code                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      15-May-2008 Indra Varada           Initial Version               |
-- |2.0      27-AUG-2008 Sreedhar Mohan         Added more parameters         |
-- +==========================================================================+
AS
  PROCEDURE MAIN(
                  p_errbuf         OUT NOCOPY VARCHAR2,
                  p_retcode        OUT NOCOPY VARCHAR2,
                  p_rpt_start_date  IN VARCHAR2,
                  p_rpt_end_date    IN VARCHAR2,
                  p_rpt_only        IN VARCHAR2
                );

END XX_CDH_GEN_EXP_SEGMENT;
/

SHOW ERRORS;
