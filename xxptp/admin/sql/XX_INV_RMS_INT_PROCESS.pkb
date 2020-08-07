CREATE OR REPLACE PACKAGE BODY XX_INV_RMS_INT_PROCESS
-- Version 1.1
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- +===========================================================================+
-- |Package Name : XX_INV_RMS_INT_PROCESS                                      |
-- |Purpose      : This package contains three procedures that interface       |
-- |               from RMS to EBS.                                            |
-- |                                                                           |
-- |                                                                           |
-- |Change History                                                             |
-- |                                                                           |
-- |Ver   Date         Author             Description                          |
-- |---   -----------  ------------------ -------------------------------------|
-- |1.0   19-JUL-2008  Ganesh Nadakudhiti Original Code                        |
-- |1.1   29-SEP-2008  Ganesh Nadakudhiti Modified to do full merch refresh    |
-- +===========================================================================+
IS
--
--Global Variables
--
G_underline VARCHAR2(100) := RPAD('-',80,'-');
G_Star      VARCHAR2(100) := RPAD('*',40,'*');
--

-- +===========================================================================+
-- | Name        :  Process_Merch_Data                                         |
-- | Description :  This procedure processes the Merch Hierarchy data          |
-- | Parameters  :                                                             |
-- +===========================================================================+
PROCEDURE Process_Merch_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)
IS
 --
 CURSOR csr_get_merch_records(p_batch_id IN NUMBER) IS
 SELECT control_id                   ,
        process_flag                 ,
        rms_process_id               ,
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
        rowid   row_id
   FROM xx_inv_merchier_int
  WHERE load_batch_id  = p_batch_id
    AND process_flag   = 1
  ORDER BY 1;
 --
 TYPE mrch_stg_rec_tbl IS TABLE OF csr_get_merch_records%ROWTYPE
 INDEX BY BINARY_INTEGER;
 lt_stg_tab  mrch_stg_rec_tbl;
 --
 v_error_message        VARCHAR2(4000) ;
 v_process_flag         NUMBER         ;
 v_error_flag           VARCHAR2(1)    ;
 v_error_code           NUMBER         ;
 v_user_id              NUMBER         ;
 v_batch_id             NUMBER         ;
 --
 v_tot_records          NUMBER         ;
 v_success              NUMBER         ;
 v_fail                 NUMBER         ;
 v_log_error            VARCHAR2(1)    ;
 --
 v_error_rec            XX_INV_RMS_INT_PROCESS.p_error_rec ;
 ex_insert_errors       EXCEPTION ;
 --
BEGIN
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_star);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'In Procedure Process_Merch_Data .....');
 --
 v_success      := 0  ;
 v_fail         := 0  ;
 v_log_error    := 'N';
 v_user_id      := FND_GLOBAL.user_id;
 --
 IF p_process_info.load_batch_id IS NULL THEN
  v_batch_id := FND_GLOBAL.conc_request_id;
 ELSE
  v_batch_id := p_process_info.load_batch_id ;
 END IF;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Load Batch Id is -'||TO_CHAR(v_batch_id));
 --
 -- -------------------------------------------------------
 -- Reset Previosuly Errored Records
 -- -------------------------------------------------------
 IF p_process_info.reset_errors = 'Y' THEN
  --
  UPDATE xx_inv_merchier_int
     SET process_flag    = 1     ,
         error_flag      = 'N'   ,
         error_message   = NULL
   WHERE process_flag NOT IN(1,7);

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated '||TO_CHAR(SQL%ROWCOUNT)||' Previously Errored records');
  --
 END IF;
 -- -------------------------------------------------------
 -- Update all Unprocessed Records with batch id
 -- -------------------------------------------------------
 UPDATE xx_inv_merchier_int
    SET load_batch_id = v_batch_id
   WHERE process_flag = 1 ;

 FND_FILE.PUT_LINE(FND_FILE.LOG,'Found '||TO_CHAR(SQL%ROWCOUNT)||' records to process');
 COMMIT;
 --
 -- -------------------------------------------------------
 -- Collect the data into the table type
 -- Limit is not used because the batch size is small
 -- -------------------------------------------------------
  OPEN csr_get_merch_records(v_batch_id) ;
 FETCH csr_get_merch_records BULK COLLECT INTO lt_stg_tab;
 CLOSE csr_get_merch_records ;

 -- -------------------------------
 -- Validate the records one by one
 -- -------------------------------

 IF lt_stg_tab.COUNT <> 0 THEN
  --
  v_tot_records := lt_stg_tab.COUNT;
  --
  FOR i IN lt_stg_tab.FIRST..lt_stg_tab.LAST LOOP
   --
   BEGIN
    --  Intialize Variables
    v_process_flag   := NULL    ;
    v_error_message  := NULL    ;
    v_error_flag     := 'N'     ;
    v_error_code     := NULL    ;
    --
    -- ------------------------------------------------------
    -- Call XX_INV_MERC_HIERARCHY_PKG. Process_Merc_Hierarchy
    -- ------------------------------------------------------
    XX_INV_MERC_HIERARCHY_PKG.process_merc_hierarchy
             (p_hierarchy_level           => lt_stg_tab(i).hierarchy_level            ,
              p_value                     => lt_stg_tab(i).hierarchy_value            ,
              p_description               => lt_stg_tab(i).hierarchy_description      ,
              p_action                    => lt_stg_tab(i).action_type                ,
              p_division_number           => lt_stg_tab(i).division_number            ,
              p_group_number              => lt_stg_tab(i).group_number               ,
              p_dept_number               => lt_stg_tab(i).dept_number                ,
              p_class_number              => lt_stg_tab(i).class_number               ,
              p_dept_forecastingind       => lt_stg_tab(i).dept_forecasting_ind       ,
              p_dept_aipfilterind         => lt_stg_tab(i).dept_aipfilter_ind         ,
              p_dept_planningind          => lt_stg_tab(i).dept_planning_ind          ,
              p_dept_noncodeind           => lt_stg_tab(i).dept_noncode_ind           ,
              p_dept_ppp_ind              => lt_stg_tab(i).dept_pp_ind                ,
              p_class_nbrdaysamd          => lt_stg_tab(i).class_nbr_days_amd         ,
              p_class_fifthmrkdwnprocsscd => lt_stg_tab(i).class_fifth_mrkdwn_cd      ,
              p_class_prczcostflg         => lt_stg_tab(i).class_prcz_cost_flg        ,
              p_class_prczpriceflag       => lt_stg_tab(i).class_prcz_price_flg       ,
              p_class_priczlistflag       => lt_stg_tab(i).class_pricz_list_flg       ,
              p_class_furnitureflag       => lt_stg_tab(i).class_furniture_flg        ,
              p_class_aipfilterind        => lt_stg_tab(i).class_aipfilter_ind        ,
              p_subclass_defaulttaxcat    => lt_stg_tab(i).subclass_default_tax_cat   ,
              p_subclass_globalcontentind => lt_stg_tab(i).subclass_globalcontent_ind ,
              p_subclass_aipfilterind     => lt_stg_tab(i).subclass_aipfilter_ind     ,
              p_subclass_ppp_ind          => lt_stg_tab(i).subclass_pp_ind            ,
              x_error_msg                 => v_error_message                          ,
              x_error_code                => v_error_code
             );
    --
    IF v_error_code = 0 THEN
     --
     v_process_flag  := 7       ;
     v_error_message := NULL    ;
     v_error_flag    := 'N'     ;
     v_success := v_success +1  ;
     --
    ELSE
     --
     ROLLBACK;
     v_process_flag  := 6               ;
     v_error_message := v_error_message ;
     v_error_flag    := 'Y'             ;
     v_fail          := v_fail +1       ;
     v_log_error     := 'Y'             ;
     --
    END IF;
   EXCEPTION
    WHEN OTHERS THEN
     --
     ROLLBACK;
     v_process_flag  := 6         ;
     v_error_message := SUBSTR(('When others invoking Merch,SQL Error -'||SQLERRM),1,4000);
     v_error_flag    := 'Y'       ;
     v_fail          := v_fail +1 ;
     v_log_error     := 'Y'       ;
     --
   END;
   --
   IF v_process_flag <> 7 THEN
    --
     IF lt_stg_tab(i).action_type = 'D' THEN
      v_error_rec.process_name     := 'EBS_MERCH_HIER'             ;	
     ELSE
      v_error_rec.process_name     := 'MERCH_HIER'                 ;
     END IF;
     --
     v_error_rec.rms_process_id   := lt_stg_tab(i).rms_process_id  ;
     v_error_rec.key_value_1      := lt_stg_tab(i).hierarchy_level ;
     v_error_rec.key_value_2      := lt_stg_tab(i).hierarchy_value ;
     v_error_rec.error_message    := v_error_message ;
     v_error_rec.user_id          := v_user_id ;
     --
     SELECT XX_INV_ERROR_LOG_S.NEXTVAL
       INTO v_error_rec.control_id
       FROM DUAL;
     --
     XX_INV_RMS_INT_PROCESS.insert_error(v_error_rec);
     --
     IF v_error_rec.return_code < 0 THEN
      v_error_message := v_error_rec.return_message ;
      RAISE ex_insert_errors;
     ELSE
      v_error_flag := 'P';
     END IF;
     --
   END IF;
   --
   -- ------------------------------------------------
   -- Update the error,process flag in the stage table
   -- ------------------------------------------------

   UPDATE xx_inv_merchier_int
      SET error_flag       = v_error_flag       ,
          error_message    = v_error_message    ,
          last_update_date = SYSDATE            ,
          last_updated_by  = v_user_id          ,
          process_flag     = v_process_flag
    WHERE rowid            = lt_stg_tab(i).row_id;

   COMMIT;
  END LOOP;
 END IF;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Successful Records - '||TO_CHAR(v_success));
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Records - '||TO_CHAR(v_fail));
EXCEPTION
 WHEN ex_insert_errors THEN
  ROLLBACK;
  p_process_info.return_code :=-1;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Encountered Errors During Error Insert');
 WHEN OTHERS THEN
  ROLLBACK;
  p_process_info.return_code :=-1;
  v_error_message := 'When Others Exception while '||v_error_message;
  v_error_message := SUBSTR((v_error_message||',SQL Error -'||SQLERRM),1,2000);
  p_process_info.error_message := v_error_message ;
  FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message) ;
END Process_Merch_Data ;

-- +===========================================================================+
-- | Name        :  Process_ItemXref_Data                                      |
-- | Description :  This procedure processes the ItemXref Hierarchy data       |
-- | Parameters  :                                                             |
-- +===========================================================================+

PROCEDURE Process_ItemXref_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)
IS
 --
 CURSOR csr_get_xref_records(p_batch_id IN NUMBER) IS
 SELECT control_id            ,
        rms_process_id        ,
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
        rowid   row_id
   FROM xx_inv_itemxref_int
  WHERE load_batch_id  = p_batch_id
    AND process_flag   = 1
  ORDER BY 1;
 --
 TYPE Xref_stg_rec_tbl IS TABLE OF csr_get_xref_records%ROWTYPE
 INDEX BY BINARY_INTEGER;
 lt_stg_tab  Xref_stg_rec_tbl;
 --
 v_error_message        VARCHAR2(4000) ;
 v_process_flag         NUMBER         ;
 v_error_flag           VARCHAR2(1)    ;
 v_error_code           NUMBER         ;
 v_user_id              NUMBER         ;
 v_batch_id             NUMBER         ;
 --
 v_tot_records          NUMBER         ;
 v_success              NUMBER         ;
 v_fail                 NUMBER         ;
 v_log_error            VARCHAR2(1)    ;
 --
 v_error_rec            XX_INV_RMS_INT_PROCESS.p_error_rec ;
 ex_insert_errors       EXCEPTION ;
 --
 BEGIN
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_star);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'In Procedure Process_Item_Xref_Data .....');
 --
 v_success      := 0  ;
 v_fail         := 0  ;
 v_log_error    := 'N';
 v_user_id      := FND_GLOBAL.user_id;
 --
 IF p_process_info.load_batch_id IS NULL THEN
  v_batch_id := FND_GLOBAL.conc_request_id;
 ELSE
  v_batch_id := p_process_info.load_batch_id ;
 END IF;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Load Batch Id is -'||TO_CHAR(v_batch_id));
 --
 -- -------------------------------------------------------
 -- Reset Previosuly Errored Records
 -- -------------------------------------------------------
 IF p_process_info.reset_errors = 'Y' THEN
  --
  UPDATE xx_inv_itemxref_int
     SET process_flag    = 1     ,
         error_flag      = 'N'   ,
         error_message   = NULL
   WHERE process_flag NOT IN(1,7);

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated '||TO_CHAR(SQL%ROWCOUNT)||' Previously Errored records');
  --
 END IF;
 -- -------------------------------------------------------
 -- Update all Unprocessed Records with batch id
 -- -------------------------------------------------------
 UPDATE xx_inv_itemxref_int
    SET load_batch_id = v_batch_id
   WHERE process_flag = 1 ;

 FND_FILE.PUT_LINE(FND_FILE.LOG,'Found '||TO_CHAR(SQL%ROWCOUNT)||' records to process');
 COMMIT;
 --
 -- -------------------------------------------------------
 -- Collect the data into the table type
 -- Limit is not used because the batch size is small
 -- -------------------------------------------------------
  OPEN csr_get_xref_records(v_batch_id) ;
 FETCH csr_get_xref_records BULK COLLECT INTO lt_stg_tab;
 CLOSE csr_get_xref_records ;

 -- -------------------------------
 -- Validate the records one by one
 -- -------------------------------

 IF lt_stg_tab.COUNT <> 0 THEN
  --
  v_tot_records := lt_stg_tab.COUNT;
  --
  FOR i IN lt_stg_tab.FIRST..lt_stg_tab.LAST LOOP
   --
   BEGIN
    --  Intialize Variables
    v_process_flag   := NULL    ;
    v_error_message  := NULL    ;
    v_error_flag     := 'N'     ;
    v_error_code     := NULL    ;
    --
    -- ------------------------------------------------------
    -- Call XX_INV_ITEM_XREF_PKG.Process_item_xref
    -- ------------------------------------------------------
    XX_INV_ITEM_XREF_PKG.Process_item_xref
                   (p_xref_object       => lt_stg_tab(i).xref_object          ,
                    p_item              => lt_stg_tab(i).item                 ,
                    p_action            => lt_stg_tab(i).action_type          ,
                    p_xref_item         => lt_stg_tab(i).xref_item            ,
                    p_xref_type         => lt_stg_tab(i).xref_type            ,
                    p_prodmultiplier    => lt_stg_tab(i).prod_multiplier      ,
                    p_prodmultdivcd     => lt_stg_tab(i).prod_mult_div_cd     ,
                    p_prdxrefdesc       => lt_stg_tab(i).prd_xref_desc        ,
                    p_whslrsupplier     => lt_stg_tab(i).whslr_supplier       ,
                    p_whslrmultiplier   => lt_stg_tab(i).whslr_multiplier     ,
                    p_whslrmultdivcd    => lt_stg_tab(i).whslr_mult_div_cd    ,
                    p_whslrretailprice  => lt_stg_tab(i).whslr_retail_price   ,
                    p_whslruomcd        => lt_stg_tab(i).whslr_uom_cd         ,
                    p_whslrprodcategory => lt_stg_tab(i).whslr_prod_category  ,
                    p_whslrgencatpgnbr  => lt_stg_tab(i).whslr_gen_cat_pgnbr  ,
                    p_whslrfurcatpgnbr  => lt_stg_tab(i).whslr_fur_cat_pgnbr  ,
                    p_whslrnnpgnbr      => lt_stg_tab(i).whslr_nn_pgnbr       ,
                    p_whslrprgeligflg   => lt_stg_tab(i).whslr_prg_elig_flg   ,
                    p_whslrbranchflg    => lt_stg_tab(i).whslr_branch_flg     ,
                    x_message_code      => v_error_code                       ,
                    x_message_data      => v_error_message
                   );
    --
    IF v_error_code = 0 THEN
     --
     v_process_flag  := 7       ;
     v_error_message := NULL    ;
     v_error_flag    := 'N'     ;
     v_success := v_success +1  ;
     --
    ELSE
     --
     v_process_flag  := 6               ;
     v_error_message := v_error_message ;
     v_error_flag    := 'Y'             ;
     v_fail          := v_fail +1       ;
     v_log_error     := 'Y'             ;
     --
    END IF;
   EXCEPTION
    WHEN OTHERS THEN
     --
     v_process_flag  := 6         ;
     v_error_message := SUBSTR(('When others invoking Xref,SQL Error -'||SQLERRM),1,4000);
     v_error_flag    := 'Y'       ;
     v_fail          := v_fail +1 ;
     v_log_error     := 'Y'       ;
     --
   END;
   --
   IF v_process_flag <> 7 THEN
    --
     v_error_rec.rms_process_id   := lt_stg_tab(i).rms_process_id  ;
     v_error_rec.process_name     := 'ITEM_XREF'                   ;
     v_error_rec.key_value_1      := lt_stg_tab(i).xref_object     ;
     v_error_rec.key_value_2      := lt_stg_tab(i).item            ;
     v_error_rec.key_value_3      := lt_stg_tab(i).xref_item       ;
     v_error_rec.error_message    := v_error_message ;
     v_error_rec.user_id          := v_user_id ;
     --
     SELECT XX_INV_ERROR_LOG_S.NEXTVAL
       INTO v_error_rec.control_id
       FROM DUAL;
     --
     XX_INV_RMS_INT_PROCESS.insert_error(v_error_rec);
     --
     IF v_error_rec.return_code < 0 THEN
      v_error_message := v_error_rec.return_message ;
      RAISE ex_insert_errors;
     ELSE
      v_error_flag := 'P';
     END IF;
     --
   END IF;
   --
   -- ------------------------------------------------
   -- Update the error,process flag in the stage table
   -- ------------------------------------------------

   UPDATE xx_inv_itemxref_int
      SET error_flag       = v_error_flag       ,
          error_message    = v_error_message    ,
          last_update_date = SYSDATE            ,
          last_updated_by  = v_user_id          ,
          process_flag     = v_process_flag
    WHERE rowid            = lt_stg_tab(i).row_id;

   COMMIT;
  END LOOP;
 END IF;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Successful Records - '||TO_CHAR(v_success));
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Records - '||TO_CHAR(v_fail));
EXCEPTION
 WHEN ex_insert_errors THEN
  ROLLBACK;
  p_process_info.return_code :=-1;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Encountered Errors During Error Insert');
 WHEN OTHERS THEN
  ROLLBACK;
  p_process_info.return_code :=-1;
  v_error_message := 'When Others Exception while '||v_error_message;
  v_error_message := SUBSTR((v_error_message||',SQL Error -'||SQLERRM),1,2000);
  p_process_info.error_message := v_error_message;
  FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
END Process_ItemXref_Data ;

-- +===========================================================================+
-- | Name        :  Process_OrgHier_Data                                       |
-- | Description :  This procedure processes the Org Hierarchy data            |
-- | Parameters  :                                                             |
-- +===========================================================================+

PROCEDURE Process_OrgHier_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)
IS
 --
 CURSOR csr_get_orghier_recs(p_batch_id IN NUMBER) IS
 SELECT control_id              ,
        rms_process_id          ,
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
        rowid   row_id
   FROM xx_inv_orghier_int
  WHERE load_batch_id  = p_batch_id
    AND process_flag   = 1
  ORDER BY 1;
 --
 TYPE orgh_stg_rec_tbl IS TABLE OF csr_get_orghier_recs%ROWTYPE
 INDEX BY BINARY_INTEGER;
 lt_stg_tab  orgh_stg_rec_tbl;
 --
 v_error_message        VARCHAR2(4000) ;
 v_process_flag         NUMBER         ;
 v_error_flag           VARCHAR2(1)    ;
 v_error_code           NUMBER         ;
 v_user_id              NUMBER         ;
 v_batch_id             NUMBER         ;
 --
 v_tot_records          NUMBER         ;
 v_success              NUMBER         ;
 v_fail                 NUMBER         ;
 v_log_error            VARCHAR2(1)    ;
 --
 v_error_rec            XX_INV_RMS_INT_PROCESS.p_error_rec ;
 ex_insert_errors       EXCEPTION ;
 --
 BEGIN
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_star);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'In Procedure Process_OrgHier_Data .....');
 --
 v_success      := 0  ;
 v_fail         := 0  ;
 v_log_error    := 'N';
 v_user_id      := FND_GLOBAL.user_id;
 --
 IF p_process_info.load_batch_id IS NULL THEN
  v_batch_id := FND_GLOBAL.conc_request_id;
 ELSE
  v_batch_id := p_process_info.load_batch_id ;
 END IF;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Load Batch Id is -'||TO_CHAR(v_batch_id));
 --
 -- -------------------------------------------------------
 -- Reset Previosuly Errored Records
 -- -------------------------------------------------------
 IF p_process_info.reset_errors = 'Y' THEN
  --
  UPDATE xx_inv_orghier_int
     SET process_flag    = 1     ,
         error_flag      = 'N'   ,
         error_message   = NULL
   WHERE process_flag NOT IN(1,7);

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated '||TO_CHAR(SQL%ROWCOUNT)||' Previously Errored records');
   --
 END IF;
 -- -------------------------------------------------------
 -- Update all Unprocessed Records with batch id
 -- -------------------------------------------------------
 UPDATE xx_inv_orghier_int
    SET load_batch_id = v_batch_id
   WHERE process_flag = 1 ;

 FND_FILE.PUT_LINE(FND_FILE.LOG,'Found '||TO_CHAR(SQL%ROWCOUNT)||' records to process');
 COMMIT;
 --
 -- -------------------------------------------------------
 -- Collect the data into the table type
 -- Limit is not used because the batch size is small
 -- -------------------------------------------------------
  OPEN csr_get_orghier_recs(v_batch_id) ;
 FETCH csr_get_orghier_recs BULK COLLECT INTO lt_stg_tab;
 CLOSE csr_get_orghier_recs ;

 -- -------------------------------
 -- Validate the records one by one
 -- -------------------------------

 IF lt_stg_tab.COUNT <> 0 THEN
  --
  v_tot_records := lt_stg_tab.COUNT;
  --
  FOR i IN lt_stg_tab.FIRST..lt_stg_tab.LAST LOOP
   --
   BEGIN
    --  Intialize Variables
    v_process_flag   := NULL    ;
    v_error_message  := NULL    ;
    v_error_flag     := 'N'     ;
    v_error_code     := NULL    ;
    --
    -- ------------------------------------------------------
    -- Call XX_INV_ORG_HIERARCHY_PKG.process_org_hierarchy
    -- ------------------------------------------------------
    XX_INV_ORG_HIERARCHY_PKG.process_org_hierarchy
                   (p_hierarchy_level => lt_stg_tab(i).hierarchy_level         ,
                    p_value           => lt_stg_tab(i).hierarchy_value         ,
                    p_description     => lt_stg_tab(i).hierarchy_description   ,
                    p_action          => lt_stg_tab(i).action_type             ,
                    p_chain_number    => lt_stg_tab(i).chain_number            ,
                    p_area_number     => lt_stg_tab(i).area_number             ,
                    p_region_number   => lt_stg_tab(i).region_number           ,
                    x_message_code    => v_error_code                          ,
                    x_message_data    => v_error_message
                   );
     --
     --
    IF v_error_code = 0 THEN
     --
     v_process_flag  := 7       ;
     v_error_message := NULL    ;
     v_error_flag    := 'N'     ;
     v_success := v_success +1  ;
     --
    ELSE
     --
     v_process_flag  := 6               ;
     v_error_message := v_error_message ;
     v_error_flag    := 'Y'             ;
     v_fail          := v_fail +1       ;
     v_log_error     := 'Y'             ;
     --
    END IF;
   EXCEPTION
    WHEN OTHERS THEN
     --
     v_process_flag  := 6         ;
     v_error_message := SUBSTR(('When others invoking OrgHier,SQL Error -'||SQLERRM),1,4000);
     v_error_flag    := 'Y'       ;
     v_fail          := v_fail +1 ;
     v_log_error     := 'Y'       ;
     --
   END;
   --
   IF v_process_flag <> 7 THEN
    --
     v_error_rec.rms_process_id   := lt_stg_tab(i).rms_process_id  ;
     v_error_rec.process_name     := 'ORG_HIER'                    ;
     v_error_rec.key_value_1      := lt_stg_tab(i).hierarchy_level ;
     v_error_rec.key_value_2      := lt_stg_tab(i).hierarchy_value ;
     v_error_rec.error_message    := v_error_message ;
     v_error_rec.user_id          := v_user_id ;
     --
     SELECT XX_INV_ERROR_LOG_S.NEXTVAL
       INTO v_error_rec.control_id
       FROM DUAL;
     --
     XX_INV_RMS_INT_PROCESS.insert_error(v_error_rec);
     --
     IF v_error_rec.return_code < 0 THEN
      v_error_message := v_error_rec.return_message ;
      RAISE ex_insert_errors;
     ELSE
      v_error_flag := 'P';
     END IF;
     --
   END IF;
   --
   -- ------------------------------------------------
   -- Update the error,process flag in the stage table
   -- ------------------------------------------------
   UPDATE xx_inv_orghier_int
      SET error_flag       = v_error_flag       ,
          error_message    = v_error_message    ,
          last_update_date = SYSDATE            ,
          last_updated_by  = v_user_id          ,
          process_flag     = v_process_flag
    WHERE rowid            = lt_stg_tab(i).row_id;
   --
   COMMIT;
  END LOOP;
 END IF;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Successful Records - '||TO_CHAR(v_success));
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Records - '||TO_CHAR(v_fail));
EXCEPTION
 WHEN ex_insert_errors THEN
  ROLLBACK;
  p_process_info.return_code :=-1;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Encountered Errors During Error Insert');
 WHEN OTHERS THEN
  ROLLBACK;
  p_process_info.return_code :=-1;
  v_error_message := 'When Others Exception while '||v_error_message;
  v_error_message := SUBSTR((v_error_message||',SQL Error -'||SQLERRM),1,2000);
  p_process_info.error_message := v_error_message ;
  FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message) ;
END Process_OrgHier_Data ;

-- +===========================================================================+
-- | Name        :  Process_Location_Data                                      |
-- | Description :  This procedure processes the Location data                 |
-- | Parameters  :                                                             |
-- +===========================================================================+

PROCEDURE Process_Location_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)
IS
 --
 CURSOR csr_get_Location_records(p_batch_id IN NUMBER) IS
 SELECT control_id                   ,
        process_flag                 ,
        rms_process_id               ,
        action_type                  ,
        bpel_instance_id             ,
        location_number_sw           ,
        org_type                     ,
        rowid   row_id
   FROM xx_inv_org_loc_def_stg
  WHERE load_batch_id  = p_batch_id
    AND process_flag   = 1
  ORDER BY 1;
 --
 TYPE mrch_stg_rec_tbl IS TABLE OF csr_get_Location_records%ROWTYPE
 INDEX BY BINARY_INTEGER;
 lt_stg_tab  mrch_stg_rec_tbl;
 --
 v_error_message        VARCHAR2(4000) ;
 v_process_flag         NUMBER         ;
 v_error_flag           VARCHAR2(1)    ;
 v_error_code           NUMBER         ;
 v_user_id              NUMBER         ;
 v_batch_id             NUMBER         ;
 --
 v_tot_records          NUMBER         ;
 v_success              NUMBER         ;
 v_fail                 NUMBER         ;
 v_log_error            VARCHAR2(1)    ;
 --
 v_error_rec            XX_INV_RMS_INT_PROCESS.p_error_rec ;
 ex_insert_errors       EXCEPTION ;
 --
BEGIN
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_star);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'In Procedure Process_Location_Data .....');
 --
 v_success      := 0  ;
 v_fail         := 0  ;
 v_log_error    := 'N';
 v_user_id      := FND_GLOBAL.user_id;
 --
 IF p_process_info.load_batch_id IS NULL THEN
  v_batch_id := FND_GLOBAL.conc_request_id;
 ELSE
  v_batch_id := p_process_info.load_batch_id ;
 END IF;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Load Batch Id is -'||TO_CHAR(v_batch_id));
 --
 -- -------------------------------------------------------
 -- Reset Previosuly Errored Records
 -- -------------------------------------------------------
 IF p_process_info.reset_errors = 'Y' THEN
  --
  UPDATE xx_inv_org_loc_def_stg
     SET process_flag    = 1     ,
         error_flag      = 'N'   ,
         error_message   = NULL
   WHERE process_flag NOT IN(1,7);

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated '||TO_CHAR(SQL%ROWCOUNT)||' Previously Errored records');
  --
 END IF;
 -- -------------------------------------------------------
 -- Update all Unprocessed Records with batch id
 -- -------------------------------------------------------
 UPDATE xx_inv_org_loc_def_stg
    SET load_batch_id = v_batch_id
   WHERE process_flag = 1 ;

 FND_FILE.PUT_LINE(FND_FILE.LOG,'Found '||TO_CHAR(SQL%ROWCOUNT)||' records to process');
 COMMIT;
 --
 -- -------------------------------------------------------
 -- Collect the data into the table type
 -- Limit is not used because the batch size is small
 -- -------------------------------------------------------
  OPEN csr_get_Location_records(v_batch_id) ;
 FETCH csr_get_Location_records BULK COLLECT INTO lt_stg_tab;
 CLOSE csr_get_Location_records ;

 -- -------------------------------
 -- Validate the records one by one
 -- -------------------------------

 IF lt_stg_tab.COUNT <> 0 THEN
  --
  v_tot_records := lt_stg_tab.COUNT;
  --
  FOR i IN lt_stg_tab.FIRST..lt_stg_tab.LAST LOOP
   --
   BEGIN
    --  Intialize Variables
    v_process_flag   := NULL    ;
    v_error_message  := NULL    ;
    v_error_flag     := 'N'     ;
    v_error_code     := NULL    ;
    --
    -- ------------------------------------------------------
    -- Call XX_INV_ORG_LOC_DEF_PKG.Process_Main
    -- ------------------------------------------------------

     XX_INV_ORG_LOC_DEF_PKG.Process_Main
                      (x_message_data  => v_error_message                  ,
                       x_message_code  => v_error_code                     ,
                       p_action_type   => 'I'                              ,
                       p_bpel_inst_id  => lt_stg_tab(i).bpel_instance_id
                      );
    --
    IF v_error_code = 0 THEN
     --
     v_process_flag  := 7       ;
     v_error_message := NULL    ;
     v_error_flag    := 'N'     ;
     v_success := v_success +1  ;
     --
    ELSE
     --
     v_process_flag  := 6               ;
     v_error_message := v_error_message ;
     v_error_flag    := 'Y'             ;
     v_fail          := v_fail +1       ;
     v_log_error     := 'Y'             ;
     --
    END IF;
   EXCEPTION
    WHEN OTHERS THEN
     --
     v_process_flag  := 6         ;
     v_error_message := SUBSTR(('When others invoking loc,SQL Error -'||SQLERRM),1,4000);
     v_error_flag    := 'Y'       ;
     v_fail          := v_fail +1 ;
     v_log_error     := 'Y'       ;
     --
   END;
   --
   IF v_process_flag <> 7 THEN
    --
     v_error_rec.rms_process_id   := lt_stg_tab(i).rms_process_id     ;
     v_error_rec.process_name     := 'LOCATION'                       ;
     v_error_rec.key_value_1      := lt_stg_tab(i).org_type           ;
     v_error_rec.key_value_2      := lt_stg_tab(i).location_number_sw ;
     v_error_rec.error_message    := v_error_message                  ;
     v_error_rec.user_id          := v_user_id                        ;
     --
     SELECT XX_INV_ERROR_LOG_S.NEXTVAL
       INTO v_error_rec.control_id
       FROM DUAL;
     --
     XX_INV_RMS_INT_PROCESS.insert_error(v_error_rec);
     --
     IF v_error_rec.return_code < 0 THEN
      v_error_message := v_error_rec.return_message ;
      RAISE ex_insert_errors;
     ELSE
      v_error_flag := 'P';
     END IF;
     --
   END IF;
   --
   -- ------------------------------------------------
   -- Update the error,process flag in the stage table
   -- updating for every record as no of recs are low
   -- ------------------------------------------------

   UPDATE xx_inv_org_loc_def_stg
      SET error_flag       = v_error_flag       ,
          error_message    = v_error_message    ,
          update_date      = SYSDATE            ,
          updated_by       = v_user_id          ,
          process_flag     = v_process_flag
    WHERE rowid            = lt_stg_tab(i).row_id;

   COMMIT;
  END LOOP;
 END IF;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Successful Records - '||TO_CHAR(v_success));
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Records - '||TO_CHAR(v_fail));
EXCEPTION
 WHEN ex_insert_errors THEN
  ROLLBACK;
  p_process_info.return_code :=-1;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Encountered Errors During Error Insert');
 WHEN OTHERS THEN
  ROLLBACK;
  p_process_info.return_code :=-1;
  v_error_message := 'When Others Exception while '||v_error_message;
  v_error_message := SUBSTR((v_error_message||',SQL Error -'||SQLERRM),1,2000);
  p_process_info.error_message := v_error_message ;
  FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message) ;
END Process_Location_Data ;

-- +===========================================================================+
-- | Name        :  process_int_data                                           |
-- | Description :  This procedure inserts error records                       |
-- | Parameters  :                                                             |
-- +===========================================================================+

PROCEDURE Process_Int_Data(x_errbuf       OUT NOCOPY VARCHAR2,
                           x_retcode      OUT NOCOPY NUMBER  ,
                           p_process_name  IN VARCHAR2       ,
                           p_reset_errors  IN VARCHAR2
                          )
IS
--
v_process_info    XX_INV_RMS_INT_LOAD.p_control_rec;
v_error_message   VARCHAR2(2000);
v_request_status  BOOLEAN;
--
EX_INVALID_PROCESS     EXCEPTION;
EX_SUB_REQU            EXCEPTION;
--

BEGIN
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,G_underline);
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Begin Processing .....');
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
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Getting Process Details.....');
 XX_INV_RMS_INT_LOAD.get_process_details(v_process_info);

 --
 IF v_process_info.return_code < 0 THEN
   --
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Getting Process details');
   v_error_message := v_process_info.error_message ;
   RAISE ex_invalid_process;
   --
 END IF;

 --
  v_process_info.reset_errors := p_reset_errors;
 --
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling Individual Processes');
 ------------------------------------------
 -- Call Individual Processes
 ------------------------------------------
 IF p_process_name = 'MERCH_HIER' THEN
  --
  Process_Merch_Data(v_process_info) ;
  --
 ELSIF p_process_name = 'ORG_HIER' THEN
  --
  Process_OrgHier_Data(v_process_info) ;
  --
 ELSIF p_process_name = 'ITEM_XREF' THEN
  --
  Process_ItemXref_Data(v_process_info) ;
  --
 ELSIF p_process_name = 'LOCATION' THEN
  --
  Process_Location_Data(v_process_info) ;
  --
 END IF;
 --

 ------------------------------------------------------
 -- Read the Return code and set the completion status
 ------------------------------------------------------

 IF v_process_info.return_code <0 THEN
  --
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Encountered Errors during processing ,Setting status to warning....');
  v_request_status := FND_CONCURRENT.set_completion_status('WARNING','Error processing data for '||p_process_name);
  --
 END IF;
 --
EXCEPTION
 WHEN ex_invalid_process THEN
  x_errbuf := v_error_message;
  FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
  RAISE_APPLICATION_ERROR(-20100,SUBSTR(v_error_message,1,250));
 WHEN OTHERS THEN
  x_errbuf := v_error_message;
  FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
  RAISE_APPLICATION_ERROR(-20101,SUBSTR(SQLERRM,1,250));
END Process_Int_Data;

-- +===========================================================================+
-- | Name        :  insert_error                                               |
-- | Description :  This procedure inserts error records                       |
-- | Parameters  :                                                             |
-- +===========================================================================+

PROCEDURE insert_error(p_error_rec  IN OUT XX_INV_RMS_INT_PROCESS.p_error_rec)
IS
--
v_error_message             VARCHAR2(2000);
--
BEGIN
 INSERT INTO xx_inv_error_log(control_id                        ,
                              rms_process_id                    ,
                              process_name                      ,
                              key_value_1                       ,
                              key_value_2                       ,
                              key_value_3                       ,
                              key_value_4                       ,
                              key_value_5                       ,
                              error_message                     ,
                              process_flag                      ,
                              created_by                        ,
                              creation_date                     ,
                              last_updated_by                   ,
                              last_update_date
                             )
                       SELECT XX_INV_ERROR_LOG_S.nextval        ,
                              p_error_rec.rms_process_id        ,
                              p_error_rec.process_name          ,
                              p_error_rec.key_value_1           ,
                              p_error_rec.key_value_2           ,
                              p_error_rec.key_value_3           ,
                              p_error_rec.key_value_4           ,
                              p_error_rec.key_value_5           ,
                              p_error_rec.error_message         ,
                              'N'                               ,
                              p_error_rec.user_id               ,
                              SYSDATE                           ,
                              p_error_rec.user_id               ,
                              SYSDATE
                         FROM dual ;

  --
  p_error_rec.return_code := 0;
  --
EXCEPTION
 WHEN others THEN
  v_error_message := 'Error in Inserting Error in Error Log, '||SQLERRM;
  p_error_rec.return_code    := -1;
  p_error_rec.return_message := v_error_message ;
  FND_FILE.PUT_LINE(FND_FILE.LOG,v_error_message);
END insert_error;
--
END xx_inv_rms_int_process;
/
