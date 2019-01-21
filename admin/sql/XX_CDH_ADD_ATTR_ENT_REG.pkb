SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_ADD_ATTR_ENT_REG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_ADD_ATTR_ENT_REG.pkb                        |
-- | Description :  CDH Additional Attributes REgistration             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  06-Apr-2007 V Jayamohan        Initial draft version     |
-- |1.0       12-Dec-2007 Rajeev Kamat       Removed Deletes           |
-- +===================================================================+
AS
                              
-- +===================================================================+
-- | Name        :  register_entity                                    |
-- | Description :  This procedure is invoked as a concurrent          | 
-- |                request for registering the entities               |
-- |                                                                   |
-- |	                                                               |	                                                       |
-- | Parameters  :						       |
-- |     p_entity_attribute_group_type		IN  VARCHAR2           |
-- |     p_entity_base_table			IN  VARCHAR2           |
-- |     p_entity_base_table_key		IN  VARCHAR2           |
-- |     p_entity_name				IN  VARCHAR2           |
-- |     p_extension_base_table			IN  VARCHAR2           |
-- |     p_extension_tl_table			IN  VARCHAR2           |
-- |     p_extension_vl				IN  VARCHAR2	       |
-- |                                                                   |
-- | Returns     :                                                     |
-- |     x_errbuf				OUT  VARCHAR2          |
-- |     x_retcode				OUT  VARCHAR2          |
-- |                                                                   |
-- +===================================================================+

PROCEDURE register_entity
      (  x_errbuf				OUT VARCHAR2,
         x_retcode				OUT VARCHAR2,
         p_entity_attribute_group_type		IN  VARCHAR2,
         p_entity_base_table			IN  VARCHAR2,
	 p_entity_base_table_key		IN  VARCHAR2,
	 p_entity_name				IN  VARCHAR2,
	 p_extension_base_table			IN  VARCHAR2,
	 p_extension_tl_table			IN  VARCHAR2,
	 p_extension_vl				IN  VARCHAR2
      )
IS
l_object_id			NUMBER(15);
l_application_id		NUMBER(15);

BEGIN   

   
   SELECT fnd_objects_s.NEXTVAL INTO l_object_id FROM dual;
   SELECT application_id INTO l_application_id FROM fnd_application WHERE application_short_name='AR';

   fnd_file.put_line(fnd_file.log, 'Register attribute group type with fnd_objects');
   
   INSERT INTO fnd_objects(  
	object_id   
	,obj_name   
	,application_id   
	,database_object_name   
	,pk1_column_name   
	,pk1_column_type   
	,created_by   
	,creation_date   
	,last_updated_by   
	,last_update_date   
	,last_update_login   
	)  
   VALUES(
	l_object_id  
	,p_entity_attribute_group_type  
	,l_application_id  
	,p_entity_base_table  
	,p_entity_base_table_key
	,'INTEGER'  
	,2  
	,SYSDATE  
	,2  
	,SYSDATE  
	,0
	);


   fnd_file.put_line(fnd_file.log, 'Register attribute group type with fnd_objects_tl');

   INSERT INTO fnd_objects_tl(  
	object_id   
	,language   
	,source_lang   
	,display_name   
	,description   
	,created_by   
	,creation_date   
	,last_updated_by   
	,last_update_date   
	,last_update_login   
	)  
   VALUES(
	l_object_id  
	,'US'
	,'US'  
	,p_entity_name  
	,p_entity_name
	,2  
	,SYSDATE  
	,2  
	,SYSDATE  
	,0
	);


   fnd_file.put_line(fnd_file.log, 'Register the extension tables with EGO_OBJECT_EXT_TABLES_B');
	
   INSERT INTO EGO_OBJECT_EXT_TABLES_B
       ( 
         OBJECT_ID             
        ,EXT_TABLE_NAME
        ,APPLICATION_ID
        ,CREATION_DATE  
        ,CREATED_BY  
        ,LAST_UPDATE_DATE 
        ,LAST_UPDATED_BY 
        ,LAST_UPDATE_LOGIN 
       ) 
     VALUES 
       ( 
         l_object_id
        ,p_extension_base_table
        ,l_application_id 
        ,SYSDATE  
        ,2 
        ,SYSDATE 
        ,2
        ,0 
       ); 

   INSERT INTO EGO_OBJECT_EXT_TABLES_B
       ( 
         OBJECT_ID             
        ,EXT_TABLE_NAME
        ,APPLICATION_ID
        ,CREATION_DATE  
        ,CREATED_BY  
        ,LAST_UPDATE_DATE 
        ,LAST_UPDATED_BY 
        ,LAST_UPDATE_LOGIN 
       ) 
     VALUES 
       ( 
         l_object_id
        ,p_extension_tl_table
        ,l_application_id 
        ,SYSDATE  
        ,2 
        ,SYSDATE 
        ,2
        ,0 
       ); 




   fnd_file.put_line(fnd_file.log, 'Register extension tables with fnd_tables');

   fnd_dictionary_pkg.uploadtable(  
	x_application_short_name => 'AR',
	x_table_name => p_extension_base_table,  
	x_user_table_name => p_extension_base_table,
	x_table_type => 'T',
	x_description => 'Additional Attributes for '||p_entity_name,
	x_auto_size => 'Y',
	x_initial_extent => 4,
	x_next_extent => 32,
	x_min_extents => 1,
	x_max_extents => 50,
	x_ini_trans => 3,
	x_max_trans => 255,
	x_pct_free => 10,  
	x_pct_increase => 0,
	x_pct_used => 60,
	x_hosted_support_style =>'LOCAL',
	x_user_id => 1);

   fnd_file.put_line(fnd_file.log, 'Register extension translation tables with fnd_tables');

   fnd_dictionary_pkg.uploadtable(  
	x_application_short_name => 'AR',
	x_table_name => p_extension_tl_table,  
	x_user_table_name => p_extension_tl_table,
	x_table_type => 'T',
	x_description => 'Additional Attributes for '||p_entity_name,
	x_auto_size => 'Y',
	x_initial_extent => 4,
	x_next_extent => 32,
	x_min_extents => 1,
	x_max_extents => 50,
	x_ini_trans => 3,
	x_max_trans => 255,
	x_pct_free => 10,  
	x_pct_increase => 0,
	x_pct_used => 60,
	x_hosted_support_style =>'LOCAL',
	x_user_id => 1);

  fnd_file.put_line(fnd_file.log, 'Register base extension table columns with fnd_columns');

   FOR attrib_index IN 1..20
   LOOP
   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_base_table,  
            x_column_name => 'C_EXT_ATTR'||attrib_index,  
            x_user_column_name => 'C_EXT_ATTR'||attrib_index,
            x_column_sequence => attrib_index *10,  
            x_column_type => 'V',  
            x_width => 150,  
            x_null_allowed_flag => 'Y',  
            x_description => 'Character based extensible attribute column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => null,  
            x_scale => null,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   END LOOP;

   FOR attrib_index IN 1..20
   LOOP
   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_base_table,  
            x_column_name => 'N_EXT_ATTR'||attrib_index,  
            x_user_column_name => 'N_EXT_ATTR'||attrib_index,
            x_column_sequence => 200+attrib_index *10,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'Y',  
            x_description => 'Number based extensible attribute column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 22,  
            x_scale => 5,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   END LOOP;


   FOR attrib_index IN 1..10
   LOOP
   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_base_table,  
            x_column_name => 'D_EXT_ATTR'||attrib_index,  
            x_user_column_name => 'D_EXT_ATTR'||attrib_index,
            x_column_sequence => 400+attrib_index *10,  
            x_column_type => 'D',  
            x_width => 7,  
            x_null_allowed_flag => 'Y',  
            x_description => 'Date based extensible attribute column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => null,  
            x_scale => null,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   END LOOP;

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_base_table,  
            x_column_name => 'ATTR_GROUP_ID',  
            x_user_column_name => 'ATTR_GROUP_ID', 
            x_column_sequence => 510,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'N',  
            x_description => 'Custom Attribute Group Identifier',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => null,
            x_flexfield_usage_code => 'C',
            x_flexfield_application_id => l_application_id,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_base_table,  
            x_column_name => 'CREATED_BY',  
            x_user_column_name => 'CREATED_BY', 
            x_column_sequence => 520,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'N',  
            x_description => 'Standard Who column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => 0,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_base_table,  
            x_column_name => 'CREATION_DATE',  
            x_user_column_name => 'CREATION_DATE', 
            x_column_sequence => 530,  
            x_column_type => 'D',  
            x_width => 7,  
            x_null_allowed_flag => 'N',  
            x_description => 'Standard Who column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => null,  
            x_scale => null,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_base_table,  
            x_column_name => p_entity_base_table_key,  
            x_user_column_name => p_entity_base_table_key, 
            x_column_sequence => 540,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'N',  
            x_description => 'Identifier for '||p_entity_name,
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => null,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_base_table,  
            x_column_name => 'EXTENSION_ID',  
            x_user_column_name => 'EXTENSION_ID', 
            x_column_sequence => 550,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'N',  
            x_description => 'Unique system-generated identifier of extension row',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => 0,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_base_table,  
            x_column_name => 'LAST_UPDATED_BY',  
            x_user_column_name => 'LAST_UPDATED_BY', 
            x_column_sequence => 560,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'N',  
            x_description => 'Standard Who column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => 0,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);


   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_base_table,  
            x_column_name => 'LAST_UPDATE_DATE',  
            x_user_column_name => 'LAST_UPDATE_DATE', 
            x_column_sequence => 570,  
            x_column_type => 'D',  
            x_width => 7,  
            x_null_allowed_flag => 'N',  
            x_description => 'Standard Who column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => null,  
            x_scale => null,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_base_table,  
            x_column_name => 'LAST_UPDATE_LOGIN',  
            x_user_column_name => 'LAST_UPDATE_LOGIN', 
            x_column_sequence => 580,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'Y',  
            x_description => 'Standard Who column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => 0,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);



  fnd_file.put_line(fnd_file.log, 'Register base translation extension table columns with fnd_columns');

   FOR attrib_index IN 1..20
   LOOP
   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_tl_table,  
            x_column_name => 'TL_EXT_ATTR'||attrib_index,  
            x_user_column_name => 'TL_EXT_ATTR'||attrib_index,
            x_column_sequence => attrib_index *10,  
            x_column_type => 'V',  
            x_width => 1000,  
            x_null_allowed_flag => 'Y',  
            x_description => 'Character based extensible attribute column',
            x_default_value => null,
            x_translate_flag => 'Y',  
            x_precision => null,  
            x_scale => null,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   END LOOP;
   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_tl_table,  
            x_column_name => 'ATTR_GROUP_ID',  
            x_user_column_name => 'ATTR_GROUP_ID', 
            x_column_sequence => 210,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'N',  
            x_description => 'Custom Attribute Group Identifier',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => null,
            x_flexfield_usage_code => 'C',
            x_flexfield_application_id => l_application_id,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_tl_table,  
            x_column_name => 'CREATED_BY',  
            x_user_column_name => 'CREATED_BY', 
            x_column_sequence => 220,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'N',  
            x_description => 'Standard Who column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => 0,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_tl_table,  
            x_column_name => 'CREATION_DATE',  
            x_user_column_name => 'CREATION_DATE', 
            x_column_sequence => 230,  
            x_column_type => 'D',  
            x_width => 7,  
            x_null_allowed_flag => 'N',  
            x_description => 'Standard Who column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => null,  
            x_scale => null,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_tl_table,  
            x_column_name => 'EXTENSION_ID',  
            x_user_column_name => 'EXTENSION_ID', 
            x_column_sequence => 240,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'N',  
            x_description => 'Unique system-generated identifier of extension row',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => 0,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_tl_table,  
            x_column_name => 'LAST_UPDATED_BY',  
            x_user_column_name => 'LAST_UPDATED_BY', 
            x_column_sequence => 250,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'N',  
            x_description => 'Standard Who column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => 0,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);


   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_tl_table,  
            x_column_name => 'LAST_UPDATE_DATE',  
            x_user_column_name => 'LAST_UPDATE_DATE', 
            x_column_sequence => 260,  
            x_column_type => 'D',  
            x_width => 7,  
            x_null_allowed_flag => 'N',  
            x_description => 'Standard Who column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => null,  
            x_scale => null,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_tl_table,  
            x_column_name => 'LAST_UPDATE_LOGIN',  
            x_user_column_name => 'LAST_UPDATE_LOGIN', 
            x_column_sequence => 270,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'Y',  
            x_description => 'Standard Who column',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => 0,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_tl_table,  
            x_column_name => p_entity_base_table_key,  
            x_user_column_name => p_entity_base_table_key, 
            x_column_sequence => 280,  
            x_column_type => 'N',  
            x_width => 22,  
            x_null_allowed_flag => 'N',  
            x_description => 'Identifier for '||p_entity_name,
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => 15,  
            x_scale => null,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_tl_table,  
            x_column_name => 'LANGUAGE',  
            x_user_column_name => 'LANGUAGE', 
            x_column_sequence => 290,  
            x_column_type => 'V',  
            x_width => 4,  
            x_null_allowed_flag => 'N',  
            x_description => 'For translation',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => null,  
            x_scale => null,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

   fnd_dictionary_pkg.uploadColumn(  
            x_application_short_name => 'AR',
            x_table_name => p_extension_tl_table,  
            x_column_name => 'SOURCE_LANG',  
            x_user_column_name => 'SOURCE_LANG', 
            x_column_sequence => 300,  
            x_column_type => 'V',  
            x_width => 4,  
            x_null_allowed_flag => 'N',  
            x_description => 'For translation',
            x_default_value => null,
            x_translate_flag => 'N',  
            x_precision => null,  
            x_scale => null,
            x_flexfield_usage_code => 'N',
            x_flexfield_application_id => null,
            x_flexfield_name => null,
            x_flex_value_set_app_id => null,
            x_flex_value_set_id => null,
            x_user_id  => 1);

  fnd_file.put_line(fnd_file.log, 'Register DFF');

INSERT INTO FND_DESCRIPTIVE_FLEXS 
	(application_id, 
	application_table_name, 
	descriptive_flexfield_name,  
	table_application_id, 
	last_update_date, 
	last_updated_by, 
	creation_date, 
	created_by, 
	last_update_login, 
	context_required_flag,  
	context_column_name, 
	context_user_override_flag,
	CONCATENATED_SEGMENT_DELIMITER, 
	freeze_flex_definition_flag, 
	protected_flag, 
	context_synchronization_flag)  
VALUES  
	( l_application_id, 
	p_extension_base_table, 
	p_entity_attribute_group_type, 
	l_application_id,
	SYSDATE, 
	2,
	SYSDATE, 
	2, 
	0, 
	'N',
	'ATTR_GROUP_ID',  
	'Y',
	'.',
	'Y',
	'N',
	'X');

insert into FND_DESCRIPTIVE_FLEXS_TL 
	(application_id, 
	descriptive_flexfield_name, 
	language, 
	title,
	last_update_date, 
	last_updated_by, 
	creation_date, 
	created_by, 
	last_update_login,
	form_context_prompt, 
	source_lang, 
	description)
values
	(l_application_id, 
	p_entity_attribute_group_type, 
	'US', 
	p_entity_name ||'Extension', 
	sysdate, 
	2,
	sysdate, 
	2, 
	0,
	'Context Value', 
	'US', 
	p_entity_name ||'Extension');


  fnd_file.put_line(fnd_file.log, 'Populate EGO_FND_DESC_FLEXS_EXT with translation table and view');

     INSERT INTO EGO_FND_DESC_FLEXS_EXT
           (APPLICATION_ID
           ,DESCRIPTIVE_FLEXFIELD_NAME
           ,APPLICATION_TL_TABLE_NAME
           ,APPLICATION_VL_NAME
           ,CREATED_BY
           ,CREATION_DATE
           ,LAST_UPDATED_BY
           ,LAST_UPDATE_DATE
           ,LAST_UPDATE_LOGIN)
     VALUES
           (l_application_id
           ,p_entity_attribute_group_type
           ,p_extension_tl_table
           ,p_extension_vl
           ,2
           ,SYSDATE
           ,2
           ,SYSDATE
           ,0);


  fnd_file.put_line(fnd_file.log, 'Register with EGO_FND_OBJECTS_EXT');

	INSERT INTO EGO_FND_OBJECTS_EXT 
		( object_name
		, ext_attr_ocv_name
		, created_by
		, creation_date
		, last_updated_by
		, last_update_date
		, last_update_login)
	VALUES
		( p_entity_attribute_group_type
		, 'HZ_ORG_PROFILES_OCV_V'
		, 2
		, sysdate
		, 2
		, sysdate
		, 0);



fnd_file.put_line(fnd_file.log, 'Add the entity type to FND_LOOKUP_VALUES to appears on the customer online admin page');

INSERT INTO FND_LOOKUP_VALUES 
	(LOOKUP_TYPE
	,LANGUAGE
	,source_lang
	,security_group_id
	, view_application_id
	, LOOKUP_CODE
	, LAST_UPDATE_DATE
	, LAST_UPDATED_BY
	, LAST_UPDATE_LOGIN
	, CREATION_DATE
	,CREATED_BY
	, MEANING
	, ENABLED_FLAG
	, START_DATE_ACTIVE
	)
VALUES
	('HZ_EXT_ENTITIES'
	, 'US'
	,'US'
	,0
	, l_application_id
	, p_entity_attribute_group_type
	, SYSDATE
	, 2
	, 0
	, SYSDATE
	, 2
	, p_entity_name
	, 'Y'
	,SYSDATE);


fnd_file.put_line(fnd_file.log, 'Add the entity type to FND_LOOKUP_VALUES for EGO_EF_DATA_LEVEL');
INSERT INTO FND_LOOKUP_VALUES 
	(LOOKUP_TYPE
	,LANGUAGE
	,source_lang
	,security_group_id
	, view_application_id
	, LOOKUP_CODE
	, LAST_UPDATE_DATE
	, LAST_UPDATED_BY
	, LAST_UPDATE_LOGIN
	, CREATION_DATE
	, CREATED_BY
	, MEANING
	, ENABLED_FLAG
	, START_DATE_ACTIVE
	,ATTRIBUTE_CATEGORY
	,ATTRIBUTE1
	,ATTRIBUTE2
	,DESCRIPTION
	)
VALUES
	('EGO_EF_DATA_LEVEL'
	, 'US'
	,'US'
	,0
	, l_application_id
	, p_entity_attribute_group_type
	, SYSDATE
	, 2
	, 0
	, SYSDATE
	, 2
	, p_entity_name
	, 'Y'
	,SYSDATE
	,p_entity_attribute_group_type||'_LEVEL'
	,p_entity_attribute_group_type
	,0
	,p_entity_name || ' Level');

x_retcode :=0;
x_errbuf  := 'No errors';
commit;

EXCEPTION

   WHEN OTHERS THEN
      x_retcode :=2;
      x_errbuf  := 'Unexpected error in main procedure - '||SQLERRM;
      fnd_file.put_line (fnd_file.log, x_errbuf );

END register_entity;

END XX_CDH_ADD_ATTR_ENT_REG;
/
show errors;
exit;
