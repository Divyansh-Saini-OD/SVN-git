create or replace 
PACKAGE xx_cdh_ebl_templ_dtl_pkg AUTHID CURRENT_USER
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_TEMPL_DTL_PKG                                    |
-- | Description :                                                             |
-- | This package provides table handlers for the tables XX_CDH_EBL_TEMPL_DTL  |
-- | and XX_CDH_EBL_TEMPL_DTL_TXT                                              |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 24-FEB-2010 Mangala       Initial draft version                   |
-- |1.0      23-Dec-2015 Sridevi K     Mod 4B R3                               |
-- |2.0      30-MAR-2016 Havish K      Modified for MOD 4B R4                  |
-- |3.0      27-FEB-2017 Bhagwan       Added new Flag parameters               |
-- |4.0      10-Aug-2017 Reddy Sekhar  Defect#41307                            |                           
-- |5.0      09-May-2018 Reddy Sekhar  Modified for Defect# NAIT-29364         |
-- +===========================================================================+
AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : INSERT_ROW                                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure inserts data into the table  XX_CDH_EBL_TEMPL_DTL.         |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE insert_row (
      p_ebl_templ_id             IN   NUMBER,
      p_cust_doc_id              IN   NUMBER,
      p_record_type              IN   VARCHAR2,
      p_seq                      IN   NUMBER,
      p_field_id                 IN   NUMBER,
      p_label                    IN   VARCHAR2,
      p_start_pos                IN   NUMBER,
      p_field_len                IN   NUMBER,
      p_data_format              IN   VARCHAR2,
      p_string_fun               IN   VARCHAR2,
      p_sort_order               IN   NUMBER,
      p_sort_type                IN   VARCHAR2,
      p_mandatory                IN   VARCHAR2,
      p_seq_start_val            IN   NUMBER,
      p_seq_inc_val              IN   NUMBER,
      p_seq_reset_field          IN   NUMBER,
      p_constant_value           IN   VARCHAR2,
      p_alignment                IN   VARCHAR2,
      p_padding_char             IN   VARCHAR2,
      p_default_if_null          IN   VARCHAR2,
      p_comments                 IN   VARCHAR2,
      p_attribute1               IN   VARCHAR2 DEFAULT NULL,
      p_attribute2               IN   VARCHAR2 DEFAULT NULL,
      p_attribute3               IN   VARCHAR2 DEFAULT NULL,
      p_attribute4               IN   VARCHAR2 DEFAULT NULL,
      p_attribute5               IN   VARCHAR2 DEFAULT NULL,
      p_attribute6               IN   VARCHAR2 DEFAULT NULL,
      p_attribute7               IN   VARCHAR2 DEFAULT NULL,
      p_attribute8               IN   VARCHAR2 DEFAULT NULL,
      p_attribute9               IN   VARCHAR2 DEFAULT NULL,
      p_attribute10              IN   VARCHAR2 DEFAULT NULL,
      p_attribute11              IN   VARCHAR2 DEFAULT NULL,
      p_attribute12              IN   VARCHAR2 DEFAULT NULL,
      p_attribute13              IN   VARCHAR2 DEFAULT NULL,
      p_attribute14              IN   VARCHAR2 DEFAULT NULL,
      p_attribute15              IN   VARCHAR2 DEFAULT NULL,
      p_attribute16              IN   VARCHAR2 DEFAULT NULL,
      p_attribute17              IN   VARCHAR2 DEFAULT NULL,
      p_attribute18              IN   VARCHAR2 DEFAULT NULL,
      p_attribute19              IN   VARCHAR2 DEFAULT NULL,
      p_attribute20              IN   VARCHAR2 DEFAULT NULL,
      p_last_update_date         IN   DATE DEFAULT SYSDATE,
      p_last_updated_by          IN   NUMBER DEFAULT fnd_global.user_id,
      p_creation_date            IN   DATE DEFAULT SYSDATE,
      p_created_by               IN   NUMBER DEFAULT fnd_global.user_id,
      p_last_update_login        IN   NUMBER DEFAULT fnd_global.user_id,
      p_request_id               IN   NUMBER DEFAULT NULL,
      p_program_application_id   IN   NUMBER DEFAULT NULL,
      p_program_id               IN   NUMBER DEFAULT NULL,
      p_program_update_date      IN   DATE DEFAULT NULL,
      p_wh_update_date           IN   DATE DEFAULT NULL,
      p_concatenate              IN   VARCHAR2 DEFAULT NULL,
      p_split                    IN   VARCHAR2 DEFAULT NULL,
      p_base_field_id            IN   VARCHAR2 DEFAULT NULL,
      p_split_field_id            IN   VARCHAR2 DEFAULT NULL,
      p_repeat_total_flag       IN   VARCHAR2 DEFAULT NULL      
   );
-- +===========================================================================+
-- |                                                                           |
-- | Name        : UPDATE_ROW                                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall update data into the table XX_CDH_EBL_TEMPL_DTL.     |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE update_row (
      p_ebl_templ_id             IN   NUMBER,
      p_cust_doc_id              IN   NUMBER,
      p_record_type              IN   VARCHAR2,
      p_seq                      IN   NUMBER,
      p_field_id                 IN   NUMBER,
      p_label                    IN   VARCHAR2,
      p_start_pos                IN   NUMBER,
      p_field_len                IN   NUMBER,
      p_data_format              IN   VARCHAR2,
      p_string_fun               IN   VARCHAR2,
      p_sort_order               IN   NUMBER,
      p_sort_type                IN   VARCHAR2,
      p_mandatory                IN   VARCHAR2,
      p_seq_start_val            IN   NUMBER,
      p_seq_inc_val              IN   NUMBER,
      p_seq_reset_field          IN   NUMBER,
      p_constant_value           IN   VARCHAR2,
      p_alignment                IN   VARCHAR2,
      p_padding_char             IN   VARCHAR2,
      p_default_if_null          IN   VARCHAR2,
      p_comments                 IN   VARCHAR2,
      p_attribute1               IN   VARCHAR2 DEFAULT NULL,
      p_attribute2               IN   VARCHAR2 DEFAULT NULL,
      p_attribute3               IN   VARCHAR2 DEFAULT NULL,
      p_attribute4               IN   VARCHAR2 DEFAULT NULL,
      p_attribute5               IN   VARCHAR2 DEFAULT NULL,
      p_attribute6               IN   VARCHAR2 DEFAULT NULL,
      p_attribute7               IN   VARCHAR2 DEFAULT NULL,
      p_attribute8               IN   VARCHAR2 DEFAULT NULL,
      p_attribute9               IN   VARCHAR2 DEFAULT NULL,
      p_attribute10              IN   VARCHAR2 DEFAULT NULL,
      p_attribute11              IN   VARCHAR2 DEFAULT NULL,
      p_attribute12              IN   VARCHAR2 DEFAULT NULL,
      p_attribute13              IN   VARCHAR2 DEFAULT NULL,
      p_attribute14              IN   VARCHAR2 DEFAULT NULL,
      p_attribute15              IN   VARCHAR2 DEFAULT NULL,
      p_attribute16              IN   VARCHAR2 DEFAULT NULL,
      p_attribute17              IN   VARCHAR2 DEFAULT NULL,
      p_attribute18              IN   VARCHAR2 DEFAULT NULL,
      p_attribute19              IN   VARCHAR2 DEFAULT NULL,
      p_attribute20              IN   VARCHAR2 DEFAULT NULL,
      p_last_update_date         IN   DATE DEFAULT SYSDATE,
      p_last_updated_by          IN   NUMBER DEFAULT fnd_global.user_id,
      p_creation_date            IN   DATE DEFAULT SYSDATE,
      p_created_by               IN   NUMBER DEFAULT fnd_global.user_id,
      p_last_update_login        IN   NUMBER DEFAULT fnd_global.user_id,
      p_request_id               IN   NUMBER DEFAULT NULL,
      p_program_application_id   IN   NUMBER DEFAULT NULL,
      p_program_id               IN   NUMBER DEFAULT NULL,
      p_program_update_date      IN   DATE DEFAULT NULL,
      p_wh_update_date           IN   DATE DEFAULT NULL,
      p_concatenate              IN   VARCHAR2 DEFAULT NULL,
      p_split                    IN   VARCHAR2 DEFAULT NULL,
      p_base_field_id            IN   VARCHAR2 DEFAULT NULL,
      p_split_field_id            IN   VARCHAR2 DEFAULT NULL,
       p_repeat_total_flag       IN   VARCHAR2 DEFAULT NULL       
   );

-- +===========================================================================+
-- |                                                                           |
-- | Name        : DELETE_ROW                                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall delete data  in XX_CDH_EBL_TEMPL_DTL.                |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE delete_row (p_ebl_templ_id IN NUMBER, p_cust_doc_id IN NUMBER);
   
-- +===========================================================================+
-- |                                                                           |
-- | Name        : DELETE_CUST_ROW                                             |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall delete data  in XX_CDH_EBL_TEMPL_DTL.                |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE delete_cust_row (p_cust_doc_id IN NUMBER);

-- +===========================================================================+
-- |                                                                           |
-- | Name        : DELETE_ALL                                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall delete all data  in XX_CDH_EBL_TEMPL_DTL based on    |
-- | Cust Doc Id                                   |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE delete_all (p_cust_doc_id IN NUMBER, p_dly_mtd IN VARCHAR2);
-- +===========================================================================+
-- |                                                                           |
-- | Name        : LOCK_ROW                                                   |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall lock rows into  the table XX_CDH_EBL_TEMPL_DTL.      |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

/*
PROCEDURE lock_row(
p_ebl_templ_id         IN    NUMBER ,
p_cust_doc_id           IN NUMBER ,
p_record_type           IN VARCHAR2 ,
p_seq               IN NUMBER ,
p_field_id           IN NUMBER,
p_label           IN VARCHAR2 ,
p_start_pos           IN NUMBER ,
p_field_len           IN NUMBER ,
p_data_format           IN VARCHAR2 ,
p_string_fun           IN VARCHAR2 ,
p_sort_order           IN NUMBER ,
p_sort_type           IN VARCHAR2 ,
p_mandatory           IN VARCHAR2 ,
p_seq_start_val       IN NUMBER ,
p_seq_inc_val           IN NUMBER ,
p_seq_reset_field       IN NUMBER ,
p_constant_value       IN VARCHAR2 ,
p_alignment           IN VARCHAR2 ,
p_padding_char       IN VARCHAR2 ,
p_default_if_null       IN VARCHAR2 ,
p_comments           IN VARCHAR2 ,
p_attribute1           IN VARCHAR2 ,
p_attribute2           IN VARCHAR2 ,
p_attribute3           IN VARCHAR2 ,
p_attribute4           IN VARCHAR2 ,
p_attribute5           IN VARCHAR2 ,
p_attribute6           IN VARCHAR2 ,
p_attribute7           IN VARCHAR2 ,
p_attribute8           IN VARCHAR2 ,
p_attribute9           IN VARCHAR2 ,
p_attribute10           IN VARCHAR2 ,
p_attribute11           IN VARCHAR2 ,
p_attribute12           IN VARCHAR2 ,
p_attribute13           IN VARCHAR2 ,
p_attribute14           IN VARCHAR2 ,
p_attribute15           IN VARCHAR2 ,
p_attribute16           IN VARCHAR2 ,
p_attribute17           IN VARCHAR2 ,
p_attribute18           IN VARCHAR2 ,
p_attribute19           IN VARCHAR2 ,
p_attribute20           IN VARCHAR2 ,
p_last_update_date       IN DATE,
p_last_updated_by       IN NUMBER ,
p_creation_date       IN DATE DEFAULT SYSDATE ,
p_created_by           IN NUMBER ,
p_last_update_login       IN NUMBER,
p_request_id           IN NUMBER ,
p_program_application_id IN NUMBER ,
p_program_id           IN NUMBER ,
p_program_update_date       IN DATE ,
p_wh_update_date       IN DATE ); */

-- Added for MOD 4B Release 4

-- +===========================================================================+
-- | Name        : INSERT_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure inserts data into the table  XX_CDH_EBL_TEMPL_DTL_TXT.     |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE insert_row_txt (
      p_ebl_templ_id             IN   NUMBER,
      p_cust_doc_id              IN   NUMBER,
      p_seq                      IN   NUMBER,
      p_field_id                 IN   NUMBER,
      p_label                    IN   VARCHAR2,
      p_start_pos                IN   NUMBER,
      p_field_len                IN   NUMBER,
      p_data_format              IN   VARCHAR2,
      p_string_fun               IN   VARCHAR2,
      p_sort_order               IN   NUMBER,
      p_sort_type                IN   VARCHAR2,
      p_mandatory                IN   VARCHAR2,
      p_seq_start_val            IN   NUMBER,
      p_seq_inc_val              IN   NUMBER,
      p_seq_reset_field          IN   NUMBER,
      p_constant_value           IN   VARCHAR2,
      p_alignment                IN   VARCHAR2,
      p_padding_char             IN   VARCHAR2,
      p_default_if_null          IN   VARCHAR2,
      p_comments                 IN   VARCHAR2,
      p_attribute1               IN   VARCHAR2 DEFAULT NULL,
      p_attribute2               IN   VARCHAR2 DEFAULT NULL,
      p_attribute3               IN   VARCHAR2 DEFAULT NULL,
      p_attribute4               IN   VARCHAR2 DEFAULT NULL,
      p_attribute5               IN   VARCHAR2 DEFAULT NULL,
      p_attribute6               IN   VARCHAR2 DEFAULT NULL,
      p_attribute7               IN   VARCHAR2 DEFAULT NULL,
      p_attribute8               IN   VARCHAR2 DEFAULT NULL,
      p_attribute9               IN   VARCHAR2 DEFAULT NULL,
      p_attribute10              IN   VARCHAR2 DEFAULT NULL,
      p_attribute11              IN   VARCHAR2 DEFAULT NULL,
      p_attribute12              IN   VARCHAR2 DEFAULT NULL,
      p_attribute13              IN   VARCHAR2 DEFAULT NULL,
      p_attribute14              IN   VARCHAR2 DEFAULT NULL,
      p_attribute15              IN   VARCHAR2 DEFAULT NULL,
      p_attribute16              IN   VARCHAR2 DEFAULT NULL,
      p_attribute17              IN   VARCHAR2 DEFAULT NULL,
      p_attribute18              IN   VARCHAR2 DEFAULT NULL,
      p_attribute19              IN   VARCHAR2 DEFAULT NULL,
      p_attribute20              IN   VARCHAR2 DEFAULT NULL,
      p_request_id               IN   NUMBER DEFAULT NULL,
      p_program_application_id   IN   NUMBER DEFAULT NULL,
      p_program_id               IN   NUMBER DEFAULT NULL,
      p_program_update_date      IN   DATE DEFAULT NULL,
      p_wh_update_date           IN   DATE DEFAULT NULL,
      p_concatenate              IN   VARCHAR2 DEFAULT NULL,
      p_split                    IN   VARCHAR2 DEFAULT NULL,
      p_base_field_id            IN   NUMBER DEFAULT NULL,
      p_split_field_id           IN   NUMBER DEFAULT NULL,
      p_start_txt_pos            IN   NUMBER DEFAULT NULL,
      p_end_txt_pos              IN   NUMBER DEFAULT NULL,
      p_fill_txt_pos             IN   NUMBER DEFAULT NULL,
      p_justify_txt              IN   VARCHAR2 DEFAULT NULL,
      p_include_header           IN   VARCHAR2,
      p_repeat_header            IN   VARCHAR2,
      p_start_val_pos            IN   NUMBER,
      p_end_val_pos              IN   NUMBER,
      p_prepend_char             IN   VARCHAR2,
      p_append_char              IN   VARCHAR2,
      p_record_type              IN   VARCHAR2,
	  p_repeat_total_flag        IN   VARCHAR2, 
	  p_tax_up_flag              IN   VARCHAR2,
	  p_freight_up_flag          IN   VARCHAR2,
	  p_misc_up_flag             IN   VARCHAR2,
	  p_tax_ep_flag              IN   VARCHAR2,
	  p_freight_ep_flag          IN   VARCHAR2,
	  p_misc_ep_flag             IN   VARCHAR2,
      p_rownumber                IN   NUMBER, -- Added by Reddy Sekhar on 10-AUG-2017 for Defect#41307
      p_absolute_value_flag      IN   VARCHAR2,  ---Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
      p_dcindicator              IN   VARCHAR2,  ---Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
	  p_db_cr_seperator          IN   VARCHAR2  ---- Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364
   );

-- +===========================================================================+
-- |                                                                           |
-- | Name        : UPDATE_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall update data into the table XX_CDH_EBL_TEMPL_DTL_TXT. |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE update_row_txt (
      p_ebl_templ_id             IN   NUMBER,
      p_cust_doc_id              IN   NUMBER,
      p_seq                      IN   NUMBER,
      p_field_id                 IN   NUMBER,
      p_label                    IN   VARCHAR2,
      p_start_pos                IN   NUMBER,
      p_field_len                IN   NUMBER,
      p_data_format              IN   VARCHAR2,
      p_string_fun               IN   VARCHAR2,
      p_sort_order               IN   NUMBER,
      p_sort_type                IN   VARCHAR2,
      p_mandatory                IN   VARCHAR2,
      p_seq_start_val            IN   NUMBER,
      p_seq_inc_val              IN   NUMBER,
      p_seq_reset_field          IN   NUMBER,
      p_constant_value           IN   VARCHAR2,
      p_alignment                IN   VARCHAR2,
      p_padding_char             IN   VARCHAR2,
      p_default_if_null          IN   VARCHAR2,
      p_comments                 IN   VARCHAR2,
      p_attribute1               IN   VARCHAR2 DEFAULT NULL,
      p_attribute2               IN   VARCHAR2 DEFAULT NULL,
      p_attribute3               IN   VARCHAR2 DEFAULT NULL,
      p_attribute4               IN   VARCHAR2 DEFAULT NULL,
      p_attribute5               IN   VARCHAR2 DEFAULT NULL,
      p_attribute6               IN   VARCHAR2 DEFAULT NULL,
      p_attribute7               IN   VARCHAR2 DEFAULT NULL,
      p_attribute8               IN   VARCHAR2 DEFAULT NULL,
      p_attribute9               IN   VARCHAR2 DEFAULT NULL,
      p_attribute10              IN   VARCHAR2 DEFAULT NULL,
      p_attribute11              IN   VARCHAR2 DEFAULT NULL,
      p_attribute12              IN   VARCHAR2 DEFAULT NULL,
      p_attribute13              IN   VARCHAR2 DEFAULT NULL,
      p_attribute14              IN   VARCHAR2 DEFAULT NULL,
      p_attribute15              IN   VARCHAR2 DEFAULT NULL,
      p_attribute16              IN   VARCHAR2 DEFAULT NULL,
      p_attribute17              IN   VARCHAR2 DEFAULT NULL,
      p_attribute18              IN   VARCHAR2 DEFAULT NULL,
      p_attribute19              IN   VARCHAR2 DEFAULT NULL,
      p_attribute20              IN   VARCHAR2 DEFAULT NULL,
      p_request_id               IN   NUMBER DEFAULT NULL,
      p_program_application_id   IN   NUMBER DEFAULT NULL,
      p_program_id               IN   NUMBER DEFAULT NULL,
      p_program_update_date      IN   DATE DEFAULT NULL,
      p_wh_update_date           IN   DATE DEFAULT NULL,
      p_concatenate              IN   VARCHAR2 DEFAULT NULL,
      p_split                    IN   VARCHAR2 DEFAULT NULL,
      p_base_field_id            IN   NUMBER DEFAULT NULL,
      p_split_field_id           IN   NUMBER DEFAULT NULL,
      p_start_txt_pos            IN   NUMBER DEFAULT NULL,
      p_end_txt_pos              IN   NUMBER DEFAULT NULL,
      p_fill_txt_pos             IN   NUMBER DEFAULT NULL,
      p_justify_txt              IN   VARCHAR2 DEFAULT NULL,
      p_include_header           IN   VARCHAR2,
      p_repeat_header            IN   VARCHAR2,
      p_start_val_pos            IN   NUMBER,
      p_end_val_pos              IN   NUMBER,
      p_prepend_char             IN   VARCHAR2,
      p_append_char              IN   VARCHAR2,
      p_record_type              IN   VARCHAR2,
      p_rownumber                IN   NUMBER, -- Added by Reddy Sekhar on 10-AUG-2017 for Defect#41307
	  p_db_cr_seperator          IN   VARCHAR2 ---- Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364
   );

-- +===========================================================================+
-- |                                                                           |
-- | Name        : DELETE_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall delete data  in XX_CDH_EBL_TEMPL_DTL_TXT.            |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE delete_row_txt (p_ebl_templ_id IN NUMBER, p_cust_doc_id IN NUMBER);


END xx_cdh_ebl_templ_dtl_pkg;
/
SHOW ERRORS;
EXIT;