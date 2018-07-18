create or replace
PACKAGE BODY xx_cs_mps_avf_feed_pkg AS
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
-- |1.1        23-JAN-2013   Bapuji Nanapaneni  Change made to pass correct value to Yellow and   |
-- |                                            Magenta Defect# 21976                             |
-- |1.2        11-MAR-2013   Bapuji Nanapaneni  Removed Logging Error message for WHEN OTHERS IN  |
-- |                                            FLEET_FEED PROCEDURE                              |
-- |1.3        22-MAR-2013   Bapuji Nanapaneni  Validate data if correct commas are passed if not |
-- |                                            skip the record and process remaining records     |
-- |1.4        01-APR-2013   Bapuji Nanapaneni  Added new procedure MISC_FEED for misc supplies   |
-- |1.5        22-MAY-2013   Bapuji Nanapaneni  Remove Carriage Return for each line              |
-- |1.6        17-OCT-2013   Raj                change file name BSD rep comments to PO           |
-- |1.7        09-DEC-2013   Arun Gannarapu     Made changes to get media id from fnd_documents   |
-- |1.8        03-NOV-2015   Havish Kasina      Removed the schema references in the existing code|
-- +==============================================================================================+

gc_process_request_id     number;

PROCEDURE process_receive_feed(p_line_feed VARCHAR2,
                               p_party_id NUMBER);

  -- +=====================================================================+
  -- | Name  : send_feed                                                   |
  -- | Description      : This Procedure will create feed to send to MPS   |
  -- |                    analyst                                          |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_request_id        IN NUMBER   Service ID       |
  -- |                    p_party_id          IN NUMBER   customer id      |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE send_feed( p_request_id      IN  NUMBER
                     , p_party_id        IN   NUMBER
                     , x_return_status  OUT VARCHAR2
                     , x_return_mesg    OUT VARCHAR2
                     ) IS
  CURSOR c_feed (p_party_id VARCHAR2) IS
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
       ,(SELECT current_count FROM xx_cs_mps_device_details
                             WHERE device_id = cb.device_id
                               AND supplies_label = 'TONERLEVEL_BLACK') device_JIT
       , program_type
       , managed_status
       ,(SELECT current_count FROM xx_cs_mps_device_details
                             WHERE device_id = cb.device_id
                               AND supplies_label = 'USAGE') support_coverage
       , bsd_rep_comments
       , sla_coverage
       , device_id
       , device_contact
       , device_phone
    FROM xx_cs_mps_device_b cb
   WHERE avf_submit IS NULL
     AND party_id = p_party_id;

    lf_Handle               utl_file.file_type;
    lc_file_path            VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
    lc_record               VARCHAR2(4000);
    lc_file_name            VARCHAR2(250);
    lc_header               VARCHAR2(4000);
    ln_media_id             NUMBER;
    lc_file_type            VARCHAR2(100) := 'text/plain';
    lf_bfile                BFILE;
    lb_blob                 BLOB;
    lc_party_name           VARCHAR2(150);
    ln_rowid                ROWID;
    ln_document_id          NUMBER;
    ln_category_id          NUMBER := 1;
    ln_attached_document_id NUMBER;
    ln_seq_num              NUMBER := 10;
    ln_loop_count           NUMBER := 0;

  BEGIN
    SELECT replace(replace(party_name,'&',''),'/','') INTO lc_party_name FROM hz_parties where party_id = p_party_id;
    lc_file_name := lc_party_name||'_AVF.csv';

    -- Check if the file is OPEN
    lf_Handle := utl_file.fopen(lc_file_path, lc_file_name, 'W'); --W will write to a new file A will append to existing file
    lc_header := 'SITE_CONTACT'       ||gc_ind||
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
                 'IP_ADDRESS'         ||gc_ind||
                 'MANUFACTURER'       ||gc_ind||
                 'MODEL'              ||gc_ind||
                 'SERIAL_NO'          ||gc_ind||
                 'MPS_REP_COMMENTS'   ||gc_ind||
                 'DEVICE_JIT'         ||gc_ind||
                 'PROGRAM_TYPE'       ||gc_ind|| --NULL
                 'MANAGED_STATUS'     ||gc_ind|| --NULL
                 'SUPPORT_COVERAGE'   ||gc_ind||
                 'SLA_COVERAGE'       ||gc_ind||
                 'BSD_REP_COMMENTS'   ||gc_ind||
                 'DEVICE_CONTACT'     ||gc_ind||
                 'DEVICE_PHONE';


    -- Write it to the file
    utl_file.put_line(lf_Handle, lc_header, FALSE);

    FOR r_feed IN c_feed( p_party_id ) LOOP
      ln_loop_count := ln_loop_count +1;
      lc_record  := r_feed.site_contact       ||gc_ind||
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
                    r_feed.ip_address         ||gc_ind||
                    r_feed.manufacturer       ||gc_ind||
                    r_feed.model              ||gc_ind||
                    r_feed.serial_no          ||gc_ind||
                    r_feed.mps_rep_comments   ||gc_ind||
                    r_feed.device_jit         ||gc_ind||
                    r_feed.program_type       ||gc_ind||
                    r_feed.managed_status     ||gc_ind||
                    r_feed.support_coverage   ||gc_ind||
                    r_feed.sla_coverage       ||gc_ind||
                    r_feed.bsd_rep_comments   ||gc_ind||
                    r_feed.device_contact     ||gc_ind||
                    r_feed.device_phone;

      -- Write it to the file
      utl_file.put_line(lf_Handle, lc_record, FALSE);

    UPDATE xx_cs_mps_device_b
       SET avf_submit = 'SUBMITTED'
     WHERE serial_no  = r_feed.serial_no
       AND ip_address = r_feed.ip_address;

    END LOOP;

    utl_file.fflush(lf_Handle);
    utl_file.fclose(lf_Handle);

    IF ln_loop_count > 0 THEN
      --INSERT the file into FND_LOBS TBL.
      SELECT FND_LOBS_S.NEXTVAL INTO ln_media_id FROM DUAL;
      lf_bfile := BFILENAME (lc_file_path, lc_file_name);
      DBMS_LOB.fileopen (lf_bfile, DBMS_LOB.file_readonly);

      BEGIN
        INSERT INTO fnd_lobs( file_id
                            , file_name
                            , file_content_type
                            , file_data
                            , upload_date
                            , program_name
                            , LANGUAGE
                            , oracle_charset
                            , file_format
                            ) VALUES
                            ( ln_media_id
                            , lc_file_name
                            , lc_file_type
                            , EMPTY_BLOB()
                            , SYSDATE
                            , 'FNDATTCH'
                            , 'US'
                            , 'UTF8'
                            , 'BINARY'
                            ) RETURN file_data INTO lb_blob;
        DBMS_LOB.loadfromfile (lb_blob, lf_bfile, DBMS_LOB.getlength (lf_bfile));
        DBMS_LOB.fileclose (lf_bfile);
      EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS RAISED AT LOB INSERT: '||SQLERRM);
          x_return_status := fnd_api.g_ret_sts_error;
          x_return_mesg   := 'WHEN OTHERS RAISED AT LOB INSERT: '||SQLERRM;
          xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                               , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.SEND_FEED'
                                               , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                               , p_error_msg          => 'WHEN OTHERS RAISED AT LOB INSERT: '||SQLERRM
                                               );
      END;
      -- Attach file to sr
      BEGIN
        fnd_documents_pkg.insert_row( X_ROWID                        => ln_rowid
                                    , X_DOCUMENT_ID                  => ln_document_id
                                    , X_CREATION_DATE                => SYSDATE
                                    , X_CREATED_BY                   => fnd_global.user_id
                                    , X_LAST_UPDATE_DATE             => SYSDATE
                                    , X_LAST_UPDATED_BY              => fnd_global.user_id
                                    , X_DATATYPE_ID                  => 6 -- File
                                    , X_CATEGORY_ID                  => ln_category_id
                                    , X_SECURITY_TYPE                => 2
                                    , X_PUBLISH_FLAG                 => 'Y'
                                    , X_USAGE_TYPE                   => 'O'
                                    , X_LANGUAGE                     => 'US'
                                    , X_DESCRIPTION                  => lc_file_name
                                    , X_FILE_NAME                    => lc_file_name
                                    , X_MEDIA_ID                     => ln_media_id
                                    );

        --dbms_output.put_line(' ln_document_id : '|| ln_document_id);
        SELECT fnd_attached_documents_s.NEXTVAL INTO ln_attached_document_id FROM DUAL;
        fnd_attached_documents_pkg.insert_row( X_ROWID                        => ln_rowid
                                             , X_ATTACHED_DOCUMENT_ID         => ln_attached_document_id
                                             , X_DOCUMENT_ID                  => ln_document_id
                                             , X_CREATION_DATE                => SYSDATE
                                             , X_CREATED_BY                   => fnd_global.user_id
                                             , X_LAST_UPDATE_DATE             => SYSDATE
                                             , X_LAST_UPDATED_BY              => fnd_global.user_id
                                             , X_LAST_UPDATE_LOGIN            => fnd_global.user_id
                                             , X_SEQ_NUM                      => ln_seq_num
                                             , X_ENTITY_NAME                  => 'CS_INCIDENTS'
                                             , X_COLUMN1                      => NULL
                                             , X_PK1_VALUE                    => p_request_id
                                             , X_PK2_VALUE                    => NULL
                                             , X_PK3_VALUE                    => NULL
                                             , X_PK4_VALUE                    => NULL
                                             , X_PK5_VALUE                    => NULL
                                             , X_AUTOMATICALLY_ADDED_FLAG     => 'N'
                                             , X_DATATYPE_ID                  => 6
                                             , X_CATEGORY_ID                  => ln_category_id
                                             , X_SECURITY_TYPE                => 2
                                             , X_PUBLISH_FLAG                 => 'Y'
                                             , X_LANGUAGE                     => 'US'
                                             , X_DESCRIPTION                  => lc_file_name
                                             , X_FILE_NAME                    => lc_file_name
                                             , X_MEDIA_ID                     => ln_media_id
                                             );

      EXCEPTION
        WHEN OTHERS THEN
          x_return_status := fnd_api.g_ret_sts_error;
          x_return_mesg   := 'WHEN OTHERS RAISED WHLIE ATTACHING : '||SQLERRM;
          xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                               , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.SEND_FEED'
                                               , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                               , p_error_msg          => 'WHEN OTHERS RAISED WHLIE ATTACHING : '||SQLERRM
                                               );

      END;

      x_return_status := fnd_api.g_ret_sts_success;
      x_return_mesg   := 'Successfully loaded data to file and attached : '||lc_file_name;
    ELSE
      x_return_status := fnd_api.g_ret_sts_success;
      x_return_mesg   := 'Not able to attach the file';
    END IF;

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS RAISED : '||SQLERRM);
      x_return_status := fnd_api.g_ret_sts_error;
      x_return_mesg   := 'WHEN OTHERS RAISED : '||SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.SEND_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'WHEN OTHERS RAISED AT SEND FEED : '||SQLERRM
                                           );
  END send_feed;

  -- +=====================================================================+
  -- | Name  : receive_feed                                                |
  -- | Description      : This Procedure will receive feed to update tbale |
  -- |                    after MPS analyst modify the data                |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_request_id        IN NUMBER   SR ID            |
  -- |                    p_party_id          IN NUMBER   customer ID      |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE receive_feed( p_request_id      IN  NUMBER
                        , p_party_id        IN NUMBER
                        , x_return_status  OUT VARCHAR2
                        , x_return_mesg    OUT VARCHAR2
                        ) IS

  lc_input_file_handle    UTL_FILE.file_type;
  lc_file_path            VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
  lc_curr_line            VARCHAR2(4000);
  lc_record_count         NUMBER := 0;
  lb_blob                 BLOB;
  ln_len                  NUMBER;
  lc_file_name            VARCHAR2(100);
  ln_start                NUMBER;
  ln_bytelen              NUMBER := 32000;
  ln_xlen                 NUMBER;
  lc_output               utl_file.file_type;
  lr_rawdata              RAW(32000);
  lc_return_status        VARCHAR2(1);
  lc_return_mesg          VARCHAR2(2000);
  ex_bad_format           EXCEPTION;

  BEGIN
    XX_CS_MPS_CONTRACTS_PKG.LOG_EXCEPTION( P_OBJECT_ID          => P_PARTY_ID
                                         , P_ERROR_LOCATION     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                         , P_ERROR_MESSAGE_CODE => 'XX_CS_REQ01_ERR_LOG'
                                         , P_ERROR_MSG          => 'Begin of Receive Fleet Procedure #: '||p_request_id);
                                         
    -- Get attached file from SR and write to XXOM ftp/in
    BEGIN
      --Write file to directory  
      get_clob_file( p_request_id    => p_request_id
                   , x_file_name     => lc_file_name
                   , x_return_status => lc_return_status
                   , x_return_msg    => lc_return_mesg
                   );
                   
      IF lc_return_status = 'E' THEN
        xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                             , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                             , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                             , p_error_msg          => lc_return_mesg
                                             );        
      END IF;
      
    EXCEPTION
      WHEN OTHERS THEN
        x_return_status := 'S';
        x_return_mesg   := 'Not able to Derive file or  : '||SQLERRM;
        xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                             , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                             , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                             , p_error_msg          => 'Not able to find the file or  : '||SQLERRM
                                             );
    END;
    
    gc_process_request_id := p_request_id;
    -- Read file 
    lc_input_file_handle := UTL_FILE.fopen(lc_file_path, lc_file_name, 'R',1000);

    LOOP
      BEGIN
        lc_curr_line := NULL;
        lc_record_count := lc_record_count + 1;
        /* UTL FILE READ START */
        UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
        --DBMS_OUTPUT.PUT_LINE('Line: '||lc_curr_line);
        lc_curr_line :=  REPLACE(lc_curr_line,chr(13),NULL);        
        IF lc_record_count = 1 THEN
          IF UPPER(lc_curr_line) <>  ('SITE_CONTACT,SITE_CONTACT_PHONE,SITE_ADDRESS_1,SITE_ADDRESS_2,SITE_CITY,SITE_STATE,SITE_ZIP_CODE,DEVICE_FLOOR,DEVICE_ROOM,DEVICE_LOCATION,DEVICE_COST_CENTER,IP_ADDRESS,MANUFACTURER,MODEL,SERIAL_NO,MPS_REP_COMMENTS,DEVICE_JIT,PROGRAM_TYPE,MANAGED_STATUS,SUPPORT_COVERAGE,SLA_COVERAGE,BSD_REP_COMMENTS,DEVICE_CONTACT,DEVICE_PHONE') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_BAD_FORMAT ERROR RAISED : '|| lc_curr_line);
            RAISE ex_bad_format;
          END IF;            
        END IF;    
        
        IF lc_record_count > 1 THEN
          process_receive_feed(p_line_feed => lc_curr_line, p_party_id => p_party_id);
        END IF;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          UTL_FILE.fclose (lc_input_file_handle);
          EXIT;
        WHEN OTHERS THEN
          --DBMS_OUTPUT.PUT_LINE('Error while reading: '||SQLERRM);
          x_return_status := fnd_api.g_ret_sts_error;
          x_return_mesg   := 'Error while reading: ' || SQLERRM;
          UTL_FILE.fclose (lc_input_file_handle);
          EXIT;
      END;
    END LOOP;

    UTL_FILE.fclose (lc_input_file_handle);
    COMMIT;
    x_return_status := fnd_api.g_ret_sts_success;
    x_return_mesg   := 'Successfully extracted data and updated table from file : '||lc_file_name;

  EXCEPTION
    WHEN UTL_FILE.invalid_path THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid file Path: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Invalid file Path: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'Invalid file Path: ' || SQLERRM
                                           );
    WHEN UTL_FILE.invalid_mode THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Mode: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Invalid Mode: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'Invalid Mode: ' || SQLERRM
                                           );

    WHEN UTL_FILE.invalid_filehandle THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid file handle: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Invalid file handle: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'Invalid file handle: ' || SQLERRM
                                           );
    WHEN UTL_FILE.invalid_operation THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'File does not exist: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'File does not exist: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'File does not exist: ' || SQLERRM
                                           );
    WHEN UTL_FILE.read_error THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Read Error: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Read Error: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'Read Error: ' || SQLERRM
                                           );
    WHEN UTL_FILE.internal_error THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Internal Error: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Internal Error: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'Internal Error: ' || SQLERRM
                                           );
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Empty File: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Empty File: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'Empty File: ' || SQLERRM
                                           );
    WHEN VALUE_ERROR THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Value Error: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'Value Error: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'Value Error: ' || SQLERRM
                                           );
    WHEN ex_bad_format THEN
      x_return_mesg   :=   'Bad File format passed';
      x_return_status :=   fnd_api.g_ret_sts_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'ex_bad_format: '||x_return_mesg);
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          =>  x_return_mesg
                                           );                                            
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others: ' || SQLERRM);
      UTL_FILE.fclose (lc_input_file_handle);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_mesg   :=   'When Others: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'When Others RECEIVE FEED: ' || SQLERRM
                                           );
  END receive_feed;

  PROCEDURE process_receive_feed(p_line_feed VARCHAR2,
                                 p_party_id NUMBER) IS
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
    lc_atr_flag           xx_cs_mps_device_b.essentials_atr_flag%TYPE;
    lc_managed_status     xx_cs_mps_device_b.managed_status%TYPE;
    lc_support_coverage   xx_cs_mps_device_b.support_coverage%TYPE;
    lc_sla_coverage       xx_cs_mps_device_b.sla_coverage%TYPE;
    lc_bsd_rep_comments   xx_cs_mps_device_b.bsd_rep_comments%TYPE;
    lc_device_contact     xx_cs_mps_device_b.device_contact%TYPE;
    lc_device_phone       xx_cs_mps_device_b.device_phone%TYPE;
    ln_no_of_commas       NUMBER := 0;
    lc_status       varchar2(100);
    ln_status_id    number;
    ln_user_id      number;
    x_return_status varchar2(25);
    lc_message      varchar2(250);

  BEGIN
     SELECT TRIM(LENGTH( p_line_feed ) ) - TRIM(LENGTH(TRANSLATE( p_line_feed, 'A,', 'A' ) ) ) 
       INTO ln_no_of_commas
       FROM DUAL;
    IF ln_no_of_commas = 23 THEN
      --1st position
      lc_site_contact := SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,1,(INSTR(p_line_feed, gc_ind,1,1)-1))),chr(13),NULL),1,249);

      --2nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,1)+1),(INSTR(p_line_feed, gc_ind,1,2)-1)-(INSTR(p_line_feed, gc_ind,1,1)))),chr(13),NULL),1,24)
        INTO lc_site_contact_phone
        FROM DUAL;

      --3nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,2)+1),(INSTR(p_line_feed, gc_ind,1,3)-1)-(INSTR(p_line_feed, gc_ind,1,2)))),chr(13),NULL),1,249)
        INTO lc_site_address_1
        FROM DUAL;

      --4nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,3)+1),(INSTR(p_line_feed, gc_ind,1,4)-1)-(INSTR(p_line_feed, gc_ind,1,3)))),chr(13),NULL),1,249)
        INTO lc_site_address_2
        FROM DUAL;

      --5nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,4)+1),(INSTR(p_line_feed, gc_ind,1,5)-1)-(INSTR(p_line_feed, gc_ind,1,4)))),chr(13),NULL),1,99)
        INTO lc_site_city
        FROM DUAL;

      --6nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,5)+1),(INSTR(p_line_feed, gc_ind,1,6)-1)-(INSTR(p_line_feed, gc_ind,1,5)))),chr(13),NULL),1,99)
        INTO lc_site_state
        FROM DUAL;

      --7nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,6)+1),(INSTR(p_line_feed, gc_ind,1,7)-1)-(INSTR(p_line_feed, gc_ind,1,6)))),chr(13),NULL),1,24)
        INTO lc_site_zip_code
        FROM DUAL;

      --8nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,7)+1),(INSTR(p_line_feed, gc_ind,1,8)-1)-(INSTR(p_line_feed, gc_ind,1,7)))),chr(13),NULL),1,149)
        INTO lc_device_floor
        FROM DUAL;

      --9nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,8)+1),(INSTR(p_line_feed, gc_ind,1,9)-1)-(INSTR(p_line_feed, gc_ind,1,8)))),chr(13),NULL),1,149)
        INTO lc_device_room
        FROM DUAL;

      --10nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,9)+1),(INSTR(p_line_feed, gc_ind,1,10)-1)-(INSTR(p_line_feed, gc_ind,1,9)))),chr(13),NULL),1,149)
        INTO lc_device_location
        FROM DUAL;

      --11nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,10)+1),(INSTR(p_line_feed, gc_ind,1,11)-1)-(INSTR(p_line_feed, gc_ind,1,10)))),chr(13),NULL),1,149)
        INTO lc_device_cost_center
        FROM DUAL;

      --12nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,11)+1),(INSTR(p_line_feed, gc_ind,1,12)-1)-(INSTR(p_line_feed, gc_ind,1,11)))),chr(13),NULL),1,99)
        INTO lc_ip_address
        FROM DUAL;

      --13nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,12)+1),(INSTR(p_line_feed, gc_ind,1,13)-1)-(INSTR(p_line_feed, gc_ind,1,12)))),chr(13),NULL),1,149)
        INTO lc_manufacturer
        FROM DUAL;

      --14nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,13)+1),(INSTR(p_line_feed, gc_ind,1,14)-1)-(INSTR(p_line_feed, gc_ind,1,13)))),chr(13),NULL),1,249)
        INTO lc_model
        FROM DUAL;

      --15nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,14)+1),(INSTR(p_line_feed, gc_ind,1,15)-1)-(INSTR(p_line_feed, gc_ind,1,14)))),chr(13),NULL),1,99)
        INTO lc_serial_no
        FROM DUAL;

      --16nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,15)+1),(INSTR(p_line_feed, gc_ind,1,16)-1)-(INSTR(p_line_feed, gc_ind,1,15)))),chr(13),NULL),1,249)
        INTO lc_mps_rep_comments
        FROM DUAL;

      --17nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,16)+1),(INSTR(p_line_feed, gc_ind,1,17)-1)-(INSTR(p_line_feed, gc_ind,1,16)))),chr(13),NULL),1,5)
        INTO lc_device_jit
        FROM DUAL;

      --18nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,17)+1),(INSTR(p_line_feed, gc_ind,1,18)-1)-(INSTR(p_line_feed, gc_ind,1,17)))),chr(13),NULL),1,149)
        INTO lc_program_type
        FROM DUAL;
        
        IF NVL(LC_PROGRAM_TYPE,'MPS') = 'ATR' THEN
           LC_ATR_FLAG := 'Y';
        ELSE
           LC_ATR_FLAG := 'N';
        END IF;

      --19nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,18)+1),(INSTR(p_line_feed, gc_ind,1,19)-1)-(INSTR(p_line_feed, gc_ind,1,18)))),chr(13),NULL),1,49)
        INTO lc_managed_status
        FROM DUAL;

      --20nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,19)+1),(INSTR(p_line_feed, gc_ind,1,20)-1)-(INSTR(p_line_feed, gc_ind,1,19)))),chr(13),NULL),1,149)
        INTO lc_support_coverage
        FROM DUAL;

       --21st Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,20)+1),(INSTR(p_line_feed, gc_ind,1,21)-1)-(INSTR(p_line_feed, gc_ind,1,20)))),chr(13),NULL),1,149)
        INTO lc_sla_coverage
        FROM DUAL;

       --22st Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,21)+1),(INSTR(p_line_feed, gc_ind,1,22)-1)-(INSTR(p_line_feed, gc_ind,1,21)))),chr(13),NULL),1,249)
        INTO lc_bsd_rep_comments
        FROM DUAL;

      --23st Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,22)+1),(INSTR(p_line_feed, gc_ind,1,23)-1)-(INSTR(p_line_feed, gc_ind,1,22)))),chr(13),NULL),1,99)
        INTO lc_device_contact
        FROM DUAL;


      --24nd Position
      SELECT SUBSTR(REPLACE(TRIM(SUBSTR(p_line_feed,(INSTR(p_line_feed, gc_ind,1,23)+1))),chr(13),NULL),1,39)
        INTO lc_device_phone
        FROM DUAL;

      UPDATE xx_cs_mps_device_b
         SET site_contact       = lc_site_contact
           , site_contact_phone = lc_site_contact_phone
           , site_address_1     = lc_site_address_1
           , site_address_2     = lc_site_address_2
           , site_city          = lc_site_city
           , site_state         = lc_site_state
           , site_zip_code      = lc_site_zip_code
           , device_floor       = lc_device_floor
           , device_room        = lc_device_room
           , device_location    = lc_device_location
           , device_cost_center = lc_device_cost_center
           , manufacturer       = lc_manufacturer
           , model              = lc_model
           , mps_rep_comments   = lc_mps_rep_comments
           , device_jit         = lc_device_jit
           , program_type       = lc_program_type
           , managed_status     = lc_managed_status
           , support_coverage   = lc_support_coverage
           , sla_coverage       = lc_sla_coverage
           , bsd_rep_comments   = lc_bsd_rep_comments
           , device_contact     = lc_device_contact
           , device_phone       = lc_device_phone
           , po_number          = substr(lc_bsd_rep_comments,1,20)
           , ship_site_id       = null
           , essentials_atr_flag = lc_atr_flag
           , Active_status = 'Active'
       WHERE serial_no          = lc_serial_no
       AND party_id             = p_party_id;
       --  AND ip_address         = lc_ip_address;
/*
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_serial_no          : '||lc_serial_no);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_ip_address         : '||lc_ip_address);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_site_contact       : '||lc_site_contact);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_site_contact_phone : '||lc_site_contact_phone);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_site_address_1     : '||lc_site_address_1);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_site_address_2     : '||lc_site_address_2);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_site_city          : '||lc_site_city);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_site_state         : '||lc_site_state);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_site_zip_code      : '||lc_site_zip_code);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_device_floor       : '||lc_device_floor);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_device_room        : '||lc_device_room);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_device_location    : '||lc_device_location);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_device_cost_center : '||lc_device_cost_center);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_manufacturer       : '||lc_manufacturer);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_model              : '||lc_model);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_mps_rep_comments   : '||lc_mps_rep_comments);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_device_jit         : '||lc_device_jit);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_managed_status     : '||lc_managed_status);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_support_coverage   : '||lc_support_coverage);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_bsd_rep_comments   : '||lc_sla_coverage);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_bsd_rep_comments   : '||lc_bsd_rep_comments);
*/

     -- update to close AVF request. 
        begin
         select user_id
         into ln_user_id
         from fnd_user
         where user_name = 'CS_ADMIN';
        end;
        
        ln_status_id := 2;
        lc_status := 'Closed';
     
        IF gc_process_request_id is not null then
           
             XX_CS_SR_UTILS_PKG.Update_SR_status(p_sr_request_id  => gc_process_request_id,
                                  p_user_id        => ln_user_id,
                                  p_status_id      => ln_status_id,
                                  p_status         => lc_status,
                                  x_return_status  => x_return_status,
                                  x_msg_data      => lc_message); 
                                  
             If nvl(x_return_status,'S') = 'E' then

                 xx_cs_mps_contracts_pkg.log_exception( p_object_id          => gc_process_request_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.PROCESS_RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'Error while updating '||gc_process_request_id||' incident_id  '||SQLERRM
                                           );
           
             end if;
          end if;
    ELSE
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.PROCESS_RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'Record has bad data : '||p_line_feed
                                           );    
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS RAISED AT PROCESS_RECEIVE_FEED : '||SQLERRM);
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.PROCESS_RECEIVE_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'WHEN OTHERS RAISED AT PROCESS_RECEIVE_FEED : '||SQLERRM
                                           );
  END process_receive_feed;

  -- +=====================================================================+
  -- | Name  : fleet_feed                                                  |
  -- | Description      : This Procedure will read fleet feed and send data|
  -- |                    to xx_cs_mps_fleet_pkg.device_feed               |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:       p_file_name       IN VARCHAR2 file_name           |
  -- |                   x_return_status   OUT VARCHAR2 Return status      |
  -- |                   x_return_msg      OUT VARCHAR2 Return Message     |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE fleet_feed( p_file_name       IN  VARCHAR2
                      , x_return_status  OUT  VARCHAR2
                      , x_return_msg     OUT  VARCHAR2
                      ) IS

  TYPE mps_device_info_type IS RECORD ( device_id         VARCHAR2(150)
                                      , group_id          VARCHAR2(100)
                                      , device_name       VARCHAR2(250)
                                      , serial_number     VARCHAR2(100)
                                      , ip_address        VARCHAR2(100)
                                      , black_toner       VARCHAR2(25)
                                      , cyan_toner        VARCHAR2(25)
                                      , magenta_toner     VARCHAR2(25)
                                      , yellow_toner      VARCHAR2(25)
                                      , total_life_count  NUMBER
                                      , mono_life_count   NUMBER
                                      , color_life_count  NUMBER
                                      , pages_in_7_days   NUMBER
                                      , last_active       DATE
                                      , aops_cust_acct    VARCHAR2(100)
                                      );

  --Local Variables Declaration
  lr_mps_device_info_type mps_device_info_type;
  lc_input_file_handle    UTL_FILE.file_type;
  lc_file_path            VARCHAR2(100)  := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
  lc_curr_line            VARCHAR2(4000);
  lc_record_count         NUMBER         := 0;
  lc_file_name            VARCHAR2(100);
  gc_ind                  VARCHAR2(1)    := ',';
  ln_user_id              NUMBER         := NVL(FND_GLOBAL.USER_ID,-1);
  ld_sys_date             DATE           := SYSDATE;
  ln_group_ct             NUMBER         := 0;
  lt_device_tbl           xx_cs_mps_device_tbl_type;
  i                       NUMBER         := 0;
  j                       number         := 0;
  k                       number         := 0;
  lt_supply_tbl           xx_cs_mps_supply_tbl_type;
  lc_return_status        VARCHAR2(1)    := 'S';
  lc_return_msg           VARCHAR2(2000);
  lc_device_id            VARCHAR2(150);
  lc_group_id             VARCHAR2(100);
  ln_no_of_commas         NUMBER         := 0;
  lc_validate_labels      VARCHAR2(2000);
  ex_bad_format           EXCEPTION;


  BEGIN

    lc_file_name         := p_file_name;
    lc_input_file_handle := UTL_FILE.fopen(lc_file_path, lc_file_name, 'R',4000);
    lt_device_tbl        := xx_cs_mps_device_tbl_type();
    
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'Begining of Procedure FLEET_FEED'
                                         );
    LOOP
      BEGIN
  
        lc_curr_line    := NULL;
        lc_record_count := lc_record_count + 1;

        /* UTL FILE READ START */
        UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Line: '||lc_curr_line);
        lc_curr_line :=  REPLACE(lc_curr_line,chr(13),NULL);
        /* Check The labels are send in correct format if not log error message and exit */
        IF     lc_record_count = 1 THEN
          lc_validate_labels := UPPER(lc_curr_line);    
          IF lc_validate_labels <> 'DEVICE ID,GROUP,DEVICE NAME,SERIAL NUMBER,IP ADDRESS,BLACK TONER,CYAN TONER,MAGENTA TONER,YELLOW TONER,TOTAL LIFE COUNT,MONO LIFE COUNT,COLOR LIFE COUNT,PAGES IN 7 DAYS,LAST ACTIVE,ACCOUNT NUMBER' THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_BAD_FORMAT ERROR RAISED : '|| lc_curr_line);
          RAISE ex_bad_format;                                                 
          END IF;
        END IF;          

        IF lc_record_count > 1 THEN

          i := i + 1;
          IF lc_curr_line IS NOT NULL THEN
            SELECT TRIM(LENGTH( lc_curr_line ) ) - TRIM(LENGTH(TRANSLATE( lc_curr_line, 'A,', 'A' ) ) ) 
              INTO ln_no_of_commas
              FROM DUAL;
          END IF;

          IF ln_no_of_commas = 14 THEN
            k := k + 1;
            lr_mps_device_info_type.device_id        := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,1,(INSTR(lc_curr_line, gc_ind,1,1)-1))),chr(13),NULL),1,149);
            lr_mps_device_info_type.group_id         := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,1)+1),(INSTR(lc_curr_line, gc_ind,1,2)-1)-(INSTR(lc_curr_line, gc_ind,1,1)))),chr(13),NULL),1,149);
            lr_mps_device_info_type.device_name      := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,2)+1),(INSTR(lc_curr_line, gc_ind,1,3)-1)-(INSTR(lc_curr_line, gc_ind,1,2)))),chr(13),NULL),1,149);
            lr_mps_device_info_type.serial_number    := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,3)+1),(INSTR(lc_curr_line, gc_ind,1,4)-1)-(INSTR(lc_curr_line, gc_ind,1,3)))),chr(13),NULL),1,99);
            lr_mps_device_info_type.ip_address       := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,4)+1),(INSTR(lc_curr_line, gc_ind,1,5)-1)-(INSTR(lc_curr_line, gc_ind,1,4)))),chr(13),NULL),1,99);
            lr_mps_device_info_type.black_toner      := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,5)+1),(INSTR(lc_curr_line, gc_ind,1,6)-1)-(INSTR(lc_curr_line, gc_ind,1,5)))),chr(13),NULL),1,24);
            lr_mps_device_info_type.cyan_toner       := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,6)+1),(INSTR(lc_curr_line, gc_ind,1,7)-1)-(INSTR(lc_curr_line, gc_ind,1,6)))),chr(13),NULL),1,24);
            lr_mps_device_info_type.magenta_toner    := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,7)+1),(INSTR(lc_curr_line, gc_ind,1,8)-1)-(INSTR(lc_curr_line, gc_ind,1,7)))),chr(13),NULL),1,24);
            lr_mps_device_info_type.yellow_toner     := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,8)+1),(INSTR(lc_curr_line, gc_ind,1,9)-1)-(INSTR(lc_curr_line, gc_ind,1,8)))),chr(13),NULL),1,24);
            lr_mps_device_info_type.total_life_count := REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,9)+1),(INSTR(lc_curr_line, gc_ind,1,10)-1)-(INSTR(lc_curr_line, gc_ind,1,9)))),chr(13),NULL);
            lr_mps_device_info_type.mono_life_count  := REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,10)+1),(INSTR(lc_curr_line, gc_ind,1,11)-1)-(INSTR(lc_curr_line, gc_ind,1,10)))),chr(13),NULL);
            lr_mps_device_info_type.color_life_count := REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,11)+1),(INSTR(lc_curr_line, gc_ind,1,12)-1)-(INSTR(lc_curr_line, gc_ind,1,11)))),chr(13),NULL);
            lr_mps_device_info_type.pages_in_7_days  := REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,12)+1),(INSTR(lc_curr_line, gc_ind,1,13)-1)-(INSTR(lc_curr_line, gc_ind,1,12)))),chr(13),NULL);
            lr_mps_device_info_type.last_active      := TO_DATE(REPLACE(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,13)+1),(INSTR(lc_curr_line, gc_ind,1,14)-1)-(INSTR(lc_curr_line, gc_ind,1,13))),chr(13),NULL),'MM/DD/YYYY HH24:MI');
            --lr_mps_device_info_type.aops_cust_acct   := SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,14)+1),(INSTR(lc_curr_line, gc_ind,1,15)-1)-(INSTR(lc_curr_line, gc_ind,1,14)));
            lr_mps_device_info_type.aops_cust_acct   := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,14)+1))),chr(13),NULL),1,99);

            lt_supply_tbl := xx_cs_mps_supply_tbl_type();

            j := 0;

            FOR K IN 1..4 LOOP
              j := j + 1;
              lt_supply_tbl.EXTEND(1);

              IF K = 1  THEN
                lt_supply_tbl(j) := XX_CS_MPS_SUPPLY_REC_TYPE( 'TONERLEVEL_BLACK'
                                                             , 'ACTIVE'
                                                             , lr_mps_device_info_type.black_toner
                                                             , lr_mps_device_info_type.black_toner
                                                             , NULL
                                                             , 'BLACK'
                                                             , NULL
                                                             , lr_mps_device_info_type.last_active
                                                             );

              ELSIF k = 2  THEN
                lt_supply_tbl(j) := XX_CS_MPS_SUPPLY_REC_TYPE( 'TONERLEVEL_CYAN'
                                                             , 'ACTIVE'
                                                             , lr_mps_device_info_type.cyan_toner
                                                             , lr_mps_device_info_type.cyan_toner
                                                             , NULL
                                                             , 'CYAN'
                                                             , NULL
                                                             , lr_mps_device_info_type.last_active
                                                             );

              ELSIF K = 3  THEN
                lt_supply_tbl(j) := XX_CS_MPS_SUPPLY_REC_TYPE( 'TONERLEVEL_MAGENTA'
                                                             , 'ACTIVE'
                                                             , lr_mps_device_info_type.magenta_toner
                                                             , lr_mps_device_info_type.magenta_toner
                                                             , NULL                                                           
                                                             , 'MAGENTA'
                                                             , NULL
                                                             , lr_mps_device_info_type.last_active
                                                             );

              ELSIF k = 4  THEN
                lt_supply_tbl(j) := XX_CS_MPS_SUPPLY_REC_TYPE( 'TONERLEVEL_YELLOW'
                                                             , 'ACTIVE'
                                                             , lr_mps_device_info_type.yellow_toner
                                                             , lr_mps_device_info_type.yellow_toner
                                                             , NULL                                                           
                                                             , 'YELLOW'
                                                             , NULL
                                                             , lr_mps_device_info_type.last_active
                                                             );
              END IF;
              --dbms_output.put_line(' K '|| K ||' J '|| J ||' COUNT '|| lt_supply_tbl.count);
            END LOOP;
            --dbms_output.put_line('supply count '||lt_supply_tbl.count);

            lt_device_tbl.EXTEND(1);
            lt_device_tbl(i) := xx_cs_mps_device_rec_type( lr_mps_device_info_type.group_id
                                                         , lr_mps_device_info_type.device_id
                                                         , lr_mps_device_info_type.device_name
                                                         , NULL
                                                         , lr_mps_device_info_type.aops_cust_acct
                                                         , lr_mps_device_info_type.pages_in_7_days
                                                         , lr_mps_device_info_type.mono_life_count
                                                         , lr_mps_device_info_type.color_life_count
                                                         , lr_mps_device_info_type.total_life_count
                                                         , lt_supply_tbl
                                                         , NULL
                                                         , lr_mps_device_info_type.last_active
                                                         , lr_mps_device_info_type.ip_address
                                                         , lr_mps_device_info_type.serial_number
                                                         , NULL
                                                         , NULL
                                                         , NULL
                                                         , NULL
                                                         , NULL
                                                         );

            lc_device_id := lt_device_tbl(i).device_id;
            lc_group_id  :=    lt_device_tbl(i).group_id;

            --dbms_output.put_line(' (i) : '||(i));
            --dbms_output.put_line('index '||i||' lt_device_tbl(i).device_id : '||lt_device_tbl(i).device_id);
            --FOR l IN lt_supply_tbl.first .. lt_supply_tbl.last loop
               --dbms_output.put_line('supply index '||l||' lt_device_tbl(i).supply_tbl.LOW_LEVEL : '|| lt_device_tbl(i).supply_tbl(l).LOW_LEVEL);
              --L :=  lt_supply_tbl.NEXT;
            --END LOOP;
          ELSE
            xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                                 , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                                 , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                                 , p_error_msg          => 'Record has bad data : ' ||lc_curr_line
                                                 );  
           END IF;                                     
 
        
        END IF;
      
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          UTL_FILE.fclose (lc_input_file_handle);
          EXIT;

        WHEN OTHERS THEN
          UTL_FILE.fclose (lc_input_file_handle);
          x_return_status := fnd_api.g_ret_sts_error;
          x_return_msg    := 'WHEN OTHERS RAISED READING FILE in fleet_feed Procedure : '||SQLERRM;
          EXIT;                                              
      END;
      
    END LOOP;
      UTL_FILE.fclose (lc_input_file_handle);

      --dbms_output.put_line('lt_device_tbl.FIRST : '||lt_device_tbl.FIRST);
      --dbms_output.put_line('lt_device_tbl.LAST : '||lt_device_tbl.LAST);

        xx_cs_mps_fleet_pkg.device_feed( p_group_id        => NULL
                                       , p_device_id       => NULL
                                       , p_device_tbl      => lt_device_tbl
                                       , x_return_status   => lc_return_status
                                       , x_return_msg      => lc_return_msg
                                       );

        x_return_status := lc_return_status;
        x_return_msg    := lc_return_msg;

        COMMIT;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No Of Records in File     : '||i);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No Of Records Processed   : '||k);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No Of Records Errored out : '||(i-k));

  EXCEPTION
    WHEN UTL_FILE.invalid_path THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid file Path: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_msg    :=   'Invalid file Path: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          =>  'Invalid file Path: ' || SQLERRM
                                           );      

    WHEN UTL_FILE.invalid_mode THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Mode: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_msg    :=   'Invalid Mode: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          =>  'Invalid Mode: ' || SQLERRM
                                           );      

    WHEN UTL_FILE.invalid_filehandle THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid file handle: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_msg    :=   'Invalid file handle: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          =>  'Invalid file handle: ' || SQLERRM
                                           );
    WHEN UTL_FILE.invalid_operation THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'File does not exist: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_msg    :=   'File does not exist: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          =>  'File does not exist: ' || SQLERRM
                                           );
    WHEN UTL_FILE.read_error THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Read Error: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_msg    :=   'Read Error: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          =>  'Read Error: ' || SQLERRM
                                           );

    WHEN UTL_FILE.internal_error THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Internal Error: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_msg    :=   'Internal Error: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          =>  'Internal Error: ' || SQLERRM
                                           );

    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Empty File: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_msg    :=   'Empty File: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          =>  'Empty File: ' || SQLERRM
                                           );

    WHEN VALUE_ERROR THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Value Error: ' || SQLERRM);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_msg    :=   'Value Error: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          =>  'Value Error: ' || SQLERRM
                                           );
    WHEN ex_bad_format THEN
      x_return_msg    :=   'Bad File format passed';
      x_return_status :=   fnd_api.g_ret_sts_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'ex_bad_format: '||x_return_msg);
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          =>  x_return_msg
                                           );        
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others: ' || SQLERRM);
      UTL_FILE.fclose (lc_input_file_handle);
      x_return_status :=   fnd_api.g_ret_sts_error;
      x_return_msg    :=   'When Others: ' || SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.FLEET_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          =>  'When Others: ' || SQLERRM
                                           );

  END fleet_feed;

  -- +=====================================================================+
  -- | Name  : get_ship_to                                                 |
  -- | Description      : This Procedure will create feed to send to AOPS  |
  -- |                    team to create SHIP TO                           |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_party_id          IN NUMBER   customer id      |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE get_ship_to( p_party_id        IN   NUMBER
                       , x_return_status  OUT VARCHAR2
                       , x_return_mesg    OUT VARCHAR2
                       ) IS
  CURSOR c_ship_to (p_party_id NUMBER) IS
    SELECT DISTINCT 'A'                        action_code
         , SUBSTR(a.orig_system_reference,1,8) account_number
         ,  p.party_name                       customer_name
         , ''                                  address_sequence
         , ''                                  address_id
         , d.site_address_1                    address_1
         , d.site_address_2                    address_2
         , d.site_city                         city
         , d.site_state                        state
         , d.site_zip_code                     zip_code
         , ''                                  desk_top_req_flag
         , ''                                  back_order_flag
         , ''                                  delivery_days
         , ''                                  max_order_amount
         , ''                                  override_address
         , ''                                  province
         , ''                                  country_code
      FROM xx_cs_mps_device_b d
         , hz_cust_accounts        a
         , hz_parties              p
     WHERE d.party_id = a.party_id
       AND a.party_id = p.party_id
       AND D.PARTY_ID = p_party_id;

  lc_sequence     VARCHAR2(5);
  ln_seq          NUMBER := 1;
  lf_Handle       utl_file.file_type;
  lc_file_path    VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
  lc_file_name    VARCHAR2(200);
  lc_header       VARCHAR2(4000);
  lc_record       VARCHAR2(4000);
  lc_party_name   VARCHAR2(150);
  lc_conn         UTL_SMTP.connection;
  lc_temp_email   VARCHAR2(100) := FND_PROFILE.VALUE('XX_CS_MPS_SHIPTO_ADDR');
  lc_email_add    VARCHAR2(240) := FND_PROFILE.VALUE('XX_CS_MPS_SHIPTO_ADDR');
  lc_subject      VARCHAR2(240) := 'SHIP TO UPLOAD';

BEGIN

  SELECT party_name INTO lc_party_name FROM hz_parties where party_id = p_party_id;
  lc_file_name := lc_party_name||'_SHIP_TO.csv';

  -- Check if the file is OPEN
  lf_Handle := utl_file.fopen(lc_file_path, lc_file_name, 'W'); --W will write to a new file A will append to existing file
  lc_header := 'ACTION CODE'       ||gc_ind||
               'ACCOUNT NUMBER'    ||gc_ind||
               'ADDRESS SEQ'       ||gc_ind||
               'ADDRESS ID'        ||gc_ind||
               'BUSINESS NAME'     ||gc_ind||
               'ADDR LINE 1'       ||gc_ind||
               'ADDR LINE 2'       ||gc_ind||
               'CITY'              ||gc_ind||
               'STATE'             ||gc_ind||
               'ZIP'               ||gc_ind||
               'DESK TOP REQ FLAG' ||gc_ind||
               'BACK ORDER FLAG'   ||gc_ind||
               'DELIVERY DAYS'     ||gc_ind||
               'MAX ORDER AMOUNT'  ||gc_ind||
               'OVERRIDE ADDR'     ||gc_ind||
               'PROVINCE'          ||gc_ind||
               'COUNTRY CODE' ;

  -- Write it to the file
  utl_file.put_line(lf_Handle, lc_header, FALSE);
  FOR r_ship_to IN c_ship_to(p_party_id) LOOP
    --ln_loop_count := ln_loop_count +1;

    ln_seq := ln_seq + 1;
    select LPAD(ln_seq,5,'0') INTO lc_sequence from dual;

    lc_record  := r_ship_to.action_code       ||gc_ind||
                  r_ship_to.account_number    ||gc_ind||
                  lc_sequence                 ||gc_ind|| -- r_ship_to.address_sequence  ||gc_ind||
                  r_ship_to.address_id        ||gc_ind||
                  r_ship_to.customer_name     ||gc_ind||
                  r_ship_to.address_1         ||gc_ind||
                  r_ship_to.address_2         ||gc_ind||
                  r_ship_to.city              ||gc_ind||
                  r_ship_to.state             ||gc_ind||
                  r_ship_to.zip_code          ||gc_ind||
                  r_ship_to.desk_top_req_flag ||gc_ind||
                  r_ship_to.back_order_flag   ||gc_ind||
                  r_ship_to.delivery_days     ||gc_ind||
                  r_ship_to.max_order_amount  ||gc_ind||
                  r_ship_to.override_address  ||gc_ind||
                  r_ship_to.province          ||gc_ind||
                  r_ship_to.country_code;
    -- Write it to the file
    utl_file.put_line(lf_Handle, lc_record, FALSE);
  END LOOP;
  utl_file.fflush(lf_Handle);
  utl_file.fclose(lf_Handle);

  lc_conn := xx_pa_pb_mail.begin_mail( sender         => lc_email_add
                                     , recipients     => lc_temp_email
                                     , cc_recipients  => NULL
                                     , subject        => lc_subject
                                     , mime_type      => xx_pa_pb_mail.multipart_mime_type
                                     );

  xx_pa_pb_mail.xx_email_excel( conn        => lc_conn
                              , p_directory => lc_file_path
                              , p_filename  => lc_file_name
                              );
  xx_pa_pb_mail.end_attachment(conn => lc_conn);
  xx_pa_pb_mail.end_mail(conn => lc_conn);
EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'S';
    x_return_mesg   := 'When Others raised at get_ship_to  : '||SQLERRM;
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_party_id
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.GET_SHIP_TO'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'When Others raised at get_ship_to  : '||SQLERRM
                                         );
END get_ship_to;

  -- +=====================================================================+
  -- | Name  : get_clob_file                                               |
  -- | Description      : This Procedure will identify the file and write  |
  -- |                    file to specfied directory                       |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_request_id        IN NUMBER   request id       |
  -- |                    x_file_name        OUT VARCHAR2 file name        |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
PROCEDURE get_clob_file( p_request_id    IN  NUMBER
                       , x_file_name     OUT VARCHAR2
                       , x_return_status OUT VARCHAR2
                       , x_return_msg    OUT VARCHAR2
                       ) IS

  -- Declare local variables
  lb_blob                 BLOB;
  ln_len                  NUMBER;
  lc_file_name            VARCHAR2(100);
  ln_start                NUMBER;
  ln_bytelen              NUMBER := 32000;
  ln_xlen                 NUMBER;
  lc_output               utl_file.file_type;
  lr_rawdata              RAW(32000);
  lc_file_path            VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');

  BEGIN
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.GET_CLOB_FILE'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'Begin of GET_CLOB_FILE Procedure '
                                         );  
                                         
    SELECT DBMS_LOB.GETLENGTH(lb.file_data)
         , lb.file_data
         , lb.file_name
      INTO ln_len
         , lb_blob
         , lc_file_name
      FROM fnd_attached_documents dc
         , fnd_documents       dt
         , fnd_lobs               lb
     WHERE lb.file_id     = dt.media_id
       AND dt.document_id = dc.document_id
       AND dc.entity_name = 'CS_INCIDENTS'
       AND lb.program_tag IS NULL
       AND dc.pk1_value   = TO_CHAR(p_request_id);

    -- define output directory to write the blob object
    lc_output  := utl_file.fopen(lc_file_path, lc_file_name,'wb', 32760);
    ln_start   := 1;
    ln_bytelen := 32000;
    
    -- save blob length
    ln_xlen    := ln_len;

    -- if small enough for a single write
    IF ln_len < 32760 THEN
      utl_file.put_raw(lc_output,lb_blob);
      utl_file.fflush(lc_output);

    ELSE -- write in pieces
      ln_start := 1;
      WHILE ln_start < ln_len and ln_bytelen > 0 LOOP
        -- read file
        dbms_lob.read(lb_blob,ln_bytelen,ln_start,lr_rawdata);
        utl_file.put_raw(lc_output,lr_rawdata);
        utl_file.fflush(lc_output);
        
        -- set the start position for the next cut
        ln_start := ln_start + ln_bytelen;
        
        -- set the end position if less than 32000 bytes
        ln_xlen := ln_xlen - ln_bytelen;

        IF ln_xlen < 32000 THEN
          ln_bytelen := ln_xlen;
        END IF;

      END LOOP;
    END IF;
    -- Close file after writing the file.
    utl_file.fclose(lc_output);
    
    x_file_name := lc_file_name;
    x_return_status := 'S';
    x_return_msg    := 'File Successfully written to requested path';

  EXCEPTION
    WHEN OTHERS THEN
      x_return_status := 'E';
      x_return_msg   := 'Not able to find the file or  : '||SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_request_id
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.GET_CLOB_FILE'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'Not able to find the file or  : '||SQLERRM
                                           );
END get_clob_file;

  -- +=====================================================================+
  -- | Name  : LOAD_FLEET_FEED                                             |
  -- | Description      : This Procedure will be called from a business    |
  -- |                    Event to process the attached file data          |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_request_id        IN NUMBER   request id       |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
 PROCEDURE load_fleet_feed(    p_request_id      IN  NUMBER
                          , x_return_status  OUT  VARCHAR2
                          , x_return_msg     OUT  VARCHAR2
                          ) IS
lc_file_name      VARCHAR2(100);
lc_return_status  VARCHAR2(1);
lc_return_msg     VARCHAR2(2000);
ln_request_id     NUMBER;
l_sr_notes        xx_cs_sr_notes_rec;
BEGIN
  xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_request_id
                                       , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.LOAD_FLEET_FEED'
                                       , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                       , p_error_msg          => 'Begin of XX_CS_MPS_AVF_FEED_PKG.LOAD_FLEET_FEED CALL: '||p_request_id
                                       );
  ln_request_id := p_request_id;

  get_clob_file( p_request_id    => ln_request_id
               , x_file_name     => lc_file_name
               , x_return_status => lc_return_status
               , x_return_msg    => lc_return_msg
              );

  IF lc_file_name IS NOT NULL THEN
    fleet_feed( p_file_name       => lc_file_name
              , x_return_status   => lc_return_status
              , x_return_msg      => lc_return_msg
              );
  END IF;

  x_return_status := lc_return_status;
  x_return_msg    := lc_return_msg;


EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'S';
    x_return_msg   := 'Not able to find the file or  : '||SQLERRM;
    l_sr_notes.notes := 'Not able to find the file or Read file  : '||SQLERRM;
    xx_cs_servicerequest_pkg.create_note( p_request_id    => ln_request_id
                                        , p_sr_notes_rec  => l_sr_notes
                                        , p_return_status => x_return_status
                                        , p_msg_data      => x_return_msg
                                        );
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_request_id
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.LOAD_FLEET_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'Not able to find the file or Read file  : '||SQLERRM
                                         );
END load_fleet_feed;

  -- +=====================================================================+
  -- | Name  : MISC_FEED                                                   |
  -- | Description      : This Procedure will read feed and insert into    |
  -- |                    XX_CS_MPS_DEVICE_SUPPLIES                        |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_file_name        IN VARCHAR2 file_name         |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
PROCEDURE MISC_FEED( p_request_id IN  VARCHAR2
                   , x_return_status  OUT  VARCHAR2
                   , x_return_msg     OUT  VARCHAR2
                   ) IS
                   
  lc_input_file_handle    UTL_FILE.file_type;
  lc_file_path            VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
  lc_curr_line            VARCHAR2(4000);
  lc_record_count         NUMBER := 0;
  ex_bad_format           EXCEPTION;
  lc_file_name            VARCHAR2(100);
  ln_user_id              NUMBER         := NVL(FND_GLOBAL.USER_ID,-1);
  ld_sys_date             DATE           := SYSDATE;
  lc_device_id            xx_cs_mps_device_supplies.device_id%TYPE;
  lc_serial_number        xx_cs_mps_device_supplies.serial_number%TYPE;
  lc_supplies_label       xx_cs_mps_device_supplies.supplies_label%TYPE;
  lc_supplies_level       xx_cs_mps_device_supplies.supplies_level%TYPE;
  lc_return_status        VARCHAR2(1)    := 'S';
  lc_return_mesg          VARCHAR2(2000);
  ln_no_of_commas         NUMBER := 0;
  ln_failed_rec           NUMBER := 0;
  ln_tot_rec              NUMBER := 0;
  
BEGIN
    -- Get attached file from SR and write to XXOM ftp/in
    get_clob_file( p_request_id    => p_request_id
                 , x_file_name     => lc_file_name
                 , x_return_status => lc_return_status
                 , x_return_msg    => lc_return_mesg
                 );               
    IF lc_file_name IS NOT NULL THEN    
      -- Read file 
      lc_input_file_handle := UTL_FILE.fopen(lc_file_path, lc_file_name, 'R',1000); 
      LOOP
        BEGIN
          lc_curr_line := NULL;
          lc_record_count := lc_record_count + 1;
          /* UTL FILE READ START */
          UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
          --DBMS_OUTPUT.PUT_LINE('Line: '||lc_curr_line);
          lc_curr_line :=  REPLACE(lc_curr_line,chr(13),NULL);
          IF lc_record_count = 1 THEN
            IF UPPER(lc_curr_line) <>  ('DEVICE ID,SERIAL NUMBER,SUPPLIES LABEL,SUPPLIES LEVEL') THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'EX_BAD_FORMAT ERROR RAISED : '|| lc_curr_line);            
              RAISE ex_bad_format;
            END IF;            
          END IF;    
        
          IF lc_record_count > 1 THEN
            ln_tot_rec := ln_tot_rec + 1;
            SELECT TRIM(LENGTH( lc_curr_line ) ) - TRIM(LENGTH(TRANSLATE( lc_curr_line, 'A,', 'A' ) ) ) 
              INTO ln_no_of_commas
              FROM DUAL;

            --Read Data and assign to columns
            IF ln_no_of_commas = 3 THEN
              lc_device_id      := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,1,(INSTR(lc_curr_line, gc_ind,1,1)-1))),chr(13),NULL),1,149);
              lc_serial_number  := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,1)+1),(INSTR(lc_curr_line, gc_ind,1,2)-1)-(INSTR(lc_curr_line, gc_ind,1,1)))),chr(13),NULL),1,99);
              lc_supplies_label := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,2)+1),(INSTR(lc_curr_line, gc_ind,1,3)-1)-(INSTR(lc_curr_line, gc_ind,1,2)))),chr(13),NULL),1,99);
              lc_supplies_level := SUBSTR(REPLACE(TRIM(SUBSTR(lc_curr_line,(INSTR(lc_curr_line, gc_ind,1,3)+1))),chr(13),NULL),1,99);
              -- INSERT INTO TBL
              INSERT INTO xx_cs_mps_device_supplies( device_id
                                                   , serial_number
                                                   , supplies_label
                                                   , supplies_level
                                                   , attribute1
                                                   , attribute2
                                                   , attribute3
                                                   , attribute4
                                                   , attribute5
                                                   , creation_date
                                                   , created_by
                                                   , last_update_date
                                                   , last_updated_by
                                                   ) VALUES
                                                   ( lc_device_id
                                                   , lc_serial_number
                                                   , lc_supplies_label
                                                   , lc_supplies_level
                                                   , NULL
                                                   , NULL
                                                   , NULL
                                                   , NULL
                                                   , NULL
                                                   , ld_sys_date
                                                   , ln_user_id
                                                   , ld_sys_date
                                                   , ln_user_id
                                                   );                      
            ELSE
              DBMS_OUTPUT.PUT_LINE('lc_curr_line : '|| lc_curr_line);
              ln_failed_rec := ln_failed_rec + 1;          
              xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                                   , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                                   , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                                   , p_error_msg          => 'Record has bad data : '||lc_curr_line
                                                   );          
            END IF;
          END IF;            
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            UTL_FILE.fclose (lc_input_file_handle);
            EXIT;
          WHEN OTHERS THEN
            x_return_status := fnd_api.g_ret_sts_error;
            x_return_msg   := 'Error while reading: ' || SQLERRM;
            UTL_FILE.fclose (lc_input_file_handle);
            EXIT;
        END;
      END LOOP;
      x_return_status := fnd_api.g_ret_sts_success;
      x_return_msg    := 'Successfully extracted data and Inserted into table : '||lc_file_name;
    ELSE
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'No file attached to request_id  : '||p_request_id
                                           );
    x_return_status := fnd_api.g_ret_sts_success;
    x_return_msg    := 'No file attached to request_id  : '||p_request_id;    
    END IF;    
    UTL_FILE.fclose (lc_input_file_handle);
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No Of Records in File     : '||ln_tot_rec);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No Of Records Processed   : '||(ln_tot_rec-ln_failed_rec));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No Of Records Errored out : '||ln_failed_rec);
EXCEPTION
  WHEN UTL_FILE.invalid_path THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid file Path: ' || SQLERRM);
    x_return_status :=   fnd_api.g_ret_sts_error;
    x_return_msg    :=   'Invalid file Path: ' || SQLERRM;
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'Invalid file Path: ' || SQLERRM
                                         );
  WHEN UTL_FILE.invalid_mode THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Mode: ' || SQLERRM);
    x_return_status :=   fnd_api.g_ret_sts_error;
    x_return_msg    :=   'Invalid Mode: ' || SQLERRM;
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'Invalid Mode: ' || SQLERRM
                                         );

  WHEN UTL_FILE.invalid_filehandle THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid file handle: ' || SQLERRM);
    x_return_status :=   fnd_api.g_ret_sts_error;
    x_return_msg    :=   'Invalid file handle: ' || SQLERRM;
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'Invalid file handle: ' || SQLERRM
                                         );
  WHEN UTL_FILE.invalid_operation THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'File does not exist: ' || SQLERRM);
    x_return_status :=   fnd_api.g_ret_sts_error;
    x_return_msg    :=   'File does not exist: ' || SQLERRM;
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'File does not exist: ' || SQLERRM
                                         );
  WHEN UTL_FILE.read_error THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Read Error: ' || SQLERRM);
    x_return_status :=   fnd_api.g_ret_sts_error;
    x_return_msg    :=   'Read Error: ' || SQLERRM;
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'Read Error: ' || SQLERRM
                                         );
  WHEN UTL_FILE.internal_error THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Internal Error: ' || SQLERRM);
    x_return_status :=   fnd_api.g_ret_sts_error;
    x_return_msg    :=   'Internal Error: ' || SQLERRM;
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'Internal Error: ' || SQLERRM
                                         );
  WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Empty File: ' || SQLERRM);
    x_return_status :=   fnd_api.g_ret_sts_error;
    x_return_msg    :=   'Empty File: ' || SQLERRM;
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'Empty File: ' || SQLERRM
                                         );
  WHEN VALUE_ERROR THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Value Error: ' || SQLERRM);
    x_return_status :=   fnd_api.g_ret_sts_error;
    x_return_msg    :=   'Value Error: ' || SQLERRM;
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'Value Error: ' || SQLERRM
                                         );
  WHEN ex_bad_format THEN
    x_return_msg    :=   'Bad File format passed';
    x_return_status :=   fnd_api.g_ret_sts_error;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'ex_bad_format: '||x_return_msg);
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          =>  x_return_msg
                                         );                                            
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others: ' || SQLERRM);
    UTL_FILE.fclose (lc_input_file_handle);
    x_return_status :=   fnd_api.g_ret_sts_error;
    x_return_msg    :=   'When Others: ' || SQLERRM;
    xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                         , p_error_location     => 'XX_CS_MPS_AVF_FEED_PKG.MISC_FEED'
                                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                         , p_error_msg          => 'When Others MISC FEED: ' || SQLERRM
                                         );
END MISC_FEED;

END xx_cs_mps_avf_feed_pkg;
/************************************************************************************************************/
/
show errors;
exit;