CREATE OR REPLACE PACKAGE XX_COM_CONV_ELEMENTS_PKG
AS
--+==============================================================================================+--
--| $HEADER  : XX_COM_CONV_ELEMENTS_PKG.pks                                                      |--
--|                                                                                              |--
--| NAME     : XX_COM_CONV_ELEMENTS_PKG.pks                                                      |--
--|                                                                                              |--
--| AUTHOR   : Nabarun Ghosh                                                                     |--
--|                                                                                              |--                                 |--
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

END XX_COM_CONV_ELEMENTS_PKG;
/
SHOW ERRORS
EXIT;