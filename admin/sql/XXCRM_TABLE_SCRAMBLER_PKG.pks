create or replace PACKAGE XXCRM_TABLE_SCRAMBLER_PKG
-- +===================================================================+
-- |                  Office Depot -  Ebiz Generic Process.            |
-- +===================================================================+
-- | Name       :  XXCRM_TABLE_SCRAMBLER_PKG                              |
-- | Description: Generic Process to create export file.	       |
-- |								       |
-- |								       |
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
-- | Name             : generate_table_exp_file                        |
-- | Description      : This procedure extracts feeds	               |
-- |					                               |
-- |                                                                   |
-- | parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+


   PROCEDURE generate_customer_account_exp (
      x_errbuf			OUT NOCOPY      VARCHAR2,
      x_retcode			OUT NOCOPY      NUMBER,
      p_scrambler_method	IN VARCHAR2 DEFAULT 'RANDOM'
   );


   PROCEDURE generate_customer_address_exp (
      x_errbuf			OUT NOCOPY      VARCHAR2,
      x_retcode			OUT NOCOPY      NUMBER,
      p_scrambler_method	IN VARCHAR2 DEFAULT 'RANDOM'
   );

   PROCEDURE generate_customer_contact_exp (
      x_errbuf			OUT NOCOPY      VARCHAR2,
      x_retcode			OUT NOCOPY      NUMBER,
      p_scrambler_method	IN VARCHAR2 DEFAULT 'RANDOM'
   );


   PROCEDURE generate_table_exp_file (
      x_errbuf      OUT NOCOPY      VARCHAR2,
      x_retcode     OUT NOCOPY      NUMBER,
      p_table_name  IN              VARCHAR2,
      p_delimiter   IN              VARCHAR2 DEFAULT '|~'
   );
   
   PROCEDURE copy_file (p_sourcepath IN VARCHAR2, p_destpath IN VARCHAR2);
   PROCEDURE Zip_File(p_sourcepath  IN VARCHAR2,
                     p_destpath    IN VARCHAR2
                    );

END XXCRM_TABLE_SCRAMBLER_PKG;
/