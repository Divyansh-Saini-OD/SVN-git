create or replace
PACKAGE xx_hr_ps_full_sync AS
  -- +======================================================================+
  -- | Name        : xx_hr_ps_full_sync                        |
  -- | Author      : Mohan Kalyanasundaram                                  |
  -- | Description : This package is used for moving complete People Soft   |
  -- |               Data into Oracle HR staging table. This packages reads |
  -- |               a csv file from the directory XXFIN_IN_PSHR, processes |
  -- |               every line from the csv file. For every line in the csv|
  -- |               file, procedure XX_HR_PS_STG_INSERT_PKG.INSERT_PROC is |                                 |
  -- |               called to insert data into the HR staging table.       | 
  -- | Date        : June 20, 2012 --> New Version Started by Mohan         |
  -- +====================================================================+
    stop_run  exception;
    skip_line exception;
    G_INFILENAME varchar2(100) := 'ODOHR141_EMPDATA_FULLSYNC.CSV';

  PROCEDURE main_process
  (
     x_errbuf      OUT NOCOPY      VARCHAR2,
      x_retcode     OUT NOCOPY      NUMBER

  );

-- +====================================================================+
-- | Name        : process_line                                         |
-- | Description : This procedure is used for processing each line from |
-- |               csv file.                                            |
-- | Parameters  : p_line_data                                          |
-- +====================================================================+

  PROCEDURE process_line
    (p_line_data IN VARCHAR2);

-- +====================================================================+
-- | Name        : log_exception                                        |
-- | Description : This procedure is used for logging exceptions into   |
-- |               conversion common elements tables.                   |
-- |                                                                    |
-- | Parameters  : p_program_name,p_procedure_name,p_error_location     |
-- |               p_error_status,p_oracle_error_code,p_oracle_error_msg|
-- +====================================================================+

  PROCEDURE log_exception
    (p_program_name IN VARCHAR2,
    p_error_location IN VARCHAR2,
    p_error_status IN VARCHAR2,
    p_oracle_error_code IN VARCHAR2,
    p_oracle_error_msg IN VARCHAR2,
    p_error_message_severity IN VARCHAR2);

-- +====================================================================+
END xx_hr_ps_full_sync;
/
Show Errors
