create or replace
PACKAGE BODY "XX_CS_STANDBY_PKG" AS

 gc_backup_count  number := 0;
 gc_status        varchar2(25);
 gc_message       varchar2(1000);
 gn_user          number;
 gd_date          date;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_TDS_STANDBY_PKG                                    |
-- |                                                                   |
-- | Description: Wrapper package for scripting.                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       08-May-13   Raj Jagarlamudi  Initial draft version       |
-- |2.0       16-OCT-13   Arun Gannarapu   Modified for R12            |
-- |3.0       30-JAN-14   Arun Gannarapu   Modified to fix the debug issues
-- |4.0       04-FEB-14   Arun Gannarapu   Modified to add SR Update for CASE
-- /5.0       04-FEB-14   Arun Gannarapu   Modified the CREATE_SR cursor 
-- |6.0       04-APR-14   Arun Gannarapu   Modified to comment the contact ref in create TDS SR pkg 
-- |                                      and increased lc_freeform_string length to 4000
-- +===================================================================+
/***************************************************************************
-- Log Messages
****************************************************************************/
PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login     Number                := 786183;  --     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   Number                := 786183; --PLS_INTEGER           := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XX_CRM'
     ,p_program_type            => 'Custom Messages'
     ,p_program_name            => 'XX_CS_TDS_IES_TEMP_PKG'
     ,p_program_id              => null
     ,p_module_name             => 'CSSYNC'
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


  --/*************************************************************
  --* This function logs message
  --*************************************************************/
  PROCEDURE log_msg(
        p_module_name IN VARCHAR2,
        p_string      IN VARCHAR2
       )
  IS

  ln_login     Number                := 786183;  --     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   Number                := 786183;  --     PLS_INTEGER           := FND_GLOBAL.Login_Id;

  BEGIN
--    IF (p_log_flag)
--    THEN
--      fnd_file.put_line(fnd_file.LOG, time_now || ' : ' || p_string);
--      DBMS_OUTPUT.put_line(SUBSTR(p_string, 1, 250));

      XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCS'
      ,p_program_type            => 'DEBUG'              --------index exists on program_type
      ,p_attribute15             => 'XX_CS_STANDBY_PKG'          --------index exists on attribute15
      ,p_program_name           =>  'XX_CS_STANDBY_PKG'
      ,p_program_id              => 0
      ,p_module_name             => p_module_name  --'SMA'                --------index exists on module_name
      ,p_error_message           => p_string
      ,p_error_message_severity  => 'LOG'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => NULL --ln_login
      );
  --  END IF;
  END log_msg;

  --**************************************************************************/
  --* Description: Log the exceptions
  --**************************************************************************/
  PROCEDURE log_error (p_object_id     IN VARCHAR2,
                       p_module        IN VARCHAR2,
                       p_error_msg     IN VARCHAR2)
   IS

  ln_login     Number                := 786183;
  ln_user_id   Number                := 786183;
   BEGIN
      xx_com_error_log_pub.log_error (p_return_code                 => fnd_api.g_ret_sts_error
                                    , p_msg_count                   => 1
                                    , p_application_name            => 'XX_CS'
                                    , p_program_type                => 'ERROR'
                                    , p_program_name                => 'XX_CS_STANDBY_PKG'
                                    , p_attribute15                 => 'XX_CS_STANDBY_PKG'          --------index exists on attribute15
                                    , p_program_id                  => NULL
                                    , p_object_id                   => p_object_id
                                    , p_module_name                 => p_module  -- 'MPS'
                                    , p_error_location              => NULL --p_error_location
                                    , p_error_message_code          => NULL --p_error_message_code
                                    , p_error_message               => p_error_msg
                                    , p_error_message_severity      => 'MAJOR'
                                    , p_error_status                => 'ACTIVE'
                                    , p_created_by                  => ln_user_id
                                    , p_last_updated_by             => ln_user_id
                                    , p_last_update_login           => NULL --g_login_id
                                     );
   END log_error;
/*--------------------------------------------------------------------------
-- AQ UPDATES
****************************************************************************/
PROCEDURE AQ_UPDATES
AS

  TYPE ORDCurTyp    IS REF CURSOR;
  ord_cur           ORDCurTyp;
  TYPE NTSCURTYP    IS REF CURSOR;
  nts_cur           NTSCURTYP;
  stmt_str_ord      VARCHAR2(2000);
  stmt_str_nts      VARCHAR2(2000);
  lc_order_table    VARCHAR2(200);
  lv_db_link        VARCHAR2(100) := fnd_profile.value('XX_CS_STANDBY_DBLINK');
  lc_module         VARCHAR2(100) := 'AQ_UPDATES';

BEGIN

    lc_order_table := 'XX_CS_AOPS_QTAB@'||lv_db_link;
      dbms_output.put_line('table '||lc_order_table);

      /* This query will extract AOPS Order Updates */
      stmt_str_ord := 'INSERT INTO XX_CS_AOPS_QTAB
                        (SELECT * FROM '||LC_ORDER_TABLE||
                        ' WHERE EXCEPTION_QUEUE = ''XX_CS_AOPS_QUEUE'')';
      dbms_output.put_line('stmt_str_ord '||stmt_str_ord);

      --execute immediate stmt_str_ord;

      COMMIT;


     lc_order_table := 'XX_CS_XML_QTAB@'||lv_db_link;
      dbms_output.put_line('table '||lc_order_table);

      /* This query will extract CLMD UPDATES */
      stmt_str_ord := 'INSERT INTO XX_CS_XML_QTAB
                        (SELECT * FROM '||LC_ORDER_TABLE||
                        ' WHERE Q_NAME = ''XX_CS_XML_QUEUE'')';
      dbms_output.put_line('stmt_str_ord '||stmt_str_ord);

      execute immediate stmt_str_ord;

       COMMIT;

END AQ_UPDATES;

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
  lc_module         VARCHAR2(100) := 'CREATE_SR';

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

      --dbms_output.put_line('table '||lc_order_table);

      /* This query will extract all customer service requests */
      stmt_str_ord := 'SELECT incident_number,incident_type_id, problem_code, problem_description,incident_attribute_1,
                              incident_attribute_5, incident_attribute_9, incident_attribute_14,
                              Incident_attribute_15, Incident_attribute_8,incident_attribute_11 ,
                              to_date(incident_attribute_2, ''mm/dd/yy''),Incident_attribute_4,incident_attribute_7,
                              incident_attribute_13, error_code
                        FROM '||LC_ORDER_TABLE||'
                        WHERE PROBLEM_CODE <> ''TDS-SERVICES''
                       --  and incident_number != ''3660134''
                        AND CREATION_DATE >'''|| gd_date ||'''
                        AND INCIDENT_NUMBER NOT IN (SELECT A.INCIDENT_NUMBER FROM CS_INCIDENTS_ALL_B A
                                                WHERE A.CREATION_DATE > '''|| gd_date ||'''
                                                ) 
                        order by incident_number asc   ';

     log_msg(lc_module, 'SQL Statement '|| stmt_str_ord);

     BEGIN
      OPEN ord_cur FOR stmt_str_ord;
        LOOP
          FETCH ord_cur INTO l_sr_req_rec.comments,l_sr_req_rec.type_id, l_sr_req_rec.problem_code, l_sr_req_rec.description,
                            l_sr_req_rec.order_number, l_sr_req_rec.contact_name,l_sr_req_rec.customer_id ,
                            l_sr_req_rec.contact_phone,l_sr_req_rec.sales_rep_contact_name,l_sr_req_rec.contact_email,
                            l_sr_req_rec.warehouse_id,l_sr_req_rec.ship_date,l_sr_req_rec.sales_rep_contact,
                            l_sr_req_rec.preferred_contact,l_sr_req_rec.contact_fax, L_sr_req_rec.user_id;
            EXIT WHEN ord_cur%NOTFOUND;

          log_msg(lc_module, 'Calling service request API for Order number :'|| l_sr_req_rec.order_number ||' '|| 'Incident number '||l_sr_req_rec.comments );

          l_sr_req_rec.ship_to            := '00001';
          l_sr_req_rec.zz_flag            := 'No';
          l_sr_req_rec.comments           := 'Ref :- '||l_sr_req_rec.comments;
          l_sr_req_rec.channel            := 'Phone';

          x_msg_data      := NULL;
          x_return_status := NULL;
          L_REQUEST_ID := NULL;
          L_REQUEST_NUM := NULL;
          
         -- dbms_output.put_line('Customer id '||l_sr_req_rec.customer_id );
         -- dbms_output.put_line('Ship to '||l_sr_req_rec.customer_id );
          
          --l_sr_req_rec.customer_id := '31218200';
          
         -- dbms_output.put_line('After Customer id '||l_sr_req_rec.customer_id );

          XX_CS_SERVICEREQUEST_PKG.CREATE_SERVICEREQUEST(
                  P_SR_REQ_REC => L_SR_REQ_REC,
                  P_ECOM_SITE_KEY => L_ECOM_SITE_KEY,
                  P_REQUEST_ID => L_REQUEST_ID,
                  P_REQUEST_NUM => L_REQUEST_NUM,
                  X_RETURN_STATUS => X_RETURN_STATUS,
                  X_MSG_DATA => X_MSG_DATA,
                  P_ORDER_TBL => L_ORDER_TBL
                );

          log_msg(lc_module, 'Service request created of order number '||l_sr_req_rec.order_number || 'SR number '|| l_request_num );

          -- DBMS_OUTPUT.PUT_LINE('L_REQUEST_NUM = ' || L_REQUEST_NUM);
          -- DBMS_OUTPUT.PUT_LINE('status '||x_return_status||' '||X_MSG_DATA);

          IF X_MSG_DATA IS NOT NULL
          THEN
            log_msg(lc_module, 'X MSG DATA'|| x_msg_data);
          END IF;
          
          commit; -- per order
        

        END LOOP;
      CLOSE ord_cur;
       commit;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      gc_status := 'W';
      gc_message := 'Data not found '||sqlerrm;
      log_error (p_object_id     => NULL,
                   p_module        => lc_module,
                   p_error_msg     => gc_message );
    WHEN OTHERS THEN
      gc_status := 'E';
      gc_message := 'Error '||sqlerrm;
      log_error (p_object_id     => NULL,
                   p_module        => lc_module,
                   p_error_msg     => gc_message );
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
  lc_freeform_string       varchar2(4000);
  lc_freeform_long         varchar2(1000);
  lc_module                VARCHAR2(100) := 'SUBMIT_ANSWERS_EXT';

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
                           log_error (p_object_id     => NULL,
                                      p_module        => lc_module,
                                      p_error_msg     => x_return_mesg );
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
  lc_module               VARCHAR2(100) := 'SUBMIT_ANSWERS';


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
              log_error (p_object_id     => NULL,
                   p_module        => lc_module,
                   p_error_msg     => lc_message );
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
/*****************************************************************************/
PROCEDURE SR_UPDATE  IS

/* Variable Declaration */
 TYPE ORDCurTyp          IS REF CURSOR;
  ord_cur                 ORDCurTyp;
  TYPE NTSCURTYP          IS REF CURSOR;
  nts_cur                 NTSCURTYP;
  ln_obj_ver              number;
  stmt_str_ord            VARCHAR2(2000);
  stmt_str_nts            VARCHAR2(2000);
  lc_message              VARCHAR2(1000);
  lc_request_number        VARCHAR2(25);
  Ln_incident_id           NUMBER;
  ln_incident_status_id    NUMBER;
  lc_status_flag           varchar2(1);
  ld_creation_date         DATE;
  lc_status                VARCHAR2(50);
  lx_return_status         VARCHAR2(1);
  lc_order_table           VARCHAR2(200);
  lc_order_table2          VARCHAR2(200);
  ln_user_id               NUMBER;
  ln_count                 NUMBER := 0;
  lv_db_link               VARCHAR2(100) := fnd_profile.value('XX_CS_STANDBY_DBLINK');
  --
  ln_resp_appl_id             number := 514;
  ln_resp_id                  number := 21739;
  lx_msg_count                NUMBER;
  lx_msg_data                 VARCHAR2(2000);
  x_msg_data                  VARCHAR2(2000);
  lx_interaction_id           NUMBER;
  lx_workflow_process_id      NUMBER;
  lx_msg_index_out            NUMBER;

  lc_module                VARCHAR2(100) := 'SR_UPDATE';


BEGIN

  --dbms_output.put_line('beginging of API ');

  IF lv_db_link IS NULL THEN
      lx_return_status := 'F';
      lc_message := 'Profile Option OD: Standby DB Link Name is not SET.';
      Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.PARTS_UPDATE'
                      ,p_error_message_code =>  'XX_CS_SR01_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
      --dbms_output.put_line('Profile Option OD: Standby DB Link Name is not SET.');
  END IF;


  IF nvl(lx_return_status,'S') = 'S' then

    BEGIN
      SELECT user_id INTO ln_user_id FROM fnd_user
       WHERE user_name = 'CS_ADMIN';
    EXCEPTION
      WHEN OTHERS THEN
        lx_return_status := 'F';
        lc_message     := 'Error while selecting userid '||sqlerrm;
        Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.SR_UPDATE'
                      ,p_error_message_code =>  'XX_CS_SR02_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
     END;

      lc_order_table := 'cs_incidents_audit_b@'||lv_db_link;
      lc_order_table2 := 'cs_incidents_all_b@'||lv_db_link;

      --dbms_output.put_line('table '||lc_order_table);

      /* This query will extract all TDS UPDATES*/

           stmt_str_ord := 'select distinct b.incident_number,
                            a.incident_status_id, a.creation_date
                            from '|| lc_order_table||'  a, '||
                                 lc_order_table2 ||'  b
                            where b.incident_id = a.incident_id
                            and b.problem_code = ''TDS-SERVICES''
                            and a.incident_status_id not in (6100,1,4100)
                            and a.last_updated_by not in (select user_id from fnd_user
                                                           where user_name in (''SUPPORT.COM'',''NEXICORE'', ''IMAGE MICRO''))

                            and a.creation_date > '''|| gd_date ||'''
                            order by b.incident_number, a.creation_date';

      log_msg(lc_module, 'sql stmt '||stmt_str_ord);

     -- dbms_output.put_line('stmt '||stmt_str_ord);

     BEGIN

     /********************************************************************
     --Apps Initialization
     *******************************************************************/
     fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);

      OPEN ord_cur FOR stmt_str_ord;
        LOOP
          FETCH ord_cur INTO lc_request_number,
                             ln_incident_status_id,ld_creation_date;
            EXIT WHEN ord_cur%NOTFOUND;

            log_msg(lc_module, 'Updating the SR '|| lc_request_number);

           --   DBMS_OUTPUT.PUT_LINE ('SR update : '||lc_request_number );

               -- Select primary  incident_id
               BEGIN
                  select incident_id ,
                         object_version_number
                  into ln_incident_id, ln_obj_ver
                  from cs_incidents_all_b
                  where incident_number = lc_request_number;
               exception
                 when others then
                    null;
               END;

               IF ln_incident_id is not null then
                BEGIN
                  SELECT 'Y'
                  INTO LC_STATUS_FLAG
                  FROM CS_INCIDENTS_AUDIT_B
                  WHERE INCIDENT_ID = LN_INCIDENT_ID
                  AND INCIDENT_STATUS_ID = LN_INCIDENT_STATUS_ID;
                EXCEPTION
                  WHEN OTHERS THEN
                     LC_STATUS_FLAG := 'N';
                END;
               end if;

               IF NVL(LC_STATUS_FLAG,'N') = 'N' THEN
               -- UPDATE STATUS.

                Begin
                     --DBMS_OUTPUT.PUT_LINE('SR# Update: '||lc_request_number||' Status '||ln_incident_status_id);
                     log_msg(lc_module, 'Calling SR Update status for '|| lc_request_number||' Status '||ln_incident_status_id);

                     lx_msg_count := null;
                     lx_return_status := null;
                     lx_msg_data := null;
                     x_msg_data := null;

                       CS_SERVICEREQUEST_PUB.Update_Status
                            (p_api_version    => 2.0,
                            p_init_msg_list    => FND_API.G_TRUE,
                            p_commit            => FND_API.G_FALSE,
                            x_return_status    => lx_return_status,
                            x_msg_count            => lx_msg_count,
                            x_msg_data           => lx_msg_data,
                            p_resp_appl_id     => ln_resp_appl_id,
                            p_resp_id             => ln_resp_id,
                            p_user_id             => ln_user_id,
                            p_login_id           => NULL,
                            p_request_id         => ln_incident_id,
                            p_request_number    => NULL,
                            p_object_version_number => ln_obj_ver,
                            p_status_id                 => ln_incident_status_id,
                            p_status                  => NULL,
                            p_closed_date              => SYSDATE,
                            p_audit_comments        => NULL,
                            p_called_by_workflow    => NULL,
                            p_workflow_process_id    => NULL,
                            p_comments                => NULL,
                            p_public_comment_flag    => NULL,
                            x_interaction_id    => lx_interaction_id);


                        commit;
                    exception
                      when others then
                         lc_message := 'Error while updating SR# '||lc_request_number||' '||sqlerrm;
                         Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.SR_UPDATE'
                                           ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                                           ,p_error_msg          =>  lc_message);
                  end;

                 IF (lx_return_status <> FND_API.G_RET_STS_SUCCESS) then
                   IF (FND_MSG_PUB.Count_Msg > 1) THEN
                   --Display all the error messages
                     FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                             FND_MSG_PUB.Get(
                                       p_msg_index => j,
                                       p_encoded => 'F',
                                       p_data => lx_msg_data,
                                       p_msg_index_out => lx_msg_index_out);
                     END LOOP;
                     x_msg_data := lx_msg_data;
                   ELSE
                               --Only one error
                           FND_MSG_PUB.Get(
                                       p_msg_index => 1,
                                       p_encoded => 'F',
                                       p_data => lx_msg_data,
                                       p_msg_index_out => lx_msg_index_out);
                         x_msg_data := lx_msg_data;
                   END IF;
                 log_msg(lc_module, 'Update status for request '||lc_request_number||' '||lx_return_status||substr(x_msg_data,1,150));

                ELSE
                  log_msg(lc_module, 'Return status for request '||lc_request_number||' '||lx_return_status );
                END IF;
               
                --DBMS_OUTPUT.PUT_LINE('Update Status: '||lx_return_status||substr(x_msg_data,1,150));
               END IF;

        END LOOP;
      CLOSE ord_cur;
       commit;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        lx_return_status := 'W';
        lc_message     := 'No Data Found '||sqlerrm;
        log_error (p_object_id     => NULL,
                   p_module        => lc_module,
                   p_error_msg     => lc_message );
    WHEN OTHERS THEN
        lx_return_status := 'F';
        lc_message     := 'Error while selecting userid '||sqlerrm;
        log_error (p_object_id     => NULL,
                   p_module        => lc_module,
                   p_error_msg     => lc_message );
  END;


  END IF;


 END SR_UPDATE;
 
 
 /*****************************************************************************/
PROCEDURE CASE_SR_UPDATE  IS

/* Variable Declaration */
 TYPE ORDCurTyp          IS REF CURSOR;
  ord_cur                 ORDCurTyp;
  TYPE NTSCURTYP          IS REF CURSOR;
  nts_cur                 NTSCURTYP;
  ln_obj_ver              number;
  stmt_str_ord            VARCHAR2(2000);
  stmt_str_nts            VARCHAR2(2000);
  lc_message              VARCHAR2(1000);
  lc_request_number        VARCHAR2(25);
  Ln_incident_id           NUMBER;
  ln_incident_owner_id     NUMBER;
  lc_resolution_code       VARCHAR2(200);
  ln_incident_status_id    NUMBER;
  lc_status_flag           varchar2(1);
  x_msg_count              NUMBER;
  x_interaction_id            NUMBER;
  x_workflow_process_id       NUMBER;
  x_msg_index_out             NUMBER;
  lc_sr_status                VARCHAR2(25);
 ln_status_id                number;
  ln_msg_index                number;
  ln_msg_index_out            number;
  ld_creation_date         DATE;
  ld_last_update_date      DATE;
  lc_status                VARCHAR2(50);
  lx_return_status         VARCHAR2(1);
  lc_order_table           VARCHAR2(200);
  lc_order_table2          VARCHAR2(200);
  ln_user_id               NUMBER;
  ln_count                 NUMBER := 0;
  lv_db_link               VARCHAR2(100) := fnd_profile.value('XX_CS_STANDBY_DBLINK');
  --
  ln_resp_appl_id             number := 514;
  ln_resp_id                  number := 21739;
  lx_msg_count                NUMBER;
  lx_msg_data                 VARCHAR2(2000);
  x_msg_data                  VARCHAR2(2000);
  lx_interaction_id           NUMBER;
  lr_service_request_rec      CS_ServiceRequest_PUB.service_request_rec_type;
  lx_workflow_process_id      NUMBER;
  lx_msg_index_out            NUMBER;
  lt_notes_table              CS_SERVICEREQUEST_PUB.notes_table;
  lt_contacts_tab             CS_SERVICEREQUEST_PUB.contacts_table;
  lc_module                   VARCHAR2(100) := 'CASE_SR_UPDATE';
  
BEGIN

  --dbms_output.put_line('beginging of API ');

  IF lv_db_link IS NULL THEN
      lx_return_status := 'F';
      lc_message := 'Profile Option OD: Standby DB Link Name is not SET.';
      Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.CASE_SR_UPDATE'
                      ,p_error_message_code =>  'XX_CS_SR01_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
      --dbms_output.put_line('Profile Option OD: Standby DB Link Name is not SET.');
  END IF;


  IF nvl(lx_return_status,'S') = 'S' then

    BEGIN
      SELECT user_id INTO ln_user_id FROM fnd_user
       WHERE user_name = 'CS_ADMIN';
    EXCEPTION
      WHEN OTHERS THEN
        lx_return_status := 'F';
        lc_message     := 'Error while selecting userid '||sqlerrm;
        Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.CASE_SR_UPDATE'
                      ,p_error_message_code =>  'XX_CS_SR02_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
     END;

      lc_order_table := 'cs_incidents_audit_b@'||lv_db_link;
      lc_order_table2 := 'cs_incidents_all_b@'||lv_db_link;

      --dbms_output.put_line('table '||lc_order_table);

      /* This query will extract all CASE SR UPDATES*/

           stmt_str_ord := 'select distinct 
                            b.incident_number, a.incident_owner_id , a.resolution_code, a.incident_status_id, a.last_update_date 
                            from '|| lc_order_table||'  a, '||
                                 lc_order_table2 ||'  b
                            where b.incident_id = a.incident_id
                            and b.problem_code != ''TDS-SERVICES''
                            and a.creation_program_code = ''CSXSRISR''
                            --and b.incident_number = ''3661313''
                            --and a.incident_status_id not in (6100,1,4100)
                           -- and a.last_updated_by not in (select user_id from fnd_user
                           --                                where user_name in (''SUPPORT.COM'',''NEXICORE'', ''IMAGE MICRO''))
                            and a.creation_date > '''|| gd_date ||'''
                            order by b.incident_number, a.last_update_date';

      log_msg(lc_module, 'sql stmt '||stmt_str_ord);

     -- dbms_output.put_line('stmt '||stmt_str_ord);

     BEGIN

     /********************************************************************
     --Apps Initialization
     *******************************************************************/
     fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);

      OPEN ord_cur FOR stmt_str_ord;
        LOOP
          FETCH ord_cur INTO lc_request_number,
                             ln_incident_owner_id,
                             lc_resolution_code,
                             ln_incident_status_id,
                             ld_last_update_date;
            EXIT WHEN ord_cur%NOTFOUND;
            

            log_msg(lc_module, 'Updating the SR '|| lc_request_number);

           --   DBMS_OUTPUT.PUT_LINE ('SR update : '||lc_request_number );

               -- Select primary  incident_id
               BEGIN
                  select incident_id ,
                         object_version_number
                  into ln_incident_id, ln_obj_ver
                  from cs_incidents_all_b
                  where incident_number = lc_request_number;
               exception
                 when others then
                    null;
               END;
               

               IF ln_incident_id is not null then
                BEGIN
                  SELECT 'Y'
                  INTO LC_STATUS_FLAG
                  FROM CS_INCIDENTS_AUDIT_B
                  WHERE INCIDENT_ID = LN_INCIDENT_ID
                  AND INCIDENT_STATUS_ID = LN_INCIDENT_STATUS_ID;
                EXCEPTION
                  WHEN OTHERS THEN
                     LC_STATUS_FLAG := 'N';
                END;
               end if;
               
               IF NVL(LC_STATUS_FLAG,'N') = 'N' THEN
               -- UPDATE STATUS.
                  Begin
                     --DBMS_OUTPUT.PUT_LINE('SR# Update: '||lc_request_number||' Status '||ln_incident_status_id);
                     log_msg(lc_module, 'Calling SR Update status for '|| lc_request_number||' Status '||ln_incident_status_id);
                      CS_SERVICEREQUEST_PUB.Update_Status
                            (p_api_version    => 2.0,
                            p_init_msg_list    => FND_API.G_TRUE,
                            p_commit            => FND_API.G_FALSE,
                            x_return_status    => lx_return_status,
                            x_msg_count            => lx_msg_count,
                            x_msg_data           => lx_msg_data,
                            p_resp_appl_id     => ln_resp_appl_id,
                            p_resp_id             => ln_resp_id,
                            p_user_id             => ln_user_id,
                            p_login_id           => NULL,
                            p_request_id         => ln_incident_id,
                            p_request_number    => NULL,
                            p_object_version_number => ln_obj_ver,
                            p_status_id                 => ln_incident_status_id,
                            p_status                  => NULL,
                            p_closed_date              => SYSDATE,
                            p_audit_comments        => NULL,
                            p_called_by_workflow    => NULL,
                            p_workflow_process_id    => NULL,
                            p_comments                => NULL,
                            p_public_comment_flag    => NULL,
                            x_interaction_id    => lx_interaction_id);
                         commit;
                    exception
                      when others then
                         lc_message := 'Error while updating SR# '||lc_request_number||' '||sqlerrm;
                         Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.SR_UPDATE'
                                           ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                                           ,p_error_msg          =>  lc_message);
                    end;
 
                    IF (lx_return_status <> FND_API.G_RET_STS_SUCCESS) then
                      IF (FND_MSG_PUB.Count_Msg > 1) THEN
                       --Display all the error messages
                         FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                               FND_MSG_PUB.Get(
                                         p_msg_index => j,
                                         p_encoded => 'F',
                                         p_data => lx_msg_data,
                                         p_msg_index_out => lx_msg_index_out);
                         END LOOP;
                         x_msg_data := lx_msg_data;
                      ELSE
                               --Only one error
                           FND_MSG_PUB.Get(
                                       p_msg_index => 1,
                                       p_encoded => 'F',
                                       p_data => lx_msg_data,
                                       p_msg_index_out => lx_msg_index_out);
                         x_msg_data := lx_msg_data;
                       END IF;
                    END IF;
  
                     log_msg(lc_module, 'Update status for request '||lc_request_number||' '||lx_return_status||substr(x_msg_data,1,150));

                --DBMS_OUTPUT.PUT_LINE('Update Status: '||lx_return_status||substr(x_msg_data,1,150));
                
               END IF; -- status 
                
               IF (ln_incident_owner_id IS NOT NULL) OR  ( lc_resolution_code IS NOT NULL) 
               THEN 
                 -- Select primary  incident_id
                    BEGIN
                      select incident_id ,
                             object_version_number
                      into ln_incident_id, ln_obj_ver
                      from cs_incidents_all_b
                      where incident_number = lc_request_number;
                   exception
                     when others then
                        null;
                   END;
               

                 log_msg(lc_module, 'Updating SR incident owner or resolution code  for request '||lc_request_number );
                 log_msg(lc_module, 'Incident owner id' || ln_incident_owner_id || ' resolution code '|| lc_resolution_code);
                 
                 cs_servicerequest_pub.initialize_rec( lr_service_request_rec );   
                 
                 IF ln_incident_owner_id IS NOT NULL 
                 THEN 
                   lr_service_request_rec.owner_id        := ln_incident_owner_id ;
                 END IF;
                 
                 IF lc_resolution_code IS NOT NULL
                 THEN 
                   lr_service_request_rec.resolution_code := lc_resolution_code ;
                 END IF;
                 
                  cs_servicerequest_pub.Update_ServiceRequest (
                              p_api_version            => 2.0,
                              p_init_msg_list          => FND_API.G_TRUE,
                              p_commit                 => FND_API.G_FALSE,
                              x_return_status          => lx_return_status,
                              x_msg_count              => lx_msg_count,
                              x_msg_data               => lx_msg_data,
                              p_request_id             => ln_incident_id,
                              p_request_number         => lc_request_number, -- p_sr_number,
                              p_audit_comments         => NULL,
                              p_object_version_number  => ln_obj_ver,
                              p_resp_appl_id           => NULL,
                              p_resp_id                => NULL,
                              p_last_updated_by        => NULL,
                              p_last_update_login      => NULL,
                              p_last_update_date       => sysdate,
                              p_service_request_rec    => lr_service_request_rec,
                              p_notes                  => lt_notes_table,
                              p_contacts               => lt_contacts_tab,
                              p_called_by_workflow     => FND_API.G_FALSE,
                              p_workflow_process_id    => NULL,
                              x_workflow_process_id    => lx_workflow_process_id,
                              x_interaction_id         => lx_interaction_id   );
                            commit;
               
                   -- Check errors
                   IF (lx_return_status <> FND_API.G_RET_STS_SUCCESS) then
                      IF (FND_MSG_PUB.Count_Msg > 1) THEN
                      --Display all the error messages
                        FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                                FND_MSG_PUB.Get(
                                          p_msg_index => j,
                                          p_encoded => 'F',
                                          p_data => lx_msg_data,
                                          p_msg_index_out => ln_msg_index_out);
                        END LOOP;
                      ELSE
                                  --Only one error
                              FND_MSG_PUB.Get(
                                          p_msg_index => 1,
                                          p_encoded => 'F',
                                          p_data =>lx_msg_data,
                                          p_msg_index_out => ln_msg_index_out);
                      END IF;
                     lx_msg_data := lx_msg_data;
                   END IF;
                   
                   log_msg(lc_module, 'Update SR for request number '||lc_request_number||' '||lx_return_status||substr(lx_msg_data,1,150));
               END IF; --Staus 

        END LOOP;
      CLOSE ord_cur;
       commit;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        lx_return_status := 'W';
        lc_message     := 'No Data Found '||sqlerrm;
        log_error (p_object_id     => NULL,
                   p_module        => lc_module,
                   p_error_msg     => lc_message );
    WHEN OTHERS THEN
        lx_return_status := 'F';
        lc_message     := 'Error while selecting userid '||sqlerrm;
        log_error (p_object_id     => NULL,
                   p_module        => lc_module,
                   p_error_msg     => lc_message );
  END;


  END IF;


 END CASE_SR_UPDATE;


/****************************************************************************
*****************************************************************************/
PROCEDURE PARTS_UPDATE  IS

/* Variable Declaration */
 TYPE ORDCurTyp          IS REF CURSOR;
  ord_cur                 ORDCurTyp;
  TYPE NTSCURTYP          IS REF CURSOR;
  nts_cur                 NTSCURTYP;
  stmt_str_ord            VARCHAR2(2000);
  stmt_str_nts            VARCHAR2(2000);
  lc_message              VARCHAR2(1000);
  ln_excess_qty           number;
  lc_excess_flag          varchar2(1);
  ln_recevied_qty         number;
  lc_received_flag        varchar2(1);
  ld_completion_date      date;
  ln_tot_rececived_qty    number;
  lc_sales_flag           varchar2(1);
  lc_attribute3           varchar2(25);
  lc_request_number        VARCHAR2(25);
  lc_status                VARCHAR2(50);
  lx_return_status         VARCHAR2(1);
  lc_order_table           VARCHAR2(200);
  ln_user_id               NUMBER;
  ln_count                 NUMBER := 0;
  lv_db_link               VARCHAR2(100) := fnd_profile.value('XX_CS_STANDBY_DBLINK');

BEGIN

  --dbms_output.put_line('beginging of API ');

  IF lv_db_link IS NULL THEN
      lx_return_status := 'F';
      lc_message := 'Profile Option OD: Standby DB Link Name is not SET.';
      Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.PARTS_UPDATE'
                      ,p_error_message_code =>  'XX_CS_SR01_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
      --dbms_output.put_line('Profile Option OD: Standby DB Link Name is not SET.');
  END IF;


  IF nvl(lx_return_status,'S') = 'S' then

    BEGIN
      SELECT user_id INTO ln_user_id FROM fnd_user
       WHERE user_name = 'CS_ADMIN';
    EXCEPTION
      WHEN OTHERS THEN
        lx_return_status := 'F';
        lc_message     := 'Error while selecting userid '||sqlerrm;
        Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.PARTS_UPDATE'
                      ,p_error_message_code =>  'XX_CS_SR02_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
     END;

      lc_order_table := 'xx_cs_tds_parts@'||lv_db_link;

      --dbms_output.put_line('table '||lc_order_table);

      /* This query will extract all TDS parts update*/
          stmt_str_ord := 'select request_number, excess_quantity,
                            excess_flag, received_quantity,
                            received_shipment_flag, completion_date,
                            tot_received_qty, sales_flag , attribute3
                            from '|| lc_order_table ||
                            ' where last_udate_date > '''|| gd_date ||''' ';

      dbms_output.put_line('stmt '||stmt_str_ord);

     BEGIN
      OPEN ord_cur FOR stmt_str_ord;
        LOOP
          FETCH ord_cur INTO lc_request_number,ln_excess_qty,lc_excess_flag,
                             ln_recevied_qty, lc_received_flag, ld_completion_date,
                             ln_tot_rececived_qty, lc_sales_flag, lc_attribute3;
            EXIT WHEN ord_cur%NOTFOUND;

              DBMS_OUTPUT.PUT_LINE ('Parts Update for Request Number : '||lc_request_number );

                begin
                      update xx_cs_tds_parts
                      set excess_quantity = ln_excess_qty,
                          excess_flag = lc_excess_flag,
                          received_quantity = ln_recevied_qty,
                          received_shipment_flag = lc_received_flag,
                          completion_date = ld_completion_date,
                          tot_received_qty = ln_tot_rececived_qty,
                          sales_flag = lc_sales_flag,
                          attribute3 = lc_attribute3
                      where request_number = lc_request_number;
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
        lx_return_status := 'W';
        lc_message     := 'No Data Found '||sqlerrm;
        Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.PARTS_UPDATE'
                      ,p_error_message_code =>  'XX_CS_SR04a_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
    WHEN OTHERS THEN
        lx_return_status := 'F';
        lc_message     := 'Error while selecting userid '||sqlerrm;
        Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.PARTS_UPDATE'
                      ,p_error_message_code =>  'XX_CS_SR04b_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
  END;


  END IF;
      -- SR updates
      SR_UPDATE;

 END PARTS_UPDATE;
/****************************************************************************
*****************************************************************************/
PROCEDURE GET_QUOTES  IS

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

  --dbms_output.put_line('beginging of API ');

  IF lv_db_link IS NULL THEN
      lx_return_status := 'F';
      lc_message := 'Profile Option OD: Standby DB Link Name is not SET.';
      Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.GET_QUOTES'
                      ,p_error_message_code =>  'XX_CS_SR01_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
      --dbms_output.put_line('Profile Option OD: Standby DB Link Name is not SET.');
  END IF;

  IF nvl(lx_return_status,'S') = 'S' then

    BEGIN
      SELECT user_id INTO ln_user_id FROM fnd_user
       WHERE user_name = 'CS_ADMIN';
    EXCEPTION
      WHEN OTHERS THEN
        lx_return_status := 'F';
        lc_message     := 'Error while selecting userid '||sqlerrm;
        Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.GET_QUOTES'
                      ,p_error_message_code =>  'XX_CS_SR02_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
     END;

      lc_order_table := 'xx_cs_tds_parts_quotes@'||lv_db_link;

      /* This query will extract all TDS Parts Quotes */
      stmt_str_ord := 'INSERT INTO XX_CS_TDS_PARTS_QUOTES
                        ( SELECT * FROM '|| lc_order_table ||
                        ' WHERE CREATION_DATE > '''|| gd_date ||''' ) ';

   --   dbms_output.put_line('stmt '||stmt_str_ord);

   BEGIN
        EXECUTE IMMEDIATE stmt_str_ord;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        lx_return_status := 'W';
        lc_message     := 'No Data Found '||sqlerrm;
        Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.GET_QUOTES'
                      ,p_error_message_code =>  'XX_CS_SR04a_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
    WHEN OTHERS THEN
        lx_return_status := 'F';
        lc_message     := 'Error while selecting userid '||sqlerrm;
        Log_Exception ( p_error_location     =>  'XX_CS_STANDBY_PKG.GET_QUOTES'
                      ,p_error_message_code =>  'XX_CS_SR04b_ERR_LOG'
                      ,p_error_msg          =>  lc_message);
  END;


  END IF;


 END GET_QUOTES;
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
  lc_module                VARCHAR2(100) := 'GET_SKUS_QUOTES';

BEGIN

  --dbms_output.put_line('beginging of API ');

  IF lv_db_link IS NULL THEN
      lx_return_status := 'F';
      lc_message := 'Profile Option OD: Standby DB Link Name is not SET.';
      log_error (p_object_id     => NULL,
                 p_module        => lc_module,
                 p_error_msg     => lc_message );
      --dbms_output.put_line('Profile Option OD: Standby DB Link Name is not SET.');
  END IF;

  IF nvl(lx_return_status,'S') = 'S' then

    BEGIN
      SELECT user_id INTO ln_user_id FROM fnd_user
       WHERE user_name = 'CS_ADMIN';
    EXCEPTION
      WHEN OTHERS THEN
        lx_return_status := 'F';
        lc_message     := 'Error while selecting userid '||sqlerrm;
        log_error (p_object_id     => NULL,
                   p_module        => lc_module,
                   p_error_msg     => lc_message );
     END;

      lc_order_table := 'xx_cs_ies_sku_relations@'||lv_db_link;

      --dbms_output.put_line('table '||lc_order_table);

      /* This query will extract all TDS ORDER sku relations */
      stmt_str_ord := 'SELECT SERVICE_ID, SKU, SKU_CATEGORY,
                        PARENT_SKU, SKU_RELATION,QUANTITY,
                        DESCRIPTION, STATUS, REQUEST_NUMBER
                        FROM '|| lc_order_table ||
                        ' WHERE CREATION_DATE > '''|| gd_date ||'''
                           AND SERVICE_ID NOT IN (SELECT A.SERVICE_ID FROM XX_CS_IES_SKU_RELATIONS A
                                                    WHERE A.CREATION_DATE > '''|| gd_date ||''' ) ';

   --   dbms_output.put_line('stmt '||stmt_str_ord);

     BEGIN
      OPEN ord_cur FOR stmt_str_ord;
        LOOP
          FETCH ord_cur INTO ln_service_id, lc_sku,lc_sku_category,
                             lc_parent_sku, lc_sku_relation, ln_quantity,
                             lc_description, lc_status, lc_request_number;
            EXIT WHEN ord_cur%NOTFOUND;


            log_msg(lc_module, 'Inserting Service Id and Request Number : '||ln_service_id||' - '||lc_request_number );

            --  DBMS_OUTPUT.PUT_LINE ('Service Id and Request Number : '||ln_service_id||' - '||lc_request_number );

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
        lx_return_status := 'W';
        lc_message     := 'No Data Found '||sqlerrm;
        log_error (p_object_id     => NULL,
                   p_module        => lc_module,
                   p_error_msg     => lc_message );
    WHEN OTHERS THEN
        lx_return_status := 'F';
        lc_message     := 'Error while selecting userid '||sqlerrm;
        log_error (p_object_id     => NULL,
                   p_module        => lc_module,
                   p_error_msg     => lc_message );
  END;

     log_msg(lc_module,'Calling Submit Answers procedure');

    SUBMIT_ANSWERS;

  END IF;


 END GET_SKUS_QUOTES;

 /******************************************************************************************/
 PROCEDURE GENERATE_TASK IS

 CURSOR C1 IS
 select incident_id
  from cs_incidents_all_b
  where problem_code = 'TDS-SERVICES'
  and creation_date > gd_date
  and incident_id not in (select source_object_id from jtf_tasks_b
                          where source_object_type_code = 'SR');
  C1_REC C1%ROWTYPE;

 LC_STATUS_FLAG     VARCHAR2(25);
 LC_MESSAGE         VARCHAR2(250);
 lc_module                VARCHAR2(100) := 'GENERATE_TASK';


 BEGIN
     BEGIN
       OPEN C1;
       LOOP
       FETCH C1 INTO C1_REC;
       EXIT WHEN C1%NOTFOUND;

       log_msg(lc_module, 'Task Generated for incident id  '||C1_REC.INCIDENT_ID);

       --   DBMS_OUTPUT.PUT_LINE('Tasks Generated for  '||C1_REC.INCIDENT_ID);

          XX_CS_SR_TASK.CREATE_PROCEDURE(C1_REC.INCIDENT_ID,
                                          LC_STATUS_FLAG,
                                          LC_MESSAGE);

      END LOOP;
      CLOSE C1;
     EXCEPTION
       WHEN OTHERS THEN
          lc_message  := SUBSTR('ERROR while creating the task '|| SQLERRM , 1, 2000);
         -- DBMS_OUTPUT.PUT_LINE('ERROR '||SQLERRM);
           log_error (p_object_id     => NULL,
                      p_module        => lc_module,
                      p_error_msg     => lc_message );
    END;


 END GENERATE_TASK;


 /*******************************************************************************************/
 PROCEDURE CREATE_TDS_SR IS

  LR_SR_REQ_REC      XX_CS_TDS_SR_REC_TYPE;
  LN_REQUEST_ID      NUMBER;
  LC_REQUEST_NUM     varchar2(25);
  lC_ORDER_NUM       VARCHAR2(150);
  ln_customer_id     number;
  ln_user_id         number;
  ld_report_date     date;
  lc_ship_to         varchar2(10);
  ln_ans_id          number;
  lc_contact_id      varchar2(50);
  ln_location_id     number;
  lc_contact_name    varchar2(150);
  lc_contact_phone   varchar2(25);
  lc_contact_email   varchar2(150);
  lc_contact_fax     varchar2(15);
  X_RETURN_STATUS    VARCHAR2(200);
  X_MSG_DATA         VARCHAR2(200);
  LT_ORDER_TBL       XX_CS_SR_ORDER_TBL;
  lr_order_rec       XX_CS_SR_ORDER_REC_TYPE;
  I                 BINARY_INTEGER;
  lv_db_link        VARCHAR2(100) := fnd_profile.value('XX_CS_STANDBY_DBLINK');
  lc_hdr_table      varchar2(1000);
  lc_sku_table      varchar2(1000);
  lc_item_table     varchar2(1000);
  lc_remote_number  VARCHAR2(2000);
  ln_incident_id    number;
  lc_item_number    varchar2(25);
  lc_category       varchar2(15);
  ln_quantity       number;
  lc_parent_sku     varchar2(25);
  lc_attribute1     varchar2(150);
  lc_attribute4     varchar2(150);
  lc_attribute3     varchar2(150);

  TYPE ORDCurTyp    IS REF CURSOR;
  hdr_cur           ORDCurTyp;
  TYPE LineCurTyp   IS REF CURSOR;
  line_cur          LineCurTyp;
  sqlstmt           VARCHAR2(2000);
  skustmt           VARCHAR2(2000);
  lc_module         VARCHAR2(100) := 'CREATE_TDS_SR';
  vl_sr_exists      NUMBER := 0;


BEGIN

  lr_sr_req_rec := XX_CS_TDS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL);


   IF lv_db_link IS NULL THEN
      gc_status := 'F';
      gc_message := 'Profile Option OD: Standby DB Link Name is not SET.';
      log_error (p_object_id     => NULL,
                 p_module        => lc_module,
                 p_error_msg     => gc_message );
      --dbms_output.put_line('Profile Option OD: Standby DB Link Name is not SET.');
   END IF;

  IF nvl(gc_status,'S') = 'S' then

    lc_hdr_table := 'cs_incidents_all_b@'||lv_db_link;
    lc_sku_table := 'xx_cs_ies_sku_relations@'||lv_db_link;

          sqlstmt :=  'select incident_attribute_1||incident_attribute_13 order_number,
                           incident_attribute_9 customer_id,
                           created_by user_id,
                           creation_date,
                           operating_system ship_to,
                           tier dev_ques_ans_id,
                           tier_version contact_id,
                           incident_attribute_11 location_id,
                           incident_attribute_5 contact_name,
                           incident_attribute_14 contact_phone,
                           incident_attribute_8 contact_email,
                           incident_attribute_4 contact_fax,
                           incident_number,
                           incident_id
                          from '|| lc_hdr_table ||'
                          where incident_number in ( select distinct request_number from '|| lc_sku_table ||'
                                              where creation_date >'''|| gd_date ||''')';

    log_msg(lc_module , 'SQL STMT :' || sqlstmt);

   --  dbms_output.put_line('stmt '||sqlstmt);

  BEGIN
    OPEN hdr_cur FOR sqlstmt;
    LOOP
    FETCH hdr_cur INTO lc_order_num,
                        ln_customer_id,
                        ln_user_id,
                        ld_report_date,
                        lc_ship_to,
                        ln_ans_id,
                        lc_contact_id,
                        ln_location_id,
                        lc_contact_name,
                        lc_contact_phone,
                        lc_contact_email,
                        lc_contact_fax,
                        lc_request_num,
                        ln_incident_id;
      EXIT WHEN HDR_CUR%NOTFOUND;

      vl_sr_exists := 0;

      lr_sr_req_rec.description          := 'Tech Depot Services';
      lr_sr_req_rec.comments            := 'testing with contact type';
      lr_sr_req_rec.user_id            := ln_user_id;
      lr_sr_req_rec.request_date       := ld_report_date;
      lr_sr_req_rec.order_number       := lc_order_num;
      lr_sr_req_rec.customer_id        := ln_customer_id;
      lr_sr_req_rec.ship_to            := lc_ship_to;
      lr_sr_req_rec.location_id        := ln_location_id;
      lr_sr_req_rec.contact_name       := lc_contact_name;
      lr_sr_req_rec.contact_phone      := lc_contact_phone;
      lr_sr_req_rec.contact_fax        := lc_contact_fax;
      lr_sr_req_rec.contact_email      := lc_contact_email;
--      lr_sr_req_rec.contact_id         := lc_contact_id;  -- -- commented to pass the contact ref to SR pkg
      lr_sr_req_rec.dev_ques_ans_id    := ln_ans_id;
      ln_incident_id                   := ln_incident_id;
      
     -- lr_sr_req_rec.customer_id := '31218200';   -- ADDDED FOR TESTING 

    -- sku record
    BEGIN

      lc_item_table := 'xx_cs_sr_items_link@'||lv_db_link;
       skustmt := 'select item_number sku, attribute5 sku_category, quantity,
                    order_link parent_sku, attribute1, attribute4, attribute3
                    from '||lc_item_table ||'
                    where service_request_id = '||ln_incident_id;

     log_msg(lc_module, 'Processing request number ..'||lc_request_num );

       I := 1;
      LT_ORDER_TBL := XX_CS_SR_ORDER_TBL();
      OPEN line_cur FOR skustmt;
      loop
      FETCH line_cur INTO lc_item_number, lc_category, ln_quantity,
                          lc_parent_sku, lc_attribute1, lc_attribute4,
                          lc_attribute3;
      EXIT WHEN LINE_CUR%NOTFOUND;

           lt_order_tbl.extend;
          lt_order_tbl(i) := XX_CS_SR_ORDER_REC_TYPE(' ',' ',' ',null,null,null,null,null,null,null,null,null);

          lt_order_tbl(i).order_number              := lc_order_num;
          lt_order_tbl(i).order_sub                 := lc_order_num;
          lt_order_tbl(i).sku_id                    := lc_item_number;
          lt_order_tbl(i).Sku_description           := null;
          lt_order_tbl(i).quantity                  := ln_quantity;
          lt_order_tbl(i).Manufacturer_info         := lc_attribute3;
          lt_order_tbl(i).order_link                := lc_parent_sku;
          lt_order_tbl(i).attribute1                := lc_attribute4;
          lt_order_tbl(i).attribute2                := lc_category;
          lt_order_tbl(i).attribute3                := null;
          lt_order_tbl(i).attribute4                := lc_attribute4;
          lt_order_tbl(i).attribute5                := null;

       --   lt_order_tbl(i) := lr_order_rec;

            i := i+1;


      end loop;
      close line_cur;
      end;

    -- Check if SR exists
    log_msg(lc_module, 'Checking whether SR exists for Request Number :'|| lc_request_num );

     IF lc_request_num IS NOT NULL
     THEN
         BEGIN
           SELECT 1
           INTO vl_sr_exists
           FROM cs_incidents_all_b
           WHERE incident_number = lc_request_num;

           IF vl_sr_exists = 1
           THEN
             log_msg(lc_module, 'Service Request'|| lc_request_num || 'already exists so Skipping the record...' );
           END IF;
         EXCEPTION
           WHEN OTHERS
           THEN
             NULL;
         END;
     END IF;

     IF vl_sr_exists = 0
     THEN

      log_msg(lc_module, 'Calling TDS SR create pkg for order '|| lc_order_num || 'for Request Number :'|| lc_request_num || ' dev_ques_ans_id' ||ln_ans_id);

      lc_request_num := NULL;
      lc_order_num := null;
      x_return_status := null;
      x_msg_data := null;


      XX_CS_TDS_SR_PKG.CREATE_SERVICEREQUEST(
        P_SR_REQ_REC => LR_SR_REQ_REC,
        x_REQUEST_ID => LN_REQUEST_ID,
        x_REQUEST_NUM => LC_REQUEST_NUM,
        X_ORDER_NUM => LC_ORDER_NUM,
        X_RETURN_STATUS => X_RETURN_STATUS,
        X_MSG_DATA => X_MSG_DATA,
        P_ORDER_TBL => LT_ORDER_TBL
      );
      log_msg(lc_module, 'Order '||lc_order_num||' Request Created ' || lc_request_num);

        IF X_RETURN_STATUS  != 'S' AND x_msg_data IS NOT NULL
        THEN
          log_error (p_object_id     => lc_order_num,
                     p_module        => lc_module,
                     p_error_msg     => x_msg_data );
        END IF;
       -- dbms_output.put_line('Order '||lc_order_num||' Request Created ' || lc_request_num);
     END IF;

  END LOOP;
  CLOSE HDR_CUR;
  END;
  end if;

  -- Not required any more . Commented by AG .
  --Get quotes
  --GET_QUOTES;

END CREATE_TDS_SR;

 /********************************************************************************************/
 PROCEDURE MAIN_PROC( P_PROCESS IN VARCHAR2,
                      P_DATE IN VARCHAR2) IS

 BEGIN
    gd_date := to_date(p_date, 'DD-MON-YYYY HH24:MI:SS');

    IF p_process = 'GET_ITEMS' THEN
     -- Get SKU Quotes
     GET_SKUS_QUOTES;
    ELSIF p_process = 'CASEMGMT' THEN
   -- Create Case Management
      CREATE_SR;
    ELSIF p_process = 'UPDATECASEMGMT' THEN
   -- Update Case Management
      CASE_SR_UPDATE;
   ELSIF P_PROCESS = 'TDSORDERS' THEN
   -- TDS Orders
      CREATE_TDS_SR;
   ELSIF P_PROCESS = 'TASK' THEN
      GENERATE_TASK;
   ELSIF P_PROCESS = 'UPDATE' THEN
       -- PARTS_UPDATE;  -- Commented its not required for R12
       SR_UPDATE; -- Added as part of R12
   ELSIF P_PROCESS = 'AQSYNC' THEN
     -- AOPS AND CLMD MESSAGE SYNC
      AQ_UPDATES;
    END IF;

END;

END XX_CS_STANDBY_PKG;
/***************************************************************************************************/

/
SHOW ERRORS;
EXIT;