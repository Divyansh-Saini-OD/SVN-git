CREATE OR REPLACE PACKAGE XX_PO_RCV_CONV_PKG AS
PROCEDURE Child_main(x_retcode            OUT NOCOPY NUMBER
                    ,x_errbuf             OUT NOCOPY VARCHAR2
                    ,p_validate_only_flag  IN        VARCHAR2  DEFAULT 'N' -- Y/N
                    ,p_reset_status_flag   IN        VARCHAR2  DEFAULT 'N' -- Y/N
                    ,p_batch_id            IN        INTEGER   DEFAULT NULL
                    ,p_debug_flag          IN        VARCHAR2  DEFAULT 'N' -- Y/N
                    );

END XX_PO_RCV_CONV_PKG;
/
