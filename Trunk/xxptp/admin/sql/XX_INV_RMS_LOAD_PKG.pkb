SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_INV_RMS_LOAD_PKG
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- +===========================================================================+
-- |Package Name : XX_INV_RMS_LOAD_PKG                                         |
-- |Purpose      : This package contains three procedures that interface       |
-- |               from RMS to EBS.                                            |
-- |                                                                           |
-- |                                                                           |
-- |Change History                                                             |
-- |                                                                           |
-- |Ver   Date          Author             Description                         |
-- |---   -----------   -----------------  ------------------------------------|
-- |1.0   11-NOV-2008   Paddy Sanjeevi     Original Code                       |
-- +===========================================================================+
IS
--
--Global Variables
--
G_underline VARCHAR2(100) := RPAD('-',80,'-');
G_Star      VARCHAR2(100) := RPAD('*',40,'*');
gn_master_org_id            mtl_parameters.organization_id%TYPE;

-- +===========================================================================+
-- | Name        :  get_process_details                                        |
-- | Description :  This procedure gets all the details of a given process     |
-- | Parameters  :  p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec    |
-- +===========================================================================+
PROCEDURE get_process_details(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)
IS
 --
 CURSOR csr_get_process_details IS
 SELECT control_id        ,
        process_name      ,
        stop_running_flag ,
        email_to          ,
        ebs_batch_size    ,
        ebs_threads
   FROM XX_INV_EBS_CONTROL
  WHERE process_name = p_process_info.process_name ;
 --
 v_control_rec          csr_get_process_details%ROWTYPE;
 --
BEGIN
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_star);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'In Procedure Get Process Details .....');
 --
 IF p_process_info.process_name IS NULL THEN
  --
  p_process_info.return_code   := -1;
  p_process_info.error_message := 'Process Name is Null';
  FND_FILE.PUT_LINE(FND_FILE.LOG,p_process_info.error_message);
  --
 ELSE
   --
   OPEN csr_get_process_details;
  FETCH csr_get_process_details INTO v_control_rec;
  CLOSE csr_get_process_details ;
  --
  IF v_control_rec.process_name IS NULL THEN
   --
   p_process_info.return_code   := -1;
   p_process_info.error_message := 'Process Does not exist in Control Table';
   FND_FILE.PUT_LINE(FND_FILE.LOG,p_process_info.error_message);
   --
  ELSE
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Assigning Process Details');
   --
   p_process_info.control_id          := v_control_rec.control_id     ;
   p_process_info.stop_running_flag   := v_control_rec.stop_running_flag    ;
   p_process_info.email_to            := v_control_rec.email_to       ;
   p_process_info.ebs_batch_size      := v_control_rec.ebs_batch_size ;
   p_process_info.ebs_threads         := v_control_rec.ebs_threads    ;
   p_process_info.return_code         := 0                            ;
   --
  END IF;
  --
 END IF;
 --
EXCEPTION
 WHEN OTHERS THEN
  p_process_info.return_code   := -2;
  p_process_info.error_message := SUBSTR(SQLERRM,1,250);
  FND_FILE.PUT_LINE(FND_FILE.LOG,p_process_info.error_message);
END get_process_details;

/*============================================================================+
+ Name        :  Start_Load                                                   |
| Description :  This procedure                                               |
| Parameters  :                                                               +
+============================================================================*/
PROCEDURE Start_Load(x_errbuf       OUT NOCOPY VARCHAR2,
                     x_retcode      OUT NOCOPY NUMBER  ,
                     p_process_name  IN VARCHAR2
                    ) IS
--
v_process_info    XX_INV_RMS_INT_LOAD.p_control_rec;
v_error_message   VARCHAR2(2000);
v_request_status  BOOLEAN;
lx_errbuf                   VARCHAR2(5000);
lx_retcode                  VARCHAR2(20);
--
EX_INVALID_PROCESS     EXCEPTION;
EX_SUB_REQU            EXCEPTION;
--
BEGIN
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_underline);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Begin Load Process');
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Process Name -'||p_process_name);

 v_process_info.process_name := p_process_name;


 FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling the Individual Process');
 ----------------------------------------------
 -- Call Individual Processes
 ----------------------------------------------

 IF p_process_name = 'MERCH_HIER' THEN

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Get Process Details');
  get_process_details(v_process_info);
  Load_MerchHier_Data(v_process_info);

 ELSIF p_process_name = 'LOCATION' THEN

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Get Process Details');
  get_process_details(v_process_info);
  Load_Location_Data(v_process_info);

 END IF;


 IF p_process_name IS NOT NULL THEN

 IF v_process_info.return_code <0 THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Load Process Returned Errors,Setting stauts to Warning');
    -- Set the status to Warning
    v_request_status := FND_CONCURRENT.set_completion_status('WARNING','Error Loading data for '||p_process_name);
    --
 END IF;

 END IF;

 IF p_process_name IS NULL THEN

    RMS_EBS_EXTRACT(x_errbuf     =>lx_errbuf
                   ,x_retcode    =>lx_retcode
                   );
    x_errbuf :=lx_errbuf;
    x_retcode:=lx_retcode;
 END IF;

EXCEPTION
 WHEN ex_invalid_process THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Process Exception Raised');
  x_errbuf := v_error_message;
  RAISE_APPLICATION_ERROR(-20100,v_error_message);
 WHEN OTHERS THEN
  x_errbuf := v_error_message;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception Raised');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'SQL Error -'||SQLERRM);
  RAISE_APPLICATION_ERROR(-20101,SQLERRM);
END Start_Load;

/*===========================================================================+
|                        Update_Ebs_Control                                  |
+===========================================================================*/
PROCEDURE update_ebs_control(p_control_rec IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)
IS
v_mesg VARCHAR2(2000);
BEGIN
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_Star);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'In Procedure update_ebs_control ....');
 --
 UPDATE xx_inv_ebs_control
    SET control_id   = p_control_rec.control_id
  WHERE process_name = p_control_rec.process_name ;
 --
EXCEPTION
 WHEN OTHERS THEN
  --
  p_control_rec.return_code   := -1;
  v_mesg := SUBSTR(('When Others updating control table,SQL Error -'||SQLERRM),1,2000);
  p_control_rec.error_message := v_mesg;
  FND_FILE.PUT_LINE(FND_FILE.LOG,v_mesg);
  --
END update_ebs_control;
/*=============================================================================+
|                        Load_MercHier_Data                                    |
+=============================================================================*/
PROCEDURE Load_MerchHier_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)
IS
--
v_user_id       NUMBER;
v_control_id    NUMBER;
v_error_message VARCHAR2(2000);
EX_UPD_CONTROL_TAB      EXCEPTION;

BEGIN
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_Star);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'In Procedure Load_MerchHier_Data ....');
 --
 v_user_id := FND_GLOBAL.user_id;
 --

 SELECT MIN(control_id)-1
   INTO v_control_id
   FROM xxptp.xx_inv_merchier_int_bkp
  WHERE TRUNC(creation_date)=(SELECT TRUNC(MAX(creation_date))
					  FROM xxptp.xx_inv_merchier_int_bkp);

 v_error_message := 'Inserting records into Staging table' ;
 INSERT INTO XX_INV_MERCHIER_INT(control_id                   ,
                                 process_flag                 ,
                                 rms_process_id               ,
                                 rms_timestamp                ,
                                 action_type                  ,
                                 hierarchy_level              ,
                                 hierarchy_value              ,
                                 hierarchy_description        ,
                                 division_number              ,
                                 group_number                 ,
                                 dept_forecasting_ind         ,
                                 dept_planning_ind            ,
                                 dept_noncode_ind             ,
                                 dept_pp_ind                  ,
                                 dept_aipfilter_ind           ,
                                 dept_number                  ,
                                 class_nbr_days_amd           ,
                                 class_fifth_mrkdwn_cd        ,
                                 class_prcz_cost_flg          ,
                                 class_prcz_price_flg         ,
                                 class_pricz_list_flg         ,
                                 class_furniture_flg          ,
                                 class_aipfilter_ind          ,
                                 class_number                 ,
                                 subclass_default_tax_cat     ,
                                 subclass_globalcontent_ind   ,
                                 subclass_pp_ind              ,
                                 subclass_aipfilter_ind       ,
                                 load_batch_id                ,
                                 error_flag                   ,
                                 error_message                ,
                                 error_count                  ,
                                 creation_date                ,
                                 created_by                   ,
                                 last_update_date             ,
                                 last_updated_by              ,
                                 request_id
                                )
                          SELECT control_id                   ,   --  control_id
                                 1                            ,   --  process_flag
                                 rms_process_id                   ,   --  rms_process_id
                                 rms_timestamp             ,   --  rms_timestamp
                                 action_type                  ,   --  action_type
                                 hierarchy_level              ,   --  hierarchy_level
                                 hierarchy_value              ,   --  hierarchy_value
                                 hierarchy_description        ,   --  hierarchy_description
                                 division_number              ,   --  division_number
                                 group_number                 ,   --  group_number
                                 dept_forecasting_ind         ,   --  dept_forecasting_ind
                                 dept_planning_ind            ,   --  dept_planning_ind
                                 dept_noncode_ind             ,   --  dept_noncode_ind
                                 dept_pp_ind                  ,   --  dept_pp_ind
                                 dept_aipfilter_ind           ,   --  dept_aipfilter_ind
                                 dept_number                  ,   --  dept_number
                                 class_nbr_days_amd           ,   --  class_nbr_days_amd
                                 class_fifth_mrkdwn_cd        ,   --  class_fifth_mrkdwn_cd
                                 class_prcz_cost_flg          ,   --  class_prcz_cost_flg
                                 class_prcz_price_flg         ,   --  class_prcz_price_flg
                                 class_pricz_list_flg         ,   --  class_pricz_list_flg
                                 class_furniture_flg          ,   --  class_furniture_flg
                                 class_aipfilter_ind          ,   --  class_aipfilter_ind
                                 class_number                 ,   --  class_number
                                 subclass_default_tax_cat     ,   --  subclass_default_tax_cat
                                 subclass_globalcontent_ind   ,   --  subclass_globalcontent_ind
                                 subclass_pp_ind              ,   --  subclass_pp_ind
                                 subclass_aipfilter_ind       ,   --  subclass_aipfilter_ind
                                 NULL                         ,   --  load_batch_id
                                 'N'                          ,   --  error_flag
                                 NULL                         ,   --  error_message
                                 0                            ,   --  error_count
                                 SYSDATE                      ,   --  creation_date
                                 v_user_id                    ,   --  created_by
                                 SYSDATE                      ,   --  last_update_date
                                 v_user_id                    ,   --  last_updated_by
                                 0                                --  request_id
                           FROM xxptp.XX_INV_MERCHIER_INT_bkp
                          WHERE control_id > v_control_id;
 --
 p_process_info.records_inserted := SQL%ROWCOUNT;
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserted '||TO_CHAR(p_process_info.records_inserted)
                   ||' into XX_INV_MERCHIER_INT table');
 --

 IF p_process_info.records_inserted > 0 THEN
   --
   v_error_message := 'Fetching Max Control id from Staging table' ;
   --
   SELECT MAX(control_id)
     INTO v_control_id
     FROM XX_INV_MERCHIER_INT;
   --
   p_process_info.control_id := v_control_id ;
   FND_FILE.PUT_LINE(FND_FILE.LOG,'The Max Control id is -'||TO_CHAR(v_control_id));
   --
   v_error_message := 'Calling procedure to update Control id in control table' ;
   FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
   --
   update_ebs_control(p_process_info) ;
   --
   IF p_process_info.return_code = -1 THEN
    --
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Received updating Max Control id in control table');
    RAISE ex_upd_control_tab ;
    --
   ELSE
    --
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Commiting ..........');
    COMMIT ;
    --
   END IF;
    --
 END IF;
 COMMIT;
EXCEPTION
 WHEN ex_upd_control_tab THEN
  --
  ROLLBACK;
  --
 WHEN OTHERS THEN
  --
  ROLLBACK;
  p_process_info.return_code   := -1;
  v_error_message := 'When Others Excpetion while '||v_error_message;
  v_error_message := SUBSTR((v_error_message||',SQL Error -'||SQLERRM),1,2000);
  p_process_info.error_message := v_error_message;
  FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
  --
END Load_MerchHier_Data;
/*===========================================================================+
|                        Load_Location_Data                                  |
+===========================================================================*/
PROCEDURE Load_Location_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)
IS
--
v_user_id       NUMBER;
v_control_id    NUMBER;
v_error_message VARCHAR2(2000);
EX_UPD_CONTROL_TAB      EXCEPTION;
--
BEGIN
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_Star);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'In Procedure Load_Location_Data ....');
 --
 v_user_id := FND_GLOBAL.user_id;
 --
 v_error_message := 'Inserting records into Staging table' ;
 INSERT INTO XX_INV_ORG_LOC_DEF_STG
              (bpel_instance_id             ,
               control_id                   ,
               process_flag                 ,
               rms_process_id               ,
               rms_timestamp                ,
               action_type                  ,
               action                       ,
               org_type                     ,
               location_number_sw           ,
               add1_sw                      ,
               add2_sw                      ,
               od_ad_mkt_id_sw              ,
               od_bts_flight_id_sw          ,
               city_sw                      ,
               od_city_limits_flg_s         ,
               close_date_sw                ,
               country_id_sw                ,
               county_sw                    ,
               od_cross_dock_lead_time_sw   ,
               od_cross_street_dir_1_sw     ,
               od_cross_street_dir_2_sw     ,
               orig_currency_code_sw        ,
               od_delivery_cd_sw            ,
               district_sw                  ,
               od_division_id_sw            ,
               email_sw                     ,
               fax_number_sw                ,
               od_geo_cd_sw                 ,
               org_name_sw                  ,
               location_name                ,
               mgr_name_sw                  ,
               od_model_tax_loc_sw          ,
               open_date_sw                 ,
               od_ord_cutoff_tm_sw          ,
               phone_number_sw              ,
               pcode_sw                     ,
               od_reloc_id_sw               ,
               od_routing_cd_sw             ,
               od_sister_store1_sw          ,
               od_sister_store2_sw          ,
               od_sister_store3_sw          ,
               state_sw                     ,
               od_sub_type_cd_sw            ,
               time_zone_sw                 ,
               od_type_cd_sw                ,
               default_wh_sw                ,
               od_default_wh_csc_s          ,
               od_mkt_open_date_s           ,
               store_class_s                ,
               format_s                     ,
               break_pack_ind_w             ,
               od_defaultcrossdock_sw       ,
               delivery_policy_w            ,
               load_batch_id                ,
               error_flag                   ,
               error_message                ,
               error_count                  ,
               creation_date                ,
               created_by                   ,
               update_date             ,
               updated_by              ,
               request_id
              )
      SELECT   bpel_instance_id                 ,    -- bpel_instance_id
               XX_INV_ORG_DEF_CTL_ID_S.nextval  ,    -- control_id
               1                                ,    -- process_flag
               rms_process_id                       ,    -- rms_process_id
               rms_timestamp                 ,    -- rms_timestamp
               'I'                              ,    -- action_type(Always I as it is interface)
               action                      ,    -- action
               org_type                      ,    -- org_type
               location_number_sw                        ,    -- location_number_sw
               add1_sw                      ,    -- add1_sw
               add2_sw                      ,    -- add2_sw
               od_ad_mkt_id_sw                     ,    -- od_ad_mkt_id_sw
               od_bts_flight_id_sw                 ,    -- od_bts_flight_id_sw
               city_sw                          ,    -- city_sw
               od_city_limits_flg_s               ,    -- od_city_limits_flg_s
               close_date_sw                    ,    -- close_date_sw
               country_id_sw                    ,    -- country_id_sw
               county_sw                        ,    -- county_sw
               od_cross_dock_lead_time_sw          ,    -- od_cross_dock_lead_time_sw
               od_cross_street_dir_1_sw                 ,    -- od_cross_street_dir_1_sw
               od_cross_street_dir_2_sw                ,    -- od_cross_street_dir_2_sw
               orig_currency_code_sw                 ,    -- orig_currency_code_sw
               od_delivery_cd_sw                  ,    -- od_delivery_cd_sw
               district_sw                   ,    -- district_sw
               od_division_id_sw                   ,    -- od_division_id_sw
               email_sw                         ,    -- email_sw
               fax_number_sw                    ,    -- fax_number_sw
               od_geo_cd_sw                        ,    -- od_geo_cd_sw
               org_name_sw                      ,    -- org_name_sw
               location_name                      ,    -- location_name
               mgr_name_sw                  ,    -- mgr_name_sw
               od_model_tax_loc_sw                 ,    -- od_model_tax_loc_sw
               open_date_sw                     ,    -- open_date_sw
               od_ord_cutoff_tm_sw               ,    -- od_ord_cutoff_tm_sw
               phone_number_sw                  ,    -- phone_number_sw
               pcode_sw                   ,    -- pcode_sw
               od_reloc_id_sw                      ,    -- od_reloc_id_sw
               od_routing_cd_sw                    ,    -- od_routing_cd_sw
               od_sister_store1_sw                   ,    -- od_sister_store1_sw
               od_sister_store2_sw                   ,    -- od_sister_store2_sw
               od_sister_store3_sw                   ,    -- od_sister_store3_sw
               state_sw                         ,    -- state_sw
               od_sub_type_cd_sw                 ,    -- od_sub_type_cd_sw
               time_zone_sw                     ,    -- time_zone_sw
               od_type_cd_sw                     ,    -- od_type_cd_sw
               default_wh_sw                     ,    -- default_wh_sw
               od_default_wh_csc_s                 ,    -- od_default_wh_csc_s
               od_mkt_open_date_s               ,    -- od_mkt_open_date_s
               store_class_s                    ,    -- store_class_s
               format_s                   ,    -- format_s
               break_pack_ind_w                 ,    -- break_pack_ind_w
               od_defaultcrossdock_sw           ,    -- od_defaultcrossdock_sw
               delivery_policy_w                ,    -- delivery_policy_w
               NULL                             ,    -- load_batch_id
               'N'                              ,    -- error_flag
               NULL                             ,    -- error_message
               0                                ,    -- error_count
               SYSDATE                          ,    -- creation_date
               v_user_id                        ,    -- created_by
               SYSDATE                          ,    -- update_date
               v_user_id                        ,    -- updated_by
               0                                     -- request_id
          FROM xxptp.XX_INV_ORG_LOC_DEF_STG_BKP
         WHERE bpel_instance_id   > p_process_info.control_id
           AND action_type='I';

 --
 p_process_info.records_inserted := SQL%ROWCOUNT;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserted '||TO_CHAR(p_process_info.records_inserted)
                   ||' into XX_INV_ORG_LOC_DEF_STG table');
 --
 IF p_process_info.records_inserted > 0 THEN
   --
   v_error_message := 'Fetching Max Control id from Staging table' ;
   --
   SELECT MAX(bpel_instance_id)
     INTO v_control_id
     FROM XX_INV_ORG_LOC_DEF_STG;
   --
   p_process_info.control_id := v_control_id ;
   FND_FILE.PUT_LINE(FND_FILE.LOG,'The Max Control id is -'||TO_CHAR(v_control_id));
   --
   v_error_message := 'Calling procedure to update Control id in control table' ;
   FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
   update_ebs_control(p_process_info) ;
   --
   IF p_process_info.return_code = -1 THEN
    --
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Received updating Max Control id in control table');
    RAISE ex_upd_control_tab ;
    --
   ELSE
    --
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Commiting ..........');
    COMMIT ;
    --
   END IF;
   --
 END IF;
 --
EXCEPTION
 WHEN ex_upd_control_tab THEN
  --
  ROLLBACK;
  --
 WHEN OTHERS THEN
  --
  ROLLBACK;
  p_process_info.return_code   := -1;
  v_error_message := 'When Others Excpetion while '||v_error_message;
  v_error_message := SUBSTR((v_error_message||',SQL Error -'||SQLERRM),1,2000);
  p_process_info.error_message := v_error_message;
  FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
  --
END Load_Location_Data;

PROCEDURE RMS_EBS_EXTRACT(
  	                    x_errbuf             OUT NOCOPY VARCHAR2
                         ,x_retcode            OUT NOCOPY VARCHAR2
                         )
IS
v_mstctl_id		PLS_INTEGER;
v_locctl_id	      PLS_INTEGER;
i 			NUMBER:=0;
j			NUMBER:=0;
v_cnt			NUMBER:=0;
v_uom_code		VARCHAR2(3);

CURSOR c_master_org
IS
SELECT MP.organization_id
FROM   mtl_parameters MP
WHERE  MP.organization_id=MP.master_organization_id
AND    ROWNUM=1;

CURSOR C1(p_action VARCHAR2) IS
SELECT item
	,loc
	,rowid drowid
  FROM xx_inv_item_loc_int
 WHERE process_Flag=-1
   AND action_type=p_action
   AND inventory_item_id=-1;

CURSOR C2(p_action VARCHAR2) IS
SELECT item
	,rowid drowid
  FROM xx_inv_item_master_int
 WHERE process_Flag=-1
   AND action_type=p_action
   AND inventory_item_id=-1;


CURSOR c_master_set(p_action VARCHAR2) IS
SELECT DISTINCT item
  FROM xx_inv_item_master_int
 WHERE process_flag=-1
   AND action_type=p_action
   AND inventory_item_id=-1;


CURSOR c_master_setd(p_item VARCHAR2,p_action VARCHAR2) IS
SELECT  item
	 ,rms_timestamp
	 ,rowid drowid
  FROM xx_inv_item_master_int
 WHERE item=p_item
   AND action_type=p_action
   AND process_flag+0=-1
   AND inventory_item_id=-1
 ORDER BY rms_timestamp DESC;

CURSOR c_loc_set(p_action VARCHAR2) IS
SELECT DISTINCT item,loc
  FROM xx_inv_item_loc_int
 WHERE process_flag=-1
   AND action_type=p_action
   AND inventory_item_id=-1;


CURSOR c_loc_setd(p_item VARCHAR2,p_loc NUMBER, p_action VARCHAR2) IS
SELECT  item
	 ,loc
	 ,rms_timestamp
	 ,rowid drowid
  FROM xx_inv_item_loc_int
 WHERE item=p_item
   AND loc=p_loc
   AND action_type=p_action
   AND process_flag+0=-1
   AND inventory_item_id=-1
 ORDER BY rms_timestamp DESC;

BEGIN
  SELECT MAX(control_id)
    INTO v_mstctl_id
    FROM xx_inv_ebs_control
   WHERE process_name='ITEM_MASTER';

  SELECT MAX(control_id)
    INTO v_locctl_id
    FROM xx_inv_ebs_control
   WHERE process_name='ITEM_LOC';

  BEGIN
    INSERT 
	INTO XX_INV_ITEM_MASTER_INT
	( 	 ITEM
		,CLASS                                
		,DEPT                                 
		,HANDLING_SENSITIVITY                 
		,ITEM_DESC                            
		,ITEM_NUMBER_TYPE                     
		,ORDER_AS_TYPE                        
		,ORDERABLE_IND                        
		,PACK_IND                             
		,PACK_TYPE                            
		,PACKAGE_SIZE                         
		,PACKAGE_UOM                          
		,SELLABLE_IND                         
		,SHIP_ALONE_IND                       
		,SHORT_DESC                           
		,SIMPLE_PACK_IND                      
		,STATUS                               
		,STORE_ORD_MULT                       
		,SUBCLASS                             
		,OD_ASSORTMENT_CD                     
		,OD_CALL_FOR_PRICE_CD                 
		,OD_COST_UP_FLG                       
		,OD_GIFT_CERTIF_FLG                   
		,OD_GSA_FLG                           
		,OD_IMPRINTED_ITEM_FLG                
		,OD_LIST_OFF_FLG                      
		,OD_META_CD                           
		,OD_OFF_CAT_FLG                       
		,OD_OVRSIZE_DELVRY_FLG                
		,OD_PRIVATE_BRAND_FLG                 
		,OD_PRIVATE_BRAND_LABEL               
		,OD_PROD_PROTECT_CD                   
		,OD_READY_TO_ASSEMBLE_FLG             
		,OD_RECYCLE_FLG                       
		,OD_RETAIL_PRICING_FLG                
		,OD_SKU_TYPE_CD                       
		,OD_TAX_CATEGORY                      
		,MASTER_ITEM                          
		,SUBSELL_MASTER_QTY                   
		,CONTROL_ID                           
		,ACTION_TYPE                          
		,RMS_PROCESS_ID                           
		,RMS_TIMESTAMP                        
		,PROCESS_FLAG                         
		,CREATION_DATE                        
		,CREATED_BY                           
		,LAST_UPDATE_DATE                     
		,LAST_UPDATED_BY 
		,inventory_item_id
	)
    SELECT 	 ITEM
		,CLASS                                
		,DEPT                                 
		,HANDLING_SENSITIVITY                 
		,ITEM_DESC                            
		,ITEM_NUMBER_TYPE                     
		,ORDER_AS_TYPE                        
		,ORDERABLE_IND                        
		,PACK_IND                             
		,PACK_TYPE                            
		,PACKAGE_SIZE                         
		,PACKAGE_UOM                          
		,SELLABLE_IND                         
		,SHIP_ALONE_IND                       
		,SHORT_DESC                           
		,SIMPLE_PACK_IND                      
		,STATUS                               
		,STORE_ORD_MULT                       
		,SUBCLASS                             
		,OD_ASSORTMENT_CD                     
		,OD_CALL_FOR_PRICE_CD                 
		,OD_COST_UP_FLG                       
		,OD_GIFT_CERTIF_FLG                   
		,OD_GSA_FLG                           
		,OD_IMPRINTED_ITEM_FLG                
		,OD_LIST_OFF_FLG                      
		,OD_META_CD                           
		,OD_OFF_CAT_FLG                       
		,OD_OVRSIZE_DELVRY_FLG                
		,OD_PRIVATE_BRAND_FLG                 
		,OD_PRIVATE_BRAND_LABEL               
		,OD_PROD_PROTECT_CD                   
		,OD_READY_TO_ASSEMBLE_FLG             
		,OD_RECYCLE_FLG                       
		,OD_RETAIL_PRICING_FLG                
		,OD_SKU_TYPE_CD                       
		,OD_TAX_CATEGORY                      
		,MASTER_ITEM                          
		,SUBSELL_MASTER_QTY                   
		,CONTROL_ID
		,ACTION_type
		,RMS_PROCESS_ID                           
		,rms_timestamp
		,-1
		,SYSDATE
		,fnd_global.user_id                           
		,SYSDATE                     
		,fnd_global.user_id 
		,-1
	FROM  xxptp.XX_INV_ITEM_MASTER_INT_BKP
     WHERE control_id>NVL(v_mstctl_id,0);

  COMMIT;
  
  SELECT MAX(control_id)
    INTO v_mstctl_id
    FROM xx_inv_item_master_int;

  UPDATE xx_inv_ebs_control
     SET control_id=NVL(v_mstctl_id,0)
   WHERE process_name='ITEM_MASTER';

  EXCEPTION
    WHEN others THEN
  	x_errbuf   :=SQLERRM;
      x_retcode  :=-1;
  END;

  COMMIT;

  BEGIN
    INSERT 
	INTO XX_INV_ITEM_LOC_INT 
	(	 CONTROL_ID                  
		,PROCESS_FLAG                
		,ACTION_TYPE                 
		,RMS_PROCESS_ID                  
		,RMS_TIMESTAMP               
		,ITEM                        
		,LOC                         
		,LOCAL_ITEM_DESC             
		,LOCAL_SHORT_DESC            
		,PRIMARY_SUPP                
		,STATUS                      
		,OD_ABC_CLASS                
		,OD_CHANNEL_BLOCK            
		,OD_DIST_TARGET              
		,OD_EBW_QTY                  
		,OD_INFINITE_QTY_CD          
		,OD_LOCK_UP_ITEM_FLG         
		,OD_PROPRIETARY_TYPE_CD      
		,OD_REPLEN_SUB_TYPE_CD       
		,OD_REPLEN_TYPE_CD           
		,OD_WHSE_ITEM_CD             
		,CREATION_DATE               
		,CREATED_BY                  
		,LAST_UPDATE_DATE            
		,LAST_UPDATED_BY             
		,inventory_item_id
	)
    SELECT   CONTROL_ID
		,-1      
		,ACTION_type
		,RMS_PROCESS_ID                  
		,rms_timestamp               
		,ITEM                        
		,LOC                         
		,LOCAL_ITEM_DESC             
		,LOCAL_SHORT_DESC            
		,PRIMARY_SUPP                
		,STATUS                      
		,OD_ABC_CLASS                
		,OD_CHANNEL_BLOCK            
		,OD_DIST_TARGET              
		,OD_EBW_QTY                  
		,OD_INFINITE_QTY_CD          
		,OD_LOCK_UP_ITEM_FLG         
		,OD_PROPRIETARY_TYPE_CD      
		,OD_REPLEN_SUB_TYPE_CD       
		,OD_REPLEN_TYPE_CD           
		,OD_WHSE_ITEM_CD             
		,SYSDATE
		,fnd_global.user_id
		,SYSDATE
		,fnd_global.user_id
		,-1
	FROM  xxptp.XX_INV_ITEM_LOC_INT_BKP
     WHERE control_id>NVL(v_locctl_id,0);
  
    COMMIT;

    SELECT MAX(control_id)
      INTO v_locctl_id
      FROM xx_inv_item_loc_int;


    UPDATE xx_inv_ebs_control
       SET control_id=NVL(v_locctl_id,0)
     WHERE process_name='ITEM_LOC';
  EXCEPTION
    WHEN others THEN
  	x_errbuf   :=SQLERRM;
      x_retcode  :=-1;
  END;

  -- To set the item records to success for duplicate 'A'
  j:=0;
  FOR cur IN c_master_set('A') LOOP
    i:=0;
    j:=j+1;
    IF j>5000 THEN
	 COMMIT;
       j:=0;
    END IF;
    FOR c IN c_master_setd(cur.item,'A') LOOP
      i:=i+1;
      IF i>1 THEN
	   UPDATE xx_inv_item_master_int
	      SET process_flag=7
		   ,item_process_flag=7
		   ,load_batch_id=-999
	    WHERE rowid=c.drowid;
	END IF;
    END LOOP;
  END LOOP;
  COMMIT;

  OPEN c_master_org;
  FETCH c_master_org INTO gn_master_org_id;
  CLOSE c_master_org;

  -- To set the item record action_type='C' if already exists in EBS for action_type='A'

  i:=0;

  FOR cur IN C2('A') LOOP
    i:=i+1;
    IF i>5000 THEN
	 COMMIT;
    END IF;
    BEGIN
      SELECT primary_uom_code
        INTO v_uom_code
        FROM mtl_system_items_b
   	 WHERE organization_id=gn_master_org_id
	   AND segment1=cur.item;
      IF v_uom_code IS NOT NULL THEN
	   UPDATE xx_inv_item_master_int
	      SET action_type='C',source_system_code=v_uom_code
	    WHERE rowid=cur.drowid;
      END IF;
    EXCEPTION
	WHEN others THEN
	   UPDATE xx_inv_item_master_int
	      SET process_flag=1
	    WHERE rowid=cur.drowid;
    END;
  END LOOP;
  COMMIT;

  -- To set the item records to success for duplicate 'C'
  j:=0;
  FOR cur IN c_master_set('C') LOOP
    i:=0;
    j:=j+1;
    IF j>5000 THEN
	 COMMIT;
       j:=0;
    END IF;
    FOR c IN c_master_setd(cur.item,'C') LOOP
      i:=i+1;
      IF i>1 THEN
	   UPDATE xx_inv_item_master_int
	      SET process_flag=7
		   ,item_process_flag=7
		   ,load_batch_id=-999
	    WHERE rowid=c.drowid;
	END IF;
    END LOOP;
  END LOOP;
  COMMIT;

  -- To set the primary_uom_code for item changed records

  i:=0;
  FOR cur IN C2('C') LOOP
    i:=i+1;
    IF i>5000 THEN
	 COMMIT;
    END IF;
    BEGIN
      SELECT primary_uom_code
        INTO v_uom_code
        FROM mtl_system_items_b
   	 WHERE organization_id=gn_master_org_id
	   AND segment1=cur.item;
      IF v_uom_code IS NOT NULL THEN
	   UPDATE xx_inv_item_master_int
	      SET process_Flag=1,source_system_code=v_uom_code
	    WHERE rowid=cur.drowid;
      END IF;
    EXCEPTION
	WHEN others THEN
	  NULL;
    END;
  END LOOP;
  COMMIT;

  -- To set the item loc records to success for duplicate 'A'

  j:=0;
  FOR cur IN c_loc_set('A') LOOP
    i:=0;
    j:=j+1;
    IF j>5000 THEN
	 COMMIT;
       j:=0;
    END IF;
    FOR c IN c_loc_setd(cur.item,cur.loc,'A') LOOP
      i:=i+1;
      IF i>1 THEN
	   UPDATE xx_inv_item_loc_int
	      SET process_flag=7
		   ,location_process_flag=7
		   ,load_batch_id=-999
	    WHERE rowid=c.drowid;
	END IF;
    END LOOP;
  END LOOP;
  COMMIT;

  -- To set the item loc records action_type='C' if already exists in EBS

  i:=0;
  FOR cur IN C1('A') LOOP
    i:=i+1;
    IF i>5000 THEN
	 COMMIT;
    END IF;
    BEGIN
   	SELECT primary_uom_code
        INTO v_uom_code
        FROM mtl_system_items_b b
		,hr_all_organization_units c
  	 WHERE c.attribute1=TO_CHAR(cur.loc)
	   AND b.organization_id=c.organization_id
	   AND b.segment1=cur.item;
      IF v_uom_code IS NOT NULL THEN
 	   UPDATE xx_inv_item_loc_int
	       SET action_type='C',source_system_code=v_uom_code
	      WHERE rowid=cur.drowid;
      END IF;
    EXCEPTION
	WHEN others THEN
	  UPDATE xx_inv_item_loc_int
	     SET process_flag=1
	   WHERE rowid=cur.drowid
	     AND EXISTS (SELECT 'x' 	
				 FROM apps.mtl_system_items_b
		            WHERE organization_id=441 
				  AND segment1=cur.item);
    END;
  END LOOP;
  COMMIT;

  -- To set the item loc records to success for duplicate 'C'

  j:=0;
  FOR cur IN c_loc_set('C') LOOP
    i:=0;
    j:=j+1;
    IF j>5000 THEN
	 COMMIT;
       j:=0;
    END IF;
    FOR c IN c_loc_setd(cur.item,cur.loc,'C') LOOP
      i:=i+1;
      IF i>1 THEN
	   UPDATE xx_inv_item_loc_int
	      SET process_flag=7
		   ,location_process_flag=7
		   ,load_batch_id=-999
	    WHERE rowid=c.drowid;
	END IF;
    END LOOP;
  END LOOP;
  COMMIT;

  i:=0;
  FOR cur IN C1('C') LOOP
    i:=i+1;
    IF i>5000 THEN
	 COMMIT;
    END IF;
    BEGIN
   	SELECT primary_uom_code
        INTO v_uom_code
        FROM mtl_system_items_b b
		,hr_all_organization_units c
  	 WHERE c.attribute1=TO_CHAR(cur.loc)
	   AND b.organization_id=c.organization_id
	   AND b.segment1=cur.item;
     IF v_uom_code IS NOT NULL THEN
 	  UPDATE xx_inv_item_loc_int
	     SET process_Flag=1,source_system_code=v_uom_code
	   WHERE rowid=cur.drowid;
     END IF;
   EXCEPTION
	  WHEN others THEN
	    NULL;
   END;
 END LOOP;
 COMMIT;
 UPDATE xxptp.xx_inv_item_loc_int
    SET process_flag=1,location_process_Flag=null,inventory_item_id=-1,load_batch_id=null,
	  error_flag=null,error_message=null
  WHERE creation_date>sysdate-1
    AND error_message like '%Master%';
 COMMIT;

END RMS_EBS_EXTRACT;


END XX_INV_RMS_LOAD_PKG;
/
SHOW ERRORS
EXIT;
