SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_PB_PRDUPLD_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_PB_PRDUPLD_PKG.pkb                           |
-- | Description :  OD PA PB Product Upload Pkg                        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       23-Sep-2010 Paddy Sanjeevi     Initial version           |
-- |1.1       13-Oct-2010 Rama Dwibhashyam   Mod cost val date logic   |
-- |1.2       26-Oct-2012 Paddy Sanjeevi     Defect 20806              |
-- +===================================================================+
AS

------------------------------------------------------------------------------------------------
--Declaring xx_process_data
------------------------------------------------------------------------------------------------

FUNCTION get_image_path RETURN VARCHAR2
IS
v_path varchar2(200);
BEGIN
  select ffv.attribute2 
    into v_path
  from fnd_flex_value_sets ffvs,
       fnd_flex_values_vl ffv
  where ffvs.flex_value_set_id = ffv.flex_value_set_id
    and ffvs.flex_value_set_name = 'XX_PA_PB_EXCEL_TEMPLATE_CONFIG'   
    and ffv.enabled_flag = 'Y'  ; 
  RETURN(v_path);
EXCEPTION
 WHEN others THEN
  v_path:=NULL;
  RETURN(v_path);
END get_image_path;

PROCEDURE xx_process_data    (  x_errbuf               OUT NOCOPY VARCHAR2
                        ,x_retcode              OUT NOCOPY VARCHAR2
                            )
IS

v_proj_id        NUMBER;
v_proj_no        VARCHAR2(25);
v_error_message     varchar2(2000);
v_prod_dtl_id        NUMBER;
v_tariff_aprv_id    NUMBER;
v_prd_logistics_id    NUMBER;
v_prd_test_id        NUMBER;
v_test_result_id    NUMBER;
v_line_no        NUMBER:=0;
v_tstdd_flag        varchar2(1):='N';
v_tstrdd_flag        varchar2(1):='N';
v_itemupd_flag        varchar2(1):='Y';
v_logisupd_flag        varchar2(1):='Y';          
v_image_directory     varchar2(150);  
v_cost_val_date     date ;

v_msg            varchar2(2000);
v_text                 varchar2(32000);
v_error        varchar2(1):='N';
v_htext                 varchar2(32000);
v_subject             varchar2(100):='Spreadsheet Item Upload Process Report : '||to_char(sysdate,'dd-mon-rr HH24:MI:SS');

CURSOR c_upd_proj IS
SELECT b.prod_dtl_id,a.rowid drowid, a.*
  FROM apps.XX_PA_PB_GENPRD_DTL b,apps.xx_pa_pb_prdupld_stg a
 WHERE a.process_Flag=1
   AND a.action_type='C'
   AND (a.item_process_flag IN (1,6) or a.logis_process_Flag=6)
   AND b.project_no=a.project_no
   AND b.vpc=a.vpc;
   
CURSOR c_mproj IS
SELECT distinct project_no
  FROM apps.xx_pa_pb_prdupld_stg
 WHERE process_Flag=1
   AND (project_id IS null or project_id=-1);

CURSOR C_main IS
SELECT a.rowid drowid,a.*
  FROM apps.xx_pa_pb_prdupld_stg a
 WHERE process_Flag=1
   AND action_type='A'
   AND project_id>0
   AND (   item_process_flag   IN (1,2,3)
        OR logis_process_flag  IN (1,2,3)
        OR tarif_process_flag  IN (1,2,3)
        OR qatst_process_flag  IN (1,2,3)
        OR qatstr_process_flag IN (1,2,3)
       )
ORDER BY a.project_no;

 CURSOR cur_image_dir IS
  select ffv.attribute2 image_directory
  from fnd_flex_value_sets ffvs,
       fnd_flex_values_vl ffv
  where ffvs.flex_value_set_id = ffv.flex_value_set_id
    and ffvs.flex_value_set_name = 'XX_PA_PB_EXCEL_TEMPLATE_CONFIG'   
    and ffv.enabled_flag = 'Y'  ;  


TYPE cmain_tbl_type IS TABLE OF c_main%ROWTYPE INDEX BY BINARY_INTEGER;
lt_cmain cmain_tbl_type;

TYPE rowid_tbl_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
lt_row_id rowid_tbl_type;

TYPE item_pf_tbl_type IS TABLE OF xx_pa_pb_prdupld_stg.item_process_flag%TYPE INDEX BY BINARY_INTEGER;

lt_item_pf item_pf_tbl_type;

TYPE logis_pf_tbl_type IS TABLE OF xx_pa_pb_prdupld_stg.logis_process_flag%TYPE INDEX BY BINARY_INTEGER;

lt_logis_pf logis_pf_tbl_type;

TYPE tarif_pf_tbl_type IS TABLE OF xx_pa_pb_prdupld_stg.tarif_process_flag%TYPE INDEX BY BINARY_INTEGER;

lt_tarif_pf tarif_pf_tbl_type;

TYPE qatst_pf_tbl_type IS TABLE OF xx_pa_pb_prdupld_stg.qatst_process_flag%TYPE INDEX BY BINARY_INTEGER;

lt_qatst_pf qatst_pf_tbl_type;

TYPE qatstr_pf_tbl_type IS TABLE OF xx_pa_pb_prdupld_stg.qatstr_process_flag%TYPE INDEX BY BINARY_INTEGER;

lt_qatstr_pf qatstr_pf_tbl_type;

TYPE error_tbl_type IS TABLE OF xx_pa_pb_prdupld_stg.error_message%TYPE INDEX BY BINARY_INTEGER;
lt_error_tbl  error_tbl_type;


CURSOR C_err IS
SELECT COUNT(1) tot
       ,project_no
       ,error_message
  FROM apps.xx_pa_pb_prdupld_stg
 WHERE process_Flag=1
   AND creation_date>sysdate-1
   AND error_message IS NOT NULL
 GROUP BY project_no,error_message;

CURSOR c_proj_tst IS
SELECT c.project_number,c.project_id,c.wbs_number,c.scheduled_finish_date,c.status_code_meaning,
       DECODE(c.wbs_number,'12.1','Testing Protocols Review',
               '12.2','Purchasing Specs Development',
                '4.2','Initial Samples Review / Approval',
                '5.2','FQA',
                '12.3','Testing Protocols Approval',
                '12.4','Lab/Sample Requested',
                '12.5','Sample Received',
                '12.6','PPT Sample Review / Approval'
          ) tst_name
  FROM apps.PA_STRUCTURES_TASKS_V c
 WHERE c.project_id IN (SELECT DISTINCT project_id
              FROM apps.xx_pa_pb_prdupld_stg
             WHERE qatdd_process_flag IN (1,3)
            )
   AND c.wbs_number IN ('12.1','12.2','4.2','5.2','12.3','12.4','12.5','12.6');


CURSOR c_tst_status(p_project_id NUMBER,p_task varchar2) IS
SELECT b.prd_test_id,
       b.task_description,
       DECODE(b.task_description,'Testing Protocols Review','12.1',
                      'Purchasing Specs Development','12.2',
                      'Initial Samples Review / Approval','4.2',
                      'FQA','5.2',
                      'Testing Protocols Approval','12.3',
                      'Lab/Sample Requested','12.4',
                      'Sample Received','12.5',
                      'PPT Sample Review / Approval','12.6'
           ) tst_wbs
   FROM apps.XX_PA_PB_PRD_QATST b,
        apps.xx_pa_pb_genprd_dtl a
  WHERE a.project_id=p_project_id
    AND a.prod_dtl_id=b.prod_dtl_id 
    AND (b.status is null OR b.due_date is null)
    AND b.task_description=p_task;


CURSOR c_proj_tstr IS
SELECT c.project_number,c.project_id,c.wbs_number,c.scheduled_finish_date,c.status_code_meaning,
       DECODE(c.wbs_number,'12.7','Product Testing',
               '12.8','Transit Testing',
               '12.9','Artwork Testing',
               '18.1','FAI',
               '18.2','Inspection Protocol Review',
               '18.3','Inspection Protocol Approval',
               '18.4','Final Sample Sent / Approval',
               '18.5','PSI'
          ) tst_name
  FROM apps.PA_STRUCTURES_TASKS_V c
 WHERE c.project_id IN (SELECT DISTINCT project_id
              FROM apps.xx_pa_pb_prdupld_stg  
             WHERE qatrdd_process_flag IN (1,3))
   AND c.wbs_number IN ('12.7','12.8','12.9','18.1','18.2','18.3','18.4','18.5');


CURSOR c_tstr_status(p_project_id NUMBER,p_task varchar2) IS
SELECT b.test_result_id,
       b.task_description,
       DECODE(b.task_description,'Product Testing','12.7',
                      'Transit Testing','12.8',
                      'Arwork Testing','12.9',
                      'FAI','18.1',
                      'Inspection Protocol Review','18.2',
                      'Inspection Protocol Approval','18.3',
                      'Final Sample Sent / Approval','18.4',
                      'PSI','18.5'
           ) tstr_wbs
   FROM apps.XX_PA_PB_PRD_QATSTR b,
        apps.xx_pa_pb_genprd_dtl a
  WHERE a.project_id=p_project_id
    AND a.prod_dtl_id=b.prod_dtl_id 
    AND (b.status is null OR b.due_date is null)
    AND b.task_description=p_task;

BEGIN


    open cur_image_dir ;
    fetch cur_image_dir into v_image_directory ;
      if cur_image_dir%notfound
      then
         v_image_directory := '/XXMER_HTML/' ;
         
      end if;
      
    close cur_image_dir;

  -- Processing the updation of the existing records

  UPDATE apps.xx_pa_pb_prdupld_stg 
     SET item_process_flag=1,action_type='A',
     logis_process_Flag=1,tarif_process_flag=1,
     qatst_process_Flag=1,qatstr_process_flag=1,
     qatdd_process_flag=1,qatrdd_process_Flag=1
   WHERE process_flag=1
     AND item_process_flag IS NULL;
  COMMIT;


    UPDATE apps.xx_pa_pb_prdupld_stg a
       SET a.action_type = 'C'
     WHERE a.process_flag = 1
       AND a.item_process_flag = 1
       AND EXISTS (SELECT 'x'
                     FROM apps.xx_pa_pb_genprd_dtl
                    WHERE project_no = a.project_no AND vpc = a.vpc);
  COMMIT;

  FOR cur IN c_upd_proj LOOP

    v_itemupd_flag        :='Y';
    v_logisupd_flag        :='Y';


    
        UPDATE apps.xx_pa_pb_genprd_dtl
           SET sourcing_agent = cur.sourcing_agent,
               existing_sku = cur.existing_sku,
               product_image = replace(cur.picture1,v_image_directory,'/XXMER_HTML/'),
               product_desc = cur.product_desc,
               sell_unit = cur.sell_unit_size,
               packaging_type = cur.package_type,
               brand = cur.brand,
               item_dimen = cur.item_dimen,
               item_purpose = cur.item_purpose,
               prod_specs = cur.prod_specs,
               prod_construc = cur.prod_construc,
               vendor_name = cur.vendor_name,
               vendor_id = cur.vendor_id,
               factory_name = cur.factory_name,
               factory_id = cur.factory_id,
               quote_date = cur.vend_quote_date,
               cost_val_period = cur.quote_val_months,
               cost_val_date  = add_months(cur.vend_quote_date,cur.quote_val_months),
               fob_amnt = cur.fob,
               division = cur.division,
               division_name = cur.division_name,
               dept = cur.dept,
               dept_name = cur.dept_name,
               CLASS = cur.CLASS,
               class_name = cur.class_name,
               subclass = cur.subclass,
               subclass_name = cur.subclass_name,
               ddp_amnt = cur.landed_cost,
               last_update_date = SYSDATE,
               last_updated_by = fnd_global.user_id
         WHERE prod_dtl_id = cur.prod_dtl_id;
 
     IF SQL%NOTFOUND THEN
        v_itemupd_flag:='N';
     END IF;

     
        UPDATE apps.xx_pa_pb_prd_logistics
           SET country_of_origin = cur.country_of_origin,
               port_of_shipping = cur.port_of_shipping,
               sl_qty = cur.sell_unit_size,
               sl_length = cur.sl_length,
               sl_width = cur.sl_width,
               sl_height = cur.sl_height,
               sl_weight = cur.sl_weight,
               sl_vend_upc_no = cur.vendor_upc_no,
               ic_qty = cur.ic_qty,
               ic_length = cur.ic_length,
               ic_width = cur.ic_width,
               ic_height = cur.ic_height,
               ic_weight = cur.ic_weight,
               mc_qty = cur.mc_qty,
               mc_length = cur.mc_length,
               mc_width = cur.mc_width,
               mc_height = cur.mc_height,
               mc_weight = cur.mc_weight,
               mc_cmb = cur.mc_cmb,
               mc_cuft = cur.mc_cuft,
           qty_20ft=cur.qty_20ft,
           qty_40ft=cur.qty_40ft,
           qty_40ft_htc=cur.qty_40ft_htc,
           qty_45ft=cur.qty_45ft,
               tariff_no = cur.tariff_no,
               duty_rate_pct = cur.duty_rate_pct,
               moq = cur.moq,
               mov = cur.fob * cur.moq,
               last_update_date = SYSDATE,
               last_updated_by = fnd_global.user_id
         WHERE prod_dtl_id = cur.prod_dtl_id;
 
     IF SQL%NOTFOUND THEN
        v_logisupd_flag        :='N';
     END IF;

     IF v_itemupd_flag='N' or v_logisupd_flag='N' THEN
     
    UPDATE apps.xx_pa_pb_prdupld_stg
       SET item_process_flag=DECODE(v_itemupd_flag,'N',6,'Y',7),
           logis_process_flag=DECODE(v_logisupd_flag,'N',6,'Y',7)
     WHERE rowid=cur.drowid;
     END IF;

     IF v_itemupd_flag='Y' AND v_logisupd_flag='Y' THEN
    UPDATE apps.xx_pa_pb_prdupld_stg
       SET item_process_flag=7,
           logis_process_flag=7,
           process_Flag=7
     WHERE rowid=cur.drowid;
     END IF;
  END LOOP;
  COMMIT;   

  FOR cur IN c_mproj LOOP
    BEGIN
      SELECT project_id
    INTO v_proj_id
    FROM apps.pa_projects_all
       WHERE segment1=cur.project_no;
    UPDATE xx_pa_pb_prdupld_stg
       SET project_id=v_proj_id
     WHERE project_no=cur.project_no;
    EXCEPTION
      WHEN others THEN
    UPDATE xx_pa_pb_prdupld_stg
       SET project_id=-1
     WHERE project_no=cur.project_no;
    END;
  END LOOP;
  COMMIT;
 
  OPEN  c_main;
  FETCH c_main BULK COLLECT INTO lt_cmain;
  CLOSE c_main;

  IF lt_cmain.COUNT <> 0 THEN

     FOR i IN 1..lt_cmain.COUNT
     LOOP

    lt_row_id(i):=lt_cmain(i).drowid;
    lt_item_pf(i):=NULL;
    lt_logis_pf(i):=NULL;
    lt_tarif_pf(i):=NULL;
    lt_qatst_pf(i):=NULL;
    lt_qatstr_pf(i):=NULL;
    lt_error_tbl(i)         := NULL;
     v_line_no    :=NULL;

         SELECT COUNT(1)
         INTO v_line_no
           FROM apps.XX_PA_PB_GENPRD_DTL
          WHERE project_no=lt_cmain(i).project_no;



     if v_line_no=0 then
            v_line_no:=1;
     else
        v_line_no:=v_line_no+1;
         end if;

         SELECT XX_PA_PB_PROD_DTL_S.nextval 
           INTO v_prod_dtl_id
       FROM dual;



     IF lt_cmain(i).item_process_flag<>7 THEN
     
       BEGIN
       
         IF lt_cmain(i).vend_quote_date IS NOT NULL
         THEN
            
            select ADD_MONTHS(lt_cmain(i).vend_quote_date,lt_cmain(i).quote_val_months)
              into v_cost_val_date
              from dual ;
              
         END IF;
         
          
       INSERT INTO apps.XX_PA_PB_GENPRD_DTL
         (   prod_dtl_id
        ,project_id    
        ,project_no
        ,line_no
        ,init_item_decision
        ,final_item_decision
        ,sourcing_agent
        ,existing_sku
        ,vpc
        ,product_image
        ,product_desc
        ,sell_unit
        ,packaging_type
        ,brand
        ,item_dimen
        ,item_purpose
        ,prod_specs
        ,prod_construc
        ,vendor_name
        ,vendor_id
        ,factory_name
        ,factory_id
        ,quote_date
        ,cost_val_period
        ,cost_val_date
        ,fob_amnt
        ,division
        ,division_name
        ,dept
        ,dept_name
        ,class
        ,class_name
        ,subclass
        ,subclass_name
        ,ddp_amnt
        ,creation_date
        ,created_by
        ,last_update_date
        ,last_updated_by
         )
      VALUES
         (   v_prod_dtl_id
        ,v_proj_id
        ,lt_cmain(i).project_no
        ,v_line_no
        ,'Potential'
        ,'Potential'
        ,lt_cmain(i).sourcing_agent
        ,lt_cmain(i).existing_sku
        ,lt_cmain(i).vpc
        ,replace(lt_cmain(i).picture1,v_image_directory,'/XXMER_HTML/')
        ,lt_cmain(i).product_desc
        ,lt_cmain(i).sell_unit_size
        ,lt_cmain(i).package_type
        ,lt_cmain(i).brand
        ,lt_cmain(i).item_dimen
        ,lt_cmain(i).item_purpose
        ,lt_cmain(i).prod_specs
        ,lt_cmain(i).prod_construc
        ,lt_cmain(i).vendor_name
        ,lt_cmain(i).vendor_id
        ,lt_cmain(i).factory_name
        ,lt_cmain(i).factory_id
        ,lt_cmain(i).vend_quote_date
        ,lt_cmain(i).quote_val_months
        ,v_cost_val_date
        ,lt_cmain(i).fob
        ,lt_cmain(i).division
        ,lt_cmain(i).division_name
        ,lt_cmain(i).dept
        ,lt_cmain(i).dept_name
        ,lt_cmain(i).class
        ,lt_cmain(i).class_name
        ,lt_cmain(i).subclass
        ,lt_cmain(i).subclass_name
        ,lt_cmain(i).landed_cost
        ,sysdate
        ,fnd_global.user_id
        ,sysdate
        ,fnd_global.user_id
          );    
             lt_item_pf(i):=7;
             EXCEPTION
             WHEN others THEN
             lt_item_pf(i):=3;
             v_msg:=sqlerrm;
         lt_error_tbl(i):='Failed while insert in XX_PA_PB_GENPRD_DTL '||','||v_msg;
            END;
     END IF; -- lt_cmain(i).item_process_flag<>7

     IF lt_cmain(i).logis_process_flag<>7 THEN

        SELECT XX_PA_PB_PRD_LOGISTICS_S.nextval 
              INTO v_prd_logistics_id
            FROM dual;
    
        BEGIN
            INSERT
            INTO apps.XX_PA_PB_PRD_LOGISTICS
        (   prod_dtl_id
           ,prd_logistics_id
           ,country_of_origin
           ,port_of_shipping
           ,sl_qty    
           ,sl_length    
           ,sl_width    
             ,sl_height    
             ,sl_weight    
           ,sl_vend_upc_no
           ,ic_qty    
             ,ic_length    
             ,ic_width    
             ,ic_height    
             ,ic_weight    
           ,mc_qty    
           ,mc_length    
             ,mc_width    
             ,mc_height    
             ,mc_weight
             ,mc_cmb    
             ,mc_cuft   
         ,qty_20ft
         ,qty_40ft
         ,qty_40ft_htc
         ,qty_45ft
           ,tariff_no    
             ,duty_rate_pct    
           ,moq        
           ,mov
           ,creation_date        
           ,created_by
           ,last_update_date
           ,last_updated_by
        )
       VALUES
        (  v_prod_dtl_id
          ,v_prd_logistics_id
          ,lt_cmain(i).country_of_origin
          ,lt_cmain(i).port_of_shipping
          ,lt_cmain(i).sell_unit_size
          ,lt_cmain(i).sl_length
          ,lt_cmain(i).sl_width
          ,lt_cmain(i).sl_height
          ,lt_cmain(i).sl_weight
          ,lt_cmain(i).vendor_upc_no 
          ,lt_cmain(i).ic_qty
          ,lt_cmain(i).ic_length
          ,lt_cmain(i).ic_width
          ,lt_cmain(i).ic_height
          ,lt_cmain(i).ic_weight
          ,lt_cmain(i).mc_qty
          ,lt_cmain(i).mc_length
          ,lt_cmain(i).mc_width
          ,lt_cmain(i).mc_height
          ,lt_cmain(i).mc_weight
          ,lt_cmain(i).mc_cmb
          ,lt_cmain(i).mc_cuft
          ,lt_cmain(i).qty_20ft
          ,lt_cmain(i).qty_40ft
          ,lt_cmain(i).qty_40ft_htc
          ,lt_cmain(i).qty_45ft
          ,lt_cmain(i).tariff_no
          ,lt_cmain(i).duty_rate_pct
          ,lt_cmain(i).moq
          ,lt_cmain(i).fob*lt_cmain(i).moq
          ,sysdate
          ,fnd_global.user_id
          ,sysdate
          ,fnd_global.user_id
        );
          lt_logis_pf(i):=7;
        EXCEPTION
            WHEN others THEN
            lt_logis_pf(i):=3;
            v_msg:=sqlerrm;
        lt_error_tbl(i):=lt_error_tbl(i)||'Failed while inserting Logistics data'||','||v_msg;        
        END;
     END IF;

     IF lt_cmain(i).tarif_process_flag<>7 THEN

            SELECT XX_PA_PB_TARIFF_APRV_S.nextval 
              INTO v_tariff_aprv_id
          FROM dual;

        BEGIN
            INSERT
            INTO apps.XX_PA_PB_TARIFF_APRV
        (   prod_dtl_id
           ,tariff_aprv_id
           ,creation_date
           ,created_by
           ,last_updated_by
           ,last_update_date
        )
          VALUES
            (   v_prod_dtl_id
           ,v_tariff_aprv_id
           ,sysdate
           ,fnd_global.user_id
           ,fnd_global.user_id
           ,sysdate
        );
           lt_tarif_pf(i):=7;
        EXCEPTION
            WHEN others THEN
            lt_tarif_pf(i):=3;
            v_msg:=sqlerrm;
        lt_error_tbl(i):=lt_error_tbl(i)||'Failed while inserting Tarif data '||','||v_msg;        
        END;
     END IF;

     IF lt_cmain(i).qatst_process_flag<>7 THEN

          FOR j in 1..8 LOOP

          SELECT XX_PA_PB_PRD_TEST_S.nextval
            INTO v_prd_test_id
            FROM dual;
          BEGIN
            INSERT 
              INTO apps.xx_pa_pb_prd_qatst
          (  prod_dtl_id 
            ,prd_test_id
            ,task_seq
            ,task_description
            ,creation_date
            ,created_by
            ,last_update_date
            ,last_updated_by
          )
                VALUES
          ( v_prod_dtl_id
           ,v_prd_test_id
           ,j    
           ,DECODE(j,1,'Testing Protocols Review',
                 2,'Purchasing Specs Development',
                 3,'Initial Samples Review / Approval',
                 4,'FQA',
                 5,'Testing Protocols Approval',
                 6,'Lab/Sample Requested',
                 7,'Sample Received',
                 8,'PPT Sample Review / Approval'
               )
           ,sysdate
           ,fnd_global.user_id
           ,sysdate
           ,fnd_global.user_id
          );
           lt_qatst_pf(i):=7;         
          EXCEPTION
            WHEN others THEN
              lt_qatst_pf(i):=3;
              v_msg:=sqlerrm;
          lt_error_tbl(i):=lt_error_tbl(i)||'Failed while inserting QA Test data '||','||v_msg;        
          END;
        END LOOP;
     END IF;

     IF lt_cmain(i).qatst_process_flag<>7 THEN

         FOR j in 1..8 LOOP

            SELECT XX_PA_PB_PRD_TESTR_S.nextval
            INTO v_test_result_id
            FROM dual;
          BEGIN
            INSERT 
              INTO apps.XX_PA_PB_PRD_QATSTR
          (  prod_dtl_id 
            ,test_result_id
            ,task_seq
            ,task_description
            ,creation_date
            ,created_by
            ,last_update_date
            ,last_updated_by
          )
                VALUES
          ( v_prod_dtl_id
           ,v_test_result_id
           ,j
           ,DECODE(j,1,'Product Testing',
                 2,'Transit Testing',
                 3,'Artwork Testing',
                 4,'FAI',
                 5,'Inspection Protocol Review',
                 6,'Inspection Protocol Approval',
                 7,'Final Samples Sent / Approval',
                 8,'PSI'
               )
           ,sysdate
           ,fnd_global.user_id
           ,sysdate
           ,fnd_global.user_id
          );
        lt_qatstr_pf(i):=7;
          EXCEPTION
            WHEN others THEN
              lt_qatstr_pf(i):=3;
              v_msg:=sqlerrm;
          lt_error_tbl(i):=lt_error_tbl(i)||'Failed while inserting QA Test data '||','||v_msg;        
          END;
      END LOOP;

     END IF;
     END LOOP;
   END IF;

   FORALL i IN 1 .. lt_cmain.LAST
      UPDATE xx_pa_pb_prdupld_stg
         SET item_process_flag  =  lt_item_pf(i)
             ,logis_process_flag =  lt_logis_pf(i)
             ,tarif_process_flag =  lt_tarif_pf(i)
             ,qatst_process_flag  = lt_qatst_pf(i)
             ,qatstr_process_flag = lt_qatstr_pf(i)
         ,error_message     =  lt_error_tbl(i)
      WHERE  ROWID               =  lt_row_id(i);

   COMMIT;

   FOR c IN c_proj_tst LOOP

        v_tstdd_flag:='Y';

    FOR cur in c_tst_status(c.project_id,c.tst_name) LOOP
      

            UPDATE apps.xx_pa_pb_prd_qatst
               SET status = c.status_code_meaning,
                   due_date = c.scheduled_finish_date
             WHERE prd_test_id = cur.prd_test_id;

      IF SQL%NOTFOUND THEN
         v_tstdd_flag:='N';
      END IF;

    END LOOP;
    
    IF v_tstdd_flag='N' THEN
       UPDATE xx_pa_pb_prdupld_stg
          SET qatdd_process_flag=3
        WHERE project_no=c.project_number;
    ELSE
       UPDATE xx_pa_pb_prdupld_stg
          SET qatdd_process_flag=7
        WHERE project_no=c.project_number;
    END IF;

   END LOOP;

   FOR c IN c_proj_tstr LOOP

       v_tstrdd_flag:='Y';

    FOR cur in c_tstr_status(c.project_id,c.tst_name) LOOP
      
          UPDATE apps.XX_PA_PB_PRD_QATSTR
         SET status=c.status_code_meaning,
         due_date=c.scheduled_finish_date
       WHERE test_result_id=cur.test_result_id;

      IF SQL%NOTFOUND THEN
         v_tstrdd_flag:='N';
      END IF;

    END LOOP;

    IF v_tstrdd_flag='N' THEN
       UPDATE xx_pa_pb_prdupld_stg
          SET qatrdd_process_flag=3
        WHERE project_no=c.project_number;
    ELSE
       UPDATE xx_pa_pb_prdupld_stg
          SET qatrdd_process_flag=7
        WHERE project_no=c.project_number;
    END IF;

   END LOOP;
   COMMIT;

   v_htext:=v_htext||RPAD('=',58,'=')||chr(10);
   v_htext:=v_htext||RPAD('Item Upload Errors      : ',49,' ')||chr(10);
   v_htext:=v_htext||RPAD('=',58,'=')||chr(10);

   FOR cur IN c_err LOOP
    v_error:='Y';
        v_text:=v_text||to_char(cur.tot)||', '||cur.project_no||','||cur.error_message||chr(10);
   END LOOP;

   v_text:=v_text||RPAD('=',58,'=')||chr(10);

   IF v_error='Y' THEN

      APPS.XX_PA_TASK_MGR_ALLOC_PKG.send_notification(v_subject,'IT_MerchEBS_Oncall@officedepot.com',null,v_htext||v_text);

   END IF;
  

   UPDATE xx_pa_pb_prdupld_stg
      SET process_flag=7
    WHERE process_flag=1
      AND item_process_Flag=7
      AND logis_process_Flag=7
      AND tarif_process_Flag=7
      AND qatst_process_Flag=7
      AND qatstr_process_Flag=7;
   COMMIT;

EXCEPTION
  WHEN others THEN
    x_errbuf  := 'Unexpected error in Spreadsheet Item Upload - '||SQLERRM;
    x_retcode := 2;
END xx_process_data;

PROCEDURE xx_submit_conc_pgm  (  o_request_id               OUT NUMBER
                     ) IS
BEGIN

  -- Defect 20806  
  -- Removed the calling of concurrent program

  o_request_id:=0;

/*
  o_request_id:=FND_REQUEST.SUBMIT_REQUEST('xxmer','XXPAUPLD',
        'OD PB Product Excle Upload Process',NULL,FALSE
    );
  if o_request_id > 0 Then
     commit;
  end if;

*/
END;
                     

END XX_PA_PB_PRDUPLD_PKG;
/