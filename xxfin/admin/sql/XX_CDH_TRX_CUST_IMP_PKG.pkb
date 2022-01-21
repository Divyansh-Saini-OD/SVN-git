create or replace 
package  body XX_CDH_TRX_CUST_IMP_PKG
as

  -------------------------------
  -- global variable
  -------------------------------
  g_chr_errbuf  VARCHAR2(200):='COMPLETE NORMAL';
  g_num_retcode NUMBER       :=0;
  --
  -- This variable holds the request id of the concurrent program
  --
  g_num_request_id NUMBER (15) := Fnd_Global.conc_request_id;
  --
  -- This variable holds the user_id of the current user
  --
  g_num_user_id NUMBER (15) := Fnd_Global.user_id;
  --
  -- This variable holds the login_id of the current user
  --
  g_num_login_id NUMBER (15) := Fnd_Global.conc_login_id;
  --
  -- This variable holds the Program Application Id
  --
  g_num_program_appl_id NUMBER (15) := Fnd_Global.prog_appl_id;--
  -- This variable holds the Program Id
  --
  g_num_program_id NUMBER (15) := Fnd_Global.conc_program_id;
  --
  -- This variable holds the System Date
  --
  g_dat_sys_date DATE := SYSDATE;
  --
  --
  vCounter   NUMBER               := 0;
  cDelimiter CONSTANT VARCHAR2(1) := ',';
 -- v_request_id  varchar2(100):=null;
 -- v_request_id2  varchar2(100):=null;
    v_request_id  number:=0;
    v_request_id2  number:=0;
  
    l_finished    boolean;
    l_phase       varchar2 (100);
    l_status      varchar2 (100);
    l_dev_phase   varchar2 (100);
    l_dev_status  varchar2 (100);
    l_message     varchar2 (100);

  
--Procedure for logging debug log
PROCEDURE log_debug_msg ( 
                          p_debug_pkg          IN  VARCHAR2
                         ,p_debug_msg          IN  VARCHAR2 )
IS

  ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
  ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;

BEGIN

    XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCRM'
      ,p_program_type            => 'DEBUG'              --------index exists on program_type
      ,p_attribute15             => p_debug_pkg          --------index exists on attribute15
      ,p_program_id              => 0                    
      ,p_module_name             => 'CDH'                --------index exists on module_name
      ,p_error_message           => p_debug_msg
      ,p_error_message_severity  => 'LOG'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );

END log_debug_msg;

--Procedure for logging Errors/Exceptions
PROCEDURE log_error ( 
                      p_error_pkg          IN  VARCHAR2
                     ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
  ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;
BEGIN
    XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCRM'
      ,p_program_type            => 'ERROR'              --------index exists on program_type
      ,p_attribute15             => p_error_pkg          --------index exists on attribute15
      ,p_program_id              => 0                    
      ,p_module_name             => 'CDH'                --------index exists on module_name
      ,p_error_message           => p_error_msg
      ,p_error_message_severity  => 'MAJOR'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );

END log_error;
PROCEDURE log(
    P_message IN VARCHAR2)
IS
BEGIN
  fnd_file.PUT_LINE(fnd_file.LOG,P_message);
END;
PROCEDURE output(
    P_message IN VARCHAR2)
IS
BEGIN
  fnd_file.PUT_LINE(fnd_file.OUTPUT,P_message);
END;
PROCEDURE CustomerImport
                ( errbuf        OUT NOCOPY VARCHAR2
                , retcode       OUT NOCOPY VARCHAR2
            --    , p_from_date              VARCHAR2
            --    , p_to_date                VARCHAR2
				    --    , p_batch_id               NUMBER
                )
 IS

 CURSOR C_BATCHES IS
   SELECT * FROM
   xxcrm.XXOD_HZ_IMP_TRXCUST_BATCH_STG
   WHERE STATUS = 'ACTIVE';
 
 BEGIN
 
   FOR R_BATCHES IN C_BATCHES
   LOOP
   log('Begin Batch   '||R_BATCHES.SOURCE_BATCH_ID);
    v_request_id2:= FND_REQUEST.SUBMIT_REQUEST('xxfin','XX_CDH_TRX_CUST_EXTR_PROG','','',FALSE,R_BATCHES.SOURCE_BATCH_ID);
     log('Ending Batch   '||R_BATCHES.SOURCE_BATCH_ID);
     log('Request id  '||v_request_id2);
   END LOOP;
 EXCEPTION
  WHEN OTHERS THEN
    log_error('XX_CDH_TRX_CUST_EXTR_PKG.EXTRACTBATCHES', 'EXTRACTBATCHES_ERROR: ' || SQLERRM);

 END CustomerImport;


PROCEDURE ImportBatches
                ( errbuf        OUT NOCOPY VARCHAR2
                , retcode       OUT NOCOPY VARCHAR2
            --    , p_from_date              VARCHAR2
            --    , p_to_date                VARCHAR2
				    --    , p_batch_id               NUMBER
                )
 IS

 
 BEGIN
 
   v_request_id := FND_REQUEST.SUBMIT_REQUEST('xxfin','XXOD_HZ_IMP_TRXCUST_BATCH_STG','','',FALSE);
  
   log('Request id  '||v_request_id);
  
   commit;    
       
        l_finished := fnd_concurrent.wait_for_request ( request_id => v_request_id
                                                     ,interval   => 5
                                                     ,max_wait   => 0
                                                     ,phase      => l_phase
                                                     ,status     => l_status
                                                     ,dev_phase  => l_dev_phase
                                                     ,dev_status => l_dev_status
                                                     ,message    => l_message );
             
        CustomerImport 
         ( errbuf        => errbuf   
         , retcode       => retcode    
         ); 
         
 EXCEPTION
  WHEN OTHERS THEN
    log_error('XX_CDH_TRX_CUST_IMP_PKG.ImportBatches', 'IMPORTBATCHES_ERROR: ' || SQLERRM);
    log('EXCEPTION: ' || SQLERRM);
 END ImportBatches;  
				
end XX_CDH_TRX_CUST_IMP_PKG;