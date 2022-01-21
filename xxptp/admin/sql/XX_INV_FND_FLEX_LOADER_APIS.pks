SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_INV_FND_FLEX_LOADER_APIS AUTHID CURRENT_USER 
AS
-- +===================================================================================================== +
-- |                  Office Depot - Project Simplify                                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                                          |
-- +======================================================================================================+
-- | Name       : XX_INV_FND_FLEX_LOADER_APIS                                                             |
-- | Description: Modified FND_FLEX_LOADER_APIS for adding timestamp to creation_date and last_update_date|
-- |              of value set values                                                                     |
-- |                                                                                                      |
-- |Change Record:                                                                                        |
-- |===============                                                                                       |
-- |Version   Date         Author             Remarks                                                     |
-- |=======   ==========   ===============    ==============================                              |
-- |DRAFT 1A  25-JUL-2007  Siddharth Singh    Modified FND_FLEX_LOADER_APIS for adding timestamp to       |
-- |                                          creation_date and last_update_date of value set values      |
-- |1.0       01-AUG-2007  Jayshree Kale      Reviewed                                                    |
-- |1.1       22-JUL-2016  Madhu Bolli        Retrofitted for 12.2.5 (Above FND_FLEX_LOADER_APIS version -|
-- |											:AFFFLDRS.pls 120.7.12020000.3                           |
-- +======================================================================================================+


--
-- Who record, used to honor customization.
--
TYPE who_type IS RECORD
  (
   created_by        NUMBER,
   creation_date     DATE,
   last_updated_by   NUMBER,
   last_update_date  DATE,
   last_update_login NUMBER
   );

PROCEDURE set_context
  (p_name                         IN VARCHAR2,
   p_value                        IN VARCHAR2);

PROCEDURE set_debugging
  (p_debug_flag                   IN VARCHAR2);

-- ==================================================
--  VALUE_SET
-- ==================================================
PROCEDURE up_value_set
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_validation_type              IN VARCHAR2,
   p_protected_flag               IN VARCHAR2,
   p_security_enabled_flag        IN VARCHAR2,
   p_longlist_flag                IN VARCHAR2,
   p_format_type                  IN VARCHAR2,
   p_maximum_size                 IN VARCHAR2,
   p_number_precision             IN VARCHAR2,
   p_alphanumeric_allowed_flag    IN VARCHAR2,
   p_uppercase_only_flag          IN VARCHAR2,
   p_numeric_mode_enabled_flag    IN VARCHAR2,
   p_minimum_value                IN VARCHAR2,
   p_maximum_value                IN VARCHAR2,
   p_parent_flex_value_set_name   IN VARCHAR2,
   p_dependant_default_value      IN VARCHAR2,
   p_dependant_default_meaning    IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_vset_depends_on
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_ind_flex_value_set_name      IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_ind_validation_type          IN VARCHAR2,
   p_dep_validation_type          IN VARCHAR2);

PROCEDURE up_vset_table
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_table_application_short_name IN VARCHAR2,
   p_application_table_name       IN VARCHAR2,
   p_summary_allowed_flag         IN VARCHAR2,
   p_value_column_name            IN VARCHAR2,
   p_value_column_type            IN VARCHAR2,
   p_value_column_size            IN VARCHAR2,
   p_id_column_name               IN VARCHAR2,
   p_id_column_type               IN VARCHAR2,
   p_id_column_size               IN VARCHAR2,
   p_meaning_column_name          IN VARCHAR2,
   p_meaning_column_type          IN VARCHAR2,
   p_meaning_column_size          IN VARCHAR2,
   p_enabled_column_name          IN VARCHAR2,
   p_compiled_attribute_column_na IN VARCHAR2,
   p_hierarchy_level_column_name  IN VARCHAR2,
   p_start_date_column_name       IN VARCHAR2,
   p_end_date_column_name         IN VARCHAR2,
   p_summary_column_name          IN VARCHAR2,
   p_additional_where_clause      IN VARCHAR2,
   p_additional_quickpick_columns IN VARCHAR2);

PROCEDURE up_vset_event
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_event_code                   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_user_exit                    IN VARCHAR2);

PROCEDURE up_vset_security_rule
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2,
   p_error_message                IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_vset_security_line
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_include_exclude_indicator    IN VARCHAR2,
   p_flex_value_low               IN VARCHAR2,
   p_flex_value_high              IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2);

PROCEDURE up_vset_security_usage
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_application_short_name       IN VARCHAR2,
   p_responsibility_key           IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2);

PROCEDURE up_vset_rollup_group
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_hierarchy_code               IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_hierarchy_name               IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_vset_qualifier
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_id_flex_application_short_na IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_assignment_order             IN VARCHAR2,
   p_assignment_date              IN VARCHAR2);

PROCEDURE up_vset_value
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_flex_value                   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_enabled_flag                 IN VARCHAR2,
   p_summary_flag                 IN VARCHAR2,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2,
   p_parent_flex_value_high       IN VARCHAR2,
   p_rollup_hierarchy_code        IN VARCHAR2,
   p_hierarchy_level              IN VARCHAR2,
   p_compiled_value_attributes    IN VARCHAR2,
   p_value_category               IN VARCHAR2,
   p_attribute1                   IN VARCHAR2,
   p_attribute2                   IN VARCHAR2,
   p_attribute3                   IN VARCHAR2,
   p_attribute4                   IN VARCHAR2,
   p_attribute5                   IN VARCHAR2,
   p_attribute6                   IN VARCHAR2,
   p_attribute7                   IN VARCHAR2,
   p_attribute8                   IN VARCHAR2,
   p_attribute9                   IN VARCHAR2,
   p_attribute10                  IN VARCHAR2,
   p_attribute11                  IN VARCHAR2,
   p_attribute12                  IN VARCHAR2,
   p_attribute13                  IN VARCHAR2,
   p_attribute14                  IN VARCHAR2,
   p_attribute15                  IN VARCHAR2,
   p_attribute16                  IN VARCHAR2,
   p_attribute17                  IN VARCHAR2,
   p_attribute18                  IN VARCHAR2,
   p_attribute19                  IN VARCHAR2,
   p_attribute20                  IN VARCHAR2,
   p_attribute21                  IN VARCHAR2,
   p_attribute22                  IN VARCHAR2,
   p_attribute23                  IN VARCHAR2,
   p_attribute24                  IN VARCHAR2,
   p_attribute25                  IN VARCHAR2,
   p_attribute26                  IN VARCHAR2,
   p_attribute27                  IN VARCHAR2,
   p_attribute28                  IN VARCHAR2,
   p_attribute29                  IN VARCHAR2,
   p_attribute30                  IN VARCHAR2,
   p_attribute31                  IN VARCHAR2,
   p_attribute32                  IN VARCHAR2,
   p_attribute33                  IN VARCHAR2,
   p_attribute34                  IN VARCHAR2,
   p_attribute35                  IN VARCHAR2,
   p_attribute36                  IN VARCHAR2,
   p_attribute37                  IN VARCHAR2,
   p_attribute38                  IN VARCHAR2,
   p_attribute39                  IN VARCHAR2,
   p_attribute40                  IN VARCHAR2,
   p_attribute41                  IN VARCHAR2,
   p_attribute42                  IN VARCHAR2,
   p_attribute43                  IN VARCHAR2,
   p_attribute44                  IN VARCHAR2,
   p_attribute45                  IN VARCHAR2,
   p_attribute46                  IN VARCHAR2,
   p_attribute47                  IN VARCHAR2,
   p_attribute48                  IN VARCHAR2,
   p_attribute49                  IN VARCHAR2,
   p_attribute50                  IN VARCHAR2,
   p_attribute_sort_order         IN VARCHAR2 DEFAULT NULL,
   p_flex_value_meaning           IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_vset_value_hierarchy
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value            IN VARCHAR2,
   p_range_attribute              IN VARCHAR2,
   p_child_flex_value_low         IN VARCHAR2,
   p_child_flex_value_high        IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2);

PROCEDURE up_vset_value_qual_value
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_flex_value                   IN VARCHAR2,
   p_id_flex_application_short_na IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_compiled_value_attribute_val IN VARCHAR2);

-- ==================================================
--  DESC_FLEX
-- ==================================================
PROCEDURE up_desc_flex
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_table_application_short_name IN VARCHAR2,
   p_application_table_name       IN VARCHAR2,
   p_concatenated_segs_view_name  IN VARCHAR2 DEFAULT NULL,
   p_context_column_name          IN VARCHAR2,
   p_context_required_flag        IN VARCHAR2,
   p_context_user_override_flag   IN VARCHAR2,
   p_concatenated_segment_delimit IN VARCHAR2,
   p_freeze_flex_definition_flag  IN VARCHAR2,
   p_protected_flag               IN VARCHAR2,
   p_default_context_field_name   IN VARCHAR2,
   p_default_context_value        IN VARCHAR2,
   p_context_default_type         IN VARCHAR2 DEFAULT NULL,
   p_context_default_value        IN VARCHAR2 DEFAULT NULL,
   p_context_override_value_set_n IN VARCHAR2 DEFAULT NULL,
   p_context_runtime_property_fun IN VARCHAR2 DEFAULT NULL,
   p_context_synchronization_flag IN VARCHAR2 DEFAULT NULL,
   p_title                        IN VARCHAR2,
   p_form_context_prompt          IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_dff_column
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_column_name                  IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_flexfield_usage_code         IN VARCHAR2);

PROCEDURE up_dff_ref_field
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_default_context_field_name   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_description                  IN VARCHAR2);

PROCEDURE up_dff_context
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_descriptive_flex_context_cod IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_enabled_flag                 IN VARCHAR2,
   p_global_flag                  IN VARCHAR2,
   p_descriptive_flex_context_nam IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_dff_segment
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_descriptive_flex_context_cod IN VARCHAR2,
   p_end_user_column_name         IN VARCHAR2,
   p_application_column_name      IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_column_seq_num               IN VARCHAR2,
   p_enabled_flag                 IN VARCHAR2,
   p_display_flag                 IN VARCHAR2,
   p_required_flag                IN VARCHAR2,
   p_security_enabled_flag        IN VARCHAR2,
   p_flex_value_set_name          IN VARCHAR2,
   p_display_size                 IN VARCHAR2,
   p_maximum_description_len      IN VARCHAR2,
   p_concatenation_description_le IN VARCHAR2,
   p_range_code                   IN VARCHAR2,
   p_default_type                 IN VARCHAR2,
   p_default_value                IN VARCHAR2,
   p_runtime_property_function    IN VARCHAR2 DEFAULT NULL,
   p_srw_param                    IN VARCHAR2,
   p_form_left_prompt             IN VARCHAR2,
   p_form_above_prompt            IN VARCHAR2,
   p_description                  IN VARCHAR2);

-- ==================================================
--  KEY_FLEX
-- ==================================================
PROCEDURE up_key_flex
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_table_application_short_name IN VARCHAR2,
   p_application_table_name       IN VARCHAR2,
   p_concatenated_segs_view_name  IN VARCHAR2 DEFAULT NULL,
   p_allow_id_valuesets           IN VARCHAR2,
   p_dynamic_inserts_feasible_fla IN VARCHAR2,
   p_index_flag                   IN VARCHAR2,
   p_unique_id_column_name        IN VARCHAR2,
   p_application_table_type       IN VARCHAR2,
   p_set_defining_column_name     IN VARCHAR2,
   p_maximum_concatenation_len    IN VARCHAR2,
   p_concatenation_len_warning    IN VARCHAR2,
   p_id_flex_name                 IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_kff_column
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_column_name                  IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_flexfield_usage_code         IN VARCHAR2);

PROCEDURE up_kff_flex_qual
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_global_flag                  IN VARCHAR2,
   p_required_flag                IN VARCHAR2,
   p_unique_flag                  IN VARCHAR2,
   p_segment_prompt               IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_kff_segment_qual
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_required_flag                IN VARCHAR2,
   p_application_column_name      IN VARCHAR2,
   p_default_value                IN VARCHAR2,
   p_lookup_type                  IN VARCHAR2,
   p_derivation_rule_code         IN VARCHAR2,
   p_derivation_rule_value1       IN VARCHAR2,
   p_derivation_rule_value2       IN VARCHAR2,
   p_prompt                       IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_kff_structure
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_concatenated_segment_delimit IN VARCHAR2,
   p_cross_segment_validation_fla IN VARCHAR2,
   p_dynamic_inserts_allowed_flag IN VARCHAR2,
   p_enabled_flag                 IN VARCHAR2,
   p_freeze_flex_definition_flag  IN VARCHAR2,
   p_freeze_structured_hier_flag  IN VARCHAR2,
   p_shorthand_enabled_flag       IN VARCHAR2,
   p_shorthand_length             IN VARCHAR2,
   p_structure_view_name          IN VARCHAR2,
   p_id_flex_structure_name       IN VARCHAR2,
   p_description                  IN VARCHAR2,
   p_shorthand_prompt             IN VARCHAR2);

PROCEDURE up_kff_wf_process
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_wf_item_type                 IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_wf_process_name              IN VARCHAR2);

PROCEDURE up_kff_sh_alias
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_alias_name                   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_concatenated_segments        IN VARCHAR2,
   p_enabled_flag                 IN VARCHAR2,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2,
   p_attribute_category           IN VARCHAR2,
   p_attribute1                   IN VARCHAR2,
   p_attribute2                   IN VARCHAR2,
   p_attribute3                   IN VARCHAR2,
   p_attribute4                   IN VARCHAR2,
   p_attribute5                   IN VARCHAR2,
   p_attribute6                   IN VARCHAR2,
   p_attribute7                   IN VARCHAR2,
   p_attribute8                   IN VARCHAR2,
   p_attribute9                   IN VARCHAR2,
   p_attribute10                  IN VARCHAR2,
   p_attribute11                  IN VARCHAR2,
   p_attribute12                  IN VARCHAR2,
   p_attribute13                  IN VARCHAR2,
   p_attribute14                  IN VARCHAR2,
   p_attribute15                  IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_kff_cvr_rule
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_flex_validation_rule_name    IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_enabled_flag                 IN VARCHAR2,
   p_error_segment_column_name    IN VARCHAR2,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2,
   p_error_message_text           IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_kff_cvr_line
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_flex_validation_rule_name    IN VARCHAR2,
   p_include_exclude_indicator    IN VARCHAR2,
   p_concatenated_segments_low    IN VARCHAR2,
   p_concatenated_segments_high   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_enabled_flag                 IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_kff_segment
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_segment_name                 IN VARCHAR2,
   p_application_column_name      IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_segment_num                  IN VARCHAR2,
   p_application_column_index_fla IN VARCHAR2,
   p_enabled_flag                 IN VARCHAR2,
   p_required_flag                IN VARCHAR2,
   p_display_flag                 IN VARCHAR2,
   p_display_size                 IN VARCHAR2,
   p_security_enabled_flag        IN VARCHAR2,
   p_maximum_description_len      IN VARCHAR2,
   p_concatenation_description_le IN VARCHAR2,
   p_flex_value_set_name          IN VARCHAR2,
   p_range_code                   IN VARCHAR2,
   p_default_type                 IN VARCHAR2,
   p_default_value                IN VARCHAR2,
   p_runtime_property_function    IN VARCHAR2 DEFAULT NULL,
   p_additional_where_clause      IN VARCHAR2 DEFAULT NULL,
   p_form_left_prompt             IN VARCHAR2,
   p_form_above_prompt            IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_kff_flexq_assign
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_application_column_name      IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_attribute_value              IN VARCHAR2);

PROCEDURE up_kff_segq_assign
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_application_column_name      IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2 DEFAULT NULL,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_assignment_order             IN VARCHAR2,
   p_assignment_date              IN VARCHAR2);

PROCEDURE up_kff_qualifier
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_flex_value_set_name          IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_assignment_order             IN VARCHAR2,
   p_assignment_date              IN VARCHAR2);

PROCEDURE up_kff_qualifier_value
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_flex_value_set_name          IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_flex_value                   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_compiled_value_attribute_val IN VARCHAR2);

FUNCTION get_qualifier_value
  (p_compiled_value_attributes    IN VARCHAR2,
   p_assignment_order             IN VARCHAR2)
  RETURN VARCHAR2;
PRAGMA restrict_references(get_qualifier_value, WNDS, WNPS, RNPS);

/****** Should be removed later - begin ******/
-- ==================================================
--  VALUE_SECURITY_RULE
-- ==================================================
PROCEDURE up_value_security_rule
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2,
   p_error_message                IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_vsec_line
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_include_exclude_indicator    IN VARCHAR2,
   p_flex_value_low               IN VARCHAR2,
   p_flex_value_high              IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2);

PROCEDURE up_vsec_usage
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_application_short_name       IN VARCHAR2,
   p_responsibility_key           IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2);

-- ==================================================
-- VALUE_ROLLUP_GROUP
--  ==================================================
PROCEDURE up_value_rollup_group
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_hierarchy_code               IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_hierarchy_name               IN VARCHAR2,
   p_description                  IN VARCHAR2);

-- ==================================================
-- VALUE_SET_VALUE
-- ==================================================
PROCEDURE up_value_set_value
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_flex_value                   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_enabled_flag                 IN VARCHAR2,
   p_summary_flag                 IN VARCHAR2,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2,
   p_parent_flex_value_high       IN VARCHAR2,
   p_rollup_flex_value_set_name   IN VARCHAR2,
   p_rollup_hierarchy_code        IN VARCHAR2,
   p_hierarchy_level              IN VARCHAR2,
   p_compiled_value_attributes    IN VARCHAR2,
   p_value_category               IN VARCHAR2,
   p_attribute1                   IN VARCHAR2,
   p_attribute2                   IN VARCHAR2,
   p_attribute3                   IN VARCHAR2,
   p_attribute4                   IN VARCHAR2,
   p_attribute5                   IN VARCHAR2,
   p_attribute6                   IN VARCHAR2,
   p_attribute7                   IN VARCHAR2,
   p_attribute8                   IN VARCHAR2,
   p_attribute9                   IN VARCHAR2,
   p_attribute10                  IN VARCHAR2,
   p_attribute11                  IN VARCHAR2,
   p_attribute12                  IN VARCHAR2,
   p_attribute13                  IN VARCHAR2,
   p_attribute14                  IN VARCHAR2,
   p_attribute15                  IN VARCHAR2,
   p_attribute16                  IN VARCHAR2,
   p_attribute17                  IN VARCHAR2,
   p_attribute18                  IN VARCHAR2,
   p_attribute19                  IN VARCHAR2,
   p_attribute20                  IN VARCHAR2,
   p_attribute21                  IN VARCHAR2,
   p_attribute22                  IN VARCHAR2,
   p_attribute23                  IN VARCHAR2,
   p_attribute24                  IN VARCHAR2,
   p_attribute25                  IN VARCHAR2,
   p_attribute26                  IN VARCHAR2,
   p_attribute27                  IN VARCHAR2,
   p_attribute28                  IN VARCHAR2,
   p_attribute29                  IN VARCHAR2,
   p_attribute30                  IN VARCHAR2,
   p_attribute31                  IN VARCHAR2,
   p_attribute32                  IN VARCHAR2,
   p_attribute33                  IN VARCHAR2,
   p_attribute34                  IN VARCHAR2,
   p_attribute35                  IN VARCHAR2,
   p_attribute36                  IN VARCHAR2,
   p_attribute37                  IN VARCHAR2,
   p_attribute38                  IN VARCHAR2,
   p_attribute39                  IN VARCHAR2,
   p_attribute40                  IN VARCHAR2,
   p_attribute41                  IN VARCHAR2,
   p_attribute42                  IN VARCHAR2,
   p_attribute43                  IN VARCHAR2,
   p_attribute44                  IN VARCHAR2,
   p_attribute45                  IN VARCHAR2,
   p_attribute46                  IN VARCHAR2,
   p_attribute47                  IN VARCHAR2,
   p_attribute48                  IN VARCHAR2,
   p_attribute49                  IN VARCHAR2,
   p_attribute50                  IN VARCHAR2,
   p_flex_value_meaning           IN VARCHAR2,
   p_description                  IN VARCHAR2);

PROCEDURE up_val_norm_hierarchy
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value            IN VARCHAR2,
   p_range_attribute              IN VARCHAR2,
   p_child_flex_value_low         IN VARCHAR2,
   p_child_flex_value_high        IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2);

PROCEDURE up_val_qual_value
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_flex_value                   IN VARCHAR2,
   p_id_flex_application_short_na IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_assignment_order             IN VARCHAR2,
   p_assignment_date              IN VARCHAR2,
   p_compiled_value_attribute_val IN VARCHAR2);

PROCEDURE up_desc_flex_nls
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_table_application_short_name IN VARCHAR2,
   p_application_table_name       IN VARCHAR2,
   p_concatenated_segs_view_name  IN VARCHAR2 DEFAULT NULL,
   p_context_column_name          IN VARCHAR2,
   p_context_required_flag        IN VARCHAR2,
   p_context_user_override_flag   IN VARCHAR2,
   p_concatenated_segment_delimit IN VARCHAR2,
   p_freeze_flex_definition_flag  IN VARCHAR2,
   p_protected_flag               IN VARCHAR2,
   p_default_context_field_name   IN VARCHAR2,
   p_default_context_value        IN VARCHAR2,
   p_context_default_type         IN VARCHAR2 DEFAULT NULL,
   p_context_default_value        IN VARCHAR2 DEFAULT NULL,
   p_context_override_value_set_n IN VARCHAR2 DEFAULT NULL,
   p_context_runtime_property_fun IN VARCHAR2 DEFAULT NULL,
   p_context_synchronization_flag IN VARCHAR2 DEFAULT NULL,
   p_title                        IN VARCHAR2,
   p_form_context_prompt          IN VARCHAR2,
   p_description                  IN VARCHAR2);


/****** Should be removed later - end ******/

END XX_INV_FND_FLEX_LOADER_APIS;
/
SHOW ERRORS;

EXIT;
