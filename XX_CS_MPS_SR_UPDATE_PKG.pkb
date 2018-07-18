CREATE OR REPLACE PACKAGE BODY xx_cs_mps_sr_update_pkg
AS

--+=============================================================================================+
--/*                     Office Depot - MPS SR Update process                                                 
--/*                                                                                             
-- +=============================================================================================+
--/* Name         : xx_cs_mps_sr_update_pkg.pkb                                                      
--/*Description  : This package is used to update the Status on MPS Service request once the corresponding PO has been closed  
--/*               
--/*  Revision History:
--/*
--/*  Date         By                   Description of Revision
--/*  19-SEP-2013  Arun Gannarapu       Initial Creation
--/*                                                                                     
-- +=============================================================================================+

  --**************************************************************************/
  --* Description: Log the exceptions
  --**************************************************************************/
  
  
  ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
  ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;
  lc_program_name      VARCHAR2(100) := 'XX_CS_MPS_SR_UPDATE_PKG';
  
  
  PROCEDURE log_error (p_object_id     IN VARCHAR2,
                       p_error_msg     IN VARCHAR2)
   IS
   BEGIN
      xx_com_error_log_pub.log_error (p_return_code                 => fnd_api.g_ret_sts_error
                                    , p_msg_count                   => 1
                                    , p_application_name            => 'XX_CS'
                                    , p_program_type                => 'ERROR'
                                    , p_program_name                => lc_program_name
                                    , p_attribute15                 => lc_program_name        --------index exists on attribute15
                                    , p_program_id                  => NULL
                                    , p_object_id                   => p_object_id
                                    , p_module_name                 => 'MPS'
                                    , p_error_location              => NULL --p_error_location
                                    , p_error_message_code          => NULL --p_error_message_code
                                    , p_error_message               => p_error_msg
                                    , p_error_message_severity      => 'MAJOR'
                                    , p_error_status                => 'ACTIVE'
                                    , p_created_by                  => ln_user_id
                                    , p_last_updated_by             => ln_user_id
                                    , p_last_update_login           => ln_login
                                     );
   END log_error;
   
 --/*************************************************************
 --* This function logs message
 --*************************************************************/
 
  PROCEDURE log_msg(
    p_log_flag IN BOOLEAN DEFAULT FALSE,
    p_string   IN VARCHAR2)
  IS
  BEGIN
    IF (p_log_flag)
    THEN
      fnd_file.put_line(fnd_file.LOG,  p_string);
      DBMS_OUTPUT.put_line(SUBSTR(p_string, 1, 250));
      
      XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCS'
      ,p_program_type            => 'DEBUG'              --------index exists on program_type
      ,p_attribute15             => lc_program_name         --------index exists on attribute15
      ,p_program_name           => lc_program_name
      ,p_program_id              => 0
      ,p_module_name             => 'MPS'                --------index exists on module_name
      ,p_error_message           => p_string
      ,p_error_message_severity  => 'LOG'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => NULL --ln_login
      );
    END IF;
  END log_msg;

   /*******************************************************************************
  ||   Filename    :
  ||   Description:
  ||------------------------------------------------------------------------------
  ||   Ver  Date          Author            Modification
  --------------------------------------------------------------------------------
  ||   0.1  Sep 10th, 2013  Arun Gannarapu  Initial creation.
  ||------------------------------------------------------------------------------
  ||
  ||   Usage : Public
  ||
  ******************************************************************************/
 -- +=============================================================================================+
   -- Procedure    : Update SR 
   -- Description : This is the Main Procedure to update the SR status once the PO is closed. 
   -- Triggered from Concurrent manager .
-- +=============================================================================================+/
  PROCEDURE Update_SR(errbuf               OUT VARCHAR2,
                      retcode              OUT NUMBER,
                      p_po_number          IN  po_headers_all.segment1%TYPE,
                      p_debug_flag         IN  VARCHAR2)
  IS
  
   lc_error_message           xx_com_error_log.error_message%TYPE;
   lc_return_status           VARCHAR2(100);
   lr_po_lines_rec            po_lines_all%ROWTYPE := NULL;
   lc_incident_number         cs_incidents_all_b.incident_number%TYPE := NULL;
   lc_debug_flag              BOOLEAN;
   
   -- Get aall the POs which are closed and SR is open
   
   CURSOR cur_sr (p_po_number po_headers_all.segment1%TYPE)
   IS
   SELECT csi.incident_id, csi.incident_number,ph.po_header_id , ph.segment1
   FROM po_headers_all ph,
        cs_incidents_all_b csi
   WHERE csi.incident_number = ph.segment1
   AND ph.segment1 = NVL(p_po_number, ph.segment1)
   AND ph.attribute_category  = 'Non-Trade MPS'
   AND ph.attribute1 = 'NA-MPS'
   AND ph.closed_code = 'CLOSED'
   AND csi.incident_status_id != 2 ;
 
   e_process_exception EXCEPTION;
   
   ln_resp_appl_id    NUMBER :=  514;
   ln_resp_id         NUMBER := 21739;
   ln_user_id         NUMBER ;
      

  BEGIN 
  
    IF (p_debug_flag = 'Y') -- Debug flag 
    THEN
      lc_debug_flag  := TRUE ;
    ELSE
      lc_debug_flag  := FALSE ;
    END IF;
        
    BEGIN
      SELECT user_id
      INTO ln_user_id
      FROM fnd_user
      WHERE user_name = 'CS_ADMIN' ; --'641633'; --CS_ADMIN';
    EXCEPTION
      WHEN OTHERS THEN
        null; --x_return_status := 'F';
    END;

  
    FOR cur_sr_rec IN cur_sr(p_po_number => p_po_number)
    LOOP
      BEGIN
        log_msg(lc_debug_flag ,  'Processing request for PO :'|| cur_sr_rec.segment1 || ' Service request number '|| cur_sr_rec.incident_number); 
        
        log_msg(lc_debug_flag , 'Calling update SR for incident id :'|| cur_sr_rec.incident_id);
        
        fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);
       
        XX_CS_MPS_UTILITIES_PKG.UPDATE_SR_STATUS(P_REQUEST_ID       => cur_sr_rec.incident_id, 
                                                 P_REQUEST_NUMBER   => cur_sr_rec.incident_number, 
                                                 P_STATUS_ID        => 2, 
                                                 P_STATUS           => NULL, --'Closed' ,
                                                 X_RETURN_STATUS    => lc_return_status,
                                                 X_RETURN_MSG       => lc_error_message);
                                                 
        log_msg(lc_debug_flag , 'API return status: '|| lc_return_status );                                                 
                                                 
        IF lc_return_status != FND_API.G_RET_STS_SUCCESS
        THEN
         RAISE e_process_exception;
        END IF;        
        
        COMMIT ; -- commit the changes          
      EXCEPTION 
        WHEN OTHERS 
        THEN 
          ROLLBACK;
          IF lc_error_message IS NULL
          THEN 
            lc_error_message := 'Error while updating the status for SR '|| cur_sr_rec.incident_number||SQLERRM ;
          END IF;
           log_error(p_object_id      => cur_sr_rec.incident_number,
                     p_error_msg      => lc_error_message);
           log_msg(TRUE, lc_error_message);                     
                     
           errbuf := lc_error_message;                     
      END;                     
    END LOOP;
  EXCEPTION 
    WHEN OTHERS 
    THEN
      ROLLBACK;
      IF lc_error_message IS NULL
      THEN 
        lc_error_message := 'Error while updating the status for SR '|| lc_incident_number ;
      END IF;
      log_error(p_object_id      => lc_incident_number,
                p_error_msg      => lc_error_message);
                
      log_msg(TRUE, lc_error_message);                     
                  
   END update_sr;
 
END xx_cs_mps_sr_update_pkg;

/
show errors;
exit;     