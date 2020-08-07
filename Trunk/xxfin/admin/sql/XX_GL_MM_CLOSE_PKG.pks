SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package  XX_GL_MM_CLOSE_PKG

Prompt Program Exits If The Creation Is Not Successful

WHENEVER SQLERROR CONTINUE
create or replace 
PACKAGE  XX_GL_MM_CLOSE_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             : XX_GL_MM_CLOSE_PKG                                   |
-- | Description      : This Program contains procedures which run for the   |
-- |                   Midmonth Financial Project                            |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    20-Mar-2015   Madhu Bolli       Initial code                  |
-- +=========================================================================+ 
 AS

  --=================================================================
  -- Declaring Global variables
  --================================================================= 

  PROCEDURE shift_fin_gl_cal ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_account_cal		IN  VARCHAR2
				    ,p_acq_period	IN  VARCHAR2
				    ,p_od_last_day		IN  VARCHAR2
				    ,p_next_period		IN  VARCHAR2
				    ,p_next_per_start_date		IN  VARCHAR2
            ,p_us_ledger      IN  NUMBER
            ,p_can_ledger     IN  NUMBER
            ,p_ledger_set     IN  NUMBER            
            ,p_is_preview     IN  VARCHAR2
	    		);

  PROCEDURE shift_fin_gl_data_maps ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_account_cal		IN  VARCHAR2
				    ,p_next_period		IN  VARCHAR2
            ,p_new_next_per_start_date IN  VARCHAR2
            ,p_next_per_start_date		 IN  VARCHAR2
            ,p_is_preview     IN  VARCHAR2
	    		);
                 
  PROCEDURE shift_fin_gl_je_bat ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
            ,p_ledger_id      IN  NUMBER    
				    ,p_acq_period	    IN  VARCHAR2
				    ,p_jou_eff_date_from		IN  VARCHAR2
				    ,p_jou_eff_date_to		IN  VARCHAR2
				    ,p_new_jou_eff_date		IN  VARCHAR2
            ,p_is_preview     IN  VARCHAR2
	    		);
                    
  PROCEDURE shift_fin_inv_cal ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_account_cal		IN  VARCHAR2
				    ,p_acq_period	IN  VARCHAR2
				    ,p_od_last_day		IN  VARCHAR2
            ,p_is_preview     IN  VARCHAR2
	    		);

  PROCEDURE shift_fin_pa_cal ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_acq_period	IN  VARCHAR2
				    ,p_od_last_day		IN  VARCHAR2
				    ,p_next_period		IN  VARCHAR2
				    ,p_next_per_start_date		IN  VARCHAR2
            ,p_is_preview     IN  VARCHAR2
	    		);  

  PROCEDURE shift_fin_fa_depr_cal ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_fa_depr_cal		IN  VARCHAR2
				    ,p_acq_period	IN  VARCHAR2
				    ,p_od_last_day		IN  VARCHAR2
				    ,p_next_period		IN  VARCHAR2
				    ,p_next_per_start_date		IN  VARCHAR2
            ,p_is_preview     IN  VARCHAR2
	    		);

  PROCEDURE shift_fin_fa_pror_conv_cal ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
				    ,p_prorate_convention_type		IN  VARCHAR2
				    ,p_from_date	IN  VARCHAR2
				    ,p_new_to_date		IN  VARCHAR2
				    ,p_new_prorate_date		IN  VARCHAR2
				    ,p_next_per_from_date		IN  VARCHAR2
				    ,p_next_new_start_date		IN  VARCHAR2
				    ,p_next_new_prorate_date		IN  VARCHAR2            
            ,p_is_preview     IN  VARCHAR2
	    		);          
                            

END XX_GL_MM_CLOSE_PKG;
/
SHOW ERRORS