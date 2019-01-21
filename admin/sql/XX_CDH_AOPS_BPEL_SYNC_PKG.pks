CREATE OR REPLACE
PACKAGE      xx_cdh_aops_bpel_sync_pkg
AS
   /*****************************************************************************
      NAME:       XX_CDH_AOPS_BPEL_SYNC_PKG
      PURPOSE:    To Apply Commit in the seesion from BPEL as sometimes BPEL 
                  process doest commit the database invoke operations.
      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        02/19/2008   Kathirvel P        1. Created this package.
   *******************************************************************************/ 

PROCEDURE xx_cdh_apply_commit_proc (p_commit_flag IN VARCHAR2);
 
END xx_cdh_aops_bpel_sync_pkg;
/