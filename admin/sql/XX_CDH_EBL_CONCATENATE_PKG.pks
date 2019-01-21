SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_cdh_ebl_concatenate_pkg AUTHID CURRENT_USER
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_CONCATENATE_PKG                                  |
-- | Description :                                                             |
-- | This package provides table handlers for the table                        |
-- | XX_CDH_EBL_CONCAT_FIELDS and XX_CDH_EBL_CONCAT_FIELDS_TXT                 |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |1.0      20-Nov-15   Sridevi K     Initial for MOD 4B R3                   |
-- |2.0      30-MAR-16   Havish K      Modified for MOD 4B R4                  |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : INSERT_ROW                                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure inserts data into the tables XX_CDH_EBL_CONCAT_FIELDS      |
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
      p_conc_field_id            IN   NUMBER,
      p_conc_field_label         IN   VARCHAR2,
      p_cust_account_id          IN   NUMBER,
      p_cust_doc_id              IN   NUMBER,
      p_conc_base_field_id1      IN   NUMBER,
      p_conc_base_field_id2      IN   NUMBER,
      p_conc_base_field_id3      IN   NUMBER,
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
      p_wh_update_date           IN   DATE DEFAULT NULL
   );

   PROCEDURE update_row (
      p_conc_field_id            IN   NUMBER,
      p_conc_field_label         IN   VARCHAR2,
      p_cust_account_id          IN   NUMBER,
      p_cust_doc_id              IN   NUMBER,
      p_conc_base_field_id1      IN   NUMBER,
      p_conc_base_field_id2      IN   NUMBER,
      p_conc_base_field_id3      IN   NUMBER,
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
      p_last_update_login        IN   NUMBER DEFAULT fnd_global.user_id,
      p_request_id               IN   NUMBER DEFAULT NULL,
      p_program_application_id   IN   NUMBER DEFAULT NULL,
      p_program_id               IN   NUMBER DEFAULT NULL,
      p_program_update_date      IN   DATE DEFAULT NULL,
      p_wh_update_date           IN   DATE DEFAULT NULL
   );

   PROCEDURE delete_row (p_conc_field_id IN NUMBER, p_cust_doc_id IN NUMBER);
   
-- Added for MOD 4B Release 4   
-- +===========================================================================+
-- |                                                                           |
-- | Name        : INSERT_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure inserts data into the table  XX_CDH_EBL_CONCAT_FIELDS_TXT  |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE insert_row_txt (
      p_conc_field_id              IN   NUMBER,
      p_cust_doc_id                IN   NUMBER,
      p_cust_account_id            IN   NUMBER,
      p_conc_base_field_id1        IN   NUMBER,
      p_conc_base_field_id2        IN   NUMBER,
      p_conc_base_field_id3        IN   NUMBER,
      p_conc_base_field_id4        IN   NUMBER,
      p_conc_base_field_id5        IN   NUMBER,
      p_conc_base_field_id6        IN   NUMBER,
      p_conc_field_label           IN   VARCHAR2, 
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
      p_tab                        IN   VARCHAR2,
      p_seq1                       IN   NUMBER,
      p_seq2                       IN   NUMBER,
      p_seq3                       IN   NUMBER,
      p_seq4                       IN   NUMBER,
      p_seq5                       IN   NUMBER,
      p_seq6                       IN   NUMBER
   );

--  +==========================================================================+
-- |                                                                           |
-- | Name        : UPDATE_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure shall update data into the table                           |
-- | XX_CDH_EBL_CONCAT_FIELDS_TXT                                              |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE update_row_txt (
      p_conc_field_id              IN   NUMBER,
      p_cust_doc_id                IN   NUMBER,
      p_cust_account_id            IN   NUMBER,
      p_conc_base_field_id1        IN   NUMBER,
      p_conc_base_field_id2        IN   NUMBER,
      p_conc_base_field_id3        IN   NUMBER,
      p_conc_base_field_id4        IN   NUMBER,
      p_conc_base_field_id5        IN   NUMBER,
      p_conc_base_field_id6        IN   NUMBER,
      p_conc_field_label           IN   VARCHAR2, 
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
      p_tab                        IN   VARCHAR2,
      p_seq1                       IN   NUMBER,
      p_seq2                       IN   NUMBER,
      p_seq3                       IN   NUMBER,
      p_seq4                       IN   NUMBER,
      p_seq5                       IN   NUMBER,
      p_seq6                       IN   NUMBER
   );

-- +===========================================================================+
-- |                                                                           |
-- | Name        : DELETE_ROW_TXT                                              |
-- |                                                                           |
-- | Description :                                                             |
-- |     This procedure shall delete data in XX_CDH_EBL_CONCAT_FIELDS_TXT      |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- | Returns     :                                                             |
-- +===========================================================================+
   PROCEDURE delete_row_txt (p_cust_doc_id    IN   NUMBER,
                             p_conc_field_id  IN   NUMBER);

END xx_cdh_ebl_concatenate_pkg;
/

SHOW ERRORS;
