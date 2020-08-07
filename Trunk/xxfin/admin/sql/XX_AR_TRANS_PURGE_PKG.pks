CREATE OR REPLACE PACKAGE apps.XX_AR_TRANS_PURGE_PKG IS
-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |                        Office Depot Organization                      |
-- +=======================================================================+
-- | Name       : XX_AR_TRANS_PURGE_PKG                                    |
-- |                                                                       |
-- | RICE#      : E2075_EBS_AR_Archive_Purge                               |
-- |                                                                       |
-- | Description: This package/RICE is used for purging AR delivered and   |
-- |              custom tables.  The follow                               |
-- |                                                                       |
-- |                                                                       |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version    Date         Author         Remarks                         |
-- |=========  ===========  =============  ================================|
-- |   1.0     09-DEC-2010  R.Aldridge     Initial Version - Defect 8950   |
-- +=======================================================================+

   -- +====================================================================+
   -- | Name       : AR_PURGE_WRAPPER                                      |
   -- |                                                                    |
   -- | Description: Procedure is used for submitting standard AR archive  |
   -- |              and purge and the custom AR archive and purge         |
   -- |                                                                    |
   -- | Parameters : x_errbuf           - Error message for conc programs  |
   -- |              x_ret_code         - Return code for conc programs    |
   -- |              p_start_gl_date    - Archive trans start GL date      |
   -- |              p_cut_off_date     - Archive trans cutoff date        |
   -- |              p_archive_level    - Level of archiving               |
   -- |              p_total_workers    - Number of child processes to use |
   -- |              p_customer_id      - Optionally limit by customer     |
   -- |              p_short_flag       - Log level for for standard purge |
   -- |              p_dm_purge_flag    - Purge DM Original Transactions   |
   -- |              p_purge_window     - Purge Window End Date-time       |
   -- |              p_bulk_limit       - Bulk processing size             |
   -- |              p_gather_tab_stats - Gathers stats on std archive tabs|
   -- |              p_debug            - Debug flag                       |
   -- |                                                                    |
   -- |                                                                    |
   -- | Returns    : x_errbuf and x_ret_code - Both are required for       |
   -- |                                        EBS concurrent processing   |
   -- |                                                                    |
   -- +====================================================================+
   PROCEDURE AR_PURGE_WRAPPER (x_errbuf             OUT    VARCHAR2
                              ,x_ret_code           OUT    NUMBER
                              ,p_start_gl_date      IN     VARCHAR2
                              ,p_cut_off_date       IN     VARCHAR2
                              ,p_archive_level      IN     VARCHAR2
                              ,p_total_workers      IN     NUMBER
                              ,p_customer_id        IN     NUMBER
                              ,p_short_flag         IN     VARCHAR2
                              ,p_dm_purge_flag      IN     VARCHAR2
					,p_purge_window	    IN     VARCHAR2
                              ,p_bulk_limit         IN     NUMBER
                              ,p_gather_tab_stats   IN     VARCHAR2
                              ,p_debug              IN     VARCHAR2);

   -- +====================================================================+
   -- | Name       : AR_PURGE_MASTER                                       |
   -- |                                                                    |
   -- | Description: Procedure is used for submitting the custom AR purge  |
   -- |              program (AR_PURGE_EXECUTE procedure).                 |
   -- |                                                                    |
   -- | Parameters : x_errbuf           - Error message for conc programs  |
   -- |              x_ret_code         - Return code for conc programs    |
   -- |              p_archive_id_low   - Archive ID low value             |
   -- |              p_archive_id_high  - Archive ID high value            |
   -- |              p_bulk_limit       - Bulk processing size             |
   -- |              p_gather_tab_stats - Gathers stats on std archive tabs|
   -- |              p_debug            - Debug flag                       |
   -- |                                                                    |
   -- |                                                                    |
   -- | Returns    : x_errbuf and x_ret_code - Both are required for       |
   -- |                                        EBS concurrent processing   |
   -- +====================================================================+
   PROCEDURE AR_PURGE_MASTER (x_errbuf             OUT    VARCHAR2
                             ,x_ret_code           OUT    NUMBER
                             ,p_archive_id_low     IN     VARCHAR2
                             ,p_archive_id_high    IN     VARCHAR2
                             ,p_bulk_limit         IN     NUMBER
                             ,p_gather_tab_stats   IN     VARCHAR2
                             ,p_debug              IN     VARCHAR2);


   -- +====================================================================+
   -- | Name       : AR_PURGE_EXECUTE                                      |
   -- |                                                                    |
   -- | Description: Procedure is used for purging gl_import_references for|
   -- |              both AR and COGS journals based.  The procedure is    |
   -- |              also used to purge the following custom tables:       |
   -- |                  - XX_AR_CASH_RECEIPTS_EXT                         |
   -- |                  - XX_AR_REFUND_ERROR_LOG                          |
   -- |                  - XX_IBY_CC_REFUNDS                               |
   -- |                                                                    |
   -- |             This procedure purges gl_import_references and custom  |
   -- |             tables based on what is purge by the delivered standard|
   -- |             "New Archive and Purge" program (ARPURGE).             |
   -- |                                                                    |
   -- | Parameters : x_errbuf           - Error message for conc programs  |
   -- |              x_ret_code         - Return code for conc programs    |
   -- |              p_archive_id       - ID used for tracking purged trans|
   -- |              p_worker_number    - Specific Worker/thread Number    |
   -- |              p_bulk_limit       - Bulk processing size             |
   -- |              p_debug            - Debug flag                       |
   -- |                                                                    |
   -- |                                                                    |
   -- | Returns    : x_errbuf and x_ret_code - Both are required for       |
   -- |                                        EBS concurrent processing   |
   -- +====================================================================+
   PROCEDURE AR_PURGE_EXECUTE (x_errbuf         OUT VARCHAR2
                              ,x_ret_code       OUT NUMBER
                              ,p_archive_id     IN  NUMBER
                              ,p_worker_number  IN  NUMBER
                              ,p_bulk_limit     IN  NUMBER
                              ,p_debug          IN  VARCHAR2);


   -- +====================================================================+
   -- | Name       : STANDARD_AR_PURGE                                     |
   -- |                                                                    |
   -- | Description: Procedure is used to submit the standard archive and  |
   -- |              purge concurrent program called"New Archive and Purge"|
   -- |                                                                    |
   -- | Parameters : x_errbuf           - Error message for conc programs  |
   -- |              x_ret_code         - Return code for conc programs    |
   -- |              p_cut_off_date     - Archive trans cutoff date        |
   -- |              p_archive_level    - Level of archiving               |
   -- |              p_total_workers    - Number of child processes to use |
   -- |              p_customer_id      - Optionally limit by customer     |
   -- |              p_short_flag       - Log level for for standard purge |
   -- |              p_dm_purge_flag    - Purge DM Original Transactions   |
   -- |              p_bulk_limit       - Bulk processing size             |
   -- |                                                                    |
   -- | Returns    : x_errbuf and x_ret_code - Both are required for       |
   -- |                                        EBS concurrent processing   |
   -- +====================================================================+
   PROCEDURE STANDARD_AR_PURGE (x_errbuf             OUT    VARCHAR2
                               ,x_ret_code           OUT    NUMBER
                               ,p_start_gl_date      IN     VARCHAR2
                               ,p_cut_off_date       IN     VARCHAR2
                               ,p_archive_level      IN     VARCHAR2
                               ,p_total_workers      IN     NUMBER
                               ,p_customer_id        IN     NUMBER
                               ,p_short_flag         IN     VARCHAR2
                               ,p_dm_purge_flag      IN     VARCHAR2
                               ,p_bulk_limit         IN     NUMBER);

END XX_AR_TRANS_PURGE_PKG;
/
SHO ERR
