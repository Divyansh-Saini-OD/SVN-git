CREATE OR REPLACE PACKAGE XX_PO_RCV_INTERFACE_MCP_PKG AS
PROCEDURE master_main( x_retcode            OUT NOCOPY NUMBER
                      ,x_errbuf             OUT NOCOPY VARCHAR2
                      ,p_validate_only_flag  IN        VARCHAR2  DEFAULT 'N' -- Y/N
                      ,p_reset_status_flag   IN        VARCHAR2  DEFAULT 'N' -- Y/N
                      ,p_max_thread          IN        INTEGER   DEFAULT NULL
                      ,p_debug_flag          IN        VARCHAR2  DEFAULT 'N'
                     );

PROCEDURE create_exception_report;

END XX_PO_RCV_INTERFACE_MCP_PKG;
/
