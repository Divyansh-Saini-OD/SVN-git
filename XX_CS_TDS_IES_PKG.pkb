create or replace
PACKAGE BODY XX_CS_TDS_IES_PKG AS

gc_backup_count number := 0;
gc_user   varchar2(25) := 'CS_ADMIN';
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_TDS_IES_PKG                                        |
-- |                                                                   |
-- | Description: Wrapper package for scripting.                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       16-Jul-10   Raj Jagarlamudi  Initial draft version       |
-- |2.0       30-Nov-13   Raj J            Added CS_ADMIN USER         |
-- |3.0		  23-Jun-14   Pooja Mehra      Uncommented a block for     |
-- |									   as per  defect 30621        |
-- |4.0      22-JAN-2012  Vasu Raparla      Removed schema References  |
-- |                                        for R.12.2                 | 
-- +===================================================================+
/***************************************************************************
-- Log Messages
****************************************************************************/
PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XX_CRM'
     ,p_program_type            => 'Custom Messages'
     ,p_program_name            => 'XX_CS_TDS_IES_PKG'
     ,p_program_id              => null
     ,p_module_name             => 'IES'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_error_message_code
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MAJOR'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     );

END Log_Exception;
/*------------------------------------------------------------------------
  Procedure Name : Make_Param_Str
  Description    : concatenates parameters for XML message
--------------------------------------------------------------------------*/

FUNCTION Make_Param_Str(p_param_name IN VARCHAR2, 
                         p_param_value IN VARCHAR2) 
 RETURN VARCHAR2
 IS
 	BEGIN
   	RETURN '<Property NAME="'||p_param_name||
        	  '">'||'<![CDATA['||p_param_value||']]>'||'</Property>';

 END Make_Param_Str;
  /****************************************************************************************
 ****************************************************************************************/
  PROCEDURE GET_SKU_QUESTIONS (P_SCRIPT_ID        IN NUMBER,
                               P_SERVICE_ID       IN NUMBER,
                               P_SKU_CATEGORY     IN VARCHAR2,
                               P_QUE_TBL_TYPE     IN OUT NOCOPY XX_CS_IES_QUE_TBL_TYPE,
                               X_RETURN_CODE      IN OUT NOCOPY VARCHAR2,
                               X_RETURN_MESG      IN OUT NOCOPY VARCHAR2) AS
                           
  
  I               NUMBER := 0;
  J               NUMBER := 0;
  lc_backup_flag  VARCHAR2(1) := 'N';
  lc_parent_flag  VARCHAR2(1) := 'N';
  lc_sku          VARCHAR2(50);
  lc_message      VARCHAR2(2000);
  LR_ANS_TBL_TYPE XX_CS_IES_OPT_TBL_TYPE;
  
  CURSOR BACKUP_CUR IS
  select pp.panel_name, 
         pq.question_id, 
         pq.node_name,
         pq.question_label, 
         pt.question_type, 
         pq.lookup_id,
         pq.question_order
  from  ies_panels pp,
        ies_questions pq,
        ies_question_types pt
  where pt.question_type_id = pq.question_type_id
  and   pq.panel_id = pp.panel_id
  and   pq.active_status <> 0
  and   pp.panel_name = 'Backup'
  and   pp.dscript_id = p_script_id
  order by  pp.panel_id, pq.question_order;
  
  BACKUP_REC  BACKUP_CUR%ROWTYPE;
  
  CURSOR PARENT_CUR IS
  select distinct a.cross_reference sku
  from  mtl_system_items_b i,
        mtl_cross_references a
  where a.cross_reference_type='XX_GI_TDS_1'
  and i.inventory_item_id=a.inventory_item_id
  and i.organization_id=441
  and i.segment1 in ( select SKU from xx_cs_ies_sku_relations
                     where service_id = p_service_id
                     --and sku_category = p_sku_category
                     and sku_relation in ('P','F')
                     and parent_sku is null)
  union
  select distinct SKU from xx_cs_ies_sku_relations
  where service_id = p_service_id;
  --and sku_category = p_sku_category;
  
  PARENT_REC  PARENT_CUR%ROWTYPE;
  
  CURSOR DIR_CUR IS
  select distinct SKU from xx_cs_ies_sku_relations
  where service_id = p_service_id;
  --and sku_category = p_sku_category;
  
  DIR_REC   DIR_CUR%ROWTYPE;
  
  CURSOR SKU_CUR IS
  select pp.panel_name, 
         pq.question_id, 
         pq.node_name,
         pq.question_label, 
         pt.question_type, 
         pq.lookup_id,
         pq.question_order
  from  ies_panels pp,
        ies_questions pq,
        ies_question_types pt
  where pt.question_type_id = pq.question_type_id
  and   pq.panel_id = pp.panel_id
  and   pq.active_status <> 0
  and   pp.panel_label = lc_sku
  and   pp.dscript_id = p_script_id
  order by  pp.panel_id, pq.question_order;
                            
  SKU_REC  SKU_CUR%ROWTYPE;
                            
  Cursor ans_options (p_lookup_id in number) IS
  select answer_value
  from  ies_answers
  where lookup_id = p_lookup_id
  and  active_status <> 0
  order by answer_order ;
  
  BEGIN
  
     /*    LC_MESSAGE := 'in Get SKU script '||p_script_id||'  service '||p_service_id||' Category '||p_sku_category;
                 Log_Exception ( p_error_location     =>  'XX_CS_TDS_IES_PKG.GET_SKU_QUESTIONS'
                                ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                                ,p_error_msg          =>  LC_MESSAGE); */
                                   
         I := P_QUE_TBL_TYPE.COUNT + 1;
      
        BEGIN
            select 'Y' 
            into lc_backup_flag
            from ies_question_data qd,
                 ies_questions qa
            where qa.question_id = qd.question_id
            and   qd.transaction_id = p_service_id
            and   qa.node_name = 'Condition'
            and   qd.freeform_string = 'Existing';
        exception
          when others then
               lc_backup_flag := 'N';
        END;
        --
        IF lc_backup_flag = 'Y' then   
        -- Verify data backup skus.
            BEGIN
              select 'Y'
              into lc_backup_flag
              from fnd_lookup_values
              where lookup_type = 'XX_TDS_BACKUP_SKUS'
              and enabled_flag = 'Y'
              and exists (select 'X' from xx_cs_ies_sku_relations
                          where service_id = p_service_id
                          and sku_category = p_sku_category
                          and sku = fnd_lookup_values.lookup_code)
              and rownum < 2;
            EXCEPTION
              WHEN OTHERS THEN
                 lc_backup_flag := 'N';
            END;
        END IF;
        --
        IF lc_backup_flag = 'Y' 
           and gc_backup_count = 0 then
          begin
            open backup_cur;
            loop
            fetch backup_cur into backup_rec;
            exit when backup_cur%notfound;
            
            gc_backup_count := 1;
            
            p_que_tbl_type.extend;
            p_que_tbl_type(I) := XX_CS_IES_QUE_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
            
                BEGIN
                  p_que_tbl_type(i).que_id          := backup_rec.question_id;
                  p_que_tbl_type(i).que_code        := backup_rec.node_name;
                  p_que_tbl_type(i).que_type        := backup_rec.question_type;
                  p_que_tbl_type(i).que_category    := backup_rec.panel_name;
                  p_que_tbl_type(i).que_sort_order  := backup_rec.question_order;
                  p_que_tbl_type(i).que_text        := backup_rec.question_label;
                  p_que_tbl_type(i).que_isReq       := 'Y';
                  
                  -- Selected Value
                  begin
                      SELECT FREEFORM_STRING
                      INTO P_QUE_TBL_TYPE(I).QUE_TEXT_ANS
                      FROM IES_QUESTION_DATA
                      WHERE TRANSACTION_ID = P_SERVICE_ID
                      AND   QUESTION_ID = BACKUP_REC.QUESTION_ID;
                  exception
                      when others then
                         p_que_tbl_type(i).que_text_ans    := null;
                  end;
                
                /***************************************************************
                -- Possible Answers
                ****************************************************************/
                  BEGIN
                     J := 1;
                     LR_ANS_TBL_TYPE  := XX_CS_IES_OPT_TBL_TYPE();
                     FOR ans_options_rec IN ans_options(backup_rec.lookup_id)
                     LOOP
    
                      LR_ANS_TBL_TYPE.EXTEND;
                      LR_ANS_TBL_TYPE(J) := XX_CS_IES_OPT_REC_TYPE(NULL,NULL,NULL);
                      
                      LR_ANS_TBL_TYPE(J).QUESTION_ID  := BACKUP_REC.QUESTION_ID;
                      LR_ANS_TBL_TYPE(J).OPTIONS      := ANS_OPTIONS_REC.ANSWER_VALUE;
                      LR_ANS_TBL_TYPE(J).SELECTED_OPT := 'N';
                      
                      J := J + 1;
                     END LOOP;
                  END; -- Possible option population
                    p_que_tbl_type(i).que_ans_opt := lr_ans_tbl_type;
                   I := I + 1;
                END;
            end loop; 
            close backup_cur;
          end;
        else 
            J :=  1;
            LR_ANS_TBL_TYPE  := XX_CS_IES_OPT_TBL_TYPE();
        end If; -- backup flag
        
        -- Verification for parent skus
        BEGIN
          select 'Y'
          into lc_parent_flag
          from xx_cs_ies_sku_relations
          where service_id = p_service_id
          and sku_relation in ('P','F')
          and parent_sku is null
          and rownum < 2;
        exception
          when others then
              lc_parent_flag := 'N';
        end;
        
        IF LC_PARENT_FLAG = 'Y' THEN
          begin
            open parent_cur;
            loop
            fetch parent_cur into parent_rec;
            exit when parent_cur%notfound;
            
              lc_sku := parent_rec.sku;
                -- Category Panels.
                begin
                open sku_cur;
                loop
                fetch sku_cur into sku_rec;
                exit when sku_cur%notfound;
                    
                    p_que_tbl_type.extend;
                    p_que_tbl_type(I) := XX_CS_IES_QUE_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
                                                    
                      BEGIN
                        p_que_tbl_type(i).que_id          := sku_rec.question_id;
                        p_que_tbl_type(i).que_code        := sku_rec.node_name;
                        p_que_tbl_type(i).que_type        := sku_rec.question_type;
                        p_que_tbl_type(i).que_category    := sku_rec.panel_name;
                        p_que_tbl_type(i).que_sort_order  := sku_rec.question_order;
                        p_que_tbl_type(i).que_text        := sku_rec.question_label;
                        p_que_tbl_type(i).que_isReq       := 'Y';
                       
                       --uncommented below block as per defect 30621 
                        begin
                          select 'Y' , tag
                          into p_que_tbl_type(i).que_isReq,
                               p_que_tbl_type(i).que_Dependent_code
                          from cs_lookups
                          where lookup_type = 'XX_CS_TDS_REQ_FIELDS'
                          and meaning = sku_rec.node_name;
                        exception
                          when others then
                           p_que_tbl_type(i).que_isReq       := 'N';
                        end; 
                        
                          -- Selected Value
                          begin
                              SELECT FREEFORM_STRING
                              INTO P_QUE_TBL_TYPE(I).QUE_TEXT_ANS
                              FROM IES_QUESTION_DATA
                              WHERE TRANSACTION_ID = P_SERVICE_ID
                              AND   QUESTION_ID = SKU_REC.QUESTION_ID;
                          exception
                              when others then
                                 p_que_tbl_type(i).que_text_ans    := null;
                          end;
                          
                          --
                         
                        /***************************************************************
                        -- Possible Answers
                        ****************************************************************/
                        BEGIN
                          -- J := LR_ANS_TBL_TYPE.COUNT + 1;
                         --  LR_ANS_TBL_TYPE  := XX_CS_IES_OPT_TBL_TYPE();
                           FOR ans_options_rec IN ans_options(sku_rec.lookup_id)
                           LOOP
          
                            LR_ANS_TBL_TYPE.EXTEND;
                            LR_ANS_TBL_TYPE(J) := XX_CS_IES_OPT_REC_TYPE(NULL,NULL,NULL);
                            
                            LR_ANS_TBL_TYPE(J).QUESTION_ID  := SKU_REC.QUESTION_ID;
                            LR_ANS_TBL_TYPE(J).OPTIONS      := ANS_OPTIONS_REC.ANSWER_VALUE;
                            LR_ANS_TBL_TYPE(J).SELECTED_OPT := 'N';
                            
                            J := J + 1;
                           END LOOP;
                        END; -- Possible option population
                          p_que_tbl_type(i).que_ans_opt := lr_ans_tbl_type;
                        
                           I := I + 1;
                      END;
                end loop;
                close sku_cur;
                end;
            end loop;
            close parent_cur;
          end;
        ELSE
          begin
            open dir_cur;
            loop
            fetch dir_cur into dir_rec;
            exit when dir_cur%notfound;
                lc_sku := dir_rec.sku;
                -- Category Panels.
                begin
                open sku_cur;
                loop
                fetch sku_cur into sku_rec;
                exit when sku_cur%notfound;
                    
                    p_que_tbl_type.extend;
                    p_que_tbl_type(I) := XX_CS_IES_QUE_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
                                                    
                      BEGIN
                        p_que_tbl_type(i).que_id          := sku_rec.question_id;
                        p_que_tbl_type(i).que_code        := sku_rec.node_name;
                        p_que_tbl_type(i).que_type        := sku_rec.question_type;
                        p_que_tbl_type(i).que_category    := sku_rec.panel_name;
                        p_que_tbl_type(i).que_sort_order  := sku_rec.question_order;
                        p_que_tbl_type(i).que_text        := sku_rec.question_label;
                        p_que_tbl_type(i).que_isReq       := 'Y';
                        
                        begin
                          select 'Y' , tag
                          into p_que_tbl_type(i).que_isReq,
                               p_que_tbl_type(i).que_Dependent_code
                          from cs_lookups
                          where lookup_type = 'XX_CS_TDS_REQ_FIELDS'
                          and meaning = sku_rec.node_name;
                        exception
                          when others then
                           p_que_tbl_type(i).que_isReq       := 'N';
                        end; 
                        
                          -- Selected Value
                          begin
                              SELECT FREEFORM_STRING
                              INTO P_QUE_TBL_TYPE(I).QUE_TEXT_ANS
                              FROM IES_QUESTION_DATA
                              WHERE TRANSACTION_ID = P_SERVICE_ID
                              AND   QUESTION_ID = SKU_REC.QUESTION_ID;
                          exception
                              when others then
                                 p_que_tbl_type(i).que_text_ans    := null;
                          end;
                          
                          --
                         
                        /***************************************************************
                        -- Possible Answers
                        ****************************************************************/
                        BEGIN
                          -- J := LR_ANS_TBL_TYPE.COUNT + 1;
                         --  LR_ANS_TBL_TYPE  := XX_CS_IES_OPT_TBL_TYPE();
                           FOR ans_options_rec IN ans_options(sku_rec.lookup_id)
                           LOOP
          
                            LR_ANS_TBL_TYPE.EXTEND;
                            LR_ANS_TBL_TYPE(J) := XX_CS_IES_OPT_REC_TYPE(NULL,NULL,NULL);
                            
                            LR_ANS_TBL_TYPE(J).QUESTION_ID  := SKU_REC.QUESTION_ID;
                            LR_ANS_TBL_TYPE(J).OPTIONS      := ANS_OPTIONS_REC.ANSWER_VALUE;
                            LR_ANS_TBL_TYPE(J).SELECTED_OPT := 'N';
                            
                            J := J + 1;
                           END LOOP;
                        END; -- Possible option population
                          p_que_tbl_type(i).que_ans_opt := lr_ans_tbl_type;
                        
                           I := I + 1;
                      END;
                end loop;
                close sku_cur;
                end;
            end loop;
            close dir_cur;
          end;
        END IF; -- PARENT FLAG
  END GET_SKU_QUESTIONS;
 /****************************************************************************************
 ****************************************************************************************/
  PROCEDURE GET_QUESTIONS_EXT (P_SCRIPT_ID        IN NUMBER,
                               P_SERVICE_ID       IN NUMBER,
                               P_PANEL_CATEGORY   IN VARCHAR2,
                               P_QUE_TBL_TYPE     IN OUT NOCOPY XX_CS_IES_QUE_TBL_TYPE,
                               X_RETURN_CODE      IN OUT NOCOPY VARCHAR2,
                               X_RETURN_MESG      IN OUT NOCOPY VARCHAR2) AS
                           
  LN_SCRIPT_ID    NUMBER;
  I               NUMBER := 0;
  J               NUMBER := 0;
  LR_ANS_TBL_TYPE XX_CS_IES_OPT_TBL_TYPE;
  LC_CATEGORY     VARCHAR2(5);
  
  CURSOR C_CUR IS
  select distinct sku_category 
  from xx_cs_ies_sku_relations
  where service_id = p_service_id;
  
  C_REC   C_CUR%ROWTYPE;
  
  CURSOR CAT_CUR IS
  select pp.panel_name, 
         pq.question_id, 
         pq.node_name,
         pq.question_label, 
         pt.question_type, 
         pq.lookup_id,
         pq.question_order,
         pp.panel_label
  from  ies_panels pp,
        ies_questions pq,
        ies_question_types pt
  where pt.question_type_id = pq.question_type_id
  and   pq.panel_id = pp.panel_id
  and   pq.active_status <> 0
  and   pp.panel_label = lc_category
  and   pp.dscript_id = p_script_id
  order by  pp.panel_id, pq.question_order;
  
  CAT_REC CAT_CUR%ROWTYPE;
                            
  Cursor ans_options (p_lookup_id in number) IS
  select answer_value
  from  ies_answers
  where lookup_id = p_lookup_id
  and  active_status <> 0
  order by answer_order ;
  
  BEGIN
      IF p_panel_category = 'ALL' then
         I := P_QUE_TBL_TYPE.COUNT + 1;
      ELSE
         I                      := 1;
         P_QUE_TBL_TYPE         := XX_CS_IES_QUE_TBL_TYPE();
      END IF;
      
      BEGIN
      OPEN C_CUR;
      LOOP
      FETCH C_CUR INTO C_REC;
      EXIT WHEN C_CUR%NOTFOUND;
        lc_category := c_rec.sku_category;
        
        -- Category Panels.
        begin
        open cat_cur;
        loop
        fetch cat_cur into cat_rec;
        exit when cat_cur%notfound;
            lc_category := cat_rec.panel_label;
            
            p_que_tbl_type.extend;
            p_que_tbl_type(I) := XX_CS_IES_QUE_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
                                            
              BEGIN
                p_que_tbl_type(i).que_id          := cat_rec.question_id;
                p_que_tbl_type(i).que_code        := cat_rec.node_name;
                p_que_tbl_type(i).que_type        := cat_rec.question_type;
                p_que_tbl_type(i).que_category    := cat_rec.panel_name;
                p_que_tbl_type(i).que_sort_order  := cat_rec.question_order;
                p_que_tbl_type(i).que_text        := cat_rec.question_label;
                
                begin
                  select 'Y' , tag
                  into p_que_tbl_type(i).que_isReq,
                       p_que_tbl_type(i).que_Dependent_code
                  from cs_lookups
                  where lookup_type = 'XX_CS_TDS_REQ_FIELDS'
                  and meaning = cat_rec.node_name;
                exception
                  when others then
                   p_que_tbl_type(i).que_isReq       := 'N';
                end; 
                
                IF cat_rec.node_name not like 'Bullet%' then
                  -- Selected Value
                  begin
                      SELECT FREEFORM_STRING
                      INTO P_QUE_TBL_TYPE(I).QUE_TEXT_ANS
                      FROM IES_QUESTION_DATA
                      WHERE TRANSACTION_ID = P_SERVICE_ID
                      AND   QUESTION_ID = CAT_REC.QUESTION_ID;
                  exception
                      when others then
                         p_que_tbl_type(i).que_text_ans    := null;
                  end;
                else
                  p_que_tbl_type(i).que_text_ans    := null;
                end if;
                
                /***************************************************************
                -- Possible Answers
                ****************************************************************/
                BEGIN
                   J := 1;
                   LR_ANS_TBL_TYPE  := XX_CS_IES_OPT_TBL_TYPE();
                   FOR ans_options_rec IN ans_options(cat_rec.lookup_id)
                   LOOP
  
                    LR_ANS_TBL_TYPE.EXTEND;
                    LR_ANS_TBL_TYPE(J) := XX_CS_IES_OPT_REC_TYPE(NULL,NULL,NULL);
                    
                    LR_ANS_TBL_TYPE(J).QUESTION_ID  := CAT_REC.QUESTION_ID;
                    LR_ANS_TBL_TYPE(J).OPTIONS      := ANS_OPTIONS_REC.ANSWER_VALUE;
                    LR_ANS_TBL_TYPE(J).SELECTED_OPT := 'N';
                    
                    J := J + 1;
                   END LOOP;
                END; -- Possible option population
                  p_que_tbl_type(i).que_ans_opt := lr_ans_tbl_type;
                               
                   I := I + 1;
              END;
        end loop;
        close cat_cur;
        end;
        /****************************************************************
                  -- Get SKU questions
        ****************************************************************/
                   GET_SKU_QUESTIONS (P_SCRIPT_ID,
                                      P_SERVICE_ID,
                                      LC_CATEGORY,
                                      P_QUE_TBL_TYPE,
                                      X_RETURN_CODE,
                                      X_RETURN_MESG);
                                      
        END LOOP;
        CLOSE C_CUR;
    END;
  END GET_QUESTIONS_EXT;
/******************************************************************************************* 
*******************************************************************************************/ 

  PROCEDURE GET_QUESTIONS (P_SERVICE_TYPE     IN VARCHAR2,
                           P_SERVICE_ID       IN NUMBER,
                           P_PANEL_CATEGORY   IN VARCHAR2,
                           P_QUE_TBL_TYPE     IN OUT NOCOPY XX_CS_IES_QUE_TBL_TYPE,
                           X_WO_NUMBER        IN OUT NOCOPY VARCHAR2,
                           X_RETURN_CODE      IN OUT NOCOPY VARCHAR2,
                           X_RETURN_MESG      IN OUT NOCOPY VARCHAR2) AS
                           
  LN_SCRIPT_ID    NUMBER;
  I               NUMBER := 0;
  J               NUMBER := 0;
  LR_ANS_TBL_TYPE XX_CS_IES_OPT_TBL_TYPE;
  
  CURSOR QUE_CUR IS
  select pp.panel_name, 
         pq.question_id, 
         pq.node_name,
         pq.question_label, 
         pt.question_type, 
         pq.lookup_id,
         pq.question_order
  from  ies_panels pp,
        ies_questions pq,
        ies_question_types pt
  where pt.question_type_id = pq.question_type_id
  and   pq.panel_id = pp.panel_id
  and   pq.active_status <> 0
  and   pp.panel_name = 'Device'
  and   pp.dscript_id = ln_script_id
  order by  pp.panel_id, pq.question_order;
  
  QUE_REC QUE_CUR%ROWTYPE;
  
  Cursor ans_options (p_lookup_id in number) IS
  select answer_value
  from  ies_answers
  where lookup_id = p_lookup_id
  and  active_status <> 0
  order by answer_order ;
  
  BEGIN
      begin
        select dscript_id
        into ln_script_id 
        from ies_deployed_scripts
        where dscript_name like 'Tech Depot Services' -- p_service_type
        and f_deletedflag is null
        and rownum < 2
        order by object_version_number desc;
      exception
        when others then
            x_return_code := 'E';
            x_return_mesg := 'Error while selecting Script Id for this Type '||p_service_type;
      end;
      -- questions
         I                      := 1;
         P_QUE_TBL_TYPE         := XX_CS_IES_QUE_TBL_TYPE();
         
      IF p_panel_category = 'ALL' then
        begin
          select distinct request_number
          into x_wo_number
          from xx_cs_ies_sku_relations
          where service_id = p_service_id
          and rownum < 2;
        exception
          when others then
            begin
              select incident_number
              into x_wo_number
              from cs_incidents_all_b
              where tier = to_char(p_service_id);
            exception
              when others then
                 x_return_code := 'E';
                 x_return_mesg := 'error while getting WO number '||sqlerrm;
            end;
         end;
       end if;   
         
      IF p_panel_category <> 'Service' OR p_panel_category = 'ALL' then  
        begin
        open que_cur;
        loop
        fetch que_cur into que_rec;
        exit when que_cur%notfound;
        
            p_que_tbl_type.extend;
            p_que_tbl_type(I) := XX_CS_IES_QUE_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
                                            
              BEGIN
                p_que_tbl_type(i).que_id          := que_rec.question_id;
                p_que_tbl_type(i).que_code        := que_rec.node_name;
                p_que_tbl_type(i).que_type        := que_rec.question_type;
                
                IF que_rec.node_name = 'Alternate Phone Number' then
                  p_que_tbl_type(i).que_category    := 'Additional Information';
                else
                  p_que_tbl_type(i).que_category    := que_rec.panel_name;
                END IF;
                
                p_que_tbl_type(i).que_sort_order  := que_rec.question_order;
                p_que_tbl_type(i).que_text        := que_rec.question_label;
                
                begin
                  select 'Y' , tag
                  into p_que_tbl_type(i).que_isReq,
                       p_que_tbl_type(i).que_Dependent_code
                  from cs_lookups
                  where lookup_type = 'XX_CS_TDS_REQ_FIELDS'
                  and meaning = que_rec.node_name;
                exception
                  when others then
                   p_que_tbl_type(i).que_isReq       := 'N';
                end; 
                
                IF p_service_id is not null then
                  -- Selected Value
                  begin
                      SELECT FREEFORM_STRING
                      INTO P_QUE_TBL_TYPE(I).QUE_TEXT_ANS
                      FROM IES_QUESTION_DATA
                      WHERE TRANSACTION_ID = P_SERVICE_ID
                      AND   QUESTION_ID = QUE_REC.QUESTION_ID
                      AND   ROWNUM < 2;
                  exception
                      when others then
                         p_que_tbl_type(i).que_text_ans    := null;
                  end;
                else
                  p_que_tbl_type(i).que_text_ans    := null;
                end if;
                
                /***************************************************************
                -- Possible Answers
                ****************************************************************/
                BEGIN
                   J := 1;
                   LR_ANS_TBL_TYPE  := XX_CS_IES_OPT_TBL_TYPE();
                   FOR ans_options_rec IN ans_options(que_rec.lookup_id)
                   LOOP
  
                    LR_ANS_TBL_TYPE.EXTEND;
                    LR_ANS_TBL_TYPE(J) := XX_CS_IES_OPT_REC_TYPE(NULL,NULL,NULL);
                    
                    LR_ANS_TBL_TYPE(J).QUESTION_ID  := QUE_REC.QUESTION_ID;
                    LR_ANS_TBL_TYPE(J).OPTIONS      := ANS_OPTIONS_REC.ANSWER_VALUE;
                    LR_ANS_TBL_TYPE(J).SELECTED_OPT := 'N';
                    
                    J := J + 1;
                   END LOOP;
                END; -- Possible option population
                  p_que_tbl_type(i).que_ans_opt := lr_ans_tbl_type;
                   
                   I := I + 1;
              END;
     
        end loop;
        end;
      END IF;
  
      IF p_panel_category = 'Service' OR p_panel_category = 'ALL' then 
      
          GET_QUESTIONS_EXT (LN_SCRIPT_ID,
                             P_SERVICE_ID,
                             P_PANEL_CATEGORY,
                             P_QUE_TBL_TYPE,
                             X_RETURN_CODE,
                             X_RETURN_MESG);
      end IF;
      
  END GET_QUESTIONS;
  /**************************************************************************************
  ***************************************************************************************/
   
  PROCEDURE SUBMIT_ANSWERS_EXT (P_SERVICE_ID IN NUMBER,
                                P_TRAN_ID    IN NUMBER,
                                P_USER_ID    IN NUMBER,
                                X_RETURN_CODE IN OUT NOCOPY VARCHAR2,
                                X_RETURN_MESG IN OUT NOCOPY VARCHAR2)
  IS
  
  l_seq_nbr               number := 1;
  l_deleted_status        number := 0;
  nullval                 number;
  l_panel_data_id         number;       
 
cursor panel_cur is 
select distinct ip.panel_id
from ies_panels ip, 
     ies_questions iq,
     ies_question_data qd
where qd.question_id = iq.question_id
and   iq.panel_id = ip.panel_id
and   ip.panel_name = 'Device'
and   qd.transaction_id = p_service_id;

panel_rec panel_cur%rowtype;

cursor que_cur is 
select qd.question_id, 
       qd.lookup_id, 
       qd.answer_id,
       qd.freeform_string,
       qd.freeform_long
from ies_panels ip, 
     ies_questions iq,
     ies_question_data qd
where qd.question_id = iq.question_id
and   iq.panel_id = ip.panel_id
and   ip.panel_name = 'Device'
and   qd.transaction_id = p_service_id
and   ip.panel_id = panel_rec.panel_id;

que_rec que_cur%rowtype;

  BEGIN
  
    x_return_code := 'S';
    
             begin
                  insert into xx_cs_ies_sku_relations
                  ( service_id, 
                    sku, 
                    sku_category, 
                    parent_sku,
                    sku_relation, 
                    creation_date,
                    created_by,
                    last_update_date,
                    last_updated_by,
                    status,
                    request_number)
                  select p_tran_id,
                         sku,
                         sku_category,
                         parent_sku,
                         sku_relation,
                          sysdate,
                          to_char(p_user_id),
                          sysdate,
                          to_char(p_user_id),
                          status,
                          request_number
                  from xx_cs_ies_sku_relations
                  where service_id = p_service_id ;
                  
                   commit;
             exception
               when others then
                  x_return_code := 'E';
                  x_return_mesg := 'Error while updating selected skus'; 
            END;
        IF p_service_id <> p_tran_id then   
       -- Panel Insert
        BEGIN
         OPEN PANEL_CUR;
         LOOP
         FETCH PANEL_CUR INTO PANEL_REC;
         EXIT WHEN PANEL_CUR%NOTFOUND;     
              
               select ies_panel_data_s.nextval  
               into l_panel_data_id from dual;
                BEGIN
                  INSERT INTO ies_panel_data( panel_data_id,
                                 created_by           ,
                                 creation_date        ,
                                 panel_id             ,
                                 transaction_id       ,
                                 elapsed_time         ,
                                 sequence_number      ,
                                 deleted_status       )
                  VALUES (l_panel_data_id,
                          p_user_id, SYSDATE, panel_rec.panel_id,
                          p_tran_id,nullval, l_seq_nbr,
                          l_deleted_status);
                  commit;
                EXCEPTION
                  WHEN OTHERS THEN
                     x_return_code := 'E';
                     x_return_mesg := 'Error while inserting service ans'; 
                END;
        
               -- Insert Questions Data
               begin
                 open que_cur;
                 loop
                 fetch que_cur into que_rec;
                 exit when que_cur%notfound;
                    begin
                      INSERT INTO ies_question_data( question_data_id,
                                          created_by           ,
                                          creation_date        ,
                                          transaction_id       ,
                                          question_id          ,
                                          lookup_id            ,
                                          answer_id            ,
                                          freeform_string      ,
                                          freeform_long        ,
                                          panel_data_id)
                                  values(ies_question_data_s.nextval,
                                          p_user_id, sysdate,p_tran_id, 
                                          que_rec.question_id, 
                                          que_rec.lookup_id, 
                                          que_rec.answer_id, 
                                          que_rec.freeform_string, 
                                          que_rec.freeform_long,
                                          l_panel_data_id);
                          commit;
                      exception
                         when others then
                           x_return_code := 'E';
                           x_return_mesg := 'Error while inserting service answer values'; 
                      END;
                  end loop;
                  close que_cur;
                  END;
         END LOOP;
         CLOSE PANEL_CUR;
        END;
    END IF;
    
END SUBMIT_ANSWERS_EXT;
/***************************************************************************/
  
  PROCEDURE SUBMIT_ANSWERS (P_SERVICE_TYPE     IN VARCHAR2, 
                            P_MODIFY_FLAG      IN VARCHAR2,
                            P_PANEL_CATEGORY   IN VARCHAR2,
                            P_ANS_TBL_TYPE     IN XX_CS_IES_ANS_TBL_TYPE,
                            P_SERVICE_ID       IN OUT NOCOPY NUMBER, 
                            X_SKUKEY           IN OUT NOCOPY VARCHAR2,
                            X_RETURN_CODE      IN OUT NOCOPY VARCHAR2,
                            X_RETURN_MESG      IN OUT NOCOPY VARCHAR2)
  IS
  l_que_index             NUMBER := 0;
  l_panel_id              number;
  l_seq_nbr               number := 1;
  l_deleted_status        number := 0;
  l_que_id                number;
  l_lookup_id             number;
  l_ans_value             varchar2(3000);
  l_ans_id                number;
  l_tran_id               number;
  l_script_id             number;
  l_user_id               number;
  l_initStr               CLOB;
  l_que_text              varchar2(250);
  l_que_panel_id         number; 
  l_condition_flag       varchar2(25);
  lc_update_flag         varchar2(25) := 'N';
  lc_message             varchar2(1000);
  lc_quote_number        varchar2(25);
  
  BEGIN
  
    x_return_code := 'S';
    
   /* LC_MESSAGE := 'Submit Answers for service Id '||p_service_id||' Category '||P_panel_category || ' Modify Flag :' ||P_modify_flag;
                 Log_Exception ( p_error_location     =>  'XX_CS_TDS_IES_PKG.SUBMIT_ANSWERS'
                                ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                                ,p_error_msg          =>  LC_MESSAGE);  */
    
    -- Selecting Panel information.
    
    BEGIN
      SELECT USER_ID INTO L_USER_ID 
      FROM FND_USER
      WHERE USER_NAME = GC_USER;
    EXCEPTION
      WHEN OTHERS THEN
        x_return_code := 'E';
        x_return_mesg := 'Error while selecting CS_ADMIN user, Please contact EBS_ADMIN';
        LC_MESSAGE := 'Error while selecting CS_ADMIN user '||sqlerrm;
                                 Log_Exception ( p_error_location     =>  'XX_CS_TDS_IES_PKG.SUBMIT_ANSWERS'
                                                ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                                ,p_error_msg          =>  LC_MESSAGE);
    END;
    
    IF P_panel_category <> 'Service' then
      begin
          select panel_id, dscript_id
          into l_panel_id,l_script_id
          from ies_panels
          where panel_name = p_panel_category
          and   dscript_id = (select dscript_id
                              from ies_deployed_scripts
                              where dscript_name like 'Tech Depot Services' -- p_service_type
                              and f_deletedflag is null);
      exception
          when others then
              x_return_code := 'E';
              x_return_mesg := 'Error selecting panel id';
               LC_MESSAGE := 'error while selecting panel id '||l_que_id||'  service '||p_service_id||' '||sqlerrm;
                                 Log_Exception ( p_error_location     =>  'XX_CS_TDS_IES_PKG.SUBMIT_ANSWERS'
                                                ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                                ,p_error_msg          =>  LC_MESSAGE);
      end;
    end if;
    
  IF nvl(x_return_code,'S') = 'S' then 
     -- Generate Transaction (Service Id)
     IF p_service_id is null then
        begin
           l_tran_id := ies_transaction_util_pkg.insert_transaction(l_user_id,l_script_id);
        end;
     ELSIF P_MODIFY_FLAG = 'Y' THEN
        begin
           l_tran_id := ies_transaction_util_pkg.insert_transaction(l_user_id,l_script_id);
        end;
     ELSE
           l_tran_id      := p_service_id;
          IF NVL(p_panel_category,'X') <> 'Service' then
           lc_update_flag := 'Y';
          end if;
     END IF; 
     
          IF NVL(p_panel_category,'X') <> 'Service' then
         
           l_initStr := '<?xml version = "1.0"?>';
           l_initStr := l_initStr||'<IESPanelData InteractionId="'||l_tran_id||'" AgentId="'||l_user_id||'" >';
           l_initStr := l_initStr||'<PanelData>';                             
           l_initStr  :=  l_initStr||Make_Param_Str
                                        ('PanelId',l_panel_id);
           l_initStr  :=  l_initStr||Make_Param_Str
                                        ('SequenceNumber',l_seq_nbr);
           l_initStr  :=  l_initStr||Make_Param_Str
                                        ('DeletedStatus', l_deleted_status);
         
            l_initStr := l_initStr||'<IESQuestionData>';
            
         end if;
            
              l_que_index := p_ans_tbl_type.FIRST;
              WHILE l_que_index IS NOT NULL LOOP
                  
                  l_que_id    := p_ans_tbl_type(l_que_index).question_id;
                  l_ans_value := p_ans_tbl_type(l_que_index).ans_text;
                 
                  begin
                    select lookup_id, node_name, panel_id
                    into   l_lookup_id, l_que_text, l_que_panel_id
                    from ies_questions
                    where question_id = l_que_id;
                  exception
                     when others then
                          x_return_code := 'E';
                          x_return_mesg := 'Error selecting lookup value';
                  end;
                  
                  IF l_que_text = 'Condition' then        
                      IF l_ans_value = 'New' then
                          x_skukey := 'TN';
                      else
                          x_skukey := 'TU';
                          l_condition_flag := l_ans_value;
                      end if;
                  end if;
                  IF l_que_text = 'Description' 
                     and nvl(l_condition_flag,'N') = 'Existing'
                           and l_ans_value is null then
                           x_return_code := 'E';
                           x_return_mesg := 'Physical condition is required';
                  END IF;
                  
                  -- Add for direct quotation -- Raj 2/15/12
                  IF l_que_text = 'QuoteNumber' 
                     and l_ans_value is not null then 
                      BEGIN
                       SELECT QUOTE_NUMBER
                        INTO LC_QUOTE_NUMBER
                        FROM XX_CS_TDS_PARTS_QUOTES
                        WHERE QUOTE_NUMBER = L_ANS_VALUE
                        AND ROWNUM < 2;
                       EXCEPTION 
                         WHEN OTHERS THEN
                           x_return_code := 'E';
                           x_return_mesg := 'Entered Quotation is not valid, please enter valid quotation or create quote again from Hotlist';
                       END;
                   END IF;
                   
                  IF L_ANS_VALUE IS NOT NULL THEN    
                     IF p_panel_category = 'Service' then
                       l_initStr := '<?xml version = "1.0"?>';
                       l_initStr := l_initStr||'<IESPanelData InteractionId="'||l_tran_id||'" AgentId="'||l_user_id||'" >';
                       l_initStr := l_initStr||'<PanelData>';                             
                       l_initStr  :=  l_initStr||Make_Param_Str
                                                    ('PanelId',l_que_panel_id);
                       l_initStr  :=  l_initStr||Make_Param_Str
                                                    ('SequenceNumber',l_seq_nbr);
                       l_initStr  :=  l_initStr||Make_Param_Str
                                                    ('DeletedStatus', l_deleted_status);
                        l_initStr := l_initStr||'<IESQuestionData>';
                     end if;
                     
                     IF LC_UPDATE_FLAG = 'Y' THEN
                       -- get answer id
                       BEGIN 
                         select answer_id
                         into l_ans_id
                          from  ies_answers
                          where lookup_id = l_lookup_id
                          and   answer_value = l_ans_value;
                       exception
                         when others then
                            l_ans_id := null;
                       end;
                      -- Update modified option                           
                          begin
                            update ies_question_data
                            set answer_id = l_ans_id,
                                freeform_string = l_ans_value
                            where question_id = l_que_id
                            and   transaction_id = l_tran_id;
                          exception
                             when others then
                                 LC_MESSAGE := 'error while update the questions '||l_que_id||'  service '||p_service_id||' '||sqlerrm;
                                 Log_Exception ( p_error_location     =>  'XX_CS_TDS_IES_PKG.SUBMIT_ANSWERS'
                                                ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                                ,p_error_msg          =>  LC_MESSAGE);
                          end;   
                          
                          commit;
                    
                     ELSE
                     
                      l_initStr := l_initStr||'<QuestionData>'; 
                      l_initStr  :=  l_initStr||Make_Param_Str
                                                ('QuestionId',l_que_id);
                      l_initStr  :=  l_initStr||Make_Param_Str
                                                ('LookupId',l_lookup_id);
                      l_initStr  :=  l_initStr||Make_Param_Str
                                                ('Value', l_ans_value);
                      l_initStr  :=  l_initStr||Make_Param_Str
                                                ('DisplayValue', l_ans_value);
                                                
                      l_initStr := l_initStr||'</QuestionData>'; 
                     
                      IF p_panel_category = 'Service' then
                          l_initStr := l_initStr||'</IESQuestionData>';
                          l_initStr := l_initStr||'</PanelData>';
                          l_initStr := l_initStr||'</IESPanelData>';  
                          begin
                              ies_new_end_of_script_pkg.saveEndOfScriptData (p_element => l_initStr );
                           exception
                             when others then
                                x_return_mesg := 'Error '||sqlerrm;
                           end;  
                        
                      end if;
                      
                     END IF;  -- Update Flag
                  end IF; -- Ans Value
                     
                      l_que_index := p_ans_tbl_type.NEXT(l_que_index);
              END LOOP;
          IF nvl(x_return_code,'S') = 'S' then   
            IF p_panel_category <> 'Service' then 
               l_initStr := l_initStr||'</IESQuestionData>';
               l_initStr := l_initStr||'</PanelData>';
               l_initStr := l_initStr||'</IESPanelData>';
               
              IF p_service_id is null OR p_service_id <> l_tran_id then 
               begin
                  ies_new_end_of_script_pkg.saveEndOfScriptData (p_element => l_initStr );
               exception
                 when others then
                    x_return_mesg := 'Error '||sqlerrm;
               end;
              end if;
          end if;
         
             IF p_modify_flag = 'Y' and p_service_id is not null then
                SUBMIT_ANSWERS_EXT (P_SERVICE_ID,
                                    L_TRAN_ID, 
                                    L_USER_ID,
                                    X_RETURN_CODE,
                                    X_RETURN_MESG);
             end if;
             
         p_service_id := l_tran_id;
         
         IF LC_QUOTE_NUMBER IS NOT NULL THEN
           BEGIN
             UPDATE XX_CS_TDS_PARTS_QUOTES
             SET SCRIPT_ID = L_TRAN_ID
             WHERE QUOTE_NUMBER = LC_QUOTE_NUMBER;
             
             COMMIT;
           END;
         END IF;  -- QUOTE_NUMBER
        
         END IF;

  END IF;
 
END SUBMIT_ANSWERS;
/***************************************************************************/
  PROCEDURE SUBMIT_SKUS (P_SERVICE_TYPE        IN VARCHAR2, 
                         P_SERVICE_ID          IN NUMBER,
                         P_EMAIL_ID            IN VARCHAR2,
                         P_LOC_ID              IN VARCHAR2,
                         P_SKU_TBL_TYPE        IN XX_CS_TDS_SKU_TBL,
                         X_RETURN_CODE         IN OUT NOCOPY VARCHAR2,
                         X_RETURN_MESG         IN OUT NOCOPY VARCHAR2)
  IS
  l_que_index             NUMBER := 0;
  l_exit_flag             varchar2(1) := 'N';
  l_script_id             number;
  l_user_id               number;
  l_initStr               CLOB;
  l_que_text              varchar2(250);
  l_msg_data              varchar2(1000);
  lc_wo_number            varchar2(100);
  lc_so_number            varchar2(100);
  ln_sub_count            number;
  lc_quote_flag           varchar2(1) := 'N';
  lc_quote_number         varchar2(50);
  ln_sku_count            number := 0;
  
BEGIN
  
    x_return_code := 'S';
    
    BEGIN
      SELECT USER_ID INTO L_USER_ID 
      FROM FND_USER
      WHERE USER_NAME = GC_USER;
    EXCEPTION
      WHEN OTHERS THEN
        x_return_code := 'E';
        x_return_mesg := 'Error while selecting CS_ADMIN user, Please contact EBS_ADMIN';
    END;
    
    IF P_service_type = 'T' THEN  -- (1)
       begin
          delete from xx_cs_ies_sku_relations
          where service_id = p_service_id;   
          commit;
      exception
         when others then
            x_return_code := 'E';
            x_return_mesg := 'Error while removing previously selected skus';
            l_msg_data := 'Error while removing skus '||sqlerrm;
     
              Log_Exception ( p_error_location     =>  'XX_CS_TDS_IES_PKG.SUBMIT_SKUs'
                             ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                             ,p_error_msg          =>  l_msg_data);
      end;
          
      BEGIN
          l_que_index := p_sku_tbl_type.FIRST;
          WHILE l_que_index IS NOT NULL LOOP
          
             ln_sku_count := ln_sku_count + 1;
             
          --Raj commented out on 2/15/12
          -- Subscription mail verification
     /*     IF p_sku_tbl_type(l_que_index).sku_category = 'S' then
            ln_sub_count := ln_sub_count + 1;
            begin
                select incident_number, incident_attribute_1, 'Y'
                into   lc_wo_number,lc_so_number, l_exit_flag
                from cs_incidents_all_b cb,
                     cs_incident_types_tl ct
                where ct.incident_type_id = cb.incident_type_id
                and   ct.name like 'TDS%'
                and   cb.incident_status_id <> 2
                and   (external_attribute_3 like '%S%'
                        OR external_attribute_3 like 'S')
                and   lower(cb.incident_attribute_8) = lower(p_email_id)
                and   rownum < 2;
            exception
              when no_data_found then
                  null; 
              when others then
                   x_return_code := 'E';
                   x_return_mesg := 'Error while verifying email address '||Sqlerrm;
            end;
          end if; */
          
           IF p_sku_tbl_type(l_que_index).sku_category = 'A' then
              BEGIN
                 select 'Y'
                  into lc_quote_flag 
                  from cs_lookups
                  where lookup_type = 'XX_TDS_PARTS_ITEM'
                  and lookup_code = p_sku_tbl_type(l_que_index).sku_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    lc_quote_flag := 'N';
                END;
                
                -- find out the quote
                IF nvl(lc_quote_flag,'N') = 'Y' then
                     BEGIN
                       SELECT REQUEST_NUMBER
                        INTO LC_WO_NUMBER
                        FROM XX_CS_TDS_PARTS_QUOTES
                        WHERE SCRIPT_ID = P_SERVICE_ID
                        AND ROWNUM < 2;
                       EXCEPTION 
                         WHEN OTHERS THEN
                           LC_WO_NUMBER := NULL;
                       END;
                end if;  -- QUOTE FLAG
            END IF;
            
          
              begin
                  insert into xx_cs_ies_sku_relations
                  ( service_id, 
                    sku, 
                    sku_category, 
                    parent_sku,
                    sku_relation, 
                    creation_date,
                    created_by,
                    last_update_date,
                    last_updated_by,
                    status, 
                    request_number)
                  values(p_service_id,
                         p_sku_tbl_type(l_que_index).sku_id,
                         p_sku_tbl_type(l_que_index).sku_category,
                         p_sku_tbl_type(l_que_index).parent_sku,
                          p_sku_tbl_type(l_que_index).sku_relations,
                          sysdate,
                          to_char(l_user_id),
                          sysdate,
                          to_char(l_user_id),
                          'NS',
                          lc_wo_number);
                l_que_index := p_sku_tbl_type.NEXT(l_que_index);
            END;
          END LOOP;
          
          -- Updating entire order if Parts sku available and quote created. 
          IF ln_sku_count > 1 then
            IF LC_WO_NUMBER IS NOT NULL THEN    
              begin
                 update xx_cs_ies_sku_relations
                 set request_number = lc_wo_number
                 where service_id = p_service_id;
                 
                 commit;
              exception
                  when others then
                     x_return_code := 'E';
                     x_return_mesg := 'Error while updating Request number '||Sqlerrm;
              end;
            END IF;  -- work order
          END if; -- sku count
          -- Raj -- Commented out on 2/15/12
          /*
          IF L_EXIT_FLAG = 'N' then
             begin
                select 'Y'
                into l_exit_flag
                from xx_cs_tds_subscriptions
                where lower(sub_email_id) = lower(p_email_id);
             exception
              when others then
                  l_exit_flag := 'N';
             end;
          end if;
      
          IF L_EXIT_FLAG = 'Y' THEN
             x_return_code := 'E';
             x_return_mesg := 'Subscription service exists with this email '||p_email_id||' for Order: '||lc_so_number||' WO# '||lc_wo_number;
             ROLLBACK;
          else
           IF LN_SUB_COUNT > 1 THEN 
              x_return_code := 'E';
              x_return_mesg := 'Multiple Subscriptions are not allowed with this email '||p_email_id||' for Order: '||lc_so_number||' WO# '||lc_wo_number;
              ROLLBACK;
            ELSE
              commit;
            END IF;
          END IF;
          */
       exception
        when others then
          x_return_code := 'E';
          x_return_mesg := 'Error '||Sqlerrm;
      END;
    ELSE
       
       BEGIN
          SELECT REQUEST_NUMBER
          INTO LC_WO_NUMBER
          FROM XX_CS_TDS_PARTS_QUOTES
          WHERE SCRIPT_ID = P_SERVICE_ID
          AND REQUEST_NUMBER IS NOT NULL
          AND ROWNUM < 2;
       EXCEPTION
          WHEN OTHERS THEN
             LC_WO_NUMBER := NULL;
        END;
        
        IF LC_WO_NUMBER IS NULL THEN  --(2)
          begin
             select LPAD(P_LOC_ID,5,0)||XX_CS_TDS_REQ_NO_S.NEXTVAL 
             INTO lc_wo_number 
             from dual;
            exception
              when others then
                x_return_code := 'E';
                x_return_mesg := 'Error while generating WO number '||Sqlerrm;
            end;
          IF LC_WO_NUMBER IS NOT NULL THEN   -- (3) 
            begin
               update xx_cs_ies_sku_relations
               set request_number = lc_wo_number
               where service_id = p_service_id;
               
               commit;
            exception
                when others then
                   x_return_code := 'E';
                   x_return_mesg := 'Error while updating Request number '||Sqlerrm;
            end;
          END IF;  -- (3)
        END IF;  -- (2)
    END IF;  -- (1)
    
END SUBMIT_SKUS;
/***************************************************************************/
PROCEDURE GET_SUBMITED_SKUS (P_SERVICE_TYPE        IN VARCHAR2, 
                             P_SERVICE_ID          IN NUMBER,
                             P_SKU_TBL_TYPE        IN OUT NOCOPY XX_CS_TDS_SKU_TBL,
                             X_RETURN_CODE         IN OUT NOCOPY VARCHAR2,
                             X_RETURN_MESG         IN OUT NOCOPY VARCHAR2)
  IS
  
  l_exit_flag             varchar2(1) := 'N';
  l_script_id             number;
  l_user_id               number;
  l_initStr               CLOB;
  l_que_text              varchar2(250);
  
CURSOR SKU_CUR IS
SELECT SKU, SKU_CATEGORY, PARENT_SKU, SKU_RELATION, STATUS 
FROM XX_CS_IES_SKU_RELATIONS   
WHERE SERVICE_ID = P_SERVICE_ID;

SKU_REC   SKU_CUR%ROWTYPE;
I         NUMBER;

BEGIN
  
       x_return_code := 'S';
       I                      := 1;
       P_SKU_TBL_TYPE         := XX_CS_TDS_SKU_TBL();
      BEGIN
        OPEN SKU_CUR;
        LOOP
        FETCH SKU_CUR INTO SKU_REC;
        EXIT WHEN SKU_CUR%NOTFOUND;
        
          p_sku_tbl_type.extend;
          p_sku_tbl_type(I) := XX_CS_TDS_SKU_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL);
        
          p_sku_tbl_type(i).sku_id := sku_rec.sku;
          p_sku_tbl_type(i).sku_category := sku_rec.sku_category;
          p_sku_tbl_type(i).parent_sku := sku_rec.parent_sku;
          p_sku_tbl_type(i).sku_relations := sku_rec.sku_relation;
          p_sku_tbl_type(i).attribute1 := sku_rec.status;
           
          I := I + 1;
          
        END LOOP;
        CLOSE SKU_CUR;
         
      EXCEPTION
       WHEN OTHERS THEN
          x_return_code := 'E';
          x_return_mesg := 'Error '||Sqlerrm;
      END;
        
END GET_SUBMITED_SKUS;
/***************************************************************************/
PROCEDURE GET_ANSWER_OPTIONS (P_ANS_OPTION    IN VARCHAR2,
                              P_QUE_ID        IN NUMBER,
                              P_ANS_OPTIONS   IN OUT NOCOPY XX_CS_IES_OPT_TBL_TYPE,
                              X_RETURN_CODE   IN OUT NOCOPY VARCHAR2,
                              X_RETURN_MESG   IN OUT NOCOPY VARCHAR2)
IS
I                 NUMBER := 0;
LR_ANS_OPT_TYPE   XX_CS_IES_OPT_TBL_TYPE;

CURSOR C1 IS
  select Meaning
  from cs_lookups
  where lookup_type = 'XX_CS_TDS_ANS_RELATIONS'
  and description = P_ANS_OPTION;
  
C1_REC  C1%ROWTYPE;

BEGIN
  BEGIN
      OPEN C1;
      I := 1;
      LR_ANS_OPT_TYPE  := XX_CS_IES_OPT_TBL_TYPE();
      LOOP
      FETCH C1 INTO C1_REC;
      EXIT WHEN C1%NOTFOUND;
     
          LR_ANS_OPT_TYPE.EXTEND;
          LR_ANS_OPT_TYPE(I) := XX_CS_IES_OPT_REC_TYPE(NULL,NULL,NULL);
                      
          LR_ANS_OPT_TYPE(I).QUESTION_ID  := P_QUE_ID;
          LR_ANS_OPT_TYPE(I).OPTIONS      := C1_REC.MEANING;
          LR_ANS_OPT_TYPE(I).SELECTED_OPT := 'N';
                      
          I := I + 1;
                 
      END LOOP;
      CLOSE C1;
      
          LR_ANS_OPT_TYPE.EXTEND;
          LR_ANS_OPT_TYPE(I) := XX_CS_IES_OPT_REC_TYPE(NULL,NULL,NULL);
          
          LR_ANS_OPT_TYPE(I).QUESTION_ID  := P_QUE_ID;
          LR_ANS_OPT_TYPE(I).OPTIONS      := 'Other';
          LR_ANS_OPT_TYPE(I).SELECTED_OPT := 'N'; 
          
          p_ans_options := LR_ANS_OPT_TYPE;
          
      x_return_code := 'S';
    EXCEPTION
      WHEN OTHERS THEN
        X_RETURN_CODE := 'E';
        X_RETURN_MESG := 'Error while selecting dependent options '||sqlerrm;
  END;

END GET_ANSWER_OPTIONS;
/****************************************************************************
*****************************************************************************/

END XX_CS_TDS_IES_PKG;
/
show errors;
exit;