create or replace PACKAGE  XX_AR_ORDER_SALES_TAX_REPORT
IS
/** The purpose of this program is to generate a report that will list orders
    that have a different ship-to information than what's in the customer 
    file  **/
PROCEDURE SALES_TAX_REPORT
(    errbuf             IN OUT NOCOPY VARCHAR2,
     retcode            IN OUT NOCOPY VARCHAR2,
     p_fromdate         IN            VARCHAR2,
     p_todate           IN            VARCHAR2,
     p_org_id           IN            VARCHAR2);
END XX_AR_ORDER_SALES_TAX_REPORT;
/