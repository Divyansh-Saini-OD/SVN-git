SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_COM_CONV_ELEMENTS_PKG
AS
-- +=================================================================================+
-- |                  Office Depot - Project Simplify                                |
-- |                Oracle NAIO Consulting Organization                              |
-- +=================================================================================+
-- | Name        :  XX_COM_CONV_ELEMENTS_PKG.pks                                     |
-- | Description :  OD Conversion Common Elements Package Spec                       |
-- |                                                                                 |
-- |Change Record:                                                                   |
-- |===============                                                                  |
-- |Version Date        Author               Remarks                                 |
-- |======= =========== ==================   ========================================|
-- |1.0     04-Sep-2006 Nabarun Ghosh        Initial draft version                   |
-- |1.1     08-Mar-2007 Ambarish Mukherjee   Added parameter p_record_control_id     |
-- |                                         in procedure log_exceptions_proc        |
-- |1.2     22-May-2007 Senthil Jayachandran Added procedures Initialize,Add_Message |
-- |                                         and Log_message                         |
-- |1.3     28-May-2007 Ambarish Mukherjee   Renamed above procedures. Added proc    |
-- |                                         insert_conversion_info                  |
-- +=================================================================================+

  -----------------------------------------------------
  -- Procedure to Log Conversion Control Informations.-
  -----------------------------------------------------

  PROCEDURE log_control_info_proc
         (  p_conversion_id          IN NUMBER
           ,p_batch_id               IN NUMBER
           ,p_num_bus_objs_processed IN NUMBER
         );
 
  -----------------------------------------------------
  /*Procedure to Update Conversion Control Informations.*/ 
  -----------------------------------------------------

  PROCEDURE upd_control_info_proc
         (  p_conc_mst_req_id              IN NUMBER  := APPS.FND_GLOBAL.CONC_REQUEST_ID
           ,p_batch_id                     IN NUMBER
           ,p_conversion_id                IN NUMBER
           ,p_num_bus_objs_failed_valid    IN VARCHAR2
           ,p_num_bus_objs_failed_process  IN VARCHAR2
           ,p_num_bus_objs_succ_process    IN VARCHAR2
         );
  --------------------------------------------
  /* Procedure to Log Conversion Exceptions */
  --------------------------------------------

  PROCEDURE log_exceptions_proc
         (  p_conversion_id          IN NUMBER
           ,p_record_control_id      IN NUMBER 
           ,p_source_system_code     IN VARCHAR2
           ,p_package_name           IN VARCHAR2
           ,p_procedure_name         IN VARCHAR2
           ,p_staging_table_name     IN VARCHAR2
           ,p_staging_column_name    IN VARCHAR2
           ,p_staging_column_value   IN VARCHAR2
           ,p_source_system_ref      IN VARCHAR2
           ,p_batch_id               IN NUMBER
           ,p_exception_log          IN VARCHAR2
           ,p_oracle_error_code      IN VARCHAR2
           ,p_oracle_error_msg       IN VARCHAR2
         );

--------------------------------------------------------------------------------------------------
-- Procedure to initialize global message table  
-- Usage : Used by API callers and developers to intialize the global message table.
--         Clears the G_msg_tbl and resets all its global variables except for the message level threshold.
--------------------------------------------------------------------------------------------------

PROCEDURE bulk_table_initialize;

TYPE msg_tbl_type IS TABLE OF xx_com_exceptions_log_conv%ROWTYPE
INDEX BY BINARY_INTEGER;

------------------------------------------------------------------------
-- Global message table variable.
-- this variable is global to the XX_COM_CONV_ELEMENTS_PKG package only.
------------------------------------------------------------------------

g_msg_tbl     msg_tbl_type;
g_msg_count   NUMBER      := 0;

------------------------------------------------------------
-- Procedure to add log message to the global message table
------------------------------------------------------------

PROCEDURE bulk_add_message 
      (  p_msg_rec IN xx_com_exceptions_log_conv%ROWTYPE  );

----------------------------------------------------------------------------------------
-- Procedure to bulk insert log messages from global message table to Common conv Tables
----------------------------------------------------------------------------------------

PROCEDURE bulk_log_message;

-- +===================================================================+
-- | Name        :  insert_conversion_info                             |
-- | Description :  Used to insert conversion RICE details into the    |
-- |                table xx_com_conversions_conv.                     |
-- |                                                                   |
-- | Parameters  :  none                                               |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE insert_conversion_info
   (   p_conversion_code         VARCHAR2
      ,p_batch_size              NUMBER
      ,p_exception_threshold     NUMBER
      ,p_max_threads             NUMBER
      ,p_extract_or_load         VARCHAR2
      ,p_system_code             VARCHAR2
   );
END XX_COM_CONV_ELEMENTS_PKG;
/
SHOW ERRORS
EXIT;