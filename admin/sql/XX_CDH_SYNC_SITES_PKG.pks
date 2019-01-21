create or replace
PACKAGE XX_CDH_SYNC_SITES_PKG AS 

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_ACCOUNT_STATUS_PKG.pkb                      |
-- | Description :  Inactivate account site and usages                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  28-Mar-2013 Dheeraj V          Initial draft version     |
-- |                                         for QC 22822              |
-- +===================================================================+
  
  procedure main_proc 
  (
    p_errbuff OUT NOCOPY VARCHAR2,
    p_retcode OUT NOCOPY VARCHAR2,
    p_summary_id IN NUMBER,
    p_commit IN VARCHAR2,
    p_force IN VARCHAR2
  );

END XX_CDH_SYNC_SITES_PKG;
