create or replace
PACKAGE Body XX_PO_WMS_SHIP_LANE_PKG AS
-- +===========================================================================+
-- |    Office Depot - Project Simplify                                        |
-- |     Office Depot                                                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_PO_WMS_SHIP_LANE_PKG
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
-- |DRAFT 1A   20-OCT-2008   Rama Dwibhashyam Initial draft version  
-- |Version 2  05-MAR-2010   Debra Gaudard    Add code to retrieve the file from
-- |                                          the ftp/in drive and changed      
-- |                                          prefixes to xx_po*
-- |                                          CR 519/Defect 3365     
-- |DRAFT 1B  21-JUN-2012   ORACLE AMS Team  Modified code to update current 
-- |					      location's shipping priority
-- |					      to be in sync with data file  
-- |3.0       25-Nov-2015     Harvinder Rakhra    Retrofit R12.2                            | 
-- |4.0       12-Feb-2015     Madhu Bolli         Defect#35424 - Query only for interface existed records
-- +===========================================================================+

-- global variables

G_ERROR_COUNT     NUMBER := 0;
G_FILE_NAME       VARCHAR2 (100);
G_LOGIN_ID        NUMBER;
G_USER_ID         NUMBER;
g_filehandle      UTL_FILE.FILE_TYPE;

PROCEDURE Process_Shiplane(
      x_retcode           OUT NOCOPY  NUMBER
    , x_errbuf            OUT NOCOPY  VARCHAR2
    , p_filepath          IN          VARCHAR2
    , p_filename          IN          VARCHAR2
   
    ) AS
    lc_input_file_handle    UTL_FILE.file_type;
    ln_request_id           NUMBER := FND_GLOBAL.CONC_REQUEST_ID();
    lc_curr_line            VARCHAR2 (1000);
    lc_return_status        VARCHAR2(100);
    ln_debug_level          NUMBER := oe_debug_pub.g_debug_level;
    lc_errbuf               VARCHAR2(2000);
    ln_retcode              NUMBER;
    ln_record_count         NUMBER;
    ln_update_count         NUMBER;
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
    lc_in_file_path         VARCHAR2(100);
    ln_master_request_id    NUMBER;
    ln_file_run_count       BINARY_INTEGER;
    lc_location             VARCHAR2(20);
    lc_location_code        VARCHAR2(100);
    lc_legacy_loc_id        VARCHAR2(100);
    lc_door_lane            VARCHAR2(20);
    lc_assign_lane          VARCHAR2(20);
    ln_location_id          NUMBER;
    ln_obj_ver_num          NUMBER;
    ln_req_id               NUMBER;
    lc_phase                VARCHAR2(100);
    lc_status               VARCHAR2(100);
    lc_dev_phase            VARCHAR2(100);
    lc_dev_status           VARCHAR2(100);
    lb_bool                 BOOLEAN;
    lc_old_status           VARCHAR2(30);
    lc_message              VARCHAR2(100);
    lc_route		    VARCHAR2(20);      -- As per DRAFT 1B
    lc_route_cd             VARCHAR2(50);
    ln_meaning 		    VARCHAR2(50);
    lc_routes_cd	    VARCHAR2(50);	
    ln_update_count_1	    NUMBER;	
    
    
    CURSOR lcu_get_location IS      
      select hrl.location_id,hrl.location_code,nvl(hrl.attribute6,'NULL') ship_lane_before,
             xgs.loc_id legacy_loc_id,nvl(xgs.ship_lane,'NONE') ship_lane_after,hrl.object_version_number,
             xgs.route_cd   	       -- As per DRAFT 1B
        from xx_po_wms_ship_lane xgs
            ,hr_locations hrl
        where xgs.loc_id = substr(hrl.location_code,1,6)   -- 4.0 defect#35424
  --     where xgs.loc_id (+) = hrl.location_id    
       order by 2 ;    
       
    CURSOR lcu_get_routecd (locid varchar2) IS                    --  As per DRAFT 1B cursor is used to fetch lookup values used to compare with data file
      select lookup_type,lookup_code, attribute6,  substr(attribute7,1,4) rtcd
        from  FND_LOOKUP_VALUES_VL  
       where lookup_type = 'OD_LOC_SHIP_PRIORITY'
         and lookup_code = locid
         and enabled_flag = 'Y';

BEGIN
  BEGIN
       ----------------------------------------
       --Copy file from ftp directory to inbound file directory
       ----------------------------------------
       -- THE XXCOMFILECOPY concurrent program will move file from xxfin/ftp/in
       -- directory to the xxfin/inbound directory and xxfin/archive/in
       
    --   FND_FILE.Put_Line(FND_FILE.LOG,'Moving the file : '|| p_filename);
         dbms_lock.sleep(1);
         
         ln_req_id := fnd_request.submit_request('XXFIN','XXCOMFILCOPY',
                      '','01-OCT-04 00:00:00',FALSE,'$XXFIN_DATA/ftp/in/shippinglane/'||
                       p_filename,'$XXFIN_DATA/inbound/' ||
                       p_filename,'','','Y','$XXFIN_DATA/archive/inbound');
         COMMIT;
         
         lb_bool := fnd_concurrent.wait_for_request(ln_req_id
                                                    ,5
                                                    ,5000
                                                    ,lc_phase
                                                    ,lc_status
                                                    ,lc_dev_phase
                                                    ,lc_dev_status
                                                    ,lc_message
                                                     );
   END;
       --FND_FILE.Put_Line(FND_FILE.OUTPUT,'Debug Level: '||nvl(p_debug_level,0));

   --    IF nvl(p_debug_level, -1) >= 0 THEN
   --    END IF;

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
         LPAD ('Loc ID', 6, ' ') || ' ' ||
         RPAD ('Loc Name', 30, ' ') || ' ' ||
         RPAD ('Lane Info Before', 16, ' ') || ' ' ||
         RPAD ('Lane Info After', 16, ' '));
      --
      fnd_file.put_line (fnd_file.OUTPUT,
         LPAD ('-', 6, '-') || ' ' ||
         RPAD ('-', 30, '-') || ' ' ||
         RPAD ('-', 16, '-') || ' ' ||
	       RPAD ('-', 16, '-'));
    

    --ln_debug_level := nvl(p_debug_level,0);


    BEGIN
        lc_return_status := 'S';
        lc_file_path := p_filepath;
        fnd_file.put_line (fnd_file.LOG, 'Start Procedure ');
        fnd_file.put_line (fnd_file.LOG, 'File Path : ' || lc_file_path);
        fnd_file.put_line (fnd_file.LOG, 'File Name : ' || p_filename);

        lc_input_file_handle := UTL_FILE.fopen(lc_file_path, p_filename, 'R');
        fnd_file.put_line (fnd_file.LOG, 'Open Successful');
   
        
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
    execute immediate 'truncate table xxfin.xx_po_wms_ship_lane'; 
    end; 

    BEGIN
      ln_record_count := 0;
      ln_update_count := 0;
      ln_update_count_1 := 0;
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
   --     IF lc_record_type = 'SHARE'  OR
   --        NOT lb_has_records
    --      fnd_file.put_line (fnd_file.LOG, 'Record Count after read = ' || ln_record_count);
          IF lc_record_type = 'SHARE'  and
             lb_has_records
          THEN
             ln_record_count := ln_record_count + 1;
  --           fnd_file.put_line (fnd_file.LOG, 'File has data');
      		
            lc_location                            := LPAD(SUBSTR(lc_curr_line,15,5),6,0);
            lc_door_lane                           := LTRIM(RTRIM(SUBSTR (lc_curr_line,72,3)));
            lc_assign_lane                         := LTRIM(RTRIM(SUBSTR (lc_curr_line,89,3)));
            lc_ship_lane                           := lc_door_lane||' '||lc_assign_lane ;
            lc_route				   := LTRIM(RTRIM(SUBSTR (lc_curr_line,6,6)));  -- As Per DRAFT 1B
            
            insert into xx_po_wms_ship_lane ( 
                        loc_id
                       ,ship_lane
                       ,route_cd                         -- As per DRAFT 1B
                       ,created_by 
                       ,creation_date 
                       ,last_updated_by 
                       ,last_update_date 
                       ,last_update_login ) 
                       values
                      ( lc_location
                       ,lc_ship_lane
                       ,lc_route
                       ,g_user_id
                       ,sysdate
                       ,g_user_id
                       ,sysdate
                       ,g_login_id
                      );

            COMMIT;

        END IF;

        IF NOT lb_has_records THEN
           IF ln_record_count = 0 THEN
            -- nothing to process
            fnd_file.put_line (fnd_file.LOG, 'Empty File');
           ELSE 
            fnd_file.put_line (fnd_file.LOG, 'End of File');
           END IF;  
           UTL_FILE.fclose (lc_input_file_handle);
           Exit;
        END IF;

      END LOOP;
      
    EXCEPTION
        WHEN OTHERS THEN
            lc_error_flag := 'Y';
            ROLLBACK;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in Process Child :'||substr(SQLERRM,1,80));
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            UTL_FILE.fclose (lc_input_file_handle);
    END;

    fnd_file.put_line (fnd_file.LOG, 'Number of input records = ' || ln_record_count);
    IF ln_record_count > 0 THEN 
    FOR get_location_rec IN lcu_get_location
    LOOP
     --    fnd_file.put_line (fnd_file.LOG, 'Updating HR location data');
        ln_location_id      := get_location_rec.location_id ;
        lc_location_code    := get_location_rec.location_code ;
        lc_ship_lane_before := get_location_rec.ship_lane_before ;
        lc_legacy_loc_id    := get_location_rec.legacy_loc_id ;
        lc_ship_lane_after  := get_location_rec.ship_lane_after ;
        ln_obj_ver_num      := get_location_rec.object_version_number ;
        lc_route_cd         := get_location_rec.route_cd ;                  -- As per DRAFT 1B
    
   --   FND_FILE.Put_Line(FND_FILE.LOG,'SHIP LANE HR  : '|| lc_ship_lane_before);
   --   FND_FILE.Put_Line(FND_FILE.LOG,'SHIP LANE WMS : '|| lc_ship_lane_after);
      
      IF lc_ship_lane_before <> lc_ship_lane_after
      THEN
           ln_update_count := ln_update_count + 1;
           UPDATE hr_locations_all
              SET attribute_category = 'US'
                 ,attribute6 = nvl(lc_ship_lane_after,'NONE')
                 ,last_updated_by = g_user_id
                 ,last_update_date = sysdate
                 ,last_update_login = g_login_id             
            WHERE location_id = ln_location_id;
   
                    fnd_file.put_line(fnd_file.output,
                    LPAD (substr(lc_location_code,1,6), 6, ' ') || ' ' ||
                    RPAD (lc_location_code, 30, ' ') || ' ' ||
                    LPAD (nvl(lc_ship_lane_before,'NONE'), 16, ' ') || ' ' ||
                    LPAD (nvl(lc_ship_lane_after,'NONE'), 16, ' '));

            COMMIT;
      END IF;
      
      --  As per DRAFT 1B cursor is used to fetch lookup values to compare with data file
      
      FOR  lcu_get_rec IN lcu_get_routecd (lc_legacy_loc_id) LOOP
        
        
         lc_routes_cd  := LTRIM(RTRIM(SUBSTR (lc_route_cd,2)));
         
        -- fnd_file.put_line(FND_FILE.LOG,'Entered into LOOP ...');
          ln_meaning := null;
          
      BEGIN
      IF lc_legacy_loc_id =  lcu_get_rec.lookup_code 
      THEN
        IF lc_route_cd <> lcu_get_rec.rtcd
        THEN
        
           ln_update_count_1 := ln_update_count_1 + 1;
        
        BEGIN 
      -- fnd_file.put_line(FND_FILE.LOG,'lc_routes_cd value...'||lc_routes_cd);
        
         SELECT  UPPER(meaning)
           INTO  ln_meaning
	   FROM  FND_LOOKUP_VALUES_VL  
	  WHERE lookup_type = 'SHIPMENT_PRIORITY'
	    AND lookup_code  like lc_routes_cd||'%'
 	    AND enabled_flag = 'Y';
 	 
 	 EXCEPTION
 	   WHEN OTHERS THEN
 	    fnd_file.put_line(FND_FILE.LOG,'Error in fetching value from lookup');
 	 END;
 	  
 	--  fnd_file.put_line(FND_FILE.LOG,'ln_meaning value...'||ln_meaning);
 	
 	UPDATE FND_LOOKUP_VALUES
 	   SET attribute7 = NVL(ln_meaning,'FRIDAY PICK') 	   
 	 WHERE lookup_type = 'OD_LOC_SHIP_PRIORITY'
	   AND lookup_code = lc_legacy_loc_id
	   AND enabled_flag = 'Y'
	   and language = userenv('LANG');
	   
	  COMMIT; 
  	
        
         END IF; 
       
      END IF; 
      
       EXCEPTION
       	   WHEN OTHERS THEN
       	    fnd_file.put_line(FND_FILE.LOG,'Error in fetching values from cursor lookup');
       END;         
      
      END LOOP;
          
          --  End of DRAFT 1B
    END LOOP;       
    
    END IF;    
    
      fnd_file.put_line (fnd_file.LOG, 'Number of records updated = ' || ln_update_count); 
      fnd_file.put_line (fnd_file.LOG, 'Number of lookup values updated ='||ln_update_count_1);  --  As per DRAFT 1B getting count of records updated
      fnd_file.put_line (fnd_file.OUTPUT,RPAD ('-', 72, '-'));
      fnd_file.put_line (fnd_file.OUTPUT,RPAD (' ', 25, ' ') || '***End of the Report***');
      
      
      x_retcode := 0;
EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
        rollback;
        x_retcode := 2;
        x_errbuf := substr(SQLERRM,1,80);
        fnd_file.put_line(FND_FILE.LOG,'Error in reading the file :'||substr(SQLERRM,1,80));
        raise FND_API.G_EXC_ERROR;
    WHEN OTHERS THEN
        rollback;
        x_retcode := 2;
        x_errbuf := substr(SQLERRM,1,80);
        fnd_file.put_line(FND_FILE.LOG,'Unexpected error in Process Shipping Lane :'||substr(SQLERRM,1,80));
        raise FND_API.G_EXC_ERROR;
  
END Process_Shiplane;

END XX_PO_WMS_SHIP_LANE_PKG;

/