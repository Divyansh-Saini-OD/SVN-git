create or replace
PACKAGE BODY XX_CRM_BULK_TEMPLATES_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name             :  XX_CRM_BULK_TEMPLATES_PKG                     |
-- | Description      :  This package contains functions which are     |
-- |                     called by                                     |
-- |                     XXTPS_FILE_UPLOADS_PKG.XXTPS_FILE_UPLOAD      |
-- |                     depending on the template code. These         |
-- |                     functions validate the data and insert it     |
-- |                     into appropriate tables.                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version  Date        Author              Remarks                   |
-- |=======  ==========  ==================  ==========================|
-- |1.0      11-JUN-2010 Mangalasundari K    Created the package body  |
-- |                     Wipro Technologies                            |
-- |1.1      16-Dec-2015 Vasu Raparla        Removed Schema References |
-- |                                            for R.12.2             |
-- |1.2      31-MAY-2016 Shubhashree R       Removed the procedure     |
-- |                                         XX_CRM_CUST_LEADS_TMPLT   |
-- |                                         for TOPS Retirement       |
-- +===================================================================+

AS


-- +===================================================================+
-- | Name        :  PROCESS_SITE_CONTACTS                              |
-- | Description :  This procedure is used to construct the table      |
-- |                Structure used by the extensiable api's.           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE PROCESS_SITE_CONTACTS
   (    p_party_site_id      IN   NUMBER
       ,p_site_contact_rec   IN   SITE_CONTACTS_REC
       ,x_return_msg         OUT  VARCHAR2
   )
IS
   le_exception                  EXCEPTION;
   ln_party_site_id              NUMBER;
   lc_user_table                 EGO_USER_ATTR_ROW_TABLE  := EGO_USER_ATTR_ROW_TABLE();
   lc_temp_user_table            EGO_USER_ATTR_ROW_TABLE  := EGO_USER_ATTR_ROW_TABLE();
   lc_row_temp_obj               EGO_USER_ATTR_ROW_OBJ    := EGO_USER_ATTR_ROW_OBJ(null,null,null,null,null,null,null,null,null,null,null,null);
   lc_data_table                 EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
   lc_temp_data_table            EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
   lc_data_temp_obj              EGO_USER_ATTR_DATA_OBJ   := EGO_USER_ATTR_DATA_OBJ(null,null,null,null,null,null,null,null);
   ln_retcode                    NUMBER;
   ln_errbuf                     VARCHAR2(2000);
   lc_rowid                      VARCHAR2(100);
   lc_failed_row_id_list         VARCHAR2(1000);
   lc_return_status              VARCHAR2(1000);
   lc_errorcode                  NUMBER;
   ln_msg_count                  NUMBER;
   lc_msg_data                   VARCHAR2(1000);
   lv_return_msg                 VARCHAR2(1000);
   lc_errors_tbl                 ERROR_HANDLER.Error_Tbl_Type;
   ln_msg_text                   VARCHAR2(32000);
   lr_site_contact_rec           SITE_CONTACTS_REC;

BEGIN

   ln_party_site_id := p_party_site_id;

   IF ln_party_site_id IS NULL THEN
      x_return_msg := 'Party Site Id is not Provided';
      RAISE le_exception;
   END IF;

   lr_site_contact_rec := p_site_contact_rec;

     build_extensible_table
      (   p_user_row_table        => lc_user_table
         ,p_user_data_table       => lc_data_table
         ,p_ext_attribs_row       => lr_site_contact_rec
         ,x_return_msg            => lv_return_msg
      );   

   IF lv_return_msg IS NOT NULL THEN
      x_return_msg := lv_return_msg;
      RAISE le_exception;
   END IF;

   HZ_EXTENSIBILITY_PUB.process_partysite_record
      (   p_api_version           => xx_cdh_cust_exten_attri_pkg.g_api_version
         ,p_party_site_id         => ln_party_site_id
         ,p_attributes_row_table  => lc_user_table
         ,p_attributes_data_table => lc_data_table
         ,x_failed_row_id_list    => lc_failed_row_id_list
         ,x_return_status         => lc_return_status
         ,x_errorcode             => lc_errorcode
         ,x_msg_count             => ln_msg_count
         ,x_msg_data              => lc_msg_data
      );

fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>PROCESS_SITE_CONTACTS: ');
fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>Return status: ' || lc_return_status);
fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>Error code: ' || lc_errorcode);
fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>Msg count: ' || ln_msg_count);
fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>Msg data: ' || lc_msg_data);


   IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
      x_return_msg := NULL;
      COMMIT;
   ELSE
      IF ln_msg_count > 0 THEN
         ERROR_HANDLER.Get_Message_List(lc_errors_tbl);
         FOR i IN 1..lc_errors_tbl.COUNT
         LOOP
            ln_msg_text := ln_msg_text||' '||lc_errors_tbl(i).message_text;
         END LOOP;
         x_return_msg := ln_msg_text;
       END IF;
    END IF;
fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>Return msg in process site contacts: ' || x_return_msg);
EXCEPTION
   WHEN le_exception THEN
      NULL;
   WHEN OTHERS THEN
      x_return_msg := 'Unexpected Error - '||SQLERRM;
END PROCESS_SITE_CONTACTS;

-- +===================================================================+
-- | Name        :  Build_extensible_table                             |
-- | Description :  This procedure is used to construct the table      |
-- |                Structure used by the extensiable api's.           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |              p_user_row_table is table structure contains the     |
-- |              Attribute group information                          |
-- |              p_user_data_table is table structure contains the    |
-- |              attribute columns informations                       |
-- |              p_ext_attribs_row is staging table row information   |
-- |              which needs to be create/updated to extensible attrs |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Build_extensible_table
      (    p_user_row_table  IN OUT EGO_USER_ATTR_ROW_TABLE
          ,p_user_data_table IN OUT EGO_USER_ATTR_DATA_TABLE
          ,p_ext_attribs_row IN OUT SITE_CONTACTS_REC
          ,x_return_msg         OUT VARCHAR2
      )
IS

--Retrieve Attribute Group id based on the Attribute Group code and
-- Flexfleid Name
CURSOR c_ego_attr_grp_id ( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
IS
SELECT attr_group_id
FROM   ego_fnd_dsc_flx_ctx_ext
WHERE  descriptive_flexfield_name    = p_flexfleid_name
AND    descriptive_flex_context_code = p_context_code;


--
CURSOR c_ext_attr_name( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
IS
SELECT *
FROM   fnd_descr_flex_column_usages
WHERE  descriptive_flexfield_name    = p_flexfleid_name
AND    descriptive_flex_context_code = p_context_code
AND    enabled_flag                  = 'Y';

TYPE l_xxod_ext_attribs_stg IS TABLE OF c_ext_attr_name%ROWTYPE INDEX BY BINARY_INTEGER;
lx_od_ext_attrib_stg        l_xxod_ext_attribs_stg;

lc_row_temp_obj             EGO_USER_ATTR_ROW_OBJ := EGO_USER_ATTR_ROW_OBJ(null,null,null,null,null,null,null,null,null,null,null,null);

lc_data_temp_obj            EGO_USER_ATTR_DATA_OBJ:= EGO_USER_ATTR_DATA_OBJ(null,null,null,null,null,null,null,null);
lc_count                    NUMBER:=1;
lc_flexfleid_name            VARCHAR2(50);
lc_attr_group_id             NUMBER;
lc_exception                EXCEPTION;


BEGIN

lc_flexfleid_name := 'HZ_PARTY_SITES_GROUP';


OPEN  c_ego_attr_grp_id ( lc_flexfleid_name,'SITE_CONTACTS' );
FETCH c_ego_attr_grp_id INTO lc_attr_group_id;
CLOSE c_ego_attr_grp_id;

IF lc_attr_group_id IS NULL THEN
   x_return_msg := 'Attribute Group ''Site Contacts'' is not found';
   RAISE lc_exception;
END IF;

OPEN  c_ext_attr_name ( lc_flexfleid_name,'SITE_CONTACTS');
FETCH c_ext_attr_name BULK COLLECT INTO lx_od_ext_attrib_stg;
CLOSE c_ext_attr_name;

p_user_row_table.extend;
p_user_row_table(1)                  := lc_row_temp_obj;
p_user_row_table(1).Row_identifier   := P_ext_attribs_row.record_id;
p_user_row_table(1).Attr_group_id    := lc_attr_group_id;
p_user_row_table(1).transaction_type := EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE;

FOR i IN 1 .. lx_od_ext_attrib_stg.COUNT
LOOP

   p_user_data_table.extend;
   p_user_data_table(i)                := lc_data_temp_obj;
   p_user_data_table(i).ROW_IDENTIFIER := P_EXT_ATTRIBS_ROW.record_id;
   p_user_data_table(i).ATTR_NAME      := lx_od_ext_attrib_stg(i).END_USER_COLUMN_NAME;

   IF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR1' THEN
      p_user_data_table(i).attr_value_str := p_ext_attribs_row.c_ext_attr1;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR2' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR2;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR3' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR3;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR4' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR4;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR5' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR5;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR6' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR6;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR7' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR7;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR8' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR8;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR9' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR9;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR10' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR10;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR11' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR11;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR12' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR12;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR13' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR13;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR14' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR14;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR15' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR15;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR16' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR16;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR17' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR17;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR18' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR18;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR19' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR19;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR20' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR20;

   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR1' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR1;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR2' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR2;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR3' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR3;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR4' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR4;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR5' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR5;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR6' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR6;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR7' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR7;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR8' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR8;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR9' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR9;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR10' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR10;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR11' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR11;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR12' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR12;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR13' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR13;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR14' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR14;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR15' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR15;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR16' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR16;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR17' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR17;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR18' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR18;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR19' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR19;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR20' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR20;

   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR1' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR1;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR2' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR2;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR3' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR3;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR4' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR4;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR5' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR5;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR6' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR6;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR7' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR7;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR8' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR8;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR9' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR9;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR10' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR10;
   END IF;
END LOOP;
EXCEPTION
   WHEN lc_exception THEN
      NULL;
   WHEN OTHERS THEN
      x_return_msg := 'Unexpected Error in Build Extensible Table'||SQLERRM;
      fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>Return msg in Build_extensible_table: ' || x_return_msg);
END Build_extensible_table;

END XX_CRM_BULK_TEMPLATES_PKG;
/
SHOW ERR;