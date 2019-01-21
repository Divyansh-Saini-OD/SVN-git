CREATE OR REPLACE PACKAGE XX_HR_PS_FULLSYNC_PKG AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- | Name:  XX_HR_PS_FULLSYNC_PKG                                                               |
-- | Description : This package is used for moving complete People Soft Data into Oracle HR     |
-- |		   staging table. Reads a txt file from the directory XXFIN_IN_PSHR, processes  |		
-- |               every line from the txt file. For every line in the txt file, procedure      | 
-- |               XX_HR_PS_STG_INSERT_PKG.INSERT_PROC is called to insert data into the        |
-- |               HR staging table.       			                                |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         08/14/2012   Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+

stop_run  	EXCEPTION;
skip_line 	EXCEPTION;
G_INFILENAME 	VARCHAR2(100) := 'ODOHR141_EMPDATA_FULLSYNC.txt';


-- +============================================================================================+
-- | Name        : main_process                                                                 |
-- | Description : This procedure is called from the concurrent program to process the data from| 
-- |               the txt file in unix directory XXFIN_IN_PSHR                                 |
-- |                                                                    		        |
-- | Parameters  : x_errbuf, x_retcode							        |
-- +============================================================================================+

PROCEDURE main_process ( x_errbuf      OUT NOCOPY      VARCHAR2
		        ,x_retcode     OUT NOCOPY      NUMBER
		       );

-- +============================================================================================+
-- | Name        : process_line                                                                 |
-- | Description : This procedure is used for processing each line from the txt file            |
-- | Parameters  : p_line_data                                                                  |
-- +============================================================================================+

PROCEDURE process_line (p_line_data IN VARCHAR2);

-- +============================================================================================+
-- | Name        : log_exception                                                                |
-- | Description : This procedure is used for logging exceptions into conversion common elements| 
-- |               tables                                                                       |
-- |                                                                    		        |
-- | Parameters  : p_program_name,p_procedure_name,p_error_location,p_error_status,             |
-- |               p_oracle_error_code,p_oracle_error_msg                                       |
-- +============================================================================================+

PROCEDURE log_exception ( p_program_name IN VARCHAR2
		         ,p_error_location IN VARCHAR2
		         ,p_error_status IN VARCHAR2
    			 ,p_oracle_error_code IN VARCHAR2
    			 ,p_oracle_error_msg IN VARCHAR2
    			 ,p_error_message_severity IN VARCHAR2
			);

END XX_HR_PS_FULLSYNC_PKG;
/
Show Errors
