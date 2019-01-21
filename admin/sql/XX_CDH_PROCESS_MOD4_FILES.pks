CREATE OR REPLACE PACKAGE APPS.XX_CDH_PROCESS_MOD4_FILES
AS
   -- +=========================================================================+
   -- |                        Office Depot                                      |
   -- +=========================================================================+
   -- | Name  : XX_CDH_PROCESS_MOD4_FILES                                   |
   -- | Rice ID: C0701                                                          |
   -- | Description      : This Program will get "XXOD_OMX_MOD4_INTERFACE"      |
   -- |                    Translation Data as well as updates the batch_id     |
   -- |                                                                         |
   -- |Change Record:                                                           |
   -- |===============                                                          |
   -- |Version Date        Author            Remarks                            |
   -- |======= =========== =============== =====================================|
   --|1.0     10-FEB-2015 Abhi K          Initial draft version                |
   --|1.1     20-MAR-2015 Abhi K          Code Review
   -- +=========================================================================+

   PROCEDURE GET_CONFIG_INFO (retcode                OUT NUMBER,
                              errbuf                 OUT VARCHAR2,
                              p_file_name         IN     VARCHAR2,
                              lc_config_details      OUT VARCHAR2);

   PROCEDURE update_table (retcode           OUT NUMBER,
                           errbuf            OUT VARCHAR2,
                           p_tab_name     IN     VARCHAR2,
                           p_source       IN     VARCHAR2,
                           p_file_name    IN     VARCHAR2,
                           p_request_id   IN     NUMBER,
                           p_user_id      IN     VARCHAR2,
                           p_login_id     IN     NUMBER);
END; 
/
SHOW ERRORS;

