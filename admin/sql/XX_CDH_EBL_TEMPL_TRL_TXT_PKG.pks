create or replace 
PACKAGE xx_cdh_ebl_templ_trl_txt_pkg AUTHID CURRENT_USER
-- +===========================================================================+
-- |                  Office Depot                                             |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_TEMPL_TRL_TXT_PKG                                |
-- | This package provides table handlers for the table                        |
-- | XX_CDH_EBL_TEMPL_TRL_TXT                                                  |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 29-MAR-2016 Havish Kasina Initial draft version (MOD4B R4)        | 
-- |1B       09-May-2018 Reddy Sekhar  Modified for Defect# NAIT-29364         |
-- +===========================================================================+
AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : INSERT_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure inserts data into the table  XX_CDH_EBL_TEMPL_TRL_TXT      |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE insert_row_txt (
      p_ebl_templtrl_id            IN   NUMBER,
      p_cust_doc_id                IN   NUMBER,
      p_include_label              IN   VARCHAR2,
      p_record_type                IN   VARCHAR2,
      p_seq                        IN   NUMBER,
      p_field_id                   IN   NUMBER,
      p_label                      IN   VARCHAR2,
      p_start_pos                  IN   NUMBER,
      p_field_len                  IN   NUMBER,
      p_data_format                IN   VARCHAR2,
      p_string_fun                 IN   VARCHAR2,
      p_sort_order                 IN   NUMBER,
      p_sort_type                  IN   VARCHAR2,
      p_mandatory                  IN   VARCHAR2,
      p_seq_start_val              IN   NUMBER,
      p_seq_inc_val                IN   NUMBER,
      p_seq_reset_field            IN   NUMBER,
      p_constant_value             IN   VARCHAR2,
      p_alignment                  IN   VARCHAR2,
      p_padding_char               IN   VARCHAR2,
      p_default_if_null            IN   VARCHAR2,
      p_comments                   IN   VARCHAR2,
      p_attribute1                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute2                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute3                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute4                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute5                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute6                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute7                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute8                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute9                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute10                IN   VARCHAR2 DEFAULT NULL,
      p_attribute11                IN   VARCHAR2 DEFAULT NULL,
      p_attribute12                IN   VARCHAR2 DEFAULT NULL,
      p_attribute13                IN   VARCHAR2 DEFAULT NULL,
      p_attribute14                IN   VARCHAR2 DEFAULT NULL,
      p_attribute15                IN   VARCHAR2 DEFAULT NULL,
      p_attribute16                IN   VARCHAR2 DEFAULT NULL,
      p_attribute17                IN   VARCHAR2 DEFAULT NULL,
      p_attribute18                IN   VARCHAR2 DEFAULT NULL,
      p_attribute19                IN   VARCHAR2 DEFAULT NULL,
      p_attribute20                IN   VARCHAR2 DEFAULT NULL,
      p_request_id                 IN   NUMBER DEFAULT NULL,
      p_program_application_id     IN   NUMBER DEFAULT NULL,
      p_program_id                 IN   NUMBER DEFAULT NULL,
      p_program_update_date        IN   DATE DEFAULT NULL,
      p_wh_update_date             IN   DATE DEFAULT NULL,
      p_concatenate                IN   VARCHAR2,
      p_split                      IN   VARCHAR2,
      p_base_field_id              IN   NUMBER,
      p_split_field_id             IN   NUMBER,
      p_rownumber                  IN   NUMBER,
      p_start_txt_pos              IN   NUMBER,
      p_end_txt_pos                IN   NUMBER,
      p_fill_txt_pos               IN   NUMBER,
      p_justify_txt                IN   VARCHAR2,
      p_start_val_pos              IN   NUMBER,
      p_end_val_pos                IN   NUMBER,
      p_prepend_char               IN   VARCHAR2,
      p_append_char                IN   VARCHAR2,
      p_absolute_value_flag        IN   VARCHAR2,   ---Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
      p_dcindicator                IN   VARCHAR2,
      p_db_cr_seperator            IN   VARCHAR2 --Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364	     
   );

--  +==========================================================================+
-- |                                                                           |
-- | Name        : UPDATE_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall update data into the table XX_CDH_EBL_TEMPL_TRL_TXT  |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE update_row_txt (
      p_ebl_templtrl_id            IN   NUMBER,
      p_cust_doc_id                IN   NUMBER,
      p_include_label              IN   VARCHAR2,
      p_record_type                IN   VARCHAR2,
      p_seq                        IN   NUMBER,
      p_field_id                   IN   NUMBER,
      p_label                      IN   VARCHAR2,
      p_start_pos                  IN   NUMBER,
      p_field_len                  IN   NUMBER,
      p_data_format                IN   VARCHAR2,
      p_string_fun                 IN   VARCHAR2,
      p_sort_order                 IN   NUMBER,
      p_sort_type                  IN   VARCHAR2,
      p_mandatory                  IN   VARCHAR2,
      p_seq_start_val              IN   NUMBER,
      p_seq_inc_val                IN   NUMBER,
      p_seq_reset_field            IN   NUMBER,
      p_constant_value             IN   VARCHAR2,
      p_alignment                  IN   VARCHAR2,
      p_padding_char               IN   VARCHAR2,
      p_default_if_null            IN   VARCHAR2,
      p_comments                   IN   VARCHAR2,
      p_attribute1                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute2                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute3                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute4                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute5                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute6                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute7                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute8                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute9                 IN   VARCHAR2 DEFAULT NULL,
      p_attribute10                IN   VARCHAR2 DEFAULT NULL,
      p_attribute11                IN   VARCHAR2 DEFAULT NULL,
      p_attribute12                IN   VARCHAR2 DEFAULT NULL,
      p_attribute13                IN   VARCHAR2 DEFAULT NULL,
      p_attribute14                IN   VARCHAR2 DEFAULT NULL,
      p_attribute15                IN   VARCHAR2 DEFAULT NULL,
      p_attribute16                IN   VARCHAR2 DEFAULT NULL,
      p_attribute17                IN   VARCHAR2 DEFAULT NULL,
      p_attribute18                IN   VARCHAR2 DEFAULT NULL,
      p_attribute19                IN   VARCHAR2 DEFAULT NULL,
      p_attribute20                IN   VARCHAR2 DEFAULT NULL,
      p_request_id                 IN   NUMBER DEFAULT NULL,
      p_program_application_id     IN   NUMBER DEFAULT NULL,
      p_program_id                 IN   NUMBER DEFAULT NULL,
      p_program_update_date        IN   DATE DEFAULT NULL,
      p_wh_update_date             IN   DATE DEFAULT NULL,
      p_concatenate                IN   VARCHAR2,
      p_split                      IN   VARCHAR2,
      p_base_field_id              IN   NUMBER,
      p_split_field_id             IN   NUMBER,
      p_rownumber                  IN   NUMBER,
      p_start_txt_pos              IN   NUMBER,
      p_end_txt_pos                IN   NUMBER,
      p_fill_txt_pos               IN   NUMBER,
      p_justify_txt                IN   VARCHAR2,
      p_start_val_pos              IN   NUMBER,
      p_end_val_pos                IN   NUMBER,
      p_prepend_char               IN   VARCHAR2,
      p_append_char                IN   VARCHAR2,
	  p_db_cr_seperator            IN   VARCHAR2   ---- Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364	
   );

-- +===========================================================================+
-- |                                                                           |
-- | Name        : DELETE_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- |     This procedure shall delete data  in XX_CDH_EBL_TEMPL_TRL_TXT         |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE delete_row_txt (p_cust_doc_id IN NUMBER,
                             p_ebl_templtrl_id  IN   NUMBER);

END xx_cdh_ebl_templ_trl_txt_pkg;
/
SHOW ERRORS;
EXIT;