SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_cs_mps_avf_feed_pkg AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_AVF_FEED_PKG.pkb                                                           |
-- | Description  : This package contains procedures related to MPS FEED to update contract       |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        15-AUG-2012   Bapuji Nanapaneni  Initial version                                   |
-- |                                                                                              |
-- +==============================================================================================+

PROCEDURE process_receive_feed(p_line_feed VARCHAR2);

  -- +=====================================================================+
  -- | Name  : send_feed                                                   |
  -- | Description      : This Procedure will create feed to send to MPS   |
  -- |                    analyst                                          |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_file_name        IN VARCHAR2 file_name         |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE send_feed( p_file_name      IN  VARCHAR2
                     , x_return_status  OUT VARCHAR2
                     , x_return_mesg    OUT VARCHAR2
                     ) IS
  CURSOR c_feed IS
  SELECT serial_no
       , ip_address
       , party_id
       , site_contact
       , site_contact_phone
       , site_address_1
       , site_address_2
       , site_city
       , site_State
       , site_zip_code
       , device_floor
       , device_room
       , device_location
       , device_Cost_center
       , manufacturer
       , model
       , mps_rep_comments
       , device_JIT
       , program_type
       , managed_status
       , support_coverage
       , bsd_rep_comments
    FROM xx_cs_mps_device_b
   WHERE avf_submit IS NULL;
  
    lf_Handle     utl_file.file_type;
    lc_file_path  VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
    lc_record     VARCHAR2(4000);
    lc_file_name  VARCHAR2(250);
    lc_header     VARCHAR2(4000);
    
  BEGIN
    lc_file_name := p_file_name||'.csv';
    -- Check if the file is OPEN
    lf_Handle := utl_file.fopen(lc_file_path, lc_file_name, 'W'); --W will write to a new file A will append to existing file
    lc_header := 'SERIAL_NO'          ||gc_ind||
                 'IP_ADDRESS'         ||gc_ind||
                 'SITE_CONTACT'       ||gc_ind||
                 'SITE_CONTACT_PHONE' ||gc_ind||
                 'SITE_ADDRESS_1'     ||gc_ind||
                 'SITE_ADDRESS_2'     ||gc_ind||
                 'SITE_CITY'          ||gc_ind||
                 'SITE_STATE'         ||gc_ind||
                 'SITE_ZIP_CODE'      ||gc_ind||
                 'DEVICE_FLOOR'       ||gc_ind||
                 'DEVICE_ROOM'        ||gc_ind||
                 'DEVICE_LOCATION'    ||gc_ind||
                 'DEVICE_COST_CENTER' ||gc_ind||
                 'MANUFACTURER'       ||gc_ind||
                 'MODEL'              ||gc_ind||
                 'MPS_REP_COMMENTS'   ||gc_ind||
                 'DEVICE_JIT'         ||gc_ind||
                 'PROGRAM_TYPE'       ||gc_ind||
                 'MANAGED_STATUS'     ||gc_ind||
                 'SUPPORT_COVERAGE'   ||gc_ind||
                 'BSD_REP_COMMENTS';
    
    
    -- Write it to the file
    utl_file.put_line(lf_Handle, lc_header, FALSE); 
    
    FOR r_feed IN c_feed LOOP
      lc_record  := r_feed.serial_no          ||gc_ind||
                    r_feed.ip_address         ||gc_ind||
                    r_feed.site_contact       ||gc_ind||
                    r_feed.site_contact_phone ||gc_ind||
                    r_feed.site_address_1     ||gc_ind||
                    r_feed.site_address_2     ||gc_ind||
                    r_feed.site_city          ||gc_ind||
                    r_feed.site_state         ||gc_ind||
                    r_feed.site_zip_code      ||gc_ind||
                    r_feed.device_floor       ||gc_ind||
                    r_feed.device_room        ||gc_ind||
                    r_feed.device_location    ||gc_ind||
                    r_feed.device_Cost_center ||gc_ind||
                    r_feed.manufacturer       ||gc_ind||
                    r_feed.model              ||gc_ind||
                    r_feed.mps_rep_comments   ||gc_ind||
                    r_feed.device_jit         ||gc_ind||
                    r_feed.program_type       ||gc_ind||
                    r_feed.managed_status     ||gc_ind||
                    r_feed.support_coverage   ||gc_ind||
                    r_feed.bsd_rep_comments; 
      -- Write it to the file
      utl_file.put_line(lf_Handle, lc_record, FALSE);   
      
    UPDATE xx_cs_mps_device_b
       SET avf_submit = 'SUBMITTED'
     WHERE serial_no  = r_feed.serial_no
       AND ip_address = r_feed.ip_address;
       
    END LOOP;
    COMMIT;
    utl_file.fflush(lf_Handle);
    utl_file.fclose(lf_Handle);
    x_return_status := fnd_api.g_ret_sts_success;
    x_return_mesg   := 'Successfully loaded data to file : '||lc_file_name;
  EXCEPTION
    WHEN OTHERS THEN 
      DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED : '||SQLERRM);
      x_return_status := fnd_api.g_ret_sts_error;
      x_return_mesg   := 'WHEN OTHERS RAISED : '||SQLERRM;
  END send_feed;
  -- +=====================================================================+
  -- | Name  : send_feed                                                   |
  -- | Description      : This Procedure will create feed to receive to MPS|
  -- |                    analyst                                          |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_file_name        IN VARCHAR2 file_name         |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE receive_feed( p_file_name      IN  VARCHAR2
                        , x_return_status  OUT VARCHAR2
                        , x_return_mesg    OUT VARCHAR2
                        ) IS
                        
  lc_input_file_handle    UTL_FILE.file_type;
  lc_file_path            VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
  lc_curr_line            VARCHAR2(4000);
  lc_record_count         NUMBER := 0;
  BEGIN
  
    lc_input_file_handle := UTL_FILE.fopen(lc_file_path, p_file_name, 'R',1000);
    LOOP
      BEGIN
        lc_curr_line := NULL;
        lc_record_count := lc_record_count + 1;
        /* UTL FILE READ START */
        UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
        DBMS_OUTPUT.PUT_LINE('Line: '||lc_curr_line);
        IF lc_record_count > 1 THEN
          process_receive_feed(p_line_feed => lc_curr_line);
        END IF;
        COMMIT;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF lc_record_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('NO Records to Read: ' || SQLERRM);
            UTL_FILE.fclose (lc_input_file_handle);
          ELSE
            DBMS_OUTPUT.PUT_LINE('END OF READING FILE: ');
          END IF;
          EXIT;
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('Error while reading: '||SQLERRM);
          x_return_status := fnd_api.g_ret_sts_error;
          x_return_mesg   := 'Error while reading: ' || SQLERRM;
          UTL_FILE.fclose (lc_input_file_handle);
          EXIT;
      END;
    END LOOP;
    x_return_status := fnd_api.g_ret_sts_success;
    x_return_mesg   := 'Successfully extracted data and updated table from file : '||p_file_name;
  EXCEPTION
    WHEN UTL_FILE.invalid_path THEN
      DBMS_OUTPUT.PUT_LINE('Invalid file Path: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Invalid file Path: ' || SQLERRM;
    WHEN UTL_FILE.invalid_mode THEN
      DBMS_OUTPUT.PUT_LINE('Invalid Mode: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Invalid Mode: ' || SQLERRM;
    WHEN UTL_FILE.invalid_filehandle THEN
      DBMS_OUTPUT.PUT_LINE('Invalid file handle: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Invalid file handle: ' || SQLERRM;
    WHEN UTL_FILE.invalid_operation THEN
      DBMS_OUTPUT.PUT_LINE('File does not exist: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'File does not exist: ' || SQLERRM;
    WHEN UTL_FILE.read_error THEN
      DBMS_OUTPUT.PUT_LINE('Read Error: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Read Error: ' || SQLERRM;
    WHEN UTL_FILE.internal_error THEN
      DBMS_OUTPUT.PUT_LINE('Internal Error: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Internal Error: ' || SQLERRM;
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Empty File: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Empty File: ' || SQLERRM;
    WHEN VALUE_ERROR THEN
      DBMS_OUTPUT.PUT_LINE('Value Error: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Value Error: ' || SQLERRM;
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('When Others: ' || SQLERRM);
      UTL_FILE.fclose (lc_input_file_handle);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'When Others: ' || SQLERRM;
  END receive_feed;
  
  PROCEDURE process_receive_feed(p_line_feed VARCHAR2) IS
  -- +=====================================================================+
  -- | Name  : process_receive_feed                                        |
  -- | Description      : This Procedure will update tbl xx_cs_mps_device_b|
  -- |                    each line processed from receive_feed            |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_line_feed        IN VARCHAR2 line feed         |
  -- |                                                                     |
  -- +=====================================================================+
  
    ln_position           NUMBER := 0;
    ln_lin_pos            NUMBER := 0;
    lc_serial_no          xx_cs_mps_device_b.serial_no%TYPE;
    lc_ip_address         xx_cs_mps_device_b.ip_address%TYPE;
    lc_site_contact       xx_cs_mps_device_b.site_contact%TYPE;
    lc_site_contact_phone xx_cs_mps_device_b.site_contact_phone%TYPE;
    lc_site_address_1     xx_cs_mps_device_b.site_address_1%TYPE;
    lc_site_address_2     xx_cs_mps_device_b.site_address_2%TYPE;
    lc_site_city          xx_cs_mps_device_b.site_city%TYPE;
    lc_site_state         xx_cs_mps_device_b.site_state%TYPE;
    lc_site_zip_code      xx_cs_mps_device_b.site_zip_code%TYPE;
    lc_device_floor       xx_cs_mps_device_b.device_floor%TYPE;  
    lc_device_room        xx_cs_mps_device_b.device_room%TYPE;
    lc_device_location    xx_cs_mps_device_b.device_location%TYPE;
    lc_device_cost_center xx_cs_mps_device_b.device_cost_center%TYPE;
    lc_manufacturer       xx_cs_mps_device_b.manufacturer%TYPE;
    lc_model              xx_cs_mps_device_b.model%TYPE;
    lc_mps_rep_comments   xx_cs_mps_device_b.mps_rep_comments%TYPE;
    lc_device_jit         VARCHAR2(30); --xx_cs_mps_device_b.device_jit%TYPE;
    lc_program_type       xx_cs_mps_device_b.program_type%TYPE;
    lc_managed_status     xx_cs_mps_device_b.managed_status%TYPE;
    lc_support_coverage   xx_cs_mps_device_b.support_coverage%TYPE;
    lc_bsd_rep_comments   xx_cs_mps_device_b.bsd_rep_comments%TYPE;
    
  BEGIN
    
    --1st position
    lc_serial_no := SUBSTR(p_line_feed,1,(INSTR(p_line_feed, gc_ind,1,1)-1));
    
    --2nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,1)+1),(INSTR(p_line_feed, gc_ind,1,2)-1)-(INSTR(p_line_feed, gc_ind,1,1)))
      INTO lc_ip_address
      FROM DUAL;
    
    --3nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,2)+1),(INSTR(p_line_feed, gc_ind,1,3)-1)-(INSTR(p_line_feed, gc_ind,1,2)))
      INTO lc_site_contact
     FROM DUAL;    
    
    --4nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,3)+1),(INSTR(p_line_feed, gc_ind,1,4)-1)-(INSTR(p_line_feed, gc_ind,1,3)))
      INTO lc_site_contact_phone
     FROM DUAL;    

    --5nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,4)+1),(INSTR(p_line_feed, gc_ind,1,5)-1)-(INSTR(p_line_feed, gc_ind,1,4)))
      INTO lc_site_address_1
     FROM DUAL;    

    --6nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,5)+1),(INSTR(p_line_feed, gc_ind,1,6)-1)-(INSTR(p_line_feed, gc_ind,1,5)))
      INTO lc_site_address_2
     FROM DUAL;    

    --7nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,6)+1),(INSTR(p_line_feed, gc_ind,1,7)-1)-(INSTR(p_line_feed, gc_ind,1,6)))
      INTO lc_site_city
     FROM DUAL;    

    --8nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,7)+1),(INSTR(p_line_feed, gc_ind,1,8)-1)-(INSTR(p_line_feed, gc_ind,1,7)))
      INTO lc_site_state
     FROM DUAL;    

    --9nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,8)+1),(INSTR(p_line_feed, gc_ind,1,9)-1)-(INSTR(p_line_feed, gc_ind,1,8)))
      INTO lc_site_zip_code
     FROM DUAL; 

    --10nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,9)+1),(INSTR(p_line_feed, gc_ind,1,10)-1)-(INSTR(p_line_feed, gc_ind,1,9)))
      INTO lc_device_floor
     FROM DUAL; 

    --11nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,10)+1),(INSTR(p_line_feed, gc_ind,1,11)-1)-(INSTR(p_line_feed, gc_ind,1,10)))
      INTO lc_device_room
     FROM DUAL; 

    --12nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,11)+1),(INSTR(p_line_feed, gc_ind,1,12)-1)-(INSTR(p_line_feed, gc_ind,1,11)))
      INTO lc_device_location
     FROM DUAL; 

    --13nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,12)+1),(INSTR(p_line_feed, gc_ind,1,13)-1)-(INSTR(p_line_feed, gc_ind,1,12)))
      INTO lc_device_cost_center
     FROM DUAL; 

    --14nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,13)+1),(INSTR(p_line_feed, gc_ind,1,14)-1)-(INSTR(p_line_feed, gc_ind,1,13)))
      INTO lc_manufacturer
     FROM DUAL; 

    --15nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,14)+1),(INSTR(p_line_feed, gc_ind,1,15)-1)-(INSTR(p_line_feed, gc_ind,1,14)))
      INTO lc_model
     FROM DUAL; 

    --16nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,15)+1),(INSTR(p_line_feed, gc_ind,1,16)-1)-(INSTR(p_line_feed, gc_ind,1,15)))
      INTO lc_mps_rep_comments
     FROM DUAL; 

    --17nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,16)+1),(INSTR(p_line_feed, gc_ind,1,17)-1)-(INSTR(p_line_feed, gc_ind,1,16)))
      INTO lc_device_jit
     FROM DUAL; 

    --18nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,17)+1),(INSTR(p_line_feed, gc_ind,1,18)-1)-(INSTR(p_line_feed, gc_ind,1,17)))
      INTO lc_program_type
     FROM DUAL; 

    --19nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,18)+1),(INSTR(p_line_feed, gc_ind,1,19)-1)-(INSTR(p_line_feed, gc_ind,1,18)))
      INTO lc_managed_status
     FROM DUAL; 

    --20nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,19)+1),(INSTR(p_line_feed, gc_ind,1,20)-1)-(INSTR(p_line_feed, gc_ind,1,19)))
      INTO lc_support_coverage
     FROM DUAL; 

    --21nd Position
    SELECT SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,20)+1))
      INTO lc_bsd_rep_comments
     FROM DUAL; 
    
    UPDATE xx_cs_mps_device_b
       SET site_contact       = lc_site_contact
         , site_contact_phone = lc_site_contact_phone
         , site_address_1     = lc_site_address_1
         , site_address_2     = lc_site_address_2
         , site_city          = lc_site_city
         , site_state         = lc_site_state
         , site_zip_code      = lc_site_zip_code
         , mps_rep_comments   = lc_mps_rep_comments
         , bsd_rep_comments   = lc_bsd_rep_comments
     WHERE serial_no          = lc_serial_no
       AND ip_address         = lc_ip_address;
     
    DBMS_OUTPUT.PUT_LINE('lc_serial_no          : '||lc_serial_no);
    DBMS_OUTPUT.PUT_LINE('lc_ip_address         : '||lc_ip_address);
    DBMS_OUTPUT.PUT_LINE('lc_site_contact       : '||lc_site_contact);
    DBMS_OUTPUT.PUT_LINE('lc_site_contact_phone : '||lc_site_contact_phone);
    DBMS_OUTPUT.PUT_LINE('lc_site_address_1     : '||lc_site_address_1);
    DBMS_OUTPUT.PUT_LINE('lc_site_address_2     : '||lc_site_address_2);
    DBMS_OUTPUT.PUT_LINE('lc_site_city          : '||lc_site_city);
    DBMS_OUTPUT.PUT_LINE('lc_site_state         : '||lc_site_state);
    DBMS_OUTPUT.PUT_LINE('lc_site_zip_code      : '||lc_site_zip_code);
    DBMS_OUTPUT.PUT_LINE('lc_device_floor       : '||lc_device_floor);
    DBMS_OUTPUT.PUT_LINE('lc_device_room        : '||lc_device_room);
    DBMS_OUTPUT.PUT_LINE('lc_device_location    : '||lc_device_location);
    DBMS_OUTPUT.PUT_LINE('lc_device_cost_center : '||lc_device_cost_center);
    DBMS_OUTPUT.PUT_LINE('lc_manufacturer       : '||lc_manufacturer);
    DBMS_OUTPUT.PUT_LINE('lc_model              : '||lc_model);
    DBMS_OUTPUT.PUT_LINE('lc_mps_rep_comments   : '||lc_mps_rep_comments);
    DBMS_OUTPUT.PUT_LINE('lc_device_jit         : '||lc_device_jit);
    DBMS_OUTPUT.PUT_LINE('lc_managed_status     : '||lc_managed_status);
    DBMS_OUTPUT.PUT_LINE('lc_support_coverage   : '||lc_support_coverage);
    DBMS_OUTPUT.PUT_LINE('lc_bsd_rep_comments   : '||lc_bsd_rep_comments);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED AT PROCESS_RECEIVE_FEED : '||SQLERRM);
  END process_receive_feed;
END xx_cs_mps_avf_feed_pkg;
/
SHOW ERRORS PACKAGE BODY xx_cs_mps_avf_feed_pkg;