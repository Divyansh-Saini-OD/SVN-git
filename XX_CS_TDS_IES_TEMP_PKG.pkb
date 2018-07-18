create or replace
PACKAGE BODY XX_CS_TDS_IES_TEMP_PKG AS

gc_backup_count number := 0;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_TDS_IES_TEMP_PKG                                   |
-- |                                                                   |
-- | Description: Wrapper package for scripting.                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       08-Mar-12   Raj Jagarlamudi  Initial draft version       |
-- |2.0       22-JAN-2012  Vasu Raparla      Removed schema References |
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
     ,p_program_name            => 'XX_CS_TDS_IES_TEMP_PKG'
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
/*--------------------------------------------------------------------------
-- Customer Service SRs extract 
****************************************************************************/
PROCEDURE CREATE_SR
AS

  L_SR_REQ_REC      XX_CS_SR_REC_TYPE;
  L_ECOM_SITE_KEY   XX_GLB_SITEKEY_REC_TYPE;
  L_REQUEST_ID      NUMBER;
  L_REQUEST_NUM     NUMBER;
  X_RETURN_STATUS   VARCHAR2(200);
  X_MSG_DATA        VARCHAR2(200);
  L_ORDER_TBL       XX_CS_SR_ORDER_TBL;
  l_order_rec       XX_CS_SR_ORDER_REC_TYPE;
  I                 BINARY_INTEGER;
  TYPE ORDCurTyp    IS REF CURSOR;
  ord_cur           ORDCurTyp;
  TYPE NTSCURTYP    IS REF CURSOR;
  nts_cur           NTSCURTYP;
  stmt_str_ord      VARCHAR2(2000);
  stmt_str_nts      VARCHAR2(2000);
  lc_order_table    VARCHAR2(200);
  lv_db_link        VARCHAR2(100) := fnd_profile.value('XX_CS_STANDBY_DBLINK');

BEGIN


  L_REQUEST_ID := NULL;
  L_REQUEST_NUM := NULL;
  X_RETURN_STATUS := NULL;
  X_MSG_DATA := NULL;
  I := 1;
  L_ORDER_TBL := XX_CS_SR_ORDER_TBL();
  l_order_rec := XX_CS_SR_ORDER_REC_TYPE(null,null,null,null,null,null,null,null,null,null,null,null);


  l_sr_req_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,null,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,null,null,null);

    lc_order_table := 'CS_INCIDENTS_ALL_B@'||lv_db_link;

      dbms_output.put_line('table '||lc_order_table);

      /* This query will extract all customer service requests */
      stmt_str_ord := 'SELECT incident_number,incident_type_id, problem_code, problem_description,incident_attribute_1,
                              incident_attribute_5, incident_attribute_9, incident_attribute_14,
                              Incident_attribute_15, Incident_attribute_8,incident_attribute_11 ,
                              to_date(incident_attribute_2, ''mm/dd/yy''),Incident_attribute_4,incident_attribute_7,
                              incident_attribute_13, error_code
                        FROM '||LC_ORDER_TABLE||'
                        WHERE PROBLEM_CODE <> ''TDS-SERVICES''
                        AND CREATION_DATE > SYSDATE - 1
                        AND INCIDENT_ID NOT IN (SELECT A.INCIDENT_ID FROM CS_INCIDENTS_ALL_B A
                                                WHERE A.CREATION_DATE > SYSDATE - 1) ';



     BEGIN
      OPEN ord_cur FOR stmt_str_ord;
        LOOP
          FETCH ord_cur INTO l_sr_req_rec.comments,l_sr_req_rec.type_id, l_sr_req_rec.problem_code, l_sr_req_rec.description,
                            l_sr_req_rec.order_number, l_sr_req_rec.contact_name,l_sr_req_rec.customer_id ,
                            l_sr_req_rec.contact_phone,l_sr_req_rec.sales_rep_contact_name,l_sr_req_rec.contact_email,
                            l_sr_req_rec.warehouse_id,l_sr_req_rec.ship_date,l_sr_req_rec.sales_rep_contact,
                            l_sr_req_rec.preferred_contact,l_sr_req_rec.contact_fax, L_sr_req_rec.user_id;
            EXIT WHEN ord_cur%NOTFOUND;

          l_sr_req_rec.ship_to            := '00001';
          l_sr_req_rec.zz_flag            := 'No';
          l_sr_req_rec.comments           := 'Ref :- '||l_sr_req_rec.comments;
          l_sr_req_rec.channel            := 'Phone';


                XX_CS_SERVICEREQUEST_PKG.CREATE_SERVICEREQUEST(
                  P_SR_REQ_REC => L_SR_REQ_REC,
                  P_ECOM_SITE_KEY => L_ECOM_SITE_KEY,
                  P_REQUEST_ID => L_REQUEST_ID,
                  P_REQUEST_NUM => L_REQUEST_NUM,
                  X_RETURN_STATUS => X_RETURN_STATUS,
                  X_MSG_DATA => X_MSG_DATA,
                  P_ORDER_TBL => L_ORDER_TBL
                );

                DBMS_OUTPUT.PUT_LINE('L_REQUEST_NUM = ' || L_REQUEST_NUM);
                DBMS_OUTPUT.PUT_LINE('status '||x_return_status||' '||X_MSG_DATA);
               
        END LOOP;
      CLOSE ord_cur;
       commit;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('NO DATA FOUND '||SQLERRM);
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED :: '||SQLERRM);
  END;

END CREATE_SR;

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

  /**************************************************************************************
  ***************************************************************************************/
   
 PROCEDURE SUBMIT_ANSWERS_EXT (P_SERVICE_ID IN NUMBER,
                                P_USER_ID IN NUMBER,
                                X_RETURN_CODE IN OUT NOCOPY VARCHAR2,
                                X_RETURN_MESG IN OUT NOCOPY VARCHAR2)
  IS

  
  TYPE ORDCurTyp          IS REF CURSOR;
  ord_cur                 ORDCurTyp;
  TYPE NTSCURTYP          IS REF CURSOR;
  nts_cur                 NTSCURTYP;
  stmt_str_ord            VARCHAR2(2000);
  stmt_str_nts            VARCHAR2(2000);
  TYPE QUECurTyp          IS REF CURSOR;
  que_cur                 QUECurTyp;
  stmt_str_que            VARCHAR2(2000);
  l_panel_id              number;
  lc_panel_table           VARCHAR2(1000);
  lc_que_table             VARCHAR2(1000);
  lv_db_link               VARCHAR2(100) := fnd_profile.value('XX_CS_STANDBY_DBLINK');
  l_seq_nbr               number := 1;
  l_deleted_status        number := 0;
  nullval                 number;
  l_panel_data_id         number;
  ln_que_id                number;
  ln_lookup_id             number;
  ln_answer_id             number;
  lc_freeform_string       varchar2(250);
  lc_freeform_long         varchar2(1000);

  BEGIN

    x_return_code := 'S';

       -- Panel Insert

       BEGIN
          lc_panel_table := 'ies_panels@'||lv_db_link||' ip, ies_questions@'||lv_db_link||' iq,
                              ies_question_data@'||lv_db_link||' qd ';

--dbms_output.put_line('tables '||lc_panel_table);

          /* This query will extract all TDS ORDER sku relations */
          stmt_str_ord := 'select distinct ip.panel_id pan_id
                                from '||lc_panel_table ||
                            ' where qd.question_id = iq.question_id
                            and   iq.panel_id = ip.panel_id
                            and   qd.transaction_id = '||p_service_id ;
                
--dbms_output.put_line('st '||stmt_str_pan);
         BEGIN
          OPEN ord_cur FOR stmt_str_ord;
          LOOP
          FETCH ord_cur INTO l_panel_id;
            EXIT WHEN ord_cur%NOTFOUND;

--dbms_output.put_line('panel id '||l_panel_id||' '||p_service_id);

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
                          p_user_id, SYSDATE, l_panel_id,
                          p_service_id,nullval, l_seq_nbr,
                          l_deleted_status);
                  commit;
                EXCEPTION
                  WHEN OTHERS THEN
                     x_return_code := 'E';
                     x_return_mesg := 'Error while inserting service ans';
                END;

---dbms_output.put_line('panel id2 '||l_panel_id||' '||p_service_id);

              lc_que_table := 'ies_panels@'||lv_db_link||' ip, ies_questions@'||lv_db_link||' iq,
                              ies_question_data@'||lv_db_link||' qd ';

---dbms_output.put_line('table2 : '||lc_que_table );

          /* This query will extract all TDS ORDER sku relations */
          stmt_str_que := 'select qd.question_id,
                                   qd.lookup_id,
                                   qd.answer_id,
                                   qd.freeform_string,
                                   qd.freeform_long
                                from '||lc_que_table ||
                            ' where qd.question_id = iq.question_id
                              and   iq.panel_id = ip.panel_id
                              and   qd.transaction_id = '|| p_service_id||'
                               and   ip.panel_id = '||l_panel_id;
                               
               -- Insert Questions Data
               begin
                 open que_cur FOR stmt_str_que;
                 loop
                 fetch que_cur into ln_que_id, ln_lookup_id, ln_answer_id, lc_freeform_string, lc_freeform_long;
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
                                          p_user_id, sysdate,p_service_id, 
                                          ln_que_id, 
                                          ln_lookup_id, 
                                          ln_answer_id, 
                                          lc_freeform_string, 
                                          lc_freeform_long,
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
         CLOSE ORD_CUR;
        END;
      END;
END SUBMIT_ANSWERS_EXT;
/***************************************************************************/
  
  PROCEDURE SUBMIT_ANSWERS 
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
  l_user_id               number := 26176;
  l_initStr               CLOB;
  l_que_text              varchar2(250);
  l_que_panel_id         number; 
  l_condition_flag       varchar2(25);
  lc_update_flag         varchar2(25) := 'N';
  lc_message             varchar2(1000);
  lc_return_code         varchar2(1);
  lc_quote_number        varchar2(25);
  sqlstmt                VARCHAR2(2000);
  
  CURSOR C1 IS
  SELECT DISTINCT SERVICE_ID 
  FROM XX_CS_IES_SKU_RELATIONS
  WHERE SERVICE_ID NOT IN (SELECT TRANSACTION_ID 
                            FROM IES_TRANSACTIONS 
                              WHERE DSCRIPT_ID = L_SCRIPT_ID);
                              
  C1_REC C1%ROWTYPE;
  
  
  BEGIN

    
      begin
          select dscript_id
          into l_script_id
          from ies_deployed_scripts
          where dscript_name like 'Tech Depot Services' 
          and f_deletedflag is null;
      exception
          when others then
              lc_return_code := 'E';
              LC_MESSAGE := 'error while selecting script id'||sqlerrm;
                                 Log_Exception ( p_error_location     =>  'XX_CS_TDS_IES_PKG.SUBMIT_ANSWERS'
                                                ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                                ,p_error_msg          =>  LC_MESSAGE);
      end;
    
  IF nvl(lc_return_code,'S') = 'S' then 
  
    BEGIN
      OPEN C1;
      LOOP 
      FETCH C1 INTO C1_REC;
      EXIT WHEN C1%NOTFOUND;
      
       sqlstmt := 'insert into ies_transactions(transaction_id, created_by, creation_date, agent_id, dscript_id, start_time)
                         values(:1, :2, sysdate, :3, :4, sysdate)';
        execute immediate sqlstmt using c1_rec.service_id, l_user_id, l_user_id, l_script_id;
        
        
     
          SUBMIT_ANSWERS_EXT (P_SERVICE_ID => C1_REC.SERVICE_ID,
                               P_USER_ID => L_USER_ID,
                                X_RETURN_CODE => LC_RETURN_CODE ,
                                X_RETURN_MESG => LC_MESSAGE);
       end loop;
       close c1;
     END;
  END IF;
 
END SUBMIT_ANSWERS;
/****************************************************************************
*****************************************************************************/
PROCEDURE GET_SKUS_QUOTES  IS

/* Variable Declaration */
 TYPE ORDCurTyp          IS REF CURSOR;
  ord_cur                 ORDCurTyp;
  TYPE NTSCURTYP          IS REF CURSOR;
  nts_cur                 NTSCURTYP;
  stmt_str_ord            VARCHAR2(2000);
  stmt_str_nts            VARCHAR2(2000);
  lc_message              VARCHAR2(1000);
  ln_service_id            NUMBER;
  lc_sku                   VARCHAR2(50);
  lc_sku_category          VARCHAR2(25);
  lc_parent_sku            VARCHAR2(50);
  lc_sku_relation          VARCHAR2(50);
  lc_description           VARCHAR2(250);
  ln_quantity              NUMBER;
  lc_request_number        VARCHAR2(25);
  lc_status                VARCHAR2(50);
  lx_return_status         VARCHAR2(1);
  lc_order_table           VARCHAR2(200);
  ln_user_id               NUMBER;
  ln_count                 NUMBER := 0;
  lv_db_link               VARCHAR2(100) := fnd_profile.value('XX_CS_STANDBY_DBLINK');

BEGIN 
  
  dbms_output.put_line('beginging of API ');
  
  IF lv_db_link IS NULL THEN
    lx_return_status := 'F';
    dbms_output.put_line('Profile Option OD: Standby DB Link Name is not SET.'); 
  END IF;
  
  IF nvl(lx_return_status,'S') = 'S' then
  
    BEGIN
      SELECT user_id INTO ln_user_id FROM fnd_user
       WHERE user_name = 'CS_ADMIN';
    EXCEPTION
      WHEN OTHERS THEN
        lx_return_status := 'F';
        lc_message     := 'Error while selecting userid '||sqlerrm;
        DBMS_OUTPUT.PUT_LINE('eRROR SLECTING USERID '||SQLERRM);
     END;
  
      lc_order_table := 'xx_cs_ies_sku_relations@'||lv_db_link;
      
      --dbms_output.put_line('table '||lc_order_table);
      
      /* This query will extract all TDS ORDER sku relations */
      stmt_str_ord := 'SELECT SERVICE_ID, SKU, SKU_CATEGORY, 
                        PARENT_SKU, SKU_RELATION,QUANTITY, 
                        DESCRIPTION, STATUS, REQUEST_NUMBER
                        FROM '|| lc_order_table ||
                        ' WHERE CREATION_DATE > SYSDATE - 1
                           AND SERVICE_ID NOT IN (SELECT A.SERVICE_ID FROM XX_CS_IES_SKU_RELATIONS A
                                                    WHERE A.CREATION_DATE > SYSDATE - 1) ';
                           
      --dbms_output.put_line('stmt '||stmt_str_ord);
                   
     BEGIN
      OPEN ord_cur FOR stmt_str_ord; 
        LOOP
          FETCH ord_cur INTO ln_service_id, lc_sku,lc_sku_category,
                             lc_parent_sku, lc_sku_relation, ln_quantity,
                             lc_description, lc_status, lc_request_number; 
            EXIT WHEN ord_cur%NOTFOUND; 
            
              DBMS_OUTPUT.PUT_LINE ('Service Id and Request Number : '||ln_service_id||' - '||lc_request_number );
      
                begin
                      insert into xx_cs_ies_sku_relations
                      ( service_id, 
                        sku, 
                        sku_category, 
                        parent_sku,
                        sku_relation, 
                        quantity,
                        description,
                        creation_date,
                        created_by,
                        last_update_date,
                        last_updated_by,
                        status, 
                        request_number)
                      values(ln_service_id,
                             lc_sku,
                             lc_sku_category,
                             lc_parent_sku,
                             lc_sku_relation,
                             ln_quantity,
                             lc_description,
                              sysdate,
                              to_char(ln_user_id),
                              sysdate,
                              to_char(ln_user_id),
                              lc_status,
                              lc_request_number);
                END;
                ln_count := ln_count + 1;
                if ln_count = 200 then
                  commit;
                  ln_count := 0;
                end if;
                
        END LOOP; 
      CLOSE ord_cur; 
       commit;
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('NO DATA FOUND '||SQLERRM);
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED :: '||SQLERRM);
  END;
    
    SUBMIT_ANSWERS;
    
  END IF;
  
  
 END GET_SKUS_QUOTES;
/**************************************************************************************/
END XX_CS_TDS_IES_TEMP_PKG;
/
SHOW ERRORS;
EXIT;