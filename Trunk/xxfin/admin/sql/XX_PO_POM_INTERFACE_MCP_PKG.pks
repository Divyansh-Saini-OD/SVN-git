CREATE OR REPLACE PACKAGE XX_PO_POM_INTERFACE_MCP_PKG AS
PROCEDURE master_main( x_retcode            OUT NOCOPY NUMBER
                      ,x_errbuf             OUT NOCOPY VARCHAR2
                      ,p_validate_only_flag  IN        VARCHAR2  DEFAULT 'N' -- Y/N
                      ,p_reset_status_flag   IN        VARCHAR2  DEFAULT 'N' -- Y/N
                      ,p_batch_size          IN        INTEGER   DEFAULT NULL
                      ,p_max_thread          IN        INTEGER   DEFAULT NULL
                      ,p_debug_flag          IN        VARCHAR2  DEFAULT 'N'
                      ,p_pdoi_batch_size     IN        INTEGER   DEFAULT 5000
					);

PROCEDURE create_exception_report;

END XX_PO_POM_INTERFACE_MCP_PKG;
/
