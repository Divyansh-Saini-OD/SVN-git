SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_COM_CONV_ELEMENTS_PKG
AS
-- +=================================================================================+
-- |                  Office Depot - Project Simplify                                |
-- |                Oracle NAIO Consulting Organization                              |
-- +=================================================================================+
-- | Name        :  XX_COM_CONV_ELEMENTS_PKG.pkb                                     |
-- | Description :  OD Conversion Common Elements Package Body                       |
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

-------------------------------
--Global variable declaration
-------------------------------

l_control_info_id        NUMBER;
l_exception_id           NUMBER;

-- +===================================================================+
-- | Name        :  log_control_info_proc                              |
-- | Description :  Used by API callers and developers to insert conv  |
-- |                control information into xx_comn_control_info_conv |
-- |                                                                   |
-- | Parameters  :  Conversion_id, Batch_id, num_bus_objs_processed    |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE log_control_info_proc
   (  p_conversion_id          IN NUMBER
     ,p_batch_id               IN NUMBER
     ,p_num_bus_objs_processed IN NUMBER
   )
IS 
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

   ----------------------------------------------------------
   /* Insert into Conversion Control Information Log table */
   ----------------------------------------------------------

   INSERT INTO xx_com_control_info_conv
       (   control_info_id          /* unique primary Key */
          ,conversion_id
          ,batch_id
          ,creation_date
          ,last_update_date
          ,master_request_id
          ,num_bus_objs_processed
       )
   VALUES
       (   xx_control_info_id_s1.nextval
          ,p_conversion_id
          ,p_batch_id
          ,SYSDATE
          ,SYSDATE
          ,apps.fnd_global.conc_request_id
          ,p_num_bus_objs_processed
       );

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      apps.fnd_file.put_line(apps.fnd_file.log,'Unable to insert record into OD_COM_CONTROL_INFO_CONV table: '|| SQLERRM);
END log_control_info_proc;

-- +===================================================================+
-- | Name        :  log_control_info_proc                              |
-- | Description :  Used by API callers and developers to update conv  |
-- |                control information into xx_comn_control_info_conv |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE upd_control_info_proc
   (  p_conc_mst_req_id              IN NUMBER  := apps.fnd_global.conc_request_id
     ,p_batch_id                     IN NUMBER
     ,p_conversion_id                IN NUMBER
     ,p_num_bus_objs_failed_valid    IN VARCHAR2
     ,p_num_bus_objs_failed_process  IN VARCHAR2
     ,p_num_bus_objs_succ_process    IN VARCHAR2
   )
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

   ---------------------------------------------------
   -- Update Conversion Control Information Log table 
   ---------------------------------------------------

   UPDATE xx_com_control_info_conv
   SET    num_bus_objs_failed_valid      = p_num_bus_objs_failed_valid
         ,num_bus_objs_failed_process    = p_num_bus_objs_failed_process
         ,num_bus_objs_succeeded_process = p_num_bus_objs_succ_process
         ,request_id                     = apps.fnd_global.conc_request_id
         ,last_update_date               = SYSDATE 
   WHERE  master_request_id              = p_conc_mst_req_id
   AND    conversion_id                  = p_conversion_id
   AND    batch_id                       = p_batch_id;

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      apps.fnd_file.put_line(apps.fnd_file.log,'Unable to update record into OD_COM_CONTROL_INFO_CONV table: '|| SQLERRM);  
END upd_control_info_proc;

-- +===================================================================+
-- | Name        :  log_exceptions_proc                                |
-- | Description :  Used by API callers and developers to log the      |
-- |                exceptions into xx_com_exceptions_log_conv         |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE log_exceptions_proc
      (   p_conversion_id          IN NUMBER
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
      ) 
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

   ----------------------------------------------
   -- Insert into Conversion Exception Log table
   ----------------------------------------------
   INSERT INTO xx_com_exceptions_log_conv
      (   exception_id 
         ,converion_id
         ,record_control_id
         ,request_id
         ,log_date
         ,source_system_code
         ,package_name
         ,procedure_name
         ,staging_table_name
         ,staging_column_name
         ,staging_column_value
         ,source_system_ref
         ,batch_id
         ,exception_log
         ,oracle_error_code
         ,oracle_error_msg
      )
   VALUES
      (   xx_exception_id_s1.NEXTVAL
         ,p_conversion_id
         ,p_record_control_id
         ,apps.fnd_global.conc_request_id
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
      apps.fnd_file.put_line(apps.fnd_file.log,'Unable to insert record into XX_COM_EXCEPTIONS_LOG_CONV table: '|| SQLERRM);  
END log_exceptions_proc;

-- +===================================================================+
-- | Name        :  bulk_table_initialize                              |
-- | Description :  Used by API callers and developers to intialize    |
-- |                the global message table.Clears the G_msg_tbl and  |
-- |                resets all its global variables except for the     |
-- |                message level threshold.                           |
-- |                                                                   |
-- | Parameters  :  None                                               |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE bulk_table_initialize
IS
BEGIN
   g_msg_tbl.DELETE;
   g_msg_count := 0;
EXCEPTION
   WHEN OTHERS THEN
      apps.fnd_file.put_line(apps.fnd_file.log,'Unable to clear Error Message Stack Table in  Package XX_COM_CONV_ELEMENTS_PKG.bulk_table_initialize: '|| SQLERRM);  
END bulk_table_initialize;

-- +===================================================================+
-- | Name        :  bulk_add_message                                   |
-- | Description :  Used to add messages to the global message table.  |
-- |                The message is appended at the bottom of the       |
-- |                message table.                                     |
-- |                                                                   |
-- | Parameters  :  p_msg_rec                                          |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE bulk_add_message 
      (  p_msg_rec in xx_com_exceptions_log_conv%ROWTYPE  )
IS
BEGIN

   --------------------------
   --Increment message count
   --------------------------
   g_msg_count := g_msg_count + 1;

   ----------------------------
   --Copy Record type to stack.
   ----------------------------
   g_msg_tbl(g_msg_count) := p_msg_rec;

   -----------------------------
   -- Deriving the Exception Id 
   -----------------------------
   SELECT xx_exception_id_s1.nextval
   INTO   g_msg_tbl(g_msg_count).exception_id
   FROM   DUAL;

EXCEPTION
   WHEN OTHERS THEN
      apps.fnd_file.put_line(apps.fnd_file.log,'Unable to Set the Error Message Stack Table in  Package XX_COM_CONV_ELEMENTS_PKG.bulk_add_message: '|| SQLERRM);  
END bulk_add_message;

-- +===================================================================+
-- | Name        :  bulk_log_message                                   |
-- | Description :  Used to insert messages from global message table  |
-- |                into the database table for conversion common      |
-- |                elements.                                          |
-- |                                                                   |
-- | Parameters  :  none                                               |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE bulk_log_message 
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

   IF g_msg_tbl.count > 0 THEN

      FORALL i IN g_msg_tbl.FIRST..g_msg_tbl.LAST
      INSERT INTO xx_com_exceptions_log_conv
      VALUES g_msg_tbl(i);

      COMMIT;

      bulk_table_initialize;

   END IF;

EXCEPTION
   WHEN OTHERS THEN
      apps.fnd_file.put_line(apps.fnd_file.log,'Unable to insert record into XX_COM_EXCEPTIONS_LOG_CONV table in Package XX_COM_CONV_ELEMENTS_PKG.bulk_log_message: '|| SQLERRM);  
END bulk_log_message;

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
   )
IS
BEGIN

   INSERT INTO xx_com_conversions_conv
      (   conversion_id
         ,conversion_code
         ,batch_size
         ,exception_threshold
         ,max_threads
         ,extract_or_load
         ,system_code
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_updated_date
      )
   VALUES
      (   xx_com_conversions_conv_s1.NEXTVAL
         ,p_conversion_code
         ,p_batch_size
         ,p_exception_threshold
         ,p_max_threads
         ,p_extract_or_load
         ,p_system_code
         ,apps.fnd_global.user_id
         ,SYSDATE
         ,apps.fnd_global.login_id
         ,SYSDATE
      );
   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      apps.fnd_file.put_line(apps.fnd_file.log,'Unable to insert record into xx_com_conversions_conv table : '|| SQLERRM);
END insert_conversion_info;
END XX_COM_CONV_ELEMENTS_PKG;
/
SHOW ERRORS
EXIT;