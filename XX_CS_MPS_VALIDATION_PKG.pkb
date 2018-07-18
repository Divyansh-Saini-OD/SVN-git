create or replace 
PACKAGE BODY XX_CS_MPS_VALIDATION_PKG AS
-- +=======================================================================================================+
-- |                            Office Depot - Project Simplify                                            |
-- |                                    Office Depot                                                       |
-- +=======================================================================================================+
-- | Name  : XX_CS_MPS_VALIDATION_PKG.pks                                                                  |
-- | Description  : This package contains Monitoring systems feed procedures                               |
-- |Change Record:                                                                                         |
-- |===============                                                                                        |
-- |Version    Date          Author             Remarks                                                    |
-- |=======    ==========    =================  ===========================================================|
-- |1.0        31-AUG-2012   Raj Jagarlamudi    Initial version                                            |
-- |2.0        01-JAN-2013   Raj Jagarlamudi    Modification Usage Order                                   |
-- |3.0        25-APR-2013   Raj Jagarlamudi    Added email procedure                                      |
-- |4.0        08-AUG-2013   Raj Jagarlamudi    Extended ATR email option                                  |
-- |4.0        24-JUL-2013   Arun Gannarapu     made changes to misc_supplies to initiate object type      |
-- |4.1        14-DEC-2013   Arun Gannarapu     fixed to pass org id in the submit_po method               |
-- |4.2        17-JAN-2014   Arun Gannarapu     Made changes to fix the PO price Defect 27289              |
-- |4.3        11-FEb-2014   Arun Gannarapu     Added debug messages in Manaul_order procedure             |
-- |4.4        19-FEB-2014   Arun Gannarapu     Made changes to fix the update statment in                 |
-- |                                            meter_req procedure -- defect 28322                        |
-- |4.5        19-FEB-2014   Arun Gannarapu     Fixed the compilation issues                               |
-- |4.6        26-FEB-2014   Arun Gannarapu     Made changes to pass the Task_id as orig_sys_line_ref      |
-- |                                            for usage order creation defect 28642                      |
-- |4.7        15-MAY-2014   Arun Gannarapu     Made changes to fix the ATR email issue defect 30164       |
-- |4.8        28-MAY-2014   Arun Gannarapu     Made changes to fix the defect 29694                       |
-- |4.9        29-MAY-2014   Arun Gannarapu     Made changes to fix the Color issue for COGS 28863         |
-- |                                            added the update to set the task id                        |
-- |                                            added the logic to set the total_retail_count              |
-- |5.0        09-JUN-2014   Arun Gannarapu     added a logic to generate report and attach to SR          |
-- |                                            for usage order                                            |
-- |5.1        09-JUN-2014   Arun Gannarapu     Made changes to remove the Ship site id from grouping      |
-- |                                            when the usage SR is created - defect 30485                |
-- |5.2        19-JUN-2014   Arun Gannarapu     Made changes for COGS  defect 30659                        |
-- |                                            -- Store the Supply level at shipment level for each toner |
-- |                                            -- to carryover the counts for mps retail                  |
-- |                                            -- formula change for current count calculation            |
-- |5.3        15-Jul-2014   Himanshu K         Made changes for QC 30971                                  |
-- |5.4        25-Sep-2014   Himanshu K         Bug fixes for QC 31778- procedure validate_sku updated     |
-- |                                            MARS not moving to 2nd toner option when option 1 is not   |
-- |                                            available.                                                 |
-- |5.5        22-Oct-2014   Arun Gannarapu     Made changes for QC 27312 - Automate toner request         |
-- |5.6        04-Nov-2014   Arun Gannarapu     Fixed the auto toner release issue                         |
-- |5.7        20-JAN-2015   Himanshu K         QC 33147  Fixed the MPS Light email issue                  |
-- |5.8        11-Jun-2015	 Pooja Mehra        Added a carriage return to email_send procedure to send    |
-- | 											email with body.	                                       |
-- |5.9        25-Jun-2015   Himanshu K         Code fix done for QC 34809                                 |
-- |6.0        03-Nov-2015	 Havish Kasina      Removed the schema references in the existing cdoe as per  |
-- | 											R12.2 Retrofit Changes.	                                   |
-- |6.1		   20-May-2016	Anoop Salim			Code change as part of QC 37609							   |
-- |6.2        08-Jul-2016  Suresh Naragam      Changes done for SSL/TSL Upgrade(Defect#38545)             |
-- |6.3        27-Apr-2017  Poonam Gupta        Changes for Defect#42134 - to fix stray SRs getting created|
-- |6.4        19-Jun-2017  Rohit Nanda         Changes to generate bill to in URL - Defect# 41758         |
-- +=======================================================================================================+

g_user_name    fnd_user.user_name%TYPE := 'CS_ADMIN';
g_login_id     fnd_user.user_id%TYPE   := fnd_global.login_id;
g_debug_flag   BOOLEAN;

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
     ,p_program_name            => 'XX_CS_MPS_VALIDATION_PKG'
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

  PROCEDURE log_msg(
    p_string   IN VARCHAR2)
  IS
  BEGIN
    IF (g_debug_flag )
    THEN
      fnd_file.put_line(fnd_file.LOG,  p_string);

      DBMS_OUTPUT.put_line(SUBSTR(p_string, 1, 250));

    /*  XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCS'
      ,p_program_type            => 'DEBUG'              --------index exists on program_type
      ,p_attribute15             => gc_object_name          --------index exists on attribute15
      ,p_program_name           => 'XX_CS_MPS_VALIDATION_PKG'
      ,p_program_id              => 0
      ,p_module_name             => 'MPS'                --------index exists on module_name
      ,p_error_message           => p_string
      ,p_error_message_severity  => 'LOG'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => gn_user_id
      ,p_last_updated_by         => gn_user_id
      ,p_last_update_login       => NULL --ln_login
      ); */
    END IF;
  END log_msg;

/******************************************************************************/
  -- Generate report
/*****************************************************************************/

procedure generate_report(p_request_number IN  xx_cs_mps_device_details.request_number%TYPE,
                          x_file_name      OUT VARCHAR2,
                          x_return_status  OUT VARCHAR2,
                          x_return_msg     OUT VARCHAR2)
as

lc_filehandle      UTL_FILE.file_type;
lc_timestamp       VARCHAR2 (100)  := TO_CHAR (SYSDATE, 'YYYYMMDDHH24MISS');
lc_dirpath         VARCHAR2 (2000) := 'XXOM_OUTBOUND';
lc_order_file_name VARCHAR2 (100)  := 'Usage_order_details';
lc_message         VARCHAR2 (4000);
lc_mode            VARCHAR2 (1) := 'W';


CURSOR cur_details (p_request_number IN xx_cs_mps_device_details.request_number%TYPE)
IS
select '"I"|"'
 ||a.device_id||'"|"'
 ||jtb.task_number||'"|"'
 ||black_count||'"|"'
 || color_count||'"|"'
 ||DECODE(jtb.attribute1, 'Over Usage', a.over_usage , NULL) ||'"|"'
 ||DECODE(jtb.attribute1, 'Color Over Usage',color_over_usage, NULL)||'"|"'
 ||DECODE(jtb.attribute1, 'Black',black_under_usage, NULL)||'"|"'
 ||DECODE(jtb.attribute1, 'Color',color_under_usage,NULL)||'"|"'
 ||b.black_cpc||'"|"'
 ||b.color_cpc||'"|"'
 ||b.service_cost||'"|"'
 ||b.allowances||'"|"'
 ||b.color_allowances||'"|"'
 ||b.flat_rate||'"|"'
 ||b.overage_cost||'"|"'
 ||b.color_overage_Cost||'"|"'
 || '"' msg,
 jtb.task_id
from XX_CS_MPS_DEVICE_DETAILS a,
     xx_cs_mps_device_b b,
     cs_incidents_All_b cia,
     jtf_tasks_b jtb
where a.request_number = p_request_number
and a.device_id = b.device_id
and cia.incident_number = a.request_number
and cia.incident_id  = jtb.source_object_id
and jtb.source_object_type_code = 'SR'
and supplies_label = 'USAGE'
aND   DECODE(JTB.ATTRIBUTE1, 'Black',      a.attribute1,
                             'Color',      a.color_task_id,
                             'Over Usage', a.overage_task_id,
                             'Color Over Usage' , a.color_overage_task_id)  = jtb.task_id ;


lc_header_msg  Varchar2(2000) := NULL;

BEGIN
  lc_header_msg         := NULL;
  lc_order_file_name := lc_order_file_name || '_' || lc_timestamp ||'.csv';
  LC_FILEHANDLE      := UTL_FILE.FOPEN (LC_DIRPATH, LC_ORDER_FILE_NAME, LC_MODE);

  log_msg('lc_order_file_name :'||lc_order_file_name);

  SELECT '"H"|"'
       ||'DEVICE_ID'||'"|"'
       ||'TASK_NUMBER'||'"|"'
       ||'BLACK_COUNT'||'"|"'
       ||'COLOR_COUNT'||'"|"'
       ||'OVER_USAGE'||'"|"'
       ||'COLOR_OVER_USAGE'||'"|"'
       ||'BLACK_UNDER_USAGE'||'"|"'
       ||'COLOR_UNDER_USAGE'||'"|"'
       ||'BLACK_CPC'||'"|"'
       ||'COLOR_CPC'||'"|"'
       ||'SERVICE_COST'||'"|"'
       ||'ALLOWANCE'||'"|"'
       ||'COLOR_ALLOWANCE'||'"|"'
       ||'FLAT_RATE'||'"|"'
       ||'OVERAGE_COST'||'"|"'
       ||'COLOR_OVERAGE_COST'||'"|"'
       || '"' msg
  INTO lc_header_msg
  FROM Dual;

  UTL_FILE.put_line (lc_filehandle, lc_header_msg);
  log_msg(lc_header_msg);

  FOR Cur_details_rec IN cur_details(p_request_number =>  p_request_number)
  LOOP

   log_msg(cur_details_rec.msg);
   UTL_FILE.put_line (lc_filehandle, cur_details_rec.msg);

   x_file_name := lc_order_file_name;

  END LOOP;

  UTL_FILE.FCLOSE(LC_FILEHANDLE);


  --
EXCEPTION
  WHEN OTHERS
  THEN
   fnd_file.put_line(fnd_file.log, 'Error while creating the report ..'|| SQLERRM);
   x_return_status :=  fnd_api.g_ret_sts_error;
   x_return_msg    := 'Error while creating the file ..'|| SQLERRM ;
END generate_report;

/******************************************************************************/
  -- Attach file to Service request
/*****************************************************************************/

procedure attach_document(p_file_name      IN  varchar2,
                          p_request_id     IN  cs_incidents_all_b.incident_id%TYPE,
                          p_entity_name    IN  VARCHAR2,
                          x_return_status  OUT VARCHAR2,
                          x_return_mesg    OUT VARCHAR2)
AS

  ln_media_id             NUMBER;
  lc_file_type            VARCHAR2(100) := 'text/plain';
  lc_file_path            VARCHAR2(100) := 'XXOM_OUTBOUND'; --FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
  lf_bfile                BFILE;
  lb_blob                 BLOB;
  lc_party_name           VARCHAR2(150);
  ln_rowid                ROWID;
  ln_seq_num              NUMBER := 10;
  ln_document_id          NUMBER;
  ln_category_id          NUMBER := 1;
  ln_attached_document_id NUMBER;
  ln_loop_count           NUMBER := 0;

Begin

  x_return_status := 'S';
  x_return_mesg    := NULL;

  log_msg('p_Request_Id :'|| p_request_id);
  log_msg('p_Entity_Name :'|| p_entity_name);
  log_msg('p_File_Name :'|| p_file_name);

  SELECT FND_LOBS_S.NEXTVAL INTO ln_media_id FROM DUAL;
  lf_bfile := BFILENAME (lc_file_path, p_file_name);
  DBMS_LOB.fileopen (lf_bfile, DBMS_LOB.file_readonly);

  log_msg('Media Id :'|| ln_media_id);

  BEGIN
    INSERT INTO fnd_lobs( file_id
                        , file_name
                        , file_content_type
                        , file_data
                        , upload_date
                        , program_name
                        , LANGUAGE
                        , oracle_charset
                        , file_format
                        ) VALUES
                        ( ln_media_id
                        , p_file_name
                        , lc_file_type
                        , EMPTY_BLOB()
                        , SYSDATE
                        , 'FNDATTCH'
                        , 'US'
                        , 'UTF8'
                        , 'BINARY'
                       ) RETURN file_data INTO lb_blob;

     DBMS_LOB.loadfromfile (lb_blob, lf_bfile, DBMS_LOB.getlength (lf_bfile));
     DBMS_LOB.fileclose (lf_bfile);

     log_msg('Record Inserted into fnd_lobs ..');

  EXCEPTION
    WHEN OTHERS THEN
      log_msg('WHEN OTHERS RAISED AT LOB INSERT: '||SQLERRM);
      x_return_status := fnd_api.g_ret_sts_error;
      x_return_mesg   := 'WHEN OTHERS RAISED AT LOB INSERT: '||SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_request_id
                                           , p_error_location     => 'XX_CS_MPS_VALIDATION_PKG.attach_document'
                                           , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                           , p_error_msg          => 'WHEN OTHERS RAISED AT LOB INSERT: '||SQLERRM
                                           );
  END;

   -- Attach file to sr

  IF NVL(x_return_status ,'S') = 'S'
  THEN
    BEGIN

      fnd_documents_pkg.insert_row( X_ROWID                        => ln_rowid
                                  , X_DOCUMENT_ID                  => ln_document_id
                                  , X_CREATION_DATE                => SYSDATE
                                  , X_CREATED_BY                   => fnd_global.user_id
                                  , X_LAST_UPDATE_DATE             => SYSDATE
                                  , X_LAST_UPDATED_BY              => fnd_global.user_id
                                  , X_DATATYPE_ID                  => 6 -- File
                                  , X_CATEGORY_ID                  => ln_category_id
                                  , X_SECURITY_TYPE                => 2
                                  , X_PUBLISH_FLAG                 => 'Y'
                                  , X_USAGE_TYPE                   => 'O'
                                  , X_LANGUAGE                     => 'US'
                                  , X_DESCRIPTION                  => p_file_name
                                  , X_FILE_NAME                    => p_file_name
                                  , X_MEDIA_ID                     => ln_media_id
                                  );

      log_msg('ln_document_id : '|| ln_document_id);

      SELECT fnd_attached_documents_s.NEXTVAL
      INTO ln_attached_document_id FROM DUAL;

      log_msg( ' ln_attachment document id :'|| ln_attached_document_id);

      fnd_attached_documents_pkg.insert_row( X_ROWID                        => ln_rowid
                                          , X_ATTACHED_DOCUMENT_ID         => ln_attached_document_id
                                          , X_DOCUMENT_ID                  => ln_document_id
                                          , X_CREATION_DATE                => SYSDATE
                                          , X_CREATED_BY                   => fnd_global.user_id
                                          , X_LAST_UPDATE_DATE             => SYSDATE
                                          , X_LAST_UPDATED_BY              => fnd_global.user_id
                                          , X_LAST_UPDATE_LOGIN            => fnd_global.user_id
                                          , X_SEQ_NUM                      => ln_seq_num
                                          , X_ENTITY_NAME                  => p_entity_name --'CS_INCIDENTS'
                                          , X_COLUMN1                      => NULL
                                          , X_PK1_VALUE                    => p_request_id
                                          , X_PK2_VALUE                    => NULL
                                          , X_PK3_VALUE                    => NULL
                                          , X_PK4_VALUE                    => NULL
                                          , X_CATEGORY_ID                  => ln_category_id
                                          , X_PK5_VALUE                    => NULL
                                          , X_AUTOMATICALLY_ADDED_FLAG     => 'N'
                                          , X_DATATYPE_ID                  => 6
                                          , X_SECURITY_TYPE                => 2
                                          , X_PUBLISH_FLAG                 => 'Y'
                                          , X_LANGUAGE                     => 'US'
                                          , X_DESCRIPTION                  => p_file_name
                                          , X_FILE_NAME                    => p_file_name
                                          , X_MEDIA_ID                     => ln_media_id
                                          );

      log_msg('Record inserted successfully into fnd documents ..');

    EXCEPTION
      WHEN OTHERS
      THEN
        x_return_status := fnd_api.g_ret_sts_error;
        x_return_mesg   := 'WHEN OTHERS RAISED WHLIE ATTACHING : '||SQLERRM;
        xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_request_id
                                             , p_error_location     => 'XX_CS_MPS_VALIDATION_PKG.attach_document'
                                             , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                             , p_error_msg          => 'WHEN OTHERS RAISED WHLIE ATTACHING : '||SQLERRM
                                             );

    END;

    x_return_status := fnd_api.g_ret_sts_success;
    x_return_mesg   := 'Successfully loaded data to file and attached : '||p_file_name;
  END IF;

  log_msg('x_return_msg' ||x_return_mesg);

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS RAISED : '||SQLERRM);
  x_return_status := fnd_api.g_ret_sts_error;
  x_return_mesg   := 'WHEN OTHERS RAISED : '||SQLERRM;
  log_msg('x_return_msg' ||x_return_mesg);
  xx_cs_mps_contracts_pkg.log_exception( p_object_id          => p_request_id
                                       , p_error_location     => 'XX_CS_MPS_VALIDATION_PKG.attach_document'
                                       , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                                       , p_error_msg          => 'WHEN OTHERS RAISED AT SEND FEED : '||SQLERRM
                                       );

END attach_document;
/*******************************8**********************************************/
  -- PO CREATION
/*****************************************************************************/
  PROCEDURE SUBMIT_PO ( P_PARTY_ID IN NUMBER,
                        P_REQUEST_NUMBER IN VARCHAR2,
                         P_TYPE IN VARCHAR2,
                         X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
                         X_RETURN_MSG     IN OUT NOCOPY VARCHAR2)
  IS
  CURSOR C1 IS
  select a.serial_no,
      a.ship_site_id,
      a.device_cost_center,
      b.current_count,
      a.service_cost,
     b.attribute3
  from xx_cs_mps_device_b a,
       xx_cs_mps_device_details b
  where b.serial_no = a.serial_no
  and a.party_id = p_party_id
  and b.request_number = p_request_number
  and b.supplies_label = 'USAGE'
  and b.current_count > 0
  and program_type in  (select meaning
                        from cs_lookups
                        where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                        and tag in ('BOTH', 'USAGE')
                        and end_date_active is null);

  c1_rec            c1%rowtype;
  lr_hdr_rec        XX_CS_PO_HDR_REC;
  lt_lines_tbl      XX_CS_ORDER_LINES_TBL;
  lr_line_rec       XX_CS_ORDER_LINES_REC;
  lc_party_name     varchar2(150);
  lc_item           varchar2(25);
  lc_item_descr     varchar2(150);
  ln_category       number;
  ln_inventory_id   number;
  ln_inv_org_id     number;
  lc_message        varchar2(1000);
  I                 number := 0;
  lc_err_flag       varchar2(1);
  lc_org_code       varchar2(25) := fnd_profile.value('XX_CS_MPS_PO_ORG_CODE');
  ln_incident_id    number;


  BEGIN

      lr_hdr_rec := XX_CS_PO_HDR_REC(null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);

           begin
              select party_name
              into lc_party_name
              from hz_parties
              where party_id = p_party_id;
           exception
            when others then
               null;
            end;

           begin
              SELECT   HCS.SITE_USE_ID
              INTO LR_HDR_REC.SHIP_TO
              FROM HZ_CUST_ACCOUNTS HCA
                 , HZ_CUST_SITE_USES_ALL HCS
                 , HZ_CUST_ACCT_SITES_ALL HCSA
             WHERE HCA.PARTY_ID                  = P_PARTY_ID
               AND HCA.CUST_ACCOUNT_ID           = HCSA.CUST_ACCOUNT_ID
               AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
              
               AND HCS.STATUS                    = 'A'
               AND HCS.SITE_USE_CODE             = 'BILL_TO' ;
            exception
             when others then
                 LR_HDR_REC.BILL_TO  := null;
            end;

             begin
              select cl.meaning,mt.description,
                    mt.inventory_item_id,  mv.category_id
              into lc_item, lc_item_descr, ln_inventory_id,
                    ln_category
              from cs_lookups cl,
                   mtl_system_items_b mt,
                   mtl_item_categories_v mv
              where mv.organization_id = mt.organization_id
              and mt.inventory_item_id = mv.inventory_item_id
              and  mt.segment1 = cl.meaning
              and mt.organization_id = 441
              and mv.category_set_name = 'PO CATEGORY'
              and cl.lookup_type ='XX_CS_MPS_USAGE_SKUS'
              and cl.lookup_code = p_type;
            exception
               when others then
                  lc_message := 'Error while select usage sku '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.SUMIT_PO'
                                     ,p_error_message_code =>   'XX_CS_SR01a_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => p_request_number);
           end;

          lr_hdr_rec.org_id := 404;

          BEGIN
            SELECT  B.DESCRIPTION, A.PARTY_NAME
               INTO LR_HDR_REC.ATTRIBUTE1,
                   LR_HDR_REC.ATTRIBUTE2
             FROM XX_CS_MPS_DEVICE_B A,
                  CS_LOOKUPS B
             WHERE B.MEANING = A.FLEET_SYSTEM
             AND A.PARTY_ID = P_PARTY_ID
             AND B.LOOKUP_CODE = 'VENDOR'
             AND A.FLEET_SYSTEM IS NOT NULL
             AND ROWNUM < 2;
          EXCEPTION
            WHEN OTHERS THEN
               LR_HDR_REC.ATTRIBUTE1 := 'BARRISTER GLOBAL SVCS NTWRK';
          END;

          begin
             select meaning
             into lr_hdr_rec.order_type
              from cs_lookups
              where lookup_type = 'XX_MPS_PO_LOOKUPS'
              and lookup_code = 'TYPE';
          exception
             when others then
                lr_hdr_rec.order_type := 'NA-MPS';
          end;

           begin
             select meaning
             into lr_hdr_rec.order_category
              from cs_lookups
              where lookup_type = 'XX_MPS_PO_LOOKUPS'
              and lookup_code = 'CATEGORY';
          exception
             when others then
                lr_hdr_rec.order_category := 'Non-Trade MPS';
          end;

            lr_hdr_rec.request_number := p_request_number;
            lr_hdr_rec.currency_code := 'USD';
            lr_hdr_rec.order_category := 'Non-Trade MPS';
            lr_hdr_rec.comments := p_type ||' Service charges for '||lc_party_name;

              i := 1;
              lt_lines_tbl :=  XX_CS_ORDER_LINES_TBL();

        IF p_type = 'USAGE' then

          begin
            open c1;
            loop
            fetch c1 into c1_rec;
            exit when c1%notfound;

                  lt_lines_tbl.extend;
                  lt_lines_tbl(i) :=  XX_CS_ORDER_LINES_REC(null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                       null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                       null,null,null);


                   IF lc_org_code is not null then
                    BEGIN
                      select organization_id
                      into ln_inv_org_id
                      from mtl_parameters
                      where organization_code = lc_org_code;
                     exception
                       when others then
                        null;
                    END;
                   else
                      begin
                            select organization_id
                            into ln_inv_org_id
                            from hr_all_organization_units
                            where to_number(attribute1) = c1_rec.attribute3;
                       exception
                         when others then
                            null;
                      end;
                  end if;

                  lt_lines_tbl(i).line_number   := i;
                  lt_lines_tbl(i).sku           := lc_item;
                  lt_lines_tbl(i).order_qty     := 1; --c1_rec.current_count;
                  lt_lines_tbl(i).selling_price := ROUND(nvl((c1_rec.current_count*c1_rec.service_cost),0),2); --c1_rec.service_cost;
                  lt_lines_tbl(i).uom           := 'EA';
                  lt_lines_tbl(i).item_description := 'Services for '||c1_rec.serial_no||' PageCount# '||c1_rec.current_count; --lc_item_descr;
                  lt_lines_tbl(i).attribute4 := ln_category ;
                  lt_lines_tbl(i).attribute1 := ln_inv_org_id;
                  lt_lines_tbl(i).attribute2 := ln_inventory_id;
                  lt_lines_tbl(i).attribute3 := c1_rec.ship_site_id;
                  lt_lines_tbl(i).vendor_part_number := lc_item;
                  lt_lines_tbl(i).comments := 'Monthly Usage for '||c1_rec.serial_no;
                  lt_lines_tbl(i).cost_center  := c1_rec.device_cost_center;
                  lt_lines_tbl(i).serial_number := c1_rec.serial_no;


              i := i + 1;

            end loop;
            close c1;
          end;

       else

         IF lc_org_code is not null then
            BEGIN
              select organization_id
              into ln_inv_org_id
              from mtl_parameters
              where organization_code = lc_org_code;
             exception
               when others then
                null;
            END;
         END IF;

         lc_message := 'Organization code  '||lc_org_code ||' Organization id' || ln_inv_org_id ;

         Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.SUMIT_PO'
                        ,p_error_message_code =>   'XX_CS_SR04i_ERR_LOG'
                        ,p_error_msg          =>  lc_message
                        ,p_object_id         =>   p_request_number);

              lt_lines_tbl.extend;
              lt_lines_tbl(i) :=  XX_CS_ORDER_LINES_REC(null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                       null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                       null,null,null);
              begin
                  select NVL(incident_attribute_11,0) + NVL(incident_attribute_13,0) + NVL(incident_attribute_14,0) ,
                         incident_attribute_15
                  into lt_lines_tbl(i).selling_price,
                        lt_lines_tbl(i).comments
                  from cs_incidents_all_b
                  where incident_number = p_request_number
                  AND incident_context = 'MPS PO Addl' ;
              exception
                 when others then
                    lc_err_flag := 'Y';
                    lc_message := 'Error while PO Cost  '||sqlerrm;
                    Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.SUMIT_PO'
                                     ,p_error_message_code =>   'XX_CS_SR04_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => p_request_number);
              end;


                  lt_lines_tbl(i).line_number   := 1;
                  lt_lines_tbl(i).sku           := lc_item;
                  lt_lines_tbl(i).order_qty     := 1;
                  lt_lines_tbl(i).uom           := 'EA';
                  lt_lines_tbl(i).item_description := lc_item_descr;
                  lt_lines_tbl(i).attribute1 := ln_inv_org_id;
                  lt_lines_tbl(i).attribute2 := ln_inventory_id;
                  lt_lines_tbl(i).attribute4 := ln_category ;
                  lt_lines_tbl(i).vendor_part_number := lc_item;

       end if;


       IF nvl(lc_err_flag,'N') = 'N' then
        -- Call PO creation
        BEGIN

         xx_cs_mps_po_create_pkg.create_purchase_order(x_return_status,
                                                      x_return_msg,
                                                      lr_hdr_rec,
                                                      lt_lines_tbl,
                                                      'Y');


             lc_message := 'PO Created'||x_return_status|| x_return_msg;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.SUMIT_PO'
                                     ,p_error_message_code =>   'XX_CS_SR02_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => p_request_number);
        EXCEPTION
          WHEN OTHERS THEN
             lc_message := 'Error while calling PO '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.SUMIT_PO'
                                     ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => p_request_number);
        END;

       -- Barrister call

       IF ln_incident_id is null then
         begin
           select incident_id
           into ln_incident_id
           from cs_incidents_all_b
           where incident_number = p_request_number;
         end;

        end if;

        -- Call vendor interface
        BEGIN
            XX_CS_MPS_VEN_PKG.OUTBOUND_PROC (P_INCIDENT_ID => LN_INCIDENT_ID ,
                           P_ACTION       => 'Create',
                           P_LINES_TBL    => LT_LINES_TBL,
                           P_TYPE         => 'PO',
                           P_PARTY_ID     => P_PARTY_ID,
                           P_HDR_REC      => LR_HDR_REC,
                           X_RETURN_STATUS => X_RETURN_STATUS,
                           X_RETURN_MSG   => X_RETURN_MSG );

        END;

       END IF;



  END;
/******************************************************************************
   -- Get Margin
******************************************************************************/
FUNCTION GET_MARGIN (P_SERIAL_NO IN VARCHAR2,
                      P_PARTY_ID IN NUMBER) RETURN NUMBER IS

ln_blk_total  number;
ln_cl_total   number;
ln_margin     number;
ln_ser_cost   number;
ln_toner_cost number;
lc_mps_flag   varchar2(1) := 'N';

BEGIN

       BEGIN
          SELECT 'Y'
          INTO LC_MPS_FLAG
          FROM XX_CS_MPS_DEVICE_B
          WHERE SERIAL_NO = P_SERIAL_NO
          AND PARTY_ID = P_PARTY_ID
          AND PROGRAM_TYPE IN (select meaning
                      from cs_lookups
                      where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                      and tag in ('BOTH', 'USAGE')
                      and end_date_active is null);
      EXCEPTION
         WHEN OTHERS THEN
            LC_MPS_FLAG := 'N';
            LN_MARGIN := 0;
      END;

      IF NVL(LC_MPS_FLAG,0) = 'Y' THEN

        --  toner cost
          begin
            select sum(nvl(e.po_cost,0))
            into ln_toner_cost
            from xx_cs_mps_device_details a,
                 xx_cs_mps_device_b b,
                 oe_order_headers_all c,
                oe_order_lines_all d,
                xx_om_line_attributes_all e
            where e.line_id = d.line_id
            and d.header_id = c.header_id
            and c.order_number = a.toner_order_number
            and a.serial_no = b.serial_no
            and a.supplies_label <> 'USAGE'
            and a.serial_no = p_serial_no
            and b.party_id = p_party_id;
          exception
            when others then
               ln_toner_cost := 0;
          end;

          -- Total revenue
          begin
            select (nvl(a.black_count,0) * e.black_cpc) ,
                   (nvl(a.color_count,0) * e.black_cpc) ,
                   (nvl(a.current_count,0) * nvl(e.service_cost,0))
            into ln_blk_total, ln_cl_total, ln_ser_cost
            from xx_cs_mps_device_details a,
                 xx_cs_mps_device_b e
            where e.serial_no = a.serial_no
            and e.party_id = p_party_id
            and a.supplies_label = 'USAGE'
            and a.serial_no = p_serial_no;
          exception
            when others then
               ln_blk_total := 0;
           end;
      END IF;

      ln_margin := ((ln_blk_total + ln_cl_total) - ln_toner_cost) -ln_ser_cost;

      RETURN LN_MARGIN;
END;
/************************************************************************
 -- SKU Validation
*************************************************************************/
PROCEDURE VALIDATE_SKU (P_ZIP_CODE  IN VARCHAR2,
                        P_SKU       IN VARCHAR2,
                        P_BILL_TO   IN VARCHAR2,     --ADDED BY ROHIT NANDA ON 19-JUN-2017 DEFECT# 41758
                        X_WAREHOUSE IN OUT VARCHAR2,
                        X_STATUS    IN OUT NOCOPY VARCHAR2)
IS

soap_request      VARCHAR2(30000);
soap_respond      VARCHAR2(30000);
x_resp            XMLTYPE;
req               utl_http.req;
resp              utl_http.resp;
l_url             varchar2 (2000) :=  FND_PROFILE.VALUE('XX_MPS_SKU_VAL_URL');  --  USER_PROFILE_OPTION_NAME = OD : MPS SKU Validation Link
l_msg_data        varchar2(2000);
ln_quantity       number := 0;
--'https://b2bwmvendors.officedepot.com/rest/ODServices/sku/inventory?';
--https://b2bwmvendors.officedepot.com/rest/ODServices/api/product/inventory? (As on 14th Feb'18)
--https://b2bwmtest.officedepot.com/rest/ODServices/api/product/inventory?(Changed by Muthu on 15th Feb'18 as per mail converation with Douglas Caselle)
l_wallet_location     VARCHAR2(256)   := NULL;
l_password            VARCHAR2(256)   := NULL;
BEGIN
     -- Changes for SSL/TSL Upgrade Start
--log_msg('Validate SKU Proc Begins: Changes for SSL/TSL Upgrade Start..');
        BEGIN
          SELECT
             TARGET_VALUE1
            ,TARGET_VALUE2
            into
            l_wallet_location
           ,l_password
          FROM XX_FIN_TRANSLATEVALUES     VAL,
               XX_FIN_TRANSLATEDEFINITION DEF
          WHERE 1=1
          and   DEF.TRANSLATE_ID = VAL.TRANSLATE_ID
          and   DEF.TRANSLATION_NAME='XX_CS_MPS_WALLET_CONFIG'
        
          and   VAL.SOURCE_VALUE1 = 'MPS_WALLET_LOCATION'
          and   VAL.ENABLED_FLAG = 'Y'
          and   SYSDATE between VAL.START_DATE_ACTIVE and nvl(VAL.END_DATE_ACTIVE, SYSDATE+1);
          
          EXCEPTION WHEN OTHERS THEN
          log_msg( 'XX_CS_MPS_VALIDATION_PKG.VALIDATE_SKU -- Wallet Location Not Found' );
          l_wallet_location := NULL;
          l_password := NULL;
        END;
        IF l_wallet_location IS NOT NULL THEN
          UTL_HTTP.SET_WALLET(l_wallet_location,l_password);
        END IF;
log_msg('============Begin of validate SKU Procedure =====================');
		log_msg('wallet location check..'||l_wallet_location);
        log_msg('wallet location Password..'||l_password);
        -- Changes for SSL/TSL Upgrade End
	
     l_url := l_url||'zipcode='||p_zip_code||'&'||'sku='||p_sku;      --QC 31778 MARS not moving to 2nd toner option when option 1 is not available.
     l_url := l_url||'&'||'billto='||p_bill_to;                            --ADDED BY ROHIT NANDA ON 19-JUN-2017 DEFECT# 41758
log_msg( 'Url for validate sku inventory '||l_url);
BEGIN
	log_msg('Begin Request to POST the URL...');
    req := utl_http.begin_request(l_url,'POST','HTTP/1.1'); 
  -- For the Defects 41758 / 42134 - Changed from Action from 'POST' to 'GET' ON 15-FEB-18
	--fnd_file.put_line(fnd_file.LOG,'log_message added for utl_http.begin_request'||req );
  utl_http.set_header(req,'Content-Type', 'text/xml'); --; charset=utf-8');
  fnd_file.put_line(fnd_file.LOG,'log_message added for utl_http.set_header Content-Type' );
    utl_http.set_header(req  , 'SOAPAction'  , 'process');
    fnd_file.put_line(fnd_file.LOG,'log_message added for utl_http.set_header SOAPAction' );
    resp := utl_http.get_response(req);
	log_msg('Get Response... '||resp.status_code);
	--DBMS_OUTPUT.PUT_LINE('HTTP response status code: ' || resp.status_code);
	utl_http.read_text(resp, soap_respond);
	log_msg('soap Response... '||soap_respond);
	utl_http.end_response(resp);
	x_resp := XMLType.createXML(soap_respond);
	--log_msg('XMLType.createXML... '||x_resp.getClobVal());
exception
	when others then
	--log_msg('Error in URL -->'||req);
     log_msg('Error in URL  / SOAP pick...'|| SQLERRM);
	--LOG_MSG('Detailed Error in URL / SOAP pick...'||utl_http.Get_Detailed_Sqlerrm);
END;
	l_msg_data := 'Response Received '||resp.status_code;


-- log_msg('Line1 Set Header');
--log_msg('Line 2.. response UTL_HTTP');
--log_msg('Line end.. End UTL_HTTP');
--log_msg('Start of Line soap_respond.. ');
--log_msg('end of Line x_resp.. ');



/*   <ODInventoryResponse>
        <zipcode>08037</zipcode>
        <sku>646557</sku>
        <quantity>98</quantity>
        <inventoryLoc>5910</inventoryLoc>
        <diffTime>156</diffTime>
      </ODInventoryResponse>
 */
     begin
	                    log_msg ('++++Value pick for warehouse  and quantity++++');
       x_warehouse := x_resp.EXTRACT('/ODInventoryResponse/inventoryLoc/text()').getstringval();
       ln_quantity := to_number(x_resp.EXTRACT('/ODInventoryResponse/quantity/text()').getstringval());  --QC 31778 MARS not moving to 2nd toner option when option 1 is not available.
                    log_msg('Value assigned for warehouse...'||x_warehouse);
                     log_msg('Value assigned for quantity...'||ln_quantity);
     exception
       when others then
         LOG_MSG(' Error in aquntity value assignment... '||SQLERRM);
         ln_quantity := 0; --QC 31778 MARS not moving to 2nd toner option when option 1 is not available.
         x_warehouse := null;
         l_msg_data := x_resp.EXTRACT('/ODInventoryResponse/Error/Description').getstringval();
         l_msg_data := 'ZIP Code:'||p_zip_code||' sku:'||p_sku;
		 --l_msg_data := utl_http.begin_request(l_url,'POST','HTTP/1.2');
         Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.VALIDATE_SKU'
                  ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                  ,p_error_msg          =>  L_MSG_DATA
                  ,p_object_id         => P_SKU);
      end;

   -- dbms_output.put_line('Warehouse '||x_warehouse);
--log_msg(x_status);
--log_msg('Qty:'|| ln_quantity);
--log_msg('uRL Log:'||l_url);

    IF ln_quantity > 0 then
      x_status := 'S';
    else
      x_status := 'F';
    end if;
END;

/************************************************************************************************
  -- Update retail Cnt
************************************************************************************************/
 PROCEDURE UPDATE_RETAIL_CNT(P_PARTY_ID IN NUMBER) IS

  CURSOR C1_CUR IS
  select cd.serial_no,
         nvl(total_black_count,0) black_count,
         nvl(total_color_count,0) color_count,
         NVL(CB.LEVEL_LIMIT,20) level_limit
  from xx_cs_mps_device_details cd,
       xx_cs_mps_device_b cb
  where cd.serial_no = cb.serial_no
  and cd.supplies_label = 'USAGE'
  and cb.party_id = nvl(p_party_id,cb.party_id)
  and cb.program_type in (select meaning
                        from cs_lookups
                        where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                        and tag in ('BOTH', 'USAGE')
                        and end_date_active is null);

  c1_rec                 c1_cur%rowtype;
  ln_color_cnt           number;
  ln_color_level         number;

  ln_prev_color_cnt      number;
  ln_changed_level       NUMBER;
  ln_total_changed_level NUMBER;
  CURSOR c2 (p_serial_no IN xx_cs_mps_device_details.serial_no%TYPE)
  IS
  SELECT To_number(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(REPLACE(SUPPLIES_LEVEL,'%',NULL), 'n/a', null), 'OK', null),
                  'LOW' , Null), 'Ok', null), 'Error', NULL), 'Warning', null), 'Critical',Null),1)) current_supplies_level,
          NVL(prev_shipment_level,99) prev_shipment_level,
         To_number(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(REPLACE(previous_level,'%',NULL), 'n/a', null), 'OK', null),
                  'LOW' , Null), 'Ok', null), 'Error', NULL), 'Warning', null),'Critical',NULL),0)) prev_supplies_level,
          supplies_label
  FROM xx_cs_mps_device_details
  WHERE serial_no = p_serial_no
  AND  supplies_label not in ('USAGE','TONERLEVEL_BLACK')
  ;

  BEGIN
     BEGIN
       open c1_cur;
       loop
       fetch c1_cur into c1_rec;
       exit when c1_cur%notfound;

       ln_color_cnt := 0;

       log_msg('Updating counts for Serial '|| c1_rec.serial_no);

       log_msg(' Updating current count for Black Toner : total_black_count :' ||c1_rec.black_count ||' Previous black count');
       BEGIN
         update xx_cs_mps_device_details
         set current_count       = (c1_rec.black_count - nvl(previous_black_count,0))
         where serial_no         = c1_rec.serial_no
         and supplies_label      = 'TONERLEVEL_BLACK';
       EXCEPTION
         WHEN OTHERS THEN
           fnd_file.put_line(fnd_file.log,'Error while updating black count for serial No '||c1_rec.serial_no||' : '||sqlerrm);
       END;

       -- COLOR COUNT
       IF C1_REC.COLOR_COUNT > 0
       THEN
         log_msg(' Updating current count for color Toner : total_color_count :' ||c1_rec.color_count );

         BEGIN
           SELECT NVL(previous_color_count,0)
           INTO ln_prev_color_cnt
           FROM xx_cs_mps_device_details
           WHERE serial_no = c1_rec.serial_no
           AND supplies_label = 'TONERLEVEL_BLACK';
         EXCEPTION
           WHEN OTHERS
           THEN
             ln_prev_color_cnt := 0;
          END;

          log_msg('Previous color count :'|| ln_prev_color_cnt);

          ln_color_cnt := (c1_rec.color_count - ln_prev_color_cnt);

          log_msg('ln_color_cnt :'|| ln_color_cnt);

          log_msg('Level Limit :'|| c1_rec.level_limit);


          ln_changed_level := 0;
          ln_total_changed_level  := 0;

          FOR c2_rec IN C2 (c1_rec.serial_no)
          LOOP
           BEGIN

            log_msg(' Toner :'|| c2_rec.supplies_label ||' Prev shipment level :'||
                    c2_rec.prev_shipment_level ||' current level :'|| c2_rec.current_supplies_level);

            IF (c2_rec.prev_shipment_level - c2_rec.current_supplies_level) < 0
            THEN
              ln_changed_level := (100 - c2_rec.current_supplies_level) + c2_rec.prev_shipment_level ;

           -- ELSIF ((c2_rec.prev_shipment_level - c2_rec.current_supplies_level) = 0)
           -- THEN
           --  ln_changed_level := 100;

            ELSIF ( c2_rec.current_supplies_level < c2_rec.prev_supplies_level) AND
                   (c2_rec.prev_supplies_level >= c2_rec.prev_shipment_level) AND
                  ( c2_rec.prev_shipment_level <= c1_rec.level_limit )
            THEN
              ln_changed_level := 100 + (c2_rec.prev_shipment_level - c2_rec.current_supplies_level);
            ELSE
              ln_changed_level := c2_rec.prev_shipment_level - c2_rec.current_supplies_level;
            END IF;

            log_msg( 'ln_changed_level :' || ln_changed_level);

            ln_total_changed_level := ln_total_changed_level + ln_changed_level ;

            log_msg( 'ln_total_changed_level :' || ln_total_changed_level);

           EXCEPTION
             WHEN OTHERS
             THEN
              log_msg('Error While calculating the change level' || SQLERRM);
           END;
          END LOOP;

          ln_changed_level := 0;

          FOR c2_rec IN c2(c1_rec.serial_no)
          LOOP

            BEGIN
              log_msg( 'Processing for Toner :'||c2_rec.supplies_label );
               ln_changed_level := 0;

              IF (c2_rec.prev_shipment_level - c2_rec.current_supplies_level) < 0
              THEN
                ln_changed_level := (100 - c2_rec.current_supplies_level) + c2_rec.prev_shipment_level ;

              --ELSIF (c2_rec.prev_shipment_level - c2_rec.current_supplies_level) = 0
              --THEN
              --  ln_changed_level := 100;

               
              ELSIF (c2_rec.current_supplies_level < c2_rec.prev_supplies_level) AND (c2_rec.prev_supplies_level >= c2_rec.prev_shipment_level ) AND
                  ( c2_rec.prev_shipment_level <= c1_rec.level_limit )
              THEN
 ln_changed_level := 100 + (c2_rec.prev_shipment_level - c2_rec.current_supplies_level);
              ELSE
                ln_changed_level := c2_rec.prev_shipment_level - c2_rec.current_supplies_level;
              END IF;

              log_msg( 'ln_changed_level :' || ln_changed_level);

              UPDATE xx_cs_mps_device_details
              SET    current_count = ROUND(ln_color_cnt *ln_changed_level/ln_total_changed_level)
              WHERE serial_no      = c1_rec.serial_no
              AND supplies_label   = c2_rec.supplies_label;

            EXCEPTION
             WHEN OTHERS
             THEN
               log_msg('Error While calculating the change level to update the current count' || SQLERRM);

            END;
          END LOOP;
        END IF;
       commit;
      end loop;
       close c1_cur;
     END;
  END;

/************************************************************************
-- Send Email for Call In type
************************************************************************/
PROCEDURE email_send (x_return_status in out nocopy varchar2 ,
                      x_return_msg in out nocopy varchar2)
AS
  mailhost VARCHAR2 (100) := fnd_profile.value('XX_CS_SMTP_SERVER');
  mail_conn UTL_SMTP.connection;

cursor party_cur is
select distinct mb.party_id,
       mb.party_name,
       mb.attribute2,
       mb.aops_cust_number
from xx_cs_mps_device_b mb,
     xx_cs_mps_device_details md
where mb.serial_no = md.serial_no
and  mb.program_type in (select meaning  from cs_lookups
                          where lookup_type = 'XX_MPS_LIGHT_TYPES'
                          and end_date_active is null)
and  To_number(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(REPLACE(SUPPLIES_LEVEL,'%',NULL), 'n/a', null), 'OK', null),
'LOW' , Null), 'Ok', null), 'Error', NULL), 'Warning', null), 'Critical', NULL),'.',988),999)) <= NVL(MB.LEVEL_LIMIT,20)
and nvl(md.toner_order_date,sysdate-10) < sysdate - 7
and NVL(md.device_status,'N') <> 'Stale'
and md.request_number is null
and upper(md.supplies_label) like '%TONER%'
and mb.party_id is not null;

party_rec party_cur%rowtype;

cursor det_cur is
select distinct mb.device_location,
       mb.device_contact,
       mb.device_phone,
       mb.model model_name,
       mb.serial_no,
       md.supplies_label,
       replace(md.supplies_label,'TONERLEVEL_','') label,
       md.supplies_level,
       md.sku_option_1,
       mb.mps_rep_comments
from xx_cs_mps_device_b mb,
     xx_cs_mps_device_details md
where mb.serial_no = md.serial_no
--and  TO_NUMBER(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUPPLIES_LEVEL,'%',NULL),'n/a',null),'OK',null),'LOW',NULL),999))
AND  To_number(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(REPLACE(SUPPLIES_LEVEL,'%',NULL), 'n/a', null), 'OK', null),
               'LOW' , Null), 'Ok', null), 'Error', NULL), 'Warning', null), 'Critical',NULL),'.',988),999)) <= NVL(MB.LEVEL_LIMIT,20)
and nvl(md.toner_order_date,sysdate-10) < sysdate - 7
and  mb.program_type in (select meaning  from cs_lookups
                          where lookup_type = 'XX_MPS_LIGHT_TYPES'
                          and end_date_active is null)  -- QC 30971 Checking if program type is set before sending an email.
and NVL(md.device_status,'N') <> 'Stale'
and md.request_number is null
and upper(md.supplies_label) like '%TONER%'
and mb.party_id = party_rec.party_id;

DET_REC DET_CUR%ROWTYPE;
ln_party_id   number;
lc_serial_no  varchar2(50);
I             number := 0;
l_fun_url     varchar2(100) := 'https://business.officedepot.com/';
v_message    varchar2(32000);

BEGIN

  BEGIN
  OPEN PARTY_CUR;
  LOOP
  FETCH PARTY_CUR INTO PARTY_REC;
  EXIT WHEN PARTY_CUR%NOTFOUND;
   ln_party_id := party_rec.party_id;
   I:= 0;
   v_message:='';   --Added to fix email issue QC 33147


  IF PARTY_REC.PARTY_ID IS NOT NULL AND
     PARTY_REC.ATTRIBUTE2 IS NOT NULL THEN

    mail_conn   := UTL_SMTP.open_connection (mailhost);
    UTL_SMTP.helo (mail_conn, mailhost);
    UTL_SMTP.mail (mail_conn, 'noreply@officedepot.com');
    UTL_SMTP.rcpt (mail_conn, party_rec.attribute2);
    UTL_SMTP.open_data (mail_conn);
    UTL_SMTP.write_data (mail_conn, 'From:' || 'noreply@officedepot.com' || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, 'To:' || party_rec.attribute2 || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, 'Subject:' || 'Toner Order Requests for ' || party_rec.party_name || ' Account : '||party_rec.aops_cust_number||UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, 'MIME-version: 1.0' || UTL_TCP.crlf);

    UTL_SMTP.write_data (mail_conn, 'Content-Type: text/html' ||
    utl_tcp.CRLF||'<content="MSHTML 6.00.2800.1276" name=GENERATOR>'||utl_tcp.CRLF||utl_tcp.CRLF||'<HTML><BODY>');


    -- Device cur
    BEGIN
      OPEN DET_CUR;
      LOOP
      FETCH DET_CUR INTO DET_REC;
      EXIT WHEN DET_CUR%NOTFOUND;

        lc_serial_no := det_rec.serial_no;

         I := I + 1;

       IF I = 1 then
               v_message:='<center><h3><i><font color=#000099>List of Supplies and their levels </font></i></h3></center>'||UTL_TCP.crlf;
               v_message:=v_message||'<table style="border: solid 0px #cccccc"  cellspacing="4" cellpadding="4"><tr BGCOLOR=#000099>';
               v_message:=v_message||'<td><b><font color=white>Location</font></td>';
               v_message:=v_message||'<td><b><font color=white>Contact</font></td>';
               v_message:=v_message||'<td><b><font color=white>Phone No</font></td>';
               v_message:=v_message||'<td><b><font color=white>Model</font></td>';
               v_message:=v_message||'<td><b><font color=white>Serial</font></td>';
               v_message:=v_message||'<td><b><font color=white>Label</font></td>';
               v_message:=v_message||'<td><b><font color=white>Level</font></td>';
               v_message:=v_message||'<td><b><font color=white>SKU</font></td>';
                v_message:=v_message||'<td><b><font color=white>MPS Rep Comments</font></td></tr>';
         END IF;


          --dbms_output.put_line('LOCATION '||DET_REC.DEVICE_LOCATION);

          v_message:=v_message||'<tr><td>'||det_rec.device_location||
                                '</td><td>'||det_rec.device_contact||
                                '</td><td>'||det_rec.device_Phone||
                                '</td><td>'||det_rec.Model_name||
                                '</td><td>'||det_rec.Serial_no||
                                '</td><td>'||det_rec.Label||
                                '</td><td>'||det_rec.supplies_Level||
                                '</td><td>'||det_rec.sku_option_1||
                                '</td><td>'||det_rec.mps_rep_comments||'</td></tr>';

          begin
            update xx_cs_mps_device_details
            set request_number = 'Email_Sent',
                toner_order_number = 1
            where serial_no = det_rec.serial_no
            and supplies_label = det_rec.supplies_label;

            commit;
          exception
            when others then
              x_return_msg := 'Error while updating : ' || SQLERRM;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.EMAIL_SEND'
                            ,p_error_message_code =>   'XX_CS_SR02c_ERR_LOG'
                            ,p_error_msg          =>  x_return_msg
                            ,p_object_id         => det_rec.serial_No);
          end;

      end loop;
      close det_cur;
      exception
        when others then
          x_return_msg := 'The following error has occured: ' || SQLERRM;
          Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.EMAIL_SEND'
                        ,p_error_message_code =>   'XX_CS_SR01a_ERR_LOG'
                        ,p_error_msg          =>  x_return_msg
                        ,p_object_id         => lc_serial_no);
      end;

     v_message:=v_message||'</table>'||utl_tcp.CRLF;
     v_message:=v_message||'<BR>';
     v_message:=v_message||'<BR>';
     v_message:=v_message||'<B><font color="#CC0000" FONT FACE="Arial" size="2" ><B> Please place orders at <a href="'|| l_fun_url || ' ">Click here </a><B></font>';
     v_message:=v_message||'<BR>';
     v_message:=v_message||'<BR>';
     v_message:=v_message||'<BR>';
     v_message:=v_message||'<B><font color="#CC0000" FONT FACE="Arial" size="4" ><B> Office Depot MPS Services <B></font>'||UTL_TCP.crlf;
     v_message:=v_message||'</BODY></HTML>'||utl_tcp.CRLF;

    IF I > 0 THEN
      UTL_SMTP.write_data (mail_conn, v_message);
      UTL_SMTP.close_data (mail_conn);
      UTL_SMTP.quit (mail_conn);
    END IF;

  END IF;
  END LOOP;
  CLOSE PARTY_CUR;
  EXCEPTION
    WHEN OTHERS THEN
      x_return_msg := 'The following error has occured: ' || SQLERRM;
      Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.EMAIL_SEND'
                    ,p_error_message_code =>   'XX_CS_SR02a_ERR_LOG'
                    ,p_error_msg          =>  x_return_msg
                    ,p_object_id         => ln_party_id);
  END;

EXCEPTION
WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error THEN
  UTL_SMTP.quit (mail_conn);
  x_return_msg := 'Failed to send mail due to the following error: ' || SQLERRM;
  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.EMAIL_SEND'
                  ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                  ,p_error_msg          =>  x_return_msg
                  ,p_object_id         => NULL);
WHEN OTHERS THEN
  x_return_msg := 'The following error has occured: ' || SQLERRM;
                 
    Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.EMAIL_SEND'
                  ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                  ,p_error_msg          =>  x_return_msg
                   ,p_object_id         => NULL);
END EMAIL_SEND ;
/************************************************************************************
  -- Misc Supplies
**************************************************************************************/
  PROCEDURE MISC_SUPPLIES(P_PARTY_ID       IN NUMBER,
                          X_RETURN_STATUS   IN OUT VARCHAR2,
                          X_RETURN_MSG      IN OUT VARCHAR2) AS

  cursor sup_cur is
  select distinct cb.party_id
  from xx_cs_mps_device_supplies cd,
       xx_cs_mps_device_b cb
  WHERE CB.DEVICE_ID = CD.DEVICE_ID
  --AND TO_NUMBER(NVL(REPLACE(REPLACE(REPLACE(CD.SUPPLIES_LEVEL,'%',NULL),'n/a',null),'OK',null),999))
  AND To_number(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CD.SUPPLIES_LEVEL,'%',NULL), 'n/a', null), 'OK', null),
                                 'LOW' , Null), 'Ok', null), 'Error', NULL), 'Warning', null),'Critical', NULL),'.',988),999))  <= NVL(CB.LEVEL_LIMIT,20)
  and cd.attribute1 is null
  and cb.party_id = nvl(p_party_id, cb.party_id);

lc_request_type   varchar2(50) := 'MPS Supplies Request';
ln_type_id        number;
lc_comments       varchar2(1000);
lc_summary        varchar2(250);
lr_request_rec     xx_cs_sr_rec_type;
lr_sr_notes_rec    XX_CS_SR_NOTES_REC;
ln_user_id        number;
lc_message        varchar2(1000);
ln_request_id     number;
lc_request_number varchar2(25);
LN_OWNER_ID         number;
LN_GROUP_ID         number;
Ln_STATUS_ID        number;
LC_STATUS           varchar2(150);
LN_OBJ_VER          NUMBER;
LC_NOTES            varchar2(2000);
LC_ITEM_DESCR       VARCHAR2(150);


sup_rec   sup_cur%rowtype;

cursor sup_det is
  select distinct cb.party_id,
        cb.serial_no,
        cb.device_location,
        cb.device_contact,
        cb.device_phone,
        cb.model,
        cb.ip_address,
        cb.level_limit,
        cd.supplies_label
  from xx_cs_mps_device_supplies cd,
       xx_cs_mps_device_b cb
  WHERE CB.SERIAL_NO = CD.SERIAL_NUMBER
 -- AND TO_NUMBER(NVL(REPLACE(REPLACE(REPLACE(CD.SUPPLIES_LEVEL,'%',NULL),'n/a',null),'OK',null),999))
  AND To_number(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CD.SUPPLIES_LEVEL,'%',NULL), 'n/a', null), 'OK', null),
          'LOW' , Null), 'Ok', null), 'Error', NULL), 'Warning', null),'Critical', NULL),'.',988), 999)) <= NVL(CB.LEVEL_LIMIT,20)
  and cd.attribute1 is null
  and cb.party_id = sup_rec.party_id;

sup_det_rec sup_det%rowtype;

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

      begin
      select incident_type_id
      into ln_type_id
      from cs_incident_types_tl
      where name = lc_request_type;
    exception
      when others then
        null;
    end;

  BEGIN
    open sup_cur;
    loop
    fetch sup_cur into sup_rec;
    exit when sup_cur%notfound;

     begin
        lr_request_rec.type_id := ln_type_id;
        lc_comments     := 'Misc Supply Request Created ';
        lc_summary      := 'Misc Supply Request Created ';
         -- Assign values to rec type
        lr_request_rec.status_name       := 'Open';
        lr_request_rec.description       := lc_summary;
        lr_request_rec.caller_type       := 'MPS Program';
        lr_request_rec.customer_id       := sup_rec.party_id;
        lr_request_rec.user_id           := ln_user_id;
        lr_request_rec.channel           := 'WEB'; -- setup
        lr_request_rec.comments          := lc_comments;

    exception
      when others then
         lc_message := 'Error at record type '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.MISC_SUPPLIES'
                                 ,p_error_message_code =>   'XX_CS_SR10_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
    end;


     XX_CS_MPS_UTILITIES_PKG.CREATE_SR
              (P_PARTY_ID        => sup_rec.party_id,
                P_SALES_NUMBER   => null,
                P_REQUEST_TYPE   => lc_request_type,
                P_COMMENTS       => lc_comments,

                p_sr_req_rec     => lr_request_rec,
                x_return_status  => x_return_status,
                X_RETURN_MSG     => x_return_msg);
       --   dbms_output.put_line('Status '||x_return_status||' '||x_return_msg||'no '||lr_request_rec.request_number);

      IF nvl(x_return_status,'S') = 'S' then

        -- Create Note
          ln_request_id     := lr_request_rec.request_id;
          lc_request_number := lr_request_rec.request_number;

          -- Open Details cursor
      begin
        open sup_det;
        loop
        fetch sup_det into sup_det_rec;
        exit when sup_det%notfound;

        lr_sr_notes_rec := XX_CS_SR_NOTES_REC(NULL,NULL,NULL,NULL);

        lr_sr_notes_rec.notes := sup_det_rec.serial_no;
        lr_sr_notes_rec.note_details := sup_det_rec.supplies_label||' required. ';

        BEGIN
          XX_CS_MPS_UTILITIES_PKG.CREATE_NOTE (p_request_id   => ln_request_id,
                                               p_sr_notes_rec => lr_sr_notes_rec,
                                               p_return_status => x_return_status,
                                               p_msg_data => x_return_msg);

          EXCEPTION
            WHEN OTHERS THEN
              lc_message := 'Error while calling notes '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.MISC_SUPPLIES'
                                 ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
          END;

        -- dbms_output.put_line(' Status  ' || x_return_msg);

           -- Update request number
         begin
           update xx_cs_mps_device_supplies
           set attribute1 = lc_request_number
           where serial_number = sup_det_rec.serial_no
           and supplies_label = sup_det_rec.supplies_label;
         end;

          end loop;
        CLOSE SUP_DET;
        EXCEPTION
         WHEN OTHERS THEN
            lc_message := 'Error at cursor '||sqlerrm;
              Log_Exception ( p_error_location     =>   'XX_CS_MPS_VALIDATION_PKG.MISC_SUPPLIES'
                                 ,p_error_message_code =>   'XX_CS_SR11_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
      end;



      else
           LC_MESSAGE := 'Error while calling SR create API '||x_return_status||' '||x_return_msg;
                     log_exception (p_error_location        =>  'XX_CS_MPS_VALIDATION_PKG.MISC_SUPPLIES',
                                    p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                                    P_ERROR_MSG             => LC_MESSAGE,
                                    p_object_id             => sup_rec.party_id);

      end if;

    end loop;
    commit;
    CLOSE SUP_CUR;
    exception
    WHEN OTHERS THEN
        lc_message := 'Error at cursor '||sqlerrm;
              Log_Exception ( p_error_location     =>   'XX_CS_MPS_VALIDATION_PKG.MISC_SUPPLIES'
                                 ,p_error_message_code =>   'XX_CS_SR12_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
 END;
END MISC_SUPPLIES;

/*************************************************************************************/
-- Create task
 /**************************************************************************************/

  PROCEDURE CREATE_TASK
  ( p_task_name          IN  VARCHAR2
  , p_task_type_id       IN  NUMBER
  , p_status_id          IN  NUMBER
  , p_priority_id        IN  NUMBER
  , p_Planned_Start_date IN  DATE
  , p_planned_effort     IN  NUMBER
  , p_planned_effort_uom IN VARCHAR2
  , p_notes              IN VARCHAR2
  , p_source_object_id   IN NUMBER
  , x_error_id           OUT NOCOPY NUMBER
  , x_error              OUT NOCOPY VARCHAR2
  , x_new_task_id        OUT NOCOPY NUMBER
  , p_note_type          IN  VARCHAR2
  , p_note_status        IN VARCHAR2
  , p_Planned_End_date   IN  DATE
  , p_owner_id           IN NUMBER
  , p_attribute_1           IN VARCHAR2
  , p_attribute_2           IN VARCHAR2
  , p_attribute_3           IN VARCHAR2
  , p_attribute_4           IN VARCHAR2
  , p_attribute_5           IN VARCHAR2
  , p_attribute_6           IN VARCHAR2
  , p_attribute_7           IN VARCHAR2
  , p_attribute_8           IN VARCHAR2
  , p_attribute_9           IN VARCHAR2
  , p_attribute_10         IN VARCHAR2
  , p_attribute_11         IN VARCHAR2
  , p_attribute_12         IN VARCHAR2
  , p_attribute_13         IN VARCHAR2
  , p_attribute_14         IN VARCHAR2
  , p_attribute_15         IN VARCHAR2
  , p_context                 IN VARCHAR2

  , p_assignee_id        IN NUMBER
  , p_template_id        IN NUMBER
) IS
l_task_type_name      varchar2(250);
l_return_status       varchar2(1);
l_msg_count           number;
l_msg_data            varchar2(2000);

l_data                varchar2(200);
l_task_notes_rec      jtf_tasks_pub.task_notes_rec;
l_task_notes_tbl      jtf_tasks_pub.task_notes_tbl;
l_msg_index_out       number;

l_resource_id         number;
l_resource_type       varchar2(30);
l_assign_by_id        number;
l_scheduled_start_date DATE;
l_scheduled_end_date   DATE;
l_incident_number     VARCHAR2(64);
l_organization_id     NUMBER;
l_note_type           varchar2(30);
l_note_status         varchar2(1);
l_user_id             number;
ln_resp_appl_id       number := 514;
ln_resp_id            number := 21739;
l_task_descr          varchar2(250);
ln_script_id          number;
I                     number;

CURSOR c_task_type (v_task_type_id NUMBER)
IS
Select name
  from jtf_task_types_vl
 where TASK_TYPE_ID = v_task_type_id;

CURSOR c_resource_type (p_owner_id NUMBER)
IS
select resource_type
  from jtf_rs_resources_vl
 where resource_id = p_owner_id
 and end_date_active is null;

CURSOR c_incident_number (v_incident_id NUMBER)
IS
Select incident_number,tier,
       INSTALL_SITE_ID
  from cs_incidents_all
 where incident_id = v_incident_id ;

 r_incident_record c_incident_number%ROWTYPE;

BEGIN

-- get the task type name
open c_task_type(p_task_type_id);
fetch c_task_type into l_task_type_name;
close c_task_type;

    begin
      select user_id
      into l_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
    end;

-- SR number
open c_incident_number (p_source_object_id);
fetch c_incident_number into r_incident_record;
close c_incident_number;
l_incident_number := r_incident_record.incident_number;
ln_script_id      := r_incident_record.tier;

--notes
    If p_notes <> '$$#@'
    then
        If p_note_type is null then
           l_note_type := 'GENERAL';
        else
           l_note_type := p_note_type;
        end if;

        If p_note_status is null then
           l_note_status := 'I';
        else
           l_note_status := p_note_status;
        end if;

      l_task_notes_rec.notes                  := p_notes;
      l_task_notes_rec.note_status          := l_note_status;
      l_task_notes_rec.entered_by            := FND_GLOBAL.user_id;
      l_task_notes_rec.entered_date          := sysdate;
      l_task_notes_rec.note_type          := l_note_type;
      I                                   := 1;
      l_task_notes_tbl (I)                := l_task_notes_rec;
      l_task_descr                        := substr(p_notes,1,250);


    else
      l_task_notes_tbl := jtf_tasks_pub.g_miss_task_notes_tbl;
    end if;

    l_assign_by_id := p_assignee_id;

-- resource type
open c_resource_type (p_owner_id);
fetch c_resource_type into l_resource_type;
close c_resource_type;


      FND_GLOBAL.APPS_INITIALIZE(L_USER_ID,ln_resp_id,ln_resp_appl_id);

        -- Lets call the API
      jtf_tasks_pub.create_task (
          p_api_version             => 1.0,
          p_commit                  => fnd_api.g_true,
          p_task_name               => p_task_name,
          p_task_type_name          => l_task_type_name,
          p_task_type_id            => p_task_type_id,
          p_description             => l_task_descr,
          p_task_status_name        => null,
          p_task_status_id          => p_status_id,
          p_task_priority_name      => null,
          p_task_priority_id        => p_priority_id,
          p_owner_type_name         => Null,
          p_owner_type_code         => l_resource_type,
          p_owner_id                => p_owner_id,
          p_owner_territory_id      => null,
          p_assigned_by_name        => NULL,
          p_assigned_by_id          => l_assign_by_id,
          p_customer_number         => null,
          p_customer_id             => null,
          p_cust_account_number     => null,
          p_cust_account_id         => null,
          p_address_id              => r_incident_record.INSTALL_SITE_ID,
          p_planned_start_date      => p_Planned_Start_date,
          p_planned_end_date        => p_Planned_End_date,
          p_scheduled_start_date    => l_scheduled_start_date,
          p_scheduled_end_date      => l_scheduled_end_date,
          p_actual_start_date       => NULL,
          p_actual_end_date         => NULL,
          p_timezone_id             => NULL,
          p_timezone_name           => NULL,
          p_duration                => null,
          p_source_object_type_code => 'SR',
          p_source_object_id        => p_source_object_id,
          p_source_object_name      => l_incident_number,
          p_duration_uom            => null,
          p_planned_effort          => p_planned_effort,
          p_planned_effort_uom      => p_planned_effort_uom,
          p_actual_effort           => NULL,
          p_actual_effort_uom       => NULL,
          p_percentage_complete     => null,
          p_reason_code             => null,
          p_private_flag            => null,
          p_publish_flag            => null,
          p_restrict_closure_flag   => NULL,
          p_multi_booked_flag       => NULL,
          p_milestone_flag          => NULL,
          p_holiday_flag            => NULL,
          p_billable_flag           => NULL,
          p_bound_mode_code         => null,
          p_soft_bound_flag         => null,
          p_workflow_process_id     => NULL,
          p_notification_flag       => NULL,
          p_notification_period     => NULL,
          p_notification_period_uom => NULL,
          p_parent_task_number      => null,
          p_parent_task_id          => NULL,
          p_alarm_start             => NULL,
          p_alarm_start_uom         => NULL,
          p_alarm_on                => NULL,
          p_alarm_count             => NULL,
          p_alarm_interval          => NULL,
          p_alarm_interval_uom      => NULL,
          p_palm_flag               => NULL,
          p_wince_flag              => NULL,
          p_laptop_flag             => NULL,
          p_device1_flag            => NULL,
          p_device2_flag            => NULL,
          p_device3_flag            => NULL,
          p_costs                   => NULL,
          p_currency_code           => NULL,
          p_escalation_level        => NULL,
          p_task_notes_tbl          => l_task_notes_tbl,
          x_return_status           => l_return_status,
          x_msg_count               => l_msg_count,
          x_msg_data                => l_msg_data,
          x_task_id                 => x_new_task_id,
          p_attribute1              => p_attribute_1,
          p_attribute2              => p_attribute_2,
          p_attribute3              => p_attribute_3,
          p_attribute4              => p_attribute_4,
          p_attribute5              => p_attribute_5,
          p_attribute6              => p_attribute_6,
          p_attribute7              => p_attribute_7,
          p_attribute8              => p_attribute_8,
          p_attribute9              => p_attribute_9,
          p_attribute10             => p_attribute_10,
          p_attribute11             => p_attribute_11,
          p_attribute12             => p_attribute_12,
          p_attribute13             => p_attribute_13,
          p_attribute14             => p_attribute_14,
          p_attribute15             => p_attribute_15,
          p_attribute_category      => p_context,
          p_date_selected           => NULL,
          p_category_id             => null,
          p_show_on_calendar        => null,
          p_owner_status_id         => null,
          p_template_id             => p_template_id,
          p_template_group_id       => null);

      commit;

IF l_return_status = FND_API.G_RET_STS_SUCCESS
THEN
    /* API-call was successfull */
    x_error_id := 0;
    x_error := FND_API.G_RET_STS_SUCCESS;
ELSE
    FOR l_counter IN 1 .. l_msg_count
    LOOP
          fnd_msg_pub.get
        ( p_msg_index     => l_counter
        , p_encoded       => FND_API.G_FALSE
        , p_data          => l_msg_data
        , p_msg_index_out => l_msg_index_out
        );
         -- dbms_output.put_line( 'Message: '||l_data );
    END LOOP ;
    x_error_id := 2;
    x_error := l_msg_data;
    x_new_task_id := 0; -- no tasks

        Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION.CREATE_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                                 ,p_error_msg          =>  l_msg_data
                                 ,p_object_id   => l_incident_number);
              
END IF;

   /*   l_data := 'Task created '||x_new_task_id;
   Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION.CREATE_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                                 ,p_error_msg          =>  l_data
                                 ,p_object_id   => l_incident_number); */

EXCEPTION
  WHEN OTHERS
  THEN
    x_error_id := 1;
    x_error := SQLERRM;

            Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION.CREATE_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                 ,p_error_msg          =>  X_ERROR
                                 ,p_object_id         => l_incident_number);
END Create_Task;
/********************************************************************************************/
 PROCEDURE MANUAL_ORDER(X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                        X_RETCODE         OUT  NOCOPY  NUMBER,
                        P_SERIAL_NO       IN VARCHAR2,
                        P_LABEL           IN VARCHAR2) AS

  cursor sup_cur is
  select distinct cb.party_id,
        cb.device_id,
        cb.device_name,
        cb.serial_no,
        cb.device_cost_center,
        cb.ship_site_id,
        cb.device_location,
        cb.device_contact,
        cb.device_phone,
        cb.program_type,
        cb.device_jit,
        cb.model,
        cb.ip_address
  from xx_cs_mps_device_b cb
  WHERE cb.program_type not in ('Removed')
  and cb.serial_no = upper(p_serial_no)
  and cb.ship_site_id is not null;

lc_request_type   varchar2(50) := 'MPS Supplies Request';
ln_type_id        number;
lc_comments       varchar2(1000);
lc_summary        varchar2(250);
lr_request_rec     xx_cs_sr_rec_type;
ln_user_id        number;
lc_message        varchar2(1000);
ln_request_id     number;
lc_request_number varchar2(25);
lc_task_type_name   varchar2(150);
ln_task_type_id     number;
lc_task_context     varchar2(150);
LN_OWNER_ID         number;
LN_GROUP_ID         number;
ln_task_id          number;
lc_error_id         varchar2(25);
ln_task_status_id   number;
ln_task_priority    number;
Ln_STATUS_ID        number;
LC_STATUS           varchar2(150);
LN_OBJ_VER          NUMBER;
LC_NOTES            varchar2(2000);
LC_ITEM_DESCR       VARCHAR2(150);
lc_sku_string       VARCHAR2(100);
ln_sku_cnt          number :=0;
x_return_status     varchar2(25);
x_return_msg        varchar2(1000);
lc_label            varchar2(50);
lc_color_1          varchar2(15);
lc_color_2          varchar2(15);
lc_color_3          varchar2(15);
lc_color_4          varchar2(15);
ln_label_cnt        number := 0;



sup_rec   sup_cur%rowtype;

cursor sup_det is
   select distinct supplies_label, sku_option_1
  from xx_cs_mps_device_details
  where  replace(supplies_label,'TONERLEVEL_','') IN (nvl(lc_color_1,'x'),nvl(lc_color_2,'x'),
                                   nvl(lc_color_3,'x'),nvl(lc_color_4,'x'))
  and  serial_no = sup_rec.serial_no;

sup_det_rec sup_det%rowtype;

BEGIN

 FND_file.put_line(fnd_file.log ,'Processing serial number '|| p_serial_no);

       lr_request_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL);

     SELECT user_id
      INTO ln_user_id
      FROM fnd_user
     WHERE user_name = g_user_name;

      begin
      select incident_type_id
      into ln_type_id
      from cs_incident_types_tl
      where name = lc_request_type;
    exception
      when others then
        null;
    end;

    FND_file.put_line(fnd_file.log , 'Incident type id: ' || ln_type_id);
     --
   lc_label := p_label||',';

   FND_file.put_line(fnd_file.log , 'Label :'|| lc_label);

    begin
       select length(lc_label) - length(replace(lc_label,',',''))
       into ln_label_cnt
       from dual;
    exception
      when others then
         ln_label_cnt := 1;
    end;

    FND_file.put_line(fnd_file.log , 'label Cnt :'|| ln_label_cnt);

     FOR i in 1 .. ln_label_cnt LOOP
      IF i = 1 then
        lc_color_1 := SUBSTR(lc_label,1,INSTR(lc_label,',')-1);
      elsif I = 2 then
        lc_color_2 := SUBSTR(lc_label,1,INSTR(lc_label,',')-1);
       elsif I = 3 then
        lc_color_3 := SUBSTR(lc_label,1,INSTR(lc_label,',')-1);
     
       
      elsif I = 4 then
        lc_color_4 := SUBSTR(lc_label,1,INSTR(lc_label,',')-1);
        lc_label := SUBSTR(lc_label,INSTR(lc_label,',')+1);
         end if;
    END LOOP;

    FND_file.put_line(fnd_file.log , 'lc_color_1 :'|| lc_color_1 || 'lc_color_2 :'|| lc_color_2|| 'lc_color_3 :'|| lc_color_3|| 'lc_color_4 :'|| lc_color_4);

    FND_file.put_line(fnd_file.log , 'lc_label :'|| lc_label);

  BEGIN
    open sup_cur;
    loop
    fetch sup_cur into sup_rec;
    exit when sup_cur%notfound;

   --  DBMS_OUTPUT.PUT_LINE('TYPE ID '||ln_type_id);

    FND_file.put_line(fnd_file.log , 'processing serial number ...'|| sup_rec.serial_no);

     begin
        lr_request_rec.type_id := ln_type_id;
        lc_comments     := 'Supply Request Created for '||sup_rec.device_name||'Serial# '||sup_rec.serial_no;
        lc_summary      := 'Supply Request Created for '||sup_rec.serial_no;
         -- Assign values to rec type
        lr_request_rec.status_name       := 'Respond';--'In Progress';
        lr_request_rec.description       := lc_summary;
        lr_request_rec.caller_type       := 'MPS Supplies Request';
        lr_request_rec.customer_id       := sup_rec.party_id;
        lr_request_rec.user_id           := ln_user_id;
        lr_request_rec.channel           := 'WEB'; -- setup
        lr_request_rec.comments          := lc_comments;
     --   lr_sr_rec.sales_rep_contact := p_sales_rep;
     --   lr_request_rec.customer_number       := lc_aops_id;
        lr_request_rec.sales_rep_contact_ext  := sup_rec.Serial_No;
        lr_request_rec.csc_location          := substr(sup_rec.Device_location,1,20);
        lr_request_rec.preferred_contact     := sup_rec.device_Cost_Center;
        lr_request_rec.contact_email         :=  sup_rec.Model;
        lr_request_rec.contact_fax           :=  sup_rec.IP_Address;
        lr_request_rec.contact_name         :=  sup_rec.Device_contact;
        lr_request_rec.contact_phone        :=  substr(sup_rec.Device_phone,1,12);
        lr_request_rec.customer_sku_id      :=  sup_rec.program_type;
        lr_request_rec.zz_flag              :=   sup_rec.device_JIT;
        lr_request_rec.ship_to              :=  sup_rec.ship_site_id;
    exception
      when others then
         lc_message := 'Error at record type '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.MANUAL_ORDER'
                                 ,p_error_message_code =>   'XX_CS_SR10_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
         FND_file.put_line(fnd_file.log ,  lc_message);
    end;

    FND_file.put_line(fnd_file.log , 'Calling XX_CS_MPS_UTILITIES_PKG.CREATE_SR');

     XX_CS_MPS_UTILITIES_PKG.CREATE_SR
              (P_PARTY_ID        => sup_rec.party_id,
                P_SALES_NUMBER   => null,
                P_REQUEST_TYPE   => lc_request_type,
                P_COMMENTS       => lc_comments,
                p_sr_req_rec     => lr_request_rec,
                x_return_status  => x_return_status,
                X_RETURN_MSG     => x_return_msg);

       --   dbms_output.put_line('Status '||x_return_status||' '||x_return_msg||'no '||lr_request_rec.request_number);

      FND_file.put_line(fnd_file.log , 'Return Status : '|| x_return_status );
      FND_file.put_line(fnd_file.log , 'Request Number : '|| lr_request_rec.request_number);
      FND_file.put_line(fnd_file.log , 'x_return_msg :' || x_return_msg);

      IF nvl(x_return_status,'S') = 'S' then

        -- Create Task
          ln_request_id     := lr_request_rec.request_id;
          lc_request_number := lr_request_rec.request_number;
          lc_task_type_name := 'MPS Supplies';
          lc_task_context   := 'MPS Services';
          LN_TASK_STATUS_ID := 15; -- In Progress
          LN_TASK_PRIORITY := 3;

        begin
          select owner_group_id
          into ln_group_id
          from cs_incidents_all_b
          where incident_id = ln_request_id;
        end ;

        begin
          select task_type_id
          into ln_task_type_id
          from jtf_task_types_tl
          where name like lc_task_type_name;
        exception
           when others then
              ln_task_type_id := null;
               lc_message := 'Error while selecting Task Type'||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.MANUAL_ORDER'
                                 ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
        end;

     If ln_task_type_id is not null then

          -- Open Details cursor
      begin
        open sup_det;
        loop
        fetch sup_det into sup_det_rec;
          
        exit when sup_det%notfound;

        BEGIN
        select description
          into lc_item_descr
          from mtl_system_items_b
          where segment1 = sup_det_rec.sku_option_1
          and organization_id = 441;
       EXCEPTION
         WHEN OTHERS THEN
            NULL;
       END;

        BEGIN
            CREATE_TASK
                  ( p_task_name          => sup_det_rec.supplies_label||' '||sup_det_rec.sku_option_1
                  , p_task_type_id       => ln_task_type_id
                  , p_status_id          => ln_task_status_id
                  , p_priority_id        => ln_task_priority
                  , p_Planned_Start_date => sysdate
                  , p_planned_effort     => null
                  , p_planned_effort_uom => null
                  , p_notes              => lc_notes
                  , p_source_object_id   => ln_request_id
                  , x_error_id           => lc_error_id
                  , x_error              => x_return_msg
                  , x_new_task_id        => ln_task_id
                  , p_note_type          => null
                  , p_note_status        => null
                  , p_Planned_End_date   => null
                  , p_owner_id           => ln_group_id
                  , p_attribute_1           => sup_rec.device_name
                  , p_attribute_2           => sup_rec.serial_no
                  , p_attribute_3           => 1
                  , p_attribute_4           => sup_det_rec.sku_option_1
                  , p_attribute_5           => lc_item_descr -- item Descr
                  , p_attribute_6           => sup_det_rec.supplies_label  -- Toner Color
                  , p_attribute_7            => null
                  , p_attribute_8            => null
                  , p_attribute_9            => null
                  , p_attribute_10          => null
                  , p_attribute_11          => null
                  , p_attribute_12          => null
                  , p_attribute_13          => null
                  , p_attribute_14          => null
                  , p_attribute_15          => null
                  , p_context                  => lc_task_context
                  , p_assignee_id         => ln_user_id
                  , p_template_id         => NULL
                );


          EXCEPTION
            WHEN OTHERS THEN
              lc_message := 'Error while calling new task '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.MANUAL_ORDER'
                                 ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
          END;

        -- dbms_output.put_line(' Status  ' || x_return_msg);

           -- Update request number
         begin
           update xx_cs_mps_device_details
           set request_number = lc_request_number,
               attribute1 = ln_task_id
           where serial_no = sup_rec.serial_no
           and supplies_label = sup_det_rec.supplies_label;
         end;

          end loop;
        CLOSE SUP_DET;
        EXCEPTION
         WHEN OTHERS THEN
            lc_message := 'Error at cursor '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.MANUAL_ORDER'
                                 ,p_error_message_code =>   'XX_CS_SR11_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
      end;

      end if;

       -- Calling order release API
          BEGIN
            -- Call order req
                     SUPPLIES_REQ(P_DEVICE_ID      => LC_REQUEST_NUMBER,
                                  P_GROUP_ID       => NULL,
                                  X_RETURN_STATUS  => X_RETURN_STATUS,
                                  X_RETURN_MSG     => X_RETURN_MSG);

                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Order Request released..  :'|| to_char(sysdate, 'mm/dd/yy hh24:mi'));
            EXCEPTION
              WHEN OTHERS THEN

                 LC_MESSAGE := 'Error while calling Order Request '||x_return_status||' '||x_return_msg;
                     log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.MANUAL_ORDER',
                                    p_error_message_code    => 'XX_CS_SR011_ERR_LOG',
                                    P_ERROR_MSG             => LC_MESSAGE,
                                    p_object_id             => sup_rec.party_id);

                FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while order released     :'|| LC_MESSAGE);

            END;

        end if;

    end loop;
    commit;
    CLOSE SUP_CUR;
    exception
    WHEN OTHERS THEN
                                lc_message := 'Error at cursor '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.MANUAL_ORDER'
                                 ,p_error_message_code =>   'XX_CS_SR12_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
 END;
END MANUAL_ORDER;
/***************************************************************************************
  /********************************************************************************/
 -- Procedure to receive the supplies feed
 /******************************************************************************/
  PROCEDURE SUPPLIES_REQ(P_DEVICE_ID       IN VARCHAR2,
                          P_GROUP_ID        IN VARCHAR2,
                          X_RETURN_STATUS   IN OUT VARCHAR2,
                          X_RETURN_MSG      IN OUT VARCHAR2) AS

 ln_request_id  number;

 cursor sup_cur is
 select distinct cb.party_id,
        cb.device_id,
        cb.device_name,
        cb.serial_no,
        cb.device_cost_center,
        cb.po_number,
        cb.ship_site_id,
        substr(cb.site_zip_code,1,5) zip_code,
        cb.site_contact,
        cb.site_contact_phone,
        cb.device_location,
        cb.device_contact,
        cb.device_phone,
        decode(cb.program_type,'ATR','Y','N') atr_flag,
        cd.request_number,
        cs.incident_id,
        cs.tier_version,
        nvl(cb.attribute3,'AB') Payment_method,
         nvl(cb.attribute4,'N') cc_split_flag
        ,cb.aops_cust_number                  --ADDED BY ROHIT NANDA ON 19-JUN-2017 DEFECT# 41758
  from xx_cs_mps_device_details cd,
       xx_cs_mps_device_b cb,
       jtf_tasks_b jt,
       cs_incidents_all_b cs
  where cs.incident_number = cd.request_number
  and cs.customer_id = cb.party_id
  and cs.incident_status_id in (1100,1101)
  and  cs.incident_id = jt.source_object_id
  and  jt.source_object_name = cd.request_number
  and  jt.source_object_type_code = 'SR'
  and  jt.attribute2 = cb.serial_no
  and  cd.sku_option_1 = jt.attribute4
  and  jt.task_status_id not in (7,4)
  and  cb.device_id = cd.device_id
  and NVL(cd.device_status,'N') <> 'Stale'
  and upper(cd.supplies_label) like '%TONER%'
  and cb.party_id = nvl(p_group_id, cb.party_id)
  and cs.incident_number = nvl(p_device_id, cs.incident_number);

sup_rec   sup_cur%rowtype;

cursor sup_det_cur is
 select distinct cd.supplies_label, cd.sku_option_1,
        cd.sku_option_2,
        cd.sku_option_3,
        nvl(cd.quantity,1) qty
  from xx_cs_mps_device_details cd,
       xx_cs_mps_device_b cb,
       jtf_tasks_b jt,
       cs_incidents_all_b cb
  where cb.incident_number = cd.request_number
  and cb.customer_id = cb.party_id
  and cb.incident_id = ln_request_id
  and  cb.incident_id = jt.source_object_id
  and  jt.source_object_name = cd.request_number
  and  jt.source_object_type_code = 'SR'
  and  jt.attribute2 = cb.serial_no
  and  jt.task_status_id not in (7,4)
  and  cb.device_id = cd.device_id
  and  cd.sku_option_1 = jt.attribute4
  and NVL(cd.device_status,'N') <> 'Stale'
  and upper(cd.supplies_label) like '%TONER%';

lc_comments       varchar2(1000);
lc_summary        varchar2(250);
ln_user_id        number;
lr_hdr_rec        XX_CS_ORDER_HDR_REC;
lt_lines_tbl      XX_CS_ORDER_LINES_TBL;
lr_line_rec       XX_CS_ORDER_LINES_REC;
l_sr_req_rec   XX_CS_SR_REC_TYPE;             --QC 31778 MARS not moving to 2nd toner option when option 1 is not available.
l_request_type varchar2(50);
i                 number := 0;
lc_message        varchar2(1000);
lc_final_sku      varchar2(100);
lc_sku_status     varchar2(1) := 'N';
lc_warehouse      varchar2(25);
lc_inv_chk_flag   varchar2(1) := fnd_profile.value('XX_CS_MPS_INV_FLAG');

sup_det_rec   sup_det_cur%rowtype;

BEGIN
  SELECT user_id
  INTO ln_user_id
  FROM fnd_user
  WHERE user_name = g_user_name;

  x_return_msg    := null;
  x_return_status := null;

  BEGIN
    open sup_cur;
    loop
    fetch sup_cur into sup_rec;
    exit when sup_cur%notfound;

    lr_hdr_rec :=  XX_CS_ORDER_HDR_REC (null,null,null,null,null, null, null,null, null,null,null,null,null,null,
                                        null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
                                        null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
                                        null,null,null,null,null,null);

    ln_request_id             := sup_rec.incident_id;
    lr_hdr_rec.party_id       := sup_rec.party_id;
    lr_hdr_rec.request_number := sup_rec.request_number;
    
	log_msg('+++++++++++++++++++++++++===================looping of service request number'||sup_rec.request_number);
    
	IF sup_rec.atr_flag = 'Y'
    THEN
      lr_hdr_rec.order_category := 'MPS';
      lr_hdr_rec.order_category := 'ATR'; --'XML';
      lr_hdr_rec.special_instructions := 'Office Depot Automatic Toner Order for SN#'||sup_rec.serial_no;
    ELSE
      lr_hdr_rec.special_instructions := 'Office Depot Automatic Toner Order for SN#'||sup_rec.serial_no;
    END IF;

    lr_hdr_rec.po_number        := nvl(sup_rec.po_number,sup_rec.serial_no);
    lr_hdr_rec.serial_no        := sup_rec.serial_no;
    lr_hdr_rec.release          := sup_rec.device_contact;
    lr_hdr_rec.cost_center      := sup_rec.device_cost_center;
    lr_hdr_rec.desk_top         := sup_rec.device_location;
    lr_hdr_rec.printer_location := sup_rec.device_contact;
    lr_hdr_rec.location_name    := sup_rec.device_location;
    lr_hdr_rec.tendertyp        := sup_rec.payment_method;
     --lr_hdr_rec.cccid
     --lr_hdr_rec.tndacctnbr
     --lr_hdr_rec.exp_date
     --lr_hdr_rec.avscode
    lr_hdr_rec.bill_to          := sup_rec.party_id;
    lr_hdr_rec.ship_to          := sup_rec.ship_site_id;
    lr_hdr_rec.contact_id       := sup_rec.party_id; ---
    lr_hdr_rec.contact_name     := sup_rec.site_contact;
    lr_hdr_rec.contact_email    := null;
    lr_hdr_rec.contact_phone    := sup_rec.site_contact_phone;
    lr_hdr_rec.sales_person     := null;
    lr_hdr_rec.associate_id     := null;
    lr_hdr_rec.attribute1       := sup_rec.cc_split_flag; -- Line level cost center split flag
    lr_hdr_rec.attribute2       := sup_rec.tier_version;  -- Request version number for resending

    --  dbms_output.put_line('incident Id  '||ln_request_id);
    i := 1;
    lt_lines_tbl :=  XX_CS_ORDER_LINES_TBL();

    -- LINES CURSOR
    BEGIN
      OPEN SUP_DET_CUR;
      LOOP
      FETCH SUP_DET_CUR INTO SUP_DET_REC;
      EXIT WHEN SUP_DET_CUR%NOTFOUND;

      /* lt_lines_tbl.extend;
      lt_lines_tbl(i) :=  XX_CS_ORDER_LINES_REC(null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                null,null,null);*/
      log_msg(' Checking Inventory validation flag for Validating the SKUs ..');
      log_msg(' Inventory  check flag ..'|| LC_INV_CHK_FLAG);

     -- SKU Validation
     IF NVL(LC_INV_CHK_FLAG,'N') = 'Y'
     THEN
		--
		-- Start of changes as per version 6.1
		--
      /* BEGIN
         IF sup_det_rec.sku_option_1 is not null
         THEN
           VALIDATE_SKU(P_ZIP_CODE  => sup_rec.zip_code ,
                        P_SKU       => sup_det_rec.sku_option_1,
                        X_WAREHOUSE => lc_warehouse,
                        X_STATUS    => lc_sku_status);
         END IF;

         IF nvl(lc_sku_status,'N') = 'S'
         THEN
           lc_final_sku := sup_det_rec.sku_option_1;
         ELSE
           IF sup_det_rec.sku_option_2 is not null
           then
              VALIDATE_SKU(P_ZIP_CODE  => sup_rec.zip_code ,
                           P_SKU       => sup_det_rec.sku_option_2,
                           X_WAREHOUSE => lc_warehouse,
                           X_STATUS    => lc_sku_status);
           END IF;
         THEN
         END IF;

         IF nvl(lc_sku_status,'N') = 'S'
           lc_final_sku := sup_det_rec.sku_option_2;
         ELSE
           IF sup_det_rec.sku_option_3 is not null
           THEN
             VALIDATE_SKU(P_ZIP_CODE => sup_rec.zip_code ,
                          P_SKU       => sup_det_rec.sku_option_3,
                          X_WAREHOUSE => lc_warehouse,
                          X_STATUS    => lc_sku_status);
           END IF;

           IF nvl(lc_sku_status,'N') = 'S'
           THEN
             lc_final_sku := sup_det_rec.sku_option_3;
           END IF;
         END IF;
       EXCEPTION
         WHEN OTHERS
         THEN
           lc_final_sku := null;
           LC_MESSAGE   := 'Error validating sku '||sqlerrm;
           log_exception(p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.SUPPLIES_REQ',
                         p_error_message_code    => 'XX_CS_SR01e_ERR_LOG',
                         P_ERROR_MSG             => LC_MESSAGE,
                         p_object_id             => sup_rec.request_number);

       END;*/
		--
--log_msg('VSKU Check'|| sup_rec.zip_code||sup_det_rec.sku_option_1||sup_rec.aops_cust_number||lc_warehouse||lc_sku_status);--31-Jan-2018
--log_msg('Validate SKU Begins...'||'zipcode='||sup_rec.zip_code||' '||'sku='||sup_det_rec.sku_option_1||' '||'billto='||sup_rec.aops_cust_number||' '||'lc_warehouse='||lc_warehouse||' '||'lc_sku_status='||lc_sku_status);
		BEGIN
log_msg('================================= calling Validate SKU procedure based on toner of device ...'||lr_hdr_rec.serial_no);
		IF sup_det_rec.sku_option_1 IS NOT NULL
			THEN
			--
					VALIDATE_SKU(
									P_ZIP_CODE  => sup_rec.zip_code ,
									P_SKU       => sup_det_rec.sku_option_1,
									P_BILL_TO   => sup_rec.aops_cust_number,             --ADDED BY ROHIT NANDA ON 19-JUN-2017 DEFECT# 41758
									X_WAREHOUSE => lc_warehouse,
									X_STATUS    => lc_sku_status
								);
			--

			END IF;
--log_msg('Log Message:'||l_url);
			--

			IF NVL(lc_sku_status,'N') = 'S'
			THEN
				--
				lc_final_sku := sup_det_rec.sku_option_1;
				--
			ELSE
--log_msg('lc_final_sku:'||lc_final_sku);
				--
log_msg('=====================Validate SKU2 Begins calls Validate SKU Procedure...');
				IF sup_det_rec.sku_option_2 IS NOT NULL
				THEN
				--
					VALIDATE_SKU(
									P_ZIP_CODE  => sup_rec.zip_code ,
									P_SKU       => sup_det_rec.sku_option_2,
									P_BILL_TO   => sup_rec.aops_cust_number,             --ADDED BY ROHIT NANDA ON 19-JUN-2017 DEFECT# 41758
									X_WAREHOUSE => lc_warehouse,
									X_STATUS    => lc_sku_status
								);
				--
				END IF;
				--
--log_msg('Log Message:'||l_url);
				IF NVL(lc_sku_status,'N') = 'S'
				THEN
					--
					lc_final_sku := sup_det_rec.sku_option_2;
					--
				ELSE
--log_msg(' VALIDATE SKU Parameters Check'|| sup_rec.zip_code||sup_det_rec.sku_option_3||sup_rec.aops_cust_number||lc_warehouse||lc_sku_status);	 -- 31-Jan-2018 -- Muthu
					--
log_msg('=============================Validate SKU 3 Begins calls Validate SKU Procedure...');
					IF sup_det_rec.sku_option_3 IS NOT NULL
					THEN
					--
					VALIDATE_SKU(
									P_ZIP_CODE  => sup_rec.zip_code ,
									P_SKU       => sup_det_rec.sku_option_3,
									P_BILL_TO   => sup_rec.aops_cust_number,             --ADDED BY ROHIT NANDA ON 19-JUN-2017 DEFECT# 41758
									X_WAREHOUSE => lc_warehouse,
									X_STATUS    => lc_sku_status
								);
					END IF;
--log_msg('Log Message:'||l_url);
					--
					IF NVL(lc_sku_status,'N') = 'S'
					THEN
						--
						lc_final_sku := sup_det_rec.sku_option_3;
						--
--log_msg('Checking for Else Statement Trigger...')
						ELSE
						--
						lc_final_sku := NULL;
						--
					END IF;
					--
				END IF;
				--
			END IF;
			--
--log_msg('Checking for EXCEPTION Trigger...')
		EXCEPTION
		WHEN OTHERS THEN
		   lc_final_sku := NULL;
		   LC_MESSAGE   := 'Error validating sku '||SQLERRM;
						
		   log_exception(p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.SUPPLIES_REQ',
						 p_error_message_code    => 'XX_CS_SR01e_ERR_LOG',
						 P_ERROR_MSG             => LC_MESSAGE,
              p_object_id             => sup_rec.request_number);
		END;
		--
		-- End of changes as per version 6.1
		--
       log_msg('SKU Validation Completed and the Final SKU is '||lc_final_sku);

       IF lc_final_sku IS NULL
       THEN
         -- lc_final_sku := sup_det_rec.sku_option_1;
	 --Set Order rejected status and update SR
         l_sr_req_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,    --QC 31778 MARS not moving to 2nd toner option when option 1 is not available.
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL);
         --assign values
		--
		-- Start of changes as per version 6.1
		--
		IF sup_det_rec.sku_option_1 IS NULL
			AND sup_det_rec.sku_option_2 IS NULL
			AND sup_det_rec.sku_option_3 IS NULL
		THEN
			LC_MESSAGE      := 'SKU Options are not set for the device, please check the device setup';
		ELSE
			LC_MESSAGE      := 'No Quantity Exists in AOPS for all SKU options';
		END IF;
		--
		-- End of changes as per version 6.1
		--
         l_sr_req_rec.status_name       := 'Order Rejected';
         l_sr_req_rec.zz_flag           := '_1';

         l_sr_req_rec.request_id        :=  ln_request_id;
         l_sr_req_rec.request_number    :=  sup_rec.request_number;
         l_request_type                 :=  'MPS Supplies Request';

         log_msg('Setting the sR status to Rejected ..');

         BEGIN
           XX_CS_MPS_UTILITIES_PKG.UPDATE_SR (P_REQUEST_ID    => ln_request_id,
                                              P_COMMENTS      => LC_MESSAGE,
                                              P_REQ_TYPE      => L_REQUEST_TYPE,
                                              P_SR_REQ_REC    => L_SR_REQ_REC,
                                              X_RETURN_STATUS => X_RETURN_STATUS,
                                              X_RETURN_MSG    => X_RETURN_MSG);

           IF NVL(X_RETURN_STATUS, 'N') = 'E'
           THEN
             log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.SUPPLIES_REQ',
                            p_error_message_code    => 'XX_CS_SR01e_ERR_LOG',
                            P_ERROR_MSG             => LC_MESSAGE,
                           p_object_id              => sup_rec.request_number);
           END IF;
         END;

       ELSIF (lc_final_sku<>sup_det_rec.sku_option_1)
       THEN    --QC 31778 MARS not moving to 2nd toner option when option 1 is not available.

         log_msg('updating tasks with final SkU ..'|| lc_final_sku);

         UPDATE jtf_tasks_b jt
         SET jt.attribute4  =lc_final_sku,
             jt.attribute5  = (SELECT description
                               FROM mtl_system_items_b
                               WHERE segment1 = lc_final_sku
                               AND organization_id = 441)
         WHERE sup_det_rec.sku_option_1 = jt.attribute4
         AND  jt.source_object_type_code = 'SR'
         AND  jt.source_object_name = sup_rec.request_number;

       END IF;
     ELSE
       lc_final_sku := sup_det_rec.sku_option_1;
     END IF;

     IF lc_final_sku IS NOT NULL
     THEN        --QC 31778 MARS not moving to 2nd toner option when option 1 is not available.

       log_msg('setting the AOPS record to create the Order for the Final SKU ..'||lc_final_sku);

       lt_lines_tbl.extend;
       lt_lines_tbl(i) :=  XX_CS_ORDER_LINES_REC(null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                 null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                 null,null,null);

       lt_lines_tbl(i).line_number   := i;
       lt_lines_tbl(i).sku           := lc_final_sku; --'315515'
       lt_lines_tbl(i).order_qty     := sup_det_rec.qty;
       lt_lines_tbl(i).selling_price := 0;
       lt_lines_tbl(i).uom           := 'USD';
       lt_lines_tbl(i).item_description := null;
       lt_lines_tbl(i).comments    := null;

       i := i + 1;
     END IF;
   END LOOP;
   CLOSE SUP_DET_CUR;
   EXCEPTION
      WHEN OTHERS THEN
        LC_MESSAGE := 'Error  '||sqlerrm;
        log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.SUPPLIES_REQ',
                       p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                       P_ERROR_MSG             => LC_MESSAGE,
                       p_object_id             => sup_rec.request_number);
    END;

                        
    /*   LC_MESSAGE := 'Lines Table Count '||lt_lines_tbl.count;
         log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.SUPPLIES_REQ',
                        p_error_message_code    => 'XX_CS_SR01_LOG',
                        P_ERROR_MSG             => LC_MESSAGE,
                        p_object_id             => sup_rec.request_number); */

    IF lt_lines_tbl.count > 0
    THEN
      XX_CS_AOPS_ORDER_PKG.MAIN_PROC(P_HDR_REC        => LR_HDR_REC,
                                     P_LINE_TBL       => LT_LINES_TBL,
                                     P_REQUEST_NUMBER => sup_rec.request_number,
                                     X_RETURN_STATUS  => X_RETURN_STATUS,
                                     X_RETURN_MSG     => X_RETURN_MSG);
    END IF;

    IF NVL(X_RETURN_MSG, 'S') <> 'S'
    THEN
      LC_MESSAGE := 'ERROR while AOPS Order request creation '||x_return_status||' '||x_return_msg;
      log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.SUPPLIES_REQ',
                     p_error_message_code    => 'XX_CS_SR01a_ERR_LOG',
                     P_ERROR_MSG             => LC_MESSAGE,
                     p_object_id             => sup_rec.party_id);
    END IF;

    -- update current count
    log_msg( 'setting the Previous black count and previous color count for serial '||sup_rec.serial_no);

    BEGIN
      update xx_cs_mps_device_details
      set previous_black_count = (select total_black_count from  xx_cs_mps_device_details
                                  where serial_no = sup_rec.serial_no
                                  and supplies_label = 'USAGE'),
          previous_color_count = (select total_color_count from  xx_cs_mps_device_details
                                  where serial_no = sup_rec.serial_no
                                  and supplies_label = 'USAGE')
      where serial_no = sup_rec.serial_no
      and supplies_label = 'TONERLEVEL_BLACK';

      log_msg( 'setting the Previous shipment level for serial '||sup_rec.serial_no);

       update xx_cs_mps_device_details
       set prev_shipment_level = To_number(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(REPLACE(SUPPLIES_LEVEL,'%',NULL),
                                 'n/a', null), 'OK', null),'LOW' , Null), 'Ok', null), 'Error', NULL), 'Warning', null),'Critical', null),'.',null),95))
       where serial_no = sup_rec.serial_no
       and supplies_label != 'USAGE';

    END;
  END LOOP;
  close sup_cur;
  LC_MESSAGE := 'Error  '||sqlerrm;
    -- dbms_output.put_line('error '||sqlerrm);
  log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.SUPPLIES_REQ',
                 p_error_message_code    => 'XX_CS_SR01b_ERR_LOG',
                 P_ERROR_MSG             => LC_MESSAGE,
                 p_object_id             => p_device_id);
 END;
END SUPPLIES_REQ;

 /********************************************************************************/
 -- Procedure use order
 /******************************************************************************/
  PROCEDURE OM_REQ(P_DEVICE_ID       IN VARCHAR2,
                   P_GROUP_ID        IN VARCHAR2,
                   X_RETURN_STATUS   IN OUT VARCHAR2,
                   X_RETURN_MSG      IN OUT VARCHAR2) AS

 ln_request_id     number;
 LR_SR_REQ_REC     XX_CS_SR_REC_TYPE;
 LC_REQUEST_TYPE   VARCHAR2(50) := 'MPS Usage Request';
 ln_incident_id    NUMBER;

 cursor usage_cur is
 select  cb.incident_id, cb.incident_number,
          cb.account_id cust_acct_party_id,
         cb.customer_id party_id,
         cb.customer_po_number -- GALC Invoice
  from cs_incidents_all_b cb,
       cs_incident_types_tl ct
  where ct.incident_type_id = cb.incident_type_id
   and ct.name = 'MPS Usage Request'
   and cb.incident_status_id = 1100
   and cb.customer_id = nvl(p_group_id, cb.customer_id)
  and   cb.incident_number = nvl(p_device_id, cb.incident_number);

usage_rec   usage_cur%rowtype;

cursor usage_det_cur is
select distinct
        jt.attribute7 ship_site_id,
        jt.attribute5 Item,
        jt.attribute6 item_descr,
        jt.attribute2 count,
        jt.attribute3 cpc,
        jt.attribute4 line_amt,
        jt.attribute8 invOrgId,
        jt.attribute9 item_cost,
        jt.attribute10 cost_center,
        jt.attribute11 sku_dept,
        jt.task_id     task_id
  from cs_incidents_all_b mb,
       jtf_tasks_b jt
  where  jt.source_object_id = mb.incident_id
  and  jt.source_object_name = mb.incident_number
  and   mb.incident_id = usage_rec.incident_id
  and   mb.incident_number = usage_rec.incident_number
  and   jt.source_object_type_code = 'SR'
  --and   jt.attribute7 = mb.ship_site_id
  and   jt.task_status_id not in (7,4)
  and   mb.customer_id =  usage_rec.party_id;

lc_comments       varchar2(1000);
lc_summary        varchar2(250);
ln_user_id        number;
lr_hdr_rec        XX_CS_ORDER_HDR_REC;
lc_message        varchar2(1000);
lt_lines_tbl      XX_CS_ORDER_LINES_TBL;
lr_line_rec       XX_CS_ORDER_LINES_REC;
i                 number := 0;
lc_final_sku      varchar2(100);
lc_po_flag        varchar2(1) := fnd_profile.value('XX_MPS_PO_CREATION');

usage_det_rec   usage_det_cur%rowtype;

BEGIN

     SELECT user_id
      INTO ln_user_id
      FROM fnd_user
     WHERE user_name = g_user_name;


  BEGIN
    open usage_cur;
    loop
    fetch usage_cur into usage_rec;
    exit when usage_cur%notfound;

            lr_hdr_rec :=  XX_CS_ORDER_HDR_REC (null,null,null,null,null, null, null,null, null,null,null,null,null,null,
                                                null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                null,null,null,null,null,null);

            ln_request_id := usage_rec.incident_id;

            lr_hdr_rec.party_id    := usage_rec.cust_acct_party_id;  -- cs_incidents_all_b.account_id
            lr_hdr_rec.request_number := usage_rec.incident_number;

            lr_hdr_rec.order_category := 'W';
            lr_hdr_rec.special_instructions := 'Usage Order ';

           -- select cost center and  po number from customer master
            lr_hdr_rec.po_number        := null;
            lr_hdr_rec.customer_po_number := usage_rec.customer_po_number; --GALC Invoice number
            lr_hdr_rec.release          := null;
            lr_hdr_rec.cost_center      := null;
            lr_hdr_rec.desk_top         := null;
            lr_hdr_rec.printer_location := null;
            lr_hdr_rec.location_name    := null;
          --
            begin
               SELECT   HCS.SITE_USE_ID
              INTO LR_HDR_REC.BILL_TO
              FROM HZ_CUST_ACCOUNTS HCA
                 , HZ_CUST_SITE_USES_ALL HCS
                 , HZ_CUST_ACCT_SITES_ALL HCSA
             WHERE HCA.PARTY_ID                  = usage_rec.party_id
               AND HCA.CUST_ACCOUNT_ID           = HCSA.CUST_ACCOUNT_ID
               AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
               AND HCS.STATUS                    = 'A'
               AND HCS.SITE_USE_CODE             = 'BILL_TO' ;
            exception
               when others then
                 LR_HDR_REC.BILL_TO  := null;
            end;

            BEGIN
              SELECT   HCS.SITE_USE_ID
              INTO LR_HDR_REC.SHIP_TO
              FROM HZ_CUST_ACCOUNTS HCA
                 , HZ_CUST_SITE_USES_ALL HCS
                 , HZ_CUST_ACCT_SITES_ALL HCSA
             WHERE HCA.PARTY_ID                  = usage_rec.party_id
               AND HCA.CUST_ACCOUNT_ID           = HCSA.CUST_ACCOUNT_ID
               AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
               AND HCS.STATUS                    = 'A'
               AND HCS.PRIMARY_FLAG              = 'Y'
               AND HCS.SITE_USE_CODE             = 'SHIP_TO' ;
            exception
               when others then
                 LR_HDR_REC.SHIP_TO  := null;
            end;

            lr_hdr_rec.contact_id       := null;
            lr_hdr_rec.contact_name     := null; --usage_rec.site_contact;
            lr_hdr_rec.contact_email    := null;
            lr_hdr_rec.contact_phone    := null; --usage_rec.site_contact_phone;
            lr_hdr_rec.sales_person     := null; --determine from cs_incident_number; rep_id


          --  dbms_output.put_line('incident Id  '||ln_request_id);
              i := 1;
              lt_lines_tbl :=  XX_CS_ORDER_LINES_TBL();

            -- LINES CURSOR
            BEGIN
              OPEN USAGE_DET_CUR;
              LOOP
              FETCH USAGE_DET_CUR INTO USAGE_DET_REC;
              EXIT WHEN USAGE_DET_CUR%NOTFOUND;

                lt_lines_tbl.extend;
                lt_lines_tbl(i) :=  XX_CS_ORDER_LINES_REC(null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                     null,null,null,null,null,null,null,null,null,null,null,null,null,
                                                     null,null,null);

            IF I = 1 THEN
              lr_hdr_rec.attribute1  := usage_det_rec.invOrgId;
            end if;
            lt_lines_tbl(i).line_number   := i;
            lt_lines_tbl(i).sku           := usage_det_rec.item;
            lt_lines_tbl(i).order_qty     := usage_det_rec.count;
            lt_lines_tbl(i).selling_price := usage_det_rec.cpc;
            lt_lines_tbl(i).uom           := 'EA';
            lt_lines_tbl(i).item_description := usage_det_rec.item_descr;
            lt_lines_tbl(i).comments         := null;
            lt_lines_tbl(i).attribute1       := usage_det_rec.invOrgId; --Warehouse Org Id;
            lt_lines_tbl(i).attribute5 := usage_det_rec.item_cost;
            lt_lines_tbl(i).attribute2       :=  LR_HDR_REC.SHIP_TO; --usage_det_rec.ship_site_id;
           -- lt_lines_tbl(i).attribute3 := contract_no;
            lt_lines_tbl(i).attribute4 := usage_det_rec.sku_dept;
            lt_lines_tbl(i).vendor_part_number := usage_det_rec.item; -- toner skus;
            lt_lines_tbl(i).comments :='Monthly Usage';

            /* lt_lines_tbl(i).po_number
            lt_lines_tbl(i).release
             lt_lines_tbl(i).serial_number       */
            lt_lines_tbl(i).cost_center       := usage_det_rec.cost_center;
            lt_lines_tbl(i).desktop_location  := usage_det_rec.cost_center;
            lt_lines_tbl(i).attribute6 := usage_det_rec.task_id;    --- Orig_sys_line_ref


            i := i + 1;

            END LOOP;
            CLOSE USAGE_DET_CUR;
            EXCEPTION
              WHEN OTHERS THEN
                  LC_MESSAGE := 'Error  '||sqlerrm;
                     log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.OM_REQ',
                                    p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                                    P_ERROR_MSG             => LC_MESSAGE,
                                    p_object_id             => usage_rec.incident_number);

           END;
            FND_FILE.PUT_LINE(FND_FILE.LOG,lt_lines_tbl.count||' Usage Order Lines for '|| usage_rec.incident_number);

      /*      LC_MESSAGE := 'Lines Table Count '||lt_lines_tbl.count;
                     log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.OM_REQ',
                                    p_error_message_code    => 'XX_CS_SR01_LOG',
                                    P_ERROR_MSG             => LC_MESSAGE,
                                    p_object_id             => usage_rec.incident_number); */

          IF lt_lines_tbl.count > 0 then

           BEGIN
             XX_CS_MPS_ORDER_PKG.CREATE_MPS_ORDER( X_RETURN_STATUS  => X_RETURN_STATUS,
                                                   X_RETURN_MESG   => X_RETURN_MSG,
                                                   P_HDR_REC       => LR_HDR_REC,
                                                   P_LIN_TBL      => LT_LINES_TBL);
           EXCEPTION
            WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while calling OM Order Process '|| usage_rec.incident_number);
              LC_MESSAGE := 'error while calling OM Order creation for '||usage_rec.incident_number||';'||sqlerrm;
                     log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.OM_REQ',
                                    p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                                    P_ERROR_MSG             => LC_MESSAGE,
                                    p_object_id             => usage_rec.incident_number);
           END;
          end if;


           FND_FILE.PUT_LINE(FND_FILE.LOG,'Usage Order Process Status '||x_return_status||' '||x_return_msg);
           LC_MESSAGE := 'OM Order request creation '||x_return_status||' '||x_return_msg;


             -- Calling PO creation for usage billing
      IF nvl(lc_po_flag,'N') = 'Y' then

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Submit for PO '|| usage_rec.incident_number);
         begin
               SUBMIT_PO( usage_rec.party_id,
                           usage_rec.incident_number,
                           'USAGE',
                           X_RETURN_STATUS,
                           X_RETURN_MSG);

        end;

          IF NVL(X_RETURN_STATUS, 'S') <> 'S' THEN

               FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR while PO creation '||x_return_status||' '||x_return_msg);
               LC_MESSAGE := 'ERROR while OM Order request creation '||x_return_status||' '||x_return_msg;
                         log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.OM_REQ',
                                        p_error_message_code    => 'XX_CS_SR01a_ERR_LOG',
                                        P_ERROR_MSG             => LC_MESSAGE,
                                        p_object_id             => usage_rec.party_id);

          END IF;

      end if;

         lr_sr_req_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL);

      -- Update SR status
         lr_sr_req_rec.status_name    := 'Order Placed';
         lr_sr_req_rec.request_id     := usage_rec.incident_id;
         ln_incident_id := usage_rec.incident_id;
         lr_sr_req_rec.request_number := usage_rec.incident_number;
         X_RETURN_STATUS := null;
         X_RETURN_MSG := null;


     begin
           XX_CS_MPS_UTILITIES_PKG.UPDATE_SR(P_REQUEST_ID    => LN_INCIDENT_ID,
                                              X_RETURN_STATUS => X_RETURN_STATUS,
                                              P_COMMENTS      => LC_MESSAGE,
                                              P_REQ_TYPE      => LC_REQUEST_TYPE,
                                              P_SR_REQ_REC    => LR_SR_REQ_REC,
                                              X_RETURN_MSG    => X_RETURN_MSG);

            IF NVL(X_RETURN_STATUS,'S') = 'S' then
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Update SR Status for '|| usage_rec.incident_number);
            ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while Update SR Status for '|| usage_rec.incident_number||' '||x_return_msg);
              LC_MESSAGE := 'Error while update SR Status '||x_return_msg;
              log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.OM_REQ',
                            p_error_message_code    => 'XX_CS_SR01b_ERR_LOG',
                            P_ERROR_MSG             => LC_MESSAGE,
                            p_object_id             => usage_rec.party_id);

            END IF;

      exception
         when others then
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while Update SR Status for '|| usage_rec.incident_number||' '||sqlerrm);
            LC_MESSAGE := 'Error while update SR Status '||sqlerrm;
            log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.OM_REQ',
                          p_error_message_code    => 'XX_CS_SR01b_ERR_LOG',
                          P_ERROR_MSG             => LC_MESSAGE,
                          p_object_id             => usage_rec.party_id);

     end;

     -- UPDATE Bill Date
     BEGIN
         Update xx_cs_mps_device_b
         set notification_date = ADD_MONTHS(notification_date,1)
         WHERE party_id = usage_rec.party_id;

         COMMIT;
     EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while Update Bill Date '||  usage_rec.party_id||' '||sqlerrm);
            LC_MESSAGE := 'Error while Update Bill Date '||sqlerrm;
            log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.OM_REQ',
                          p_error_message_code    => 'XX_CS_SR01b_ERR_LOG',
                          P_ERROR_MSG             => LC_MESSAGE,
                          p_object_id             => usage_rec.party_id);

     END;

      -- UPDATE Bill Date
     BEGIN
         Update xx_cs_mps_device_details
         set previous_bill_count = total_black_count,
             previous_color_bill_count = total_color_count
         where serial_no in (select serial_no from xx_cs_mps_device_b
                              WHERE party_id = usage_rec.party_id)
          and supplies_label = 'USAGE';

         COMMIT;
     EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while previous bill counts '||  usage_rec.party_id||' '||sqlerrm);
            LC_MESSAGE := 'Error while Update Bill Date '||sqlerrm;
            log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.OM_REQ',
                          p_error_message_code    => 'XX_CS_SR01c_ERR_LOG',
                          P_ERROR_MSG             => LC_MESSAGE,
                          p_object_id             => usage_rec.party_id);

     END;

    end loop;
    close usage_cur;
        LC_MESSAGE := 'Error  '||sqlerrm;
           log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.OM_REQ',
                          p_error_message_code    => 'XX_CS_SR01b_ERR_LOG',
                          P_ERROR_MSG             => LC_MESSAGE,
                          p_object_id             => usage_rec.party_id);
 END;

END OM_REQ;
/************************************************************************************/
/********************************************************************************/
 -- Procedure to receive the supplies feed
 /******************************************************************************/
  PROCEDURE SUPPLIES_ORDER(P_PARTY_ID       IN NUMBER,
                          X_RETURN_STATUS   IN OUT VARCHAR2,
                          X_RETURN_MSG      IN OUT VARCHAR2) AS

  ln_bulk_level   number := fnd_profile.value('XX_CS_MPS_BULK_LEVEL');
  
  
  
  
  cursor sup_cur is
  select distinct cb.party_id,
        cb.device_id,
        cb.device_name,
        cb.serial_no,
        cb.device_cost_center,
        cb.ship_site_id,
        cb.device_location,
        cb.device_contact,
        cb.device_phone,
        cb.program_type,
        cb.device_jit,
        cb.model,
        cb.ip_address,
        UPPER(cb.auto_toner_release) auto_toner_release
  from xx_cs_mps_device_details cd,
       xx_cs_mps_device_b cb
  WHERE CB.DEVICE_ID = CD.DEVICE_ID
--  and  TO_NUMBER(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CD.SUPPLIES_LEVEL,'%',NULL),'n/a',null),'OK',null),'LOW',NULL),999))
          
  and To_number(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(REPLACE(CD.SUPPLIES_LEVEL,'%',NULL), 'n/a', null), 'OK', null),
         'LOW' , Null), 'Ok', null), 'Error', NULL), 'Warning', null),'.',988),'Critical',Null),999)) <= NVL(CB.LEVEL_LIMIT,20)
   and To_number(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(REPLACE(CD.SUPPLIES_LEVEL,'%',NULL), 'n/a', null), 'OK', null),     				--- Added for Defect#42134
    'LOW' , Null), 'Ok', null), 'Error', NULL), 'Warning', null), 'Critical', NULL),'.',988), 999)) <= NVL(TO_NUMBER(CD.ATTRIBUTE2),20) + nvl(ln_bulk_level,10)  --- Added for Defect#42134
  and nvl(cd.toner_order_date,sysdate-10) < sysdate - 7
  and NVL(cd.device_status,'N') <> 'Stale'
  and cb.program_type in (select meaning
                          from cs_lookups
                          where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                          and tag in ('BOTH', 'TONER')
                          and end_date_active is null)
  and cd.request_number is null
  and upper(cd.supplies_label) like '%TONER%'
  and cb.party_id = nvl(p_party_id, cb.party_id)
  and cb.ship_site_id is not null
  and cd.sku_option_1 is not null;

lc_request_type   varchar2(50) := 'MPS Supplies Request';
ln_type_id        number;
lc_comments       varchar2(1000);
lc_summary        varchar2(250);
lr_request_rec     xx_cs_sr_rec_type;
ln_user_id        number;
lc_message        varchar2(1000);
ln_request_id     number;
lc_request_number varchar2(25);
lc_task_type_name   varchar2(150);
ln_task_type_id     number;
lc_task_context     varchar2(150);
LN_OWNER_ID         number;
LN_GROUP_ID         number;
ln_task_id          number;
lc_error_id         varchar2(25);
ln_task_status_id   number;
ln_task_priority    number;
Ln_STATUS_ID        number;
LC_STATUS           varchar2(150);
LN_OBJ_VER          NUMBER;
LC_NOTES            varchar2(2000);
LC_ITEM_DESCR       VARCHAR2(150);
lc_cnt_check_flag   VARCHAR2(1) := 'N';
lc_status_name      VARCHAR2(20);
lc_auto_toner_release  xx_cs_mps_device_b.auto_toner_release%TYPE ;

sup_rec         sup_cur%rowtype;


cursor sup_det is
  select distinct supplies_label, sku_option_1
  from xx_cs_mps_device_details
  where To_number(NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(REPLACE(SUPPLIES_LEVEL,'%',NULL), 'n/a', null), 'OK', null),
           'LOW' , Null), 'Ok', null), 'Error', NULL), 'Warning', null), 'Critical', NULL),'.',988), 999)) <= NVL(TO_NUMBER(ATTRIBUTE2),20) + nvl(ln_bulk_level,10)
  and  upper(supplies_label) like '%TONER%'
  and  serial_no = sup_rec.serial_no
  and request_number is null;

sup_det_rec sup_det%rowtype;

BEGIN
  log_msg('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
   log_msg('Begin of Supplies Order ..');
   log_msg('Party id'|| p_party_id);

   lr_request_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL);

     SELECT user_id
      INTO ln_user_id
      FROM fnd_user
     WHERE user_name = g_user_name;

      begin
      select incident_type_id
      into ln_type_id
      from cs_incident_types_tl
      where name = lc_request_type;
    exception
      when others then
        null;
    end;

  BEGIN
    open sup_cur;
    loop
    fetch sup_cur into sup_rec;
    exit when sup_cur%notfound;
	
           log_msg('##########################################');
		    log_msg('looping start  for device Id ' ||sup_rec.serial_no);

    log_msg(' Checking the counts to validate  of total count minus previous count..');

    -- Check count
     BEGIN
        select 'Y'
        into lc_cnt_check_flag
        from xx_cs_mps_device_details
        where serial_no = sup_rec.serial_no
        and supplies_label = 'USAGE'
        and (nvl(total_count,0) - nvl(previous_count,0)) > 0;
     EXCEPTION
        WHEN OTHERS THEN
           lc_cnt_check_flag := 'N';
     END;
     log_msg('Device Fetched based on the Total Count and Previous Count from Details Table...');
     log_msg('Counting check flag :'||lc_cnt_check_flag);

    IF nvl(lc_cnt_check_flag,'N') = 'Y' then
   --  DBMS_OUTPUT.PUT_LINE('TYPE ID '||ln_type_id);

      fnd_file.put_line(fnd_file.log, 'Creating Service request for device '||sup_rec.serial_no );
      fnd_file.put_line(fnd_file.log, 'Check Auto release flag it is required ..');
      fnd_file.put_line(fnd_file.log, 'Auto release flag: '|| sup_rec.auto_toner_release);

      IF sup_rec.auto_toner_release = 'Y'
      THEN
        lc_status_name := 'Resolved';
      ELSE
        lc_status_name := 'In Progress';
      END IF;

     fnd_file.put_line(fnd_file.log, 'displaying  the status of aunto toner release flag  ' || lc_status_name);

     begin
        lr_request_rec.type_id := ln_type_id;
        lr_request_rec.status_name       := lc_status_name; --'In Progress';
        lc_comments     := 'Supply Request Created for '||sup_rec.device_name||'Serial# '||sup_rec.serial_no;
        lc_summary      := 'Supply Request Created for '||sup_rec.serial_no;
         -- Assign values to rec type
        lr_request_rec.description       := lc_summary;
        lr_request_rec.caller_type       := 'MPS Supplies Request';
        lr_request_rec.customer_id       := sup_rec.party_id;
        lr_request_rec.user_id           := ln_user_id;
        lr_request_rec.channel           := 'WEB'; -- setup
        lr_request_rec.comments          := lc_comments;
     --   lr_sr_rec.sales_rep_contact := p_sales_rep;
     --   lr_request_rec.customer_number       := lc_aops_id;
        lr_request_rec.sales_rep_contact_ext  := sup_rec.Serial_No;
        lr_request_rec.csc_location          := substr(sup_rec.Device_location,1,20);
        lr_request_rec.preferred_contact     := substr(sup_rec.device_Cost_Center,1,20);
        lr_request_rec.contact_email         :=  sup_rec.Model;
        lr_request_rec.contact_fax           :=  sup_rec.IP_Address;
        lr_request_rec.contact_name         :=  sup_rec.Device_contact;
        lr_request_rec.contact_phone        :=  substr(sup_rec.Device_phone,1,12);
        lr_request_rec.customer_sku_id      :=  sup_rec.program_type;
        lr_request_rec.zz_flag              :=   sup_rec.device_JIT;
        lr_request_rec.ship_to              :=  sup_rec.ship_site_id;
    exception
      when others then
         lc_message := 'Error at record type '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.SUPPLIES_ORDER'
                                 ,p_error_message_code =>   'XX_CS_SR10_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
    end;

   log_msg('============== Procedure call for Creating Service Request...');
     XX_CS_MPS_UTILITIES_PKG.CREATE_SR
              (P_PARTY_ID        => sup_rec.party_id,
                P_SALES_NUMBER   => null,
                P_REQUEST_TYPE   => lc_request_type,
                P_COMMENTS       => lc_comments,
                p_sr_req_rec     => lr_request_rec,
                x_return_status  => x_return_status,
                X_RETURN_MSG     => x_return_msg);

       log_msg('Status  of service request '||x_return_status|| ' msg :'||x_return_msg);
       log_msg('Service Request Created and the Request# is '||lr_request_rec.request_number);

       --x_return_msg := x_return_msg|| ' For ' || sup_rec.Serial_No;   Commented for QC 34809
	   --QC 34809

      IF nvl(x_return_status,'S') = 'S' then

        -- Create Task
          ln_request_id     := lr_request_rec.request_id;
          lc_request_number := lr_request_rec.request_number;
          lc_task_type_name := 'MPS Supplies';
          lc_task_context   := 'MPS Services';
          LN_TASK_STATUS_ID := 15; -- In Progress
          LN_TASK_PRIORITY := 3;

        begin
          select owner_group_id
          into ln_group_id
          from cs_incidents_all_b
          where incident_id = ln_request_id;
        end ;

        begin
          select task_type_id
          into ln_task_type_id
          from jtf_task_types_tl
          where name like lc_task_type_name;
        exception
           when others then
              ln_task_type_id := null;
               lc_message := 'Error while selecting Task Type'||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.CREATE_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
        end;

     If ln_task_type_id is not null then

          -- Open Details cursor
      begin
        open sup_det;
        loop
        fetch sup_det into sup_det_rec;
        exit when sup_det%notfound;

        BEGIN
          select description
          into lc_item_descr
          from mtl_system_items_b
          where segment1 = sup_det_rec.sku_option_1
          and organization_id = 441;
       EXCEPTION
         WHEN OTHERS THEN
            NULL;
       END;

        BEGIN
            CREATE_TASK
                  ( p_task_name          => sup_det_rec.supplies_label||' '||sup_det_rec.sku_option_1
                  , p_task_type_id       => ln_task_type_id
                  , p_status_id          => ln_task_status_id
                  , p_priority_id        => ln_task_priority
                  , p_Planned_Start_date => sysdate
                  , p_planned_effort     => null
                  , p_planned_effort_uom => null
                  , p_notes              => lc_notes
                  , p_source_object_id   => ln_request_id
                  , p_note_type          => null
                  , x_error_id           => lc_error_id
                  , x_error              => x_return_msg
                  , x_new_task_id        => ln_task_id
                  , p_note_status        => null
                  , p_Planned_End_date   => null
                  , p_owner_id           => ln_group_id
                  , p_attribute_1           => sup_rec.device_name
                  , p_attribute_2           => sup_rec.serial_no
                  , p_attribute_3           => 1
                  , p_attribute_4           => sup_det_rec.sku_option_1
                  , p_attribute_5           => lc_item_descr -- item Descr
                  , p_attribute_6           => sup_det_rec.supplies_label  -- Toner Color
                  , p_attribute_7            => null
                  , p_attribute_8            => null
                  , p_attribute_9            => null
                  , p_attribute_10          => null
                  , p_attribute_11          => null
                  , p_attribute_12          => null
                  , p_attribute_13          => null
                  , p_attribute_14          => null
                  , p_attribute_15          => null
                  , p_context                  => lc_task_context
                  , p_assignee_id         => ln_user_id
                  , p_template_id         => NULL
                );

          /*    lc_message := 'Task created '||x_return_msg;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.CREATE_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR01_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number); */

          EXCEPTION
            WHEN OTHERS THEN
              lc_message := 'Error while calling new task '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.CREATE_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
          END;

        -- dbms_output.put_line(' Status  ' || x_return_msg);

           -- Update request number
         begin
           update xx_cs_mps_device_details
           set request_number = lc_request_number,
               attribute1 = ln_task_id
           where serial_no = sup_rec.serial_no
           and supplies_label = sup_det_rec.supplies_label;
         end;


          end loop;
        CLOSE SUP_DET;
        EXCEPTION
         WHEN OTHERS THEN
            lc_message := 'Error at cursor '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.CREATE_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR11_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
      end;

      end if;

      log_msg('Auto toner release:'|| sup_rec.auto_toner_Release);

      IF sup_rec.auto_toner_release = 'Y'
      THEN
        -- Calling order release API
        BEGIN
		
		     log_msg('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
              log_msg('Calling supplies req procedure ..'||LC_REQUEST_NUMBER);
           -- Call order req

          SUPPLIES_REQ(P_DEVICE_ID      => LC_REQUEST_NUMBER,
                       P_GROUP_ID       => NULL,
                       X_RETURN_STATUS  => X_RETURN_STATUS,
                       X_RETURN_MSG     => X_RETURN_MSG);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Order Request released for request number..  :'|| LC_REQUEST_NUMBER||' '||to_char(sysdate, 'mm/dd/yy hh24:mi'));
        EXCEPTION
          WHEN OTHERS
          THEN
            LC_MESSAGE := 'Error while calling Order Request '||x_return_status||' '||x_return_msg;
            log_exception(p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.MANUAL_ORDER',
                          p_error_message_code    => 'XX_CS_SR011_ERR_LOG',
                          P_ERROR_MSG             => LC_MESSAGE,
                          p_object_id             => sup_rec.party_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while order released     :'|| LC_MESSAGE);
        END;
      END IF;
    else
      LC_MESSAGE := 'Error while calling SR create API '||x_return_status||' '||x_return_msg;
      log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.SUPPLIES_REQ',
                     p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                     P_ERROR_MSG             => LC_MESSAGE,
                     p_object_id             => sup_rec.party_id);
      log_msg(lc_message);

    end if;  -- status

    log_msg('Commiting the service request..');

    log_msg('End of Order Creation..');
	log_msg('+++++++++++++++++++++++++ end of supplies req procedure');

    commit;

  end if; -- lc_cnt_check_flag
  end loop;

 
    COMMIT;

  CLOSE SUP_CUR;
   exception
    WHEN OTHERS THEN
        lc_message := 'Error at cursor '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.CREATE_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR12_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => lc_request_number);
 END;
END SUPPLIES_ORDER;
/***************************************************************************************/
PROCEDURE UPDATE_COUNT(P_PARTY_ID IN NUMBER)
IS
cursor c1 is
select serial_no, nvl(allowances,0) allowances,
       nvl(color_allowances,0)
 from xx_cs_mps_device_b cb
  where cb.party_id = nvl(p_party_id,cb.party_id)
  and program_type in (select meaning
                      from cs_lookups
                      where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                      and tag in ('BOTH', 'USAGE')
                      and end_date_active is null);

  c1_rec                c1%rowtype;
  lc_warehouse          number;
  lc_message            varchar2(1000);
  ln_black_over_usage   number;
  ln_color_over_usage   number;
  ln_black_under_usage  number;
  ln_color_under_usage  number;

BEGIN
    -- update counts
    begin
      open c1;
      loop
      fetch c1 into c1_rec;
      exit when c1%notfound;


          begin
            select attribute3
            into lc_warehouse
            from xx_cs_mps_device_details
            where supplies_label = 'TONERLEVEL_BLACK'
            and serial_no = c1_rec.serial_no
            and rownum < 2;
          exception
           when others then
              lc_warehouse := 1165;
              lc_message := 'Error while calling warehouse for Serial_no '||c1_rec.serial_no||' '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.UPDATE_COUNT'
                                 ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => p_party_id);
          end;

          log_msg( 'updating counts for Serial number for usage record ..'|| c1_Rec.serial_no);


           begin
             update xx_cs_mps_device_details
             set color_count = nvl(total_color_count,0) - nvl(previous_color_bill_count,0),
                 black_count = nvl(total_black_count,0) - nvl(previous_bill_count,0),
                 current_count = nvl(black_count,0) + nvl(color_count,0),
                 attribute3 = lc_warehouse
             where serial_no = c1_rec.serial_no
             and supplies_label = 'USAGE';

             commit;
          exception
             when others then
                 lc_message := 'Error while updating '||c1_rec.serial_no||' '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.UPDATE_COUNT'
                                     ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => p_party_id);
          end;

          log_msg( 'allowances value ..'|| c1_Rec.allowances);

          --Allowances
          If nvl(c1_rec.allowances,0) > 0 then
           begin
               select (black_count - c1_rec.allowances) black_allow,
                      (color_count - c1_rec.allowances) color_allow
               into  ln_black_over_usage, ln_color_over_usage
               from xx_cs_mps_device_details
                where serial_no = c1_rec.serial_no
                 and supplies_label = 'USAGE';


          log_msg( 'ln_black_over_usage'|| ln_black_over_usage);
          log_msg( 'ln_color_over_usage'|| ln_color_over_usage);

            exception
               when others then
                lc_message := 'Error selecting allowance '||c1_rec.serial_no||' '||sqlerrm;
                    Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.UPDATE_COUNT'
                                       ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                       ,p_error_msg          =>  lc_message
                                       ,p_object_id         => p_party_id);
            end;

            IF ln_black_over_usage < 0 then
               ln_black_under_usage := ln_black_over_usage;
               ln_black_over_usage := null;
            end if;

            IF ln_color_over_usage < 0 then
               ln_color_under_usage := ln_color_over_usage;
               ln_color_over_usage := null;
            end if;


            log_msg( 'ln_black_under_usage:'|| ln_black_under_usage);
            log_msg( 'ln_color_under_usage:'|| ln_color_under_usage);


                   
             begin
               update xx_cs_mps_device_details
               set over_usage = ln_black_over_usage,
               color_over_usage = ln_color_over_usage,
                   black_under_usage = ln_black_under_usage,
                   color_under_usage = ln_color_under_usage
               where serial_no = c1_rec.serial_no
               and supplies_label = 'USAGE';

               commit;

            exception
               when others then
                   lc_message := 'Error while updating '||c1_rec.serial_no||' '||sqlerrm;
                    Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.UPDATE_COUNT'
                                       ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                                       ,p_error_msg          =>  lc_message
                                       ,p_object_id         => p_party_id);
            end;

          end if;

     end loop;
     close c1;
    end;

END UPDATE_COUNT;

/********************************************************************************/
 -- Procedure to receive meter reading
 /******************************************************************************/
 PROCEDURE METER_REQ(P_DEVICE_ID       IN VARCHAR2,
                     P_GROUP_ID        IN VARCHAR2,
                     X_RETURN_STATUS   IN OUT VARCHAR2,
                     X_RETURN_MSG      IN OUT VARCHAR2) AS



  cursor c1 is
  select distinct cb.party_id,
                  cb.party_name,
                  cb.contract_number
  from xx_cs_mps_device_b cb,
       xx_cs_mps_device_details cd
  where cd.serial_no = cb.serial_no
  and trunc(nvl(cb.notification_date,sysdate)) = trunc(sysdate)
--  and nvl(cd.black_count,0) > 0
  AND nvl(total_black_count,0) - nvl(previous_bill_count,0) > 0
  and cb.party_id = nvl(p_group_id,cb.party_id)
  and program_type in (select meaning
                      from cs_lookups
                      where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                      and tag in ('BOTH', 'USAGE')
                      and end_date_active is null);

  c1_rec  c1%rowtype;

lc_request_type   varchar2(50) := 'MPS Usage Request';
ln_type_id        number;
lc_comments       varchar2(1000);
lc_summary        varchar2(250);
lr_request_rec     xx_cs_sr_rec_type;
ln_user_id        number;
i                 number := 0;
lc_message        varchar2(1000);
ln_request_id     number;
lc_request_number varchar2(25);

lc_task_type_name   varchar2(150);
ln_task_type_id     number;
lc_task_context     varchar2(150);
LN_OWNER_ID         number;
LN_GROUP_ID         number;
ln_task_id          number;
lc_error_id         varchar2(25);
ln_task_status_id   number;
ln_task_priority    number;
Ln_STATUS_ID        number;
LC_STATUS           varchar2(150);
LN_OBJ_VER          NUMBER;
LC_NOTES            varchar2(2000);
l_user_id           number := 26176;
lc_item             varchar2(25);
lc_item_descr       varchar2(150);
ln_item_cost        number(8,4);
ln_black_cpc        number(8,4);
ln_color_cpc        number(8,4);
ln_overage_cost     number(8,4);
lc_site_cont_phone  varchar2(25);
ln_inv_org_id       number;
ln_sku_dept         number;
ln_ship_to          number;
ln_standard_amt     NUMBER;
ln_black_amt        NUMBER;
ln_color_amt        NUMBER;
ln_attach_document  VARCHAR2(1) := 'Y';
lc_file_name        VARCHAR2(200) := NULL;

ln_overage_standard_amt  NUMBER;
ln_overage_black_amt     NUMBER;
ln_overage_black_cnt     NUMBER;
ln_overage_color_amt     NUMBER;
ln_overage_color_cnt     NUMBER;

cursor usage_cur is
select cb.party_id,
      -- cb.ship_site_id,
       nvl(cd.attribute3,1165) warehouse_id,
       sum(nvl(cd.black_count,0)) black_count,
       sum(nvl(cd.black_count,0) * nvl(cb.black_cpc,0.02)) black_amt,
       sum(nvl(cb.flat_rate,0)) standard_amt,
       sum(nvl(cd.color_count,0)) color_count,
       sum(nvl(cd.color_count,0) * nvl(cb.color_cpc,0.09)) color_amt,
       sum(nvl(cd.over_usage,0)) over_usage,
       sum(nvl(cd.over_usage,0) * (cb.overage_cost)) overage_amt,
       sum(nvl(cd.color_over_usage,0)) color_over_usage,
       sum(nvl(cd.color_over_usage,0) * cb.color_overage_cost) color_overage_amt
from xx_cs_mps_device_details cd,
     xx_cs_mps_device_b cb
where cd.serial_no = cb.serial_no
and  cb.party_id = c1_rec.party_id
and cd.supplies_label = 'USAGE'
and cb.ship_site_id is not null
and nvl(cd.black_count,0) > 0
and cb.program_type in (select meaning
                      from cs_lookups
                      where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                      and tag in ('BOTH', 'USAGE')

                      and end_date_active is null)
group by cb.party_id,  ---cb.ship_site_id,
nvl(cd.attribute3,1165);
usage_rec   usage_cur%rowtype;


BEGIN

  lr_request_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                      NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                      NULL,NULL,NULL,NULL);

  SELECT user_id
  INTO ln_user_id
  FROM fnd_user
  WHERE user_name = 'CS_ADMIN';


  BEGIN
    select incident_type_id
    into ln_type_id
    from cs_incident_types_tl
    where name = lc_request_type;
  EXCEPTION
    when others then
     null;
   END;

    -- Initiation of party wise request
   begin
      open c1;
      loop
      fetch c1 into c1_rec;
      exit when c1%notfound;

       ln_ship_to := null;

         -- Update bill count

         log_msg('Calling update count for party id '|| c1_rec.party_id);

         begin
          UPDATE_COUNT (c1_rec.party_id);
        exception
         when others then
            lc_message := 'Error while calling update count '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                 ,p_error_message_code =>   'XX_CS_SR01c_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => c1_rec.party_id);
        end;

        lr_request_rec.type_id := ln_type_id;
        lc_comments     := to_char(sysdate,'MON')||' Usage Request Created for '||c1_rec.party_name;
        lc_summary      := to_char(sysdate,'MON')||' Usage Request Created for '||c1_rec.party_name;
         -- Assign values to rec type
        lr_request_rec.status_name       := 'In Progress';
        lr_request_rec.description       := lc_summary;
        lr_request_rec.caller_type       := 'MPS Uasage Request';
        lr_request_rec.customer_id       := c1_rec.party_id;
        lr_request_rec.user_id           := ln_user_id;
        lr_request_rec.channel           := 'WEB'; -- setup
        lr_request_rec.comments          := lc_comments;
     --   lr_sr_rec.sales_rep_contact := sales_rep;


      begin
        log_msg('Calling service request create process for party id '|| c1_rec.party_id);

       XX_CS_MPS_UTILITIES_PKG.CREATE_SR
              (P_PARTY_ID        => c1_rec.party_id,
                P_SALES_NUMBER   => null,
                P_REQUEST_TYPE   => lc_request_type,
                P_COMMENTS       => lc_comments,
                p_sr_req_rec     => lr_request_rec,
                x_return_status  => x_return_status,
                X_RETURN_MSG     => x_return_msg);
      exception
        when others then
           lc_message := 'Error while calling SR '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                 ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                 ,p_object_id         => c1_rec.party_id);
      end;

      log_msg('Service reqest number :'|| lr_request_rec.request_number);

      -- Select Primary ship to

         BEGIN
              SELECT   HCS.SITE_USE_ID
              INTO LN_SHIP_TO
              FROM HZ_CUST_ACCOUNTS HCA
                 , HZ_CUST_SITE_USES_ALL HCS
                 , HZ_CUST_ACCT_SITES_ALL HCSA
             WHERE HCA.PARTY_ID                  = C1_REC.PARTY_ID
               AND HCA.CUST_ACCOUNT_ID           = HCSA.CUST_ACCOUNT_ID
               AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
               AND HCS.STATUS                    = 'A'
               AND HCS.PRIMARY_FLAG              = 'Y'
               AND HCS.SITE_USE_CODE             = 'SHIP_TO' ;
            exception
               when others then
                 LN_SHIP_TO  := null;
            end;

       -- Task Defenition

      IF nvl(x_return_status,'S') = 'S' then

        -- Create Task
         ln_request_id     := lr_request_rec.request_id;
         lc_request_number := lr_request_rec.request_number;
         lc_task_type_name := 'MPS Usage';
         lc_task_context   := 'MPS Usage';
          LN_TASK_STATUS_ID := 15; -- In Progress
          LN_TASK_PRIORITY := 3;

          begin
            select owner_group_id
            into ln_group_id
            from cs_incidents_all_b
            where incident_id = ln_request_id;
          end ;

          begin
           
            select task_type_id
            into ln_task_type_id
            from jtf_task_types_tl
             where name like lc_task_type_name;
          exception
             when others then
                ln_task_type_id := null;
                 lc_message := 'Error while selecting Task Type'||sqlerrm;
                Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                   ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                   ,p_error_msg          =>  lc_message
                                   ,p_object_id         => lc_request_number);
          end;

        -- Ship location details

       IF ln_task_type_id is not null then

        BEGIN
          open usage_cur;
          loop
          fetch usage_cur into usage_rec;
          exit when usage_cur%notfound;


         ln_standard_amt := NULL;
         ln_black_amt    := NULL;
         ln_black_cpc    := NULL;
         ln_color_amt    := NULL;
         ln_color_cpc    := NULL;

         --ln_overage_standard_amt := 0;
         --ln_overage_black_amt    := 0;
         --ln_overage_black_cnt    := 0;
         --ln_overage_color_amt    := 0;
         --ln_overage_color_cnt    := 0;



        /*   begin
              select nvl(black_cpc,0.02), nvl(color_cpc,0.09), overage_cost
              into ln_black_cpc, ln_color_cpc, ln_overage_cost
              from xx_cs_mps_device_b
              where ship_site_id = usage_rec.ship_site_id
              and party_id = usage_rec.party_id
              and rownum < 2;
            exception
              when others then
                 lc_message := 'Error while getting CPC '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                     ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => lc_request_number);
            end;
             */
            begin
                select organization_id
                into ln_inv_org_id
                from hr_all_organization_units
                where to_number(attribute1) = usage_rec.warehouse_id;
              exception
                when others then
                    ln_inv_org_id := null;
              end;
          -- Block

          log_msg( 'Black Count :'|| usage_rec.black_count);

          IF usage_rec.black_count > 0 then

           begin
              select cl.meaning,mt.description,
                     mt.attribute14, mv.segment3
              into lc_item, lc_item_descr, ln_item_cost, ln_sku_dept
              from cs_lookups cl,
                   mtl_system_items_b mt,
                   mtl_item_categories_v mv
              where mv.organization_id = mt.organization_id
              and mt.inventory_item_id = mv.inventory_item_id
              and  mt.segment1 = cl.meaning
              and mt.organization_id = 441
              and mv.category_set_name = 'Inventory'
              and cl.lookup_type ='XX_CS_MPS_USAGE_SKUS'
              and cl.lookup_code = 'BLACK';
            exception
               when others then
                  lc_message := 'Error while select usage sku '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                     ,p_error_message_code =>   'XX_CS_SR01a_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => lc_request_number);
           end;

           log_msg( 'standard amount: '|| usage_rec.standard_amt);
           log_msg( 'black_amt:'|| usage_rec.black_amt);
          -- log_msg( 'black_under_usage_amt:'|| usage_rec.black_under_usage_amt);

           IF ln_black_cpc IS NULL
            THEN
              ln_black_cpc := usage_rec.black_amt/usage_rec.black_count;
           END IF; -- black_under_usage_amt

           log_msg( 'black cpc: '|| ln_black_cpc);

           ln_black_cpc := nvl(ln_black_cpc,0.02);

            BEGIN

                ln_task_id := Null;

                CREATE_TASK
                      ( p_task_name          => lc_item_descr
                      , p_task_type_id       => ln_task_type_id
                      , p_status_id          => ln_task_status_id
                      , p_priority_id        => ln_task_priority
                      , p_Planned_Start_date => sysdate
                      , p_planned_effort     => null
                      , p_planned_effort_uom => null
                      , p_notes              => lc_notes
                      , p_source_object_id   => ln_request_id
                      , p_note_type          => null
                      , x_error_id           => lc_error_id
                      , x_error              => x_return_msg
                      , x_new_task_id        => ln_task_id
                      , p_note_status        => null
                      , p_Planned_End_date   => null
                      , p_owner_id           => ln_group_id
                      , p_attribute_1           => 'Black'
                      , p_attribute_2           => usage_rec.black_count
                      , p_attribute_3           => nvl(ln_black_cpc,0.02)
                      , p_attribute_4           => (usage_rec.black_count * nvl(ln_black_cpc,0.02))
                      , p_attribute_5           => lc_item
                      , p_attribute_6           => lc_item_descr
                      , p_attribute_7            => ln_ship_to --usage_rec.ship_site_id
                      , p_attribute_8            => ln_inv_org_id
                      , p_attribute_9            => ln_item_cost
                      , p_attribute_10          => null
                      , p_attribute_11          => ln_sku_dept
                      , p_attribute_12          => null
                      , p_attribute_13          => null
                      , p_attribute_14          => null
                      , p_attribute_15          => null
                      , p_context                  => lc_task_context
                      , p_assignee_id         => l_user_id
                      , p_template_id         => NULL
                    );


              EXCEPTION
                WHEN OTHERS THEN
                  lc_message := 'Error while calling new task for BLACK '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                     ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => lc_request_number);
              END;

              -- update with Request Number and Task Id
              begin
                  update xx_cs_mps_device_details
                  set request_number = lc_request_number ,
                      attribute1 = ln_task_id,
                      usage_order_date = sysdate
                  where supplies_label = 'USAGE'
                  and NVL(attribute3,1165) = usage_rec.warehouse_id
                  AND NVL(black_count,0) > 0
                  and serial_no in (
                  select serial_no from xx_cs_mps_device_b
                  where  party_id = c1_rec.party_id
                  AND ship_site_id IS NOT NULL
                  --and ship_site_id = usage_rec.ship_site_id
                  and program_type in (select meaning
                                        from cs_lookups
                                        where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                                        and tag in ('BOTH', 'USAGE')
                                        and end_date_active is null));

                  commit;
              exception
                when others then
                    lc_message := 'Error while updating with task and SR# '||lc_request_number||' '||sqlerrm;
                    Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                     ,p_error_message_code =>   'XX_CS_SR01a_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => lc_request_number);
              end;

              log_msg( 'Task for Mono clicks  :' || ln_task_id);

         end if;
         -- color
          IF usage_rec.color_count > 0 then

             begin
              select cl.meaning,mt.description,
                     mt.attribute14, mv.segment3
              into lc_item, lc_item_descr, ln_item_cost, ln_sku_dept
              from cs_lookups cl,
                   mtl_system_items_b mt,
                   mtl_item_categories_v mv
              where mv.organization_id = mt.organization_id
              and mt.inventory_item_id = mv.inventory_item_id
              and  mt.segment1 = cl.meaning
              and mt.organization_id = 441
              and mv.category_set_name = 'Inventory'
                and cl.lookup_type ='XX_CS_MPS_USAGE_SKUS'
                and cl.lookup_code = 'COLOR';
              exception
                 when others then
                    lc_message := 'Error while select usage sku '||sqlerrm;
                    Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                       ,p_error_message_code =>   'XX_CS_SR01B_ERR_LOG'
                                       ,p_error_msg          =>  lc_message
                                       ,p_object_id         => lc_request_number);
             end;


           log_msg( 'standard amount: '|| usage_rec.standard_amt);
           log_msg( 'color_amt:'|| usage_rec.color_amt);

           ln_color_cpc := usage_rec.color_amt/usage_rec.color_count;
           ln_color_cpc := nvl(ln_color_cpc,0.09);
             

           BEGIN
                ln_task_id := Null;
                      CREATE_TASK  ( p_task_name          => lc_item_descr
                        , p_task_type_id       => ln_task_type_id
                        , p_status_id          => ln_task_status_id
                        , p_priority_id        => ln_task_priority
                        , p_Planned_Start_date => sysdate
                        , p_planned_effort     => null
                        , p_planned_effort_uom => null
                        , p_notes              => lc_notes
                        , p_source_object_id   => ln_request_id
                        , x_error_id           => lc_error_id
                        , x_error              => x_return_msg
                        , x_new_task_id        => ln_task_id
                        , p_note_type          => null
                        , p_note_status        => null
                        , p_Planned_End_date   => null
                        , p_owner_id           => ln_group_id
                        , p_attribute_1           => 'Color'
                        , p_attribute_2           => usage_rec.color_count
                        , p_attribute_3           => ln_color_cpc
                        , p_attribute_4           => (usage_rec.color_count * ln_color_cpc)
                        , p_attribute_5           => lc_item
                        , p_attribute_6           => lc_item_descr
                        , p_attribute_7            => ln_ship_to --usage_rec.ship_site_id
                        , p_attribute_8            => ln_inv_org_id
                        , p_attribute_9            => ln_item_cost
                        , p_attribute_10          => null
                        , p_attribute_11          => ln_sku_dept
                        , p_attribute_12          => null
                        , p_attribute_13          => null
                        , p_attribute_14          => null
                        , p_attribute_15          => null
                        , p_context                  => lc_task_context
                        , p_assignee_id         => l_user_id
                        , p_template_id         => NULL
                      );


                EXCEPTION
                  WHEN OTHERS THEN
                    lc_message := 'Error while calling new task for COLOR '||sqlerrm;
                    Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                       ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                       ,p_error_msg          =>  lc_message
                                       ,p_object_id         => lc_request_number);
                END;

                -- update with Request Number and Task Id
                begin
                  update xx_cs_mps_device_details
                  set request_number       = lc_request_number ,
                      color_task_id        = ln_task_id,
                      usage_order_date     = sysdate
                  where supplies_label     = 'USAGE'
                  and NVL(attribute3,1165) = usage_rec.warehouse_id
                  AND NVL(color_count,0) > 0
                  and serial_no in ( select serial_no from xx_cs_mps_device_b
                                     where  party_id = c1_rec.party_id
                                     --and ship_site_id = usage_rec.ship_site_id
                                     AND ship_site_id IS NOT NULL
                                     and program_type in (select meaning
                                                          from cs_lookups
                                                          where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                                                           and tag in ('BOTH', 'USAGE')
                                      and end_date_active is null));

                  commit;
              exception
                when others then
                    lc_message := 'Error while updating with color task and SR# '||lc_request_number||' '||sqlerrm;
                    Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                     ,p_error_message_code =>   'XX_CS_SR01a_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => lc_request_number);
              end;

              log_msg( 'Task for color clicks  :' || ln_task_id);
          end if;

          --over usage
          log_msg( 'Black over usage :'|| usage_rec.over_usage);

          IF usage_rec.over_usage > 0
          THEN

            begin
              select cl.meaning,mt.description,
                     mt.attribute14, mv.segment3
              into lc_item, lc_item_descr, ln_item_cost, ln_sku_dept
              from cs_lookups cl,
                   mtl_system_items_b mt,
                   mtl_item_categories_v mv
              where mv.organization_id = mt.organization_id
              and mv.category_set_name = 'Inventory'
              and mt.inventory_item_id = mv.inventory_item_id
              and  mt.segment1 = cl.meaning
              and mt.organization_id = 441
              and cl.lookup_type ='XX_CS_MPS_USAGE_SKUS'
              and cl.lookup_code = 'OVERUSAGE';
            exception
               when others then
                  log_msg( 'Error while select usage SKU '|| SQLERRM);
                  lc_message := 'Error while select usage sku '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                     ,p_error_message_code =>   'XX_CS_SR01a_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => lc_request_number);
           end;

           log_msg( 'usage_rec.overage_amt:'||  usage_rec.overage_amt);
           log_msg( 'usage_rec.over_usage:'|| usage_rec.over_usage);

           ln_overage_cost := usage_rec.overage_amt/usage_rec.over_usage;
           ln_overage_cost := nvl(ln_overage_cost,0.09);

            BEGIN
                ln_task_id := Null;
                CREATE_TASK
                      ( p_task_name          => lc_item_descr
                      , p_task_type_id       => ln_task_type_id
                      , p_status_id          => ln_task_status_id
                      , p_priority_id        => ln_task_priority
                      , p_Planned_Start_date => sysdate
                      , p_planned_effort     => null
                      , p_planned_effort_uom => null
                      , p_notes              => lc_notes
                      , p_source_object_id   => ln_request_id
                      , x_error_id           => lc_error_id
                      , x_error              => x_return_msg
                      , x_new_task_id        => ln_task_id
                      , p_note_type          => null
                      , p_note_status        => null
                      , p_Planned_End_date   => null
                      , p_owner_id           => ln_group_id
                      , p_attribute_1           => 'Over Usage'
                      , p_attribute_2           => usage_rec.over_usage
                      , p_attribute_3           => ln_overage_cost
                      , p_attribute_4           => (usage_rec.over_usage * ln_overage_cost)
                      , p_attribute_5           => lc_item
                      , p_attribute_6           => lc_item_descr
                      , p_attribute_7            => ln_ship_to --usage_rec.ship_site_id
                      , p_attribute_8            => ln_inv_org_id
                      , p_attribute_9            => ln_item_cost
                      , p_attribute_10          => null
                      , p_attribute_11          => ln_sku_dept
                      , p_attribute_12          => null
                      , p_attribute_13          => null
                      , p_attribute_14          => null
                      , p_attribute_15          => null
                      , p_context                  => lc_task_context
                      , p_assignee_id         => l_user_id
                      , p_template_id         => NULL
                    );


              EXCEPTION
                WHEN OTHERS THEN
                  lc_message := 'Error while calling new task for OVERUSAGE '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                     ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => lc_request_number);
              END;

              -- update with Request Number and Task Id
              begin
                update xx_cs_mps_device_details
                set request_number       = lc_request_number ,
                    overage_task_id      = ln_task_id,
                    usage_order_date     = sysdate
                where supplies_label     = 'USAGE'
                and NVL(attribute3,1165)  = usage_rec.warehouse_id
                AND NVL(over_usage,0) > 0
                and serial_no in ( select serial_no from xx_cs_mps_device_b
                                   where  party_id = c1_rec.party_id
                                   --and ship_site_id = usage_rec.ship_site_id
                                   AND ship_site_id IS NOT NULL
                                   and program_type in (select meaning
                                                        from cs_lookups
                                                        where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                                                        and tag in ('BOTH', 'USAGE')
                                   and end_date_active is null));

                commit;
              exception
                when others then
                    lc_message := 'Error while updating with color task and SR# '||lc_request_number||' '||sqlerrm;
                    Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
              
                                     ,p_error_message_code =>   'XX_CS_SR01a_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => lc_request_number);
                                     end;

              log_msg( 'Task for Black overage :'|| ln_task_id);


          end if;

          -- added on June 5th
       /*   IF usage_rec.color_over_usage > 0
          THEN

            ln_overage_cost := 0;

            begin
              select cl.meaning,mt.description,
                     mt.attribute14, mv.segment3
              into lc_item, lc_item_descr, ln_item_cost, ln_sku_dept
              from cs_lookups cl,
                   mtl_system_items_b mt,
                   mtl_item_categories_v mv
              where mv.organization_id = mt.organization_id
              and mt.inventory_item_id = mv.inventory_item_id
              and  mt.segment1 = cl.meaning
              and mt.organization_id = 441
              and mv.category_set_name = 'Inventory'
              and cl.lookup_type ='XX_CS_MPS_USAGE_SKUS'
              and cl.lookup_code = 'OVERUSAGE';
            exception
               when others then
                  lc_message := 'Error while select usage sku '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                     ,p_error_message_code =>   'XX_CS_SR01a_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => lc_request_number);
           end;

           log_msg( ' usage_rec.color_overage_amt: '||  usage_rec.color_overage_amt);
           log_msg( 'usage_rec.color_over_usage:'|| usage_rec.color_over_usage);

           ln_overage_cost := usage_rec.color_overage_amt/usage_rec.color_over_usage;
           ln_overage_cost := nvl(ln_overage_cost,0.09);

            BEGIN
                ln_task_id := Null;
                CREATE_TASK
                      ( p_task_name          => lc_item_descr
                      , p_task_type_id       => ln_task_type_id
                      , p_status_id          => ln_task_status_id
                      , p_priority_id        => ln_task_priority
                      , p_Planned_Start_date => sysdate
                      , p_planned_effort     => null
                      , p_planned_effort_uom => null
                      , p_notes              => lc_notes
                      , p_source_object_id   => ln_request_id
                      , x_error_id           => lc_error_id
                      , x_error              => x_return_msg
                      , x_new_task_id        => ln_task_id
                      , p_note_type          => null
                      , p_note_status        => null
                      , p_Planned_End_date   => null
                      , p_owner_id           => ln_group_id
                      , p_attribute_1           => 'Color Over Usage'
                      , p_attribute_2           => usage_rec.color_over_usage
                      , p_attribute_3           => ln_overage_cost
                      , p_attribute_4           => (usage_rec.color_over_usage * ln_overage_cost)
                      , p_attribute_5           => lc_item
                      , p_attribute_6           => lc_item_descr
                      , p_attribute_7            => ln_ship_to --usage_rec.ship_site_id
                      , p_attribute_8            => ln_inv_org_id
                      , p_attribute_9            => ln_item_cost
                      , p_attribute_10          => null
                      , p_attribute_11          => ln_sku_dept
                      , p_attribute_15          => null
                      , p_attribute_12          => null
                      , p_attribute_13          => null
                      , p_attribute_14          => null
                      , p_context                  => lc_task_context
                      , p_assignee_id         => l_user_id
                      , p_template_id         => NULL
                    );


              EXCEPTION
                WHEN OTHERS THEN
                  lc_message := 'Error while calling new task for OVERUSAGE '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                     ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => lc_request_number);
              END;

              -- update with Request Number and Task Id
              begin
                update xx_cs_mps_device_details
                set request_number           = lc_request_number ,
                    color_overage_task_id    = ln_task_id,
                    usage_order_date     = sysdate
                where supplies_label     = 'USAGE'
                and NVL(attribute3,1165)  = usage_rec.warehouse_id
                AND NVL(color_over_usage,0) > 0
                and serial_no in ( select serial_no from xx_cs_mps_device_b
                                   where  party_id = c1_rec.party_id
                                   --and ship_site_id = usage_rec.ship_site_id
                                   AND ship_site_id IS NOT NULL
                                   and program_type in (select meaning
                                                        from cs_lookups
                                                        where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                                                        and tag in ('BOTH', 'USAGE')
                                   and end_date_active is null));

                commit;
              exception
                when others then
                    lc_message := 'Error while updating with color task and SR# '||lc_request_number||' '||sqlerrm;
                    Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.METER_REQ'
                                     ,p_error_message_code =>   'XX_CS_SR01a_ERR_LOG'
                                     ,p_error_msg          =>  lc_message
                                     ,p_object_id         => lc_request_number);
              end;

           log_msg( 'Task for Color oVerage: '|| ln_task_id);


          end if; */
         end loop;
         close usage_cur;
         end;

         -- End of USAGE cursor.
        end if; -- Task Type id
      end if; -- SR creation check

      IF ln_task_id IS NOT NULL AND ln_attach_document = 'Y'
      THEN

        log_msg(' Calling generate Report ..') ;

        -- Generate the report with all the associated serial numbers for the tasks and attach to the SR .
        generate_report(p_request_number  => lc_request_number,
                        x_file_name       => lc_file_name,
                        x_return_status   => x_return_status,
                        x_return_msg      => x_return_msg);

        IF NVL(x_return_status,'S')  = 'S' AND lc_file_name IS NOT NULL
        THEN

          log_msg(' Calling attach_document ..') ;

          attach_document(p_file_name      => lc_file_name,
                          p_request_id     => ln_request_id,
                          p_entity_name    => 'CS_INCIDENTS',
                          x_return_status  => x_return_status,
                          x_return_mesg    => x_return_msg);
        END IF;
       END IF;
    end loop;
    close c1;
    end;

  END METER_REQ;
/*********************************************************************/


PROCEDURE NO_FEED_DEVICES( X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
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

 CURSOR C_PARTY_ID IS
 SELECT DISTINCT DB.PARTY_ID
 FROM  XX_CS_MPS_DEVICE_DETAILS DT,
       XX_CS_MPS_DEVICE_B DB
  WHERE DB.DEVICE_ID = DT.DEVICE_ID
  AND  DT.LAST_UPDATE_DATE <= SYSDATE - 7
  AND DT.REQUEST_NUMBER IS NULL;

 C_PARTY_REC C_PARTY_ID%ROWTYPE;

 CURSOR c_device_id IS
 select DT.DEVICE_ID, DB.SERIAL_NO
  FROM  XX_CS_MPS_DEVICE_DETAILS DT,
       XX_CS_MPS_DEVICE_B DB
  WHERE DB.DEVICE_ID = DT.DEVICE_ID
  AND  DT.LAST_UPDATE_DATE <= SYSDATE - 7
  AND DT.REQUEST_NUMBER IS NULL
  and DB.PARTY_ID = C_PARTY_REC.PARTY_ID
  and program_type in (select meaning
                      from cs_lookups
                      where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                      and tag in ('BOTH', 'USAGE')
                      and end_date_active is null);


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
   OPEN C_PARTY_ID;
   LOOP
   FETCH C_PARTY_ID INTO C_PARTY_REC;
   EXIT WHEN C_PARTY_ID%NOTFOUND;

    LN_COUNT := 0;

    FOR R_DEVICE_ID IN C_DEVICE_ID LOOP

     ln_count := ln_count + 1;

    IF ln_count = 1 then
        lc_serial_str := 'Feed not Received for  '||r_device_id.serial_no;
        lc_device_str := r_device_id.device_id;
    else
        lc_serial_str := lc_serial_str||';'||r_device_id.serial_no;
        lc_device_str := lc_device_str||','||r_device_id.device_id;
    end if;


   END LOOP;

    IF LN_COUNT > 0 THEN
        lc_request_type := 'MPS Exception Request';
        lc_comments     := lc_serial_str;
        lc_summary      := 'Feed not received exption request';
         -- Assign values to rec type
        lr_request_rec.status_name       := 'Open';
        lr_request_rec.description       := lc_summary;
        lr_request_rec.caller_type       := 'MPS Exception Request';
        lr_request_rec.customer_id       := c_party_rec.party_id;
        lr_request_rec.user_id           := ln_user_id;
        lr_request_rec.channel           := 'WEB'; -- setup
        lr_request_rec.comments          := lc_comments;

       BEGIN
         XX_CS_MPS_UTILITIES_PKG.CREATE_SR
                  (P_PARTY_ID        => c_party_rec.party_id,
                    P_SALES_NUMBER   => null,
                    P_REQUEST_TYPE   => lc_request_type,
                    P_COMMENTS       => lc_comments,
                    p_sr_req_rec     => lr_request_rec,
                    x_return_status  => x_return_status,
                    X_RETURN_MSG     => x_return_msg);

       EXCEPTION
        when OTHERS then
          LC_MESSAGE := 'Error while calling SR create API '||sqlerrm;
                     log_exception (p_error_location        => 'XX_CS_MPS_VALIDATION_PKG.NO_FEED_DEVICES',
                                    p_error_message_code    => 'XX_CS_SR01_ERR_LOG',
                                    P_ERROR_MSG             => LC_MESSAGE,
                                    p_object_id             => c_party_rec.party_id);

        END;

    END IF;

   END LOOP;
   CLOSE C_PARTY_ID;

EXCEPTION
  when OTHERS then
    LC_MESSAGE := 'Error in '||sqlerrm;
               log_exception (p_error_location        => 'XX_CS_MPS_FLEET_PKG.NO_FEED_DEVICES',
                              p_error_message_code    => 'XX_CS_SR03_ERR_LOG',
                              P_ERROR_MSG             => LC_MESSAGE,
                              p_object_id             => -1);
 END;

END  NO_FEED_DEVICES;
/******************************************************************************/
 PROCEDURE MAIN_PROC ( X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                       X_RETCODE         OUT  NOCOPY  NUMBER,
                       P_TYPE            IN   VARCHAR2,
                       P_DEVICE_ID       IN   VARCHAR2,
                       P_GROUP_ID        IN   VARCHAR2,
                       p_debug_flag      IN   VARCHAR2)
  IS

  LC_RETURN_STATUS      VARCHAR2(50);
  LC_RETURN_MSG         VARCHAR2(1000);
  lc_msg_data            VARCHAR2(2000);
  l_initstr              VARCHAR2(2000);
  l_url                  VARCHAR2(240) := fnd_profile.value('XX_CS_MPS_APRIMO_URL');
  lc_vendor              VARCHAR2(50) := 'APRIMO';

  CURSOR C1 IS
  
  SELECT CB.INCIDENT_ID,
         CB.CUSTOMER_ID, CB.ACCOUNT_ID,
         substr(HC.ORIG_SYSTEM_REFERENCE,1,8) customer_no
         FROM CS_INCIDENTS_ALL_B CB,
       CS_INCIDENT_TYPES_TL CT,
       HZ_CUST_ACCOUNTS HC
  WHERE HC.PARTY_ID = CB.CUSTOMER_ID
  AND   CT.INCIDENT_TYPE_ID = CB.INCIDENT_TYPE_ID
  AND   CT.NAME = 'MPS Contract Request'
  AND   CB.INCIDENT_STATUS_ID = 1
  AND   CB.CUSTOMER_TICKET_NUMBER IS NULL;

  C1_REC  C1%ROWTYPE;

  BEGIN

    IF (p_debug_flag = 'Y') -- Debug flag
    THEN
      g_debug_flag  := TRUE ;
    ELSE
      g_debug_flag  := FALSE ;
    END IF;

    IF P_TYPE = 'SUBMIT' THEN
	log_msg('Starting of the program');
    log_msg('********************************************************************');
	

       log_msg('Calling Supplies Order procedure for party id : '|| p_group_id);
       log_msg('Before Calling Supplies Order Procedure...');


       SUPPLIES_ORDER(P_PARTY_ID   => P_GROUP_ID, -- Party Id
                      X_RETURN_STATUS  => LC_RETURN_STATUS,
                      X_RETURN_MSG    => LC_RETURN_MSG);

       FND_FILE.PUT_LINE(FND_FILE.LOG,'In Progress Requests Completed     :'|| to_char(sysdate, 'mm/dd/yy hh24:mi'));

       -- Misc Supplies

       MISC_SUPPLIES(P_PARTY_ID   => P_GROUP_ID, -- Party Id
                      X_RETURN_STATUS  => LC_RETURN_STATUS,
                      X_RETURN_MSG    => LC_RETURN_MSG);

        -- Email Light
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Misc Supplies process Completed     :'|| to_char(sysdate, 'mm/dd/yy hh24:mi'));

        /*  email_send (lc_return_status, lc_return_msg);

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Requests Completed     :'|| to_char(sysdate, 'mm/dd/yy hh24:mi'));  */
		--QC 30971..Business doesn't want emails to be sent for Light when they submit the program with parameter 'SUBMIT'

         -- UPDATE RETAIL CNT
            BEGIN
             log_msg('Calling Update retail cnt ..');
             UPDATE_RETAIL_CNT(P_GROUP_ID);
            EXCEPTION
              WHEN OTHERS THEN
                 LC_RETURN_MSG := 'Error while calling new task for Update Retail CNT '||sqlerrm;
                          Log_Exception ( p_error_location     =>  'XX_CS_MPS_VALIDATION_PKG.MAIN_PROC'
                                             ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                             ,p_error_msg          =>  LC_RETURN_MSG
                                             ,p_object_id         => P_group_id);
            END;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Retail Count Calculation  :'|| to_char(sysdate, 'mm/dd/yy hh24:mi'));

    ELSIF P_TYPE = 'SUPPLIES' THEN

       SUPPLIES_REQ(P_DEVICE_ID   => P_DEVICE_ID,
                          P_GROUP_ID  => P_GROUP_ID,
                          X_RETURN_STATUS  => LC_RETURN_STATUS,
                          X_RETURN_MSG    => LC_RETURN_MSG);


    ELSIF P_TYPE = 'USAGE' THEN

       METER_REQ(P_DEVICE_ID   => P_DEVICE_ID,
                          P_GROUP_ID  => P_GROUP_ID,
                          X_RETURN_STATUS  => LC_RETURN_STATUS,
                          X_RETURN_MSG    => LC_RETURN_MSG);

      ELSIF P_TYPE = 'USAGEORDER' THEN

          OM_REQ(P_DEVICE_ID      => P_DEVICE_ID,
                         P_GROUP_ID   => P_GROUP_ID,
                         X_RETURN_STATUS  => LC_RETURN_STATUS,
                         X_RETURN_MSG     => LC_RETURN_MSG);

    ELSIF P_TYPE = 'EXCEPTION' THEN

       NO_FEED_DEVICES( X_RETURN_STATUS   => LC_RETURN_STATUS,
                          X_RETURN_MSG    => LC_RETURN_MSG);

    ELSIF P_TYPE = 'CONTRACT_REQ' THEN
      BEGIN
       OPEN C1;
       LOOP
       FETCH C1 INTO C1_REC;
       EXIT WHEN C1%NOTFOUND;

          -- Call aprimo call

               -- APRIMO WEB SERVICE CALL
              l_initstr := l_initstr||'<sch:InputParameters xmlns:sch="http://officedepot.com/MPS/CCP/GetContract/Schema">';
              l_initstr := l_initstr||'<!--Optional:-->';
              l_initstr := l_initstr||'<sch:CUSTOMER>'||c1_rec.customer_no||'</sch:CUSTOMER>';
              l_initstr := l_initstr||'<sch:VENDOR>'||lc_vendor||'</sch:VENDOR>';
              l_initstr := l_initstr||'</sch:InputParameters>';


              BEGIN
                lc_msg_data := xx_cs_mps_utilities_pkg.http_post(l_url,l_initstr) ;

              EXCEPTION
                WHEN OTHERS THEN
                  lc_msg_data := 'Error while calling APRIMO API  '||SQLERRM;
               --   dbms_output.put_line('error at aprimo service '||lc_msg_data);
                  Log_Exception( p_object_id          => c1_rec.customer_id
                               , p_error_location     => 'XX_CS_MPS_VALIDATION_PKG.MAIN_PROC'
                               , p_error_message_code => 'XX_CS_REQ05_ERR_LOG'
                               , p_error_msg          => lc_msg_data
                               );
              END;

            --dbms_output.put_line('msg '||lc_msg_data);

        END LOOP;
      CLOSE C1;
      END;

    ELSIF P_TYPE = 'LIGHT' THEN
        email_send (lc_return_status, lc_return_msg);
     ELSIF P_TYPE = 'USAGEPO' THEN
             SUBMIT_PO ( P_GROUP_ID,
                            P_DEVICE_ID,
                             'USAGE',
                           
                         lc_return_status, lc_return_msg);
      ELSIF P_TYPE = 'OTHER' THEN
             SUBMIT_PO ( P_GROUP_ID,
              P_DEVICE_ID,
                             'OTHER',
                         lc_return_status, lc_return_msg);
       ELSIF P_TYPE = 'TMATERIAL' THEN
             SUBMIT_PO ( P_GROUP_ID,
                            P_DEVICE_ID,
                             'TMATERIAL',
                         lc_return_status, lc_return_msg);

        ELSIF P_TYPE = 'UPDATECOUNT' THEN
               UPDATE_COUNT (P_GROUP_ID);
    END IF;

      IF NVL(lc_return_status,'S') = 'S' then
            x_retcode := 0;
      else
            x_retcode := -1;
      end if;

    X_ERRBUF := LC_RETURN_MSG;

  END MAIN_PROC;
/*******************************************************************************/
END XX_CS_MPS_VALIDATION_PKG;
/
