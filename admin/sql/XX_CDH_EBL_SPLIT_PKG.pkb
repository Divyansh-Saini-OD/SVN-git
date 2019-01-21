SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_cdh_ebl_split_pkg
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- +===========================================================================+
-- | Name        : xx_cdh_ebl_split_pkg                                        |
-- | Description :                                                             |
-- | This package provides table handlers for the tables                       |
-- | XX_CDH_EBL_SPLIT_FIELDS and XX_CDH_EBL_SPLIT_FIELDS_TXT                   |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |1.0      30-Nov-15   Sridevi K     Initial                                 |
-- |2.0      30-MAR-16   Havish K      Added for MOD 4B Release 4              |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : INSERT_ROW                                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure inserts data into the table XX_CDH_EBL_SPLIT_FIELDS.       |
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
      p_split_field_id           IN   NUMBER,
      p_split_base_field_id      IN   NUMBER,
      p_fixed_position           IN   VARCHAR2,
      p_delimiter                IN   VARCHAR2,
      p_split_field1_label       IN   VARCHAR2,
      p_split_field2_label       IN   VARCHAR2,
      p_split_field3_label       IN   VARCHAR2,
      p_split_field4_label       IN   VARCHAR2,
      p_split_field5_label       IN   VARCHAR2,
      p_split_field6_label       IN   VARCHAR2,
      p_cust_account_id          IN   NUMBER,
      p_cust_doc_id              IN   NUMBER,
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
      p_split_type               IN   VARCHAR2
   )
   IS
   BEGIN
      INSERT INTO xx_cdh_ebl_split_fields
                  (split_field_id, split_base_field_id,
                   fixed_position, delimiter, split_field1_label,
                   split_field2_label, split_field3_label,
                   split_field4_label, split_field5_label,
                   split_field6_label, cust_account_id, cust_doc_id,
                   attribute1, attribute2, attribute3, attribute4,
                   attribute5, attribute6, attribute7, attribute8,
                   attribute9, attribute10, attribute11,
                   attribute12, attribute13, attribute14,
                   attribute15, attribute16, attribute17,
                   attribute18, attribute19, attribute20, last_update_date,
                   last_updated_by, creation_date, created_by,
                   last_update_login, request_id,
                   program_application_id, program_id,
                   program_update_date, wh_update_date, split_type
                  )
           VALUES (p_split_field_id, p_split_base_field_id,
                   p_fixed_position, p_delimiter, p_split_field1_label,
                   p_split_field2_label, p_split_field3_label,
                   p_split_field4_label, p_split_field5_label,
                   p_split_field6_label, p_cust_account_id, p_cust_doc_id,
                   p_attribute1, p_attribute2, p_attribute3, p_attribute4,
                   p_attribute5, p_attribute6, p_attribute7, p_attribute8,
                   p_attribute9, p_attribute10, p_attribute11,
                   p_attribute12, p_attribute13, p_attribute14,
                   p_attribute15, p_attribute16, p_attribute17,
                   p_attribute18, p_attribute19, p_attribute20, SYSDATE,
                   p_last_updated_by, SYSDATE, p_created_by,
                   p_last_update_login, p_request_id,
                   p_program_application_id, p_program_id,
                   p_program_update_date, p_wh_update_date, p_split_type
                  );
   END insert_row;

   PROCEDURE update_row (
      p_split_field_id           IN   NUMBER,
      p_split_base_field_id      IN   NUMBER,
      p_fixed_position           IN   VARCHAR2,
      p_delimiter                IN   VARCHAR2,
      p_split_field1_label       IN   VARCHAR2,
      p_split_field2_label       IN   VARCHAR2,
      p_split_field3_label       IN   VARCHAR2,
      p_split_field4_label       IN   VARCHAR2,
      p_split_field5_label       IN   VARCHAR2,
      p_split_field6_label       IN   VARCHAR2,
      p_cust_account_id          IN   NUMBER,
      p_cust_doc_id              IN   NUMBER,
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
      p_split_type               IN   VARCHAR2
   )
   IS
   BEGIN
      UPDATE xx_cdh_ebl_split_fields
         SET split_field_id = p_split_field_id,
             split_base_field_id = p_split_base_field_id,
             fixed_position = p_fixed_position,
             delimiter = p_delimiter,
             split_field1_label = p_split_field1_label,
             split_field2_label = p_split_field2_label,
             split_field3_label = p_split_field3_label,
             split_field4_label = p_split_field4_label,
             split_field5_label = p_split_field5_label,
             split_field6_label = p_split_field6_label,
             cust_account_id = p_cust_account_id,
             cust_doc_id = p_cust_doc_id,
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
             split_type = p_split_type
       WHERE cust_doc_id = p_cust_doc_id AND split_field_id = p_split_field_id;

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

   PROCEDURE delete_row (p_split_field_id IN NUMBER, p_cust_doc_id IN NUMBER)
   IS
   BEGIN
      DELETE      xx_cdh_ebl_split_fields
            WHERE split_field_id = p_split_field_id
              AND cust_doc_id = p_cust_doc_id;

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
   
-- Added for MOD 4B Release 4

-- +===========================================================================+
-- |                                                                           |
-- | Name        : INSERT_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure inserts data into the table XX_CDH_EBL_SPLIT_FIELDS_TXT    |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE insert_row_txt (
      p_split_field_id             IN   NUMBER,
      p_cust_doc_id                IN   NUMBER,
      p_cust_account_id            IN   NUMBER,
      p_split_base_field_id        IN   NUMBER,
      p_split_field1_label         IN   VARCHAR2, 
      p_split_field2_label         IN   VARCHAR2,
      p_split_field3_label         IN   VARCHAR2,
      p_split_field4_label         IN   VARCHAR2,
      p_split_field5_label         IN   VARCHAR2,
      p_split_field6_label         IN   VARCHAR2,
      p_fixed_position             IN   VARCHAR2,
      p_delimiter                  IN   VARCHAR2,
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
      p_split_type                 IN   VARCHAR2,
      p_tab                        IN   VARCHAR2
   )
   IS
   BEGIN
      INSERT INTO xx_cdh_ebl_split_fields_txt
                  (split_field_id, 
                   cust_doc_id,
                   cust_account_id,
                   split_base_field_id,
                   split_field1_label,
                   split_field2_label,
                   split_field3_label,
                   split_field4_label,
                   split_field5_label,
                   split_field6_label,
                   fixed_position,
                   delimiter,
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
                   split_type,
                   tab
                  )
           VALUES (p_split_field_id ,
                   p_cust_doc_id ,
                   p_cust_account_id ,
                   p_split_base_field_id,
                   p_split_field1_label,
                   p_split_field2_label,
                   p_split_field3_label,
                   p_split_field4_label,
                   p_split_field5_label,
                   p_split_field6_label,
                   p_fixed_position,
                   p_delimiter,
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
                   p_split_type,
                   p_tab
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
-- |  This procedure shall update data into the table                          |
-- |  XX_CDH_EBL_SPLIT_FIELDS_TXT                                              |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE update_row_txt (
      p_split_field_id             IN   NUMBER,
      p_cust_doc_id                IN   NUMBER,
      p_cust_account_id            IN   NUMBER,
      p_split_base_field_id        IN   NUMBER,
      p_split_field1_label         IN   VARCHAR2, 
      p_split_field2_label         IN   VARCHAR2,
      p_split_field3_label         IN   VARCHAR2,
      p_split_field4_label         IN   VARCHAR2,
      p_split_field5_label         IN   VARCHAR2,
      p_split_field6_label         IN   VARCHAR2,
      p_fixed_position             IN   VARCHAR2,
      p_delimiter                  IN   VARCHAR2,
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
      p_split_type                 IN   VARCHAR2,
      p_tab                        IN   VARCHAR2
   )
   IS
   BEGIN
      UPDATE xx_cdh_ebl_split_fields_txt
         SET split_base_field_id = p_split_base_field_id,
             split_field1_label = p_split_field1_label,
             split_field2_label = p_split_field2_label,
             split_field3_label = p_split_field3_label,
             split_field4_label = p_split_field4_label,
             split_field5_label = p_split_field5_label,
             split_field6_label = p_split_field6_label,
             fixed_position = p_fixed_position,
             delimiter = p_delimiter,
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
             split_type = p_split_type,
             tab = p_tab
       WHERE cust_doc_id = p_cust_doc_id
         AND split_field_id = p_split_field_id;

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
-- |  This procedure shall delete data in XX_CDH_EBL_SPLIT_FIELDS_TXT.         |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE delete_row_txt (p_cust_doc_id IN NUMBER,
                             p_split_field_id  IN   NUMBER
                             )
   IS
   BEGIN
      DELETE FROM xx_cdh_ebl_split_fields_txt
            WHERE cust_doc_id = p_cust_doc_id
              AND split_field_id = p_split_field_id;

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
   
END xx_cdh_ebl_split_pkg;
/

SHOW ERRORS;
