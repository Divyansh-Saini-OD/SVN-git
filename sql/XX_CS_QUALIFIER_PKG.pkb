CREATE OR REPLACE
PACKAGE BODY "XX_CS_QUALIFIER_PKG" AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_QUALIFIER_PKG                                         |
-- | Rice ID :                                                         |
-- | Description: This package contains the PROCEDURES that CREATES    |
-- |              Custom Territory qualifiers                          |
-- |                                                                   |
-- | Order                                                             |
-- | Vendor                                                            |
-- | Warehouse                                                         |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       115-Aug-07   Raj Jagarlamudi  Initial draft version      |
-- +===================================================================+

/**************************************************************
-- Order Level Qualifier
***************************************************************/
PROCEDURE Q_ORDER IS
 l_return_status       VARCHAR2(100) := 'S';
   l_Msg_Count          NUMBER;
   l_Msg_Data          VARCHAR2(100);

   p_Seed_Qual_Rec        JTF_QUALIFIER_PUB.Seed_Qual_Rec_Type;
   p_Qual_Usgs_Rec        JTF_QUALIFIER_PUB.Qual_Usgs_All_Rec_Type;
   l_Seed_Qual_out_Rec    JTF_QUALIFIER_PUB.Seed_Qual_Out_Rec_Type;
   l_Qual_Usgs_out_Rec    JTF_QUALIFIER_PUB.Qual_Usgs_All_Out_Rec_Type;

   l_msg_index_out       NUMBER;
   l_sequence_id          number;
   l_org_id      NUMBER;

BEGIN
  BEGIN
  begin SELECT jtf_seeded_qual_s.nextval into l_sequence_id from dual; end;

  l_org_id := to_number(FND_PROFILE.VALUE('ORG_ID'));
  fnd_client_info.set_org_context(l_org_id);

 /**************************************************************************/
  p_seed_qual_rec.SEEDED_QUAL_ID         :=  l_sequence_id;
  p_seed_qual_rec.QUAL_TYPE_ID            :=  Null;
  p_seed_qual_rec.LAST_UPDATE_DATE        :=  sysdate;
  p_seed_qual_rec.LAST_UPDATED_BY         :=  2024;
  p_seed_qual_rec.CREATION_DATE           :=  sysdate;
  p_seed_qual_rec.CREATED_BY              :=  2024;
p_seed_qual_rec.LAST_UPDATE_LOGIN       :=  0;
p_seed_qual_rec.NAME                    :=  'Order Line Type';
p_seed_qual_rec.DESCRIPTION             :=  'Order Line Type';
p_seed_qual_rec.ORG_ID                  :=  l_org_id;

p_qual_usgs_rec.QUAL_USG_ID     := l_sequence_id;
p_qual_usgs_rec.LAST_UPDATE_DATE   := sysdate;
p_qual_usgs_rec.LAST_UPDATED_BY :=  2024;
p_qual_usgs_rec.CREATION_DATE := sysdate;
p_qual_usgs_rec.CREATED_BY := 2024;
p_qual_usgs_rec.APPLICATION_SHORT_NAME := 'JTF';
--p_qual_usgs_rec.SEEDED_QUAL_ID := l_sequence_id;
p_qual_usgs_rec.QUAL_TYPE_USG_ID := -1006;
p_qual_usgs_rec.ENABLED_FLAG := 'Y';
p_qual_usgs_rec.QUAL_COL1 := 'LOOKUP_CODE';
p_qual_usgs_rec.QUAL_COL1_ALIAS := 'SQUAL_CHAR25';
p_qual_usgs_rec.QUAL_COL1_DATATYPE := 'VARCHAR2';
p_qual_usgs_rec.QUAL_COL1_TABLE := 'FND_LOOKUP_VALUES';
p_qual_usgs_rec.QUAL_COL1_TABLE_ALIAS := 'FND_LOOKUP_VALUES';
p_qual_usgs_rec.PRIM_INT_CDE_COL := null;
p_qual_usgs_rec.PRIM_INT_CDE_COL_DATATYPE := null;
p_qual_usgs_rec.PRIM_INT_CDE_COL_ALIAS := null;
p_qual_usgs_rec.SEC_INT_CDE_COL := null;
p_qual_usgs_rec.SEC_INT_CDE_COL_ALIAS := null;
p_qual_usgs_rec.sec_int_cde_col_datatype := null;
p_qual_usgs_rec.INT_CDE_COL_TABLE := null;
p_qual_usgs_rec.INT_CDE_COL_TABLE_ALIAS := null;
p_qual_usgs_rec.SEEDED_FLAG := 'N';
p_qual_usgs_rec.DISPLAY_TYPE := 'CHAR';
p_qual_usgs_rec.LOV_SQL := 'SELECT c.meaning col1_value, c.lookup_code col2_value FROM cs_lookups c WHERE c.lookup_type = ''XX_OD_ORDER_ITEM_TYPE'' AND c.enabled_flag = ''Y'' AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(c.start_date_active, sysdate)) AND TRUNC(NVL(c.end_date_active, SYSDATE)) AND c.meaning LIKE NVL(:system.cursor_value || ''%'', ''%'') ORDER BY col1_value';
p_qual_usgs_rec.CONVERT_TO_ID_FLAG := 'N';
p_qual_usgs_rec.COLUMN_COUNT := 1;
p_qual_usgs_rec.FORMATTING_FUNCTION_FLAG := 'N';
p_qual_usgs_rec.FORMATTING_FUNCTION_NAME := null;
p_qual_usgs_rec.SPECIAL_FUNCTION_FLAG := 'N';
p_qual_usgs_rec.SPECIAL_FUNCTION_NAME := null;
p_qual_usgs_rec.ENABLE_LOV_VALIDATION := null;
p_qual_usgs_rec.DISPLAY_SQL1 := 'SELECT c.meaning FROM cs_lookups c WHERE c.lookup_type = ''XX_OD_ORDER_ITEM_TYPE'' AND c.enabled_flag = ''Y'' AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(c.start_date_active, sysdate)) AND TRUNC(NVL(c.end_date_active, SYSDATE)) AND c.lookup_code = ' ;
p_qual_usgs_rec.LOV_SQL2 := null;
p_qual_usgs_rec.DISPLAY_SQL2 := null;
p_qual_usgs_rec.LOV_SQL3 := null;
p_qual_usgs_rec.DISPLAY_SQL3 := null;
p_qual_usgs_rec.ORG_ID := l_org_id;
p_qual_usgs_rec.RULE1 := 'SELECT  /*+ INDEX (jtv jtf_terr_values_n8) (jtdr jtf_terr_denorm_rules_n2) (jtq jtf_terr_qual_n2) */' || chr(10) || ' DISTINCT jtdr.terr_id, jtdr.absolute_rank, jtdr.related_terr_id, jtdr.top_level_terr_id, jtdr.num_winners ' || chr(10) || ' FROM jtf_terr_values_all jtv, jtf_terr_denorm_rules_all jtdr, jtf_terr_qual_all jtq ' || chr(10) || ' WHERE jtv.COMPARISON_OPERATOR = ''='' AND jtv.low_value_char = p_rec.SQUAL_CHAR25(i) AND jtv.terr_qual_id = jtq.terr_qual_id ' || chr(10) || 'AND jtdr.source_id = -1002 AND jtdr.qual_type_id = lp_qual_type_id AND ' || chr(10) || 'jtdr.related_terr_id = jtq.terr_id AND jtq.qual_usg_id = ' || l_sequence_id;
p_qual_usgs_rec.RULE2 := 'SELECT  /*+ INDEX (jtv jtf_terr_values_n8) (jtdr jtf_terr_denorm_rules_n2) (jtq jtf_terr_qual_n2) */' || chr(10) || ' DISTINCT jtdr.terr_id, jtdr.absolute_rank, jtdr.related_terr_id, jtdr.top_level_terr_id, jtdr.num_winners ' || chr(10) || ' FROM jtf_terr_values_all jtv, jtf_terr_denorm_rules_all jtdr, jtf_terr_qual_all jtq ' || chr(10) || ' WHERE jtv.COMPARISON_OPERATOR = ''<>'' AND ( jtv.low_value_char <> p_rec.SQUAL_CHAR25(i) OR p_rec.SQUAL_CHAR25(i) is null ) ' || chr(10) || 'AND jtv.terr_qual_id = jtq.terr_qual_id AND jtdr.source_id = -1002 AND ' || chr(10) || 'jtdr.qual_type_id = lp_qual_type_id AND jtdr.related_terr_id = jtq.terr_id AND jtq.qual_usg_id = ' || l_sequence_id;
p_qual_usgs_rec.DISPLAY_SEQUENCE := null;
p_qual_usgs_rec.DISPLAY_LENGTH := null;
p_qual_usgs_rec.JSP_LOV_SQL := null;
p_qual_usgs_rec.use_in_lookup_flag := null;

 JTF_QUALIFIER_PUB.Create_Qualifier
  (p_api_version         => 1.0,
   p_Init_Msg_List       => FND_API.G_TRUE,
   p_Commit              => FND_API.G_FALSE,
   x_return_status     => l_return_status,
   x_Msg_Count         => l_Msg_Count,
   x_Msg_Data          => l_Msg_Data,
   p_Seed_Qual_Rec     => p_Seed_Qual_Rec,
   p_Qual_Usgs_Rec     => p_Qual_Usgs_Rec,
   x_Seed_Qual_Rec     => l_Seed_Qual_out_Rec,
   x_Qual_Usgs_Rec     => l_Qual_Usgs_out_Rec );

  dbms_output.put_line('Status:'||l_return_status);
  dbms_output.put_line('Msg count:'||l_msg_count);
  dbms_output.put_line('msg Data:'||l_msg_data);
  dbms_output.put_line('end');

exception
when others then
    dbms_output.put_line('Error:' || SQLERRM);
END;

begin
  p_seed_qual_rec.ORG_ID                  := -3113;
  p_qual_usgs_rec.ORG_ID                  := -3113;

   JTF_QUALIFIER_PUB.Create_Qualifier
  (p_api_version         => 1.0,
   p_Init_Msg_List       => FND_API.G_TRUE,
   p_Commit              => FND_API.G_FALSE,
   x_return_status     => l_return_status,
   x_Msg_Count         => l_Msg_Count,
   x_Msg_Data          => l_Msg_Data,
   p_Seed_Qual_Rec     => p_Seed_Qual_Rec,
   p_Qual_Usgs_Rec     => p_Qual_Usgs_Rec,
   x_Seed_Qual_Rec     => L_Seed_Qual_out_Rec,
   x_Qual_Usgs_Rec     => L_Qual_Usgs_out_Rec );

  dbms_output.put_line('Status:'||l_return_status);
  dbms_output.put_line('Msg count:'||l_msg_count);
  dbms_output.put_line('msg Data:'||l_msg_data);
  dbms_output.put_line('end');
exception
when others then
    dbms_output.put_line('Error:' || SQLERRM);
end;

END;


/**************************************************************
-- Vendor level Qualifier
***************************************************************/
PROCEDURE Q_VENDOR IS
 l_return_status       VARCHAR2(100) := 'S';
   l_Msg_Count          NUMBER;
   l_Msg_Data          VARCHAR2(100);

   p_Seed_Qual_Rec        JTF_QUALIFIER_PUB.Seed_Qual_Rec_Type;
   p_Qual_Usgs_Rec        JTF_QUALIFIER_PUB.Qual_Usgs_All_Rec_Type;
   l_Seed_Qual_out_Rec    JTF_QUALIFIER_PUB.Seed_Qual_Out_Rec_Type;
   l_Qual_Usgs_out_Rec    JTF_QUALIFIER_PUB.Qual_Usgs_All_Out_Rec_Type;

   l_msg_index_out       NUMBER;
   l_sequence_id          number;
   l_org_id      NUMBER;

BEGIN
  BEGIN
  begin SELECT jtf_seeded_qual_s.nextval into l_sequence_id from dual; end;

l_org_id := to_number(FND_PROFILE.VALUE('ORG_ID'));
fnd_client_info.set_org_context(l_org_id);

 /**************************************************************************/
p_seed_qual_rec.SEEDED_QUAL_ID         :=  l_sequence_id;
p_seed_qual_rec.QUAL_TYPE_ID            :=  Null;
p_seed_qual_rec.LAST_UPDATE_DATE        :=  sysdate;
p_seed_qual_rec.LAST_UPDATED_BY         :=  2024;
p_seed_qual_rec.CREATION_DATE           :=  sysdate;
p_seed_qual_rec.CREATED_BY              :=  2024;
p_seed_qual_rec.LAST_UPDATE_LOGIN       :=  0;
p_seed_qual_rec.NAME                    :=  'Vendor';
p_seed_qual_rec.DESCRIPTION             :=  'Vendor';
p_seed_qual_rec.ORG_ID                  :=  l_org_id;

p_qual_usgs_rec.QUAL_USG_ID     := l_sequence_id;
p_qual_usgs_rec.LAST_UPDATE_DATE   := sysdate;
p_qual_usgs_rec.LAST_UPDATED_BY :=  2024;
p_qual_usgs_rec.CREATION_DATE := sysdate;
p_qual_usgs_rec.CREATED_BY := 2024;
p_qual_usgs_rec.APPLICATION_SHORT_NAME := 'JTF';
--p_qual_usgs_rec.SEEDED_QUAL_ID := l_sequence_id;
p_qual_usgs_rec.QUAL_TYPE_USG_ID := -1006;
p_qual_usgs_rec.ENABLED_FLAG := 'Y';
p_qual_usgs_rec.QUAL_COL1 := 'VENDOR_ID';
p_qual_usgs_rec.QUAL_COL1_ALIAS := 'SQUAL_NUM38';
p_qual_usgs_rec.QUAL_COL1_DATATYPE := 'NUMBER';
p_qual_usgs_rec.QUAL_COL1_TABLE := 'PO_VENDORS';
p_qual_usgs_rec.QUAL_COL1_TABLE_ALIAS := 'PO_VENDORS';
p_qual_usgs_rec.PRIM_INT_CDE_COL := null;
p_qual_usgs_rec.PRIM_INT_CDE_COL_DATATYPE := null;
p_qual_usgs_rec.PRIM_INT_CDE_COL_ALIAS := null;
p_qual_usgs_rec.SEC_INT_CDE_COL := null;
p_qual_usgs_rec.SEC_INT_CDE_COL_ALIAS := null;
p_qual_usgs_rec.sec_int_cde_col_datatype := null;
p_qual_usgs_rec.INT_CDE_COL_TABLE := null;
p_qual_usgs_rec.INT_CDE_COL_TABLE_ALIAS := null;
p_qual_usgs_rec.SEEDED_FLAG := 'N';
p_qual_usgs_rec.DISPLAY_TYPE := 'CHAR';
p_qual_usgs_rec.LOV_SQL := 'SELECT vendor_name || '' : '' || segment1 col1_value, vendor_id col2_value FROM po_vendors ORDER BY vendor_name';
p_qual_usgs_rec.CONVERT_TO_ID_FLAG := 'Y';
p_qual_usgs_rec.COLUMN_COUNT := 1;
p_qual_usgs_rec.FORMATTING_FUNCTION_FLAG := 'N';
p_qual_usgs_rec.FORMATTING_FUNCTION_NAME := null;
p_qual_usgs_rec.SPECIAL_FUNCTION_FLAG := 'N';
p_qual_usgs_rec.SPECIAL_FUNCTION_NAME := null;
p_qual_usgs_rec.ENABLE_LOV_VALIDATION := null;
p_qual_usgs_rec.DISPLAY_SQL1 := 'SELECT c.vendor_name || '' : '' || c.segment1 FROM po_vendors c WHERE c.vendor_id =';
p_qual_usgs_rec.LOV_SQL2 := null;
p_qual_usgs_rec.DISPLAY_SQL2 := null;
p_qual_usgs_rec.LOV_SQL3 := null;
p_qual_usgs_rec.DISPLAY_SQL3 := null;
p_qual_usgs_rec.ORG_ID := l_org_id;
p_qual_usgs_rec.RULE1 := 'SELECT /*+ INDEX (jtv jtf_terr_values_n9) (jtdr jtf_terr_denorm_rules_n2) (jtq jtf_terr_qual_n2) */ ' || chr(10) || 'DISTINCT jtdr.terr_id , jtdr.absolute_rank , jtdr.related_terr_id , jtdr.top_level_terr_id , jtdr.num_winners ' || chr(10) || ' FROM jtf_terr_values_all jtv, jtf_terr_denorm_rules_all jtdr, jtf_terr_qual_all jtq ' || chr(10) || ' WHERE ( ( p_rec.squal_num38(i) = jtv.low_value_char_id AND jtv.COMPARISON_OPERATOR = ''='' ) ) AND jtv.terr_qual_id = jtq.terr_qual_id ' || chr(10) || ' AND jtdr.source_id = -1002 AND jtdr.related_terr_id = jtq.terr_id ' || chr(10) || ' AND jtq.qual_usg_id = ' || l_sequence_id;
p_qual_usgs_rec.RULE2 := 'SELECT /*+ INDEX (jtv jtf_terr_values_n9) (jtdr jtf_terr_denorm_rules_n2) (jtq jtf_terr_qual_n2) */ ' || chr(10) || 'DISTINCT jtdr.terr_id , jtdr.absolute_rank , jtdr.related_terr_id , jtdr.top_level_terr_id , jtdr.num_winners ' || chr(10) || ' FROM jtf_terr_values_all jtv, jtf_terr_denorm_rules_all jtdr, jtf_terr_qual_all jtq ' || chr(10) || ' WHERE ( ( ( p_rec.squal_num38(i) <> jtv.low_value_char_id OR p_rec.squal_num38(i) IS NULL) AND jtv.COMPARISON_OPERATOR = ''<>'' ) ) ' || chr(10) || ' AND jtv.terr_qual_id = jtq.terr_qual_id AND jtdr.source_id = -1002 ' || chr(10) || ' AND jtdr.related_terr_id = jtq.terr_id AND jtq.qual_usg_id = '|| l_sequence_id;
p_qual_usgs_rec.DISPLAY_SEQUENCE := null;
p_qual_usgs_rec.DISPLAY_LENGTH := null;
p_qual_usgs_rec.JSP_LOV_SQL := null;
p_qual_usgs_rec.use_in_lookup_flag := null;

 JTF_QUALIFIER_PUB.Create_Qualifier
  (p_api_version         => 1.0,
   p_Init_Msg_List       => FND_API.G_TRUE,
   p_Commit              => FND_API.G_FALSE,
   x_return_status     => l_return_status,
   x_Msg_Count         => l_Msg_Count,
   x_Msg_Data          => l_Msg_Data,
   p_Seed_Qual_Rec     => p_Seed_Qual_Rec,
   p_Qual_Usgs_Rec     => p_Qual_Usgs_Rec,
   x_Seed_Qual_Rec     => l_Seed_Qual_out_Rec,
   x_Qual_Usgs_Rec     => l_Qual_Usgs_out_Rec );

  dbms_output.put_line('Status:'||l_return_status);
  dbms_output.put_line('Msg count:'||l_msg_count);
  dbms_output.put_line('msg Data:'||l_msg_data);
  dbms_output.put_line('end');

exception
when others then
    dbms_output.put_line('Error:' || SQLERRM);

END;

BEGIN
  p_qual_usgs_rec.ORG_ID := -3113;
  p_seed_qual_rec.ORG_ID := -3113;
  JTF_QUALIFIER_PUB.Create_Qualifier
  (p_api_version         => 1.0,
   p_Init_Msg_List       => FND_API.G_TRUE,
   p_Commit              => FND_API.G_FALSE,
   x_return_status     => l_return_status,
   x_Msg_Count         => l_Msg_Count,
   x_Msg_Data          => l_Msg_Data,
   p_Seed_Qual_Rec     => p_Seed_Qual_Rec,
   p_Qual_Usgs_Rec     => p_Qual_Usgs_Rec,
   x_Seed_Qual_Rec     => l_Seed_Qual_out_Rec,
   x_Qual_Usgs_Rec     => l_Qual_Usgs_out_Rec );

  dbms_output.put_line('Status:'||l_return_status);
  dbms_output.put_line('Msg count:'||l_msg_count);
  dbms_output.put_line('msg Data:'||l_msg_data);
  dbms_output.put_line('end');

  exception
  when others then
    dbms_output.put_line('Error:' || SQLERRM);
  END;
END;

/**************************************************************
-- Warehouse Level Qualifier
***************************************************************/
PROCEDURE Q_WAREHOUSE IS
l_return_status       VARCHAR2(100) := 'S';
   l_Msg_Count          NUMBER;
   l_Msg_Data          VARCHAR2(100);

   p_Seed_Qual_Rec        JTF_QUALIFIER_PUB.Seed_Qual_Rec_Type;
   p_Qual_Usgs_Rec        JTF_QUALIFIER_PUB.Qual_Usgs_All_Rec_Type;
   l_Seed_Qual_out_Rec    JTF_QUALIFIER_PUB.Seed_Qual_Out_Rec_Type;
   l_Qual_Usgs_out_Rec    JTF_QUALIFIER_PUB.Qual_Usgs_All_Out_Rec_Type;
   v_Seed_Qual_out_Rec    JTF_QUALIFIER_PUB.Seed_Qual_Out_Rec_Type;
   v_Qual_Usgs_out_Rec    JTF_QUALIFIER_PUB.Qual_Usgs_All_Out_Rec_Type;

   l_msg_index_out       NUMBER;
   l_sequence_id          number;
   l_org_id      NUMBER;

BEGIN

begin
begin SELECT jtf_seeded_qual_s.nextval into l_sequence_id from dual; end;

l_org_id := to_number(FND_PROFILE.VALUE('ORG_ID'));
--territor management org_id : -3113
fnd_client_info.set_org_context(l_org_id);

 /**************************************************************************/
p_seed_qual_rec.SEEDED_QUAL_ID         :=  l_sequence_id;
p_seed_qual_rec.QUAL_TYPE_ID            :=  Null;
p_seed_qual_rec.LAST_UPDATE_DATE        :=  sysdate;
p_seed_qual_rec.LAST_UPDATED_BY         :=  2024;
p_seed_qual_rec.CREATION_DATE           :=  sysdate;
p_seed_qual_rec.CREATED_BY              :=  2024;
p_seed_qual_rec.LAST_UPDATE_LOGIN       :=  0;
p_seed_qual_rec.NAME                    :=  'Warehouse';
p_seed_qual_rec.DESCRIPTION             :=  'Warehouse';
p_seed_qual_rec.ORG_ID                  :=  l_org_id;

p_qual_usgs_rec.QUAL_USG_ID     := l_sequence_id;
p_qual_usgs_rec.LAST_UPDATE_DATE   := sysdate;
p_qual_usgs_rec.LAST_UPDATED_BY :=  2024;
p_qual_usgs_rec.CREATION_DATE := sysdate;
p_qual_usgs_rec.CREATED_BY := 2024;
p_qual_usgs_rec.APPLICATION_SHORT_NAME := 'JTF';
--p_qual_usgs_rec.SEEDED_QUAL_ID := l_sequence_id;
p_qual_usgs_rec.QUAL_TYPE_USG_ID := -1006;
p_qual_usgs_rec.ENABLED_FLAG := 'Y';
p_qual_usgs_rec.QUAL_COL1 := 'ORGANIZATION_ID';
p_qual_usgs_rec.QUAL_COL1_ALIAS := 'SQUAL_NUM39';
p_qual_usgs_rec.QUAL_COL1_DATATYPE := 'NUMBER';
p_qual_usgs_rec.QUAL_COL1_TABLE := 'HR_ALL_ORGANIZATION_UNITS';
p_qual_usgs_rec.QUAL_COL1_TABLE_ALIAS := 'HR_ALL_ORGANIZATION_UNITS';
p_qual_usgs_rec.PRIM_INT_CDE_COL := null;
p_qual_usgs_rec.PRIM_INT_CDE_COL_DATATYPE := null;
p_qual_usgs_rec.PRIM_INT_CDE_COL_ALIAS := null;
p_qual_usgs_rec.SEC_INT_CDE_COL := null;
p_qual_usgs_rec.SEC_INT_CDE_COL_ALIAS := null;
p_qual_usgs_rec.sec_int_cde_col_datatype := null;
p_qual_usgs_rec.INT_CDE_COL_TABLE := null;
p_qual_usgs_rec.INT_CDE_COL_TABLE_ALIAS := null;
p_qual_usgs_rec.SEEDED_FLAG := 'N';
p_qual_usgs_rec.DISPLAY_TYPE := 'CHAR';
p_qual_usgs_rec.LOV_SQL := 'SELECT org.organization_name col1_value, org.organization_id col2_value FROM org_organization_definitions org ORDER BY org.organization_code';
p_qual_usgs_rec.CONVERT_TO_ID_FLAG := 'Y';
p_qual_usgs_rec.COLUMN_COUNT := 1;
p_qual_usgs_rec.FORMATTING_FUNCTION_FLAG := 'N';
p_qual_usgs_rec.FORMATTING_FUNCTION_NAME := null;
p_qual_usgs_rec.SPECIAL_FUNCTION_FLAG := 'N';
p_qual_usgs_rec.SPECIAL_FUNCTION_NAME := null;
p_qual_usgs_rec.ENABLE_LOV_VALIDATION := null;
p_qual_usgs_rec.DISPLAY_SQL1 := 'SELECT c.organization_name FROM org_organization_definitions c WHERE c.organization_id =';
p_qual_usgs_rec.LOV_SQL2 := null;
p_qual_usgs_rec.DISPLAY_SQL2 := null;
p_qual_usgs_rec.LOV_SQL3 := null;
p_qual_usgs_rec.DISPLAY_SQL3 := null;
p_qual_usgs_rec.ORG_ID := l_org_id;
p_qual_usgs_rec.RULE1 := 'SELECT /*+ INDEX (jtv jtf_terr_values_n9) (jtdr tf_terr_denorm_rules_n2)(jtq jtf_terr_qual_n2)*/ ' || chr(10) || ' DISTINCT jtdr.terr_id , jtdr.absolute_rank , jtdr.related_terr_id , jtdr.top_level_terr_id , jtdr.num_winners ' || chr(10) || ' FROM jtf_terr_values_all jtv, jtf_terr_denorm_rules_all jtdr, jtf_terr_qual_all jtq ' || chr(10) || ' WHERE ((p_rec.squal_num39(i) = jtv.low_value_char_id AND jtv.COMPARISON_OPERATOR = ''='' )) ' || chr(10) || ' AND jtv.terr_qual_id = jtq.terr_qual_id AND jtdr.source_id = -1002 AND jtdr.related_terr_id = jtq.terr_id ' || chr(10) || ' AND jtq.qual_usg_id = ' || l_sequence_id;
p_qual_usgs_rec.RULE2 := 'SELECT /*+ INDEX (jtv jtf_terr_values_n9) (jtdr tf_terr_denorm_rules_n2)(jtq jtf_terr_qual_n2)*/ ' || chr(10) || ' DISTINCT jtdr.terr_id , jtdr.absolute_rank , jtdr.related_terr_id , jtdr.top_level_terr_id , jtdr.num_winners ' || chr(10) || ' FROM jtf_terr_values_all jtv, jtf_terr_denorm_rules_all jtdr, jtf_terr_qual_all jtq ' || chr(10) || ' WHERE (((p_rec.squal_num39(i) <> jtv.low_value_char_id OR p_rec.squal_num39(i) IS NULL) AND jtv.COMPARISON_OPERATOR = ''<>'' )) ' || chr(10) || ' AND jtv.terr_qual_id = jtq.terr_qual_id AND jtdr.source_id = -1002 ' || chr(10) || ' AND jtdr.related_terr_id = jtq.terr_id AND jtq.qual_usg_id = ' ||l_sequence_id;
p_qual_usgs_rec.DISPLAY_SEQUENCE := null;
p_qual_usgs_rec.DISPLAY_LENGTH := null;
p_qual_usgs_rec.JSP_LOV_SQL := null;
p_qual_usgs_rec.use_in_lookup_flag := null;

 JTF_QUALIFIER_PUB.Create_Qualifier
  (p_api_version         => 1.0,
   p_Init_Msg_List       => FND_API.G_TRUE,
   p_Commit              => FND_API.G_FALSE,
   x_return_status     => l_return_status,
   x_Msg_Count         => l_Msg_Count,
   x_Msg_Data          => l_Msg_Data,
   p_Seed_Qual_Rec     => p_Seed_Qual_Rec,
   p_Qual_Usgs_Rec     => p_Qual_Usgs_Rec,
   x_Seed_Qual_Rec     => l_Seed_Qual_out_Rec,
   x_Qual_Usgs_Rec     => l_Qual_Usgs_out_Rec );

  dbms_output.put_line('Status:'||l_return_status);
  dbms_output.put_line('Msg count:'||l_msg_count);
  dbms_output.put_line('msg Data:'||l_msg_data);
  dbms_output.put_line('end');

exception
when others then
    dbms_output.put_line('Error:' || SQLERRM);

end;

begin
 l_return_status := 'S';
 -- fnd_client_info.set_org_context(-3113);
  p_seed_qual_rec.ORG_ID                  := -3113;
  p_qual_usgs_rec.ORG_ID                  := -3113;

   JTF_QUALIFIER_PUB.Create_Qualifier
  (p_api_version         => 1.0,
   p_Init_Msg_List       => FND_API.G_TRUE,
   p_Commit              => FND_API.G_FALSE,
   x_return_status     => l_return_status,
   x_Msg_Count         => l_Msg_Count,
   x_Msg_Data          => l_Msg_Data,
   p_Seed_Qual_Rec     => p_Seed_Qual_Rec,
   p_Qual_Usgs_Rec     => p_Qual_Usgs_Rec,
   x_Seed_Qual_Rec     => v_Seed_Qual_out_Rec,
   x_Qual_Usgs_Rec     => v_Qual_Usgs_out_Rec );

  dbms_output.put_line('Status:'||l_return_status);
  dbms_output.put_line('Msg count:'||l_msg_count);
  dbms_output.put_line('msg Data:'||l_msg_data);
  dbms_output.put_line('end');
exception
when others then
    dbms_output.put_line('Error:' || SQLERRM);
end;

END;

END;
