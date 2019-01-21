SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - Project Simplify						|
-- +============================================================================================+
-- | Name        : XX_CRM_EXP_BATCH_PKG.pks                                                     |
-- | Description : SFDC Conversion                                                              |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        08/07/11       Devendra Petkar        Initial version                            |
-- +============================================================================================+

CREATE OR REPLACE PACKAGE xx_crm_exp_batch_pkg
-- +===================================================================+
-- |                  Office Depot -  Ebiz to SFDC Conversion.         |
-- +===================================================================+
-- | Name       :  XX_CRM_EXP_BATCH_PKG                                |
-- | Description: This Package is to performed to create csv file from |
-- |          staging table and send this file to the SFDC.            |
-- |          SFDC will load exception table and then this process     |
-- |          will update staging table with exceptions.               |
-- |								       |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |V 1.0    08/07/11   Devendra Petkar				       |
-- +===================================================================+
AS
--G_LEVEL_ID                      CONSTANT  NUMBER       := 10001;
--G_LEVEL_VALUE                   CONSTANT  NUMBER       := 0;

-- +===================================================================+
-- | Name             : Generate_File                                  |
-- | Description      : This procedure extracts feeds	               |
-- |					                               |
-- |                                                                   |
-- | parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

   PROCEDURE generate_file (
      x_errbuf      OUT NOCOPY      VARCHAR2,
      x_retcode     OUT NOCOPY      NUMBER,
      p_batch_id    IN              NUMBER,
      p_delimiter   IN              VARCHAR2 DEFAULT ','
   );

   PROCEDURE generate_batch_id (
      x_batch_id      OUT NOCOPY      xx_crm_exp_batch.batch_id%TYPE,
      p_batch_name    IN              xx_crm_exp_batch.batch_name%TYPE,
      p_entity_name   IN              xx_crm_exp_batch.entity_name%TYPE
   );

   PROCEDURE update_batch_status (
      x_error      OUT NOCOPY      NUMBER,
      p_batch_id   IN              xx_crm_exp_batch.batch_id%TYPE,
      p_status     IN              xx_crm_exp_batch.batch_status%TYPE
   );

   PROCEDURE update_batch_record_cnt (
      x_error                  OUT NOCOPY      NUMBER,
      p_batch_id               IN              xx_crm_exp_batch.batch_id%TYPE,
      p_total_record           IN              xx_crm_exp_batch.total_record%TYPE,
      p_total_success_record   IN              xx_crm_exp_batch.total_success_record%TYPE,
      p_total_failed_record    IN              xx_crm_exp_batch.total_failed_record%TYPE
   );

   PROCEDURE update_exception (
      x_error      OUT NOCOPY      NUMBER,
      p_batch_id   IN              xx_crm_exp_batch.batch_id%TYPE
   );

   PROCEDURE purge_table (
      x_errbuf      OUT NOCOPY      VARCHAR2,
      x_retcode     OUT NOCOPY      NUMBER,
      p_table_name		   VARCHAR2,
      p_batch_id   IN              xx_crm_exp_batch.batch_id%TYPE DEFAULT '0',
      p_truncate   IN		  VARCHAR2 DEFAULT 'N'
   );

END xx_crm_exp_batch_pkg;
/
SHOW ERRORS;

EXIT;
