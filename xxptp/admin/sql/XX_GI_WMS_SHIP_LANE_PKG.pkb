SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY APPS.XX_GI_WMS_SHIP_LANE_PKG AS

-- +===========================================================================+
-- |    Office Depot - Project Simplify                                        |
-- |     Office Depot                                                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_GI_WMS_SHIP_LANE_PKG
-- | Description      : Package Body
-- |
-- |
-- |
-- |Change Record:
-- |
-- |===============
-- |
-- |Version    Date          Author           Remarks
-- |=======    ==========    =============    =================================+
-- |DRAFT 1A   20-OCT-2008   Rama Dwibhashyam Initial draft version            |
-- +===========================================================================+
PROCEDURE Process_Shiplane(
      x_retcode           OUT NOCOPY  NUMBER
    , x_errbuf            OUT NOCOPY  VARCHAR2
    , p_filename          IN          VARCHAR2
    , p_filepath          IN          VARCHAR2
    ) IS


    lc_input_file_handle    UTL_FILE.file_type;
    lc_curr_line            VARCHAR2 (1000);
    lc_return_status        VARCHAR2(100);
    ln_debug_level          NUMBER := oe_debug_pub.g_debug_level;
    lc_errbuf               VARCHAR2(2000);
    ln_retcode              NUMBER;
    ln_request_id           NUMBER;
    lc_file_path            VARCHAR2(100) := p_filepath;
    lb_has_records          BOOLEAN;
    i                       BINARY_INTEGER;
    lc_ship_lane            hr_locations_all.attribute6%TYPE;
    lc_ship_lane_before     hr_locations_all.attribute6%TYPE;
    lc_ship_lane_after      hr_locations_all.attribute6%TYPE;
    lc_record_type          VARCHAR2(10);
    lc_error_flag           VARCHAR2(1) := 'N';
    lc_filename             VARCHAR2(100);
    lc_filedate             VARCHAR2(30);
    lb_at_trailer           BOOLEAN := FALSE;
    lc_arch_path            VARCHAR2(100);
    ln_master_request_id    NUMBER;
    ln_file_run_count       BINARY_INTEGER;
    lc_location                VARCHAR2(20);
    lc_location_code           VARCHAR2(100);
    lc_legacy_loc_id           VARCHAR2(100);
    lc_door_lane               VARCHAR2(20);
    lc_assign_lane             VARCHAR2(20);
    ln_location_id             NUMBER;
    ln_obj_ver_num             NUMBER;

       
    CURSOR lcu_get_location IS      
    select hrl.location_id,hrl.location_code,nvl(hrl.attribute6,'NULL') ship_lane_before,
           xgs.loc_id legacy_loc_id,nvl(xgs.ship_lane,'NONE') ship_lane_after,hrl.object_version_number
    from xxptp.xx_gi_wms_ship_lane xgs
        ,hr_locations hrl
    where xgs.loc_id (+) = substr(hrl.location_code,1,6)    
    order by 2 ;       

    
BEGIN
    --Initialize the error count
    g_error_count := 0;

    --FND_FILE.Put_Line(FND_FILE.OUTPUT,'Debug Level: '||nvl(p_debug_level,0));

--    IF nvl(p_debug_level, -1) >= 0 THEN
--    END IF;

    --FND_FILE.Put_Line(FND_FILE.OUTPUT,'Processing The file : '|| p_filename);
    
             -- Header
      fnd_file.put_line (fnd_file.OUTPUT,' ');
      fnd_file.put_line (fnd_file.OUTPUT,' ');
      fnd_file.put_line (fnd_file.OUTPUT,RPAD (' ', 20, ' ') || 'WMS Shipping Lane Interface Report');
      fnd_file.put_line (fnd_file.OUTPUT,' ');
      fnd_file.put_line (fnd_file.OUTPUT,'File Name :'||p_filename);
      fnd_file.put_line (fnd_file.OUTPUT,' ');
      fnd_file.put_line (fnd_file.OUTPUT,' ');
      fnd_file.put_line (fnd_file.OUTPUT,'Summary Report');
      fnd_file.put_line (fnd_file.OUTPUT,' ');
      fnd_file.put_line (fnd_file.OUTPUT,RPAD ('-', 72, '-'));
      fnd_file.put_line (fnd_file.OUTPUT,
         --RPAD ('Status', 15, ' ') || ' ' ||
         LPAD ('Loc ID', 6, ' ') || ' ' ||
         RPAD ('Loc Name', 30, ' ') || ' ' ||
         RPAD ('Lane Info Before', 16, ' ') || ' ' ||
         RPAD ('Lane Info After', 16, ' '));
      --
      fnd_file.put_line (fnd_file.OUTPUT,
         --RPAD ('-', 15, '-') || ' ' ||
         LPAD ('-', 6, '-') || ' ' ||
         RPAD ('-', 30, '-') || ' ' ||
         RPAD ('-', 16, '-') || ' ' ||
	     RPAD ('-', 16, '-'));
    

    --ln_debug_level := nvl(p_debug_level,0);


    BEGIN
        lc_return_status := 'S';

        fnd_file.put_line (fnd_file.LOG, 'Start Procedure ');
        fnd_file.put_line (fnd_file.LOG, 'File Path : ' || lc_file_path);
        fnd_file.put_line (fnd_file.LOG, 'File Name : ' || p_filename);

        lc_input_file_handle := UTL_FILE.fopen(lc_file_path, p_filename, 'R');


    EXCEPTION
    WHEN UTL_FILE.invalid_path THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid Path: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_mode THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid Mode: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_filehandle THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid file handle: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_operation THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid operation222: ' || SQLERRM ||'::::'||p_filename );
         lc_errbuf := 'Can not find the Shipping Lane file :'||p_filename||' in '||lc_file_path;
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.read_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Read Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.write_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Write Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.internal_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Internal Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN NO_DATA_FOUND THEN
         fnd_file.put_line (fnd_file.LOG, 'No data found: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN VALUE_ERROR THEN
         fnd_file.put_line (fnd_file.LOG, 'Value Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN OTHERS THEN
         UTL_FILE.fclose (lc_input_file_handle);
         RAISE FND_API.G_EXC_ERROR;
    END;

    lb_has_records := TRUE;
    g_file_name := p_filename;
    i := 0;
    ln_file_run_count := 0 ;

    -- truncate staging table every time before loading the file data. 
    begin 
    execute immediate 'truncate table xxptp.xx_gi_wms_ship_lane'; 
    end; 

    BEGIN
      LOOP
        BEGIN
             lc_curr_line := NULL;
            /* UTL FILE READ START */
            UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            fnd_file.put_line (fnd_file.LOG, 'NO MORE RECORD TO READ');
            lb_has_records := FALSE;
        WHEN OTHERS THEN
          x_retcode := 2;
          fnd_file.put_line(FND_FILE.OUTPUT,'Unexpected error '||substr(sqlerrm,1,200));
          fnd_file.put_line(FND_FILE.OUTPUT,'');
          x_errbuf := 'Please check the log file for error messages';
          lb_has_records := FALSE;
           RAISE FND_API.G_EXC_ERROR;
        END;

        -- Always get the exact byte length in lc_curr_line to avoid reading new line characters
        lc_curr_line := substr(lc_curr_line,1,91);
        --fnd_file.put_line(FND_FILE.OUTPUT,lc_curr_line);
        lc_record_type := substr(lc_curr_line,1 ,5);

        -- check to see the first 5 chars
        IF lc_record_type = 'SHARE'  OR
           NOT lb_has_records
        THEN
            --fnd_file.put_line(FND_FILE.LOG,'Before Process Current Record :');
            
            --fnd_file.put_line(FND_FILE.LOG,'Before updating Current Record :');
            lc_location                            := LPAD(SUBSTR(lc_curr_line,15,5),6,0);
            lc_door_lane                           := LTRIM(RTRIM(SUBSTR (lc_curr_line,72,3)));
            lc_assign_lane                         := LTRIM(RTRIM(SUBSTR (lc_curr_line,89,3)));
            lc_ship_lane                           := lc_door_lane||' '||lc_assign_lane ;
            
            
            
            insert into xxptp.xx_gi_wms_ship_lane ( 
                        loc_id
                       ,ship_lane
                       ,created_by 
                       ,creation_date 
                       ,last_updated_by 
                       ,last_update_date 
                       ,last_update_login ) 
                       values
                      ( lc_location
                       ,lc_ship_lane
                       ,g_user_id
                       ,sysdate
                       ,g_user_id
                       ,sysdate
                       ,g_login_id
                      );
--            
--            HR_LOCATION_API.update_location
--                            (
--                             p_effective_date       => SYSDATE
--                            ,p_location_id          => ln_location_id
--                            ,p_object_version_number=> ln_obj_ver_num
--                            ,p_attribute_category   => 'US'
--                            ,p_attribute6           => lc_ship_lane
--                            );
    
           -- G_header_counter := G_header_counter + 1;
           -- fnd_file.put_line(FND_FILE.LOG,'Number of Records updated :'||g_header_counter);

            COMMIT;

        END IF;

        IF NOT lb_has_records THEN
            -- nothing to process
            UTL_FILE.fclose (lc_input_file_handle);
            Exit;
        END IF;

      END LOOP;
      
    EXCEPTION
        WHEN OTHERS THEN
            lc_error_flag := 'Y';
            ROLLBACK;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in Process Child :'||substr(SQLERRM,1,80));
            -- Send email notification
          --  SEND_NOTIFICATION('DEPOSIT unexpected Error','Unexpected error while processing the file : '||p_filename || 'Check the request log for request_id :'||g_request_id);
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            UTL_FILE.fclose (lc_input_file_handle);
    END;


     
    FOR get_location_rec IN lcu_get_location
    LOOP
    
        ln_location_id      := get_location_rec.location_id ;
        lc_location_code    := get_location_rec.location_code ;
        lc_ship_lane_before := get_location_rec.ship_lane_before ;
        lc_legacy_loc_id    := get_location_rec.legacy_loc_id ;
        lc_ship_lane_after  := get_location_rec.ship_lane_after ;
        ln_obj_ver_num      := get_location_rec.object_version_number ;
    
    
      IF lc_ship_lane_before <> lc_ship_lane_after
      THEN
      
           UPDATE hr_locations_all
              SET attribute_category = 'US'
                 ,attribute6 = nvl(lc_ship_lane_after,'NONE')
                 ,last_updated_by = g_user_id
                 ,last_update_date = sysdate
                 ,last_update_login = g_login_id             
            WHERE location_id = ln_location_id ;
   
                 fnd_file.put_line(fnd_file.output,
                    LPAD (substr(lc_location_code,1,6), 6, ' ') || ' ' ||
                    RPAD (lc_location_code, 30, ' ') || ' ' ||
                    LPAD (nvl(lc_ship_lane_before,'NONE'), 16, ' ') || ' ' ||
                    LPAD (nvl(lc_ship_lane_after,'NONE'), 16, ' '));

            COMMIT;
      END IF;
          
    END LOOP;
       
      

    -- Move the file to archive directory
    BEGIN
        --lc_arch_path := p_arch_path;
        -- UTL_FILE.FRENAME(lc_file_path, p_filename, lc_arch_path, p_filename||'.done');
        --UTL_FILE.FCOPY(lc_file_path, p_filename, lc_arch_path, p_filename||'.done');
        UTL_FILE.FREMOVE(lc_file_path, p_filename);
    EXCEPTION
        WHEN UTL_FILE.delete_failed THEN
         fnd_file.put_line (fnd_file.LOG, 'Error While deleting the file: ' || SQLERRM);
        WHEN UTL_FILE.invalid_path THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid Path: ' || SQLERRM);
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to Remove the File.'|| SQLERRM);
    END;

      fnd_file.put_line (fnd_file.OUTPUT,RPAD ('-', 72, '-'));
      fnd_file.put_line (fnd_file.OUTPUT,RPAD (' ', 25, ' ') || '***End of the Report***');
      
    x_retcode := 0;
EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
        rollback;
        x_retcode := 2;
        x_errbuf := substr(SQLERRM,1,80);
        fnd_file.put_line(FND_FILE.LOG,'Error in reading the file :'||substr(SQLERRM,1,80));
        --SEND_NOTIFICATION('Deposit File Missing',lc_errbuf);
        raise FND_API.G_EXC_ERROR;
    WHEN OTHERS THEN
        rollback;
        x_retcode := 2;
        x_errbuf := substr(SQLERRM,1,80);
        fnd_file.put_line(FND_FILE.LOG,'Unexpected error in Process Shipping Lane :'||substr(SQLERRM,1,80));
        --SEND_NOTIFICATION('Error in Processing Deposits ',
        --    'Unexpected error in Process Deposit :'||substr(SQLERRM,1,80) || ' in File ' ||p_filename);
        raise FND_API.G_EXC_ERROR;
END Process_Shiplane;

END XX_GI_WMS_SHIP_LANE_PKG;
/

SHOW ERRORS;
EXIT