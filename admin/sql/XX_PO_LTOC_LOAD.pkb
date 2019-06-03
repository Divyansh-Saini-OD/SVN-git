CREATE OR REPLACE PACKAGE BODY xx_po_ltoc_load AS
PROCEDURE Main_RMS(p_user_id     IN NUMBER DEFAULT fnd_global.user_id
                  ,x_error_buff	OUT	VARCHAR2
                  ,x_ret_code	OUT	VARCHAR2) IS

v_nmatched PLS_INTEGER := 0;
v_action   VARCHAR2(200);

BEGIN

v_action := 'Merging RMS';

MERGE INTO xx_po_lead_time_order_cycle oc
USING (SELECT vs.vendor_site_id source_id,
              destination_id,
              item_id,
              overall_lt,
              ship_lt,
              (overall_lt - ship_lt)  receipt_lt,
              decode(substr(order_cycle_days,1,1),'Y','SUN') || 
              decode(substr(order_cycle_days,2,1),'Y','MON') ||
              decode(substr(order_cycle_days,3,1),'Y','TUE') ||
              decode(substr(order_cycle_days,4,1),'Y','WED') ||
              decode(substr(order_cycle_days,5,1),'Y','THU') ||
              decode(substr(order_cycle_days,6,1),'Y','FRI') ||
              decode(substr(order_cycle_days,7,1),'Y','SAT') order_cycle_days,
              decode(ordercycle_frequency,7,1,2)             ordercycle_frequency
         FROM xx_po_lead_time_order_cyc_stg st
             ,po_vendor_sites_all           vs
        WHERE origin = 'RMS'
          AND source_id = vs.attribute9
          AND destination_id = 0
          AND item_id        = 0
        UNION
       SELECT vs.vendor_site_id source_id,
              decode(destination_id,0,0,hr.organization_id) destination_id,
              item_id,
              overall_lt,
              ship_lt,
              (overall_lt - ship_lt)  receipt_lt,
              decode(substr(order_cycle_days,1,1),'Y','SUN') || 
              decode(substr(order_cycle_days,2,1),'Y','MON') ||
              decode(substr(order_cycle_days,3,1),'Y','TUE') ||
              decode(substr(order_cycle_days,4,1),'Y','WED') ||
              decode(substr(order_cycle_days,5,1),'Y','THU') ||
              decode(substr(order_cycle_days,6,1),'Y','FRI') ||
              decode(substr(order_cycle_days,7,1),'Y','SAT') order_cycle_days,
              decode(ordercycle_frequency,7,1,2)             ordercycle_frequency
         FROM xx_po_lead_time_order_cyc_stg st
             ,po_vendor_sites_all           vs
             ,hr_all_organization_units     hr
        WHERE origin = 'RMS'
          AND source_id = vs.attribute9
          AND destination_id <> 0
          AND destination_id = hr.attribute1
          AND item_id       = 0
        UNION
       SELECT vs.vendor_site_id source_id,
              decode(destination_id,0,0,hr.organization_id) destination_id,
              it.inventory_item_id item_id,
              overall_lt,
              ship_lt,
              (overall_lt - ship_lt)  receipt_lt,
              decode(substr(order_cycle_days,1,1),'Y','SUN') || 
              decode(substr(order_cycle_days,2,1),'Y','MON') ||
              decode(substr(order_cycle_days,3,1),'Y','TUE') ||
              decode(substr(order_cycle_days,4,1),'Y','WED') ||
              decode(substr(order_cycle_days,5,1),'Y','THU') ||
              decode(substr(order_cycle_days,6,1),'Y','FRI') ||
              decode(substr(order_cycle_days,7,1),'Y','SAT') order_cycle_days,
              decode(ordercycle_frequency,7,1,2)             ordercycle_frequency
         FROM xx_po_lead_time_order_cyc_stg st
             ,po_vendor_sites_all           vs
             ,hr_all_organization_units     hr
             ,(SELECT DISTINCT inventory_item_id,
                               segment1
                 FROM mtl_system_items_b)  it
        WHERE origin = 'RMS'
          AND source_id        = vs.attribute9
          AND destination_id   = hr.attribute1
          AND item_id         <> 0
          AND to_char(item_id) = it.segment1
        UNION
       SELECT vs.vendor_site_id source_id,
              destination_id,
              it.inventory_item_id item_id,
              overall_lt,
              ship_lt,
              (overall_lt - ship_lt)  receipt_lt,
              decode(substr(order_cycle_days,1,1),'Y','SUN') || 
              decode(substr(order_cycle_days,2,1),'Y','MON') ||
              decode(substr(order_cycle_days,3,1),'Y','TUE') ||
              decode(substr(order_cycle_days,4,1),'Y','WED') ||
              decode(substr(order_cycle_days,5,1),'Y','THU') ||
              decode(substr(order_cycle_days,6,1),'Y','FRI') ||
              decode(substr(order_cycle_days,7,1),'Y','SAT') order_cycle_days,
              decode(ordercycle_frequency,7,1,2)             ordercycle_frequency
         FROM xx_po_lead_time_order_cyc_stg st
             ,po_vendor_sites_all           vs
             ,(SELECT DISTINCT inventory_item_id,
                               segment1
                 FROM mtl_system_items_b)  it
        WHERE origin = 'RMS'
          AND source_id        = vs.attribute9
          AND destination_id   = 0
          AND item_id         <> 0
          AND to_char(item_id) = it.segment1) st
   ON (    oc.source_id      = st.source_id
       AND oc.destination_id = st.destination_id
       AND oc.item_id        = st.item_id)
WHEN MATCHED THEN
UPDATE SET oc.overall_lt           = st.overall_lt,
           oc.ship_lt              = st.ship_lt,
           oc.receipt_lt           = st.receipt_lt,
           oc.order_cycle_days     = st.order_cycle_days,
           oc.ordercycle_frequency = st.ordercycle_frequency,
           oc.last_update_date     = sysdate,
           oc.last_updated_by      = p_user_id,
           oc.last_update_login    = fnd_global.login_id
WHEN NOT MATCHED THEN
INSERT (source_id
       ,source_type
       ,destination_id
       ,destination_type
       ,item_id
       ,overall_lt
       ,ship_lt
       ,receipt_lt
       ,order_cycle_days
       ,ordercycle_frequency
       ,last_update_date
       ,last_updated_by
       ,creation_date
       ,created_by
       ,last_update_login
       )
VALUES (st.source_id
       ,'V'
       ,st.destination_id
       ,'S'
       ,st.item_id
       ,st.overall_lt
       ,st.ship_lt
       ,st.receipt_lt
       ,st.order_cycle_days
       ,st.ordercycle_frequency
       ,sysdate
       ,p_user_id
       ,sysdate
       ,p_user_id
       ,fnd_global.login_id
       );

dbms_output.put_line(chr(10) ||'Records merged for RMS = ' || sql%rowcount);

x_ret_code := 0;

v_action := 'Inserting not matched RMS records';

FOR err IN (SELECT source_id, destination_id, item_id 
              FROM xx_po_lead_time_order_cyc_stg st
             WHERE origin = 'RMS'
            MINUS
            SELECT source_id, destination_id, item_id
              FROM (SELECT st.*
                      FROM xx_po_lead_time_order_cyc_stg st
                          ,po_vendor_sites_all           vs
                     WHERE origin = 'RMS'
                       AND source_id = vs.attribute9
                       AND destination_id = 0
                       AND item_id        = 0
                     UNION
                    SELECT st.*
                      FROM xx_po_lead_time_order_cyc_stg st
                          ,po_vendor_sites_all           vs
                          ,hr_all_organization_units     hr
                     WHERE origin = 'RMS'
                       AND source_id = vs.attribute9
                       AND destination_id <> 0
                       AND destination_id = hr.attribute1
                       AND item_id       = 0
                     UNION
                    SELECT st.*
                      FROM xx_po_lead_time_order_cyc_stg st
                          ,po_vendor_sites_all           vs
                          ,hr_all_organization_units     hr
                          ,(SELECT DISTINCT inventory_item_id,
                                            segment1
                              FROM mtl_system_items_b)  it
                     WHERE origin = 'RMS'
                       AND source_id        = vs.attribute9
                       AND destination_id   = hr.attribute1
                       AND item_id         <> 0
                       AND to_char(item_id) = it.segment1
                     UNION
                    SELECT st.*
                      FROM xx_po_lead_time_order_cyc_stg st
                          ,po_vendor_sites_all           vs
                          ,(SELECT DISTINCT inventory_item_id,
                                            segment1
                              FROM mtl_system_items_b)  it
                     WHERE origin = 'RMS'
                       AND source_id        = vs.attribute9
                       AND destination_id   = 0
                       AND item_id         <> 0
                       AND to_char(item_id) = it.segment1)) LOOP
 x_ret_code := 2; -- If records are found then set exit code with a warning
 v_nmatched := v_nmatched + 1;
 xx_po_log_errors_pkg.po_log_errors ( trunc(sysdate)
                                     ,c_module_rms
                                     ,v_action
                                     ,'W'
                                     ,'2'
                                     ,'Supplier/organization not found for legacy source/destination/item id: '
                                       || err.source_id || '/' 
                                       || NVL(err.destination_id,0) || '/'
                                       || NVL(err.item_id,0)
                                     ,p_user_id
                                     );
END LOOP;
IF x_ret_code > 0 THEN
   dbms_output.put_line(chr(10) ||'(RMS) Records not matched = ' ||  v_nmatched);
END IF;

EXCEPTION
 WHEN OTHERS THEN
      xx_po_log_errors_pkg.po_log_errors ( trunc(sysdate)
                                         ,c_module_rms
                                         ,v_action
                                         ,'E'
                                         ,'1'
                                         ,sqlerrm
                                         ,p_user_id
                                         );
      x_ret_code := 1;
      x_error_buff := sqlerrm;
END Main_RMS;

--------------------------------------------------------------------------------------
PROCEDURE Main_LEG(p_user_id     IN NUMBER DEFAULT fnd_global.user_id
                  ,x_error_buff	OUT	VARCHAR2
                  ,x_ret_code	OUT	VARCHAR2) IS

 v_nmatched PLS_INTEGER := 0;
 v_action   VARCHAR2(200);

BEGIN

v_action := 'Merging Legacy';

MERGE INTO xx_po_lead_time_order_cycle oc
USING (SELECT vs.vendor_site_id source_id,
              destination_id,
              item_id,
              overall_lt,
              ship_lt,
              (overall_lt - ship_lt)  receipt_lt,
              decode(substr(order_cycle_days,1,1),'Y','SUN') || 
              decode(substr(order_cycle_days,2,1),'Y','MON') ||
              decode(substr(order_cycle_days,3,1),'Y','TUE') ||
              decode(substr(order_cycle_days,4,1),'Y','WED') ||
              decode(substr(order_cycle_days,5,1),'Y','THU') ||
              decode(substr(order_cycle_days,6,1),'Y','FRI') ||
              decode(substr(order_cycle_days,7,1),'Y','SAT') order_cycle_days,
              decode(ordercycle_frequency,7,1,2)             ordercycle_frequency
         FROM xx_po_lead_time_order_cyc_stg st
             ,po_vendor_sites_all           vs
        WHERE origin = 'LEG'
          AND source_id = vs.attribute9
          AND destination_id = 0
          AND item_id        = 0
        UNION
       SELECT vs.vendor_site_id source_id,
              decode(destination_id,0,0,hr.organization_id) destination_id,
              item_id,
              overall_lt,
              ship_lt,
              (overall_lt - ship_lt)  receipt_lt,
              decode(substr(order_cycle_days,1,1),'Y','SUN') || 
              decode(substr(order_cycle_days,2,1),'Y','MON') ||
              decode(substr(order_cycle_days,3,1),'Y','TUE') ||
              decode(substr(order_cycle_days,4,1),'Y','WED') ||
              decode(substr(order_cycle_days,5,1),'Y','THU') ||
              decode(substr(order_cycle_days,6,1),'Y','FRI') ||
              decode(substr(order_cycle_days,7,1),'Y','SAT') order_cycle_days,
              decode(ordercycle_frequency,7,1,2)             ordercycle_frequency
         FROM xx_po_lead_time_order_cyc_stg st
             ,po_vendor_sites_all           vs
             ,hr_all_organization_units     hr
        WHERE origin = 'LEG'
          AND source_id = vs.attribute9
          AND destination_id <> 0
          AND destination_id = hr.attribute1
          AND item_id       = 0
        UNION
       SELECT vs.vendor_site_id source_id,
              decode(destination_id,0,0,hr.organization_id) destination_id,
              it.inventory_item_id item_id,
              overall_lt,
              ship_lt,
              (overall_lt - ship_lt)  receipt_lt,
              decode(substr(order_cycle_days,1,1),'Y','SUN') || 
              decode(substr(order_cycle_days,2,1),'Y','MON') ||
              decode(substr(order_cycle_days,3,1),'Y','TUE') ||
              decode(substr(order_cycle_days,4,1),'Y','WED') ||
              decode(substr(order_cycle_days,5,1),'Y','THU') ||
              decode(substr(order_cycle_days,6,1),'Y','FRI') ||
              decode(substr(order_cycle_days,7,1),'Y','SAT') order_cycle_days,
              decode(ordercycle_frequency,7,1,2)             ordercycle_frequency
         FROM xx_po_lead_time_order_cyc_stg st
             ,po_vendor_sites_all           vs
             ,hr_all_organization_units     hr
             ,(SELECT DISTINCT inventory_item_id,
                               segment1
                 FROM mtl_system_items_b)  it
        WHERE origin = 'LEG'
          AND source_id        = vs.attribute9
          AND destination_id   = hr.attribute1
          AND item_id         <> 0
          AND to_char(item_id) = it.segment1
        UNION
       SELECT vs.vendor_site_id source_id,
              destination_id,
              it.inventory_item_id item_id,
              overall_lt,
              ship_lt,
              (overall_lt - ship_lt)  receipt_lt,
              decode(substr(order_cycle_days,1,1),'Y','SUN') || 
              decode(substr(order_cycle_days,2,1),'Y','MON') ||
              decode(substr(order_cycle_days,3,1),'Y','TUE') ||
              decode(substr(order_cycle_days,4,1),'Y','WED') ||
              decode(substr(order_cycle_days,5,1),'Y','THU') ||
              decode(substr(order_cycle_days,6,1),'Y','FRI') ||
              decode(substr(order_cycle_days,7,1),'Y','SAT') order_cycle_days,
              decode(ordercycle_frequency,7,1,2)             ordercycle_frequency
         FROM xx_po_lead_time_order_cyc_stg st
             ,po_vendor_sites_all           vs
             ,(SELECT DISTINCT inventory_item_id,
                               segment1
                 FROM mtl_system_items_b)  it
        WHERE origin = 'LEG'
          AND source_id        = vs.attribute9
          AND destination_id   = 0
          AND item_id         <> 0
          AND to_char(item_id) = it.segment1) st
   ON (    oc.source_id      = st.source_id
       AND oc.destination_id = st.destination_id
       AND oc.item_id        = st.item_id)
WHEN MATCHED THEN
UPDATE SET oc.overall_lt           = st.overall_lt,
           oc.ship_lt              = st.ship_lt,
           oc.receipt_lt           = st.receipt_lt,
           oc.order_cycle_days     = st.order_cycle_days,
           oc.ordercycle_frequency = st.ordercycle_frequency,
           oc.last_update_date     = sysdate,
           oc.last_updated_by      = p_user_id,
           oc.last_update_login    = fnd_global.login_id
WHEN NOT MATCHED THEN
INSERT (source_id
       ,source_type
       ,destination_id
       ,destination_type
       ,item_id
       ,overall_lt
       ,ship_lt
       ,receipt_lt
       ,order_cycle_days
       ,ordercycle_frequency
       ,last_update_date
       ,last_updated_by
       ,creation_date
       ,created_by
       ,last_update_login
       )
VALUES (st.source_id
       ,'V'
       ,st.destination_id
       ,decode(st.destination_id,'0','S','W')
       ,0
       ,st.overall_lt
       ,st.ship_lt
       ,st.receipt_lt
       ,st.order_cycle_days
       ,st.ordercycle_frequency
       ,sysdate
       ,p_user_id
       ,sysdate
       ,p_user_id
       ,fnd_global.login_id
       );
dbms_output.put_line(chr(10) ||'Records merged for Legacy = ' || sql%rowcount);

x_ret_code := 0;

v_action := 'Inserting not matched Legacy record';

FOR err IN (SELECT source_id, destination_id, item_id 
              FROM xx_po_lead_time_order_cyc_stg st
             WHERE origin = 'LEG'
            MINUS
            SELECT source_id, destination_id, item_id
              FROM (SELECT st.*
                      FROM xx_po_lead_time_order_cyc_stg st
                          ,po_vendor_sites_all           vs
                     WHERE origin = 'LEG'
                       AND source_id = vs.attribute9
                       AND destination_id = 0
                       AND item_id        = 0
                     UNION
                    SELECT st.*
                      FROM xx_po_lead_time_order_cyc_stg st
                          ,po_vendor_sites_all           vs
                          ,hr_all_organization_units     hr
                     WHERE origin = 'LEG'
                       AND source_id = vs.attribute9
                       AND destination_id <> 0
                       AND destination_id = hr.attribute1
                       AND item_id       = 0
                     UNION
                    SELECT st.*
                      FROM xx_po_lead_time_order_cyc_stg st
                          ,po_vendor_sites_all           vs
                          ,hr_all_organization_units     hr
                          ,(SELECT DISTINCT inventory_item_id,
                                            segment1
                              FROM mtl_system_items_b)  it
                     WHERE origin = 'LEG'
                       AND source_id        = vs.attribute9
                       AND destination_id   = hr.attribute1
                       AND item_id         <> 0
                       AND to_char(item_id) = it.segment1
                     UNION
                    SELECT st.*
                      FROM xx_po_lead_time_order_cyc_stg st
                          ,po_vendor_sites_all           vs
                          ,(SELECT DISTINCT inventory_item_id,
                                            segment1
                              FROM mtl_system_items_b)  it
                     WHERE origin = 'LEG'
                       AND source_id        = vs.attribute9
                       AND destination_id   = 0
                       AND item_id         <> 0
                       AND to_char(item_id) = it.segment1)) LOOP
 x_ret_code := 2; -- If not matched records are found, then set exit code with a warning
 v_nmatched := v_nmatched + 1;
 xx_po_log_errors_pkg.po_log_errors ( trunc(sysdate)
                                     ,c_module_leg
                                     ,v_action
                                     ,'W'
                                     ,'2'
                                     ,'Supplier/organization not found for legacy source/destination/item id: '
                                       || err.source_id || '/' 
                                       || NVL(err.destination_id,0) || '/'
                                       || NVL(err.item_id,0)
                                     ,p_user_id
                                     );
END LOOP;
IF x_ret_code > 0 THEN
   dbms_output.put_line(chr(10) ||'(Legacy) Records not matched = ' ||  v_nmatched);
END IF;
EXCEPTION
 WHEN OTHERS THEN
      xx_po_log_errors_pkg.po_log_errors ( trunc(sysdate)
                                         ,c_module_leg
                                         ,v_action
                                         ,'E'
                                         ,'1'
                                         ,sqlerrm
                                         ,p_user_id
                                         );
      x_ret_code := 1;
      x_error_buff := sqlerrm;
END Main_LEG;
END xx_po_ltoc_load;
