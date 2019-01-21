SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF 
SET FEEDBACK OFF
SET TERM ON  

PROMPT Creating Package XX_IEX_DEL_WRAP_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE 
PACKAGE XX_IEX_DEL_WRAP_PKG
AS
 -- +==================================================================+
 -- |                  Office Depot - Project Simplify                 |
 -- |                       WIPRO Technologies                         |
 -- +==================================================================+
 -- | Name :    XX_IEX_BULK_XML_DELIVERY_WRAPPER_PKG                   |
 -- | RICE :    E0984                                                  |
 -- | Description : This package submits 'IEX: Bulk XML                |
 -- |               Delivery Manager Wrapper' Program                  |
 -- |Change Record:                                                    |
 -- |===============                                                   |
 -- |Version   Date          Author              Remarks               |
 -- |=======   ==========   =============        ======================|
 -- |1.0       17-JUN-10    POORNIMADEVI R       Initial version       |
 -- |                                                                  |
 -- +==================================================================+
 -- +==================================================================+
 -- | Name        : IEX_BULK_XML_DELIVERY                              |
 -- | Description : The procedure submits standard 'IEX: Bulk XML      |
 -- |                Delivery Manager' program from the wrapper        |
 -- |                                                                  |
 -- |Change Record:                                                    |
 -- |===============                                                   |
 -- |Version   Date          Author              Remarks               |
 -- |=======   ==========   =============        ======================|
 -- |1.0       17-JUN-10    POORNIMADEVI R       Initial version       |
 -- |                                                                  |
 -- +==================================================================+
 PROCEDURE IEX_BULK_XML_DELIVERY  (  x_errbuf         OUT NOCOPY      VARCHAR2
                                    ,x_retcode        OUT NOCOPY      NUMBER
                                    ,p_workers        IN              NUMBER
                                    ,p_from_date      IN              VARCHAR2
                                    ,p_retry_errors   IN              VARCHAR2
                                    ,p_get_status     IN              VARCHAR2
                                     );
END XX_IEX_DEL_WRAP_PKG;
/

SHOW ERR
