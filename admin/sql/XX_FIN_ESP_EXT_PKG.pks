CREATE OR REPLACE PACKAGE XX_FIN_ESP_EXT_PKG AS

-- +===================================================================+
-- | Name  : XX_FIN_ESP_EXT_PKG.EXTRACT_ESP_DETAILS                    |
-- | Description      : This Procedure will read a file with ESP data  |
-- |                    extracted on the mainframe, and sent to EBS.   |
-- |                    It will get the program name and query tables  |
-- |                    to get the user program name.                  |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+

PROCEDURE EXTRACT_ESP_DETAILS(errbuf             OUT NOCOPY VARCHAR2,
                              retcode            OUT NOCOPY NUMBER);

PROCEDURE XX_GET_TRANS_DEF_ID(p_member           IN  VARCHAR2,
                              p_trans_id         OUT NUMBER,
                              p_ret_code         OUT NUMBER);

PROCEDURE XX_GET_TRANS_VAL_ID(p_trans_id         IN  NUMBER,
                              p_member_name      IN  VARCHAR2,
                              p_job_name_1       IN  VARCHAR2,
                              p_job_name_2       IN  VARCHAR2,
                              p_rel_name_1       IN  VARCHAR2,
                              p_rel_name_2       IN  VARCHAR2,
                              p_appl_name        IN  VARCHAR2,
                              p_resp_name        IN  VARCHAR2,
                              p_user_name        IN  VARCHAR2,
                              p_short_name       IN  VARCHAR2,
                              p_pgm_args         IN  VARCHAR2,
                              p_exec_name        IN  VARCHAR2,
                              p_ret_code         OUT NUMBER);

PROCEDURE UPDATE_ESP_DETAILS(errbuf              OUT NOCOPY VARCHAR2,
                             retcode             OUT NOCOPY NUMBER);

PROCEDURE LOAD_ESP_DETAILS(errbuf                OUT NOCOPY VARCHAR2,
                           retcode               OUT NOCOPY NUMBER);

PROCEDURE LOAD_ESP_LINKS(errbuf                  OUT NOCOPY VARCHAR2,
                         retcode                 OUT NOCOPY NUMBER);

PROCEDURE LOAD_ESP_SCHED(errbuf                  OUT NOCOPY VARCHAR2,
                         retcode                 OUT NOCOPY NUMBER);

PROCEDURE LOAD_ESP_RUNS(errbuf                   OUT NOCOPY VARCHAR2,
                        retcode                  OUT NOCOPY NUMBER);

PROCEDURE LOAD_ESP_PARMS(errbuf                   OUT NOCOPY VARCHAR2,
                         retcode                  OUT NOCOPY NUMBER);

PROCEDURE UPDT_ESP_STATS(errbuf                   OUT NOCOPY VARCHAR2,
                         retcode                  OUT NOCOPY NUMBER);

PROCEDURE PRINT_ESP_RPT(errbuf                   OUT NOCOPY VARCHAR2,
                        retcode                  OUT NOCOPY NUMBER,
                        p_application             IN VARCHAR2,
                        p_job_name_1              IN VARCHAR2,
                        p_job_name_2              IN VARCHAR2);

END XX_FIN_ESP_EXT_PKG;
/
