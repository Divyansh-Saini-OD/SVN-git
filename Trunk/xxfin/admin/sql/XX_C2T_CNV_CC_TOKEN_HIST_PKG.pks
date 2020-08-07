	SET SHOW OFF
	SET VERIFY OFF
	SET ECHO OFF
	SET TAB OFF
	SET FEEDBACK OFF
	SET TERM ON

	PROMPT Creating PACKAGE xx_c2t_cnv_cc_token_hist_pkg

	PROMPT Program exits IF the creation IS NOT SUCCESSFUL

	WHENEVER SQLERROR CONTINUE

	CREATE OR REPLACE PACKAGE xx_c2t_cnv_cc_token_hist_pkg IS
	---+============================================================================================+
	---|                              Office Depot                                                  |
	---+============================================================================================+
	---|    Application     : AR                                                                    |
	---|                                                                                            |
	---|    Name            : XX_C2T_CNV_CC_TOKEN_HIST_PKG.pks                                       |
	---|                                                                                            |
	---|    Description     :                                                                       |
	---|                                                                                            |
	---|                                                                                            |
	---|                                                                                            |
	---|    Change Record                                                                           |
	---|    ---------------------------------                                                       |
	---|    Version         DATE              AUTHOR             DESCRIPTION                        |
	---|    ------------    ----------------- ---------------    ---------------------              |
	---|    1.0             13-AUG-2015       Harvinder Rakhra   Initial Version                    |
	---|                                                                                            |
	---+============================================================================================+

					  
	   PROCEDURE prepare_master ( x_errbuf               OUT NOCOPY       VARCHAR2
							    , x_retcode              OUT NOCOPY       NUMBER
							    , p_child_threads        IN PLS_INTEGER   DEFAULT 10
							    , p_processing_type      IN VARCHAR2      DEFAULT 'ALL'
							    , p_recreate_child_thrds IN VARCHAR2      DEFAULT 'N'
							    , p_batch_size           IN PLS_INTEGER   DEFAULT 10000
							    , p_debug_flag           IN VARCHAR2      DEFAULT 'N'
                                );

	   PROCEDURE prepare_child ( x_errbuf                   OUT NOCOPY      VARCHAR2
						       , x_retcode                  OUT NOCOPY      NUMBER
						       , p_child_threads            IN              NUMBER
						       , p_child_thread_num         IN              NUMBER
						       , p_processing_type          IN              VARCHAR2     DEFAULT 'ALL'
						       , p_min_hist_id              IN              NUMBER
						       , p_max_hist_id              IN              NUMBER
						       , p_batch_size               IN              PLS_INTEGER   DEFAULT 10000
						       , p_debug_flag               IN              VARCHAR2      DEFAULT 'N'
                               );

								   
	  END xx_c2t_cnv_cc_token_hist_pkg;
	/
	SHOW ERROR