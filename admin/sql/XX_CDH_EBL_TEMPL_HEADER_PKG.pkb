create or replace 
PACKAGE BODY xx_cdh_ebl_templ_header_pkg
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_TEMPL_HEADER_PKG                                 |
-- | Description :                                                             |
-- | This package provides table handlers for the tables                       |
-- | XX_CDH_EBL_TEMPL_HEADER and XX_CDH_EBL_TEMPL_HDR_TXT                      |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 24-FEB-2010 Mangala        Initial draft version                  |
-- |1.0      30-JUL-2015 Sridevi K      Modified for MOD4B R2 Changes          |
-- |2.0      23-DEC-2015 Sridevi K      Modified for MOD 4B R3 Changes         |
-- |3.0      30-MAR-2016 Havish K       Modified for MOD 4B R4 Changes         |
-- |4.0      09-May-2018 Reddy Sekhar K Modified for Defect# NAIT-29364        |
-- +===========================================================================+
AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : INSERT_ROW                                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure inserts data into the table  XX_CDH_EBL_TEMPL_HEADER.      |
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
      p_cust_doc_id                IN   NUMBER,
      p_ebill_file_creation_type   IN   VARCHAR2,
      p_delimiter_char             IN   VARCHAR2,
      p_line_feed_style            IN   VARCHAR2,
      p_include_header             IN   VARCHAR2,
      p_logo_file_name             IN   VARCHAR2,
      p_file_split_criteria        IN   VARCHAR2,
      p_file_split_value           IN   NUMBER,
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
      p_last_update_date           IN   DATE DEFAULT SYSDATE,
      p_last_updated_by            IN   NUMBER DEFAULT fnd_global.user_id,
      p_creation_date              IN   DATE DEFAULT SYSDATE,
      p_created_by                 IN   NUMBER DEFAULT fnd_global.user_id,
      p_last_update_login          IN   NUMBER DEFAULT fnd_global.user_id,
      p_request_id                 IN   NUMBER DEFAULT NULL,
      p_program_application_id     IN   NUMBER DEFAULT NULL,
      p_program_id                 IN   NUMBER DEFAULT NULL,
      p_program_update_date        IN   DATE DEFAULT NULL,
      p_wh_update_date             IN   DATE DEFAULT NULL,
      p_splittabsby                IN   VARCHAR2,
      p_enablexlsubtotal           IN   VARCHAR2,
      p_concatsplit                IN   VARCHAR2
   )
   IS
   BEGIN
      INSERT INTO xx_cdh_ebl_templ_header
                  (cust_doc_id, ebill_file_creation_type,
                   delimiter_char, line_feed_style, include_header,
                   logo_file_name, file_split_criteria,
                   file_split_value, attribute1, attribute2,
                   attribute3, attribute4, attribute5, attribute6,
                   attribute7, attribute8, attribute9, attribute10,
                   attribute11, attribute12, attribute13,
                   attribute14, attribute15, attribute16,
                   attribute17, attribute18, attribute19,
                   attribute20, last_update_date, last_updated_by,
                   creation_date, created_by, last_update_login, request_id,
                   program_application_id, program_id,
                   program_update_date, wh_update_date, split_tabs_by,
                   enable_xl_subtotal, concatsplit
                  )
           VALUES (p_cust_doc_id, p_ebill_file_creation_type,
                   p_delimiter_char, p_line_feed_style, p_include_header,
                   p_logo_file_name, p_file_split_criteria,
                   p_file_split_value, p_attribute1, p_attribute2,
                   p_attribute3, p_attribute4, p_attribute5, p_attribute6,
                   p_attribute7, p_attribute8, p_attribute9, p_attribute10,
                   p_attribute11, p_attribute12, p_attribute13,
                   p_attribute14, p_attribute15, p_attribute16,
                   p_attribute17, p_attribute18, p_attribute19,
                   p_attribute20, p_last_update_date, p_last_updated_by,
                   SYSDATE, p_created_by, p_last_update_login, p_request_id,
                   p_program_application_id, p_program_id,
                   p_program_update_date, p_wh_update_date, p_splittabsby,
                   p_enablexlsubtotal, p_concatsplit
                  );
   END insert_row;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : UPDATE_ROW                                                  |
-- |                                                                           |
-- | Description :                                                             |
-- |  This procedure shall update data into the table XX_CDH_EBL_TEMPL_HEADER. |
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
      p_cust_doc_id                IN   NUMBER,
      p_ebill_file_creation_type   IN   VARCHAR2,
      p_delimiter_char             IN   VARCHAR2,
      p_line_feed_style            IN   VARCHAR2,
      p_include_header             IN   VARCHAR2,
      p_logo_file_name             IN   VARCHAR2,
      p_file_split_criteria        IN   VARCHAR2,
      p_file_split_value           IN   NUMBER,
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
      p_last_update_date           IN   DATE DEFAULT SYSDATE,
      p_last_updated_by            IN   NUMBER DEFAULT fnd_global.user_id,
      p_creation_date              IN   DATE DEFAULT SYSDATE,
      p_created_by                 IN   NUMBER DEFAULT fnd_global.user_id,
      p_last_update_login          IN   NUMBER DEFAULT fnd_global.user_id,
      p_request_id                 IN   NUMBER DEFAULT NULL,
      p_program_application_id     IN   NUMBER DEFAULT NULL,
      p_program_id                 IN   NUMBER DEFAULT NULL,
      p_program_update_date        IN   DATE DEFAULT NULL,
      p_wh_update_date             IN   DATE DEFAULT NULL,
      p_splittabsby                IN   VARCHAR2,
      p_enablexlsubtotal           IN   VARCHAR2,
      p_concatsplit                IN   VARCHAR2
   )
   IS
   BEGIN
      UPDATE xx_cdh_ebl_templ_header
         SET ebill_file_creation_type = p_ebill_file_creation_type,
             delimiter_char = p_delimiter_char,
             line_feed_style = p_line_feed_style,
             include_header = p_include_header,
             logo_file_name = p_logo_file_name,
             file_split_criteria = p_file_split_criteria,
             file_split_value = p_file_split_value,
             attribute1 = p_attribute1,
             attribute2 = p_attribute2,
             attribute3 = p_attribute3,
             attribute4 = p_attribute4,
             attribute5 = p_attribute5,
             attribute6 = p_attribute6,
             attribute7 = p_attribute7,
             attribute8 = p_attribute8,
             attribute9 = p_attribute9,
             attribute10 = p_attribute10,
             attribute11 = p_attribute11,
             attribute12 = p_attribute12,
             attribute13 = p_attribute13,
             attribute14 = p_attribute14,
             attribute15 = p_attribute15,
             attribute16 = p_attribute16,
             attribute17 = p_attribute17,
             attribute18 = p_attribute18,
             attribute19 = p_attribute19,
             attribute20 = p_attribute20,
             last_update_date = p_last_update_date,
             last_updated_by = p_last_updated_by,
             last_update_login = p_last_update_login,
             request_id = p_request_id,
             program_application_id = p_program_application_id,
             program_id = p_program_id,
             program_update_date = p_program_update_date,
             wh_update_date = p_wh_update_date,
             split_tabs_by = p_splittabsby,
             enable_xl_subtotal = p_enablexlsubtotal,
             concatsplit = p_concatsplit
       WHERE cust_doc_id = p_cust_doc_id;

      IF (SQL%NOTFOUND)
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         RAISE;
   END update_row;

--  +==========================================================================+
-- |                                                                           |
-- | Name        : DELETE_ROW                                                  |
-- |                                                                           |
-- | Description :                                                             |
-- |  This procedure shall delete data  in XX_CDH_EBL_TEMPL_HEADER.            |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE delete_row (p_cust_doc_id IN NUMBER)
   IS
   BEGIN
      DELETE FROM xx_cdh_ebl_templ_header
            WHERE cust_doc_id = p_cust_doc_id;

      IF (SQL%NOTFOUND)
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RAISE;
      WHEN TOO_MANY_ROWS
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         RAISE;
   END delete_row;
--  +==========================================================================+
-- |                                                                           |
-- | Name        : LOCK_ROW                                                    |
-- |                                                                           |
-- | Description :                                                             |
-- |This procedure shall lock rows into  the table XX_CDH_EBL_TEMPL_HEADER.    |
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
p_cust_doc_id     IN NUMBER ,
p_ebill_file_creation_type IN VARCHAR2 ,
p_delimiter_char    IN VARCHAR2 ,
p_line_feed_style    IN VARCHAR2 ,
p_include_header    IN VARCHAR2 ,
p_logo_file_name    IN VARCHAR2 ,
p_file_split_criteria    IN VARCHAR2 ,
p_file_split_value    IN NUMBER ,
p_attribute1     IN VARCHAR2 ,
p_attribute2     IN VARCHAR2 ,
p_attribute3     IN VARCHAR2 ,
p_attribute4     IN VARCHAR2 ,
p_attribute5     IN VARCHAR2 ,
p_attribute6     IN VARCHAR2 ,
p_attribute7     IN VARCHAR2 ,
p_attribute8     IN VARCHAR2 ,
p_attribute9     IN VARCHAR2 ,
p_attribute10     IN VARCHAR2 ,
p_attribute11     IN VARCHAR2 ,
p_attribute12     IN VARCHAR2 ,
p_attribute13     IN VARCHAR2 ,
p_attribute14     IN VARCHAR2 ,
p_attribute15     IN VARCHAR2 ,
p_attribute16     IN VARCHAR2 ,
p_attribute17     IN VARCHAR2 ,
p_attribute18     IN VARCHAR2 ,
p_attribute19     IN VARCHAR2 ,
p_attribute20     IN VARCHAR2 ,
p_last_update_date    IN DATE ,
p_last_updated_by    IN NUMBER ,
p_creation_date     IN DATE ,
p_created_by     IN NUMBER ,
p_last_update_login    IN NUMBER ,
p_request_id     IN NUMBER ,
p_program_application_id   IN NUMBER ,
p_program_id     IN NUMBER ,
p_program_update_date    IN DATE ,
p_wh_update_date    IN DATE  );
*/

-- Added for the MOD 4B Release 4

-- +===========================================================================+
-- |                                                                           |
-- | Name        : INSERT_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure inserts data into the table  XX_CDH_EBL_TEMPL_HDR_TXT      |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE insert_row_txt (
      p_ebl_templhdr_id            IN   NUMBER,
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
      p_absolute_value_flag        IN   VARCHAR2,   --Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
      p_dcindicator                IN   VARCHAR2,
	  p_db_cr_seperator            IN   VARCHAR2 --Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364
   )
   IS
   BEGIN
      INSERT INTO xx_cdh_ebl_templ_hdr_txt
                  (ebl_templhdr_id,
                   cust_doc_id,
                   include_label,
                   record_type,
                   seq,
                   field_id,
                   label,
                   start_pos,
                   field_len,
                   data_format,
                   string_fun,
                   sort_order,
                   sort_type,
                   mandatory,
                   seq_start_val,
                   seq_inc_val,
                   seq_reset_field,
                   constant_value,
                   alignment,
                   padding_char,
                   default_if_null,
                   comments,
                   attribute1,
                   attribute2,
                   attribute3,
                   attribute4,
                   attribute5,
                   attribute6,
                   attribute7,
                   attribute8,
                   attribute9,
                   attribute10,
                   attribute11,
                   attribute12,
                   attribute13,
                   attribute14,
                   attribute15,
                   attribute16,
                   attribute17,
                   attribute18,
                   attribute19,
                   attribute20,
                   last_update_date,
                   last_updated_by,
                   creation_date,
                   created_by,
                   last_update_login,
                   request_id,
                   program_application_id,
                   program_id,
                   program_update_date,
                   wh_update_date,
                   concatenate,
                   split,
                   base_field_id,
                   split_field_id,
                   rownumber,
                   start_txt_pos,
                   end_txt_pos,
                   fill_txt_pos,
                   justify_txt,
                   start_val_pos,
                   end_val_pos,
                   prepend_char,
                   append_char,
                   absolute_flag,   --Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
                   dc_indicator,
                   db_cr_seperator --Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364					
                  )
           VALUES (p_ebl_templhdr_id ,
                   p_cust_doc_id ,
                   p_include_label,
                   p_record_type ,
                   p_seq ,
                   p_field_id ,
                   p_label ,
                   p_start_pos ,
                   p_field_len ,
                   p_data_format ,
                   p_string_fun ,
                   p_sort_order ,
                   p_sort_type ,
                   p_mandatory ,
                   p_seq_start_val ,
                   p_seq_inc_val ,
                   p_seq_reset_field ,
                   p_constant_value ,
                   p_alignment ,
                   p_padding_char ,
                   p_default_if_null ,
                   p_comments ,
                   p_attribute1 ,
                   p_attribute2 ,
                   p_attribute3 ,
                   p_attribute4 ,
                   p_attribute5 ,
                   p_attribute6 ,
                   p_attribute7 ,
                   p_attribute8 ,
                   p_attribute9 ,
                   p_attribute10,
                   p_attribute11,
                   p_attribute12,
                   p_attribute13,
                   p_attribute14,
                   p_attribute15,
                   p_attribute16,
                   p_attribute17,
                   p_attribute18,
                   p_attribute19,
                   p_attribute20,
                   sysdate,
                   fnd_global.user_id,
                   sysdate,
                   fnd_global.user_id,
                   fnd_global.login_id,
                   p_request_id,
                   p_program_application_id,
                   p_program_id,
                   p_program_update_date,
                   p_wh_update_date,
                   p_concatenate,
                   p_split,
                   p_base_field_id,
                   p_split_field_id,
                   p_rownumber,
                   p_start_txt_pos,
                   p_end_txt_pos,
                   p_fill_txt_pos,
                   p_justify_txt,
                   p_start_val_pos,
                   p_end_val_pos,
                   p_prepend_char,
                   p_append_char,
                   p_absolute_value_flag,   --Added by Bhagwan Rao on 23-AUG-2017 for Defect #40174
                   p_dcindicator,
				   p_db_cr_seperator        --Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END insert_row_txt;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : UPDATE_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- |  This procedure shall update data into the table XX_CDH_EBL_TEMPL_HDR_TXT.|
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE update_row_txt (
      p_ebl_templhdr_id            IN   NUMBER,
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
	  p_db_cr_seperator            IN   VARCHAR2  --Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364
   )
   IS
   BEGIN
      UPDATE xx_cdh_ebl_templ_hdr_txt
         SET include_label = p_include_label,
             record_type = p_record_type,
             seq = p_seq,
             field_id = p_field_id,
             label = p_label,
             start_pos = p_start_pos,
             field_len = p_field_len,
             data_format = p_data_format,
             string_fun = p_string_fun,
             sort_order = p_sort_order,
             sort_type = p_sort_type,
             mandatory = p_mandatory,
             seq_start_val = p_seq_start_val,
             seq_inc_val = p_seq_inc_val,
             seq_reset_field = p_seq_reset_field,
             constant_value = p_constant_value,
             alignment = p_alignment,
             padding_char = p_padding_char,
             default_if_null = p_default_if_null,
             comments = p_comments,
             attribute1 = p_attribute1,
             attribute2 = p_attribute2,
             attribute3 = p_attribute3,
             attribute4 = p_attribute4,
             attribute5 = p_attribute5,
             attribute6 = p_attribute6,
             attribute7 = p_attribute7,
             attribute8 = p_attribute8,
             attribute9 = p_attribute9,
             attribute10 = p_attribute10,
             attribute11 = p_attribute11,
             attribute12 = p_attribute12,
             attribute13 = p_attribute13,
             attribute14 = p_attribute14,
             attribute15 = p_attribute15,
             attribute16 = p_attribute16,
             attribute17 = p_attribute17,
             attribute18 = p_attribute18,
             attribute19 = p_attribute19,
             attribute20 = p_attribute20,
             last_update_date = sysdate,
             last_updated_by = fnd_global.user_id,
             last_update_login = fnd_global.login_id,
             request_id = p_request_id,
             program_application_id = p_program_application_id,
             program_id = p_program_id,
             program_update_date = p_program_update_date,
             wh_update_date = p_wh_update_date,
             concatenate = p_concatenate,
             split = p_split,
             base_field_id = p_base_field_id,
             split_field_id = p_split_field_id,
             rownumber = p_rownumber,
             start_txt_pos = p_start_txt_pos,
             end_txt_pos = p_end_txt_pos,
             fill_txt_pos = p_fill_txt_pos,
             justify_txt = p_justify_txt,
             start_val_pos = p_start_val_pos,
             end_val_pos = p_end_val_pos,
             prepend_char = p_prepend_char,
             append_char = p_append_char,
			 db_cr_seperator = p_db_cr_seperator --Added By Reddy Sekhar K CG on 09-May-2018 for Defect# NAIT-29364
       WHERE cust_doc_id = p_cust_doc_id
         AND ebl_templhdr_id = p_ebl_templhdr_id;

      IF (SQL%NOTFOUND)
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         RAISE;
   END update_row_txt;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : DELETE_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- |  This procedure shall delete data  in XX_CDH_EBL_TEMPL_HDR_TXT.           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE delete_row_txt (p_cust_doc_id IN NUMBER,
                             p_ebl_templhdr_id  IN   NUMBER
                             )
   IS
   BEGIN
      DELETE FROM xx_cdh_ebl_templ_hdr_txt
            WHERE cust_doc_id = p_cust_doc_id
              AND ebl_templhdr_id = p_ebl_templhdr_id;

      IF (SQL%NOTFOUND)
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RAISE;
      WHEN TOO_MANY_ROWS
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         RAISE;
   END delete_row_txt;

END xx_cdh_ebl_templ_header_pkg;
/
SHOW ERRORS;
EXIT;