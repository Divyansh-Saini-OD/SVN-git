SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating Package  XX_FA_MASS_ADJ_PKG
Prompt Program Exits If The Creation Is Not Successful
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace 
PACKAGE      XX_FA_MASS_ADJ_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_FA_MASS_ADJ_PKG.pkb	              	           |
-- | Description :  OD FA Mass Adjustment                              |
-- | RICEID      :  E3121                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       06-Jul-2015 Paddy Sanjeevi     Initial version           |
-- |1.0       06-Jul-2015 Madhu Bolli        Batch programming         |
-- +===================================================================+
AS
  --=================================================================
  -- Declaring Global variables
  --=================================================================
 gn_batch_size 		NUMBER;
 gn_threads    		NUMBER;  
  
PROCEDURE asset_adjust( x_errbuf      	OUT NOCOPY VARCHAR2
                       ,x_retcode     	OUT NOCOPY VARCHAR2
                       ,p_process_mode 	IN  VARCHAR2
                      ,p_book_type	IN  VARCHAR2
                      ,p_batch_id   IN  NUMBER
  		      );

PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode             OUT NOCOPY VARCHAR2
                     ,p_process_mode		     IN        VARCHAR2
            		     ,p_book_type            IN        VARCHAR2            		     
                     );                        

END XX_FA_MASS_ADJ_PKG;
/
SHOW ERRORS;