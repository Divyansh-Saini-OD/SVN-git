CREATE OR REPLACE
PACKAGE "XX_CS_CONC_PKG" AS

PROCEDURE GET_AQ_MSG (x_errbuf     OUT  NOCOPY  VARCHAR2
                    , x_retcode  OUT  NOCOPY  NUMBER );
                    
PROCEDURE ROUTE_DC_QUEUE (x_errbuf     OUT  NOCOPY  VARCHAR2
                    , x_retcode  OUT  NOCOPY  NUMBER );
                    
PROCEDURE GET_EMAIL_RES (x_errbuf     OUT  NOCOPY  VARCHAR2
                    , x_retcode  OUT  NOCOPY  NUMBER );
                    
END;
/
exit;

