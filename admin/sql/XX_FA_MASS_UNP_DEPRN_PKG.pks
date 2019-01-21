SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating Package  XX_FA_MASS_UNP_DEPRN_PKG
Prompt Program Exits If The Creation Is Not Successful
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace 
PACKAGE      XX_FA_MASS_UNP_DEPRN_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_FA_MASS_UNP_DEPRN_PKG.pkb	               |
-- | Description :  OD FA Mass Adjustment                              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       16-Jul-2015 Madhu Bolli        Initial version           |
-- |1.1       28-Aug-2015 Paddy Sanjeevi     Defect 35674              |
-- |1.2       25-Sep-2015 Paddy Sanjeevi     Multi-threading           |
-- +===================================================================+
AS
  --=================================================================
  -- Declaring Global variables
  --=================================================================


G_AMORTZ_FLAG		VARCHAR2(3);
G_trx_date 		DATE;
G_cal_per_close_date 	DATE;  

gn_batch_size 		NUMBER;
gn_threads    		NUMBER;  
  
PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode             OUT NOCOPY VARCHAR2
                     ,p_process_mode		     IN        VARCHAR2
         		     ,p_book_type            IN        VARCHAR2            		     
                     );                        


PROCEDURE fa_unplanned_depreciation( x_errbuf      	OUT NOCOPY VARCHAR2
          			               ,x_retcode     	OUT NOCOPY VARCHAR2                      
                     		  	    ,p_process_mode 	IN  VARCHAR2
					 	                   ,p_book_type	IN  VARCHAR2                       	
		                         ,p_batch_id   IN  NUMBER
  		   				  );

END;
/
SHOW ERRORS;