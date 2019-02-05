CREATE OR REPLACE PACKAGE BODY XX_INV_RMS_INT_LOAD
-- Version 1.1
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- +===========================================================================+
-- |Package Name : XX_INV_RMS_INT_LOAD                                         |
-- |Purpose      : This package contains three procedures that interface       |
-- |               from RMS to EBS.                                            |
-- |                                                                           |
-- |                                                                           |
-- |Change History                                                             |
-- |                                                                           |
-- |Ver   Date          Author             Description                         |
-- |---   -----------   -----------------  ------------------------------------|
-- |1.0   19-JUL-2008  Ganesh Nadakudhiti Original Code                        |
-- |1.1   29-SEP-2008  Ganesh Nadakudhiti Modified to do full merch refresh    |
-- |1.2   19-Oct-2015  Madhu Bolli        Remove schema for 12.2 retrofit      |
-- |1.3	  04-Jan-2018  Shalu George       Commented lines for EBS Lift and Shift |
-- +===========================================================================+
IS
--
--Global Variables
--
G_underline VARCHAR2(100) := RPAD('-',80,'-');
G_Star      VARCHAR2(100) := RPAD('*',40,'*');

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
--
EX_INVALID_PROCESS     EXCEPTION;
EX_SUB_REQU            EXCEPTION;
--
BEGIN
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_underline);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Begin Load Process');
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Process Name -'||p_process_name);
 --
 IF p_process_name IS NULL THEN
   --
   v_error_message := 'Process Name is Null';
   FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
   RAISE ex_invalid_process;
   --
 ELSE
   --
   v_process_info.process_name := p_process_name;
   --
 END IF;
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Get Process Details');
 get_process_details(v_process_info);

 --
 IF v_process_info.return_code < 0 THEN
   --
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Getting Process Details');
   v_error_message := v_process_info.error_message ;
   RAISE ex_invalid_process;
   --
 END IF;
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling the Individual Process');
 ----------------------------------------------
 -- Call Individual Processes
 ----------------------------------------------

 IF p_process_name = 'MERCH_HIER' THEN
  --
  Load_MerchHier_Data(v_process_info);
  --
 ELSIF p_process_name = 'ORG_HIER' THEN
  --
  Load_OrgHier_Data(v_process_info);
  --
 ELSIF p_process_name = 'ITEM_XREF' THEN
  --
  Load_ItemXref_Data(v_process_info);
  --
 ELSIF p_process_name = 'LOCATION' THEN
  --
  Load_Location_Data(v_process_info);
  --
 END IF;
 --

 ------------------------------------------------------
 -- Read the Return code and set the completion status
 ------------------------------------------------------

 IF v_process_info.return_code <0 THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Load Process Returned Errors,Setting stauts to Warning');
  -- Set the status to Warning
  v_request_status := FND_CONCURRENT.set_completion_status('WARNING','Error Loading data for '||p_process_name);
  --
 END IF;
 --
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
--
--
/*CURSOR csr_get_mrch_deletes IS
SELECT mrch.hierarchy_value ,
       mrch.hierarchy_level ,
       mrch.hierarchy_order
  FROM (SELECT ffv.flex_value hierarchy_value, 'DIVISION' hierarchy_level,1 hierarchy_order
          FROM fnd_flex_values ffv, fnd_flex_value_sets fvs
         WHERE fvs.flex_value_set_name = 'XX_GI_DIVISION_VS'
           AND ffv.flex_value_set_id = fvs.flex_value_set_id
           AND ffv.flex_value NOT IN ('NEW', 'COGS', '0')
           AND NVL (ffv.enabled_flag, 'N') = 'Y'
           AND NOT EXISTS (SELECT 1
                             FROM division@rms.na.odcorp.net
                            WHERE TO_CHAR (division) = ffv.flex_value)
        UNION ALL
        SELECT ffv.flex_value hierarchy_value, 'GROUP' hierarchy_level,2 hierarchy_order
          FROM fnd_flex_values ffv, fnd_flex_value_sets fvs
         WHERE fvs.flex_value_set_name = 'XX_GI_GROUP_VS'
           AND ffv.flex_value_set_id = fvs.flex_value_set_id
           AND ffv.flex_value NOT IN ('NEW', 'COGS', '0')
           AND NVL (ffv.enabled_flag, 'N') = 'Y'
           AND NOT EXISTS (SELECT 1
                             FROM GROUPS@rms.na.odcorp.net
                            WHERE TO_CHAR (group_no) = ffv.flex_value)
        UNION ALL
        SELECT ffv.flex_value hierarchy_value, 'DEPARTMENT' hierarchy_level,3 hierarchy_order
          FROM fnd_flex_values ffv, fnd_flex_value_sets fvs
         WHERE fvs.flex_value_set_name = 'XX_GI_DEPARTMENT_VS'
           AND ffv.flex_value_set_id = fvs.flex_value_set_id
           AND ffv.flex_value NOT IN ('NEW', 'COGS', '0')
           AND NVL (ffv.enabled_flag, 'N') = 'Y'
           AND NOT EXISTS (SELECT 1
                             FROM deps@rms.na.odcorp.net
                            WHERE TO_CHAR (dept) = ffv.flex_value)
        UNION ALL
        SELECT ffv.flex_value hierarchy_value, 'CLASS' hierarchy_level,4 hierarchy_order
          FROM fnd_flex_values ffv, fnd_flex_value_sets fvs
         WHERE fvs.flex_value_set_name = 'XX_GI_CLASS_VS'
           AND ffv.flex_value_set_id = fvs.flex_value_set_id
           AND ffv.flex_value NOT IN ('NEW', 'COGS', '0')
           AND NVL (ffv.enabled_flag, 'N') = 'Y'
           AND NOT EXISTS (SELECT 1
                             FROM CLASS@rms.na.odcorp.net
                            WHERE TO_CHAR (CLASS) = ffv.flex_value)
        UNION ALL
        SELECT ffv.flex_value hierarchy_value, 'SUBCLASS' hierarchy_level,5 hierarchy_order
          FROM fnd_flex_values ffv, fnd_flex_value_sets fvs
         WHERE fvs.flex_value_set_name = 'XX_GI_SUBCLASS_VS'
           AND ffv.flex_value_set_id = fvs.flex_value_set_id
           AND ffv.flex_value NOT IN ('NEW', 'COGS', '0')
           AND NVL (ffv.enabled_flag, 'N') = 'Y'
           AND NOT EXISTS (SELECT 1
                             FROM subclass@rms.na.odcorp.net
                            WHERE TO_CHAR (subclass) = ffv.flex_value)) mrch
 WHERE NOT EXISTS(SELECT 1
                    FROM xx_inv_merchier_int
                   WHERE process_flag = 1
                     AND hierarchy_level = mrch.hierarchy_level
                     AND hierarchy_value = mrch.hierarchy_value)
ORDER BY hierarchy_order DESC ;*/
v_del_records NUMBER := 0;
--
BEGIN
 --
 /*FND_FILE.PUT_LINE(FND_FILE.LOG,G_Star);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'In Procedure Load_MerchHier_Data ....');
 --
 v_user_id := FND_GLOBAL.user_id;
 --
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
                                 process_id                   ,   --  rms_process_id
                                 create_timestamp             ,   --  rms_timestamp
                                 action_code                  ,   --  action_type
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
                           FROM RMS_INT_MERCH_HIER
                          WHERE control_id   > p_process_info.control_id;
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
 --
 -- Identify the deleted Merch Records and Insert them into the Staging table
 -- make sure the control id for these records is less than the control id of the
 -- records received from rms
 --
 v_error_message := 'Identifying Merch records that were deleted in RMS' ;
 FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
 --
 BEGIN
  SELECT MAX(control_id)
    INTO v_control_id
    FROM xx_inv_merchier_int
   WHERE process_flag in( 1,6)
     AND control_id < 0;
 EXCEPTION
  WHEN OTHERS THEN
   v_control_id := NULL;
 END ;
 --
 IF v_control_id IS NULL THEN
  v_control_id := p_process_info.control_id ;
  v_control_id := -1 * p_process_info.control_id;
 ELSE
  v_control_id := v_control_id + 1;	
 END IF;
 --
 FOR mer_del IN csr_get_mrch_deletes 
 LOOP
 --
 v_error_message := 'Inserting Delete Record for '||mer_del .hierarchy_level||' ,value '||mer_del .hierarchy_value ;
 FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
 --	
 v_del_records := v_del_records +1;
  INSERT INTO XX_INV_MERCHIER_INT(control_id                   ,
                                  process_flag                 ,
                                  rms_process_id               ,
                                  rms_timestamp                ,
                                  action_type                  ,
                                  hierarchy_level              ,
                                  hierarchy_value              ,
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
                           SELECT v_control_id                 ,   --  control_id
                                  1                            ,   --  process_flag
                                  0                            ,   --  rms_process_id
                                  SYSDATE                      ,   --  rms_timestamp
                                  'D'                          ,   --  action_type
                                  mer_del .hierarchy_level     ,   --  hierarchy_level
                                  mer_del .hierarchy_value     ,   --  hierarchy_value
                                  NULL                         ,   --  load_batch_id
                                  'N'                          ,   --  error_flag
                                  NULL                         ,   --  error_message
                                  0                            ,   --  error_count
                                  SYSDATE                      ,   --  creation_date
                                  v_user_id                    ,   --  created_by
                                  SYSDATE                      ,   --  last_update_date
                                  v_user_id                    ,   --  last_updated_by
                                  0                                --  request_id
                            FROM DUAL ;
   --                         
   v_control_id := v_control_id + 1; 
   --                         
 END LOOP;
 --
 v_error_message := 'Inserted '||TO_CHAR(v_del_records)||' Delete records in XX_INV_MERCHIER_INT table' ;
 FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
 --
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
  p_process_info.error_message := v_error_message;*/
  FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
  --
END Load_MerchHier_Data;
/*=============================================================================+
|                        Load_OrgHier_Data                                     |
+=============================================================================*/
PROCEDURE Load_OrgHier_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)
IS
--
v_user_id               NUMBER;
v_control_id            NUMBER;
v_error_message         VARCHAR2(2000);
EX_UPD_CONTROL_TAB      EXCEPTION;
--
BEGIN
 /*--
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_Star);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'In Procedure Load_OrgHier_Data ....');
 --
 --
 v_user_id := FND_GLOBAL.user_id;
 --
 v_error_message := 'Inserting records into Staging table' ;
 INSERT INTO xx_inv_orghier_int (control_id              ,
                                 process_flag            ,
                                 rms_process_id          ,
                                 rms_timestamp           ,
                                 action_type             ,
                                 hierarchy_level         ,
                                 hierarchy_value         ,
                                 hierarchy_description   ,
                                 chain_manager           ,
                                 area_manager            ,
                                 chain_number            ,
                                 region_manager          ,
                                 area_number             ,
                                 district_manager        ,
                                 region_number           ,
                                 load_batch_id           ,
                                 error_flag              ,
                                 error_message           ,
                                 error_count             ,
                                 creation_date           ,
                                 created_by              ,
                                 last_update_date        ,
                                 last_updated_by         ,
                                 request_id
                                )
                          SELECT control_id              ,      -- control_id
                                 1                       ,      -- process_flag
                                 process_id              ,      -- rms_process_id
                                 create_timestamp        ,      -- rms_timestamp
                                 action_code             ,      -- action_type
                                 hierarchy_level         ,      -- hierarchy_level
                                 hierarchy_value         ,      -- hierarchy_value
                                 hierarchy_description   ,      -- hierarchy_description
                                 chain_manager           ,      -- chain_manager
                                 area_manager            ,      -- area_manager
                                 chain_number            ,      -- chain_number
                                 region_manager          ,      -- region_manager
                                 area_number             ,      -- area_number
                                 district_manager        ,      -- district_manager
                                 region_number           ,      -- region_number
                                 NULL                    ,      -- load_batch_id
                                 'N'                     ,      -- error_flag
                                 NULL                    ,      -- error_message
                                 0                       ,      -- error_count
                                 SYSDATE                 ,      -- creation_date
                                 v_user_id               ,      -- created_by
                                 SYSDATE                 ,      -- last_update_date
                                 v_user_id               ,      -- last_updated_by
                                 0                              -- request_id
                            FROM RMS_INT_ORG_HIER
                           WHERE control_id   > p_process_info.control_id;
 --
 p_process_info.records_inserted := SQL%ROWCOUNT;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserted '||TO_CHAR(p_process_info.records_inserted)
                   ||' into XX_INV_ORGHIER_INT table');
 --
 IF p_process_info.records_inserted > 0 THEN
   v_error_message := 'Fetching Max Control id from Staging table' ;
   --
   SELECT MAX(control_id)
     INTO v_control_id
     FROM xx_inv_orghier_int;
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
  --*/
  NULL
END Load_OrgHier_Data;
/*===========================================================================+
|                        Load_ItemXref_Data                                  |
+===========================================================================*/
PROCEDURE Load_ItemXref_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)
IS
--
v_user_id               NUMBER;
v_control_id            NUMBER;
v_error_message         VARCHAR2(2000);
EX_UPD_CONTROL_TAB      EXCEPTION;
--
BEGIN
 --
/* FND_FILE.PUT_LINE(FND_FILE.LOG,G_Star);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'In Procedure Load_ItemXref_Data ....');
 --
 v_user_id := FND_GLOBAL.user_id;
 --
 v_error_message := 'Inserting records into Staging table' ;
 INSERT INTO xx_inv_itemxref_int (control_id            ,
                                  process_flag          ,
                                  rms_process_id        ,
                                  rms_timestamp         ,
                                  action_type           ,
                                  xref_object           ,
                                  item                  ,
                                  xref_item             ,
                                  xref_type             ,
                                  prod_multiplier       ,
                                  prod_mult_div_cd      ,
                                  prd_xref_desc         ,
                                  whslr_supplier        ,
                                  whslr_multiplier      ,
                                  whslr_mult_div_cd     ,
                                  whslr_retail_price    ,
                                  whslr_uom_cd          ,
                                  whslr_prod_category   ,
                                  whslr_gen_cat_pgnbr   ,
                                  whslr_fur_cat_pgnbr   ,
                                  whslr_nn_pgnbr        ,
                                  whslr_prg_elig_flg    ,
                                  whslr_branch_flg      ,
                                  load_batch_id         ,
                                  error_flag            ,
                                  error_message         ,
                                  error_count           ,
                                  creation_date         ,
                                  created_by            ,
                                  last_update_date      ,
                                  last_updated_by       ,
                                  request_id
                                 )
                           SELECT control_id            ,      -- control_id
                                  1                     ,      -- process_flag
                                  process_id            ,      -- rms_process_id
                                  create_timestamp      ,      -- rms_timestamp
                                  action_code           ,      -- action_type
                                  xref_object           ,      -- xref_object
                                  item                  ,      -- item
                                  xref_item             ,      -- xref_item
                                  xref_type             ,      -- xref_type
                                  prod_multiplier       ,      -- prod_multiplier
                                  prod_mult_div_cd      ,      -- prod_mult_div_cd
                                  prd_xref_desc         ,      -- prd_xref_desc
                                  whslr_supplier        ,      -- whslr_supplier
                                  whslr_multiplier      ,      -- whslr_multiplier
                                  whslr_mult_div_cd     ,      -- whslr_mult_div_cd
                                  whslr_retail_price    ,      -- whslr_retail_price
                                  whslr_uom_cd          ,      -- whslr_uom_cd
                                  whslr_prod_category   ,      -- whslr_prod_category
                                  whslr_gen_cat_pgnbr   ,      -- whslr_gen_cat_pgnbr
                                  whslr_fur_cat_pgnbr   ,      -- whslr_fur_cat_pgnbr
                                  whslr_nn_pgnbr        ,      -- whslr_nn_pgnbr
                                  whslr_prg_elig_flg    ,      -- whslr_prg_elig_flg
                                  whslr_branch_flg      ,      -- whslr_branch_flg
                                  NULL                  ,      -- load_batch_id
                                  'N'                   ,      -- error_flag
                                  NULL                  ,      -- error_message
                                  0                     ,      -- error_count
                                  SYSDATE              ,      -- creation_date
                                  v_user_id             ,      -- created_by
                                  SYSDATE               ,      -- last_update_date
                                  v_user_id             ,      -- last_updated_by
                                  0                            -- request_id
                             FROM RMS_INT_ITEM_XREF
                            WHERE control_id   > p_process_info.control_id;
 --
 p_process_info.records_inserted := SQL%ROWCOUNT;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserted '||TO_CHAR(p_process_info.records_inserted)
                   ||' into XX_INV_ITEMXREF_INT table');
 --
 IF p_process_info.records_inserted > 0 THEN
   --
   v_error_message := 'Fetching Max Control id from Staging table' ;
   --
   SELECT MAX(control_id)
     INTO v_control_id
     FROM xx_inv_itemxref_int;
   --
   p_process_info.control_id := v_control_id ;
   FND_FILE.PUT_LINE(FND_FILE.LOG,'The Max Control id is -'||TO_CHAR(v_control_id));
   --
   v_error_message := 'Calling procedure to update Control id in control table' ;
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
  --*/
  NULL
END Load_ItemXref_Data;
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
 /*FND_FILE.PUT_LINE(FND_FILE.LOG,G_Star);
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
      SELECT   control_id                       ,    -- bpel_instance_id
               XX_INV_ORG_DEF_CTL_ID_S.nextval  ,    -- control_id
               1                                ,    -- process_flag
               process_id                       ,    -- rms_process_id
               create_timestamp                 ,    -- rms_timestamp
               'I'                              ,    -- action_type(Always I as it is interface)
               action_code                      ,    -- action
               loc_type_ws                      ,    -- org_type
               loc_id_ws                        ,    -- location_number_sw
               address1_ws                      ,    -- add1_sw
               address2_ws                      ,    -- add2_sw
               ad_mkt_id_ws                     ,    -- od_ad_mkt_id_sw
               bts_flight_id_ws                 ,    -- od_bts_flight_id_sw
               city_ws                          ,    -- city_sw
               city_limits_flg_ws               ,    -- od_city_limits_flg_s
               close_date_ws                    ,    -- close_date_sw
               country_id_ws                    ,    -- country_id_sw
               county_ws                        ,    -- county_sw
               cross_dock_lead_time_ws          ,    -- od_cross_dock_lead_time_sw
               cross_str_dir_ws                 ,    -- od_cross_street_dir_1_sw
               cross_str_dir2_ws                ,    -- od_cross_street_dir_2_sw
               currency_code_ws                 ,    -- orig_currency_code_sw
               delivery_flg_ws                  ,    -- od_delivery_cd_sw
               district_id_ws                   ,    -- district_sw
               division_id_ws                   ,    -- od_division_id_sw
               email_ws                         ,    -- email_sw
               fax_number_ws                    ,    -- fax_number_sw
               geo_cd_ws                        ,    -- od_geo_cd_sw
               loc_name_ws                      ,    -- org_name_sw
               loc_name_ws                      ,    -- location_name
               manager_name_ws                  ,    -- mgr_name_sw
               model_tax_loc_ws                 ,    -- od_model_tax_loc_sw
               open_date_ws                     ,    -- open_date_sw
               order_cutoff_tm_ws               ,    -- od_ord_cutoff_tm_sw
               phone_number_ws                  ,    -- phone_number_sw
               postal_code_ws                   ,    -- pcode_sw
               reloc_id_ws                      ,    -- od_reloc_id_sw
               routing_cd_ws                    ,    -- od_routing_cd_sw
               sister_loc1_ws                   ,    -- od_sister_store1_sw
               sister_loc2_ws                   ,    -- od_sister_store2_sw
               sister_loc3_ws                   ,    -- od_sister_store3_sw
               state_ws                         ,    -- state_sw
               sub_type_code_ws                 ,    -- od_sub_type_cd_sw
               time_zone_ws                     ,    -- time_zone_sw
               type_code_ws                     ,    -- od_type_cd_sw
               default_wh_s                     ,    -- default_wh_sw
               default_wh_csc_s                 ,    -- od_default_wh_csc_s
               market_open_date_s               ,    -- od_mkt_open_date_s
               store_class_s                    ,    -- store_class_s
               store_format_s                   ,    -- format_s
               break_pack_ind_w                 ,    -- break_pack_ind_w
               default_xdock_w                  ,    -- od_defaultcrossdock_sw
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
          FROM RMS_INT_LOCATION
         WHERE control_id   > p_process_info.control_id;

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
  --*/
  NULL
END Load_Location_Data;

END XX_INV_RMS_INT_LOAD;
/