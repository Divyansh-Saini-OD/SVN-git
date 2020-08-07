CREATE OR REPLACE PACKAGE BODY XX_COM_CONV_ELEMENTS_PKG
AS
--+==============================================================================================+--
--| $HEADER  : XX_COM_CONV_ELEMENTS_PKG.pkb                                                      |--
--|                                                                                              |--
--| NAME     : XX_COM_CONV_ELEMENTS_PKG.pkb                                                      |--
--|                                                                                              |--
--| AUTHOR   : Nabarun Ghosh                                                                     |--
--|                                                                                              |--
--| DESCRIPTION  : OD Conversion Common Elements Package                                         |--
--| NOTES        :                                                                               |--
--|                                                                                              |--
--+==============================================================================================+--
--| VERSION DATE         CHANGED BY                    DESCRIPTION                               |--
--+==============================================================================================+--
--| 1.0     04/09/2006   Nabarun Ghosh                  Initial                                  |--
--| 1.1     08-Mar-2007  Ambarish Mukherjee             Added parameter p_record_control_id      |--
--|                                                     in procedure log_exceptions_proc         |--
--+==============================================================================================+--


--Global variable declaration
-----------------------------

l_control_info_id        NUMBER;
l_exception_id           NUMBER;

-----------------------------------------------------
/*Procedure to Log Conversion Control Informations.*/
-----------------------------------------------------

PROCEDURE log_control_info_proc
   (  p_conversion_id          IN NUMBER
     ,p_batch_id               IN NUMBER
     ,p_num_bus_objs_processed IN NUMBER
   )
IS 
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

        ----------------------------------
        /* Deriving the Control Info Id */
        ----------------------------------

        SELECT xx_control_info_id_s1.nextval
        INTO   l_control_info_id 
        FROM   DUAL;

        ----------------------------------------------------------
        /* Insert into Conversion Control Information Log table */
        ----------------------------------------------------------

        INSERT INTO xx_com_control_info_conv
            (   Control_Info_Id          /* Unique Primary Key */
               ,Conversion_Id
               ,Batch_Id
               ,Creation_Date
               ,Last_Update_Date
               ,Master_Request_Id
               ,Num_Bus_Objs_Processed
            )
        VALUES
            (   l_control_info_id
               ,p_conversion_id
               ,p_batch_id
               ,SYSDATE
               ,SYSDATE
               ,APPS.FND_GLOBAL.CONC_REQUEST_ID
               ,p_num_bus_objs_processed
            );


COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,'Unable to insert record into OD_COM_CONTROL_INFO_CONV table: '|| SQLERRM);
END log_control_info_proc;

-----------------------------------------------------
/*Procedure to Update Conversion Control Informations.*/ 
-----------------------------------------------------

PROCEDURE upd_control_info_proc(
                                p_conc_mst_req_id                IN  NUMBER  := APPS.FND_GLOBAL.CONC_REQUEST_ID
                               ,p_batch_id                       IN  NUMBER
                               ,p_conversion_id                  IN  NUMBER
                               ,p_num_bus_objs_failed_valid      IN  VARCHAR2
                               ,p_num_bus_objs_failed_process    IN  VARCHAR2
                               ,p_num_bus_objs_succ_process      IN  VARCHAR2 
                               ) 
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN


        ------------------------------------------------------
        /* Update Conversion Control Information Log table  */
        ------------------------------------------------------

             UPDATE xx_com_control_info_conv
             SET    Num_Bus_Objs_Failed_Valid      = p_num_bus_objs_failed_valid
                   ,Num_Bus_Objs_Failed_Process    = p_num_bus_objs_failed_process
                   ,Num_Bus_Objs_Succeeded_Process = p_num_bus_objs_succ_process
                   ,Request_id                     = APPS.FND_GLOBAL.CONC_REQUEST_ID
                   ,Last_Update_Date               = SYSDATE 
             WHERE  Master_Request_Id              = p_conc_mst_req_id
             AND    Conversion_Id                  = p_conversion_id
             AND    Batch_Id                       = p_batch_id;

COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,'Unable to update record into OD_COM_CONTROL_INFO_CONV table: '|| SQLERRM);  
END upd_control_info_proc;

--------------------------------------------
/* Procedure to Log Conversion Exceptions */
--------------------------------------------

PROCEDURE log_exceptions_proc
      (   p_conversion_id          IN  NUMBER
         ,p_record_control_id      IN  NUMBER 
         ,p_source_system_code     IN  VARCHAR2
         ,p_package_name           IN  VARCHAR2
         ,p_procedure_name         IN  VARCHAR2
         ,p_staging_table_name     IN  VARCHAR2
         ,p_staging_column_name    IN  VARCHAR2
         ,p_staging_column_value   IN  VARCHAR2
         ,p_source_system_ref      IN  VARCHAR2
         ,p_batch_id               IN  NUMBER  
         ,p_exception_log          IN  VARCHAR2
         ,p_oracle_error_code      IN  VARCHAR2
         ,p_oracle_error_msg       IN  VARCHAR2
      ) 
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

        ----------------------------------
        /* Deriving the Exception Id */
        ----------------------------------
   
        SELECT xx_exception_id_s1.nextval       
        INTO   l_exception_id
        FROM   DUAL;
                    
        -------------------------------------------------
        /* Insert into Conversion Exception Log table */
        -------------------------------------------------
          
        INSERT INTO xx_com_exceptions_log_conv
           (   Exception_Id 
              ,Converion_Id
              ,Record_control_id
              ,Request_Id
              ,Log_Date
              ,Source_System_Code
              ,Package_Name
              ,Procedure_Name
              ,Staging_Table_Name
              ,Staging_Column_Name
              ,Staging_Column_Value
              ,Source_System_Ref
              ,Batch_Id
              ,Exception_Log
              ,Oracle_Error_Code
              ,Oracle_Error_Msg
           )
        VALUES
           (   l_exception_id 
              ,p_conversion_id
              ,p_record_control_id
              ,APPS.FND_GLOBAL.CONC_REQUEST_ID
              ,SYSDATE
              ,p_source_system_code
              ,p_package_name
              ,p_procedure_name
              ,p_staging_table_name
              ,p_staging_column_name
              ,p_staging_column_value
              ,p_source_system_ref 
              ,p_batch_id 
              ,p_exception_log 
              ,p_oracle_error_code
              ,p_oracle_error_msg
           );
COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,'Unable to insert record into XX_COM_EXCEPTIONS_LOG_CONV table: '|| SQLERRM);  
END log_exceptions_proc;

END XX_COM_CONV_ELEMENTS_PKG;
/
SHOW ERRORS
EXIT;