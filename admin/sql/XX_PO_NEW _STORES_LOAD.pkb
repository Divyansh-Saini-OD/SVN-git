CREATE OR REPLACE PACKAGE BODY xx_po_new_stores_load AS
PROCEDURE Main(p_user_id     IN NUMBER DEFAULT fnd_global.user_id
              ,x_error_buff OUT	VARCHAR2
              ,x_ret_code   OUT	VARCHAR2) IS

 v_nmatched PLS_INTEGER := 0;
 v_action   VARCHAR2(200);

BEGIN

v_action := 'Merging New Stores';

MERGE INTO xxmer_new_store_reloc_param ns
USING (SELECT ou.organization_id,
              st.*
         FROM xxmer_new_store_reloc_par_stg st,
              hr_all_organization_units     ou
        WHERE loc_id = attribute1) ss
ON    (ns.loc_id = ss.organization_id)
WHEN MATCHED THEN
UPDATE SET ns.store_dir_rcv_date    = ss.store_dir_rcv_date,
           ns.proc_status           = 'P', -- Pending
           ns.rec_status            = 'A', -- Active
           ns.last_update_date      = sysdate,
           ns.last_updated_by       = p_user_id,
           ns.last_update_login     = fnd_global.login_id
WHEN NOT MATCHED THEN
INSERT (process_date
       ,loc_id
       ,type_of_process
       ,proc_status
       ,rec_status
       ,first_inv_create_date
       ,xdoc_rcv_date
       ,store_dir_rcv_date
       ,processed_date
       ,last_update_date
       ,last_updated_by
       ,creation_date
       ,created_by
       ,last_update_login
       )
VALUES (trunc(sysdate)        -- Date of process
       ,ss.organization_id    -- Location ID
       ,'I'                   -- type of processing is inventory modeling
       ,'P'                   -- process is pending                   
       ,'A'                   -- status is active
       ,ss.store_dir_rcv_date -- first_inv_create_date
       ,ss.store_dir_rcv_date -- xdoc_rcv_date
       ,ss.store_dir_rcv_date -- store_dir_rcv_date
       ,trunc(sysdate)        -- processed_date
       ,sysdate               -- last_update_date
       ,p_user_id
       ,sysdate
       ,p_user_id
       ,fnd_global.login_id
       );
dbms_output.put_line('Records merged for New Stores = ' || sql%rowcount);

v_action := 'Set inactive all records that has not been updated by legacy refresh';

UPDATE xxmer_new_store_reloc_param
   SET proc_status       = 'C',  -- Cancel/Completed
       rec_status        = 'I',  -- Inactive
       last_update_date  = sysdate,
       last_updated_by   = p_user_id,
       last_update_login = fnd_global.login_id
 WHERE last_update_date < trunc(sysdate)
   AND rec_status = 'A';

dbms_output.put_line('Records updated for New Stores = ' || sql%rowcount);

COMMIT;

x_ret_code := 0;

v_action := 'Inserting not matched Organizations in Errors Log';

FOR rec IN (SELECT ou.organization_id,
                   st.*
              FROM xxmer_new_store_reloc_par_stg st,
                   hr_all_organization_units     ou
             WHERE loc_id = attribute1(+)
               AND ou.organization_id IS NULL) LOOP
    x_ret_code := 2;
    v_nmatched := v_nmatched + 1;
    xx_po_log_errors_pkg.po_log_errors ( trunc(sysdate)
                                        ,c_module
                                        ,v_action
                                        ,'W'
                                        ,'1'
                                        ,'Organization id not found for Legacy New Store ID: '
                                          || rec.loc_id
                                        ,p_user_id
                                        ,fnd_global.login_id
                                       );
END LOOP;

EXCEPTION
 WHEN OTHERS THEN
      xx_po_log_errors_pkg.po_log_errors ( trunc(sysdate)
                                         ,c_module
                                         ,v_action
                                         ,'E'
                                         ,'1'
                                         ,sqlerrm
                                         ,p_user_id
                                         );
      x_ret_code := 1;
      x_error_buff := sqlerrm;
END Main;
END xx_po_new_stores_load;
/
