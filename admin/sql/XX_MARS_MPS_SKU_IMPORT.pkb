create or replace
PACKAGE body XX_MARS_MPS_SKU_IMPORT
AS
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
  l_num_count                NUMBER := 0;
  l_chr_error_message        VARCHAR2(2000);
  l_chr_err_msg              VARCHAR2(2000);
  l_chr_state_license_code   VARCHAR2(250);
  l_chr_state_license_number VARCHAR2(250);
  l_num_dn_transaction_id    NUMBER;
  v_request_id               NUMBER:=0;
  l_finished                 BOOLEAN;
  l_phase                    VARCHAR2 (100);
  l_status                   VARCHAR2 (100);
  l_dev_phase                VARCHAR2 (100);
  l_dev_status               VARCHAR2 (100);
  l_message                  VARCHAR2 (100);
  --Procedure for logging debug log
PROCEDURE log_debug_msg(
    p_debug_pkg IN VARCHAR2 ,
    p_debug_msg IN VARCHAR2 )
IS
  ln_login PLS_INTEGER   := FND_GLOBAL.Login_Id;
  ln_user_id PLS_INTEGER := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error ( p_return_code => FND_API.G_RET_STS_SUCCESS ,p_msg_count => 1 ,p_application_name => 'XXCRM' ,p_program_type => 'DEBUG' --------index exists on program_type
  ,p_attribute15 => p_debug_pkg                                                                                                                           --------index exists on attribute15
  ,p_program_id => 0 ,p_module_name => 'CDH'                                                                                                              --------index exists on module_name
  ,p_error_message => p_debug_msg ,p_error_message_severity => 'LOG' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
END log_debug_msg;
--Procedure for logging Errors/Exceptions
PROCEDURE log_error(
    p_error_pkg IN VARCHAR2 ,
    p_error_msg IN VARCHAR2 )
IS
  ln_login PLS_INTEGER   := FND_GLOBAL.Login_Id;
  ln_user_id PLS_INTEGER := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error ( p_return_code => FND_API.G_RET_STS_SUCCESS ,p_msg_count => 1 ,p_application_name => 'XXCRM' ,p_program_type => 'ERROR' --------index exists on program_type
  ,p_attribute15 => p_error_pkg                                                                                                                           --------index exists on attribute15
  ,p_program_id => 0 ,p_module_name => 'CDH'                                                                                                              --------index exists on module_name
  ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
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
PROCEDURE SKU_IMPORT
                ( errbuf        OUT NOCOPY VARCHAR2
                , retcode       OUT NOCOPY VARCHAR2
				        , p_batch_id               NUMBER
                )
IS
  CURSOR C1_SKU_REC
  IS
    SELECT XA.SERIAL_NO,
      XA.BLACK1,
      XA.BLACK2,
      XA.BLACK3,
      XA.MAGENTA1,
      XA.MAGENTA2,
      XA.MAGENTA3,
      XA.CYAN1,
      XA.CYAN2,
      XA.CYAN3,
      XA.YELLOW1,
      XA.YELLOW2,
      XA.YELLOW3
    FROM XXOM.XX_CS_MPS_SKU_IMP_STG xa,
      xx_cs_mps_device_details xd,
      xx_cs_mps_device_b xb
    WHERE xb.serial_no     = xd.serial_no
    AND xd.serial_no       = xa.serial_no
    AND xd.SUPPLIES_LABEL != 'USAGE'
    AND XA.MODEL           = XB.MODEL
    AND XA.BATCH_ID        = p_batch_id;
    
  CURSOR C_NUMBER
  IS
    SELECT DISTINCT XA.SERIAL_NO
    FROM XXOM.XX_CS_MPS_SKU_IMP_STG xa,
      xx_cs_mps_device_details xd,
      xx_cs_mps_device_b xb,
      XX_CS_MPS_DEVICE_DETAILS xcm
    WHERE xb.serial_no     = xd.serial_no
    AND xd.serial_no       = xa.serial_no
    AND xd.SUPPLIES_LABEL != 'USAGE'
    AND XA.MODEL           = XB.MODEL
    AND XA.BATCH_ID        = p_batch_id;
    
  CURSOR C_DEVICE_DETAILS(p_serial_no VARCHAR2)
  IS
    SELECT DISTINCT serial_no,
      supplies_label,
      sku_option_1,
      sku_option_2,
      sku_option_3
    FROM XX_CS_MPS_DEVICE_DETAILS
    WHERE serial_no     = p_serial_no --'CNDX177901'
    AND supplies_label IN ('TONERLEVEL_BLACK','TONERLEVEL_CYAN','TONERLEVEL_YELLOW','TONERLEVEL_MAGENTA');
  l1 C1_SKU_REC%rowtype;
BEGIN
  log('Request id  '||v_request_id);
  OPEN C1_SKU_REC;
  FETCH C1_SKU_REC INTO l1;
  l_num_count := C1_SKU_REC%ROWCOUNT;
  CLOSE C1_SKU_REC;
  -- check cursor count
  IF l_num_count   = 0 THEN
    l_chr_err_msg := 'There are no SKU Import records on '||g_dat_sys_date;
    log(l_chr_err_msg);
    output(l_chr_err_msg);
  ELSE
    output('SKU Import on   '||g_dat_sys_date);
    output(lpad('*',120,'*'));
    output('SERIAL_NO          SUPPLIES_LABEL      SKU_OPTION_1        SKU_OPTION_2        SKU_OPTION_3');
    output(lpad('*',120,'*'));
  END IF;
  FOR C1_REC IN C1_SKU_REC
  LOOP
    UPDATE XX_CS_MPS_DEVICE_DETAILS
    SET SKU_OPTION_1 = DECODE(SUPPLIES_LABEL,'TONERLEVEL_BLACK',C1_REC.BLACK1,'TONERLEVEL_CYAN', C1_REC.CYAN1,'TONERLEVEL_YELLOW',C1_REC.YELLOW1,'TONERLEVEL_MAGENTA',C1_REC.MAGENTA1),
      SKU_OPTION_2   = DECODE(SUPPLIES_LABEL,'TONERLEVEL_BLACK',C1_REC.BLACK2,'TONERLEVEL_CYAN', C1_REC.CYAN2,'TONERLEVEL_YELLOW',C1_REC.YELLOW2,'TONERLEVEL_MAGENTA',C1_REC.MAGENTA2),
      SKU_OPTION_3   = DECODE(SUPPLIES_LABEL,'TONERLEVEL_BLACK',C1_REC.BLACK3,'TONERLEVEL_CYAN', C1_REC.CYAN3,'TONERLEVEL_YELLOW',C1_REC.YELLOW3,'TONERLEVEL_MAGENTA',C1_REC.MAGENTA3)
    WHERE serial_no  = C1_REC.SERIAL_NO;
    COMMIT;
  END LOOP;
  FOR I_NUMBER IN C_NUMBER
  LOOP
    FOR i_device_details IN C_DEVICE_DETAILS(I_NUMBER.SERIAL_NO)
    LOOP
      output(rpad(i_device_details.serial_no,20,' ')||rpad(i_device_details.SUPPLIES_LABEL,20,' ')||rpad(i_device_details.SKU_OPTION_1,20,' ')||rpad(i_device_details.SKU_OPTION_2,30,' ')||rpad(i_device_details.SKU_OPTION_3,30,' '));
    END LOOP;
    --DELETE
    --FROM XXOM.XX_CS_MPS_SKU_IMP_STG xa
    --WHERE xa.serial_no = I_NUMBER.SERIAL_NO;
    COMMIT;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  log_error('XX_MARS_MPS_SKU_IMPORT.SKU_IMPORT', 'SKUIMPORT_ERROR: ' || SQLERRM);
  log('EXCEPTION: ' || SQLERRM);
END SKU_IMPORT;
END XX_MARS_MPS_SKU_IMPORT;
/
SHOW ERRORS;