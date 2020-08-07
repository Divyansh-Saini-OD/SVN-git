SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_STD_LBX_SUB_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE


CREATE OR REPLACE PACKAGE APPS.XX_AR_STD_LBX_SUB_PKG AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Oracle Cloud Services                                |
-- +=================================================================================+
-- | Name       : XX_AR_STD_LBX_SUB_PKG.pks                                          |
-- | Description: AR Lockbox wrapper program                                         |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |DRAFT 1A  07-APR-2010  Sundaram S         Initial draft version                  |
-- |1.1       08-Nov-2010  Sundaram S         Added new parameter for Defect 8808    |
-- |1.2       10-Nov-2011  Pradeep Mariappan  Modified for parallel execution of     |
-- |                                          validation part of ARLPLB to improve   |
-- |                                          performance # defect 14764             |
-- +=================================================================================+
-- | Name        : XX_PROC_LBX_MAIN                                                  |
-- | Description : This procedure will be used to insert into AR_TRANSMISSIONS_ALL   |
-- |               ,AR_PAYMENTS_INTERFACE_ALL and Submit Processs Lockbox            |
-- |                                                                                 |
-- | Parameters  : x_errbuf                                                          |
-- |              ,x_retcode                                                         |
-- |              ,p_days_start_purge                                                |
-- |              ,p_cycle_Date    --Added for Defect# 8808                          |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- +=================================================================================+
  PROCEDURE xx_proc_lbx_main(x_errbuf                   OUT     NOCOPY     VARCHAR2
                           ,x_retcode                 OUT     NOCOPY     NUMBER
                           ,p_days_start_purge        IN                 NUMBER
                           ,p_cycle_date              In                 VARCHAR2 -- Added for defect #8808
			   );

  FUNCTION xx_custom_main_program_check return NUMBER ;
  FUNCTION xx_custom_wrapper_check return NUMBER ;
  PROCEDURE xx_submit_program (p_loop_count IN OUT NUMBER
	                     , p_exceptn_cnt IN OUT NUMBER
			     , p_cycle_date IN VARCHAR2
                             , p_errbuf  OUT VARCHAR2
                             , p_retcode OUT NUMBER ) ;
  PROCEDURE xx_purge_data (p_days_start_purge IN NUMBER) ;
  PROCEDURE xx_program_output (p_this_request_id IN NUMBER, p_file_count IN OUT NUMBER) ; 
  PROCEDURE xx_wrapper_pgm_status (p_this_request_id IN NUMBER
                                 , p_errbuf  OUT VARCHAR2
                                 , p_retcode OUT NUMBER ) ;

END XX_AR_STD_LBX_SUB_PKG;
/
SHOW ERR
