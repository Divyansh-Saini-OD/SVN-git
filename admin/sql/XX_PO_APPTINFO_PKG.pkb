CREATE OR REPLACE PACKAGE body APPS.XX_PO_APPTINFO_PKG AS
/******************************************************************************
   NAME:       XX_PO_APPTINFO_PKG 
   PURPOSE:    Write Appointment Info from XX_PO_APPOINTMENT_DATE_TEMP to 
               XX_PO_APPOINTMENT_DATE for both Conversion and Interface processing 


   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        9/19/2007   Roc Polimeni      Initial Development
******************************************************************************/

PROCEDURE XX_PO_APPTINFO(x_error_buff	OUT	VARCHAR2
                        ,x_ret_code	    OUT	VARCHAR2)
IS

   L_operating_unit                        number := 0;   -- ebs var
   L_po_number                             VARCHAR2(50);  -- Local copy of PO number (strip any concat locs) 
   L_insert_appt_date_cnt                  number := 0;   -- Count of inserted appt dates 
   L_dup_appt_date_cnt                     number := 0;   -- Count of dup appt dates
   L_no_appt_date_cnt                      number := 0;   -- Count of missing appt dates
   L_unknown_err_appt_date_cnt             number := 0;   -- Count of unknown errors processed
   L_commit_cnt                            number := 0;   -- Commit records count 
   L_loop_cnt                              number := 0;   -- Conversion Loop process count 
   L_po_result                             number := 0;   -- number of times PO Num exists in EBS 
   L_po_not_exist_appt_date_cnt            number := 0;   -- Count of non-existant POs 
   L_do_not_insert_rec                     number := 0;   -- Error flag; will not insert record if this flag is set 
   err_code                                number;
   err_msg                                 VARCHAR2 (100);     
   RECORD_LOCKED                           EXCEPTION;
   PRAGMA                                  EXCEPTION_INIT(Record_Locked, -54);

   cursor C_get_appt_date is
     select * 
     from xx_po_appointment_date_temp;             
   L_appt_info                C_get_appt_date%ROWTYPE;
      
            
   BEGIN
   
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Starting Package XX_PO_APPT_INFO_PKG......');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
      open  C_get_appt_date;
         
      LOOP         
        L_do_not_insert_rec := 0;                               -- reset do not insert record flag 
        L_loop_cnt := L_loop_cnt + 1;
        
        fetch C_get_appt_date into L_appt_info;                 -- first time to prime for loop 
        exit when C_get_appt_date%NOTFOUND;

        -- Manhattan PO Number formats can be concatenated with the location id,
        -- delimited by a "-".      
        IF ( INSTR(L_appt_info.po_number, '-') = 0 ) THEN 
            L_po_number := L_appt_info.po_number;
        ELSE
            L_po_number := SUBSTR(L_appt_info.po_number, 1, 
                INSTR(L_appt_info.po_number, '-') - 1);
        END IF;

        -- Does the PO already exist in EBS?
        SELECT COUNT (*) INTO L_po_result
        FROM po_headers_all
        WHERE segment1 = L_po_number;
     
        -- PO Number can exist in EBS more than once.
        IF (L_po_result = 1) THEN  -- if 1 PO exists in EBS (po is unique)  

             SELECT Org_ID INTO L_operating_unit
             FROM po_headers_all
             WHERE segment1 = L_po_number;

        ELSIF (L_po_result > 1) THEN  -- if more than 1 PO exists in EBS (get ou from loc) 

          BEGIN         
                   
             SELECT operating_unit INTO L_operating_unit
             FROM org_organization_definitions
             WHERE organization_id = 
                  (SELECT organization_id
                   FROM hr_all_organization_units
                   WHERE attribute1 = L_appt_info.loc_number);

             -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Debug: Select operating_unit ' || L_operating_unit);
          EXCEPTION 
           WHEN TOO_MANY_ROWS THEN 
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Debug: Too many Locs found ' || TRIM (L_appt_info.loc_number));
              
              L_do_not_insert_rec := 1;       -- set do not insert record flag 
              L_dup_appt_date_cnt := L_dup_appt_date_cnt + 1;
              
              UPDATE xx_po_appointment_date_temp
              SET process_status = '3'
              WHERE po_number = L_appt_info.po_number
              AND   appointment_number = L_appt_info.appointment_number
              AND   loc_number = L_appt_info.loc_number;
              
              x_ret_code := 1;
               
              -- placeholder for new plsql error table name and data format   
        
           WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Debug: No Data Found for Loc ' || TRIM (L_appt_info.loc_number));
              
              L_do_not_insert_rec := 1;            -- set do not insert record flag 
              L_no_appt_date_cnt := L_no_appt_date_cnt + 1;
              
              UPDATE xx_po_appointment_date_temp
              SET process_status = '3'
              WHERE po_number = L_appt_info.po_number
              AND   appointment_number = L_appt_info.appointment_number
              AND   loc_number = L_appt_info.loc_number; 
              
              x_ret_code := 1;
               
              -- placeholder for new plsql error table name and data format   
     
           WHEN others THEN
              err_code := SQLCODE;
              err_msg := substr(SQLERRM, 1, 200);        
              
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Debug: Unknown Error on location lookup ' || 
                                TRIM (L_appt_info.loc_number) ||
                                ' err code ' || err_code ||
                                ' err msg '  || err_msg);
              
              L_do_not_insert_rec := 1;       -- set do not insert record flag 
              L_unknown_err_appt_date_cnt := L_unknown_err_appt_date_cnt + 1;
              
              UPDATE xx_po_appointment_date_temp
              SET process_status = '3'
              WHERE po_number = L_appt_info.po_number
              AND   appointment_number = L_appt_info.appointment_number
              AND   loc_number = L_appt_info.loc_number;
              
              x_ret_code := 1;
               
              -- placeholder for new plsql error table name and data format   
          END;      
        ELSE  -- PO does not exist 
              L_po_not_exist_appt_date_cnt := L_po_not_exist_appt_date_cnt + 1;
              
              UPDATE xx_po_appointment_date_temp
              SET process_status = '6'
              WHERE po_number = L_appt_info.po_number
              AND   appointment_number = L_appt_info.appointment_number
              AND   loc_number = L_appt_info.loc_number;
              
              x_ret_code := 1;
               
              -- placeholder for new plsql error table name and data format           
              -- 'PO does not exist in EBS'
 
              -- err_code := SQLCODE;
              -- err_msg := substr(SQLERRM, 1, 200);   
              L_do_not_insert_rec := 1;     -- set error condition: do not insert record
        END IF;   
                 
        BEGIN
          -- check for error condition where we would not want to insert a record
          IF (L_do_not_insert_rec = 0) THEN
       
              INSERT INTO xx_po_appointment_date
              (po_number, 
               appointment_number, 
               org_id, 
               appointment_date,
               created_by,
               creation_date,
               last_updated_by,
               last_update_date,
               last_update_login)

              VALUES
              (L_po_number, 
               L_appt_info.appointment_number,
               L_operating_unit,  
               L_appt_info.appointment_date, 
               apps.fnd_global.user_id,    
               SYSDATE,
               apps.fnd_global.user_id,    
               SYSDATE,
               apps.fnd_global.login_id
               );
       
               L_insert_appt_date_cnt := L_insert_appt_date_cnt + 1;
               UPDATE xx_po_appointment_date_temp
               SET process_status = '7'
               WHERE po_number = L_appt_info.po_number
               AND   appointment_number = L_appt_info.appointment_number
               AND   loc_number = L_appt_info.loc_number;       
       
              IF L_commit_cnt > 1000 THEN
                  commit;
                  L_commit_cnt := 0;
              ELSE
                  L_commit_cnt := L_commit_cnt + 1;
              END IF;       
               
          END IF;
       
        EXCEPTION
        WHEN others THEN
              err_code := SQLCODE;
              err_msg := substr(SQLERRM, 1, 200);
                      
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Debug: Unknown Error on insert ' ||
                      L_appt_info.po_number || ' ' ||
                      L_appt_info.appointment_number || ' ' ||      
                      TRIM (L_appt_info.loc_number) ||
                                ' err code ' || err_code ||
                                ' err msg '  || err_msg);
                                
              L_unknown_err_appt_date_cnt := L_unknown_err_appt_date_cnt + 1;
              
              UPDATE xx_po_appointment_date_temp
              SET process_status = '3'
              WHERE po_number = L_appt_info.po_number
              AND   appointment_number = L_appt_info.appointment_number
              AND   loc_number = L_appt_info.loc_number;
              
              x_ret_code := 1;
              -- placeholder for new plsql error table name and data format   
              -- err_code || ' ' || err_msg);     
        END;
           
      END LOOP;

      close C_get_appt_date;
      commit;
       x_ret_code := 0;
       
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Totals: ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Insert_appt_date_Cnt: ' || L_insert_appt_date_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Dup_appt_date_Cnt: '    || L_dup_appt_date_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'No_appt_dateCnt: '      || L_no_appt_date_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Unknown_err_Cnt: '      || L_unknown_err_appt_date_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PO_not_exist_Cnt: '     || L_po_not_exist_appt_date_cnt);  

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');      
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Ended Package XX_PO_APPT_INFO_PKG');

   END XX_PO_APPTINFO;  

END XX_PO_APPTINFO_PKG; 
/

