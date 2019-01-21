CREATE OR REPLACE PACKAGE  XX_TM_GET_WINNER_PKG 
AS

PROCEDURE CUST_GET_WINNER ( x_retcode OUT NOCOPY NUMBER
                           ,x_errbuf  OUT NOCOPY VARCHAR2
                           ,p_party_site_id IN NUMBER
                         );

END  XX_TM_GET_WINNER_PKG;  
/

SHOW ERRORS;
