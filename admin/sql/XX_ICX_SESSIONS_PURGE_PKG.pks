CREATE OR REPLACE PACKAGE XX_ICX_SESSIONS_PURGE_PKG IS

PROCEDURE icx_purge (x_retcode OUT NOCOPY NUMBER
                    ,x_errbuf  OUT NOCOPY VARCHAR2
                    ,p_date    IN         VARCHAR2 DEFAULT NULL
                    );

END XX_ICX_SESSIONS_PURGE_PKG;
/
