CREATE OR REPLACE PACKAGE body APPS.XX_PO_SHIPSTAT_CONV_PKG AS
/******************************************************************************
   NAME:       XX_PO_SHIPSTAT_CONV_PKG 
   PURPOSE:    Process the Load portion of the PO Ship Status Conversions,
               which will take data from from XX_PO_SHIP_STATUS_CONV_STG,
               determine the EBS Organization ID and which ship date we're
               processing, and write the result to XX_PO_SHIP_STATUS 

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        9/19/2007   Roc Polimeni         1. Created this package.
******************************************************************************/


PROCEDURE XX_PO_SHIPSTAT_CONV    
IS


   L_ship_date                       date;          -- 1 of 3 possible dates in a given record 
   L_est_arrival_date                date;          -- 1 of 3 possible dates in a given record 
   L_arrival_date                    date;          -- 1 of 3 possible dates in a given record 
   L_operating_unit                  VARCHAR2(10);  -- ebs var
   L_dup_org_id_cnt                  number := 0;   -- count of Org_ID duplicate recs
   L_no_org_id_cnt                   number := 0;   -- count of Org_ID missing recs
   L_unknown_err_cnt                 number := 0;   -- count of unknown errors
   L_insert_dup_cnt                  number := 0;   -- count of po's with more than one org id 
   L_commit_cnt                      number := 0;   -- count of committed records
   L_loop_cnt                        number := 0;   -- number of records processed in loop
   L_po_result                       number := 0;   -- how many times po appears in ebs po headers
   L_po_not_exist_cnt                number := 0;   -- count of po's not found in ebs
   L_do_not_insert_rec               number := 0;   -- flag used to prevent insert erring records
   err_code                          number;
   err_msg                           VARCHAR2 (100);
   RECORD_LOCKED                     EXCEPTION;
   PRAGMA                            EXCEPTION_INIT(Record_Locked, -54);

   cursor C_get_ship_status is
     select * 
     from xx_po_ship_status_conv_stg;             
   L_ship_status                C_get_ship_status%ROWTYPE;
      
                 
   BEGIN

      -- call standard load control function with conversion_id, batch_id,
      --                                          num_bus_objs_processed
      xx_com_conv_elements_pkg.log_control_info_proc(302, 10, 100);  
      open  C_get_ship_status;

      LOOP         
        L_do_not_insert_rec := 0;       -- reset do not insert record flag
        L_loop_cnt := L_loop_cnt + 1;
        --    DBMS_OUTPUT.PUT_LINE('Debug: loop cnt ' || L_loop_cnt);
       
        FETCH C_get_ship_status into L_ship_status; -- first time to prime for loop 
        EXIT WHEN C_get_ship_status%NOTFOUND;

        -- Does the PO already exist in EBS?
        SELECT COUNT (*) INTO L_po_result
        FROM po_headers_all
        WHERE segment1 = L_ship_status.document_nbr;
   
        IF (L_po_result = 1) THEN  -- if 1 PO exists in EBS (unique PO)  
     
             SELECT Org_ID INTO L_operating_unit
             FROM po_headers_all
             WHERE segment1 = L_ship_status.document_nbr;

             DBMS_OUTPUT.PUT_LINE('Debug: Select operating_unit (Org_ID) ' || 
              L_operating_unit);                              
        
        ELSIF (L_po_result > 1) THEN  -- if more than 1 PO exists in EBS (get operating unit from loc)
 
           BEGIN   
               SELECT operating_unit INTO L_operating_unit
               FROM org_organization_definitions
               WHERE organization_id = 
                  (SELECT inventory_organization_id
                   FROM hr_locations_all
                   WHERE location_code = L_ship_status.loc_id); -- loc_code = varchar
                              
               -- validation errors to be written to reject or error table
               -- and stg table has process_status field updated to an error
           EXCEPTION 
             WHEN TOO_MANY_ROWS THEN 
                    L_do_not_insert_rec := 1;       -- set do not insert record flag
                    L_dup_org_id_cnt := L_dup_org_id_cnt + 1;
                    UPDATE xx_po_ship_status_conv_stg
                    SET process_status = '3'
                    WHERE document_nbr = L_ship_status.document_nbr
                    AND   loc_id       = L_ship_status.loc_id;

                    err_code := SQLCODE;
                    err_msg := substr(SQLERRM, 1, 200);        
             
                    xx_com_conv_elements_pkg.log_exceptions_proc('C0302', 18, '108',
                           'ship_stat', 'odshipstat_conv',
                           'xx_po_ship_status_conv_stg',
                           'operating_unit', L_operating_unit, 'ssr', 5,
                           'shipstatus', err_code, err_msg );
       
             WHEN NO_DATA_FOUND THEN
                  L_do_not_insert_rec := 1;       -- set do not insert record flag
                  L_no_org_id_cnt := L_no_org_id_cnt + 1;
                  UPDATE xx_po_ship_status_conv_stg
                  SET process_status = '3'
                  WHERE document_nbr = L_ship_status.document_nbr
                  AND   loc_id       = L_ship_status.loc_id; 

                  err_code := SQLCODE;
                  err_msg := substr(SQLERRM, 1, 200);        

                      -- parms: conv_code, record_control_id, source_system_code,      
                      --        package_name, procedure_name, staging_table_name,
                      --        staging_column_name, staging_column_value, 
                      --        source_system_ref, batch_id, exception_log,
                      --        oracle_error_code, oracle_error_msg                
              
                      --  procedure log_exceptions_proc updates table xx_com_exceptions_log_conv 
                      --  in schema xxcomn 
                      
                  xx_com_conv_elements_pkg.log_exceptions_proc('C0302', 18, '108',
                          'ship_stat', 'odshipstat_conv', 'xx_po_ship_status_conv_stg',
                          'operating_unit', L_operating_unit, 'ssr', 5,
                          'shipstatus', err_code, 'No Location or Org_ID found');
         
             WHEN others THEN
                  err_code := SQLCODE;
                  err_msg := substr(SQLERRM, 1, 200);        
                  L_do_not_insert_rec := 1;       -- set do not insert record flag
                  L_unknown_err_cnt := L_unknown_err_cnt + 1;
             
                  UPDATE xx_po_ship_status_conv_stg
                  SET process_status = '3'
                  WHERE document_nbr = L_ship_status.document_nbr
                  AND   loc_id       = L_ship_status.loc_id;

                       -- parms: conv_id, record_control_id, source_system_code,      
                       --        package_name, procedure_name, staging_table_name,
                       --        staging_column_name, staging_column_value, 
                       --        source_system_ref, batch_id, exception_log,
                       --        oracle_error_code, oracle_error_msg                
       
                  xx_com_conv_elements_pkg.log_exceptions_proc(308, 18, '108',
                          'ship_stat', 'odshipstat_conv', 'xx_po_ship_status_conv_stg',
                          'operating_unit', L_operating_unit, 'ssr', 5,
                          'shipstatus', err_code, err_msg );       
           END;      

        ELSE      -- PO does not exist
              L_po_not_exist_cnt := L_po_not_exist_cnt + 1;
              UPDATE xx_po_ship_status_conv_stg
              SET process_status = '6'
              WHERE document_nbr = L_ship_status.document_nbr
              AND   loc_id       = L_ship_status.loc_id;

              err_code := SQLCODE;
              err_msg := substr(SQLERRM, 1, 200);        

                       -- parms: conv_id, record_control_id, source_system_code,      
                       --        package_name, procedure_name, staging_table_name,
                       --        staging_column_name, staging_column_value, 
                       --        source_system_ref, batch_id, exception_log,
                       --        oracle_error_code, oracle_error_msg                
      
              xx_com_conv_elements_pkg.log_exceptions_proc(308, 18, '108',
                      'ship_stat', 'odshipstat_conv', 'xx_po_ship_status_conv_stg',
                      'operating_unit', L_operating_unit, 'ssr', 5,
                      'shipstatus', err_code, 'PO does not exist in EBS');

              L_do_not_insert_rec := 1;     -- set error condition: do not insert record
   
        END IF;     -- end po exist if  

        -- populate date fields for db insert          
        IF L_ship_status.ship_dt IS NULL then
                 L_ship_date := '';
        ELSE                                  
                 L_ship_date := TO_DATE(TO_CHAR(L_ship_status.ship_dt)||' '||
                                TO_CHAR(L_ship_status.ship_tm),
                               'DD-MON-YY HH24:MI:SS');
        END IF;

        IF L_ship_status.est_arrival_dt IS NULL then
                 L_est_arrival_date := '';
        ELSE  
                 L_est_arrival_date :=
                         TO_DATE(TO_CHAR(L_ship_status.est_arrival_dt)||' '||
                         TO_CHAR(L_ship_status.est_arrival_tm),
                              'DD-MON-YY HH24:MI:SS');
        END IF;

        IF L_ship_status.arrival_dt IS NULL THEN
                 L_arrival_date := '';
        ELSE  
                 L_arrival_date :=
                         TO_DATE(TO_CHAR(L_ship_status.arrival_dt)||' '||
                         TO_CHAR(L_ship_status.arrival_tm),
                              'DD-MON-YY HH24:MI:SS');
        END IF;
           
        BEGIN                      
           -- check for error condition where we would not want to insert a record 
           IF (L_do_not_insert_rec = 0) THEN
     
                   INSERT INTO xx_po_ship_status
                   (po_number,
                    carrier_code, 
                    bill_of_lading, 
                    pro_bill_number,
                    actual_arrival_date,
                    shipped_date, 
                    estimated_arrival_date, 
                    org_id,
                    reason,
                    created_by, 
                    creation_date,
                    last_updated_by, 
                    last_update_date,
                    last_update_login
                   )

                   VALUES(L_ship_status.document_nbr,
                    L_ship_status.scac,
                    L_ship_status.bill_of_lading, 
                    L_ship_status.pro_bill_nbr,
                    L_arrival_date, 
                    L_ship_date,
                    L_est_arrival_date, 
                    L_operating_unit,   
                    L_ship_status.reason_cd,
                    --   L_ship_status.pgm_ent,
                    apps.fnd_global.user_id,
                    --   L_ship_status.dt_ent,
                    SYSDATE,
                    --   L_ship_status.user_id_chg_by,
                    apps.fnd_global.user_id,
                    --   L_ship_status.dt_chg,
                    SYSDATE,
                    --   L_ship_status.user_id_chg_by
                    apps.fnd_global.login_id                  
                    );
 
                   -- make update to indicate record successfully processed 
                   UPDATE xx_po_ship_status_conv_stg
                   SET process_status = '7'
                   WHERE document_nbr = L_ship_status.document_nbr
                   AND   loc_id       = L_ship_status.loc_id;       
        
                   -- po is processed, so update count and maybe commit 
                   IF L_commit_cnt > 1000 THEN
                       COMMIT;
                       L_commit_cnt := 0;
                   ELSE
                       L_commit_cnt := L_commit_cnt + 1;
                   END IF;      

           END IF;

        EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN  -- more than one org_id found 
                 err_code := SQLCODE;
                 err_msg := substr(SQLERRM, 1, 200);        
      
                 L_do_not_insert_rec := 1;       -- set do not insert record flag
                 L_insert_dup_cnt := L_insert_dup_cnt + 1; 
                 --  DBMS_OUTPUT.PUT_LINE('dup on insert ' || L_operating_unit ||
                 --         ' err code ' || err_code ||
                 --         ' err msg '  || err_msg);
                        
                 UPDATE xx_po_ship_status_conv_stg
                   SET process_status = '6'
                   WHERE document_nbr = L_ship_status.document_nbr
                   AND   loc_id       = L_ship_status.loc_id;
 
                 -- stored procedure will update table xx_com_exceptions_log_conv
                 xx_com_conv_elements_pkg.log_exceptions_proc(308, 18, '108',
                         'ship_stat', 'odshipstat_conv',
                         'xx_po_ship_status_conv_stg',
                         'operating_unit', L_operating_unit, 'ssr', 5,
                         'shipstatus', err_code, err_msg );     
        END;           
 
      END LOOP;

      CLOSE C_get_ship_status;
      COMMIT;
   
      DBMS_OUTPUT.PUT_LINE('Valid Ship Status Records: '  || L_commit_cnt);
      DBMS_OUTPUT.PUT_LINE('Dup_Cnt: '                    || L_dup_org_id_cnt);
      DBMS_OUTPUT.PUT_LINE('No_org_id_cnt: '              || L_no_org_id_cnt);
      DBMS_OUTPUT.PUT_LINE('Unknown_err_Cnt: '            || L_unknown_err_cnt);
      DBMS_OUTPUT.PUT_LINE('Insert_dup_Cnt: '             || L_insert_dup_cnt);
      DBMS_OUTPUT.PUT_LINE('PO_not_exist_Cnt: '           || L_po_not_exist_cnt);
   
   END XX_PO_SHIPSTAT_CONV;  

END XX_PO_SHIPSTAT_CONV_PKG;
/
