SET VERIFY OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_COMN_DATA_PURGE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_COMN_DATA_PURGE_PKG.pks                              |
-- | Description :  Custom/Staging tables data purging                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  29-Oct-2007 Binoy              Initial draft version     |
-- +===================================================================+
AS
-- +===================================================================+
-- | Name        :  data_purge_main                                    |
-- | Description :  This procedure is invoked first when called from   |
-- |                Data purging UI                                    |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE data_purge_main
   (  x_errbuf              OUT VARCHAR2,
      x_retcode             OUT VARCHAR2,
      p_purge_group         IN  VARCHAR2,
      p_action_type         IN  VARCHAR2,
      p_commit              IN  VARCHAR2,
      p_c_para1             IN  VARCHAR2,
      p_c_para2             IN  VARCHAR2,
      p_c_para3             IN  VARCHAR2,
      p_c_para4             IN  VARCHAR2,
      p_c_para5             IN  VARCHAR2,
      p_n_para1             IN  NUMBER,
      p_n_para2             IN  NUMBER,
      p_n_para3             IN  NUMBER,
      p_n_para4             IN  NUMBER,
      p_n_para5             IN  NUMBER,
      p_d_para1             IN  VARCHAR2,
      p_d_para2             IN  VARCHAR2,
      p_d_para3             IN  VARCHAR2,
      p_d_para4             IN  VARCHAR2,
      p_d_para5             IN  VARCHAR2
  ) ;
  
PROCEDURE purge_n_days_data
   (  x_errbuf              OUT VARCHAR2,
      x_retcode             OUT VARCHAR2,
      p_purge_group         IN  VARCHAR2,
      p_action_type         IN  VARCHAR2,
      p_commit              IN  VARCHAR2,
      p_n_days              IN  NUMBER
   ) ;
  
END XX_COMN_DATA_PURGE_PKG;
/
SHOW ERRORS;