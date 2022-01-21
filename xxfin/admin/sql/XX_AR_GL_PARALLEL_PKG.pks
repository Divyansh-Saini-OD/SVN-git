SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF

WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR  EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_AR_GL_PARALLEL_PKG AS
/*=============================================================================+
 | PACKAGE          XX_AR_GL_PARALLEL_PKG                                      |
 |                                                                             |
 | RICE#            E2050                                                      |
 |                                                                             |
 | DESCRIPTION                                                                 |
 |      Generic package for recording and maintaining plsql                    |
 |      procedures and functions for the ARGLTP concurrent program.            |
 |                                                                             |
 | PSEUDO CODE LOGIC/ALGORITHMS                                                |
 |                                                                             |
 |                                                                             |
 | PUBLIC PROCEDURES                                                           |
 |   MAIN                                                                      |
 |                                                                             |
 | PROFILE OPTIONS                                                             |
 |                                                                             |
 | KNOWN ISSUES                                                                |
 |      This package implemented specifically for plsql functions              |
 |      calling ARGLTP.                                                        |
 |                                                                             |
 | NOTES                                                                       |
 |                                                                             |
 | MODIFICATION HISTORY                                                        |
 | Date                  Author               Description of Changes           |
 | 20-NOV-2009           Sreelatha Givvimani  Created                          |
 | 22-APR-2010           Ganga Devi R         Added Procedure PREPARE_RECEIPTS |
 |                                            for defect#4889                  |
 *============================================================================*/
PROCEDURE MAIN(
                 x_errbuf                 OUT NOCOPY VARCHAR2
                ,x_retcode                OUT NOCOPY NUMBER
                ,p_gl_start_date          IN VARCHAR2
                ,p_gl_end_date            IN VARCHAR2
                ,p_gl_posted_date         IN VARCHAR2
                ,p_report_only            IN VARCHAR2
                ,p_summary_flag           IN VARCHAR2
                ,p_journal_import         IN VARCHAR2
                ,p_posting_days_per_cycle IN NUMBER
                ,p_posting_control_id     IN NUMBER
                ,p_debug_flag             IN VARCHAR2
                ,p_org_id                 IN NUMBER
                ,p_sob_id                 IN NUMBER
                ,p_processing_type        IN VARCHAR2
                ,p_worker_number          IN NUMBER
                ,p_max_workers            IN NUMBER
                ,p_skip_unposted_items    IN VARCHAR2
                ,p_skip_revenue           IN VARCHAR2
                ,p_batch_size             IN NUMBER
                )  ;

PROCEDURE PREPARE_RECEIPTS  (x_errbuf          OUT VARCHAR2
                            ,x_retcode         OUT NUMBER
                            ,p_worker_number   IN  NUMBER
                            ,p_org_id          IN  NUMBER
                            ,p_start_date      IN  DATE
                            ,p_post_thru_date  IN  DATE);

END XX_AR_GL_PARALLEL_PKG;
/
SHOW ERRORS;
