SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PURGE_COMN_ERROR_LOG_PKG
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                Oracle NAIO Consulting Organization                            |
-- +===============================================================================+
-- | Name        :  XX_PURGE_COMN_ERROR_LOG_PKG.pkb                                |
-- | Description :  This package will purge the records from the common            |
-- |                error log table                                                |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date           Author                      Remarks                   |
-- |========  =========== ================== ======================================|
-- |Draft 1A  12-SEP-2007  Ritu Shukla                  Initial Draft              |
-- |Draft 1B  13-SEP-2007  Ritu Shukla                  Updated after Review       |
-- |Draft 1C  19-MAR-2008  Jeevan Babu                  Removed the error flag     |
-- |                                                    Parameter refers from      |
-- |                                                    purge_common_error_log api |
-- |1.0       28-Apr-2008  Rajeev Kamath     Removed commented lines               |
-- |                                         Added procedure to delete by module   |
-- |                                         and optional program name             |
-- +===============================================================================+
AS

-- +===================================================================+
-- | Name             : display_out                                    |
-- | Description      : Local Procedure to print the log message in    |
-- |                    Log File                                       |
-- |                                                                   |
-- | Parameters :       p_message                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          None                                           |
-- |                                                                   |
-- +===================================================================+

PROCEDURE display_out (p_message VARCHAR2)
IS
BEGIN
    fnd_file.put_line(fnd_file.OUTPUT,p_message);
END;

-- +===================================================================+
-- | Name             : display_log                                    |
-- | Description      : Local procedure to print the output in out file|
-- |                                                                   |
-- | Parameters :       p_message                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          None                                           |
-- |                                                                   |
-- +===================================================================+

PROCEDURE display_log (p_message VARCHAR2)
IS
BEGIN
    fnd_file.put_line(fnd_file.LOG,p_message);
END;

-- +===================================================================+
-- | Name             : purge_common_error_log                         |
-- | Description      : Procedure to purge the data from common error  |
-- |                    log table on the bais of parameters provided.  |
-- |                                                                   |
-- | Parameters :       p_age                                          |
-- |                                                                   |
-- | Returns :          x_errbuf                                       |
-- |                    x_retcode                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE purge_common_error_log ( x_errbuf               OUT NOCOPY VARCHAR2
                                  ,x_retcode              OUT NOCOPY VARCHAR2
                                  ,p_age                  IN         NUMBER
                                 )
IS
------------------------------------------------
--Declaring local Exceptions and local Variables
------------------------------------------------   
ln_error_log_detail_count                   PLS_INTEGER;
ln_error_log_count                          PLS_INTEGER;
lc_error_message                            VARCHAR2(4000);

EX_DELETE_DETAIL                            EXCEPTION;
EX_DELETE_HEADER                            EXCEPTION;
BEGIN

    display_out(RPAD('Age               :',30,' ') || p_age);
    --display_out(RPAD('Error Status Flag :',30,' ') || p_error_status_flag);
    display_out('');

    --------------------------------------------------
    --Deleting data from xx_com_error_log_detail table
    -------------------------------------------------- 
    BEGIN
        DELETE   FROM xx_com_error_log_details XCELD
        WHERE    EXISTS (SELECT 1
                         FROM   XX_COM_ERROR_LOG XCEL
                         WHERE  XCEL.error_log_id       =  XCELD.error_log_id
                         AND    trunc(XCEL.last_update_date)  <=  trunc(SYSDATE - p_age)
--                         AND    XCEL.error_status_flag  =  NVL(p_error_status_flag,XCEL.error_status_flag)
--                         AND    XCEL.error_status_flag  IN ('LOG_ONLY', 'CLOSED')
                        );

        ln_error_log_detail_count := SQL%ROWCOUNT;
    EXCEPTION
    WHEN OTHERS THEN
        lc_error_message := 'Unexpected error while deleting records from the table XX_COM_ERROR_LOG_DETAILS. Error : '||SQLERRM;
        RAISE EX_DELETE_DETAIL;
    END;
    -------------------------------------------
    --Deleting data from xx_com_error_log table
    ------------------------------------------- 
    BEGIN
        DELETE FROM XX_COM_ERROR_LOG XCEL
        WHERE  trunc(XCEL.last_update_date) <= trunc(SYSDATE - p_age);
        --AND    XCEL.error_status_flag = NVL(p_error_status_flag,XCEL.error_status_flag)
        --AND    XCEL.error_status_flag  IN ('LOG_ONLY', 'CLOSED')
        ln_error_log_count := SQL%ROWCOUNT;
    EXCEPTION
        WHEN OTHERS THEN
            lc_error_message := 'Unexpected error while deleting records from the table XX_COM_ERROR_LOG_DETAILS. Error : '||SQLERRM;
            RAISE EX_DELETE_HEADER;
    END;

    display_out('Number of Records deleted from XX_COM_ERROR_LOG table          : '||ln_error_log_count );
    display_out('Number of Records deleted from XX_COM_ERROR_LOG_DETAILS table  : '||ln_error_log_detail_count );

COMMIT;
EXCEPTION
WHEN EX_DELETE_DETAIL THEN
    ROLLBACK;
    display_log(lc_error_message);

WHEN EX_DELETE_HEADER THEN
    ROLLBACK;
    display_log(lc_error_message);

WHEN OTHERS THEN 
    display_log('Unexpected error in Procedure PURGE_COMMON_ERROR_LOG Error: '||SQLERRM);
END purge_common_error_log;                                  


-- +===================================================================+
-- | Name             : purge_common_error_module_log                  |
-- | Description      : Procedure to purge the data from common error  |
-- |                    log table on the bais of parameters provided.  |
-- |                                                                   |
-- | Parameters :       p_age                                          |
-- |                    p_error_status_flag                            |
-- |                                                                   |
-- | Returns :          x_errbuf                                       |
-- |                    x_retcode                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE purge_common_error_module_log ( x_errbuf               OUT NOCOPY VARCHAR2
                                         ,x_retcode              OUT NOCOPY VARCHAR2
                                         ,p_module               IN         VARCHAR2
                                         ,p_program              IN         VARCHAR2
                                         ,p_age                  IN         NUMBER
                                        )
IS
------------------------------------------------
--Declaring local Exceptions and local Variables
------------------------------------------------   
ln_error_log_detail_count                   PLS_INTEGER;
ln_error_log_count                          PLS_INTEGER;
lc_error_message                            VARCHAR2(4000);

EX_DELETE_DETAIL                            EXCEPTION;
EX_DELETE_HEADER                            EXCEPTION;
BEGIN

    display_out(RPAD('Module               :',30,' ') || p_module);
    display_out(RPAD('Program              :',30,' ') || p_program);
    display_out(RPAD('Age                  :',30,' ') || p_age);
    display_out('');

    --------------------------------------------------
    --Deleting data from xx_com_error_log_detail table
    -------------------------------------------------- 
    BEGIN
        if (p_program is not null) then
            DELETE   FROM xx_com_error_log_details XCELD
            WHERE    EXISTS (SELECT 1
                             FROM   XX_COM_ERROR_LOG XCEL
                             WHERE  XCEL.error_log_id       =  XCELD.error_log_id
                             AND    trunc(XCEL.last_update_date)  <=  trunc(SYSDATE - p_age)
                             AND    module_name = p_module
                             and    program_name = p_program
                            );
         else
            DELETE   FROM xx_com_error_log_details XCELD
            WHERE    EXISTS (SELECT 1
                             FROM   XX_COM_ERROR_LOG XCEL
                             WHERE  XCEL.error_log_id       =  XCELD.error_log_id
                             AND    trunc(XCEL.last_update_date)  <=  trunc(SYSDATE - p_age)
                             AND    module_name = p_module
                            );             
         end if;
        ln_error_log_detail_count := SQL%ROWCOUNT;
    EXCEPTION
    WHEN OTHERS THEN
        lc_error_message := 'Unexpected error while deleting records from the table XX_COM_ERROR_LOG_DETAILS. Error : '||SQLERRM;
        RAISE EX_DELETE_DETAIL;
    END;
    -------------------------------------------
    --Deleting data from xx_com_error_log table
    ------------------------------------------- 
    BEGIN
        if (p_program is not null) then
            DELETE FROM XX_COM_ERROR_LOG XCEL
            WHERE  module_name = p_module
            and    program_name = p_program
            and    trunc(XCEL.last_update_date) <= trunc(SYSDATE - p_age);
        else
            DELETE FROM XX_COM_ERROR_LOG XCEL
            WHERE  module_name = p_module
            and    trunc(XCEL.last_update_date) <= trunc(SYSDATE - p_age);        
        end if;
        ln_error_log_count := SQL%ROWCOUNT;
    EXCEPTION
        WHEN OTHERS THEN
            lc_error_message := 'Unexpected error while deleting records from the table XX_COM_ERROR_LOG_DETAILS. Error : '||SQLERRM;
            RAISE EX_DELETE_HEADER;
    END;

    display_out('Number of Records deleted from XX_COM_ERROR_LOG table          : '||ln_error_log_count );
    display_out('Number of Records deleted from XX_COM_ERROR_LOG_DETAILS table  : '||ln_error_log_detail_count );

COMMIT;
EXCEPTION
WHEN EX_DELETE_DETAIL THEN
    ROLLBACK;
    display_log(lc_error_message);

WHEN EX_DELETE_HEADER THEN
    ROLLBACK;
    display_log(lc_error_message);

WHEN OTHERS THEN 
    display_log('Unexpected error in Procedure PURGE_COMMON_ERROR_LOG Error: '||SQLERRM);
END purge_common_error_module_log;                                  

END XX_PURGE_COMN_ERROR_LOG_PKG;
/
SHOW ERRORS

EXIT;
