create or replace 
PACKAGE BODY XX_CS_MPS_FLEET_PKG AS
-- +===============================================================================================+
-- |                            Office Depot - Project Simplify                                    |
-- |                                    Office Depot                                               |
-- +===============================================================================================+
-- | Name  : XX_CS_MPS_FLEET_PKG.pks                                                               |
-- | Description  : This package contains Monitoring systems feed procedures                       |
-- |Change Record:                                                                                 |
-- |===============                                                                                |
-- |Version    Date          Author             Remarks                                            |
-- |=======    ==========    =================  ===================================================|
-- |1.0        31-AUG-2012   Raj Jagarlamudi    Initial version                                    |
-- |1.1                      Raj Jagarlamudi    update the changes                                 |
-- |1.2        28-May-2014   Arun Gannarapu     Made changes to fix the defect 29694               |
-- |1.3        03-Jun-2014   Arun Gannarapu     Made changes to add new values to update_na proc   |
-- |1.4        09-JUN-2014   Arun Gannarapu     Made changes to fix the update_na procedure  30487 |
-- |1.5        22-SEP-2014   Arun Gannarapu     Made changes to fix defect 27312-auto toner release|
-- |1.6        13-APR-2015   Havish Kasina      Added new procedure as per defect id 33419         |
-- |1.7        06-MAY-2015   Havish Kasina      Changes done as per Defect Id  34382               |
-- |1.8        25-May-2015   Himanshu K         Changes for QC 33420                               |
-- |1.9        26-Aug-2015   Himanshu K         Changes for QC 35398                               |
-- |2.0        06-Nov-2015   Havish Kasina      Removed the Schema References as per R12.2 Retrofit|
-- +===============================================================================================+

g_user_name    fnd_user.user_name%TYPE := 'CS_ADMIN';
g_login_id     fnd_user.user_id%TYPE   := fnd_global.login_id;
g_level_limit   number := FND_PROFILE.VALUE('XX_CS_MPS_HIGH_LEVEL'); -- 75

PROCEDURE Initialize_Line_Object (x_line_rec IN OUT NOCOPY XX_CS_SR_REC_TYPE) IS

BEGIN
  x_line_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL);

END Initialize_Line_Object;
/*******************************************************************************************/

PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2
                         ,p_object_id          IN  VARCHAR2)
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
     ,p_program_name            => 'XX_CS_MPS_FLEET_PKG'
     ,p_object_id               =>  p_object_id
     ,p_module_name             => 'MPS'
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
/******************************************************************************/
PROCEDURE CREATE_AVF_SR ( p_party_id      IN NUMBER
                        , x_request_number IN OUT NOCOPY VARCHAR2
                        , x_request_id    IN OUT NOCOPY NUMBER
                        , x_return_status IN OUT NOCOPY VARCHAR2
                        , x_return_msg    IN OUT NOCOPY VARCHAR2
                        ) AS

 -- local variable declaration
  ln_user_id             fnd_user.user_id%TYPE;
  ln_customer            hz_cust_accounts_all.cust_account_id%TYPE;
  lc_return_status       VARCHAR2(1);
  lc_return_mesg         VARCHAR2(2000);
  exc_failed             EXCEPTION;
  lc_msg_data            VARCHAR2(2000);
  lc_summary             VARCHAR2(150);
  lc_comments           VARCHAR2(1000);
  l_initstr              VARCHAR2(2000);
  lc_aops_id             hz_cust_accounts.orig_system_reference%TYPE;
  lr_sr_rec             XX_CS_SR_REC_TYPE;
  lc_request_type       VARCHAR2(150);
  ln_party_id           NUMBER;
  ln_incident_id        number;


  BEGIN

     SELECT user_id
      INTO ln_user_id
      FROM fnd_user
     WHERE user_name = g_user_name;

    BEGIN
      SELECT a.party_id,b.cust_account_id,SUBSTR(b.orig_system_reference,1,8)
        INTO ln_party_id,ln_customer,lc_aops_id
        FROM hz_parties A,
             hz_cust_accounts b
       WHERE b.party_id = a.party_id
       AND a.party_id = p_party_id;
    EXCEPTION
      WHEN OTHERS THEN
        x_return_status := 'E';
        x_return_msg    := 'No party Id in EBS ';
            Log_Exception( p_object_id          => p_party_id
                     , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                     , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                     , p_error_msg          => x_return_msg
                     );
    END;


    --DBMS_OUTPUT.PUT_LINE('PARTY ID '||LN_PARTY_ID||' '||X_RETURN_STATUS);

    IF nvl(x_return_status,'S') = 'S' THEN

      BEGIN
        lr_sr_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL);

        lc_request_type := 'MPS Contract Request';
        lc_comments     := 'AVF Request creation for '||p_party_id;
        lc_summary      := 'AVF Request creation for '||p_party_id;

        BEGIN
          SELECT incident_type_id , name
            INTO lr_sr_rec.type_id, lr_sr_rec.type_name
            FROM cs_incident_types_tl
           WHERE name = lc_request_type;
        EXCEPTION
          WHEN OTHERS THEN
                x_return_status := 'F';
                x_return_msg := 'Req Type Not Defind';
                Log_Exception( p_object_id          => p_party_id
                         , p_error_location     => 'XX_CS_MPS_FLEET_PKG.CREATE_AVF_SR'
                         , p_error_message_code => 'XX_CS_REQ04_ERR_LOG'
                         , p_error_msg          => 'Req Type NOT DEFINED'
                         );
        END;

       IF nvl(x_return_status,'S') = 'S' then
        -- Assign values to rec type
        lr_sr_rec.status_name       := 'Open';
        lr_sr_rec.description       := lc_summary;
        lr_sr_rec.caller_type       := 'MPS-Contract';
        lr_sr_rec.customer_id       := ln_party_id;
        lr_sr_rec.user_id           := ln_user_id;
        lr_sr_rec.channel           := 'WEB'; -- setup
        lr_sr_rec.comments          := lc_comments;
        lr_sr_rec.sales_rep_contact := null;
        lr_sr_rec.customer_number   := lc_aops_id;

        -- Create Request.

         XX_CS_MPS_UTILITIES_PKG.CREATE_SR (P_PARTY_ID => p_party_id,
                       P_SALES_NUMBER   => null,
                       P_REQUEST_TYPE   => LC_REQUEST_TYPE,
                       P_COMMENTS       => LC_COMMENTS,
                       p_sr_req_rec     => lr_sr_rec,
                       x_return_status  => x_return_status,
                       X_RETURN_MSG     => x_return_msg);

         x_request_number := lr_sr_rec.request_number;
         x_request_id := lr_sr_rec.request_id;

        IF NVL(X_RETURN_STATUS,'S') <> 'S'THEN

            lc_msg_data := 'Error while creating SR '||x_return_msg;
            x_return_status := 'F';
            x_return_msg := lc_msg_data;

              Log_Exception( p_object_id          => p_party_id
                           , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                           , p_error_message_code => 'XX_CS_MPS01_ERR_LOG'
                           , p_error_msg          => lc_msg_data
                           );
        END IF;

       END IF;
      END;


      /***********************************************************************/

    END IF; -- status

  EXCEPTION
      WHEN OTHERS THEN
        lc_msg_data     := 'Error '||SQLERRM;
        x_return_status := 'F';
        x_return_msg    := lc_msg_data;
       -- dbms_output.put_line(lc_msg_data);
        Log_Exception( p_object_id          => p_party_id
                     , p_error_location     => 'XX_CS_MPS_FLEET_PKG.CREATE_AVF_SR'
                     , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                     , p_error_msg          => lc_msg_data
                     );

  END CREATE_AVF_SR;
/******************************************************************************/
PROCEDURE TONER_ORDER (P_DAYS IN NUMBER)
IS
CURSOR C1 IS
select distinct mb.party_id, md.serial_no
from xx_cs_mps_device_b mb,
     xx_cs_mps_device_details md
where md.serial_no = mb.serial_no
and  md.toner_order_number is not null
and md.supplies_label <> 'USAGE'
and md.toner_order_date > SYSDATE - P_DAYS
and not exists (select 'X' from xx_cs_mps_toner_details
                where party_id = mb.party_id
                and serial_no = md.serial_no
                and toner_order_number = md.toner_order_number);

C1_REC C1%ROWTYPE;
LC_USAGE_REQUEST    VARCHAR2(25);
LC_MESSAGE       VARCHAR2(2000);

BEGIN
   BEGIN
     OPEN C1;
     LOOP
     FETCH C1 INTO C1_REC;
     EXIT WHEN C1%NOTFOUND;

        BEGIN
           SELECT REQUEST_NUMBER
           INTO LC_USAGE_REQUEST
           FROM XX_CS_MPS_DEVICE_DETAILS
           WHERE SERIAL_NO = C1_REC.SERIAL_NO
           AND SUPPLIES_LABEL = 'USAGE'
           AND ROWNUM < 2;
        EXCEPTION
           WHEN OTHERS THEN
              LC_USAGE_REQUEST := NULL;
        END;

        BEGIN
           INSERT INTO XX_CS_MPS_TONER_DETAILS
           (party_id, serial_no, supplies_label, supplies_level, usage_request_number,
            toner_order_number, toner_order_total, toner_order_date, delivery_date,
            current_count, ordered_item, creation_date, created_by, last_update_date, last_update_by)
            select c1_rec.party_id, md.serial_no, md.supplies_label, md.supplies_level,
                            lc_usage_request, md.toner_order_number, ool.mps_toner_retail,
                            md.toner_order_date, md.delivery_date,
                            md.current_count, ol.ordered_item,sysdate, uid, sysdate, uid
          from xx_cs_mps_device_details md,
               oe_order_headers_all oh,
               oe_order_lines_all ol,
               xx_om_line_attributes_all ool
          where ool.line_id = ol.line_id
          and ol.header_id = oh.header_id
          and oh.order_number = md.toner_order_number||'001'
          and oh.cust_po_number = md.serial_no
          and ool.item_source = 'MPS'
          and ol.ordered_item = decode(ol.ordered_item, md.sku_option_1, md.sku_option_1, md.sku_option_2, md.sku_option_2, md.sku_option_3, md.sku_option_3)
          and md.supplies_label <> 'USAGE'
          and md.serial_no = c1_rec.serial_no;

          commit;
        exception
          when others then
              LC_MESSAGE := 'Error while inserting into TONER DETAIL TABLE'||sqlerrm;
                log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.TONER_ORDER',
                                    p_error_message_code    => 'XX_CS_SR02_ERR_LOG',
                                    P_ERROR_MSG             => LC_MESSAGE,
                                    p_object_id             => C1_rec.party_id);
        end;
     END LOOP;
     CLOSE C1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
END;
/******************************************************************************/
PROCEDURE Device_change (X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
                            X_RETURN_MSG    IN OUT NOCOPY VARCHAR2)
AS

 LN_COUNT         NUMBER := 0;
 LC_MESSAGE       VARCHAR2(2000);
 LC_DEVICE_STR    VARCHAR2(2000);
 LC_SERIAL_STR    VARCHAR2(2000);
 lc_request_type   varchar2(50) := 'MPS Exception Request';
lc_comments       varchar2(1000);
lc_summary        varchar2(250);
lr_request_rec     xx_cs_sr_rec_type;
ln_user_id        number;

 CURSOR C_PARTY_CHANGE IS
 SELECT DISTINCT PARTY_ID
 FROM  XX_CS_MPS_DEVICE_B
  WHERE AVF_SUBMIT IN ('CHANGE','ADDITION');

 C_PARTY_REC C_PARTY_CHANGE%ROWTYPE;

 CURSOR c_device_change (P_PARTY_ID IN NUMBER) IS
 SELECT DB.SERIAL_NO, DB.IP_ADDRESS, DB.MODEL
  FROM  XX_CS_MPS_DEVICE_B DB
  WHERE DB.AVF_SUBMIT IN ('CHANGE','ADDITION')
  AND DB.PARTY_ID = P_PARTY_ID;


BEGIN
    lr_request_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL);

     SELECT user_id
      INTO ln_user_id
      FROM fnd_user
     WHERE user_name = g_user_name;

 BEGIN

   OPEN C_PARTY_CHANGE;
   LOOP
   FETCH C_PARTY_CHANGE INTO C_PARTY_REC;
   EXIT WHEN C_PARTY_CHANGE%NOTFOUND;

    LN_COUNT := 0;

    FOR R_DEVICE_ID IN C_DEVICE_CHANGE(C_PARTY_REC.PARTY_ID) LOOP

     ln_count := ln_count + 1;

    IF ln_count = 1 then
        lc_serial_str := 'Printer changed  '||r_device_id.serial_no||' Ip Address : '||r_device_id.ip_address;
        lc_device_str := r_device_id.serial_no;
    else
        lc_serial_str := lc_serial_str||';'||r_device_id.serial_no;
        lc_device_str := lc_device_str||','||r_device_id.serial_no;
    end if;

   END LOOP;

    IF LN_COUNT > 0 THEN

    FND_FILE.PUT_LINE(FND_FILE.LOG,'IP Address change or Add  FOR '||c_party_rec.party_id) ;

        lc_request_type := 'MPS Exception Request';
        lc_comments     := lc_serial_str;
        lc_summary      := 'Printer Moved/Added ';
         -- Assign values to rec type
         BEGIN
          SELECT incident_type_id , name
            INTO lr_request_rec.type_id,
                 lr_request_rec.type_name
            FROM cs_incident_types_tl
           WHERE name = lc_request_type;
        EXCEPTION
          WHEN OTHERS THEN
                x_return_status := 'F';
                x_return_msg := 'Req Type Not Defind';
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Req Type Not Defind '||c_party_rec.party_id) ;
                Log_Exception( p_object_id          => c_party_rec.party_id
                         , p_error_location     => 'XX_CS_MPS_FLEET_PKG.DEVICE_CHANGE'
                         , p_error_message_code => 'XX_CS_REQ04_ERR_LOG'
                         , p_error_msg          => 'Req Type NOT DEFINED'
                         );
        END;

        lr_request_rec.status_name       := 'Open';
        lr_request_rec.description       := lc_summary;
        lr_request_rec.caller_type       := 'MPS Exception Request';
        lr_request_rec.customer_id       := c_party_rec.party_id;
        lr_request_rec.user_id           := ln_user_id;
        lr_request_rec.channel           := 'WEB';
        lr_request_rec.comments          := lc_comments;

        IF nvl(x_return_status,'S') = 'S' THEN

             BEGIN
               XX_CS_MPS_UTILITIES_PKG.CREATE_SR
                        (P_PARTY_ID        => c_party_rec.party_id,
                          P_SALES_NUMBER   => null,
                          P_REQUEST_TYPE   => lc_request_type,
                          P_COMMENTS       => lc_comments,
                          p_sr_req_rec     => lr_request_rec,
                          x_return_status  => x_return_status,
                          X_RETURN_MSG     => x_return_msg);

               FND_FILE.PUT_LINE(FND_FILE.LOG,'SR Creation status  '||x_return_status||' '||x_return_msg) ;

             EXCEPTION
              when OTHERS then
                LC_MESSAGE := 'Error while calling SR create API '||sqlerrm;
                           log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_CHANGE',
                                          p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                                          P_ERROR_MSG             => LC_MESSAGE,
                                          p_object_id             => c_party_rec.party_id);

              END;
        END IF;

        IF NVL(X_RETURN_STATUS,'S') = 'S' THEN
            BEGIN
               UPDATE XX_CS_MPS_DEVICE_B
               SET AVF_SUBMIT = NULL
               WHERE PARTY_ID = C_PARTY_REC.PARTY_ID
               AND AVF_SUBMIT IN ('CHANGE','ADDITION');

               COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                   LC_MESSAGE := 'Error while updating device table '||sqlerrm;
                     log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_CHANGE',
                                    p_error_message_code    => 'XX_CS_SR02_ERR_LOG',
                                    P_ERROR_MSG             => LC_MESSAGE,
                                    p_object_id             => c_party_rec.party_id);
            END;
       END IF;


    END IF;

   END LOOP;
   CLOSE  C_PARTY_CHANGE;
EXCEPTION
  when OTHERS then
    LC_MESSAGE := 'Error in '||sqlerrm;
               log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_CHANGE',
                              p_error_message_code    => 'XX_CS_SR03_ERR_LOG',
                              P_ERROR_MSG             => LC_MESSAGE,
                              p_object_id             => -1);
 END;

END DEVICE_CHANGE;
/******************************************************************************/
PROCEDURE INSERT_PROC (P_GROUP_ID IN VARCHAR2,
                       P_DEVICE_TBL      IN XX_CS_MPS_DEVICE_TBL_TYPE,
                          X_RETURN_STATUS   IN OUT VARCHAR2,
                          X_RETURN_MSG      IN OUT VARCHAR2)
IS
I           NUMBER;
LC_MESSAGE  VARCHAR2(1000);
ln_def_lev_limit    number := FND_PROFILE.VALUE('XX_CS_MPS_DEV_LIMIT');
BEGIN
    I := P_DEVICE_TBL.FIRST;
    WHILE (I IS NOT NULL) LOOP

    BEGIN
     INSERT INTO XX_CS_MPS_DEVICE_B
                  (DEVICE_ID ,
                    DEVICE_NAME  ,
                    GROUP_ID  ,
                    GROUP_NAME  ,
                    SERIAL_NO ,
                    IP_ADDRESS  ,
                    MANUFACTURER ,
                    MODEL     ,
                    PARTY_ID   ,
                    PARTY_NAME   ,
                    DEVICE_FLOOR ,
                    DEVICE_ROOM ,
                    DEVICE_LOCATION  ,
                    DEVICE_COST_CENTER ,
                    DEVICE_JIT  ,
                    PROGRAM_TYPE   ,
                    MANAGED_STATUS ,
                    ACTIVE_STATUS  ,
                    AVF_SUBMIT  ,
                    FLEET_SYSTEM  ,
                    CREATION_DATE ,
                    CREATED_BY    ,
                    LAST_UPDATE_DATE  ,
                    LAST_UPDATED_BY  ,
                    ASSET_NUMBER,
                    level_limit	)
            VALUES( P_DEVICE_TBL(I).DEVICE_ID
                    ,P_DEVICE_TBL(I).DEVICE_NAME
                    ,P_GROUP_ID
                    , NULL
                    ,P_DEVICE_TBL(I).SERIAL_NUMBER
                    ,P_DEVICE_TBL(I).IP_ADDRESS
                    ,NULL
                    ,NULL
                    ,NULL -- PARTY_ID
                    ,NULL -- PARTY_NAME
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,P_DEVICE_TBL(I).DEVICE_STATUS -- MANAGED STATUS
                    ,'Active'
                    ,'Y'
                    ,'PRINTFLEET'
                    ,SYSDATE
                    ,UID
                    ,SYSDATE
                    ,UID
                    ,NULL
					,nvl(ln_def_lev_limit,70)  );      --QC 33420
              COMMIT;
          EXCEPTION
             WHEN OTHERS THEN
                  lc_message  := 'Error while inserting '||sqlerrm;
                  log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.INSERT_PROC',
                               p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                               p_error_msg             => x_return_msg,
                               p_object_id             => P_DEVICE_TBL(I).DEVICE_ID);
          END;
          I := P_DEVICE_TBL.NEXT(I);
        END LOOP;

  END INSERT_PROC;

  /**************************************************************************/
  PROCEDURE CLOSE_REQ IS

 cursor c1 is
 select distinct md.serial_no,
         md.supplies_label,
         md.request_number,
         md.previous_level,
         floor(md.current_count/30) ave_cnt
  from xx_cs_mps_device_details md
  where md.supplies_label <> 'USAGE'
  and md.toner_order_number is not null
  and  md.request_number is not null
  AND TO_NUMBER(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(REPLACE(md.SUPPLIES_LEVEL,'%',NULL), 'n/a', null), 'OK', null),'LOW' , Null),
           'Ok', null), 'Error', NULL), 'Warning', null), 'Critical', Null),1)) > nvl(g_level_limit,75);

  c1_rec          c1%rowtype;
  lc_status       varchar2(100);
  ln_status_id    number;
  ln_user_id      number;
  x_return_status varchar2(25);
  lc_message      varchar2(250);
  loop_count      number;
  lc_count        number:=0;
  ln_incident_id  number;
  ln_diff_cnt     number;
  ln_exc_level    number := 10;

  BEGIN
    begin
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
     end;

     ln_status_id := 2;
     lc_status := 'Closed';

      fnd_file.put_line(fnd_file.log, 'Before start the loop ..g_level_limit'||' '||g_level_limit);

      begin
      open c1;
      loop
      fetch c1 into c1_rec;
      exit when c1%notfound;

      loop_count  := loop_count + 1;

       fnd_file.put_line(fnd_file.log, 'Processing service request to reset request number and close SR for device'||' '||c1_rec.request_number||' '||c1_rec.serial_no);

             -- Update device table
             begin
               update xx_cs_mps_device_details
               set request_number = null,
                   attribute1 = null,
                   usage_billed = null,
                   last_active = sysdate,
                   first_seen = sysdate,
                   toner_stock = toner_stock - 1
               where serial_no = c1_rec.serial_no
               and supplies_label = c1_rec.supplies_label
               and request_number = c1_rec.request_number;
            exception
               when others then
                  fnd_file.put_line(fnd_file.log,'Error while removing flag for request : '||c1_rec.request_number||' '||c1_rec.serial_no);
            end;

           -- check the SR
           BEGIN
               select cb.incident_id
               into ln_incident_id
               from cs_incidents_all_b cb,
                    cs_incident_statuses_tl ct
                where ct.incident_status_id = cb.incident_status_id
                and  cb.incident_number = c1_rec.request_number
                and ct.name in ('Order Placed', 'Order Delivered');
            exception
               when others then
                  ln_status_id := null;
           END;

           IF Ln_incident_id is not null then

             XX_CS_SR_UTILS_PKG.Update_SR_status(p_sr_request_id  => ln_incident_id,
                                  p_user_id        => ln_user_id,
                                  p_status_id      => ln_status_id,
                                  p_status         => lc_status,
                                  x_return_status  => x_return_status,
                                  x_msg_data      => lc_message);


             If x_return_status= 'E' then

                fnd_file.put_line(fnd_file.log,'Service Request errored : '|| c1_rec.request_number||' '||lc_message);
                fnd_file.put_line(fnd_file.log,'Error status received from  : '||'XX_CS_SR_UTILS_PKG.Update_SR_status'||'.');

             end if;
          end if;

          -- Verify the toner level
          Begin
             select decode(c1_rec.supplies_label, 'TONERLEVEL_BLACK',nvl(total_black_count,0), nvl(total_color_count,0)) -
                    decode(c1_rec.supplies_label, 'TONERLEVEL_BLACK',nvl(previous_black_count,0), nvl(previous_color_count,0))
             into ln_diff_cnt
             from xx_cs_mps_device_details
             where serial_no = c1_rec.serial_no
             and supplies_label = c1_rec.supplies_label
             and rownum < 2;
          exception
            when others then
              null;
          end;

          -- Determine Prematured Toner replacement
         -- IF TO_NUMBER(NVL(REPLACE(REPLACE(REPLACE(REPLACE(c1_rec.previous_level,'%',NULL),'n/a',null),'OK',null),'LOW',NULL),1))

          IF TO_NUMBER(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(REPLACE(c1_rec.previous_level,'%',NULL), 'n/a', null), 'OK', null),
                      'LOW' , Null), 'Ok', null), 'Error', NULL), 'Warning', null), 'Critical', NULL), 1)) > nvl(ln_exc_level,10)
          THEN
             IF ln_diff_cnt < c1_rec.ave_cnt then
               begin
                update xx_cs_mps_device_details
                set attribute4 = 'Y'
                where serial_no = c1_rec.serial_no
                and supplies_label = c1_rec.supplies_label;
               exception
                 when others then
                   null;
               end;
             end if;
            end if;

         IF loop_count = 500 then
           commit;
           loop_count := 0;
         END if;

      end loop;
      close c1;
       commit;
    END;

 END CLOSE_REQ;

 /********************************************************************************/
 -- Procedure is to reset the request flag                                       -- Added by Havish Kasina as per Defect Id:33419
 /********************************************************************************/
 PROCEDURE reset_request_flag (x_retcode             OUT NOCOPY    NUMBER,
                               x_errbuf              OUT NOCOPY    VARCHAR2,
                               p_supplies_label      IN            VARCHAR2,
                               p_request_number      IN            VARCHAR2,
                               p_serial_number       IN            VARCHAR2)
IS
-- +=============================================================================+
-- | Name  : reset_request_flag                                                  |
-- | Description     : The reset_request_flag is the procedure which is going    |
-- |                   to reset the request flags for the supplies label that we |
-- |                   passed through the p_serial_number parameter with         |
-- |                   comma seperator and p_request_number,p_serial_number are  |
-- |                   the other parameters                                      |
-- | Parameters      : x_retcode           OUT                                   |
-- |                   x_errbuf            OUT                                   |
-- |                   p_supplies_label    IN -> Supplies Label                  |
-- |                   p_request_number    IN -> Incident Number                 |
-- |                   p_serial_number     IN -> Serial Number                   |
-- +=============================================================================+
--------------------------------------
-- Local Variable --
--------------------------------------
    ln_var1             NUMBER;
    ln_var2             NUMBER;
    ln_var3             NUMBER;
    ln_pos              NUMBER;
    ln_supplies_label   VARCHAR2(200);
    ln_incident_number  VARCHAR2(100);

BEGIN

  fnd_file.put_line(fnd_file.log , 'Input Parameters ..');
  fnd_file.put_line(fnd_file.log , 'p_request_number :'|| p_request_number);
  fnd_file.put_line(fnd_file.log , 'p_serial_number :'|| p_serial_number);
  fnd_file.put_line(fnd_file.log , 'p_supplies_label :'|| p_supplies_label);

  fnd_file.put_line(fnd_file.log, 'Check whether SR is closed /cancelled ');

  SELECT cb.incident_number
  INTO ln_incident_number
  FROM cs_incidents_all_b   cb,
        cs_incident_statuses ct
  WHERE ct.incident_status_id = cb.incident_status_id
    AND ct.end_date_active is NULL
    AND ct.incident_subtype= 'INC'
    AND cb.incident_number = p_request_number
    AND ct.name in ('Cancelled','Closed');

    IF ln_incident_number IS NOT NULL
    THEN
      ln_var2 := length(p_supplies_label);
      ln_var1 := 1;
      ln_var3 := 1;

      WHILE (ln_var1 < ln_var2)
      LOOP
        BEGIN
          ln_pos := (INSTR(p_supplies_label,',',1,ln_var3)-ln_var1);

          IF ln_pos < 0 THEN
             ln_pos := ln_var2;
          END IF;

          SELECT SUBSTR(p_supplies_label,ln_var1,ln_pos) INTO ln_supplies_label FROM dual;

        --Passing the Supplies Label,Serial Number and Request Number to update the table
          fnd_file.put_line(fnd_file.log,'  ');
          fnd_file.put_line(fnd_file.log,'Reseting the flag for Supplies Label: '||ln_supplies_label);

          UPDATE xx_cs_mps_device_details
             SET request_number =  NULL,
                 attribute1     =  NULL,
                 usage_billed   =  NULL,
                 last_active    =  SYSDATE,
                 first_seen     =  SYSDATE,
                 toner_stock    =  toner_stock - 1
           WHERE request_number =  ln_incident_number
             AND serial_no      =  p_serial_number
             --AND supplies_label =  ln_supplies_label -- Changes done as per Defect Id 34382
             AND UPPER(SUBSTR(supplies_label,12)) = UPPER(ln_supplies_label);

          fnd_file.put_line(fnd_file.log,'Number of records updated :'||SQL%ROWCOUNT);

          IF SQL%ROWCOUNT > 0
          THEN
            fnd_file.put_line(fnd_file.log,'Successfully reset the request flag');
          ELSE
            fnd_file.put_line(fnd_file.log,'Failed to reset the request flag');
          END IF;

          COMMIT;

          ln_var1 := ln_var1 + length(ln_supplies_label)+1;
          ln_var3 := ln_var3+1;

        EXCEPTION
          WHEN OTHERS
          THEN
            fnd_file.put_line(fnd_file.log,'Unable to reset the Request Flag');
            ln_var1 := ln_var1 + length(ln_supplies_label)+1;
            ln_var3 := ln_var3+1;
        END;
      END LOOP;
    END IF;

EXCEPTION
  WHEN NO_DATA_FOUND
  THEN
     fnd_file.put_line(fnd_file.log,'Request status is neither closed nor cancelled. So, the flag cannot be reset.');
     x_retcode := 2;
     ROLLBACK;
  WHEN OTHERS
  THEN
     fnd_file.put_line(fnd_file.log,'Unable to process ' || SQLERRM);
     x_retcode := 2;
     ROLLBACK;
END reset_request_flag;

/**************************************************************************/
  PROCEDURE UPDATE_NA IS

  cursor c1 is
  select md.serial_no, md.supplies_label
  from xx_cs_mps_device_details md,
       xx_cs_mps_device_b mb
  where mb.serial_no = md.serial_no
  and  md.supplies_level in ('n/a','OK','LOW','NA',null,'Ok','Error','Warning', 'Critical')
  and mb.program_type in ('MPS','ATR')
  and md.supplies_label <> 'USAGE';

  c1_rec          c1%rowtype;
  ln_count        number := 0;
  lc_valid_flag   varchar2(1);
  ln_count_limit  number := FND_PROFILE.VALUE('XX_CS_MPS_COUNT_LEVEL'); -- 100

  BEGIN
      begin
      open c1;
      loop
      fetch c1 into c1_rec;
      exit when c1%notfound;


       IF c1_rec.supplies_label = 'TONERLEVEL_BLACK' THEN
          -- verify page count
          BEGIN
              select (nvl(Total_black_count,0) - nvl(previous_black_count,0)) count
              into ln_count
              from xx_cs_mps_device_details
              where serial_no = c1_rec.serial_no
              and supplies_label = 'USAGE';
         exception
            when others then
               ln_count := 0;
         end;

       ELSE

           BEGIN
              select (nvl(Total_color_count,0) - nvl(previous_color_count,0)) count
              into ln_count
              from xx_cs_mps_device_details
              where serial_no = c1_rec.serial_no
              and supplies_label = 'USAGE';
          exception
            when others then
               ln_count := 0;
          end;

       END IF;

       If ln_count > nvl(ln_count_limit,100)
       then
        -- IF lc_valid_flag = 'Y' then
              begin
                update xx_cs_mps_device_details
                set supplies_level = '1%'
                where serial_no = c1_rec.serial_no
                and supplies_label = c1_rec.supplies_label;

                commit;
              end;
        -- end if;
       end if;
      end loop;
      close c1;
      end;
  END;
 /*------------------------------------------------------------------------*/
    --Procedure Name : Make_Param_Str
    --Description    : concatenates parameters for XML message
  /*------------------------------------------------------------------------*/
  FUNCTION make_param_str( p_param_name  IN VARCHAR2
                         , p_param_value IN VARCHAR2
                         ) RETURN VARCHAR2 IS
  BEGIN
  --  RETURN '<ns1:'||p_param_name||
     --      '>'||'<![CDATA['||p_param_value||']]>'||'</ns1:'||p_param_name||'>';

       -- Modified 12/10 based on SOA-Infosec team recomendations -- Raj
        RETURN '<sch:'||p_param_name||
           '>'||'<![CDATA['||p_param_value||']]>'||'</sch:'||p_param_name||'>';


  END make_param_str;
  /***************************************************************************************/
   -- This procedure to receive the device alert message and then get supplies details
   /**************************************************************************************/
  PROCEDURE SUPPLIES_ALERT (P_DEVICE_ID       IN VARCHAR2,
                            P_GROUP_ID        IN VARCHAR2,
                            X_RETURN_STATUS   IN OUT VARCHAR2,
                            X_RETURN_MSG      IN OUT VARCHAR2) AS

       LC_FLEET_SYSTEM    VARCHAR2(100);
       LC_MESSAGE         VARCHAR2(1000);
  BEGIN

         BEGIN
            SELECT FLEET_SYSTEM
            INTO LC_FLEET_SYSTEM
            FROM XX_CS_MPS_DEVICE_B
            WHERE DEVICE_ID = P_DEVICE_ID;
          EXCEPTION
            WHEN OTHERS THEN
                LC_MESSAGE := 'Device not exists ';
                log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.SUPPLIES_ALERT',
                               p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                               p_error_msg             => lc_message,
                               p_object_id             => p_device_id);
          END;

          -- update device notification date
          BEGIN
            UPDATE XX_CS_MPS_DEVICE_B
            SET NOTIFICATION_DATE = SYSDATE
            WHERE DEVICE_ID = P_DEVICE_ID;

            COMMIT;
          EXCEPTION
             WHEN OTHERS THEN
                LC_MESSAGE := 'Error while update notification Date '||sqlerrm;
               log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.SUPPLIES_ALERT',
                              p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                              p_error_msg             => lc_message,
                              p_object_id             => p_device_id);
          END;

          -- Call Supplies feed web service.


  END SUPPLIES_ALERT;
  /********************************************************************************/
 -- Procedure to receive the DEVICE feed
 /******************************************************************************/
 PROCEDURE DEVICE_FEED(P_GROUP_ID        IN VARCHAR2,
                          P_DEVICE_ID       IN VARCHAR2,
                          P_DEVICE_TBL      IN XX_CS_MPS_DEVICE_TBL_TYPE,
                          X_RETURN_STATUS   IN OUT VARCHAR2,
                          X_RETURN_MSG      IN OUT VARCHAR2)
  AS
  l_que_index          Integer; -- NUMBER := 0;
  l_sup_index          Integer; -- NUMBER := 0;
  lc_exit_flag         VARCHAR2(1) := 'N';
  lc_change_flag       VARCHAR2(1) := 'N';
  lc_ip_address        VARCHAR2(100);
  lc_serial_no         VARCHAR2(100);
  lc_message           VARCHAR2(1000);
  lc_avf_proc          VARCHAR2(25);
  l_supply_tbl         XX_CS_MPS_SUPPLY_TBL_TYPE;
  -- Request variables
  lc_request_type     varchar2(50) := 'MPS Exception Request';
  ln_type_id          number;
  lc_comments         varchar2(1000);
  lc_summary          varchar2(250);
  lr_request_rec      xx_cs_sr_rec_type;
  ln_user_id          number;
  ln_party_id         number;
  lc_party_name       varchar2(250);
  lc_return_status    varchar2(25);
  lc_return_mesg      varchar2(1000);
  lc_aops_cust_no     varchar2(25);
  lc_current_cust_no  varchar2(25);
  ln_row_count        number;
  ln_level_limit      number := FND_PROFILE.VALUE('XX_CS_MPS_HIGH_LEVEL'); -- 75
  ln_def_lev_limit    number := FND_PROFILE.VALUE('XX_CS_MPS_DEV_LIMIT');


  BEGIN

     ln_row_count := P_DEVICE_TBL.COUNT;
     LC_MESSAGE := 'Total No Of records '||ln_row_count||' start time ' ||to_char(sysdate,'mm/dd/yy hh24:mi');
     log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_FEED',
                               p_error_message_code    => 'XX_CS_SR01_LOG',
                               p_error_msg             => lc_message,
                               p_object_id             => p_device_id);


     --dbms_output.put_line('count '||P_DEVICE_TBL.count);

     l_que_index    := P_DEVICE_TBL.FIRST;
     WHILE (l_que_index IS NOT NULL) LOOP

		LN_PARTY_ID:=null;    --QC 35398
		LC_PARTY_NAME:='';
    -- dbms_output.put_line('Index '||l_que_index||' device id '||P_DEVICE_TBL(L_QUE_INDEX).ACCOUNT_NUMBER);
    
    IF P_DEVICE_TBL(L_QUE_INDEX).ACCOUNT_NUMBER IS NOT NULL THEN
      BEGIN
        SELECT HP.PARTY_ID, HP.PARTY_NAME
          INTO LN_PARTY_ID, LC_PARTY_NAME
          FROM HZ_PARTIES HP,
               HZ_CUST_ACCOUNTS HC
          WHERE HC.PARTY_ID = HP.PARTY_ID
          AND HC.ORIG_SYSTEM_REFERENCE LIKE P_DEVICE_TBL(L_QUE_INDEX).ACCOUNT_NUMBER||'%';
      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while selecting Account  : '|| sqlerrm);
      END;

    END IF;

     IF P_DEVICE_TBL(L_QUE_INDEX).DEVICE_ID IS NOT NULL THEN
      -- Verify the device
      lc_serial_no := P_DEVICE_TBL(L_QUE_INDEX).SERIAL_NUMBER;
     BEGIN
         SELECT  DISTINCT SERIAL_NO, 'Y', AOPS_CUST_NUMBER, IP_ADDRESS
         INTO LC_SERIAL_NO , LC_EXIT_FLAG, LC_CURRENT_CUST_NO, LC_IP_ADDRESS
         FROM XX_CS_MPS_DEVICE_B
         WHERE DEVICE_ID = P_DEVICE_TBL(L_QUE_INDEX).DEVICE_ID
         AND ROWNUM < 2;
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           LC_EXIT_FLAG := 'N';
           x_return_status := 'S';
           x_return_msg := 'New device';
        WHEN OTHERS THEN
           LC_EXIT_FLAG := 'N';
           x_return_status := 'F';
           x_return_msg := 'Error while selecting. '||sqlerrm;
              log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_FEED',
                               p_error_message_code    => 'XX_CS_SR02_ERR_LOG',
                               p_error_msg             => x_return_msg,
                               p_object_id             => LC_SERIAL_NO);
      END;

     -- dbms_output.put_line('New Device *** '||P_DEVICE_TBL(L_QUE_INDEX).DEVICE_ID||' '||X_RETURN_STATUS||' '||LC_EXIT_FLAG);

      IF NVL(X_RETURN_STATUS,'S') = 'S' THEN

      IF LC_EXIT_FLAG = 'N' THEN
          x_return_msg := 'New device ';
          IF NVL(P_DEVICE_TBL(L_QUE_INDEX).GROUP_ID, P_GROUP_ID) = 'Implementation' THEN
             LC_AVF_PROC := NULL;
          ELSE
             LC_AVF_PROC := 'ADDITION';
          END IF;

          --Insert
          BEGIN
                  INSERT INTO XX_CS_MPS_DEVICE_B
                                (DEVICE_ID ,
                                  DEVICE_NAME  ,
                                  MODEL,
                                  GROUP_ID  ,
                                  SERIAL_NO ,
                                  IP_ADDRESS  ,
                                  PARTY_ID   ,
                                  PARTY_NAME   ,
                                  MANAGED_STATUS ,
                                  ACTIVE_STATUS  ,
                                  AVF_SUBMIT  ,
                                  FLEET_SYSTEM  ,
                                  LEVEL_LIMIT,
                                  CREATION_DATE ,
                                  CREATED_BY    ,
                                  LAST_UPDATE_DATE  ,
                                  LAST_UPDATED_BY  ,
                                  ASSET_NUMBER ,
                                  AOPS_CUST_NUMBER)
                          VALUES ( P_DEVICE_TBL(L_QUE_INDEX).DEVICE_ID
                                  ,P_DEVICE_TBL(L_QUE_INDEX).DEVICE_NAME
                                  ,P_DEVICE_TBL(L_QUE_INDEX).DEVICE_NAME
                                  ,P_GROUP_ID
                                  ,P_DEVICE_TBL(L_QUE_INDEX).SERIAL_NUMBER
                                  ,P_DEVICE_TBL(L_QUE_INDEX).IP_ADDRESS
                                  ,LN_PARTY_ID
                                  ,LC_PARTY_NAME
                                  ,NULL -- MANAGED STATUS
                                  ,P_DEVICE_TBL(L_QUE_INDEX).DEVICE_STATUS
                                  ,LC_AVF_PROC
                                  ,'PRINTFLEET'
                                  ,nvl(ln_def_lev_limit,70)         --QC 33420
                                  ,SYSDATE
                                  ,UID
                                  ,SYSDATE
                                  ,UID
                                  ,NULL
                                  ,P_DEVICE_TBL(L_QUE_INDEX).ACCOUNT_NUMBER);
              COMMIT;
            EXCEPTION
              WHEN OTHERS THEN
                  lc_message  := 'Error while inserting '||sqlerrm;
                  log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_FEED',
                               p_error_message_code    => 'XX_CS_SR02_ERR_LOG',
                               p_error_msg             => x_return_msg,
                               p_object_id             => lc_serial_no);
            END;

            -- Details table update
           BEGIN
                  INSERT INTO XX_CS_MPS_DEVICE_DETAILS
                     (current_count    ,
                      black_count,
                      color_count,
                      supplies_label,
                      total_count,
                      creation_date,
                      created_by,
                      last_update_date,
                      last_update_by ,
                      first_seen ,
                      last_active,
                      device_id,
                      serial_no)
                  VALUES(  p_device_tbl(l_que_index).current_count,
                           p_device_tbl(l_que_index).black_count,
                           p_device_tbl(l_que_index).color_count,
                          'USAGE',
                           p_device_tbl(l_que_index).total_count,
                           sysdate,
                           uid,
                           sysdate,
                           uid ,
                           p_device_tbl(l_que_index).first_seen,
                           p_device_tbl(l_que_index).last_active,
                           p_device_tbl(l_que_index).device_id,
                           p_device_tbl(l_que_index).serial_number);

                 commit;
              exception
                when others then
                     LC_MESSAGE := 'Error while INSERTING '||sqlerrm;
                       log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_FEED',
                                     p_error_message_code    => 'XX_CS_SR03_ERR_LOG',
                                     p_error_msg             => lc_message,
                                     p_object_id             => lc_serial_no);
              end;
            -- SUPPLY information insert
          BEGIN
              l_supply_tbl   := p_device_tbl(l_que_index).supply_tbl;
              l_sup_index    := l_supply_tbl.FIRST;

          FND_FILE.PUT_LINE(FND_FILE.LOG,'New Device :'||p_device_tbl(l_que_index).device_id||'Supplies Row count '||l_supply_tbl.count);

          WHILE l_sup_index IS NOT NULL
          LOOP

          IF l_supply_tbl(l_sup_index).label is not null then
           BEGIN
            INSERT INTO XX_CS_MPS_DEVICE_DETAILS
            (supplies_level,
                creation_date    ,
                created_by    ,
                last_update_date,
                last_update_by     ,
                first_seen,
                last_active ,
                device_id ,
                serial_no,
                supplies_label,
                attribute2)
            VALUES( l_supply_tbl(l_sup_index).high_level,
                    sysdate,
                    uid,
                    sysdate,
                    uid ,
                    l_supply_tbl(l_sup_index).first_report,
                    l_supply_tbl(l_sup_index).last_report,
                    p_device_tbl(l_que_index).device_id,
                     p_device_tbl(l_que_index).serial_number,
                    l_supply_tbl(l_sup_index).label,
                    20);

           commit;
        exception
          when others then
               LC_MESSAGE := 'Error while INSERTING '||sqlerrm;
                 log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_FEED',
                               p_error_message_code    => 'XX_CS_SR04_ERR_LOG',
                               p_error_msg             => lc_message,
                               p_object_id             => lc_serial_no);
        end;

          end if;
           l_sup_index := l_supply_tbl.next(l_sup_index);
        end loop;
        end;


      ELSE

        IF LC_IP_ADDRESS <> P_DEVICE_TBL(L_QUE_INDEX).IP_ADDRESS THEN
           LC_CHANGE_FLAG := 'Y';
          -- create exception request
           LC_AVF_PROC := 'CHANGE';
          -- update device table
          BEGIN
            UPDATE XX_CS_MPS_DEVICE_B
            SET IP_ADDRESS = P_DEVICE_TBL(L_QUE_INDEX).IP_ADDRESS,
                AVF_SUBMIT = LC_AVF_PROC,
                LAST_UPDATE_DATE = SYSDATE
            WHERE DEVICE_ID = P_DEVICE_TBL(L_QUE_INDEX).DEVICE_ID;

            COMMIT;
          EXCEPTION
             WHEN OTHERS THEN
                 LC_MESSAGE := 'Error while updating '||sqlerrm;
                 log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_FEED',
                               p_error_message_code    => 'XX_CS_SR05_ERR_LOG',
                               p_error_msg             => lc_message,
                               p_object_id             => lc_serial_no);
          END;

        END IF;

      -- Update the customer if program changed. 04/17
      IF P_DEVICE_TBL(L_QUE_INDEX).ACCOUNT_NUMBER IS NOT NULL THEN

         BEGIN
            UPDATE XX_CS_MPS_DEVICE_B
            SET AOPS_CUST_NUMBER = P_DEVICE_TBL(L_QUE_INDEX).ACCOUNT_NUMBER,
                PARTY_ID = LN_PARTY_ID,
                PARTY_NAME = LC_PARTY_NAME
            WHERE DEVICE_ID = P_DEVICE_TBL(L_QUE_INDEX).DEVICE_ID;

            COMMIT;
          EXCEPTION
             WHEN OTHERS THEN
                 LC_MESSAGE := 'Error while updating '||sqlerrm;
                 log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_FEED',
                               p_error_message_code    => 'XX_CS_SR05A_ERR_LOG',
                               p_error_msg             => lc_message,
                               p_object_id             => lc_serial_no);

          END;

      END IF;
      -- UPDATE TABLE  modified on 4/12
        BEGIN
            UPDATE XX_CS_MPS_DEVICE_DETAILS
            SET total_count          = p_device_tbl(l_que_index).total_count,
                total_black_count = p_device_tbl(l_que_index).black_count,
                total_color_count = p_device_tbl(l_que_index).color_count,
                previous_count = nvl(total_count,0),
                previous_black_count = nvl(total_black_count,0),
                previous_color_count = nvl(total_color_count,0),
                last_update_date    = sysdate,
                last_update_by        = uid ,
                first_seen =  p_device_tbl(l_que_index).first_seen,
                last_active =  p_device_tbl(l_que_index).last_active
                where device_id = p_device_tbl(l_que_index).device_id
                and supplies_label = 'USAGE';

           commit;
        exception
          when others then
               LC_MESSAGE := 'Error while updating details '||sqlerrm;
                 log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_FEED',
                               p_error_message_code    => 'XX_CS_SR06_ERR_LOG',
                               p_error_msg             => lc_message,
                               p_object_id             => lc_serial_no);
        end;
        -- supplies information

        begin
          l_supply_tbl   := p_device_tbl(l_que_index).supply_tbl;
          l_sup_index    := l_supply_tbl.FIRST;

           FND_FILE.PUT_LINE(FND_FILE.LOG,'SerialNo :'||p_device_tbl(l_que_index).device_id||'Supplies Row count '||l_supply_tbl.count);


          WHILE l_sup_index IS NOT NULL
          LOOP

         -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Device :'||p_device_tbl(l_que_index).device_id||'-level '||l_supply_tbl(l_sup_index).high_level||'-label '||l_supply_tbl(l_sup_index).label);

                   BEGIN
                      UPDATE XX_CS_MPS_DEVICE_DETAILS
                      SET previous_level = supplies_level,
                          supplies_level = l_supply_tbl(l_sup_index).high_level,
                          --creation_date        = sysdate,
                          --created_by        = uid,
                          last_update_date    = sysdate,
                          last_update_by        = uid ,
                          first_seen =  l_supply_tbl(l_sup_index).first_report,
                          last_active =  l_supply_tbl(l_sup_index).last_report
                          where device_id = p_device_tbl(l_que_index).device_id
                          and  supplies_label = l_supply_tbl(l_sup_index).label;

                     commit;
                  exception
                    when others then
                         LC_MESSAGE := 'Error while updating details '||sqlerrm;
                           log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_FEED',
                                         p_error_message_code    => 'XX_CS_SR07_ERR_LOG',
                                         p_error_msg             => lc_message,
                                         p_object_id             => lc_serial_no);
                  end;

           l_sup_index := l_supply_tbl.next(l_sup_index);

          end loop;
        end;

       END IF;

   END IF;

      END IF;

      l_que_index := P_DEVICE_TBL.NEXT(l_que_index);
      END LOOP;

       x_return_status := 'S';


      LC_MESSAGE := 'end time ' ||to_char(sysdate,'mm/dd/yy hh24:mi');
      log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_FEED',
                               p_error_message_code    => 'XX_CS_SR02_LOG',
                               p_error_msg             => lc_message,
                               p_object_id             => p_device_id);
    exception
      when others then
        x_return_status := 'F';
        x_return_msg := 'Error while processing data '||sqlerrm;
           log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.DEVICE_FEED',
                               p_error_message_code    => 'XX_CS_SR08_ERR_LOG',
                               p_error_msg             => x_return_msg,
                               p_object_id             => p_group_id);
  END DEVICE_FEED;


 /****************************************************************************/
 /*************************************************************************
-- Soap Request
**************************************************************************/
FUNCTION http_post ( p_customer_no IN VARCHAR2,
                     p_group_id    IN VARCHAR2,
                     p_vendor      IN VARCHAR2,
                     P_URL         IN VARCHAR2)
RETURN VARCHAR2 AS

    soap_request      VARCHAR2(30000);
    soap_respond      VARCHAR2(30000);
    req               utl_http.req;
    resp              utl_http.resp;
    v_response_text   VARCHAR2(32767);
    x_resp            XMLTYPE;
    i                 integer;
    l_msg_data        varchar2(30000);
    lc_return_status  varchar2(100) := 'false';
    lc_conn_link      varchar2(3000);
    lc_message        varchar2(3000);
    l_initstr         VARCHAR2(2000);
    x_return_status   varchar2(100);
    x_return_msg      varchar2(1000);


begin

   -- modified on 10/4 based on SOA xsd file
   -- modified on 10/16 based on SOA fix
   -- modified on 12/6 based on SOA team instructions
   -- modified on 12/10 based on SOA team instructions

          l_initstr := l_initstr||'<sch:GetPFDetailsRequest>';
          --  l_initstr := l_initstr||'<GroupID>'||p_group_id||'</GroupID>';
           l_initstr := l_initstr||Make_Param_Str
                                    ('GroupID',p_group_id);
          --  l_initstr := l_initstr||'<VendorName>'||p_vendor||'</VendorName>';
            l_initstr := l_initstr||Make_Param_Str
                                    ('VendorName',p_vendor);
          l_initstr := l_initstr||'</sch:GetPFDetailsRequest>';

    /*   l_initstr := l_initstr||'<sch:GetPFDetailsResponse>';
        --    l_initstr := l_initstr||'<StatusCode>'||x_return_status||'</StatusCode>';
              l_initstr := l_initstr||Make_Param_Str
                                    ('StatusCode',x_return_status);
          --  l_initstr := l_initstr||'<StatusMessage>'||x_return_msg||'</StatusMessage>';
           l_initstr := l_initstr||Make_Param_Str
                                    ('StatusMessage',x_return_msg);
          l_initstr := l_initstr||'</sch:GetPFDetailsResponse>'; */

                -- Modified on 10/16 based in SOA service fix

    /*  soap_request := '<?xml version="1.0" encoding="UTF-8"?>'||
                      '<schema targetNamespace="http://officedepot.com/MPS/PF/GetDetails/Schema" elementFormDefault="qualified" '||
                      'xmlns="http://www.w3.org/2001/XMLSchema" xmlns:tns="http://officedepot.com/MPS/PF/GetDetails/Schema">'||l_initstr||'</schema>';
                       */

         -- modified on 10/16 based on SOA team instructions
     /*  soap_request := '<?xml version = "1.0" encoding = "UTF-8"?>'||
                      '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'||
                      '<soapenv:Header xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'||
                      '</soapenv:Header>'||
                      '<soapenv:Body>'||l_initstr||
                      '</soapenv:Body>'||'</soapenv:Envelope>';  */

        -- modified on 12/10 based on SOA team
        soap_request := '<?xml version = "1.0" encoding = "UTF-8"?>'||
                      '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sch="http://officedepot.com/MPS/PF/GetDetails/Schema">'||
                      '<soapenv:Header xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'||
                      '</soapenv:Header>'||
                      '<soapenv:Body>'||l_initstr||
                      '</soapenv:Body>'||'</soapenv:Envelope>';

      dbms_output.put_line(p_url||soap_request);

      req := utl_http.begin_request(p_url,'POST','HTTP/1.1');
      utl_http.set_header(req,'Content-Type', 'text/xml'); --; charset=utf-8');
      utl_http.set_header(req,'Content-Length', length(soap_request));
      utl_http.set_header(req  , 'SOAPAction'  , 'process');
      utl_http.write_text(req, soap_request);

        resp := utl_http.get_response(req);
        utl_http.read_text(resp, soap_respond);

        lc_message := 'Response Received '||resp.status_code;

        dbms_output.put_line('message '||lc_message);

      utl_http.end_response(resp);

      x_resp := XMLType.createXML(soap_respond);

      l_msg_data := 'Req '||soap_request;

        x_resp := x_resp.extract('/soap:Envelop/soap:Body/child::node()'
                               ,'xmlns:soap="http://TargetNamespace.com/XMLSchema-instance"');

          l_msg_data := 'Res '||soap_respond;

         v_response_text := l_msg_data;

         dbms_output.put_line('res '||l_msg_data);

    return v_response_text;
end;
/********************************************************************************************/

 /******************************************************************************/

 PROCEDURE MAIN_PROC ( X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                        X_RETCODE         OUT  NOCOPY  NUMBER,
                        P_TYPE            IN VARCHAR2,
                        P_GROUP_ID        IN VARCHAR2,
                        P_FEED_SYSTEM     IN VARCHAR2)
  AS
  CURSOR C1 IS
  SELECT DISTINCT GROUP_ID
  FROM XX_CS_MPS_DEVICE_B
  WHERE FLEET_SYSTEM = P_FEED_SYSTEM;

  C1_REC  C1%ROWTYPE;

  lc_comments           VARCHAR2(1000);
  lc_msg_data           VARCHAR2(2000);
  l_initstr             VARCHAR2(2000);
  l_url                 varchar2(1000) := FND_PROFILE.VALUE('XX_CS_MPS_FLEET_URL');
  --http://soafmwdev01app02.na.odcorp.net:7052//PFGetDataViewService/Services/ProxyServices/PFGetDataViewService
  x_return_status       varchar2(100);
  x_return_msg          varchar2(1000);
  l_customer_no         varchar2(100);
  v_file_name           varchar2(150);
  lc_request_number     varchar2(25);
  ln_request_id         number;
  ln_party_id           number;
  lc_message            varchar2(1000);

  BEGIN

  IF P_TYPE = 'UPLOAD' THEN

     select NVL(fnd_profile.value('XX_CS_MPS_AVE_FILE'),'NEW_FILE_02.csv')
     into v_file_name
     from dual;

     lc_message := 'UPLOAD PROCESS : FILE NAME '||V_FILE_NAME;

      log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                              p_error_message_code    => 'XX_CS_SR01_LOG',
                              p_error_msg             => lc_message,
                              p_object_id             => ln_party_id);

     BEGIN

      xx_cs_mps_avf_feed_pkg.fleet_feed ( p_file_name    => v_file_name
                                        , x_return_status => x_return_status
                                        , x_return_msg     => x_return_msg );

     EXCEPTION
        WHEN OTHERS THEN
           lc_message := 'error while UPLOAD PROCESS : '||V_FILE_NAME||' ' ||x_return_msg;
          log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                              p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                              p_error_msg             => lc_message,
                              p_object_id             => ln_party_id);
     END;

  ELSIF P_TYPE = 'SHIPTO' THEN

     begin
      select incident_id , customer_id
      into ln_request_id, ln_party_id
      from cs_incidents_all_b
      where incident_number = p_group_id;
     exception
       when others then
         null;
     end;

     IF ln_request_id is not null then

      lc_message := 'Call ShipTo file process for party : '||ln_party_id;

      log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                              p_error_message_code    => 'XX_CS_SR01_LOG',
                              p_error_msg             => lc_message,
                              p_object_id             => ln_party_id);

     BEGIN

       xx_cs_mps_avf_feed_pkg.get_ship_to(p_party_id      => ln_party_id
                                      , x_return_status  => x_return_status
                                      , x_return_mesg    => x_return_msg);

    EXCEPTION
     WHEN OTHERS THEN
           lc_message := 'error while calling ShipTo file process for party : '||ln_party_id ||x_return_msg;
          log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                              p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                              p_error_msg             => lc_message,
                              p_object_id             => ln_party_id);
      END;

      end if;

  ELSIF P_TYPE = 'FLEETLOAD' THEN

     begin
      select incident_id , customer_id
      into ln_request_id, ln_party_id
      from cs_incidents_all_b
      where incident_number = p_group_id;
     exception
       when others then
         null;
     end;

     IF ln_request_id is not null then

       lc_message := 'Before call receive feed '||ln_request_id;

         Log_Exception ( p_error_location     =>  'XX_CS_MPS_FLEET_PKG.MAIN_PROC'
                           ,p_error_message_code =>   'XX_CS_0001A_SUCCESS_LOG'
                           ,p_error_msg          =>  lc_message
                           ,p_object_id          => ln_request_id
                            );
         BEGIN
             xx_cs_mps_avf_feed_pkg.load_fleet_feed( p_request_id   => ln_request_id
                                              , x_return_status  => x_return_status
                                              , x_return_msg    => lc_message);

        EXCEPTION
         WHEN OTHERS THEN
               lc_message := 'error while calling load_fleet_feed for request : '||p_group_id ||x_return_msg;
              log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                                  p_error_message_code    => 'XX_CS_SR01B_ERR_LOG',
                                  p_error_msg             => lc_message,
                                  p_object_id             => p_group_id);
          END;

      else
         lc_message := 'Request Id not Passed '||p_group_id;

         Log_Exception ( p_error_location     =>  'XX_CS_MPS_FLEET_PKG.MAIN_PROC'
                           ,p_error_message_code =>   'XX_CS_0001b_ERR_LOG'
                           ,p_error_msg          =>  lc_message
                           ,p_object_id          => ln_request_id
                            );

      end if;

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Load Data Completed     :'|| to_char(sysdate, 'mm/dd/yy hh24:mi'));

  ELSIF P_TYPE = 'MISC' THEN

     begin
      select incident_id , customer_id
      into ln_request_id, ln_party_id
      from cs_incidents_all_b
      where incident_number = p_group_id;
     exception
       when others then
         null;
     end;

      BEGIN
             xx_cs_mps_avf_feed_pkg.misc_feed( p_request_id   => ln_request_id
                                              , x_return_status  => x_return_status
                                              , x_return_msg    => lc_message);

        EXCEPTION
         WHEN OTHERS THEN
               lc_message := 'error while calling misc for request : '||p_group_id ||x_return_msg;
              log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                                  p_error_message_code    => 'XX_CS_SR01c_ERR_LOG',
                                  p_error_msg             => lc_message,
                                  p_object_id             => p_group_id);
          END;

  ELSIF P_TYPE = 'AVF' THEN
   IF p_group_id is not null then
     begin
       update xx_cs_mps_device_b
       set avf_submit = null
       where party_id = p_group_id;

       commit;
      exception
        when others then
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while updating AVF flag for party '||p_group_id);
           x_return_status := 'F';
     end;

     IF nvl(x_return_status,'S') <> 'F' then
         CREATE_AVF_SR ( p_party_id      => p_group_id
                            , x_request_number => lc_request_number
                            , x_request_id    => ln_request_id
                            , x_return_status => x_return_status
                            , x_return_msg    => x_return_msg
                            );

     IF ln_request_id is not null then

     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_request_number||' Request created and AVF is in Process... ');

      BEGIN

       xx_cs_mps_avf_feed_pkg.send_feed( p_request_id   => ln_request_id
                                      , p_party_id      => p_group_id
                                      , x_return_status  => x_return_status
                                      , x_return_mesg    => x_return_msg);

      FND_FILE.PUT_LINE(FND_FILE.LOG,' AVF generated, Please upload AVF to Request# '||lc_request_number);

     exception
      WHEN OTHERS THEN
           lc_message := 'error while calling AVF process for party : '||ln_party_id ||x_return_msg;
          log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                              p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                              p_error_msg             => lc_message,
                              p_object_id             => ln_party_id);
      END;

      end if;  -- Incident id

      else
         FND_FILE.PUT_LINE(FND_FILE.LOG,' error while updating AVF flag '||p_group_id);
      end if;  -- status flag
   else
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Not a valid party id '||p_group_id);
   end if; -- Group id check

  ELSIF P_TYPE = 'SOA-WEB' THEN

    IF P_GROUP_ID IS NULL THEN
        OPEN C1;
        LOOP
          FETCH C1 INTO C1_REC;
          EXIT WHEN C1%NOTFOUND;

            -- CALL DEVICE WEB SERVICE

            BEGIN
              lc_msg_data := http_post(l_customer_no,
                                       c1_rec.group_id,
                                       p_feed_system,
                                       l_url) ;

             -- dbms_output.put_line('msg '||lc_msg_data);

            EXCEPTION
              WHEN OTHERS THEN
                lc_msg_data := 'Error while calling monitoring system web service '||SQLERRM;
                Log_Exception( p_object_id          => c1_rec.group_id
                             , p_error_location     => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC'
                             , p_error_message_code => 'XX_CS_MPS01_ERR_LOG'
                             , p_error_msg          => lc_msg_data
                             );
            END;

        END LOOP;

    ELSE
          BEGIN
              lc_msg_data := http_post(l_customer_no,
                                       p_group_id,
                                       p_feed_system,
                                       l_url) ;

            EXCEPTION
              WHEN OTHERS THEN
                lc_msg_data := 'Error while calling monitoring system web service '||SQLERRM;
                Log_Exception( p_object_id          => p_group_id
                             , p_error_location     => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC'
                             , p_error_message_code => 'XX_CS_MPS02_ERR_LOG'
                             , p_error_msg          => lc_msg_data
                             );
            END;
    END IF;

  END IF; -- TYPE

IF P_TYPE = 'FLEETLOAD' THEN
  BEGIN
      UPDATE_NA;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated level not received devices  : '|| to_char(sysdate, 'mm/dd/yy hh24:mi'));
  EXCEPTION
     WHEN OTHERS THEN
           lc_message := 'error while calling update NAs : '||SQLERRM;
          log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                              p_error_message_code    => 'XX_CS_MPS05a_ERR_LOG',
                              p_error_msg             => lc_message,
                              p_object_id             => ln_party_id);
   END;

   BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling CLOSE_REQ to close the SRs...');

        CLOSE_REQ;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Closed Toner Order requests..  : '|| to_char(sysdate, 'mm/dd/yy hh24:mi'));

  EXCEPTION
     WHEN OTHERS THEN
           lc_message := 'error while closing REQ : '||SQLERRM;
          log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                              p_error_message_code    => 'XX_CS_MPS05b_ERR_LOG',
                              p_error_msg             => lc_message,
                              p_object_id             => ln_party_id);
   END;


  -- Add ship to
   BEGIN
    XX_CS_MPS_CDH_SYNC.ADD_SHIP_TO;

    FND_FILE.PUT_LINE(FND_FILE.LOG,' Add ship to for new devices  : '|| to_char(sysdate, 'mm/dd/yy hh24:mi'));

   EXCEPTION
     WHEN OTHERS THEN
           lc_message := 'error while calling XX_CS_MPS_CDH_SYNC.ADD_SHIP_TO : '||SQLERRM;
          log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                              p_error_message_code    => 'XX_CS_MPS05_ERR_LOG',
                              p_error_msg             => lc_message,
                              p_object_id             => ln_party_id);
   END;

   -- Update ship-to
   BEGIN
    XX_CS_MPS_CDH_SYNC.UPDATE_SHIP_TO;

    FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated ship to sync  : '|| to_char(sysdate, 'mm/dd/yy hh24:mi'));
   EXCEPTION
     WHEN OTHERS THEN
           lc_message := 'error while calling XX_CS_MPS_CDH_SYNC.UPDATE_SHIP_TO : '||SQLERRM;
          log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                              p_error_message_code    => 'XX_CS_MPS06_ERR_LOG',
                              p_error_msg             => lc_message,
                              p_object_id             => ln_party_id);
  END;

   -- Generate requests for Added or changed printers. (IP Address changes)

   BEGIN
    Device_change (X_RETURN_STATUS  => X_RETURN_STATUS,
                    X_RETURN_MSG   => X_RETURN_MSG);


    FND_FILE.PUT_LINE(FND_FILE.LOG,'IP Address change or Add  : '|| to_char(sysdate, 'mm/dd/yy hh24:mi'));
   EXCEPTION
     WHEN OTHERS THEN
           lc_message := 'error while calling Device_change : '||SQLERRM;
          log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.MAIN_PROC',
                              p_error_message_code    => 'XX_CS_MPS07_ERR_LOG',
                              p_error_msg             => lc_message,
                              p_object_id             => ln_party_id);
    END;

END IF;

    IF P_TYPE = 'TONER' THEN

      TONER_ORDER(TO_NUMBER(P_GROUP_ID));

    END IF;

  END MAIN_PROC;

/*************************************************************************/
END XX_CS_MPS_FLEET_PKG;


/