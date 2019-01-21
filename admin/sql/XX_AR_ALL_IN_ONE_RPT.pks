create or replace
PACKAGE XX_AR_ALL_IN_ONE_RPT
AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- +====================================================================+
-- | Name         : XX_AR_ALL_IN_ONE_RPT                                |
-- | Description  : This package is used to get the Daily Invoices count|
-- |                and amount for all billing methods in single report |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version  Date         Author         Remarks                        |
-- |=======  ===========  =============  ===============================|
-- | 1       28-AUG-2012  Ankit Arora    Initial version                |
-- |                                     Created for Defect 24869       |
-- | 1.2     01-JUN-2016  Suresh Naragam Changes related Mod 4B         |
-- |                                     Release 4 (Defect#2185)        |
-- +====================================================================+

-- +====================================================================+
-- | Name        : XX_AR_ALL_IN_ONE_RPT.MAIN                            |
-- | Description : This procedure is used to trigger all other procedure|
-- |               for all delivery methods                             |
-- |                                                                    |
-- | Parameters  : 1. p_print_date                                      |
-- |               2  p_email_address                                   |
-- |               3. p_sender_address                                  |
-- |                                                                    |
-- | Returns     :   x_errbuf, x_ret_code                               |
-- |                                                                    |
-- |                                                                    |
-- +====================================================================+

RPT_REQUEST_ID NUMBER(20);
P_START_TIME VARCHAR2(30);
P_END_TIME VARCHAR2(30);
P_ORG_ID VARCHAR2(10);

 PROCEDURE MAIN (x_errbuf             OUT    VARCHAR2
                          ,x_ret_code           OUT    NUMBER
                          ,p_print_date         IN     VARCHAR2
                          ,p_email_address      IN     VARCHAR2
                          ,p_sender_address     IN     VARCHAR2);


PROCEDURE xx_get_epdf(
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,
	p_request_id IN NUMBER);

 PROCEDURE xx_get_exls(
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,p_request_id IN NUMBER);

 PROCEDURE xx_get_etxt(
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,p_request_id IN NUMBER);

 PROCEDURE xx_get_edi(
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,p_request_id IN NUMBER);

     PROCEDURE xx_get_elec(
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,p_request_id IN NUMBER);

        PROCEDURE xx_get_certegy(
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,p_request_id IN NUMBER);

    PROCEDURE xx_get_spl_handling(
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,p_request_id IN NUMBER);



END ;
/