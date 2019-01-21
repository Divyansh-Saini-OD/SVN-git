  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |                       ORACLE AMS                                         				 |
  -- +===================================================================================+
  -- | Name        : XX_CDH_REL_SYNC_PKG                                                 |
  -- | Description : This Package is used by the OD: CDH Relationships Correction program|                  
  -- |                                                                                   |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 20-OCT-2012  Dheeraj Vernekar		     Initial draft version               |
  -- +===================================================================================+
  
create or replace
PACKAGE XX_CDH_REL_SYNC_PKG AS 

PROCEDURE rel_main ( x_errbuf       OUT NOCOPY  VARCHAR2
                    , x_retcode      OUT NOCOPY  VARCHAR2
                    , p_load_aops     IN         VARCHAR2
                    , p_run_fix       IN         VARCHAR2
                    , p_chk_load      IN         VARCHAR2
                    , p_commit        IN         VARCHAR2);

END XX_CDH_REL_SYNC_PKG;
/